/// Mốc đo hiệu năng cho `tools/perf/run_perf.py` (docs/refactor-plan.md, mục 3.5).
///
/// Log `WW_PERF …` chỉ in ở bản profile (`kProfileMode`); bản phát hành không in gì, không đổi gì người dùng thấy.
/// Không dùng `reportFullyDrawn` của Android: `FlutterActivity` đã tự gọi nó ở khung hình Flutter đầu tiên
/// (lúc còn màn chờ), nên mốc "tới Hôm nay có dữ liệu" là log `today_ready`.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';

abstract final class PerfProbe {
  static final Stopwatch _sinceMain = Stopwatch();
  static bool _todayReady = false;
  static final List<FrameTiming> _frames = [];
  static bool _collecting = false;

  /// Gọi đầu `main()`: mốc 0 của các `mark`, bắt đầu thu thời gian khung hình (bản profile).
  static void start() {
    _sinceMain.start();
    if (kProfileMode && !_collecting) {
      _collecting = true;
      SchedulerBinding.instance.addTimingsCallback(_frames.addAll);
    }
    mark('main_start');
  }

  /// Ghi một mốc: số ms tính từ đầu `main()`.
  static void mark(String name) {
    if (kProfileMode) debugPrint('WW_PERF mark $name ${_sinceMain.elapsedMilliseconds}');
  }

  /// Đo thời gian chạy của [body] và ghi `WW_PERF step <name> <ms>`.
  static Future<T> step<T>(String name, Future<T> Function() body) async {
    if (!kProfileMode) return body();
    final sw = Stopwatch()..start();
    try {
      return await body();
    } finally {
      debugPrint('WW_PERF step $name ${sw.elapsedMilliseconds}');
    }
  }

  /// Ghi mốc `today_ready` sau khung hình kế tiếp (màn Hôm nay đã có dữ liệu); chỉ lần đầu, chỉ bản profile.
  static void markTodayReadyAfterNextFrame() {
    if (!kProfileMode || _todayReady) return;
    _todayReady = true;
    SchedulerBinding.instance.addPostFrameCallback((_) => mark('today_ready'));
    SchedulerBinding.instance.scheduleFrame();
  }

  /// In thống kê khung hình thu được từ lần in trước rồi xóa (bản profile). Gọi khi app vào nền.
  static void dumpFrameStats(String label) {
    if (!kProfileMode || _frames.isEmpty) return;
    final build = _frames.map((f) => f.buildDuration.inMicroseconds).toList()..sort();
    final raster = _frames.map((f) => f.rasterDuration.inMicroseconds).toList()..sort();
    int pct(List<int> v, double p) => v[((v.length - 1) * p).round()];
    debugPrint(
      'WW_PERF frames $label n=${_frames.length} '
      'build_p50=${pct(build, .5)} build_p90=${pct(build, .9)} build_p99=${pct(build, .99)} '
      'raster_p50=${pct(raster, .5)} raster_p90=${pct(raster, .9)} raster_p99=${pct(raster, .99)}',
    );
    _frames.clear();
  }
}
