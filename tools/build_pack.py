#!/usr/bin/env python3
"""Sinh gói dữ liệu tham chiếu (reference_pack.json) cho engine.

Chỉ lưu số liệu (sự kiện) theo cấu trúc riêng của dự án, kèm nguồn và link.
Không chép văn bản hay bố cục bảng của NASEM / LPI.

Chạy:  python3 tools/build_pack.py
Kết quả: packages/health_engine/assets/reference_pack.json và app/assets/reference_pack.json
"""
import json
import pathlib
import sys

if hasattr(sys.stdout, "reconfigure"):
    sys.stdout.reconfigure(encoding="utf-8")

PACK_VERSION = "2026.11.25-2"
RETRIEVED = "2026-11-25"

# ---------------------------------------------------------------- nguồn
SOURCES = [
    {"id": "nasem_dri_summary", "label": "A",
     "title": "NASEM – bảng tóm tắt DRI (RDA, AI, UL), cập nhật 2019",
     "url": "https://www.nationalacademies.org/read/25353/chapter/28",
     "via": "https://ods.od.nih.gov/healthinformation/nutrientrecommendations/",
     "retrieved": "2026-11-25"},
    {"id": "nasem_energy_2023", "label": "A",
     "title": "NASEM – Dietary Reference Intakes for Energy (2023), phương trình EER",
     "url": "https://www.nationalacademies.org/read/26818/chapter/7"},
    {"id": "nasem_amdr", "label": "A",
     "title": "NASEM – AMDR (khoảng phân bố năng lượng từ đạm, béo, bột đường)",
     "url": "https://nap.nationalacademies.org/read/10490/chapter/13"},
    {"id": "nasem_vit_e_2000", "label": "A",
     "title": "NASEM – Dietary Reference Intakes for Vitamin C, Vitamin E, Selenium, and Carotenoids (2000), Ch. 6 & Ch. 9",
     "url": "https://www.nationalacademies.org/read/9810/chapter/8",
     "retrieved": "2026-11-25"},
    {"id": "nih_ods_vit_e", "label": "A",
     "title": "NIH ODS – Vitamin E Fact Sheet for Health Professionals (cập nhật 19/10/2026)",
     "url": "https://ods.od.nih.gov/factsheets/VitaminE-HealthProfessional/",
     "retrieved": "2026-11-25"},
    {"id": "fda_21cfr_101_36", "label": "A",
     "title": "eCFR – 21 CFR 101.36 Nutrition labeling of dietary supplements",
     "url": "https://www.ecfr.gov/current/title-21/chapter-I/subchapter-B/part-101/subpart-A/section-101.36",
     "retrieved": "2026-11-28"},
    {"id": "fda_unit_conversions", "label": "A",
     "title": "FDA – Guidance for Industry: Converting Units of Measure for Folate, Niacin, and Vitamins A, D, and E (2019); 21 CFR 101.9, 101.36",
     "url": "https://www.fda.gov/media/129863/download",
     "retrieved": "2026-11-25"},
    {"id": "dga_2025_2030", "label": "A",
     "title": "USDA, HHS – Dietary Guidelines for Americans 2025–2030",
     "url": "https://cdn.realfood.gov/DGA.pdf",
     "retrieved": "2026-11-24"},
    {"id": "compendium_2024", "label": "A",
     "title": "2024 Adult Compendium of Physical Activities (miễn phí cả cho mục đích thương mại)",
     "url": "https://pacompendium.com/adult-compendium/"},
    {"id": "pag_2", "label": "A",
     "title": "HHS – Physical Activity Guidelines for Americans, bản 2 (2018)",
     "url": "https://odphp.health.gov/sites/default/files/2019-09/Physical_Activity_Guidelines_2nd_edition.pdf",
     "retrieved": "2026-11-25"},
    {"id": "nih_ods_calcium", "label": "A",
     "title": "NIH ODS – Calcium Fact Sheet for Health Professionals",
     "url": "https://ods.od.nih.gov/factsheets/Calcium-HealthProfessional/",
     "retrieved": "2026-11-25"},
    {"id": "nih_ods_iron", "label": "A",
     "title": "NIH ODS – Iron Fact Sheet for Health Professionals",
     "url": "https://ods.od.nih.gov/factsheets/Iron-HealthProfessional/",
     "retrieved": "2026-11-25"},
    {"id": "nih_ods_zinc", "label": "A",
     "title": "NIH ODS – Zinc Fact Sheet for Health Professionals",
     "url": "https://ods.od.nih.gov/factsheets/Zinc-HealthProfessional/",
     "retrieved": "2026-11-23"},
    {"id": "nih_ods_vit_d", "label": "A",
     "title": "NIH ODS – Vitamin D Fact Sheet for Health Professionals",
     "url": "https://ods.od.nih.gov/factsheets/VitaminD-HealthProfessional/",
     "retrieved": "2026-11-23"},
]

