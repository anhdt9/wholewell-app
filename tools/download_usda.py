#!/usr/bin/env python3
"""Tải và kiểm toàn vẹn bộ dữ liệu USDA FoodData Central + FPED vào tools/.cache/."""
import pathlib
import subprocess
import zipfile

CACHE = pathlib.Path(__file__).resolve().parent / ".cache"
CACHE.mkdir(parents=True, exist_ok=True)

URLS = {
    "foundation.zip": ("zip", "https://fdc.nal.usda.gov/fdc-datasets/FoodData_Central_foundation_food_json_2026-10-29.zip"),
    "sr_legacy.zip": ("zip", "https://fdc.nal.usda.gov/fdc-datasets/FoodData_Central_sr_legacy_food_json_2018-04.zip"),
    "fndds.zip": ("zip", "https://fdc.nal.usda.gov/fdc-datasets/FoodData_Central_survey_food_json_2024-10-31.zip"),
    "FPED_2123.xls": ("xls", "https://www.ars.usda.gov/ARSUserFiles/80400530/apps/FPED_2123.xls"),
}


def valid_file(kind: str, path: pathlib.Path) -> bool:
    if not path.exists() or path.stat().st_size < 1000:
        return False
    if kind == "zip":
        try:
            with zipfile.ZipFile(path) as zf:
                return zf.testzip() is None and len(zf.namelist()) > 0
        except Exception:
            return False
    if kind == "xls":
        with open(path, "rb") as f:
            sig = f.read(4)
        return sig in (b"\xd0\xcf\x11\xe0", b"PK\x03\x04", b"<?xm", b"<htm", b"<HTM")
    return True


def download(kind: str, url: str, dest: pathlib.Path):
    if valid_file(kind, dest):
        print(f"valid cache {dest.name} ({dest.stat().st_size} B)", flush=True)
        return
    if dest.exists():
        print(f"removing invalid/incomplete {dest.name} ({dest.stat().st_size} B)", flush=True)
        dest.unlink()
    tmp = dest.with_suffix(dest.suffix + ".part")
    if tmp.exists():
        tmp.unlink()
    print(f"downloading {url} -> {dest.name} ...", flush=True)
    subprocess.run(
        ["curl", "-fL", "--retry", "3", "--connect-timeout", "20", "--max-time", "300",
         "-A", "Mozilla/5.0", "-o", str(tmp), url],
        check=True,
    )
    tmp.replace(dest)
    if not valid_file(kind, dest):
        raise RuntimeError(f"Tệp tải về bị hỏng: {dest}")
    print(f"done {dest.name} ({dest.stat().st_size} B)", flush=True)


def main():
    for name, (kind, url) in URLS.items():
        download(kind, url, CACHE / name)


if __name__ == "__main__":
    main()
