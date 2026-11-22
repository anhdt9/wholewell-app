#!/usr/bin/env python3
"""Bản tham chiếu bằng Python của engine Dart, viết độc lập để kiểm chéo.

1. Tự kiểm tra với vài phép tính tay.
2. Sinh packages/health_engine/test/fixtures/cases.json: đầu vào + kết quả mong đợi.
   Bộ test Dart đọc file này, nên logic Dart phải cho đúng kết quả của bản Python.

Chạy: python3 tools/reference_engine.py
"""
import json
import pathlib
import sys

# Console Windows mặc định cp1252, không in được tiếng Việt.
sys.stdout.reconfigure(encoding="utf-8")

ROOT = pathlib.Path(__file__).resolve().parent.parent
PACK = json.loads((ROOT / "packages/health_engine/assets/reference_pack.json").read_text(encoding="utf-8"))
NUT = {n["id"]: n for n in PACK["nutrients"]}
ACT = {a["code"]: a["met"] for a in PACK["activities"]}


def group(p):
    age = p["age"]
    if age < 14:
        raise ValueError("ageUnsupported")
    stage = p.get("stage", "none")
    if stage in ("pregnant", "lactating"):
        pre = "p" if stage == "pregnant" else "l"
        return f"{pre}14_18" if age <= 18 else (f"{pre}19_30" if age <= 30 else f"{pre}31_50")
    s = "m" if p["sex"] == "male" else "f"
    if age <= 18:
        return f"{s}14_18"
    if age <= 30:
        return f"{s}19_30"
    if age <= 50:
        return f"{s}31_50"
    if age <= 70:
        return f"{s}51_70"
    return f"{s}71"


def target(p, nid):
    d = NUT[nid]
    if d["kind"] == "NONE":
        return None
    if nid == "protein" and p["age"] >= 19 and p.get("stage", "none") == "none":
        return round(PACK["proteinPerKg"]["adult19"] * p["weight"] * 10) / 10
    return d["target"].get(group(p))


def tee(c, p, week=0):
    return c["a"] + c["age"] * p["age"] + c["height"] * p["height"] + c["weight"] * p["weight"] + c.get("gestWeek", 0) * week


def eer(p):
    e = PACK["eer"]
    if p["age"] < e["minAge"]:
        return None, "eerUnderAge19"
    lvl = p.get("level", "inactive")
    stage = p.get("stage", "none")
    if stage == "none":
        k = tee(e["adult"][p["sex"]][lvl], p)
    elif stage == "pregnant":
        w = p.get("gestWeek")
        if w is None:
            return None, "missingGestationWeek"
        if w <= e["pregnancyFirstTrimesterMaxWeek"]:
            k = tee(e["adult"]["female"][lvl], p)
        else:
            if p.get("bmi") is None:
                return None, "missingPrePregnancyBmi"
            k = tee(e["pregnancy"][lvl], p, w) + e["pregnancyDeposition"][p["bmi"]]
    else:
        base = tee(e["adult"]["female"][lvl], p)
        m = p.get("monthsPostpartum", 0)
        if m <= 6:
            k = base + e["lactation"]["0_6"]["milk"] - e["lactation"]["0_6"]["mobilization"]
        elif m <= 12:
            k = base + e["lactation"]["7_12"]["milk"] - e["lactation"]["7_12"]["mobilization"]
        else:
            k = base
    # Dart .round(): làm tròn nửa ra xa số 0
    return int(k + 0.5) if k >= 0 else -int(-k + 0.5), None


def amount_for_ul(d, items):
    key = d.get("ulKey") or d["id"]
    s = 0.0
    for it in items:
        src = it["source"]
        ok = {"total": True, "supplement": src == "supplement",
              "synthetic": src in ("supplement", "fortified")}[d["ulScope"]]
        if ok:
            s += it["n"].get(key, 0)
    return s


def ul_flags(p, days):
    g = group(p)
    out = []
    for d in PACK["nutrients"]:
        if d.get("ulKey"):
            continue
        ul = d["ul"].get(g)
        if ul is None:
            continue
        a = sum(amount_for_ul(d, day) for day in days) / len(days)
        if a > ul:
            out.append({"id": d["id"], "amount": round(a * 100) / 100, "ul": ul})
    out.sort(key=lambda f: -f["amount"] / f["ul"])
    return out


def macros(p, day):
    amdr = PACK["amdr"]["adult19" if p["age"] >= 19 else "age4_18"]
    g = {m: sum(it["n"].get(m, 0) for it in day) for m in ("protein", "fat", "carbohydrate")}
    k = {m: g[m] * PACK["energyPerGram"][m] for m in g}
    tot = sum(k.values())
    res = {}
    for m in ("protein", "fat", "carbohydrate"):
        pct = 0 if tot == 0 else k[m] / tot * 100
        lo, hi = amdr[m]
        res[m] = {"pct": pct, "status": "below" if pct < lo else ("above" if pct > hi else "within")}
    return res


