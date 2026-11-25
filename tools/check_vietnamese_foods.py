#!/usr/bin/env python3
"""Kiểm sớm 200 thực phẩm phổ biến ở Việt Nam + 34 công thức + danh sách món chỉ có ở Việt Nam.

Kiểm tra khả năng tra cứu FTS5 trong app/assets/food_library.db và hiệu năng truy vấn.
"""
import json
import pathlib
import sqlite3
import time

ROOT = pathlib.Path(__file__).resolve().parent.parent
DB_PATH = ROOT / "app/assets/food_library.db"
RECIPES_PATH = ROOT / "tools/data/vn_recipes.json"
VN_ONLY_PATH = ROOT / "tools/data/vn_only_foods.json"

# 200 truy vấn thực phẩm phổ biến người Việt hay tìm (34 món công thức + nguyên liệu & món USDA).
QUERIES_200 = [
    # 34 công thức món Việt
    "pho bo", "pho ga", "com trang", "com tam", "com ga", "bun cha", "bun bo",
    "bun thit nuong", "mien ga", "hu tieu", "banh mi thit", "banh mi op la",
    "xoi dau xanh", "chao thit bam", "chao ga", "thit kho trung", "ca kho",
    "ca hap", "dau phu sot ca chua", "dau phu ran", "trung chien", "trung hap",
    "tom rim", "muc xao", "thit bo xao", "ga rang gung", "canh cai", "canh chua",
    "rau cai xao", "goi cuon", "ca phe sua", "sinh to bo", "che dau xanh", "banh cuon",
    # Ngũ cốc, tinh bột, bánh
    "gao lut", "gao te", "xoi nep", "bun tuoi", "banh mi", "rice white",
    "rice brown", "oats", "quinoa", "pasta", "spaghetti", "bread whole wheat",
    "potato", "sweet potato", "corn", "cornstarch", "wheat flour", "rice noodles",
    "macaroni", "bagel", "croissant", "tortilla", "pancake", "waffle", "cracker",
    "biscuit", "cereal", "granola", "barley", "millet", "buckwheat",
    # Thịt, gia cầm, trứng
    "thit bo", "thit heo", "thit ba chi", "thit heo xay", "uc ga", "dui ga",
    "thit vit", "trung ga", "trung luoc", "beef steak", "beef ground", "beef liver",
    "pork chop", "pork tenderloin", "pork sausage", "bacon", "ham",
    "chicken breast", "chicken thigh", "chicken wing", "chicken liver", "turkey",
    "duck", "lamb", "egg whole", "egg white", "egg yolk", "egg scrambled",
    # Cá, hải sản
    "ca thu", "ca ro phi", "tom tuoi", "muc tuoi", "salmon", "tuna", "mackerel",
    "tilapia", "cod", "catfish", "shrimp", "crab", "lobster", "oyster", "clam",
    "mussel", "squid", "sardine", "anchovy", "herring", "trout",
    # Đậu, hạt, sữa, đồ uống
    "dau phu", "sua tuoi", "sua dau nanh", "sua dac", "lac rang", "dau xanh",
    "tofu", "soy milk", "milk whole", "milk skim", "yogurt plain", "yogurt greek",
    "cheese cheddar", "cheese mozzarella", "butter", "cream cheese", "almond",
    "walnut", "cashew", "peanut", "chia seed", "flaxseed", "sesame", "sunflower seed",
    "black beans", "kidney beans", "chickpeas", "lentils", "edamame", "tempeh",
    # Rau củ
    "cai thia", "cai xanh", "rau chan vit", "bong cai xanh", "bap cai", "ca chua",
    "ca rot", "dua leo", "hanh tay", "toi", "gung", "rau mui", "gia do",
    "khoai tay", "khoai lang", "ngo ngot", "xa lach", "nam",
    "spinach", "broccoli", "cauliflower", "cabbage", "kale", "carrot", "tomato",
    "cucumber", "onion", "garlic", "bell pepper", "eggplant", "zucchini",
    "pumpkin", "asparagus", "green beans", "celery", "radish", "mushroom",
    "avocado", "olive",
    # Trái cây
    "chuoi", "xoai", "qua bo", "cam", "du du", "dua hau", "dua thom",
    "apple", "banana", "orange", "mango", "papaya", "watermelon", "pineapple",
    "strawberry", "blueberry", "grape", "kiwi", "pear", "peach", "plum",
    "lemon", "lime", "grapefruit", "guava", "lychee", "dragon fruit",
    # Gia vị, dầu, đồ ngọt, đồ uống
    "duong cat", "ca phe den", "nuoc mam", "xi dau",
    "olive oil", "soybean oil", "coconut oil", "coconut milk", "honey",
    "sugar", "dark chocolate", "green tea", "coffee brewed", "orange juice",
]


