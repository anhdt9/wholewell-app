"""Đo hiệu năng WholeWell trên máy Android thật (docs/refactor-plan.md, mục 3.5).

Cách dùng (từ gốc repo, máy đã kết nối adb):

    python tools/perf/run_perf.py --flutter <đường dẫn flutter> [--device <serial>] [--runs 10] [--skip-build]
        [--flavor prod|dev]

Mặc định đo flavor prod (`vn.wholewell.app`, cần hồ sơ đã xong onboarding để tới màn Hôm nay).

Kết quả ghi vào docs/perf/<ngày>-<nhánh>.json.

AN TOÀN DỮ LIỆU: script chỉ cài bằng `adb install -r` (giữ dữ liệu). Cài không được thì dừng,
**không bao giờ gỡ app**: gỡ là mất khóa Keystore và CSDL. Không dùng `flutter run` / `flutter drive`,
vì hai lệnh này tự gỡ bản cũ khi cài đè thất bại. App không ghi gì thêm khi đo (chỉ mở, cuộn, vào nền).

Đo:
- Khởi động nguội: `am start -W` (TotalTime, tới khung hình Android đầu tiên, lúc app còn màn chờ) và
  "tới Hôm nay": từ lúc Android tạo tiến trình (`Start proc` trong logcat) tới mốc `today_ready` của app
  (màn Hôm nay đã có dữ liệu). Không dùng "Fully drawn" của Android: FlutterActivity tự báo ở khung hình đầu.
  Cần hồ sơ đã xong onboarding.
- Từng bước khởi động: log `WW_PERF step/mark` của bản profile.
- Độ trễ isolate giao diện 6 s đầu (`WW_PERF uilag`): lúc bị chặn, chạm và cuộn không phản hồi.
- Khung hình 5 giây đầu sau khởi động nguội (gồm lúc chuẩn bị thư viện DSLD) và khi cuộn Hôm nay:
  log `WW_PERF frames` in lúc app vào nền.
- Kích thước APK arm64 (bản profile và, nếu có, bản release đã build).
"""
from __future__ import annotations

import argparse
import datetime as dt
import json
import re
import statistics
import subprocess
import sys
import time
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
APP = ROOT / 'app'
PKG = 'vn.wholewell.app'
ACTIVITY = f'{PKG}/vn.wholewell.app.MainActivity'
PROFILE_APK = APP / 'build/app/outputs/flutter-apk/app-prod-profile.apk'
RELEASE_APK = APP / 'build/app/outputs/flutter-apk/app-prod-release.apk'


def use_flavor(flavor: str) -> None:
    global PKG, ACTIVITY, PROFILE_APK, RELEASE_APK
    PKG = 'vn.wholewell.app' + ('.dev' if flavor == 'dev' else '')
    ACTIVITY = f'{PKG}/vn.wholewell.app.MainActivity'
    PROFILE_APK = APP / f'build/app/outputs/flutter-apk/app-{flavor}-profile.apk'
    RELEASE_APK = APP / f'build/app/outputs/flutter-apk/app-{flavor}-release.apk'


def run(cmd: list[str], check: bool = True, timeout: int = 600) -> str:
    res = subprocess.run(cmd, capture_output=True, text=True, encoding='utf-8', errors='replace', timeout=timeout)
    if check and res.returncode != 0:
        sys.exit(f'Lỗi: {" ".join(cmd)}\n{res.stdout}\n{res.stderr}')
    return res.stdout + res.stderr


class Adb:
    def __init__(self, adb: str, serial: str | None):
        self.base = [adb] + (['-s', serial] if serial else [])

    def __call__(self, *args: str, check: bool = True, timeout: int = 120) -> str:
        return run(self.base + list(args), check=check, timeout=timeout)

    def shell(self, cmd: str, check: bool = True) -> str:
        return self(*['shell', cmd], check=check)


def _ts(line: str) -> float:
    # logcat -v time: "11-29 01:06:23.817 I/..."
    m = re.match(r'\d\d-\d\d (\d\d):(\d\d):(\d\d)\.(\d{3})', line)
    if not m:
        raise ValueError(line)
    h, mi, se, ms = (int(x) for x in m.groups())
    return ((h * 60 + mi) * 60 + se) * 1000 + ms


