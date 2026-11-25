#!/usr/bin/env python3
"""Đóng gói USDA FoodData Central + FPED + công thức món Việt thành tệp SQLite chỉ đọc có FTS5.

Chạy: python tools/build_food_library.py
Đầu ra:
  - app/assets/food_library.db
  - app/assets/food_library_manifest.json (sha256, library_version, thống kê dung lượng)
"""
import hashlib
import json
import pathlib
import re
import sqlite3
import unicodedata
import zipfile
import zlib

import xlrd

ROOT = pathlib.Path(__file__).resolve().parent.parent
CACHE = pathlib.Path(__file__).resolve().parent / ".cache"
DATA = pathlib.Path(__file__).resolve().parent / "data"
PACK_PATH = ROOT / "packages/health_engine/assets/reference_pack.json"
RECIPES_PATH = DATA / "vn_recipes.json"
OUT_DB = ROOT / "app/assets/food_library.db"
OUT_MANIFEST = ROOT / "app/assets/food_library_manifest.json"

LIBRARY_VERSION = "2026.11.25-1"
BUILT_AT = "2026-11-25"
USDA_RELEASE = "FDC Foundation 2026-10 / SR Legacy 2018-04 / FNDDS 2021-2023"
FPED_RELEASE = "FPED 2021-2023"

VIET_MAP = str.maketrans(
    "àáảãạăằắẳẵặâầấẩẫậđèéẻẽẹêềếểễệìíỉĩịòóỏõọôồốổỗộơờớởỡợùúủũụưừứửữựỳýỷỹỵ"
    "ÀÁẢÃẠĂẰẮẲẴẶÂẦẤẨẪẬĐÈÉẺẼẸÊỀẾỂỄỆÌÍỈĨỊÒÓỎÕỌÔỒỐỔỖỘƠỜỚỞỠỢÙÚỦŨỤƯỪỨỬỮỰỲÝỶỸỴ",
    "aaaaaaaaaaaaaaaaadeeeeeeeeeeeiiiiiooooooooooooooooouuuuuuuuuuuyyyyy"
    "AAAAAAAAAAAAAAAAADEEEEEEEEEEEIIIIIOOOOOOOOOOOOOOOOOUUUUUUUUUUUYYYYY",
)

