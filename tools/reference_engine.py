#!/usr/bin/env python3
"""Bản tham chiếu bằng Python của engine Dart, viết độc lập để kiểm chéo.

1. Tự kiểm tra với vài phép tính tay.
2. Sinh packages/health_engine/test/fixtures/cases.json: đầu vào + kết quả mong đợi.
   Bộ test Dart đọc file này, nên logic Dart phải cho đúng kết quả của bản Python.

Chạy: python3 tools/reference_engine.py
"""
from datetime import datetime
import json
import pathlib
import sys

if hasattr(sys.stdout, "reconfigure"):
    sys.stdout.reconfigure(encoding="utf-8")

ROOT = pathlib.Path(__file__).resolve().parent.parent
PACK = json.loads((ROOT / "packages/health_engine/assets/reference_pack.json").read_text(encoding="utf-8"))

ESTER_ORIGINS = {
    "d_alpha_tocopheryl_acetate": "natural",
    "dl_alpha_tocopheryl_acetate": "synthetic",
    "d_alpha_tocopheryl_succinate": "natural",
    "dl_alpha_tocopheryl_succinate": "synthetic",
}

METRIC_FACTOR_TO_UG = {"g": 1_000_000.0, "mg": 1_000.0, "ug": 1.0}


def _nut_map(pack):
    return {n["id"]: n for n in pack["nutrients"]}


def _act_map(pack):
    return {a["code"]: a for a in pack["activities"]}


def group_def(p, pack=PACK):
    age = p["age"]
    stage = p.get("stage", "none")
    sex = p["sex"]
    for g in pack["groups"]:
        if g["stage"] != stage:
            continue
        if g["sex"] is not None and g["sex"] != sex:
            continue
        if age < g["minAge"]:
            continue
        if g["maxAge"] is not None and age > g["maxAge"]:
            continue
        return g
    raise ValueError("ageUnsupported")


def target(p, nid, pack=PACK):
    nuts = _nut_map(pack)
    d = nuts.get(nid)
    if d is None or d["kind"] == "NONE":
        return None
    g = group_def(p, pack)
    if nid == "protein" and g["proteinPerKg"] is not None:
        return round(g["proteinPerKg"] * p["weight"] * 10) / 10
    return d["target"].get(g["id"])


def ul_for(p, nid, pack=PACK):
    nuts = _nut_map(pack)
    d = nuts.get(nid)
    if d is None:
        return None
    g1 = group_def(p, pack)
    u1 = d["ul"].get(g1["id"])
    if g1["maxAge"] is not None and p["age"] == g1["maxAge"]:
        try:
            g2 = group_def({**p, "age": p["age"] + 1}, pack)
        except ValueError:
            g2 = None
        if g2 is not None and g2["id"] != g1["id"]:
            u2 = d["ul"].get(g2["id"])
            vals = [v for v in (u1, u2) if v is not None]
            return min(vals) if vals else None
    return u1


def tee(c, p, week=0):
    return c["a"] + c["age"] * p["age"] + c["height"] * p["height"] + c["weight"] * p["weight"] + c.get("gestWeek", 0) * week


def eer(p, pack=PACK):
    e = pack["eer"]
    g = group_def(p, pack)
    mode = g["eerType"]
    if mode == "none":
        return None, "eerUnderAge19"
    lvl = p.get("level", "inactive")
    if mode == "adult":
        k = tee(e["adult"][p["sex"]][lvl], p)
    elif mode == "pregnant":
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
    return (int(k + 0.5) if k >= 0 else -int(-k + 0.5)), None


def _item_ul_amount(it, key):
    ul_n = it.get("ulN")
    if ul_n is not None and key in ul_n:
        return ul_n[key]
    return it["n"].get(key, 0.0)


def amount_for_ul(d, items):
    key = d.get("ulKey") or d["id"]
    s = 0.0
    for it in items:
        src = it["source"]
        ok = {"total": True, "supplement": src == "supplement",
              "synthetic": src in ("supplement", "fortified")}[d["ulScope"]]
        if ok:
            s += _item_ul_amount(it, key)
    return s


def ul_flags(p, days, kind="daily", pack=PACK):
    if kind == "sevenDayAverage":
        days = [d for d in days if len(d) > 0]
    if not days:
        return []
    out = []
    for d in pack["nutrients"]:
        if d.get("ulKey"):
            continue
        ul = ul_for(p, d["id"], pack)
        if ul is None:
            continue
        a = sum(amount_for_ul(d, day) for day in days) / len(days)
        if a > ul:
            excess = a - ul
            out.append({
                "id": d["id"],
                "kind": kind,
                "amount": a,
                "ul": ul,
                "excess": excess,
                "percentOver": excess / ul * 100.0,
                "percentOfUl": a / ul * 100.0,
                "scope": d["ulScope"],
                "dayCount": len(days) if kind == "sevenDayAverage" else None,
            })
    kind_rank = {"daily": 0, "sevenDayAverage": 1, "schedule": 2}
    out.sort(key=lambda f: (-f["percentOver"], kind_rank[f["kind"]], f["id"]))
    return out


def nutrient_statuses(p, days, average=False, pack=PACK):
    nuts = _nut_map(pack)
    if average:
        days = [d for d in days if len(d) > 0]
    n_days = len(days)
    ul_target_keys = {n["ulKey"] for n in pack["nutrients"] if n.get("ulKey")}
    out = []
    for d in pack["nutrients"]:
        nid = d["id"]
        if nid in ul_target_keys:
            continue
        t = target(p, nid, pack)
        ul_def = nuts[d["ulKey"]] if d.get("ulKey") else d
        ul = ul_for(p, ul_def["id"], pack)
        if t is None and ul is None:
            continue
        food = fort = supp = ul_amt = 0.0
        for day in days:
            for it in day:
                val = it["n"].get(nid, 0.0)
                if it["source"] == "food":
                    food += val
                elif it["source"] == "fortified":
                    fort += val
                else:
                    supp += val
            ul_amt += amount_for_ul(ul_def, day)
        if average and n_days > 0:
            food /= n_days
            fort /= n_days
            supp /= n_days
            ul_amt /= n_days
        elif average and n_days == 0:
            food = fort = supp = ul_amt = 0.0
        total = food + fort + supp
        out.append({
            "id": nid,
            "total": total,
            "food": food,
            "fortified": fort,
            "supplement": supp,
            "target": t,
            "ul": ul,
            "ulAmount": ul_amt,
            "ulScope": ul_def["ulScope"],
            "ulNutrientId": None if ul is None else ul_def["id"],
        })
    return out


def macros(p, days, average=False, pack=PACK):
    g = group_def(p, pack)
    amdr = pack["amdr"][g["amdrKey"]]
    if average:
        days = [d for d in days if len(d) > 0]
    n_days = len(days)
    totals = {m: sum(it["n"].get(m, 0.0) for day in days for it in day) for m in ("protein", "fat", "carbohydrate")}
    kcal = {m: totals[m] * pack["energyPerGram"][m] for m in totals}
    tot_kcal = sum(kcal.values())
    res = {}
    for m in ("protein", "fat", "carbohydrate"):
        pct = 0.0 if tot_kcal == 0 else kcal[m] / tot_kcal * 100.0
        lo, hi = amdr[m]
        grams = totals[m] / n_days if (average and n_days > 0) else (0.0 if average else totals[m])
        res[m] = {
            "grams": grams,
            "pct": pct,
            "status": "below" if pct < lo else ("above" if pct > hi else "within"),
        }
    return res