MIN_PROFILE_AGE = 18


def _grp(id_, sex, stage, min_age, max_age, amdr_key, protein_per_kg, eer_type):
    return {
        "id": id_,
        "sex": sex,
        "stage": stage,
        "minAge": min_age,
        "maxAge": max_age,
        "amdrKey": amdr_key,
        "proteinPerKg": protein_per_kg,
        "eerType": eer_type,
    }


GROUPS_META = [
    _grp("m14_18", "male", "none", 14, 18, "age4_18", None, "none"),
    _grp("m19_30", "male", "none", 19, 30, "adult19", 0.8, "adult"),
    _grp("m31_50", "male", "none", 31, 50, "adult19", 0.8, "adult"),
    _grp("m51_70", "male", "none", 51, 70, "adult19", 0.8, "adult"),
    _grp("m71",    "male", "none", 71, None, "adult19", 0.8, "adult"),
    _grp("f14_18", "female", "none", 14, 18, "age4_18", None, "none"),
    _grp("f19_30", "female", "none", 19, 30, "adult19", 0.8, "adult"),
    _grp("f31_50", "female", "none", 31, 50, "adult19", 0.8, "adult"),
    _grp("f51_70", "female", "none", 51, 70, "adult19", 0.8, "adult"),
    _grp("f71",    "female", "none", 71, None, "adult19", 0.8, "adult"),
    _grp("p14_18", "female", "pregnant", 14, 18, "age4_18", None, "none"),
    _grp("p19_30", "female", "pregnant", 19, 30, "adult19", None, "pregnant"),
    _grp("p31_50", "female", "pregnant", 31, None, "adult19", None, "pregnant"),
    _grp("l14_18", "female", "lactating", 14, 18, "age4_18", None, "none"),
    _grp("l19_30", "female", "lactating", 19, 30, "adult19", None, "lactating"),
    _grp("l31_50", "female", "lactating", 31, None, "adult19", None, "lactating"),
]

GROUPS = [g["id"] for g in GROUPS_META]


def row(m14, m19, m31, m51, m71, f14, f19, f31, f51, f71, p14, p19, p31, l14, l19, l31):
    vals = [m14, m19, m31, m51, m71, f14, f19, f31, f51, f71, p14, p19, p31, l14, l19, l31]
    return {g: v for g, v in zip(GROUPS, vals) if v is not None}


def ul_adult(v14, v19_50, v51_70, v71, p14, p19, l14, l19):
    """UL theo nhóm; nam và nữ giống nhau ở mọi chất có UL cho người lớn."""
    d = {}
    for sex in ("m", "f"):
        d[f"{sex}14_18"] = v14
        d[f"{sex}19_30"] = v19_50
        d[f"{sex}31_50"] = v19_50
        d[f"{sex}51_70"] = v51_70
        d[f"{sex}71"] = v71
    d["p14_18"] = p14
    d["p19_30"] = p19
    d["p31_50"] = p19
    d["l14_18"] = l14
    d["l19_30"] = l19
    d["l31_50"] = l19
    return {k: v for k, v in d.items() if v is not None}


# ul_scope:
#   total        – mọi nguồn (thực phẩm + tăng cường + bổ sung)
#   supplement   – chỉ từ thuốc/bổ sung (magie)
#   synthetic    – dạng tổng hợp từ bổ sung + thực phẩm tăng cường (niacin, vitamin E)
#   ul_key       – UL so với một khóa khác (vitamin A: retinol; folate: folic acid)
NUTRIENTS = []


def nut(id_, name_vi, unit, kind, rda, ul=None, ul_scope="total", ul_key=None, group="vitamin"):
    NUTRIENTS.append({
        "id": id_, "nameVi": name_vi, "unit": unit, "group": group,
        "kind": kind, "target": rda, "ul": ul or {}, "ulScope": ul_scope,
        "ulKey": ul_key, "source": "nasem_dri_summary",
    })


# ---------------------------------------------------------------- vitamin
nut("vitA", "Vitamin A", "ug_RAE", "RDA",
    row(900, 900, 900, 900, 900, 700, 700, 700, 700, 700, 750, 770, 770, 1200, 1300, 1300),
    ul_adult(2800, 3000, 3000, 3000, 2800, 3000, 2800, 3000), "total", ul_key="retinol")
nut("retinol", "Vitamin A dạng có sẵn (retinol)", "ug", "NONE", {},
    ul_adult(2800, 3000, 3000, 3000, 2800, 3000, 2800, 3000), "total")