def safe_match(q: str) -> str:
    return " ".join(f'"{t}"*' for t in q.lower().split() if t)


def main():
    assert DB_PATH.exists(), f"Thiếu {DB_PATH}"
    conn = sqlite3.connect(f"file:{DB_PATH}?mode=ro", uri=True)
    cur = conn.cursor()

    recipes = json.loads(RECIPES_PATH.read_text(encoding="utf-8"))
    vn_only = json.loads(VN_ONLY_PATH.read_text(encoding="utf-8"))

    # Kiểm mọi công thức có đủ dinh dưỡng, is_estimate=1, added_sugar_known=1
    for r in recipes:
        fid = f"recipe:{r['slug']}"
        row = cur.execute(
            "SELECT is_estimate, added_sugar_known FROM foods WHERE id = ?", (fid,)
        ).fetchone()
        assert row == (1, 1), f"{fid} sai cờ: {row}"

    unique_q = list(dict.fromkeys(QUERIES_200))
    matched = 0
    missed = []
    t0 = time.perf_counter()
    for q in unique_q:
        hits = cur.execute(
            "SELECT f.id, f.name_vi FROM foods_fts JOIN foods f ON f.rowid = foods_fts.rowid "
            "WHERE foods_fts MATCH ? LIMIT 5",
            (safe_match(q),),
        ).fetchall()
        if hits:
            matched += 1
        else:
            missed.append(q)
    elapsed_ms = (time.perf_counter() - t0) * 1000
    avg_ms = elapsed_ms / len(unique_q)

    # Kiểm dữ liệu tách nguồn trong food_library.db
    vit_e_fort = cur.execute(
        "SELECT food_id, amount, ul_amount FROM food_nutrients_per_100g "
        "WHERE nutrient_id='vitE' AND source='fortified' AND ul_amount IS NOT NULL LIMIT 1"
    ).fetchone()
    assert vit_e_fort is not None and abs(vit_e_fort[2] - 2 * vit_e_fort[1]) < 1e-6, vit_e_fort
    folic = cur.execute(
        "SELECT food_id, amount FROM food_nutrients_per_100g WHERE nutrient_id='folicAcid' LIMIT 1"
    ).fetchone()
    assert folic is not None and folic[1] > 0, folic
    fped_row = cur.execute(
        "SELECT f.id, n.amount FROM foods f JOIN food_nutrients_per_100g n ON f.id=n.food_id "
        "WHERE f.kind='usda_fndds' AND n.nutrient_id='addedSugar' AND n.amount>0 LIMIT 1"
    ).fetchone()
    assert fped_row is not None and fped_row[1] > 0, fped_row
    sr_unsep = cur.execute(
        "SELECT count(*) FROM foods WHERE folate_unseparated=1"
    ).fetchone()[0]
    assert sr_unsep > 0
    recipe_unsep = cur.execute(
        "SELECT count(*) FROM foods WHERE kind='recipe' AND (niacin_fortified_unseparated=1 OR folate_unseparated=1)"
    ).fetchone()[0]
    assert recipe_unsep > 0, "Công thức món Việt dùng nguyên liệu có niacin/folate chưa tách phải kế thừa cờ"

    print(f"Công thức Việt: {len(recipes)} (có cờ chưa tách nguồn: {recipe_unsep}) | Món chỉ có ở VN (chưa có công thức): {len(vn_only)}")
    print(f"Tách nguồn OK: vitE_fort={vit_e_fort[0]}, folicAcid={folic[0]}, FPED_addedSugar={fped_row[0]}, folate_unseparated={sr_unsep}")
    print(f"Kiểm khớp {len(unique_q)} thực phẩm: {matched}/{len(unique_q)} khớp | TB {avg_ms:.2f} ms/truy vấn")
    if missed:
        print("Không khớp:", missed)
    conn.close()


if __name__ == "__main__":
    main()