def sugar(day):
    s = sum(it["n"].get("addedSugar", 0) for it in day)
    e = sum(it["n"].get("energyKcal", 0) for it in day)
    if e <= 0:
        e = sum(it["n"].get("protein", 0) * 4 + it["n"].get("carbohydrate", 0) * 4 + it["n"].get("fat", 0) * 9 for it in day)
    pct = 0 if e <= 0 else s * 4 / e * 100
    meals = {}
    for it in day:
        if it.get("meal"):
            meals[it["meal"]] = meals.get(it["meal"], 0) + it["n"].get("addedSugar", 0)
    over = {m: g for m, g in meals.items() if g > PACK["addedSugar"]["maxGramsPerMeal"]}
    return {"pct": pct, "overDaily": pct > PACK["addedSugar"]["maxPercentEnergyPerDay"], "mealsOver": sorted(over)}


def workout_kcal(p, code, minutes):
    return ACT[code] * p["weight"] * minutes / 60


def suggest_level(ws, days=7):
    mod = vig = 0.0
    for code, minutes in ws:
        met = ACT[code]
        if met >= PACK["pag"]["vigorousMinMet"]:
            vig += minutes
        elif met >= PACK["pag"]["moderateMinMet"]:
            mod += minutes
    per = (mod + 2 * vig) / days
    t = PACK["palSuggestion"]["moderateEquivalentMinPerDay"]
    if per >= t["veryActive"]:
        return "veryActive"
    if per >= t["active"]:
        return "active"
    if per >= t["lowActive"]:
        return "lowActive"
    return "inactive"


# ------------------------------------------------------------ tự kiểm bằng tay
def self_check():
    man = {"age": 30, "sex": "male", "height": 170, "weight": 65, "level": "inactive"}
    # 753.07 - 10.83*30 + 6.50*170 + 14.10*65 = 753.07 - 324.9 + 1105 + 916.5 = 2449.67
    assert eer(man) == (2450, None), eer(man)
    woman = {"age": 25, "sex": "female", "height": 158, "weight": 52, "level": "active"}
    # 710.25 - 175.25 + 1033.32 + 641.68 = 2210.0
    assert eer(woman) == (2210, None), eer(woman)
    lac = dict(woman, stage="lactating", monthsPostpartum=3)
    assert eer(lac) == (2610, None)
    assert target(man, "protein") == 52.0
    assert target(man, "iron") == 8
    assert abs(workout_kcal({"weight": 60}, "12050", 30) - 279) < 1e-9
    assert group({"age": 18, "sex": "female"}) == "f14_18"
    print("tự kiểm: OK")


# ------------------------------------------------------------ fixtures
def it(source, n, meal=None, label="x"):
    d = {"label": label, "source": source, "n": n}
    if meal:
        d["meal"] = meal
    return d


PROFILES = {
    "man30": {"age": 30, "sex": "male", "height": 170, "weight": 65, "level": "inactive"},
    "man45_active": {"age": 45, "sex": "male", "height": 175, "weight": 78, "level": "active"},
    "man72_very": {"age": 72, "sex": "male", "height": 165, "weight": 60, "level": "veryActive"},
    "woman25_low": {"age": 25, "sex": "female", "height": 158, "weight": 52, "level": "lowActive"},
    "woman55": {"age": 55, "sex": "female", "height": 155, "weight": 58, "level": "inactive"},
    "woman18": {"age": 18, "sex": "female", "height": 156, "weight": 48, "level": "inactive"},
    "preg_t1": {"age": 29, "sex": "female", "height": 160, "weight": 55, "level": "inactive",
                "stage": "pregnant", "gestWeek": 10},
    "preg_t2": {"age": 29, "sex": "female", "height": 160, "weight": 58, "level": "lowActive",
                "stage": "pregnant", "gestWeek": 24, "bmi": "normal"},
    "preg_t3_obese": {"age": 34, "sex": "female", "height": 162, "weight": 85, "level": "inactive",
                      "stage": "pregnant", "gestWeek": 32, "bmi": "obese"},
    "preg_nobmi": {"age": 29, "sex": "female", "height": 160, "weight": 58, "level": "inactive",
                   "stage": "pregnant", "gestWeek": 20},
    "lact_4m": {"age": 31, "sex": "female", "height": 157, "weight": 56, "level": "inactive",
                "stage": "lactating", "monthsPostpartum": 4},
    "lact_9m": {"age": 31, "sex": "female", "height": 157, "weight": 56, "level": "active",
                "stage": "lactating", "monthsPostpartum": 9},
}