nut("vitC", "Vitamin C", "mg", "RDA",
    row(75, 90, 90, 90, 90, 65, 75, 75, 75, 75, 80, 85, 85, 115, 120, 120),
    ul_adult(1800, 2000, 2000, 2000, 1800, 2000, 1800, 2000))
nut("vitD", "Vitamin D", "ug", "RDA",
    row(15, 15, 15, 15, 20, 15, 15, 15, 15, 20, 15, 15, 15, 15, 15, 15),
    ul_adult(100, 100, 100, 100, 100, 100, 100, 100))
nut("vitE", "Vitamin E (alpha-tocopherol)", "mg", "RDA",
    row(15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 19, 19, 19),
    ul_adult(800, 1000, 1000, 1000, 800, 1000, 800, 1000), "synthetic")
nut("vitK", "Vitamin K", "ug", "AI",
    row(75, 120, 120, 120, 120, 75, 90, 90, 90, 90, 75, 90, 90, 75, 90, 90))
nut("thiamin", "Vitamin B1 (thiamin)", "mg", "RDA",
    row(1.2, 1.2, 1.2, 1.2, 1.2, 1.0, 1.1, 1.1, 1.1, 1.1, 1.4, 1.4, 1.4, 1.4, 1.4, 1.4))
nut("riboflavin", "Vitamin B2 (riboflavin)", "mg", "RDA",
    row(1.3, 1.3, 1.3, 1.3, 1.3, 1.0, 1.1, 1.1, 1.1, 1.1, 1.4, 1.4, 1.4, 1.6, 1.6, 1.6))
nut("niacin", "Vitamin B3 (niacin)", "mg_NE", "RDA",
    row(16, 16, 16, 16, 16, 14, 14, 14, 14, 14, 18, 18, 18, 17, 17, 17),
    ul_adult(30, 35, 35, 35, 30, 35, 30, 35), "synthetic")
nut("vitB6", "Vitamin B6", "mg", "RDA",
    row(1.3, 1.3, 1.3, 1.7, 1.7, 1.2, 1.3, 1.3, 1.5, 1.5, 1.9, 1.9, 1.9, 2.0, 2.0, 2.0),
    ul_adult(80, 100, 100, 100, 80, 100, 80, 100))
nut("folate", "Folate", "ug_DFE", "RDA",
    row(400, 400, 400, 400, 400, 400, 400, 400, 400, 400, 600, 600, 600, 500, 500, 500),
    ul_adult(800, 1000, 1000, 1000, 800, 1000, 800, 1000), "total", ul_key="folicAcid")
nut("folicAcid", "Axit folic (dạng tổng hợp)", "ug", "NONE", {},
    ul_adult(800, 1000, 1000, 1000, 800, 1000, 800, 1000), "total")
nut("vitB12", "Vitamin B12", "ug", "RDA",
    row(2.4, 2.4, 2.4, 2.4, 2.4, 2.4, 2.4, 2.4, 2.4, 2.4, 2.6, 2.6, 2.6, 2.8, 2.8, 2.8))
nut("pantothenic", "Vitamin B5 (axit pantothenic)", "mg", "AI",
    row(5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 6, 6, 6, 7, 7, 7))
nut("biotin", "Biotin", "ug", "AI",
    row(25, 30, 30, 30, 30, 25, 30, 30, 30, 30, 30, 30, 30, 35, 35, 35))
nut("choline", "Choline", "mg", "AI",
    row(550, 550, 550, 550, 550, 400, 425, 425, 425, 425, 450, 450, 450, 550, 550, 550),
    ul_adult(3000, 3500, 3500, 3500, 3000, 3500, 3000, 3500))

# ---------------------------------------------------------------- khoáng
G = "mineral"
nut("calcium", "Canxi", "mg", "RDA",
    row(1300, 1000, 1000, 1000, 1200, 1300, 1000, 1000, 1200, 1200, 1300, 1000, 1000, 1300, 1000, 1000),
    ul_adult(3000, 2500, 2000, 2000, 3000, 2500, 3000, 2500), group=G)
nut("chromium", "Crom", "ug", "AI",
    row(35, 35, 35, 30, 30, 24, 25, 25, 20, 20, 29, 30, 30, 44, 45, 45), group=G)
nut("copper", "Đồng", "ug", "RDA",
    row(890, 900, 900, 900, 900, 890, 900, 900, 900, 900, 1000, 1000, 1000, 1300, 1300, 1300),
    ul_adult(8000, 10000, 10000, 10000, 8000, 10000, 8000, 10000), group=G)
nut("fluoride", "Florua", "mg", "AI",
    row(3, 4, 4, 4, 4, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3),
    ul_adult(10, 10, 10, 10, 10, 10, 10, 10), group=G)