# Từ điển ánh xạ một số thực phẩm phổ biến (fdcId -> (name_vi, aliases_vi)) để người Việt tìm nhanh.
COMMON_VI_NAMES = {
    168935: ("Cơm gạo tẻ trắng", "com trang gao te"),
    169711: ("Xôi nếp trắng (chín)", "xoi nep gao nep"),
    168914: ("Bún / phở tươi chín", "bun tuoi banh pho mi gao"),
    172675: ("Bánh mì Pháp / ổ mì", "banh mi khong o banh mi"),
    2646175: ("Thịt bò nạc (thăn/bắp sống)", "thit bo song"),
    2646174: ("Thịt bò vai (sống)", "thit bo vai"),
    167819: ("Thịt heo thăn nạc (nấu/om)", "thit lon nac thit heo"),
    167812: ("Thịt heo ba chỉ (sống)", "thit ba chi ba roi"),
    2514745: ("Thịt heo xay (sống)", "thit lon xay thit bam"),
    171075: ("Ức gà nướng (cả da)", "thit ga uc ga"),
    172385: ("Đùi gà (sống)", "dui ga"),
    172409: ("Thịt vịt quay/nướng", "thit vit quay"),
    323604: ("Trứng gà tươi (tách vỏ)", "trung ga"),
    173424: ("Trứng gà luộc chín", "trung luoc"),
    172448: ("Đậu phụ (đậu hũ) cứng", "dau phu dau hu"),
    746782: ("Sữa tươi nguyên kem (bổ sung vitamin D)", "sua tuoi co duong khong duong"),
    1999630: ("Sữa đậu nành không đường", "sua dau nanh"),
    2257044: ("Sữa đậu nành có đường", "sua dau nanh"),
    171275: ("Sữa đặc có đường", "sua dac"),
    171994: ("Cá thu nướng/áp chảo", "ca thu"),
    2684442: ("Cá rô phi (sống)", "ca ro phi"),
    2684443: ("Tôm sú / tôm thẻ (sống)", "tom tuoi"),
    174223: ("Mực ống (sống)", "muc tuoi"),
    168517: ("Cải thìa (cải chíp) luộc", "rau cai thia cai chip"),
    169257: ("Cải xanh (cải bẹ) luộc", "rau cai xanh"),
    168463: ("Rau chân vịt (bó xôi) luộc", "rau chan vit bo xoi"),
    747447: ("Bông cải xanh (súp lơ xanh)", "bong cai xanh sup lo"),
    169975: ("Bắp cải trắng (sống)", "bap cai"),
    170050: ("Cà chua chín (nấu)", "ca chua"),
    2258586: ("Cà rốt tươi", "ca rot"),
    2346406: ("Dưa chuột (dưa leo) tươi", "dua chuot dua leo"),
    790577: ("Hành tây tím/tây tươi", "hanh tay"),
    1104647: ("Tỏi tươi", "toi"),
    169231: ("Gừng tươi", "gung"),
    169997: ("Rau mùi (ngò rí) tươi", "rau mui ngo ri"),
    169137: ("Giá đỗ xanh luộc", "gia do"),
    173944: ("Chuối chín tươi", "chuoi"),
    169910: ("Xoài chín tươi", "xoai"),
    171705: ("Quả bơ tươi", "bo qua bo"),
    746771: ("Cam vàng tươi", "cam"),
    169926: ("Đu đủ chín tươi", "du du"),
    167765: ("Dưa hấu tươi", "dua hau"),
    2346398: ("Dứa (thơm) tươi", "dua thom khom"),
    173806: ("Lạc (đậu phộng) rang không muối", "lac dau phong"),
    174256: ("Đậu xanh hạt khô", "dau xanh do xanh"),
    746784: ("Đường cát trắng", "duong cat trang"),
    171881: ("Cà phê đen pha sẵn", "ca phe den"),
    2706457: ("Nước mắm", "nuoc mam"),
    172473: ("Xì dầu (nước tương) ít muối", "xi dau nuoc tuong"),
    2346401: ("Khoai tây tươi gọt vỏ", "khoai tay"),
    2346404: ("Khoai lang ruột cam tươi", "khoai lang"),
    2710826: ("Ngô (bắp) ngọt tươi", "ngo ngot bap ngot"),
    746769: ("Xà lách tươi", "rau xa lach"),
    1999629: ("Nấm mỡ trắng", "nam"),
    2512380: ("Gạo lứt hạt dài", "gao lut"),
}

# Các nhóm USDA được coi là nguyên liệu thô/tươi không pha trộn (Câu hỏi đã chốt 1).
RAW_SAFE_CATEGORIES = {
    "Beef Products",
    "Cereal Grains and Pasta",
    "Finfish and Shellfish Products",
    "Fruits and Fruit Juices",
    "Lamb, Veal, and Game Products",
    "Legumes and Legume Products",
    "Nut and Seed Products",
    "Pork Products",
    "Poultry Products",
    "Spices and Herbs",
    "Vegetables and Vegetable Products",
    "Fats and Oils",
    "Dairy and Egg Products",
}

PROCESSED_WORDS_RE = re.compile(
    r"\b(sweetened|sugar|syrup|honey|glazed|candy|chocolate|flavored|vanilla|"
    r"strawberry|blueberry|teriyaki|barbecue|marinated|breaded|battered|ice cream|"
    r"pudding|yogurt|jam|jelly|pie|cookie|cake|cracker|sauce|dressing|cereal|"
    r"condensed|mix|beverage|drink|smoothie|juice drink|nectar|jam|preserves|"
    r"spread|frosting|dessert|pastry|donut|muffin|pancake|waffle)\b",
    re.I,
)


def norm_ascii(text: str) -> str:
    s = (text or "").translate(VIET_MAP).lower()
    s = unicodedata.normalize("NFKD", s)
    s = "".join(ch for ch in s if unicodedata.category(ch) != "Mn")
    return " ".join(re.findall(r"[a-z0-9]+", s))