def _group_sugar_entries(day):
    grouped = []
    by_eid = {}
    for it in day:
        eid = it.get("entryId")
        if eid is not None and eid in by_eid:
            g = by_eid[eid]
            g["sugar"] += it["n"].get("addedSugar", 0.0)
            if not it.get("addedSugarKnown", True):
                g["known"] = False
        else:
            g = {
                "label": it["label"],
                "meal": it.get("meal"),
                "at": it.get("at"),
                "sugar": it["n"].get("addedSugar", 0.0),
                "known": it.get("addedSugarKnown", True),
            }
            grouped.append(g)
            if eid is not None:
                by_eid[eid] = g
    return grouped


def sugar(day, pack=PACK):
    s = sum(it["n"].get("addedSugar", 0.0) for it in day)
    e = sum(it["n"].get("energyKcal", 0.0) for it in day)
    if e <= 0:
        e = sum(it["n"].get("protein", 0.0) * 4 + it["n"].get("carbohydrate", 0.0) * 4 + it["n"].get("fat", 0.0) * 9 for it in day)
    pct = 0.0 if e <= 0 else s * 4 / e * 100.0
    limit = pack["addedSugar"]["maxGramsPerMeal"]
    entries = _group_sugar_entries(day)
    alerts = []
    for meal in ("breakfast", "lunch", "dinner"):
        ms = [g for g in entries if g["meal"] == meal]
        total = sum(g["sugar"] for g in ms)
        if total > limit:
            alerts.append({"meal": meal, "grams": total, "startAt": None, "endAt": None,
                           "labels": [g["label"] for g in ms]})
    snacks = [g for g in entries if g["meal"] == "snack"]
    timed = sorted([g for g in snacks if g["at"] is not None], key=lambda g: datetime.fromisoformat(g["at"]))
    untimed = [g for g in snacks if g["at"] is None]
    clusters = []
    for g in timed:
        t = datetime.fromisoformat(g["at"])
        if not clusters or (t - clusters[-1]["last_t"]).total_seconds() >= 30 * 60:
            clusters.append({"start": g["at"], "end": g["at"], "last_t": t, "grams": g["sugar"], "labels": [g["label"]]})
        else:
            c = clusters[-1]
            c["end"] = g["at"]
            c["last_t"] = t
            c["grams"] += g["sugar"]
            c["labels"].append(g["label"])
    for g in untimed:
        clusters.append({"start": None, "end": None, "grams": g["sugar"], "labels": [g["label"]]})
    for c in clusters:
        if c["grams"] > limit:
            alerts.append({"meal": "snack", "grams": c["grams"], "startAt": c["start"], "endAt": c["end"],
                           "labels": c["labels"]})
    unknown = [g["label"] for g in entries if not g["known"]]
    return {"addedSugarG": s, "pct": pct, "mealsOverLimit": alerts, "unknownSugarFoods": unknown}


def workout_kcal(p, code, minutes, pack=PACK):
    acts = _act_map(pack)
    if code not in acts:
        raise ValueError("unknownActivity")
    return acts[code]["met"] * p["weight"] * minutes / 60.0


def activity_summary(ws, pack=PACK, days=7):
    acts = _act_map(pack)
    mod = vig = 0.0
    strength_keys = set()
    for i, w in enumerate(ws):
        a = acts.get(w["code"])
        if a is None:
            continue
        if a["met"] >= pack["pag"]["vigorousMinMet"]:
            vig += w["minutes"]
        elif a["met"] >= pack["pag"]["moderateMinMet"]:
            mod += w["minutes"]
        if a["muscleStrengthening"]:
            strength_keys.add(w.get("day") or f"__anon_{i}")
    eq = mod + 2 * vig
    per_day = eq / days
    t = pack["palSuggestion"]["moderateEquivalentMinPerDay"]
    if per_day >= t["veryActive"]:
        lvl = "veryActive"
    elif per_day >= t["active"]:
        lvl = "active"
    elif per_day >= t["lowActive"]:
        lvl = "lowActive"
    else:
        lvl = "inactive"
    return {
        "moderateMinutes": mod,
        "vigorousMinutes": vig,
        "moderateEquivalentMinutes": eq,
        "strengthDays": len(strength_keys),
        "suggestedLevel": lvl,
    }


def daily_report(p, today, workouts=(), last7=(), workouts7=(), pack=PACK):
    k, why = eer(p, pack)
    non_empty = [d for d in last7 if len(d) > 0]
    flags = ul_flags(p, [today], "daily", pack) + ul_flags(p, non_empty, "sevenDayAverage", pack)
    kind_rank = {"daily": 0, "sevenDayAverage": 1, "schedule": 2}
    flags.sort(key=lambda f: (-f["percentOver"], kind_rank[f["kind"]], f["id"]))
    return {
        "energyInKcal": sum(it["n"].get("energyKcal", 0.0) for it in today),
        "eerKcal": k,
        "eerNotComputed": why,
        "energyOutWorkoutKcal": sum(workout_kcal(p, w["code"], w["minutes"], pack) for w in workouts),
        "macros": macros(p, [today], False, pack),
        "sugar": sugar(today, pack),
        "nutrients": nutrient_statuses(p, [today], False, pack),
        "ulFlags": flags,
        "loggedDaysCount": len(non_empty),
        "activity7Days": activity_summary(workouts7, pack),
    }


def average_report(p, logged_days, workouts7=(), pack=PACK):
    non_empty = [d for d in logged_days if len(d) > 0]
    n = len(non_empty)
    k, why = eer(p, pack)
    tot_energy_in = sum(it["n"].get("energyKcal", 0.0) for d in non_empty for it in d)
    tot_sugar = sum(it["n"].get("addedSugar", 0.0) for d in non_empty for it in d)
    tot_e = tot_energy_in
    if tot_e <= 0:
        tot_e = sum(it["n"].get("protein", 0.0) * 4 + it["n"].get("carbohydrate", 0.0) * 4 + it["n"].get("fat", 0.0) * 9
                    for d in non_empty for it in d)
    return {
        "loggedDaysCount": n,
        "averageEnergyInKcal": tot_energy_in / n if n > 0 else 0.0,
        "eerKcal": k,
        "eerNotComputed": why,
        "macros": macros(p, non_empty, True, pack),
        "averageAddedSugarG": tot_sugar / n if n > 0 else 0.0,
        "addedSugarPercentEnergy": 0.0 if tot_e <= 0 else tot_sugar * 4 / tot_e * 100.0,
        "nutrients": nutrient_statuses(p, non_empty, True, pack),
        "ulFlags": ul_flags(p, non_empty, "sevenDayAverage", pack),
        "activity7Days": activity_summary(workouts7, pack),
    }