nut("iodine", "Iốt", "ug", "RDA",
    row(150, 150, 150, 150, 150, 150, 150, 150, 150, 150, 220, 220, 220, 290, 290, 290),
    ul_adult(900, 1100, 1100, 1100, 900, 1100, 900, 1100), group=G)
nut("iron", "Sắt", "mg", "RDA",
    row(11, 8, 8, 8, 8, 15, 18, 18, 8, 8, 27, 27, 27, 10, 9, 9),
    ul_adult(45, 45, 45, 45, 45, 45, 45, 45), group=G)
nut("magnesium", "Magie", "mg", "RDA",
    row(410, 400, 420, 420, 420, 360, 310, 320, 320, 320, 400, 350, 360, 360, 310, 320),
    ul_adult(350, 350, 350, 350, 350, 350, 350, 350), "supplement", group=G)
nut("manganese", "Mangan", "mg", "AI",
    row(2.2, 2.3, 2.3, 2.3, 2.3, 1.6, 1.8, 1.8, 1.8, 1.8, 2.0, 2.0, 2.0, 2.6, 2.6, 2.6),
    ul_adult(9, 11, 11, 11, 9, 11, 9, 11), group=G)
nut("molybdenum", "Molypden", "ug", "RDA",
    row(43, 45, 45, 45, 45, 43, 45, 45, 45, 45, 50, 50, 50, 50, 50, 50),
    ul_adult(1700, 2000, 2000, 2000, 1700, 2000, 1700, 2000), group=G)
nut("phosphorus", "Phốt pho", "mg", "RDA",
    row(1250, 700, 700, 700, 700, 1250, 700, 700, 700, 700, 1250, 700, 700, 1250, 700, 700),
    ul_adult(4000, 4000, 4000, 3000, 3500, 3500, 4000, 4000), group=G)
nut("selenium", "Selen", "ug", "RDA",
    row(55, 55, 55, 55, 55, 55, 55, 55, 55, 55, 60, 60, 60, 70, 70, 70),
    ul_adult(400, 400, 400, 400, 400, 400, 400, 400), group=G)
nut("zinc", "Kẽm", "mg", "RDA",
    row(11, 11, 11, 11, 11, 9, 8, 8, 8, 8, 12, 11, 11, 13, 12, 12),
    ul_adult(34, 40, 40, 40, 34, 40, 34, 40), group=G)
nut("potassium", "Kali", "mg", "AI",
    row(3000, 3400, 3400, 3400, 3400, 2300, 2600, 2600, 2600, 2600, 2600, 2900, 2900, 2500, 2800, 2800), group=G)
nut("sodium", "Natri", "mg", "AI",
    row(*([1500] * 16)), group=G)
nut("chloride", "Clorua", "mg", "AI",
    row(2300, 2300, 2300, 2000, 1800, 2300, 2300, 2300, 2000, 1800, 2300, 2300, 2300, 2300, 2300, 2300),
    ul_adult(3600, 3600, 3600, 3600, 3600, 3600, 3600, 3600), group=G)
nut("boron", "Bo", "mg", "NONE", {},
    ul_adult(17, 20, 20, 20, 17, 20, 17, 20), group=G)
nut("nickel", "Niken", "mg", "NONE", {},
    ul_adult(1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0), group=G)
nut("vanadium", "Vanadi", "mg", "NONE", {},
    ul_adult(None, 1.8, 1.8, 1.8, None, None, None, None), group=G)

# ---------------------------------------------------------------- đa lượng
M = "macro"
nut("water", "Tổng nước (gồm nước trong thức ăn)", "L", "AI",
    row(3.3, 3.7, 3.7, 3.7, 3.7, 2.3, 2.7, 2.7, 2.7, 2.7, 3.0, 3.0, 3.0, 3.8, 3.8, 3.8), group=M)
nut("carbohydrate", "Bột đường (carbohydrate)", "g", "RDA",
    row(130, 130, 130, 130, 130, 130, 130, 130, 130, 130, 175, 175, 175, 210, 210, 210), group=M)
nut("fiber", "Chất xơ", "g", "AI",
    row(38, 38, 38, 30, 30, 26, 25, 25, 21, 21, 28, 28, 28, 29, 29, 29), group=M)
nut("protein", "Đạm (protein)", "g", "RDA",
    row(52, 56, 56, 56, 56, 46, 46, 46, 46, 46, 71, 71, 71, 71, 71, 71), group=M)
nut("linoleic", "Axit linoleic (omega-6)", "g", "AI",
    row(16, 17, 17, 14, 14, 11, 12, 12, 11, 11, 13, 13, 13, 13, 13, 13), group=M)