def is_raw_zero_added_sugar(desc: str, category: str) -> bool:
    if category not in RAW_SAFE_CATEGORIES:
        return False
    if PROCESSED_WORDS_RE.search(desc):
        return False
    # Sữa có hương vị hoặc sữa đặc đã bị lọc bởi regex trên; riêng dairy chỉ nhận milk plain/egg/butter/cheese nguyên chất.
    if category == "Dairy and Egg Products":
        dl = desc.lower()
        if any(w in dl for w in ("with added sugar", "chocolate", "eggnog", "malted")):
            return False
    if category == "Fruits and Fruit Juices":
        dl = desc.lower()
        if any(w in dl for w in ("heavy syrup", "light syrup", "sweetened", "candied", "maraschino")):
            return False
    return True


def load_fped_map() -> dict[int, float]:
    wb = xlrd.open_workbook(str(CACHE / "FPED_2123.xls"))
    sh = wb.sheet_by_index(0)
    headers = [str(h).strip() for h in sh.row_values(0)]
    fc_idx = next(i for i, h in enumerate(headers) if h.upper().startswith("FOODCODE"))
    as_idx = next(i for i, h in enumerate(headers) if "ADD_SUGARS" in h.upper())
    out = {}
    for r in range(1, sh.nrows):
        fc = sh.cell_value(r, fc_idx)
        val = sh.cell_value(r, as_idx)
        if fc:
            out[int(float(fc))] = float(val or 0.0)
    return out


# Ánh xạ USDA nutrient.id -> (nutrient_id_trong_pack, unit, scale)
DIRECT_NUTRIENT_MAP = {
    1003: ("protein", "g", 1.0),
    1079: ("fiber", "g", 1.0),
    1087: ("calcium", "mg", 1.0),
    1089: ("iron", "mg", 1.0),
    1090: ("magnesium", "mg", 1.0),
    1091: ("phosphorus", "mg", 1.0),
    1092: ("potassium", "mg", 1.0),
    1093: ("sodium", "mg", 1.0),
    1095: ("zinc", "mg", 1.0),
    1098: ("copper", "ug", 1000.0),  # USDA ghi mg; gói chuẩn WholeWell dùng ug!
    1100: ("iodine", "ug", 1.0),
    1101: ("manganese", "mg", 1.0),
    1102: ("molybdenum", "ug", 1.0),
    1103: ("selenium", "ug", 1.0),
    1105: ("retinol", "ug_RAE", 1.0),
    1106: ("vitA", "ug_RAE", 1.0),
    1114: ("vitD", "ug", 1.0),
    1162: ("vitC", "mg", 1.0),
    1165: ("thiamin", "mg", 1.0),
    1166: ("riboflavin", "mg", 1.0),
    1167: ("niacin", "mg_NE", 1.0),
    1170: ("pantothenic", "mg", 1.0),
    1175: ("vitB6", "mg", 1.0),
    1176: ("biotin", "ug", 1.0),
    1178: ("vitB12", "ug", 1.0),
    1180: ("choline", "mg", 1.0),
    1185: ("vitK", "ug", 1.0),
}


def has_rrr_footnote(food_obj: dict, nut_obj: dict | None = None) -> bool:
    texts = [food_obj.get("footnote") or ""]
    if nut_obj:
        texts.append(nut_obj.get("footnote") or "")
    for fn in food_obj.get("foodNutrients", []):
        if (fn.get("nutrient") or {}).get("id") in (1109, 1242):
            texts.append(fn.get("footnote") or "")
    joined = " ".join(str(t) for t in texts).lower()
    return ("rrr" in joined or "d-alpha" in joined) and "all rac" not in joined