_UNIT_ALIAS = {"ugDfe": "ug_DFE", "ugRae": "ug_RAE", "mgNe": "mg_NE"}


def _to_target_unit(amount, from_unit, target_unit):
    from_unit = _UNIT_ALIAS.get(from_unit, from_unit)
    if from_unit == target_unit:
        return amount
    if from_unit == "mg" and target_unit == "mg_NE":
        return amount
    if from_unit == "ug" and target_unit == "ug_RAE":
        return amount
    if from_unit == "ug" and target_unit == "ug_DFE":
        return amount
    if from_unit in METRIC_FACTOR_TO_UG and target_unit in METRIC_FACTOR_TO_UG:
        return amount * METRIC_FACTOR_TO_UG[from_unit] / METRIC_FACTOR_TO_UG[target_unit]
    raise ValueError(f"unsupportedUnit:{from_unit}->{target_unit}")


def convert_intake_line(inp, pack=PACK):
    amt = inp["amount"]
    sec_fa = inp.get("secondaryFolicAcidUg")
    if amt < 0 or (sec_fa is not None and sec_fa < 0):
        raise ValueError("negativeAmount")
    nuts = _nut_map(pack)
    nid = inp.get("nutrientId")
    if nid is None or nid not in nuts:
        return {"amounts": {}, "ulAmounts": None, "uncertain": False, "amountsNotComputed": "missingNutrientInPack"}
    uc = pack["unitConversions"]
    src = inp["source"]
    form = inp.get("form") or "unknown"
    unit = inp["unit"]
    ckind = inp.get("compoundKind", "elemental")

    # ---- Folate / Folic acid
    if nid == "folicAcid":
        ug = _to_target_unit(amt, unit, "ug")
        return {"amounts": {"folate": ug * uc["folicAcid_ug_to_ug_DFE"], "folicAcid": ug},
                "ulAmounts": None, "uncertain": False, "amountsNotComputed": None}
    if nid == "folate":
        if form == "folic_acid" and _UNIT_ALIAS.get(unit, unit) in METRIC_FACTOR_TO_UG:
            ug = _to_target_unit(amt, unit, "ug")
            return {"amounts": {"folate": ug * uc["folicAcid_ug_to_ug_DFE"], "folicAcid": ug},
                    "ulAmounts": None, "uncertain": False, "amountsNotComputed": None}
        dfe = _to_target_unit(amt, unit, "ug_DFE")
        if sec_fa is not None:
            return {"amounts": {"folate": dfe, "folicAcid": sec_fa},
                    "ulAmounts": None, "uncertain": False, "amountsNotComputed": None}
        if form == "natural_folate":
            return {"amounts": {"folate": dfe}, "ulAmounts": None, "uncertain": False, "amountsNotComputed": None}
        if form == "folic_acid":
            return {"amounts": {"folate": dfe, "folicAcid": dfe / uc["folicAcid_ug_to_ug_DFE"]},
                    "ulAmounts": None, "uncertain": False, "amountsNotComputed": None}
        return {"amounts": {"folate": dfe, "folicAcid": dfe / uc["folicAcid_ug_to_ug_DFE"]},
                "ulAmounts": None, "uncertain": True, "amountsNotComputed": None}

    # ---- Vitamin A
    if nid == "vitA":
        if form == "retinol":
            rae = amt * uc["vitA_retinol_IU_to_ug_RAE"] if unit == "iu" else _to_target_unit(amt, unit, "ug_RAE")
            return {"amounts": {"vitA": rae, "retinol": rae}, "ulAmounts": None, "uncertain": False, "amountsNotComputed": None}
        if form == "beta_carotene":
            if unit != "iu":
                rae = _to_target_unit(amt, unit, "ug_RAE")
                return {"amounts": {"vitA": rae}, "ulAmounts": None, "uncertain": False, "amountsNotComputed": None}
            if src == "supplement":
                rae = amt * uc["vitA_supplemental_betacarotene_IU_to_ug_RAE"]
                return {"amounts": {"vitA": rae}, "ulAmounts": None, "uncertain": False, "amountsNotComputed": None}
            food_f = uc.get("vitA_food_betacarotene_IU_to_ug_RAE")
            if food_f is None:
                return {"amounts": {}, "ulAmounts": None, "uncertain": False, "amountsNotComputed": "missingFoodBetaCaroteneFactor"}
            return {"amounts": {"vitA": amt * food_f}, "ulAmounts": None, "uncertain": False, "amountsNotComputed": None}
        # unknown form
        if unit != "iu":
            rae = _to_target_unit(amt, unit, "ug_RAE")
            return {"amounts": {"vitA": rae, "retinol": rae}, "ulAmounts": None, "uncertain": True, "amountsNotComputed": None}
        if src == "supplement":
            rae = amt * uc["vitA_retinol_IU_to_ug_RAE"]
            return {"amounts": {"vitA": rae, "retinol": rae}, "ulAmounts": None, "uncertain": True, "amountsNotComputed": None}
        food_f = uc.get("vitA_food_betacarotene_IU_to_ug_RAE")
        ret = amt * uc["vitA_retinol_IU_to_ug_RAE"]
        if food_f is None:
            return {"amounts": {}, "ulAmounts": {"retinol": ret}, "uncertain": True, "amountsNotComputed": "missingFoodBetaCaroteneFactor"}
        return {"amounts": {"vitA": amt * food_f}, "ulAmounts": {"retinol": ret}, "uncertain": True, "amountsNotComputed": None}

    # ---- Vitamin E
    if nid == "vitE":
        esters = uc.get("vitaminEEsters", {})
        is_ester = form in ESTER_ORIGINS or form in esters
        e_rda_nat = uc["vitE_natural_IU_to_mg"]
        e_rda_syn = uc["vitE_synthetic_IU_to_mg"]
        e_ul_nat = uc["vitE_ul_natural_IU_to_mg"]
        e_ul_syn = uc["vitE_ul_synthetic_IU_to_mg"]

        if unit == "iu":
            origin = None
            if form == "natural_2r":
                origin = "natural"
            elif form in ("synthetic_2r", "synthetic_mass"):
                origin = "synthetic"
            elif is_ester:
                origin = esters[form]["origin"] if form in esters else ESTER_ORIGINS[form]
            if origin == "natural":
                rda = amt * e_rda_nat
                ul = amt * e_ul_nat
                return {"amounts": {"vitE": rda}, "ulAmounts": None if abs(ul - rda) < 1e-12 else {"vitE": ul},
                        "uncertain": False, "amountsNotComputed": None}
            if origin == "synthetic":
                return {"amounts": {"vitE": amt * e_rda_syn}, "ulAmounts": {"vitE": amt * e_ul_syn},
                        "uncertain": False, "amountsNotComputed": None}
            return {"amounts": {"vitE": amt * e_rda_syn}, "ulAmounts": {"vitE": amt * e_ul_syn},
                    "uncertain": True, "amountsNotComputed": None}

        mg = _to_target_unit(amt, unit, "mg")
        if is_ester:
            edef = esters.get(form)
            if edef is None:
                return {"amounts": {}, "ulAmounts": {"vitE": mg}, "uncertain": False, "amountsNotComputed": "missingEsterRatio"}
            tmg = mg * edef["tocopherolRatio"]
            if edef["origin"] == "natural":
                return {"amounts": {"vitE": tmg}, "ulAmounts": None, "uncertain": False, "amountsNotComputed": None}
            return {"amounts": {"vitE": tmg / e_ul_syn * e_rda_syn}, "ulAmounts": {"vitE": tmg},
                    "uncertain": False, "amountsNotComputed": None}
        if form == "natural_2r":
            return {"amounts": {"vitE": mg}, "ulAmounts": None, "uncertain": False, "amountsNotComputed": None}
        if form == "synthetic_2r":
            return {"amounts": {"vitE": mg}, "ulAmounts": {"vitE": mg / e_rda_syn * e_ul_syn},
                    "uncertain": False, "amountsNotComputed": None}
        if form == "synthetic_mass":
            return {"amounts": {"vitE": mg / e_ul_syn * e_rda_syn}, "ulAmounts": {"vitE": mg},
                    "uncertain": False, "amountsNotComputed": None}
        # unknown mg
        return {"amounts": {"vitE": mg / e_ul_syn * e_rda_syn},
                "ulAmounts": {"vitE": mg / e_rda_syn * e_ul_syn},
                "uncertain": True, "amountsNotComputed": None}

    # ---- Vitamin D
    if nid == "vitD" and unit == "iu":
        return {"amounts": {"vitD": amt * uc["vitD_IU_to_ug"]}, "ulAmounts": None,
                "uncertain": False, "amountsNotComputed": None}

    # ---- Hợp chất khoáng vs nguyên tố (hàng 15–17)
    std_val = _to_target_unit(amt, unit, nuts[nid]["unit"])
    compounds = uc.get("compounds", {})
    if ckind == "compound":
        ratio = compounds.get(nid, {}).get(form)
        if ratio is None:
            return {"amounts": {}, "ulAmounts": None, "uncertain": False, "amountsNotComputed": "missingCompoundRatio"}
        return {"amounts": {nid: std_val * ratio}, "ulAmounts": None, "uncertain": False, "amountsNotComputed": None}
    if ckind == "unknown":
        by_nut = compounds.get(nid, {})
        if not by_nut:
            return {"amounts": {}, "ulAmounts": {nid: std_val}, "uncertain": True, "amountsNotComputed": "missingCompoundRatio"}
        min_r = min(by_nut.values())
        return {"amounts": {nid: std_val * min_r}, "ulAmounts": {nid: std_val}, "uncertain": True, "amountsNotComputed": None}
    # elemental (hàng 17)
    return {"amounts": {nid: std_val}, "ulAmounts": None, "uncertain": False, "amountsNotComputed": None}