nut("ala", "Axit alpha-linolenic (omega-3)", "g", "AI",
    row(1.6, 1.6, 1.6, 1.6, 1.6, 1.1, 1.1, 1.1, 1.1, 1.1, 1.4, 1.4, 1.4, 1.3, 1.3, 1.3), group=M)

# ---------------------------------------------------------------- năng lượng
# TEE = a + b*tuổi + c*cao(cm) + d*nặng(kg) [+ e*tuần thai]
EER = {
    "source": "nasem_energy_2023",
    "palRanges19": {"inactive": [1.00, 1.53], "lowActive": [1.53, 1.68],
                    "active": [1.68, 1.85], "veryActive": [1.85, 2.50]},
    "adult": {
        "male": {
            "inactive":   {"a": 753.07, "age": -10.83, "height": 6.50, "weight": 14.10},
            "lowActive":  {"a": 581.47, "age": -10.83, "height": 8.30, "weight": 14.94},
            "active":     {"a": 1004.82, "age": -10.83, "height": 6.52, "weight": 15.91},
            "veryActive": {"a": -517.88, "age": -10.83, "height": 15.61, "weight": 19.11},
        },
        "female": {
            "inactive":   {"a": 584.90, "age": -7.01, "height": 5.72, "weight": 11.71},
            "lowActive":  {"a": 575.77, "age": -7.01, "height": 6.60, "weight": 12.14},
            "active":     {"a": 710.25, "age": -7.01, "height": 6.54, "weight": 12.34},
            "veryActive": {"a": 511.83, "age": -7.01, "height": 9.07, "weight": 12.56},
        },
    },
    # quý 2 và 3; quý 1 dùng phương trình nữ không mang thai
    "pregnancy": {
        "inactive":   {"a": 1131.20, "age": -2.04, "height": 0.34, "weight": 12.15, "gestWeek": 9.16},
        "lowActive":  {"a": 693.35, "age": -2.04, "height": 5.73, "weight": 10.20, "gestWeek": 9.16},
        "active":     {"a": -223.84, "age": -2.04, "height": 13.23, "weight": 8.15, "gestWeek": 9.16},
        "veryActive": {"a": -779.72, "age": -2.04, "height": 18.45, "weight": 8.73, "gestWeek": 9.16},
    },
    "pregnancyFirstTrimesterMaxWeek": 13,
    # năng lượng tích lũy theo BMI trước khi mang thai (kcal/ngày)
    "pregnancyDeposition": {"underweight": 300, "normal": 200, "overweight": 150, "obese": -50},
    # cho con bú: cộng chi phí tạo sữa, trừ năng lượng huy động từ mô
    "lactation": {"0_6": {"milk": 540, "mobilization": 140}, "7_12": {"milk": 380, "mobilization": 0}},
    "note": "EER là mức giữ cân; không thiết kế cho mục tiêu tăng hoặc giảm cân",
}

AMDR = {"source": "nasem_amdr",
        "adult19": {"protein": [10, 35], "fat": [20, 35], "carbohydrate": [45, 65]},
        "age4_18": {"protein": [10, 30], "fat": [25, 35], "carbohydrate": [45, 65]}}

# DGA 2025–2030, tr. 3 (tra 24/11/2026): "no amount of added sugars ... is recommended",
# "one meal should contain no more than 10 grams of added sugars". Không có giới hạn theo %
# năng lượng/ngày (mức 10% của bản 2020–2025; 10% ở bản mới là của chất béo bão hòa).
ADDED_SUGAR = {"source": "dga_2025_2030", "maxGramsPerMeal": 10}

ENERGY_PER_GRAM = {"protein": 4, "carbohydrate": 4, "fat": 9, "alcohol": 7,
                   "note": "hệ số Atwater chung"}