def extract_nutrients(food_obj: dict, added_sugar_g: float | None) -> tuple[list[tuple], bool, bool]:
    """Trả ([(nutrient_id, source, form, amount, ul_amount, unit)], niacin_unsep, folate_unsep)."""
    by_id: dict[int, tuple[float, dict]] = {}
    for fn in food_obj.get("foodNutrients", []):
        n = fn.get("nutrient") or {}
        nid = n.get("id")
        amt = fn.get("amount")
        if nid is not None and amt is not None:
            by_id[int(nid)] = (float(amt), fn)

    rows = []

    def add_first(ids, key, unit):
        for nid in ids:
            if nid in by_id:
                v = by_id[nid][0]
                if v > 0:
                    rows.append((key, "food", None, v, None, unit))
                return

    add_first((1008, 2048, 2047), "energyKcal", "kcal")
    add_first((1004, 1085), "fat", "g")
    add_first((1005, 1050), "carbohydrate", "g")
    add_first((2000, 1063), "totalSugar", "g")
    add_first((1316, 1269), "linoleic", "g")
    add_first((1404, 1270), "ala", "g")

    if added_sugar_g is not None:
        rows.append(("addedSugar", "food", None, round(added_sugar_g, 4), None, "g"))

    niacin_unsep = False
    for usda_id, (pack_id, unit, scale) in DIRECT_NUTRIENT_MAP.items():
        if usda_id not in by_id:
            continue
        val = by_id[usda_id][0] * scale
        if val <= 0 and pack_id != "fiber":
            continue
        if pack_id == "niacin" and val > 0:
            niacin_unsep = True
        form = "retinol" if pack_id == "retinol" else None
        if val > 0:
            rows.append((pack_id, "food", form, val, None, unit))

    # Folate: 1186/1187 (SR Legacy, FNDDS) hoặc fallback 1177 (Foundation & fallback SR Legacy)
    folate_unsep = False
    val_fa = by_id[1186][0] if 1186 in by_id else None
    val_ff = by_id[1187][0] if 1187 in by_id else None
    val_ftot = by_id[1177][0] if 1177 in by_id else None
    if val_fa is not None or val_ff is not None:
        if (val_fa or 0.0) > 0:
            rows.append(("folicAcid", "fortified", "folic_acid", val_fa, None, "ug"))
        if (val_ff or 0.0) > 0:
            rows.append(("folate", "food", "natural_folate", val_ff, None, "ug_DFE"))
    elif val_ftot is not None and val_ftot > 0:
        rows.append(("folate", "food", None, val_ftot, None, "ug_DFE"))
        folate_unsep = True

    # Vitamin E: 1242 (fortified, ul_amount * 2 trừ ngoại lệ RRR) & phần tự nhiên max(0, 1109 - 1242)
    val_e_tot = by_id[1109][0] if 1109 in by_id else 0.0
    val_e_add = by_id[1242][0] if 1242 in by_id else 0.0
    if val_e_add > 0:
        if has_rrr_footnote(food_obj, by_id.get(1242, (0, {}))[1]):
            rows.append(("vitE", "fortified", "natural_2r", val_e_add, None, "mg"))
        else:
            rows.append(("vitE", "fortified", "synthetic_2r", val_e_add, val_e_add * 2.0, "mg"))
        nat_e = max(0.0, val_e_tot - val_e_add)
        if nat_e > 0:
            rows.append(("vitE", "food", None, nat_e, None, "mg"))
    elif val_e_tot > 0:
        rows.append(("vitE", "food", None, val_e_tot, None, "mg"))

    return rows, niacin_unsep, folate_unsep


def extract_portions(food_id: str, food_obj: dict) -> tuple[list[tuple], str | None]:
    portions = []
    seen_labels = set()
    for idx, fp in enumerate(food_obj.get("foodPortions", [])):
        grams = fp.get("gramWeight")
        if not grams or grams <= 0:
            continue
        desc = (fp.get("portionDescription") or "").strip()
        if not desc:
            amt = fp.get("amount") or fp.get("value")
            mu = (fp.get("measureUnit") or {}).get("name") or ""
            mod = (fp.get("modifier") or "").strip()
            parts = []
            if amt and float(amt) != 1.0:
                parts.append(f"{float(amt):g}")
            elif amt:
                parts.append("1")
            if mu and mu.lower() != "undetermined":
                parts.append(mu)
            if mod and mod != "90000":
                parts.append(f"({mod})")
            desc = " ".join(parts).strip()
        if not desc or "quantity not specified" in desc.lower():
            continue
        if desc.lower() in seen_labels:
            continue
        seen_labels.add(desc.lower())
        pid = f"{food_id}:p{idx}"
        portions.append((pid, food_id, desc, float(grams)))
        if len(portions) >= 5:
            break
    default_id = portions[0][0] if portions else None
    return portions, default_id