def parse_to_today(log: str) -> int | None:
    start = next((ln for ln in log.splitlines() if 'Start proc' in ln and f':{PKG}/' in ln), None)
    ready = next((ln for ln in log.splitlines() if 'WW_PERF mark today_ready' in ln), None)
    if not start or not ready:
        return None
    return int(_ts(ready) - _ts(start))


def parse_perf(log: str) -> dict:
    marks = {m[0]: int(m[1]) for m in re.findall(r'WW_PERF mark (\w+) (\d+)', log)}
    steps = {m[0]: int(m[1]) for m in re.findall(r'WW_PERF step (\w+) (\d+)', log)}
    frames = [
        {'label': m[0], **{k: int(v) for k, v in re.findall(r'(\w+)=(\d+)', m[1])}}
        for m in re.findall(r'WW_PERF frames (\w+) (.+)', log)
    ]
    return {'marks': marks, 'steps': steps, 'frames': frames}


def summary(values: list[int]) -> dict:
    if not values:
        return {}
    v = sorted(values)
    return {
        'n': len(v),
        'min': v[0],
        'median': statistics.median(v),
        'p90': v[min(len(v) - 1, round((len(v) - 1) * 0.9))],
        'max': v[-1],
    }


def cold_start(adb: Adb, runs: int) -> dict:
    total, to_today, steps_all, marks_all, lag_max, lag_blocked = [], [], {}, {}, [], []
    for i in range(runs):
        adb.shell(f'am force-stop {PKG}')
        time.sleep(1.5)
        adb('logcat', '-c')
        out = adb.shell(f'am start -W -n {ACTIVITY}')
        m = re.search(r'TotalTime: (\d+)', out)
        if m:
            total.append(int(m.group(1)))
        tt = None
        log = ''
        for _ in range(30):  # chờ tối đa ~15 s cho mốc Hôm nay và bước thư viện DSLD
            time.sleep(0.5)
            log = adb('logcat', '-d', '-v', 'time', check=False)
            tt = parse_to_today(log)
            if tt is not None and 'WW_PERF uilag' in log:
                break
        if tt is not None:
            to_today.append(tt)
        perf = parse_perf(log)
        lag = re.search(r'WW_PERF uilag max=(\d+) blocked_over50=(\d+)', log)
        if lag:
            lag_max.append(int(lag.group(1)))
            lag_blocked.append(int(lag.group(2)))
        for k, v in perf['steps'].items():
            steps_all.setdefault(k, []).append(v)
        for k, v in perf['marks'].items():
            marks_all.setdefault(k, []).append(v)
        print(f'  lần {i + 1}: TotalTime={total[-1] if m else "?"} ms, tới Hôm nay={tt} ms, '
              f'trễ giao diện tối đa={lag.group(1) if lag else "?"} ms, bước={perf["steps"]}')
    return {
        'total_time_ms': summary(total),
        'to_today_ms': summary(to_today),
        'ui_lag_max_ms': summary(lag_max),
        'ui_blocked_over_50ms_total_ms': summary(lag_blocked),
        'steps_ms': {k: summary(v) for k, v in steps_all.items()},
        'marks_ms': {k: summary(v) for k, v in marks_all.items()},
        'raw': {'total_time_ms': total, 'to_today_ms': to_today, 'ui_lag_max_ms': lag_max},
    }


def startup_frames(adb: Adb) -> dict:
    """Khởi động nguội, chờ 5 s (thư viện DSLD chuẩn bị xong), vào nền: khung hình của 5 s đầu."""
    adb.shell(f'am force-stop {PKG}')
    time.sleep(1.5)
    adb('logcat', '-c')
    adb.shell(f'am start -W -n {ACTIVITY}')
    time.sleep(5.0)
    adb.shell('input keyevent KEYCODE_HOME')
    time.sleep(1.5)
    frames = parse_perf(adb('logcat', '-d', '-v', 'brief', check=False))['frames']
    return frames[-1] if frames else {}