# ------------------------------------------------------------ tự kiểm bằng tay
def self_check():
    man = {"age": 30, "sex": "male", "height": 170, "weight": 65, "level": "inactive"}
    assert eer(man) == (2450, None), eer(man)
    woman = {"age": 25, "sex": "female", "height": 158, "weight": 52, "level": "active"}
    assert eer(woman) == (2210, None), eer(woman)
    lac = dict(woman, stage="lactating", monthsPostpartum=3)
    assert eer(lac) == (2610, None)
    assert target(man, "protein") == 52.0
    assert target(man, "iron") == 8
    assert abs(workout_kcal({"weight": 60}, "12050", 30) - 279) < 1e-9
    assert group_def({"age": 18, "sex": "female"})["id"] == "f14_18"
    # kiểm mốc tuổi & vitE UL
    assert ul_for({"age": 18, "sex": "male"}, "calcium") == 2500
    assert ul_for({"age": 18, "sex": "male"}, "vanadium") == 1.8
    assert ul_for({"age": 50, "sex": "female"}, "calcium") == 2000
    assert ul_for({"age": 70, "sex": "male"}, "phosphorus") == 3000
    ve_safe = convert_intake_line({"nutrientId": "vitE", "source": "supplement", "form": "synthetic_2r", "amount": 1100, "unit": "iu"})
    assert abs(ve_safe["amounts"]["vitE"] - 495.0) < 1e-9
    assert abs(ve_safe["ulAmounts"]["vitE"] - 1000.0) < 1e-9
    print("tự kiểm: OK")


# ------------------------------------------------------------ fixtures
def it(source, n, meal=None, at=None, added_sugar_known=True, entry_id=None, ul_n=None, label="x"):
    d = {"label": label, "source": source, "n": n, "addedSugarKnown": added_sugar_known}
    if meal is not None:
        d["meal"] = meal
    if at is not None:
        d["at"] = at
    if entry_id is not None:
        d["entryId"] = entry_id
    if ul_n is not None:
        d["ulN"] = ul_n
    return d