DAYS = {
    "balanced": [
        it("food", {"energyKcal": 550, "protein": 25, "fat": 15, "carbohydrate": 78, "addedSugar": 4,
                    "vitC": 30, "iron": 3, "calcium": 200}, "breakfast"),
        it("food", {"energyKcal": 750, "protein": 35, "fat": 22, "carbohydrate": 100, "addedSugar": 6,
                    "vitC": 40, "iron": 5, "calcium": 300}, "lunch"),
        it("food", {"energyKcal": 650, "protein": 30, "fat": 20, "carbohydrate": 88, "addedSugar": 3,
                    "vitC": 25, "iron": 4, "calcium": 250}, "dinner"),
    ],
    "sweet_fatty": [
        it("food", {"energyKcal": 900, "protein": 15, "fat": 50, "carbohydrate": 95, "addedSugar": 40}, "snack"),
        it("food", {"energyKcal": 800, "protein": 30, "fat": 40, "carbohydrate": 80, "addedSugar": 8}, "lunch"),
    ],
    "supplements_heavy": [
        it("food", {"energyKcal": 1800, "protein": 70, "fat": 60, "carbohydrate": 240,
                    "magnesium": 300, "niacin": 20, "retinol": 400, "vitA": 700, "zinc": 9, "vitD": 3}),
        it("supplement", {"magnesium": 400, "niacin": 50, "vitD": 125, "zinc": 30, "retinol": 3000, "vitA": 3000}),
        it("fortified", {"niacin": 5, "folicAcid": 200, "folate": 340}),
    ],
    "fortified_folic": [
        it("food", {"energyKcal": 2000, "protein": 80, "fat": 65, "carbohydrate": 270, "folate": 300}),
        it("fortified", {"folicAcid": 600, "folate": 1020}),
        it("supplement", {"folicAcid": 500, "folate": 850}),
    ],
}

WORKOUT_SETS = {
    "none": [],
    "light": [("17190", 20), ("17190", 20), ("17190", 20)],
    "moderate": [("17200", 45)] * 7,
    "mixed": [("12050", 40), ("12050", 40), ("12050", 40), ("17200", 60), ("17200", 60), ("15030", 60)],
    "athlete": [("12090", 60)] * 7 + [("02050", 60)] * 3,
}


def main():
    self_check()
    cases = {"profiles": PROFILES, "days": DAYS, "workoutSets": WORKOUT_SETS,
             "expect": {"eer": {}, "group": {}, "targets": {}, "ulDay": {}, "macros": {}, "sugar": {},
                        "ulAvg": {}, "suggest": {}, "workoutKcal": {}}}
    ex = cases["expect"]
    for name, p in PROFILES.items():
        k, why = eer(p)
        ex["eer"][name] = {"kcal": k, "reason": why}
        ex["group"][name] = group(p)
        ex["targets"][name] = {nid: target(p, nid) for nid in
                               ("protein", "iron", "calcium", "vitD", "folate", "fiber", "potassium", "vitK", "magnesium")}
        for dname, day in DAYS.items():
            ex["ulDay"][f"{name}|{dname}"] = ul_flags(p, [day])
            ex["macros"][f"{name}|{dname}"] = macros(p, day)
        ex["workoutKcal"][name] = workout_kcal(p, "12050", 30)
    for dname, day in DAYS.items():
        ex["sugar"][dname] = sugar(day)
    # trung bình 7 ngày: 1 ngày nhiều bổ sung + 6 ngày cân bằng
    week = [DAYS["supplements_heavy"]] + [DAYS["balanced"]] * 6
    ex["ulAvg"]["man30|1heavy6balanced"] = ul_flags(PROFILES["man30"], week)
    for wname, ws in WORKOUT_SETS.items():
        ex["suggest"][wname] = suggest_level(ws)
    out = ROOT / "packages/health_engine/test/fixtures/cases.json"
    out.parent.mkdir(parents=True, exist_ok=True)
    out.write_text(json.dumps(cases, ensure_ascii=False, indent=1), encoding="utf-8")
    print(f"wrote {out}")
    # in vài kết quả để người đọc kiểm
    for n in ("man30", "woman25_low", "preg_t2", "preg_t3_obese", "lact_4m", "woman18", "preg_nobmi"):
        print(f"  EER {n}: {ex['eer'][n]}")
    print("  UL man30|supplements_heavy:", ex["ulDay"]["man30|supplements_heavy"])
    print("  UL woman25|fortified_folic:", ex["ulDay"]["woman25_low|fortified_folic"])
    print("  UL avg:", ex["ulAvg"]["man30|1heavy6balanced"])
    print("  sugar:", ex["sugar"])
    print("  suggest:", ex["suggest"])
    print("  macros man30|sweet_fatty:", ex["macros"]["man30|sweet_fatty"])


if __name__ == "__main__":
    main()