def scroll_today(adb: Adb, swipes: int = 8) -> dict:
    size = re.search(r'(\d+)x(\d+)', adb.shell('wm size'))
    w, h = (int(size.group(1)), int(size.group(2))) if size else (1080, 2340)
    x = w // 2
    y_top, y_bottom = int(h * 0.3), int(h * 0.75)
    # App đang mở sau lần đo cuối: vào nền để xóa khung hình lúc khởi động, rồi quay lại.
    adb.shell('input keyevent KEYCODE_HOME')
    time.sleep(1.5)
    adb.shell(f'am start -n {ACTIVITY}')
    time.sleep(2.0)
    adb('logcat', '-c')
    for i in range(swipes):
        if i % 2 == 0:
            adb.shell(f'input swipe {x} {y_bottom} {x} {y_top} 250')
        else:
            adb.shell(f'input swipe {x} {y_top} {x} {y_bottom} 250')
        time.sleep(0.6)
    adb.shell('input keyevent KEYCODE_HOME')
    time.sleep(1.5)
    frames = parse_perf(adb('logcat', '-d', '-v', 'brief', check=False))['frames']
    return frames[-1] if frames else {}


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument('--flutter', default='flutter')
    ap.add_argument('--adb', default='adb')
    ap.add_argument('--device')
    ap.add_argument('--runs', type=int, default=10)
    ap.add_argument('--skip-build', action='store_true')
    ap.add_argument('--out')
    ap.add_argument('--flavor', choices=['prod', 'dev'], default='prod')
    args = ap.parse_args()
    use_flavor(args.flavor)

    adb = Adb(args.adb, args.device)
    devices = adb('devices')
    if '\tdevice' not in devices:
        sys.exit('Không thấy máy Android nào qua adb.')

    if not args.skip_build:
        print('Build APK profile arm64...')
        run(
            [args.flutter, 'build', 'apk', '--profile', '--flavor', args.flavor, '--target-platform', 'android-arm64'],
            timeout=1800,
        )
    print('Cài đè (adb install -r, giữ dữ liệu)...')
    out = adb('install', '-r', str(PROFILE_APK), check=False, timeout=600)
    if 'Success' not in out:
        sys.exit(f'Cài đè không được, dừng (KHÔNG gỡ app):\n{out}')

    model = adb.shell('getprop ro.product.model').strip()
    sdk = adb.shell('getprop ro.build.version.sdk').strip()
    branch = run(['git', '-C', str(ROOT), 'rev-parse', '--abbrev-ref', 'HEAD']).strip()
    sha = run(['git', '-C', str(ROOT), 'rev-parse', '--short', 'HEAD']).strip()

    print(f'Khởi động nguội x{args.runs} trên {model} (API {sdk})...')
    cold = cold_start(adb, args.runs)
    print('Khung hình 5 s đầu sau khởi động...')
    startup = startup_frames(adb)
    print('Cuộn màn Hôm nay...')
    scroll = scroll_today(adb)

    result = {
        'date': dt.date.today().isoformat(),
        'branch': branch,
        'commit': sha,
        'device': {'model': model, 'sdk': sdk},
        'build': f'profile arm64, flavor {args.flavor}',
        'cold_start': cold,
        'startup_5s_frames_us': startup,
        'scroll_today_frames_us': scroll,
        'apk_bytes': {
            'profile_arm64': PROFILE_APK.stat().st_size if PROFILE_APK.exists() else None,
            'release_arm64': RELEASE_APK.stat().st_size if RELEASE_APK.exists() else None,
        },
    }
    out_path = Path(args.out).resolve() if args.out else ROOT / 'docs/perf' / f'{result["date"]}-{branch.replace("/", "_")}.json'
    out_path.parent.mkdir(parents=True, exist_ok=True)
    out_path.write_text(json.dumps(result, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
    print(f'Đã ghi {out_path}')
    print(json.dumps({'total_time_ms': cold['total_time_ms'], 'to_today_ms': cold['to_today_ms'],
                      'ui_lag_max_ms': cold['ui_lag_max_ms'],
                      'steps_ms': cold['steps_ms'], 'startup_5s': startup, 'scroll': scroll}, ensure_ascii=False, indent=2))


if __name__ == '__main__':
    main()
