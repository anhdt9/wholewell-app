#!/usr/bin/env python3
"""Đóng gói cơ sở dữ liệu NIH DSLD (chỉ On Market + có mã vạch hợp lệ) thành SQLite chỉ đọc nén gzip.

Chạy: python tools/build_dsld.py
Đầu vào: tools/.cache/dsld/csv/DSLD-full-database-CSV/*.csv
Đầu ra:
  - app/assets/dsld_library.db.gz
  - app/assets/dsld_library_manifest.json
"""
import csv
import gzip
import hashlib
import json
import pathlib
import re
import sqlite3

ROOT = pathlib.Path(__file__).resolve().parent.parent
CACHE_DSLD = pathlib.Path(__file__).resolve().parent / ".cache" / "dsld"
CSV_DIR = CACHE_DSLD / "csv" / "DSLD-full-database-CSV"
TMP_DB = CACHE_DSLD / "dsld_library.db"
OUT_GZ = ROOT / "app/assets/dsld_library.db.gz"
OUT_MANIFEST = ROOT / "app/assets/dsld_library_manifest.json"

LIBRARY_VERSION = "2026.01.16-1"
DSLD_RELEASE = "NIH DSLD Bulk CSV 2026-01-16 (On Market + Valid Barcode)"
BUILT_AT = "2026-11-26"


def sha256_file(path: pathlib.Path) -> str:
    h = hashlib.sha256()
    with path.open("rb") as f:
        for chunk in iter(lambda: f.read(1024 * 1024), b""):
            h.update(chunk)
    return h.hexdigest()


def normalize_barcode(raw: str) -> str:
    return re.sub(r"\D", "", raw.strip())


