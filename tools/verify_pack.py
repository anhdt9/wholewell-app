#!/usr/bin/env python3
"""Kiểm tra gói dữ liệu: cấu trúc + đối chiếu ô mẫu với bảng gốc NASEM, FDA, PAG.

Các ô "GOLDEN" dưới đây được nhập lại độc lập từ nguồn gốc (lần nhập thứ hai),
để bắt lỗi gõ nhầm trong build_pack.py.
Chạy: python3 tools/verify_pack.py  (thoát mã 1 nếu có lỗi)
"""
import json
import pathlib
import sys

if hasattr(sys.stdout, "reconfigure"):
    sys.stdout.reconfigure(encoding="utf-8")

PACK = pathlib.Path(__file__).resolve().parent.parent / "packages/health_engine/assets/reference_pack.json"
p = json.loads(PACK.read_text(encoding="utf-8"))
errors = []


def err(msg):
    errors.append(msg)


if p.get("schema") != 2:
    err(f"schema {p.get('schema')} != 2")
if not (isinstance(p.get("minProfileAge"), int) and p["minProfileAge"] >= 1):
    err(f"minProfileAge không hợp lệ: {p.get('minProfileAge')}")

N = {n["id"]: n for n in p["nutrients"]}
groups_meta = p["groups"]
groups = [g["id"] for g in groups_meta]
src_ids = {s["id"] for s in p["sources"]}
amdr_keys = {k for k in p["amdr"] if k != "source"}

# ---- cấu trúc nhóm tuổi
if len(groups) != len(set(groups)):
    err("trùng id nhóm")
by_ss = {}
for g in groups_meta:
    if g["sex"] not in ("male", "female", None):
        err(f"{g['id']}: sex lạ {g['sex']}")
    if g["stage"] not in ("none", "pregnant", "lactating"):
        err(f"{g['id']}: stage lạ {g['stage']}")
    if g["amdrKey"] not in amdr_keys:
        err(f"{g['id']}: amdrKey {g['amdrKey']} không có trong amdr")
    if g["eerType"] not in ("none", "adult", "pregnant", "lactating"):
        err(f"{g['id']}: eerType lạ {g['eerType']}")
    if g["proteinPerKg"] is not None and not (isinstance(g["proteinPerKg"], (int, float)) and g["proteinPerKg"] > 0):
        err(f"{g['id']}: proteinPerKg không hợp lệ")
    if not isinstance(g["minAge"], int) or g["minAge"] < 0:
        err(f"{g['id']}: minAge không hợp lệ")
    if g["maxAge"] is not None and (not isinstance(g["maxAge"], int) or g["maxAge"] < g["minAge"]):
        err(f"{g['id']}: maxAge < minAge")
    by_ss.setdefault((g["sex"], g["stage"]), []).append(g)

for key, lst in by_ss.items():
    lst.sort(key=lambda x: x["minAge"])
    for i in range(len(lst) - 1):
        cur, nxt = lst[i], lst[i + 1]
        if cur["maxAge"] is None or nxt["minAge"] != cur["maxAge"] + 1:
            err(f"nhóm {key}: khoảng tuổi hở hoặc chồng giữa {cur['id']} và {nxt['id']}")
    if lst[-1]["maxAge"] is not None:
        err(f"nhóm {key}: nhóm cuối {lst[-1]['id']} phải có maxAge = null")

# ---- cấu trúc chất dinh dưỡng
if len(N) != len(p["nutrients"]):
    err("trùng id chất")
for n in p["nutrients"]:
    if n["source"] not in src_ids:
        err(f"{n['id']}: nguồn không tồn tại")
    if n["kind"] in ("RDA", "AI"):
        missing = [g for g in groups if g not in n["target"]]
        if missing:
            err(f"{n['id']}: thiếu mục tiêu cho {missing}")
    for g, v in n["target"].items():
        if not (isinstance(v, (int, float)) and v > 0):
            err(f"{n['id']}/{g}: mục tiêu không hợp lệ {v}")
        ul = n["ul"].get(g)
        # UL so với dạng bổ sung (magie) hoặc khóa khác thì không so trực tiếp
        if ul is not None and n["ulScope"] == "total" and not n.get("ulKey") and ul < v:
            err(f"{n['id']}/{g}: UL {ul} < mục tiêu {v}")
    if n.get("ulKey") and n["ulKey"] not in N:
        err(f"{n['id']}: ulKey {n['ulKey']} không có")
    if n["ulScope"] not in ("total", "supplement", "synthetic"):
        err(f"{n['id']}: ulScope lạ")

# ---- quy đổi đơn vị & nguồn
uc = p["unitConversions"]
for sk in ("source", "ulSource", "ulCrossRefSource"):
    if uc.get(sk) not in src_ids:
        err(f"unitConversions.{sk} không có trong sources")