def build_recipe_record(rec: dict, by_fdc: dict[int, list[tuple]]):
    total_grams = sum(ing["grams"] for ing in rec["ingredients"])
    acc: dict[tuple, float] = {}  # (nutrient_id, source, form, unit) -> amount per 100g dish
    ul_acc: dict[tuple, float] = {}
    has_unsep_niacin = False
    has_unsep_folate = False

    for ing in rec["ingredients"]:
        fid = f"usda:{ing['fdcId']}"
        if fid not in by_fdc:
            raise KeyError(f"Công thức {rec['slug']} thiếu nguyên liệu fdcId={ing['fdcId']}")
        weight = ing["grams"] / total_grams
        for nid, src, form, amt, ul_amt, unit in by_fdc[fid]:
            key = (nid, src, form, unit)
            acc[key] = acc.get(key, 0.0) + amt * weight
            if ul_amt is not None:
                ul_acc[key] = ul_acc.get(key, 0.0) + ul_amt * weight

    food_id = f"recipe:{rec['slug']}"
    portions = []
    default_pid = None
    for p in rec["portions"]:
        portions.append((p["id"], food_id, p["label_vi"], float(p["grams"])))
        if p.get("default"):
            default_pid = p["id"]
    if default_pid is None and portions:
        default_pid = portions[0][0]

    search_blob = norm_ascii(f"{rec['name_vi']} {rec.get('aliases_vi', '')} {rec.get('name_en', '')}")
    food_row = (
        food_id,
        "recipe",
        rec["name_vi"],
        rec.get("name_en"),
        rec.get("aliases_vi"),
        search_blob,
        1,  # is_estimate
        1,  # added_sugar_known (mọi thành phần đường/nguyên liệu trong công thức đều rõ)
        1 if has_unsep_niacin else 0,
        1 if has_unsep_folate else 0,
        default_pid,
    )
    nut_rows = []
    # Bảo đảm luôn có addedSugar nếu mọi nguyên liệu không có đường thêm
    if not any(k[0] == "addedSugar" for k in acc):
        acc[("addedSugar", "food", None, "g")] = 0.0
    for (nid, src, form, unit), amt in acc.items():
        ul_v = ul_acc.get((nid, src, form, unit))
        nut_rows.append((food_id, nid, src, form, round(amt, 5), None if ul_v is None else round(ul_v, 5), unit))
    return food_row, portions, nut_rows


def load_dataset(zip_name: str) -> list[dict]:
    with zipfile.ZipFile(CACHE / zip_name) as zf:
        raw = json.loads(zf.read(zf.namelist()[0]).decode("utf-8"))
        return next(iter(raw.values()))


SR_DROP_CATEGORIES = {
    "American Indian/Alaska Native Foods",
    "Baby Foods",
    "Fast Foods",
    "Meals, Entrees, and Side Dishes",
    "Restaurant Foods",
    "Snacks",
    "Sweets",
}


def _short_stem(desc: str) -> str:
    parts = [p.strip() for p in desc.split(",")]
    return norm_ascii(" ".join(parts[:2]))


def is_brand_or_redundant_sr(desc: str, category: str, seen_stems: set[str]) -> bool:
    if category in SR_DROP_CATEGORIES:
        return True
    # Bỏ các món mang tên hãng/thương hiệu Mỹ viết hoa (vd. KELLOGG'S, CAMPBELL'S)
    if re.search(r"\b[A-Z]{4,}(?:'S)?\b", desc) and not re.search(r"\b(USDA|NLEA)\b", desc):
        return True
    dl = desc.lower()
    # Bỏ hàng trăm biến thể cắt thịt Mỹ trùng lặp (choice/select/prime/trimmed to...)
    if category in ("Beef Products", "Pork Products", "Lamb, Veal, and Game Products"):
        if any(k in dl for k in ("trimmed to", "choice,", "select,", "prime,", "separable lean only")):
            return True
    # Bỏ SR Legacy trùng nhóm 2 vế đầu với Foundation/FNDDS (ưu tiên Foundation/FNDDS vì có tách folate & FPED)
    if _short_stem(desc) in seen_stems:
        return True
    return False