PROFILES = {
    "man30": {"age": 30, "sex": "male", "height": 170, "weight": 65, "level": "inactive"},
    "man45_active": {"age": 45, "sex": "male", "height": 175, "weight": 78, "level": "active"},
    "man50": {"age": 50, "sex": "male", "height": 168, "weight": 65, "level": "lowActive"},
    "man70": {"age": 70, "sex": "male", "height": 166, "weight": 62, "level": "inactive"},
    "man72_very": {"age": 72, "sex": "male", "height": 165, "weight": 60, "level": "veryActive"},
    "boy18": {"age": 18, "sex": "male", "height": 172, "weight": 60, "level": "inactive"},
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
                    "vitC": 30, "iron": 3, "calcium": 200}, "breakfast", "2026-11-24T07:30:00", entry_id="f1", label="Phở"),
        it("food", {"energyKcal": 750, "protein": 35, "fat": 22, "carbohydrate": 100, "addedSugar": 6,
                    "vitC": 40, "iron": 5, "calcium": 300}, "lunch", "2026-11-24T12:00:00", entry_id="f2", label="Cơm"),
        it("food", {"energyKcal": 650, "protein": 30, "fat": 20, "carbohydrate": 88, "addedSugar": 3,
                    "vitC": 25, "iron": 4, "calcium": 250}, "dinner", "2026-11-24T19:00:00", entry_id="f3", label="Cá"),
    ],
    "sweet_fatty": [
        it("food", {"energyKcal": 900, "protein": 15, "fat": 50, "carbohydrate": 95, "addedSugar": 40},
           "snack", "2026-11-24T15:00:00", entry_id="s1", label="Trà sữa"),
        it("food", {"energyKcal": 800, "protein": 30, "fat": 40, "carbohydrate": 80, "addedSugar": 8},
           "lunch", "2026-11-24T12:00:00", entry_id="l1", label="Cơm sườn"),
    ],
    "supplements_heavy": [
        it("food", {"energyKcal": 1800, "protein": 70, "fat": 60, "carbohydrate": 240,
                    "magnesium": 300, "niacin": 20, "retinol": 400, "vitA": 700, "zinc": 9, "vitD": 3,
                    "boron": 22, "vanadium": 1.9}, "lunch", "2026-11-24T12:00:00", entry_id="fh"),
        it("supplement", {"magnesium": 400, "niacin": 50, "vitD": 125, "zinc": 30, "retinol": 3000, "vitA": 3000,
                          "vitE": 540}, ul_n={"vitE": 1200 * 1000 / 1100}),
        it("fortified", {"niacin": 5, "folicAcid": 200, "folate": 340}, "breakfast", "2026-11-24T07:00:00", entry_id="ff"),
    ],
    "fortified_folic": [
        it("food", {"energyKcal": 2000, "protein": 80, "fat": 65, "carbohydrate": 270, "folate": 300},
           "lunch", "2026-11-24T12:00:00", entry_id="ff1"),
        it("fortified", {"folicAcid": 600, "folate": 1020}, "breakfast", "2026-11-24T07:00:00", entry_id="ff2"),
        it("supplement", {"folicAcid": 500, "folate": 850}),
    ],
    "vitE_boundary": [
        it("supplement", {"vitE": 495}, ul_n={"vitE": 1100 * 1000 / 1100}, label="VitE 1100 IU syn"),
        it("food", {"energyKcal": 1800, "protein": 70, "fat": 60, "carbohydrate": 240, "calcium": 2400},
           "lunch", "2026-11-24T12:00:00", entry_id="vb1"),
    ],
    "snack_chain": [
        it("food", {"energyKcal": 150, "addedSugar": 4}, "snack", "2026-11-24T15:00:00", entry_id="sc1", label="Bánh 1"),
        it("food", {"energyKcal": 150, "addedSugar": 4}, "snack", "2026-11-24T15:25:00", entry_id="sc2", label="Kẹo 2"),
        it("food", {"energyKcal": 150, "addedSugar": 4}, "snack", "2026-11-24T15:50:00", entry_id="sc3", label="Nước 3"),
        it("food", {"energyKcal": 200, "addedSugar": 6}, "snack", "2026-11-24T17:00:00", entry_id="sc4", label="Sữa 4"),
        it("food", {"energyKcal": 200, "addedSugar": 6}, "snack", "2026-11-24T17:30:00", entry_id="sc5", label="Chè 5"),
        it("food", {"energyKcal": 250, "protein": 8, "addedSugar": 0}, "breakfast", "2026-11-24T08:00:00",
           added_sugar_known=False, entry_id="unk1", label="Bánh mì nhãn cũ"),
        it("fortified", {"vitD": 2, "addedSugar": 0}, "breakfast", "2026-11-24T08:00:00",
           added_sugar_known=False, entry_id="unk1", label="Bánh mì nhãn cũ"),
        it("food", {"energyKcal": 100, "addedSugar": 7}, "snack", None, entry_id="un1", label="Snack không giờ 1"),
        it("food", {"energyKcal": 100, "addedSugar": 7}, "snack", None, entry_id="un2", label="Snack không giờ 2"),
    ],
}

WORKOUT_SETS = {
    "none": [],
    "light": [
        {"code": "17190", "minutes": 20, "day": "2026-11-18"},
        {"code": "17190", "minutes": 20, "day": "2026-11-20"},
        {"code": "17190", "minutes": 20, "day": "2026-11-22"},
    ],
    "moderate": [{"code": "17200", "minutes": 45, "day": f"2026-11-{18 + i}"} for i in range(7)],
    "mixed": [
        {"code": "12050", "minutes": 40, "day": "2026-11-18"},
        {"code": "12050", "minutes": 40, "day": "2026-11-19"},
        {"code": "12050", "minutes": 40, "day": "2026-11-20"},
        {"code": "17200", "minutes": 60, "day": "2026-11-21"},
        {"code": "17200", "minutes": 60, "day": "2026-11-22"},
        {"code": "15030", "minutes": 60, "day": "2026-11-23"},
    ],
    "athlete": [
        {"code": "12090", "minutes": 60, "day": f"2026-11-{18 + i}"} for i in range(7)
    ] + [
        {"code": "02050", "minutes": 60, "day": "2026-11-18"},
        {"code": "02054", "minutes": 30, "day": "2026-11-18"},
        {"code": "02024", "minutes": 15, "day": "2026-11-20"},
        {"code": "02160", "minutes": 45, "day": "2026-11-21"},
    ],
}

EXTENDED_PACK = json.loads(json.dumps(PACK))
EXTENDED_PACK["unitConversions"]["vitA_food_betacarotene_IU_to_ug_RAE"] = 0.05
EXTENDED_PACK["unitConversions"]["vitaminEEsters"] = {
    "d_alpha_tocopheryl_acetate": {"tocopherolRatio": 430 / 472, "origin": "natural"},
    "dl_alpha_tocopheryl_acetate": {"tocopherolRatio": 430 / 472, "origin": "synthetic"},
    "d_alpha_tocopheryl_succinate": {"tocopherolRatio": 430 / 530, "origin": "natural"},
    "dl_alpha_tocopheryl_succinate": {"tocopherolRatio": 430 / 530, "origin": "synthetic"},
}
EXTENDED_PACK["unitConversions"]["compounds"] = {
    "calcium": {"calcium_carbonate": 0.40, "calcium_citrate": 0.21},
    "copper": {"copper_sulfate": 0.25},
}