if uc.get("vitE_ul_natural_IU_to_mg") != 0.67:
    err(f"vitE_ul_natural_IU_to_mg sai: {uc.get('vitE_ul_natural_IU_to_mg')}")
if abs(uc.get("vitE_ul_synthetic_IU_to_mg", 0) - 1000 / 1100) > 1e-12:
    err(f"vitE_ul_synthetic_IU_to_mg sai: {uc.get('vitE_ul_synthetic_IU_to_mg')}")
if not isinstance(uc.get("vitaminEEsters"), dict) or not isinstance(uc.get("compounds"), dict):
    err("vitaminEEsters và compounds phải là dict")

# ---- vận động & PAG
pag = p["pag"]
if pag.get("source") not in src_ids:
    err("pag.source không có trong sources")
if pag.get("weeklyModerateMin") != [150, 300] or pag.get("weeklyVigorousMin") != [75, 150]:
    err(f"PAG weekly min sai: {pag}")
if pag.get("strengthDaysPerWeek") != 2:
    err(f"PAG strengthDaysPerWeek sai: {pag.get('strengthDaysPerWeek')}")

codes = [a["code"] for a in p["activities"]]
if len(codes) != len(set(codes)):
    err("trùng mã hoạt động")
for a in p["activities"]:
    if not (1.0 <= a["met"] <= 25):
        err(f"MET lạ {a}")
    if not isinstance(a.get("muscleStrengthening"), bool):
        err(f"hoạt động thiếu muscleStrengthening bool: {a}")
    if a.get("source") not in src_ids:
        err(f"hoạt động nguồn lạ: {a}")

# ---- GOLDEN: nhập lại từ bảng NASEM (tóm tắt DRI, 25353 ch.28)
GOLDEN_TARGET = {
    ("vitA", "m19_30"): 900, ("vitA", "f31_50"): 700, ("vitA", "p19_30"): 770, ("vitA", "l31_50"): 1300,
    ("vitA", "p14_18"): 750, ("vitA", "l14_18"): 1200,
    ("vitC", "m51_70"): 90, ("vitC", "f71"): 75, ("vitC", "p31_50"): 85, ("vitC", "l19_30"): 120, ("vitC", "f14_18"): 65,
    ("vitD", "m71"): 20, ("vitD", "f51_70"): 15,
    ("vitE", "l19_30"): 19, ("vitK", "m31_50"): 120, ("vitK", "f19_30"): 90, ("vitK", "m14_18"): 75,
    ("thiamin", "f51_70"): 1.1, ("riboflavin", "l31_50"): 1.6, ("niacin", "p19_30"): 18, ("niacin", "l19_30"): 17,
    ("vitB6", "m51_70"): 1.7, ("vitB6", "f71"): 1.5, ("vitB6", "l19_30"): 2.0,
    ("folate", "p31_50"): 600, ("folate", "l19_30"): 500, ("vitB12", "l31_50"): 2.8,
    ("pantothenic", "l19_30"): 7, ("biotin", "l31_50"): 35, ("choline", "f19_30"): 425, ("choline", "f14_18"): 400,
    ("calcium", "m71"): 1200, ("calcium", "f51_70"): 1200, ("calcium", "m51_70"): 1000, ("calcium", "m14_18"): 1300,
    ("chromium", "f51_70"): 20, ("chromium", "l19_30"): 45, ("copper", "l19_30"): 1300,
    ("iodine", "l31_50"): 290, ("iron", "f19_30"): 18, ("iron", "f51_70"): 8, ("iron", "p31_50"): 27, ("iron", "l19_30"): 9,
    ("iron", "f14_18"): 15, ("iron", "l14_18"): 10,
    ("magnesium", "m19_30"): 400, ("magnesium", "m31_50"): 420, ("magnesium", "f19_30"): 310, ("magnesium", "p31_50"): 360,
    ("manganese", "l31_50"): 2.6, ("molybdenum", "p19_30"): 50, ("phosphorus", "f14_18"): 1250,
    ("selenium", "l19_30"): 70, ("zinc", "f31_50"): 8, ("zinc", "l19_30"): 12, ("zinc", "l14_18"): 13,
    ("potassium", "m19_30"): 3400, ("potassium", "f19_30"): 2600, ("potassium", "p19_30"): 2900, ("potassium", "l31_50"): 2800,
    ("sodium", "f71"): 1500, ("chloride", "m71"): 1800, ("chloride", "f51_70"): 2000,
    ("water", "m19_30"): 3.7, ("water", "l19_30"): 3.8, ("fiber", "m51_70"): 30, ("fiber", "f51_70"): 21,
    ("carbohydrate", "l19_30"): 210, ("protein", "m19_30"): 56, ("protein", "p31_50"): 71,
    ("linoleic", "m51_70"): 14, ("ala", "p19_30"): 1.4,
}
GOLDEN_UL = {
    ("vitA", "m19_30"): 3000, ("vitA", "f14_18"): 2800, ("vitC", "l31_50"): 2000, ("vitD", "f71"): 100,
    ("vitE", "m31_50"): 1000, ("niacin", "p19_30"): 35, ("vitB6", "m71"): 100, ("folate", "l19_30"): 1000,
    ("choline", "m19_30"): 3500, ("calcium", "f31_50"): 2500, ("calcium", "m51_70"): 2000, ("calcium", "f14_18"): 3000,
    ("copper", "m19_30"): 10000, ("iodine", "f19_30"): 1100, ("iron", "p19_30"): 45, ("magnesium", "m71"): 350,
    ("manganese", "f31_50"): 11, ("molybdenum", "m51_70"): 2000, ("phosphorus", "m71"): 3000,
    ("phosphorus", "p31_50"): 3500, ("phosphorus", "l19_30"): 4000, ("selenium", "f19_30"): 400, ("zinc", "m19_30"): 40,
    ("zinc", "m14_18"): 34, ("chloride", "f71"): 3600, ("boron", "m19_30"): 20, ("nickel", "f19_30"): 1.0,
    ("vanadium", "m19_30"): 1.8, ("retinol", "p19_30"): 3000, ("folicAcid", "m19_30"): 1000,
}
for (nid, g), v in GOLDEN_TARGET.items():
    got = N[nid]["target"].get(g)
    if got != v:
        err(f"GOLDEN mục tiêu {nid}/{g}: {got} != {v}")