def build_db(include_all_sr: bool = True) -> tuple[int, int, int]:
    pack = json.loads(PACK_PATH.read_text(encoding="utf-8"))
    fped = load_fped_map()
    recipes = json.loads(RECIPES_PATH.read_text(encoding="utf-8"))
    recipe_fdc_ids = {ing["fdcId"] for r in recipes for ing in r["ingredients"]}

    foundation = load_dataset("foundation.zip")
    sr_legacy = load_dataset("sr_legacy.zip")
    fndds = load_dataset("fndds.zip")

    seen_norm_names = set()
    seen_stems = set()
    foods_rows = []
    portions_rows = []
    nutrient_rows = []
    by_fdc_nuts: dict[str, list[tuple]] = {}

    def process_item(kind: str, obj: dict, force_keep: bool = False):
        fdc_id = int(obj["fdcId"])
        if kind == "usda_fndds" and int(obj.get("foodCode") or 0) == 11000000:
            return
        desc = (obj.get("description") or "").strip()
        if not desc or not obj.get("foodNutrients"):
            return

        if kind == "usda_sr" and not include_all_sr and not force_keep:
            cat_sr = (obj.get("foodCategory") or {}).get("description", "")
            if is_brand_or_redundant_sr(desc, cat_sr, seen_stems) or norm_ascii(desc) in seen_norm_names:
                return

        if kind == "usda_fndds":
            fc = int(obj["foodCode"])
            tsp = fped.get(fc)
            added_sugar_g = tsp * 4.2 if tsp is not None else None
            added_sugar_known = 1 if tsp is not None else 0
            cat = (obj.get("wweiaFoodCategory") or {}).get("wweiaFoodCategoryDescription", "")
        else:
            cat = (obj.get("foodCategory") or {}).get("description", "")
            if is_raw_zero_added_sugar(desc, cat):
                added_sugar_g = 0.0
                added_sugar_known = 1
            else:
                added_sugar_g = None
                added_sugar_known = 0

        nuts, niacin_unsep, folate_unsep = extract_nutrients(obj, added_sugar_g)
        if not nuts:
            return

        food_id = f"usda:{fdc_id}"
        by_fdc_nuts[food_id] = nuts
        vi_name, aliases_vi = COMMON_VI_NAMES.get(fdc_id, (desc, None))
        # Chỉ đưa tên tiếng Việt không dấu vào search_ascii; name_en đã được FTS5 đánh chỉ mục riêng.
        search_ascii = norm_ascii(f"{vi_name} {aliases_vi or ''}")
        seen_norm_names.add(norm_ascii(desc))
        seen_stems.add(_short_stem(desc))

        p_rows, def_pid = extract_portions(food_id, obj)
        foods_rows.append((
            food_id,
            kind,
            vi_name,
            desc,
            aliases_vi,
            search_ascii,
            0,  # is_estimate
            added_sugar_known,
            1 if niacin_unsep else 0,
            1 if folate_unsep else 0,
            def_pid,
        ))
        portions_rows.extend(p_rows)
        for nid, src, form, amt, ul_amt, unit in nuts:
            nutrient_rows.append((food_id, nid, src, form, round(amt, 5), None if ul_amt is None else round(ul_amt, 5), unit))

    # Ưu tiên Foundation + FNDDS (có tách 1186/1187 và FPED), rồi SR Legacy
    for obj in foundation:
        process_item("usda_foundation", obj, force_keep=True)
    for obj in fndds:
        process_item("usda_fndds", obj, force_keep=True)
    for obj in sr_legacy:
        fid = int(obj["fdcId"])
        process_item("usda_sr", obj, force_keep=(fid in recipe_fdc_ids or fid in COMMON_VI_NAMES))

    # Công thức món Việt
    for rec in recipes:
        f_row, p_rows, n_rows = build_recipe_record(rec, by_fdc_nuts)
        foods_rows.append(f_row)
        portions_rows.extend(p_rows)
        nutrient_rows.extend(n_rows)

    OUT_DB.parent.mkdir(parents=True, exist_ok=True)
    if OUT_DB.exists():
        OUT_DB.unlink()

    conn = sqlite3.connect(str(OUT_DB))
    cur = conn.cursor()
    cur.executescript(
        """
        CREATE TABLE meta (
          library_version TEXT NOT NULL,
          usda_release TEXT NOT NULL,
          fped_release TEXT NOT NULL,
          built_at TEXT NOT NULL,
          pack_version TEXT NOT NULL
        );
        CREATE TABLE foods (
          id TEXT PRIMARY KEY,
          kind TEXT NOT NULL,
          name_vi TEXT NOT NULL,
          name_en TEXT,
          aliases_vi TEXT,
          search_ascii TEXT NOT NULL,
          is_estimate INTEGER NOT NULL,
          added_sugar_known INTEGER NOT NULL,
          niacin_fortified_unseparated INTEGER NOT NULL,
          folate_unseparated INTEGER NOT NULL,
          default_portion_id TEXT
        );
        CREATE TABLE food_portions (
          id TEXT PRIMARY KEY,
          food_id TEXT NOT NULL,
          label_vi TEXT NOT NULL,
          grams REAL NOT NULL
        );
        CREATE TABLE food_nutrients_per_100g (
          food_id TEXT NOT NULL,
          nutrient_id TEXT NOT NULL,
          source TEXT NOT NULL,
          form TEXT,
          amount REAL NOT NULL,
          ul_amount REAL,
          unit TEXT NOT NULL
        );
        CREATE INDEX idx_portions_food ON food_portions (food_id);
        CREATE INDEX idx_nutrients_food ON food_nutrients_per_100g (food_id);
        CREATE VIRTUAL TABLE foods_fts USING fts5(
          name_vi,
          aliases_vi,
          search_ascii,
          name_en,
          content='foods',
          content_rowid='rowid'
        );
        """
    )
    cur.execute(
        "INSERT INTO meta VALUES (?, ?, ?, ?, ?)",
        (LIBRARY_VERSION, USDA_RELEASE, FPED_RELEASE, BUILT_AT, pack["version"]),
    )
    cur.executemany("INSERT INTO foods VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)", foods_rows)
    cur.executemany("INSERT INTO food_portions VALUES (?, ?, ?, ?)", portions_rows)
    cur.executemany("INSERT INTO food_nutrients_per_100g VALUES (?, ?, ?, ?, ?, ?, ?)", nutrient_rows)
    cur.execute("INSERT INTO foods_fts(foods_fts) VALUES ('rebuild')")
    conn.commit()
    cur.execute("VACUUM")
    conn.close()
    return len(foods_rows), len(portions_rows), len(nutrient_rows)