LINE_CASES = [
    ("row1_folic_ug", False, {"nutrientId": "folicAcid", "source": "supplement", "form": "folic_acid", "amount": 400, "unit": "ug"}),
    ("row1_folate_folic_mg", False, {"nutrientId": "folate", "source": "supplement", "form": "folic_acid", "amount": 0.4, "unit": "mg"}),
    ("row2_dfe_with_folic", False, {"nutrientId": "folate", "source": "fortified", "form": "folic_acid", "amount": 500, "unit": "ugDfe", "secondaryFolicAcidUg": 200}),
    ("row2_natural_folate", False, {"nutrientId": "folate", "source": "food", "form": "natural_folate", "amount": 300, "unit": "ugDfe"}),
    ("row3_dfe_unknown", False, {"nutrientId": "folate", "source": "supplement", "form": "unknown", "amount": 680, "unit": "ugDfe"}),
    ("row4_vitA_retinol_iu", False, {"nutrientId": "vitA", "source": "supplement", "form": "retinol", "amount": 5000, "unit": "iu"}),
    ("row5a_vitA_bc_supp_iu", False, {"nutrientId": "vitA", "source": "supplement", "form": "beta_carotene", "amount": 5000, "unit": "iu"}),
    ("row5b_vitA_bc_food_iu_food", False, {"nutrientId": "vitA", "source": "food", "form": "beta_carotene", "amount": 5000, "unit": "iu"}),
    ("row5b_vitA_bc_food_iu_fort", False, {"nutrientId": "vitA", "source": "fortified", "form": "beta_carotene", "amount": 5000, "unit": "iu"}),
    ("row6_vitA_rae_unknown", False, {"nutrientId": "vitA", "source": "supplement", "form": "unknown", "amount": 750, "unit": "ugRae"}),
    ("row7_vitA_supp_iu_unknown", False, {"nutrientId": "vitA", "source": "supplement", "form": "unknown", "amount": 3000, "unit": "iu"}),
    ("row8_vitA_food_iu_unknown_food", False, {"nutrientId": "vitA", "source": "food", "form": "unknown", "amount": 3000, "unit": "iu"}),
    ("row8_vitA_food_iu_unknown_fort", False, {"nutrientId": "vitA", "source": "fortified", "form": "unknown", "amount": 3000, "unit": "iu"}),
    ("row9_vitE_iu_nat", False, {"nutrientId": "vitE", "source": "supplement", "form": "natural_2r", "amount": 400, "unit": "iu"}),
    ("row9_vitE_iu_syn", False, {"nutrientId": "vitE", "source": "supplement", "form": "synthetic_2r", "amount": 1100, "unit": "iu"}),
    ("row9_vitE_iu_ester_d", False, {"nutrientId": "vitE", "source": "supplement", "form": "d_alpha_tocopheryl_acetate", "amount": 400, "unit": "iu"}),
    ("row9_vitE_iu_ester_dl", False, {"nutrientId": "vitE", "source": "supplement", "form": "dl_alpha_tocopheryl_succinate", "amount": 400, "unit": "iu"}),
    ("row10_vitE_iu_unknown", False, {"nutrientId": "vitE", "source": "supplement", "form": "unknown", "amount": 400, "unit": "iu"}),
    ("row11_vitE_mg_2r_nat", False, {"nutrientId": "vitE", "source": "supplement", "form": "natural_2r", "amount": 15, "unit": "mg"}),
    ("row11_vitE_mg_2r_syn", False, {"nutrientId": "vitE", "source": "supplement", "form": "synthetic_2r", "amount": 15, "unit": "mg"}),
    ("row12_vitE_mg_syn_mass", False, {"nutrientId": "vitE", "source": "supplement", "form": "synthetic_mass", "amount": 30, "unit": "mg"}),
    ("row13_vitE_mg_ester_missing", False, {"nutrientId": "vitE", "source": "supplement", "form": "dl_alpha_tocopheryl_acetate", "amount": 30, "unit": "mg"}),
    ("row13_vitE_mg_ester_d_ext", True, {"nutrientId": "vitE", "source": "supplement", "form": "d_alpha_tocopheryl_acetate", "amount": 30, "unit": "mg"}),
    ("row13_vitE_mg_ester_dl_ext", True, {"nutrientId": "vitE", "source": "supplement", "form": "dl_alpha_tocopheryl_succinate", "amount": 30, "unit": "mg"}),
    ("row14_vitE_mg_unknown", False, {"nutrientId": "vitE", "source": "supplement", "form": "unknown", "amount": 15, "unit": "mg"}),
    ("row15_compound_missing", False, {"nutrientId": "magnesium", "source": "supplement", "form": "magnesium_oxide", "amount": 400, "unit": "mg", "compoundKind": "compound"}),
    ("row15_compound_calcium_pack", False, {"nutrientId": "calcium", "source": "supplement", "form": "calcium_carbonate", "amount": 1.25, "unit": "g", "compoundKind": "compound"}),
    ("row15_compound_calcium_citrate_pack", False, {"nutrientId": "calcium", "source": "supplement", "form": "calcium_citrate", "amount": 1000, "unit": "mg", "compoundKind": "compound"}),
    ("row15_compound_iron_fumarate_pack", False, {"nutrientId": "iron", "source": "supplement", "form": "ferrous_fumarate", "amount": 100, "unit": "mg", "compoundKind": "compound"}),
    ("row15_compound_iron_sulfate_pack", False, {"nutrientId": "iron", "source": "supplement", "form": "ferrous_sulfate", "amount": 100, "unit": "mg", "compoundKind": "compound"}),
    ("row15_compound_iron_gluconate_pack", False, {"nutrientId": "iron", "source": "supplement", "form": "ferrous_gluconate", "amount": 100, "unit": "mg", "compoundKind": "compound"}),
    ("row15_compound_calcium_ext", True, {"nutrientId": "calcium", "source": "supplement", "form": "calcium_carbonate", "amount": 1.25, "unit": "g", "compoundKind": "compound"}),
    ("row15_compound_copper_ug_ext", True, {"nutrientId": "copper", "source": "supplement", "form": "copper_sulfate", "amount": 2, "unit": "mg", "compoundKind": "compound"}),
    ("row16_compound_unknown_missing", False, {"nutrientId": "magnesium", "source": "supplement", "form": "unknown", "amount": 250, "unit": "mg", "compoundKind": "unknown"}),
    ("row16_compound_unknown_pack", False, {"nutrientId": "calcium", "source": "supplement", "form": "unknown", "amount": 500, "unit": "mg", "compoundKind": "unknown"}),
    ("row16_compound_unknown_ext", True, {"nutrientId": "calcium", "source": "supplement", "form": "unknown", "amount": 500, "unit": "mg", "compoundKind": "unknown"}),
    ("row17_elemental_with_form", False, {"nutrientId": "calcium", "source": "supplement", "form": "calcium_carbonate", "amount": 500, "unit": "mg", "compoundKind": "elemental"}),
    ("row17_vitD_iu", False, {"nutrientId": "vitD", "source": "supplement", "form": "unknown", "amount": 1000, "unit": "iu"}),
    ("row17_niacin_mg", False, {"nutrientId": "niacin", "source": "supplement", "form": "unknown", "amount": 20, "unit": "mg"}),
    ("row18_unknown_nutrient", False, {"nutrientId": None, "freeName": "Coenzyme Q10", "source": "supplement", "form": "unknown", "amount": 30, "unit": "mg"}),
]


def check_ingredient_sanity(p, inp, pack=PACK):
    nid = inp.get("nutrientId")
    nuts = _nut_map(pack)
    d = nuts.get(nid) if nid else None
    if d is None:
        return {"suspectedUnitMistake": False, "exceedsSingleServingUl": False}
    conv = convert_intake_line(inp, pack)
    ul_lim = ul_for(p, d["id"], pack)
    ul_key = d.get("ulKey") or d["id"]
    ul_val = (conv.get("ulAmounts") or {}).get(ul_key)
    if ul_val is None:
        ul_val = conv.get("amounts", {}).get(ul_key)
    exceeds = ul_lim is not None and ul_val is not None and ul_val > ul_lim

    suspected = False
    if d["unit"] == "ug" and inp["unit"] in ("mg", "g"):
        val_cmp = ul_val if ul_val is not None else conv.get("amounts", {}).get(d["id"], 0.0)
        if ul_lim is not None:
            suspected = val_cmp > ul_lim * 10
        else:
            t = target(p, d["id"], pack)
            if t is not None and t > 0:
                suspected = conv.get("amounts", {}).get(d["id"], 0.0) > t * 100
    return {"suspectedUnitMistake": suspected, "exceedsSingleServingUl": exceeds}


def _clock_diff_minutes(a: int, b: int) -> int:
    d = abs(a - b) % 1440
    return min(d, 1440 - d)