for (nid, g), v in GOLDEN_UL.items():
    got = N[nid]["ul"].get(g)
    if got != v:
        err(f"GOLDEN UL {nid}/{g}: {got} != {v}")
for nid in ("vitK", "thiamin", "riboflavin", "vitB12", "pantothenic", "biotin", "potassium", "sodium", "chromium"):
    if N[nid]["ul"]:
        err(f"{nid} không có UL theo NASEM nhưng gói lại có")
for nid in ("vanadium",):
    if "p19_30" in N[nid]["ul"] or "l19_30" in N[nid]["ul"] or "m14_18" in N[nid]["ul"]:
        err("vanadi không có UL ở 14-18, mang thai, cho con bú")
if N["magnesium"]["ulScope"] != "supplement":
    err("UL magie phải chỉ tính nguồn bổ sung")
for nid in ("niacin", "vitE"):
    if N[nid]["ulScope"] != "synthetic":
        err(f"UL {nid} phải tính dạng tổng hợp")
if N["vitA"]["ulKey"] != "retinol" or N["folate"]["ulKey"] != "folicAcid":
    err("UL vitamin A/folate phải so với retinol/axit folic")

# ---- EER (NASEM 2023, bảng 5-5, 5-17)
e = p["eer"]
if e["adult"]["male"]["veryActive"] != {"a": -517.88, "age": -10.83, "height": 15.61, "weight": 19.11}:
    err("EER nam rất năng động sai")
if e["adult"]["female"]["active"] != {"a": 710.25, "age": -7.01, "height": 6.54, "weight": 12.34}:
    err("EER nữ năng động sai")
if e["pregnancy"]["lowActive"]["a"] != 693.35 or e["pregnancy"]["active"]["gestWeek"] != 9.16:
    err("EER mang thai sai")
if e["lactation"]["0_6"] != {"milk": 540, "mobilization": 140}:
    err("EER cho con bú sai")
if p["amdr"]["adult19"] != {"protein": [10, 35], "fat": [20, 35], "carbohydrate": [45, 65]}:
    err("AMDR sai")
if p["addedSugar"] != {"source": "dga_2025_2030", "maxGramsPerMeal": 10}:
    err("giới hạn đường bổ sung sai")

acts = {a["code"]: a for a in p["activities"]}
for code, met in {"12050": 9.3, "17200": 4.8, "01030": 8.0, "15030": 5.5, "18240": 5.8, "02214": 11.0}.items():
    if acts.get(code, {}).get("met") != met:
        err(f"MET {code} sai")

GOLDEN_STRENGTH = {
    "02054": True, "02050": True, "02024": True, "02022": True,
    "02020": True, "02035": True, "02040": True,
    "02160": False, "02105": False, "02150": False, "02101": False,
    "12050": False, "17200": False,
}
for code, want in GOLDEN_STRENGTH.items():
    if acts.get(code, {}).get("muscleStrengthening") is not want:
        err(f"muscleStrengthening {code} sai")

if errors:
    print("LỖI:")
    for x in errors:
        print(" -", x)
    sys.exit(1)
print(f"OK: schema {p['schema']}, {len(N)} chất, {len(groups)} nhóm, {len(acts)} hoạt động; "
      f"{len(GOLDEN_TARGET)} ô mục tiêu, {len(GOLDEN_UL)} ô UL và {len(GOLDEN_STRENGTH)} cờ tăng cơ khớp")