def main():
    n_foods, n_portions, n_nuts = build_db(include_all_sr=True)
    raw_bytes = OUT_DB.read_bytes()
    zlib_bytes = len(zlib.compress(raw_bytes, level=9))
    print(f"Full build: {n_foods} món, {n_portions} khẩu phần, {n_nuts} dòng chất | "
          f"raw={len(raw_bytes)/1048576:.2f} MB, zlib={zlib_bytes/1048576:.2f} MB")

    if zlib_bytes > 4 * 1024 * 1024:
        print("Vượt ngưỡng nén 4 MB → lọc SR Legacy trùng tên chuẩn với Foundation/FNDDS...")
        n_foods, n_portions, n_nuts = build_db(include_all_sr=False)
        raw_bytes = OUT_DB.read_bytes()
        zlib_bytes = len(zlib.compress(raw_bytes, level=9))
        print(f"Filtered build: {n_foods} món, {n_portions} khẩu phần, {n_nuts} dòng chất | "
              f"raw={len(raw_bytes)/1048576:.2f} MB, zlib={zlib_bytes/1048576:.2f} MB")

    sha = hashlib.sha256(raw_bytes).hexdigest()
    manifest = {
        "libraryVersion": LIBRARY_VERSION,
        "sha256": sha,
        "usdaRelease": USDA_RELEASE,
        "fpedRelease": FPED_RELEASE,
        "builtAt": BUILT_AT,
        "foodCount": n_foods,
        "portionCount": n_portions,
        "nutrientRowCount": n_nuts,
        "rawBytes": len(raw_bytes),
        "compressedApproxBytes": zlib_bytes,
    }
    OUT_MANIFEST.write_text(json.dumps(manifest, ensure_ascii=False, indent=2), encoding="utf-8")
    print(f"Manifest written: sha256={sha}")


if __name__ == "__main__":
    main()