def evaluate_schedule_rules(meal_times, scheduled_doses, pack=PACK):
    """Đánh giá toàn bộ scheduleRules trong pack thuần bằng dữ liệu."""
    rules = pack.get("scheduleRules", [])
    meals = [meal_times["breakfast"], meal_times["lunch"], meal_times["dinner"]]
    out = []

    for r in rules:
        rtype = r["type"]
        req_nuts = r["nutrients"]
        req_forms = set(r.get("forms") or [])
        window = r.get("windowMinutes") or 0

        if rtype == "single_dose_max":
            target_nid = req_nuts[0]
            threshold = r["threshold"]
            by_time = {}
            for d in scheduled_doses:
                t = d["timeOfDay"]
                total = sum(
                    item["amount"]
                    for item in d["nutrients"]
                    if item["nutrientId"] == target_nid
                    and (not req_forms or item.get("form") in req_forms)
                )
                if total > 0:
                    entry = by_time.setdefault(t, {"amount": 0.0, "productIds": set()})
                    entry["amount"] += total
                    entry["productIds"].add(d["productId"])
            for t in sorted(by_time):
                entry = by_time[t]
                if entry["amount"] > threshold:
                    out.append({
                        "ruleId": r["id"],
                        "severity": r["severity"],
                        "timeOfDay": t,
                        "productIds": sorted(entry["productIds"]),
                        "uncertain": r["uncertain"],
                    })

        elif rtype == "take_with_meal":
            target_nid = req_nuts[0]
            for d in scheduled_doses:
                matched = any(
                    item["nutrientId"] == target_nid
                    and item["amount"] > 0
                    and (not req_forms or item.get("form") in req_forms)
                    for item in d["nutrients"]
                )
                if not matched:
                    continue
                if not any(_clock_diff_minutes(d["timeOfDay"], m) <= window for m in meals):
                    out.append({
                        "ruleId": r["id"],
                        "severity": r["severity"],
                        "timeOfDay": d["timeOfDay"],
                        "productIds": [d["productId"]],
                        "uncertain": r["uncertain"],
                    })

        elif rtype == "co_timing_caution":
            n_a, n_b = req_nuts[0], req_nuts[1]
            list_a = [
                d for d in scheduled_doses
                if any(it["nutrientId"] == n_a and it["amount"] > 0 for it in d["nutrients"])
            ]
            list_b = [
                d for d in scheduled_doses
                if any(it["nutrientId"] == n_b and it["amount"] > 0 for it in d["nutrients"])
            ]
            seen_clusters = set()
            for da in list_a:
                for db in list_b:
                    if _clock_diff_minutes(da["timeOfDay"], db["timeOfDay"]) <= window:
                        t_key = (min(da["timeOfDay"], db["timeOfDay"]), max(da["timeOfDay"], db["timeOfDay"]))
                        if t_key in seen_clusters:
                            continue
                        seen_clusters.add(t_key)
                        pids = sorted({da["productId"], db["productId"]})
                        out.append({
                            "ruleId": r["id"],
                            "severity": r["severity"],
                            "timeOfDay": da["timeOfDay"],
                            "productIds": pids,
                            "uncertain": r["uncertain"],
                        })

        elif rtype == "co_timing_threshold":
            n_trigger, n_affected = req_nuts[0], req_nuts[1]
            threshold = r["threshold"]
            list_aff = [
                d for d in scheduled_doses
                if any(it["nutrientId"] == n_affected and it["amount"] > 0 for it in d["nutrients"])
            ]
            list_trig = [
                d for d in scheduled_doses
                if any(it["nutrientId"] == n_trigger and it["amount"] > 0 for it in d["nutrients"])
            ]
            seen_times = set()
            for da in list_aff:
                trig_sum = 0.0
                pids = {da["productId"]}
                for dt in list_trig:
                    if _clock_diff_minutes(da["timeOfDay"], dt["timeOfDay"]) <= window:
                        trig_amt = sum(
                            it["amount"] for it in dt["nutrients"] if it["nutrientId"] == n_trigger
                        )
                        if trig_amt > 0:
                            trig_sum += trig_amt
                            pids.add(dt["productId"])
                if trig_sum >= threshold and da["timeOfDay"] not in seen_times:
                    seen_times.add(da["timeOfDay"])
                    out.append({
                        "ruleId": r["id"],
                        "severity": r["severity"],
                        "timeOfDay": da["timeOfDay"],
                        "productIds": sorted(pids),
                        "uncertain": r["uncertain"],
                    })

    return out