# ---------------------------------------------------------------- vận động
ACTIVITIES = [
    # code, MET, tên tiếng Việt, muscleStrengthening (theo PAG bản 2, 2018)
    ("17152", 2.8, "Đi bộ chậm (3,2–3,9 km/h)", False),
    ("17170", 3.0, "Đi bộ 4 km/h", False),
    ("17190", 3.8, "Đi bộ vừa (4,5–5,5 km/h)", False),
    ("17200", 4.8, "Đi bộ nhanh (5,6–6,3 km/h)", False),
    ("17220", 5.5, "Đi bộ rất nhanh (6,4–7,1 km/h)", False),
    ("17230", 7.0, "Đi bộ rất nhanh (7,2–7,9 km/h)", False),
    ("17160", 3.5, "Đi dạo", False),
    ("17080", 6.0, "Leo núi, đi bộ đường dài", False),
    ("17131", 6.8, "Leo cầu thang", False),
    ("12020", 7.5, "Chạy bộ nhẹ (tự chọn tốc độ)", False),
    ("12028", 6.5, "Chạy 6,4–6,8 km/h", False),
    ("12030", 8.5, "Chạy 8,0–8,4 km/h", False),
    ("12050", 9.3, "Chạy 9,7–10,1 km/h", False),
    ("12060", 10.5, "Chạy 10,8 km/h", False),
    ("12070", 11.0, "Chạy 11,3 km/h", False),
    ("12090", 12.0, "Chạy 12,9 km/h", False),
    ("12110", 13.0, "Chạy 14,5 km/h", False),
    ("12120", 14.8, "Chạy 16,1 km/h", False),
    ("01010", 4.0, "Đạp xe nhẹ (dưới 16 km/h)", False),
    ("01011", 6.8, "Đạp xe đi làm", False),
    ("01020", 6.8, "Đạp xe 16–19 km/h", False),
    ("01030", 8.0, "Đạp xe 19–22 km/h", False),
    ("01040", 10.0, "Đạp xe 22–25 km/h", False),
    ("01214", 4.0, "Xe đạp tập, nhẹ", False),
    ("01220", 6.0, "Xe đạp tập, vừa", False),
    ("01236", 10.8, "Xe đạp tập, mạnh", False),
    ("02054", 3.5, "Tập tạ nhiều bài, 8–15 lần", True),
    ("02050", 6.0, "Tập tạ nặng, thể hình", True),
    ("02024", 2.8, "Bài tập thể lực nhẹ (plank, gập bụng)", True),
    ("02022", 3.8, "Bài tập thể lực vừa (chống đẩy, lunge)", True),
    ("02020", 7.5, "Bài tập thể lực mạnh (burpee, nhảy)", True),
    ("02150", 2.3, "Yoga Hatha", False),
    ("02160", 4.0, "Power yoga", False),
    ("02105", 2.8, "Pilates", False),
    ("02048", 5.0, "Máy elliptical, vừa", False),
    ("02071", 5.0, "Máy chèo thuyền, vừa", False),
    ("02035", 5.0, "Circuit training, vừa", True),
    ("02040", 7.5, "Circuit training, mạnh", True),
    ("02210", 7.0, "HIIT, vừa", False),
    ("02214", 11.0, "HIIT, mạnh", False),
    ("02068", 11.0, "Nhảy dây", False),
    ("02101", 2.3, "Giãn cơ nhẹ", False),
    ("15030", 5.5, "Cầu lông phong trào", False),
    ("15020", 7.0, "Cầu lông thi đấu", False),
    ("15610", 7.0, "Bóng đá phong trào", False),
    ("15605", 9.5, "Bóng đá thi đấu", False),
    ("15055", 7.5, "Bóng rổ", False),
    ("15720", 3.0, "Bóng chuyền phong trào", False),
    ("15675", 6.8, "Quần vợt, vừa", False),
    ("15660", 4.0, "Bóng bàn", False),
    ("15670", 3.3, "Thái cực quyền, khí công", False),
    ("18240", 5.8, "Bơi sải chậm", False),
    ("18230", 9.8, "Bơi sải nhanh", False),
    ("18310", 6.0, "Bơi thư giãn", False),
    ("18265", 5.3, "Bơi ếch", False),
    ("18255", 4.8, "Bơi ngửa", False),
    ("18355", 5.5, "Thể dục dưới nước", False),
]

PAG = {"source": "pag_2", "moderateMinMet": 3.0, "vigorousMinMet": 6.0,
       "weeklyModerateMin": [150, 300], "weeklyVigorousMin": [75, 150],
       "strengthDaysPerWeek": 2}

# Gợi ý mức vận động cho EER từ nhật ký (heuristic của app, KHÔNG phải chuẩn):
# phút tương đương vừa mỗi ngày (phút mạnh tính gấp đôi, như PAG) trung bình 7 ngày.
PAL_SUGGESTION = {"kind": "app_heuristic",
                  "moderateEquivalentMinPerDay": {"lowActive": 30, "active": 60, "veryActive": 120},
                  "note": "Chỉ là gợi ý; người dùng tự xác nhận mức vận động"}