def build() -> None:
    if not CSV_DIR.exists():
        raise SystemExit(
            f"Không tìm thấy thư mục CSV tại {CSV_DIR}. "
            "Hãy tải và giải nén DSLD-full-database-CSV.zip trước."
        )

    overview_files = sorted(CSV_DIR.glob("ProductOverview_*.csv"))
    facts_files = sorted(CSV_DIR.glob("DietarySupplementFacts_*.csv"))
    other_files = sorted(CSV_DIR.glob("OtherIngredients_*.csv"))
    if not overview_files or not facts_files or not other_files:
        raise SystemExit(f"Thiếu tệp CSV trong {CSV_DIR}")

    valid_ids: set[str] = set()
    products_rows: list[tuple[int, str, str, str, str, str, str, str, str]] = []

    for p in overview_files:
        with p.open("r", encoding="utf-8-sig", newline="") as f:
            for row in csv.DictReader(f):
                if row["Market Status"].strip().lower() != "on market":
                    continue
                digits = normalize_barcode(row["Bar Code"])
                if not (8 <= len(digits) <= 14):
                    continue
                dsld_id_str = row["DSLD ID"].strip()
                valid_ids.add(dsld_id_str)
                products_rows.append((
                    int(dsld_id_str),
                    digits,
                    row["Product Name"].strip(),
                    row["Brand Name"].strip(),
                    row["Serving Size"].strip(),
                    row["Supplement Form [LanguaL]"].strip(),
                    row["Net Contents"].strip(),
                    row["Suggested Use"].strip(),
                    "",
                ))

    other_map: dict[int, str] = {}
    for p in other_files:
        with p.open("r", encoding="utf-8-sig", newline="") as f:
            for row in csv.DictReader(f):
                dsld_id_str = row["DSLD ID"].strip()
                if dsld_id_str in valid_ids:
                    txt = row["Other Ingredients"].strip()
                    if txt:
                        other_map[int(dsld_id_str)] = txt

    products_rows = [
        r[:8] + (other_map.get(r[0], ""),)
        for r in products_rows
    ]

    facts_rows: list[tuple[int, str, str, str, str, str, str]] = []
    for p in facts_files:
        with p.open("r", encoding="utf-8-sig", newline="") as f:
            for row in csv.DictReader(f):
                dsld_id_str = row["DSLD ID"].strip()
                if dsld_id_str not in valid_ids:
                    continue
                facts_rows.append((
                    int(dsld_id_str),
                    row["Ingredient"].strip(),
                    row["DSLD Ingredient Categories"].strip(),
                    row["Amount Per Serving"].strip(),
                    row["Amount Per Serving Unit"].strip(),
                    row["% Daily Value per Serving"].strip(),
                    row["Daily Value Target Group"].strip(),
                ))

    if TMP_DB.exists():
        TMP_DB.unlink()
    TMP_DB.parent.mkdir(parents=True, exist_ok=True)

    conn = sqlite3.connect(TMP_DB)
    cur = conn.cursor()
    cur.execute("PRAGMA journal_mode=OFF;")
    cur.execute("PRAGMA synchronous=OFF;")

    cur.execute("""
        CREATE TABLE meta (
            library_version TEXT NOT NULL,
            dsld_release TEXT NOT NULL,
            built_at TEXT NOT NULL,
            product_count INTEGER NOT NULL,
            fact_count INTEGER NOT NULL
        );
    """)
    cur.execute(
        "INSERT INTO meta VALUES (?,?,?,?,?)",
        (LIBRARY_VERSION, DSLD_RELEASE, BUILT_AT, len(products_rows), len(facts_rows)),
    )

    cur.execute("""
        CREATE TABLE products (
            dsld_id INTEGER PRIMARY KEY,
            barcode TEXT NOT NULL,
            product_name TEXT NOT NULL,
            brand_name TEXT NOT NULL,
            serving_size TEXT NOT NULL,
            supplement_form TEXT NOT NULL,
            net_contents TEXT NOT NULL,
            suggested_use TEXT NOT NULL,
            other_ingredients TEXT NOT NULL DEFAULT ''
        );
    """)
    cur.executemany(
        "INSERT INTO products VALUES (?,?,?,?,?,?,?,?,?)",
        products_rows,
    )

    cur.execute("""
        CREATE TABLE facts (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            dsld_id INTEGER NOT NULL,
            ingredient TEXT NOT NULL,
            category TEXT NOT NULL,
            amount TEXT NOT NULL,
            unit TEXT NOT NULL,
            dv_percent TEXT NOT NULL,
            dv_group TEXT NOT NULL
        );
    """)
    cur.executemany(
        "INSERT INTO facts (dsld_id, ingredient, category, amount, unit, dv_percent, dv_group) VALUES (?,?,?,?,?,?,?)",
        facts_rows,
    )

    cur.execute("CREATE INDEX idx_products_barcode ON products(barcode);")
    cur.execute("CREATE INDEX idx_facts_dsld_id ON facts(dsld_id);")
    cur.execute(
        "CREATE VIRTUAL TABLE products_fts USING fts5("
        "product_name, brand_name, content='products', content_rowid='dsld_id');"
    )
    cur.execute("INSERT INTO products_fts(products_fts) VALUES('rebuild');")
    conn.commit()
    cur.execute("VACUUM;")
    conn.close()

    OUT_GZ.parent.mkdir(parents=True, exist_ok=True)
    with TMP_DB.open("rb") as src, OUT_GZ.open("wb") as raw_out:
        with gzip.GzipFile(filename="", mode="wb", compresslevel=9, fileobj=raw_out, mtime=0) as dst:
            for chunk in iter(lambda: src.read(1024 * 1024), b""):
                dst.write(chunk)

    db_sha = sha256_file(TMP_DB)
    gz_sha = sha256_file(OUT_GZ)
    db_bytes = TMP_DB.stat().st_size
    gz_bytes = OUT_GZ.stat().st_size

    manifest = {
        "libraryVersion": LIBRARY_VERSION,
        "dsldRelease": DSLD_RELEASE,
        "builtAt": BUILT_AT,
        "productCount": len(products_rows),
        "factCount": len(facts_rows),
        "dbSha256": db_sha,
        "gzSha256": gz_sha,
        "dbBytes": db_bytes,
        "gzBytes": gz_bytes,
    }
    OUT_MANIFEST.write_text(json.dumps(manifest, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")

    print(f"Built {TMP_DB} ({db_bytes:,} bytes, sha256={db_sha})")
    print(f"Compressed {OUT_GZ} ({gz_bytes:,} bytes, sha256={gz_sha})")
    print(f"Products: {len(products_rows):,}, Facts: {len(facts_rows):,}")


if __name__ == "__main__":
    build()