def match_dose_to_schedule_window(dose_at_iso, product_id, candidates):
    """Khớp lần uống trong khung ±2 giờ quanh giờ lịch (chỉ xét unmarked).
    `candidates`: danh sách {scheduleId, productId, day, timeOfDay}.
    """
    dose_dt = datetime.fromisoformat(dose_at_iso)
    best = None
    for c in candidates:
        if c["productId"] != product_id:
            continue
        base = datetime.strptime(c["day"], "%Y-%m-%d")
        sched_minutes = c["timeOfDay"]
        sched_dt = base.replace(hour=sched_minutes // 60, minute=sched_minutes % 60, second=0, microsecond=0)
        diff_min = abs((dose_dt - sched_dt).total_seconds()) / 60.0
        if diff_min <= 120.0 + 1e-9:
            key = (diff_min, sched_dt, c["scheduleId"])
            if best is None or key < best[0]:
                best = (key, {"scheduleId": c["scheduleId"], "day": c["day"]})
    return None if best is None else best[1]


SCHEDULE_RULE_CASES = [
    (
        "ca_over_500_with_meal_ok_and_ca_iron_zinc",
        {"breakfast": 420, "lunch": 720, "dinner": 1140},
        [
            {
                "scheduleId": 1, "productId": 10, "timeOfDay": 480,  # 08:00 (trong ±1h bữa sáng 07:00)
                "nutrients": [
                    {"nutrientId": "calcium", "form": "calcium_carbonate", "amount": 500.0},
                    {"nutrientId": "vitD", "form": "unknown", "amount": 10.0},
                ],
            },
            {
                "scheduleId": 2, "productId": 11, "timeOfDay": 480,
                "nutrients": [
                    {"nutrientId": "calcium", "form": "calcium_citrate", "amount": 100.0},
                    {"nutrientId": "iron", "form": "ferrous_fumarate", "amount": 25.0},
                ],
            },
            {
                "scheduleId": 3, "productId": 12, "timeOfDay": 510,  # 08:30 (cách 08:00 30p <= 60p)
                "nutrients": [
                    {"nutrientId": "zinc", "form": "unknown", "amount": 15.0},
                ],
            },
        ],
    ),
    (
        "vitd_and_ca_carb_outside_meal_safe_iron_zinc",
        {"breakfast": 420, "lunch": 720, "dinner": 1140},
        [
            {
                "scheduleId": 4, "productId": 20, "timeOfDay": 540,  # 09:00 (cách bữa sáng 120p > 60p)
                "nutrients": [
                    {"nutrientId": "calcium", "form": "calcium_carbonate", "amount": 300.0},
                    {"nutrientId": "vitD", "form": "unknown", "amount": 25.0},
                    {"nutrientId": "iron", "form": "ferrous_sulfate", "amount": 18.0},
                ],
            },
            {
                "scheduleId": 5, "productId": 21, "timeOfDay": 1200,  # 20:00 (cùng bữa tối 19:00)
                "nutrients": [
                    {"nutrientId": "zinc", "form": "unknown", "amount": 15.0},
                ],
            },
        ],
    ),
]

WINDOW_MATCH_CASES = [
    (
        "midnight_prev_day_match",
        "2026-11-26T00:30:00",
        10,
        [
            {"scheduleId": 1, "productId": 10, "day": "2026-11-25", "timeOfDay": 1380},  # 23:00 hôm qua (+90p)
            {"scheduleId": 2, "productId": 10, "day": "2026-11-26", "timeOfDay": 480},   # 08:00 hôm nay
        ],
    ),
    (
        "overlapping_windows_nearest",
        "2026-11-26T08:40:00",
        10,
        [
            {"scheduleId": 1, "productId": 10, "day": "2026-11-26", "timeOfDay": 480},  # 08:00 (40p)
            {"scheduleId": 2, "productId": 10, "day": "2026-11-26", "timeOfDay": 540},  # 09:00 (20p)
        ],
    ),
    (
        "outside_2h_window",
        "2026-11-26T14:05:00",
        10,
        [
            {"scheduleId": 1, "productId": 10, "day": "2026-11-26", "timeOfDay": 1200},  # 20:00
        ],
    ),
]


SANITY_CASES = [
    ("vitD_normal_ug", "man30", {"nutrientId": "vitD", "source": "supplement", "form": "unknown", "amount": 25, "unit": "ug"}),
    ("vitD_mistake_mg", "man30", {"nutrientId": "vitD", "source": "supplement", "form": "unknown", "amount": 25, "unit": "mg"}),
    ("vitB12_mistake_mg_no_ul", "man30", {"nutrientId": "vitB12", "source": "supplement", "form": "unknown", "amount": 10, "unit": "mg"}),
    ("magnesium_exceed_ul", "man30", {"nutrientId": "magnesium", "source": "supplement", "form": "unknown", "amount": 400, "unit": "mg"}),
    ("free_nutrient", "man30", {"nutrientId": None, "freeName": "Coenzyme Q10", "source": "supplement", "form": "unknown", "amount": 100, "unit": "mg"}),
]


def main():
    self_check()
    cases = {
        "profiles": PROFILES,
        "days": DAYS,
        "workoutSets": WORKOUT_SETS,
        "extendedUnitConversions": EXTENDED_PACK["unitConversions"],
        "lineCases": [{"name": n, "extended": ext, "input": inp} for n, ext, inp in LINE_CASES],
        "expect": {
            "eer": {}, "group": {}, "targets": {}, "uls": {}, "ulDay": {}, "macros": {},
            "sugar": {}, "ulAvg": {}, "activity": {}, "workoutKcal": {},
            "dailyReport": {}, "averageReport": {}, "convertLine": {}, "sanityCheck": {},
            "scheduleRules": {}, "windowMatch": {},
        },
        "sanityCases": [{"name": n, "profile": p, "input": inp} for n, p, inp in SANITY_CASES],
        "scheduleRuleCases": [{"name": n, "mealTimes": m, "doses": d} for n, m, d in SCHEDULE_RULE_CASES],
        "windowMatchCases": [{"name": n, "doseAt": dt, "productId": pid, "candidates": c} for n, dt, pid, c in WINDOW_MATCH_CASES],
    }
    ex = cases["expect"]
    for name, p in PROFILES.items():
        k, why = eer(p)
        ex["eer"][name] = {"kcal": k, "reason": why}
        ex["group"][name] = group_def(p)["id"]
        ex["targets"][name] = {nid: target(p, nid) for nid in
                               ("protein", "iron", "calcium", "vitD", "folate", "fiber", "potassium", "vitK", "magnesium")}
        ex["uls"][name] = {nid: ul_for(p, nid) for nid in ("calcium", "phosphorus", "vitA", "retinol", "vitE", "vanadium")}
        for dname, day in DAYS.items():
            ex["ulDay"][f"{name}|{dname}"] = ul_flags(p, [day])
            ex["macros"][f"{name}|{dname}"] = macros(p, [day])
        ex["workoutKcal"][name] = workout_kcal(p, "12050", 30)
    for dname, day in DAYS.items():
        ex["sugar"][dname] = sugar(day)
    # trung bình 7 ngày: 1 ngày nhiều bổ sung + 6 ngày cân bằng; và 2 ngày có ghi + 5 ngày []
    week = [DAYS["supplements_heavy"]] + [DAYS["balanced"]] * 6
    ex["ulAvg"]["man30|1heavy6balanced"] = ul_flags(PROFILES["man30"], week, "sevenDayAverage")
    sparse_week = [DAYS["supplements_heavy"], DAYS["balanced"], [], [], [], [], []]
    both_week = [DAYS["supplements_heavy"], DAYS["vitE_boundary"], [], [], [], [], []]
    ex["ulAvg"]["man30|sparse2of7"] = ul_flags(PROFILES["man30"], sparse_week, "sevenDayAverage")
    ex["ulAvg"]["man30|both2of7"] = ul_flags(PROFILES["man30"], both_week, "sevenDayAverage")
    for wname, ws in WORKOUT_SETS.items():
        ex["activity"][wname] = activity_summary(ws)
    ex["dailyReport"]["man30|heavy_sparse"] = daily_report(
        PROFILES["man30"], DAYS["supplements_heavy"],
        workouts=[{"code": "17200", "minutes": 30, "day": "2026-11-24"}],
        last7=sparse_week,
        workouts7=WORKOUT_SETS["athlete"],
    )
    ex["dailyReport"]["man30|heavy_both_flags"] = daily_report(
        PROFILES["man30"], DAYS["supplements_heavy"],
        workouts=[{"code": "17200", "minutes": 30, "day": "2026-11-24"}],
        last7=both_week,
        workouts7=WORKOUT_SETS["athlete"],
    )
    ex["averageReport"]["man30|sparse2of7"] = average_report(
        PROFILES["man30"], sparse_week, workouts7=WORKOUT_SETS["athlete"],
    )
    ex["averageReport"]["man30|both2of7"] = average_report(
        PROFILES["man30"], both_week, workouts7=WORKOUT_SETS["athlete"],
    )
    ex["averageReport"]["man30|empty"] = average_report(PROFILES["man30"], [])
    for cname, ext, inp in LINE_CASES:
        ex["convertLine"][cname] = convert_intake_line(inp, EXTENDED_PACK if ext else PACK)
    for sname, pname, inp in SANITY_CASES:
        ex["sanityCheck"][sname] = check_ingredient_sanity(PROFILES[pname], inp, PACK)
    for rname, meal_t, doses in SCHEDULE_RULE_CASES:
        ex["scheduleRules"][rname] = evaluate_schedule_rules(meal_t, doses, PACK)
    for wname, dt, pid, cands in WINDOW_MATCH_CASES:
        ex["windowMatch"][wname] = match_dose_to_schedule_window(dt, pid, cands)

    out = ROOT / "packages/health_engine/test/fixtures/cases.json"
    out.parent.mkdir(parents=True, exist_ok=True)
    out.write_text(json.dumps(cases, ensure_ascii=False, indent=1), encoding="utf-8")
    print(f"wrote {out} ({len(LINE_CASES)} ca chuyển đổi dòng)")


if __name__ == "__main__":
    main()