UNIT_CONVERSIONS = {
    "vitD_IU_to_ug": 0.025,
    "vitA_retinol_IU_to_ug_RAE": 0.3,
    "vitA_supplemental_betacarotene_IU_to_ug_RAE": 0.3,
    "vitA_food_betacarotene_IU_to_ug_RAE": 0.05,
    "vitE_natural_IU_to_mg": 0.67,
    "vitE_synthetic_IU_to_mg": 0.45,
    "vitE_ul_natural_IU_to_mg": 0.67,
    "vitE_ul_synthetic_IU_to_mg": 1000 / 1100,
    "folicAcid_ug_to_ug_DFE": 1.7,
    "vitaminEEsters": {},
    "compounds": {
        # NIH ODS Calcium Fact Sheet (tra 25/11/2026):
        # "calcium carbonate is 40% calcium by weight, whereas calcium citrate is 21% calcium"
        "calcium": {
            "calcium_carbonate": 0.40,
            "calcium_citrate": 0.21,
        },
        # NIH ODS Iron Fact Sheet (tra 25/11/2026):
        # "ferrous fumarate is 33% elemental iron by weight, whereas ferrous sulfate is 20% and ferrous gluconate is 12% elemental iron"
        "iron": {
            "ferrous_fumarate": 0.33,
            "ferrous_sulfate": 0.20,
            "ferrous_gluconate": 0.12,
        },
    },
    "source": "fda_unit_conversions",
    "ulSource": "nih_ods_vit_e",
    "ulCrossRefSource": "nasem_vit_e_2000",
    "note": "Hệ số RDA/IU theo FDA 2019 Bảng 3 (FDA-2016-D-4484, tr. 19; 21 CFR 101.9/101.36); hệ số UL vitamin E theo NASEM 2000 Bảng 9-1 và NIH ODS (tra 25/11/2026); tỷ lệ nguyên tố hợp chất theo NIH ODS (tra 25/11/2026)",
}

COMPOUND_META = {
    "calcium": {
        "calcium_carbonate": {"nameVi": "Canxi carbonat (40%)", "source": "nih_ods_calcium"},
        "calcium_citrate": {"nameVi": "Canxi citrat (21%)", "source": "nih_ods_calcium"},
    },
    "iron": {
        "ferrous_fumarate": {"nameVi": "Sắt fumarat (33%)", "source": "nih_ods_iron"},
        "ferrous_sulfate": {"nameVi": "Sắt sulfat (20%)", "source": "nih_ods_iron"},
        "ferrous_gluconate": {"nameVi": "Sắt gluconat (12%)", "source": "nih_ods_iron"},
    },
}

# Lượng ghi trên bảng Supplement Facts là lượng nguyên tố, kể cả khi ghi nguồn trong ngoặc
# ("Calcium (as calcium carbonate)"). Đặc tả label-scan-inventory, Bổ sung 1, mục B1.8.
# Tra 28/11/2026 qua bản chép của Cornell LII (eCFR chặn truy cập tự động); phải đối chiếu
# nguyên văn trên eCFR bằng Claude in Chrome trước khi gộp PR 1.
SUPPLEMENT_FACTS_ELEMENTAL = {
    "source": "fda_21cfr_101_36",
    "paragraph": "(b)(2)(ii), (d)",
    "url": "https://www.ecfr.gov/current/title-21/chapter-I/subchapter-B/part-101/subpart-A/section-101.36",
    "accessedDate": "2026-11-28",
    "quote": "The quantitative amounts by weight shall represent the weight of the dietary ingredient rather than the weight of the source",
    "markers": ["as", "from"],
    "nutrients": ["calcium", "iron"],
}

# Quy tắc lịch (tra NIH ODS Health Professional fact sheets ngày 23/11/2026, docs/plan.md mục 4).
# Mọi quy tắc đều chạy bằng dữ liệu ở cả Python reference_engine và Dart health_engine.
SCHEDULE_RULES = [
    {
        "id": "ca_single_dose_500",
        "type": "single_dose_max",
        "severity": "notice",
        "nutrients": ["calcium"],
        "forms": [],
        "threshold": 500.0,
        "unit": "mg",
        "windowMinutes": 0,
        "uncertain": False,
        "messageVi": "Canxi hấp thu tốt nhất khi mỗi lần không quá 500 mg.",
        "tipVi": "Canxi hấp thu tốt nhất khi mỗi lần không quá 500 mg.",
        "source": "nih_ods_calcium",
        "url": "https://ods.od.nih.gov/factsheets/Calcium-HealthProfessional/",
        "accessedDate": "2026-11-23",
        "quote": "Percentage of calcium absorbed depends on dose; absorption is highest in doses <= 500 mg.",
    },
    {
        "id": "ca_carbonate_with_meal",
        "type": "take_with_meal",
        "severity": "suggestion",
        "nutrients": ["calcium"],
        "forms": ["calcium_carbonate"],
        "threshold": None,
        "unit": None,
        "windowMinutes": 60,
        "uncertain": False,
        "messageVi": "Canxi carbonat hấp thu tốt hơn khi uống cùng bữa ăn.",
        "tipVi": "Canxi carbonat hấp thu tốt hơn khi uống cùng bữa ăn.",
        "source": "nih_ods_calcium",
        "url": "https://ods.od.nih.gov/factsheets/Calcium-HealthProfessional/",
        "accessedDate": "2026-11-23",
        "quote": "Calcium carbonate is absorbed most efficiently when taken with food; calcium citrate is well absorbed with or without food.",
    },
    {
        "id": "ca_iron_co_timing",
        "type": "co_timing_caution",
        "severity": "notice",
        "nutrients": ["calcium", "iron"],
        "forms": [],
        "threshold": None,
        "unit": None,
        "windowMinutes": 60,
        "uncertain": True,
        "messageVi": "Canxi có thể làm giảm hấp thu sắt (chưa chắc chắn); có thể xếp hai loại vào giờ khác nhau.",
        "tipVi": "Canxi có thể làm giảm hấp thu sắt (chưa chắc chắn); có thể xếp hai loại vào giờ khác nhau.",
        "source": "nih_ods_iron",
        "url": "https://ods.od.nih.gov/factsheets/Iron-HealthProfessional/",
        "accessedDate": "2026-11-23",
        "quote": "Some experts recommend taking calcium and iron supplements at different times, although clinical significance is uncertain.",
    },
    {
        "id": "iron_zinc_co_timing",
        "type": "co_timing_threshold",
        "severity": "notice",
        "nutrients": ["iron", "zinc"],
        "forms": [],
        "threshold": 25.0,
        "unit": "mg",
        "windowMinutes": 60,
        "uncertain": False,
        "messageVi": "Sắt từ 25 mg trở lên uống cùng lúc với kẽm làm giảm hấp thu kẽm.",
        "tipVi": "Sắt từ 25 mg trở lên uống cùng lúc với kẽm làm giảm hấp thu kẽm.",
        "source": "nih_ods_zinc",
        "url": "https://ods.od.nih.gov/factsheets/Zinc-HealthProfessional/",
        "accessedDate": "2026-11-23",
        "quote": "Large intakes of supplemental iron (>= 25 mg) taken simultaneously with zinc can reduce zinc absorption.",
    },
    {
        "id": "vitd_with_meal",
        "type": "take_with_meal",
        "severity": "suggestion",
        "nutrients": ["vitD"],
        "forms": [],
        "threshold": None,
        "unit": None,
        "windowMinutes": 60,
        "uncertain": False,
        "messageVi": "Chất béo trong bữa giúp hấp thu vitamin D; không có vẫn hấp thu một phần.",
        "tipVi": "Chất béo trong bữa giúp hấp thu vitamin D; không có vẫn hấp thu một phần.",
        "source": "nih_ods_vit_d",
        "url": "https://ods.od.nih.gov/factsheets/VitaminD-HealthProfessional/",
        "accessedDate": "2026-11-23",
        "quote": "Vitamin D is fat soluble; taking it with a meal containing some fat improves absorption, though some is absorbed without dietary fat.",
    },
]


def main():
    pack = {
        "schema": 2,
        "version": PACK_VERSION,
        "retrieved": RETRIEVED,
        "minProfileAge": MIN_PROFILE_AGE,
        "groups": GROUPS_META,
        "sources": SOURCES,
        "nutrients": NUTRIENTS,
        "eer": EER,
        "amdr": AMDR,
        "addedSugar": ADDED_SUGAR,
        "energyPerGram": ENERGY_PER_GRAM,
        "activities": [
            {"code": c, "met": m, "nameVi": n, "muscleStrengthening": s, "source": "compendium_2024"}
            for c, m, n, s in ACTIVITIES
        ],
        "pag": PAG,
        "palSuggestion": PAL_SUGGESTION,
        "unitConversions": UNIT_CONVERSIONS,
        "compoundMeta": COMPOUND_META,
        "supplementFactsElemental": SUPPLEMENT_FACTS_ELEMENTAL,
        "scheduleRules": SCHEDULE_RULES,
    }
    out = pathlib.Path(__file__).resolve().parent.parent / "packages/health_engine/assets/reference_pack.json"
    text = json.dumps(pack, ensure_ascii=False, indent=1)
    out.write_text(text, encoding="utf-8")
    # bản sao cho app Flutter (đóng gói cùng bản cài)
    app_asset = out.parents[3] / "app/assets/reference_pack.json"
    app_asset.parent.mkdir(parents=True, exist_ok=True)
    app_asset.write_text(text, encoding="utf-8")
    print(f"wrote {out} và {app_asset} ({len(NUTRIENTS)} chất, {len(ACTIVITIES)} hoạt động)")


if __name__ == "__main__":
    main()
