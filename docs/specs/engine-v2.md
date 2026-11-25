# Đặc tả: Sửa engine (việc 2)

Trạng thái: Đã duyệt  <!-- Nháp | Đã duyệt -->
Thiết kế UX: không có màn riêng (logic tính toán và gói dữ liệu); giao diện hiển thị theo [design/mvp-overview.md](../design/mvp-overview.md)
Thứ tự MVP: việc 2 trong [status.md](../status.md)

## Mục tiêu

Sửa lỗi quy đổi giới hạn vitamin E tổng hợp (đang tính thiếu một nửa) và bổ sung đầy đủ phần tính toán trong `packages/health_engine`, `tools/build_pack.py`, `tools/reference_engine.py` theo thiết kế tổng thể đã duyệt, đồng thời mở khóa `engineSupportsUlAmounts` trong `packages/journal_db` và nối đường ghi bổ sung của khung tạm trước mọi đường ghi sinh lượng tính giới hạn riêng (việc 3–5).

## Người dùng và tình huống

- Không thêm màn hình hay luồng người dùng mới; kết quả được dùng trực tiếp khi xem màn `Hôm nay` (hôm nay và 7 ngày), `Chi tiết chất`, `Chi tiết cảnh báo`, `Hồ sơ`, và khi ghi/sửa món ăn, bổ sung, buổi tập.
- Toàn bộ phép tính chạy trên máy trong `packages/health_engine` (thuần Dart, không I/O), đối chiếu chéo với `tools/reference_engine.py`.

## Ràng buộc

- Quy tắc trong `AGENTS.md`: chỉ dùng chuẩn Mỹ đã chốt; không thêm chuẩn khác; không AI tạo sinh; `tools/build_pack.py` là nguồn số liệu duy nhất; mọi thay đổi logic engine sửa cả `tools/reference_engine.py` và sinh lại `packages/health_engine/test/fixtures/cases.json`.
- **0 vi phạm UL, 0 lỗi đơn vị.** Không đoán số khi gói chưa có hệ số (hệ số beta-caroten trong thức ăn ở việc 3; tỷ lệ nguyên tố hợp chất và tỷ lệ tocopherol este vitamin E ở việc 5): phần chưa có hệ số trả `NotComputed` kèm lý do ở phía mức khuyến nghị, trong khi phía giới hạn vẫn tính thận trọng nhất theo [specs/encrypted-db.md](encrypted-db.md).
- **Không viết cứng mốc tuổi trong engine:** nhóm tham chiếu, tuổi tối thiểu tạo hồ sơ, cách tính đạm theo cân nặng hay bảng, khoảng AMDR, và nhóm nào có EER đều đọc từ gói dữ liệu.
- **Chặn bỏ qua lặng lẽ đã mở khóa đúng điều kiện:** chỉ đặt `engineSupportsUlAmounts = true` trong `packages/journal_db/lib/src/intake.dart` sau khi `amountForUl` đọc được `ulNutrients` và `_group` tổng hợp đầy đủ `ulAmounts`.

## Nguồn

*(Đã đối chiếu trực tiếp qua trình duyệt Chrome ngày 25/11/2026 trên 5 nguồn gốc dưới đây.)*

- **UL và quy đổi vitamin E:**
  - NASEM – *Dietary Reference Intakes for Vitamin C, Vitamin E, Selenium, and Carotenoids* (2000, DOI `10.17226/9810`, Chương 6 tr. 187, 191–193, 244–245, 255–259; Chương 9 tr. 396–397): UL người lớn = 1.000 mg/ngày mọi dạng alpha-tocopherol bổ sung (cả 8 đồng phân, tuổi 14–18 là 800 mg/ngày). Bảng 6-1: `1 mg dl-alpha-tocopherol = 1,10 IU` (`0,91 mg/IU`), `1 mg d-alpha-tocopherol = 1,49 IU` (`0,67 mg/IU`); hệ số RDA `0,45` (tổng hợp) và `0,67` (tự nhiên). Bảng 9-1: quy đổi UL `1.000 mg/ngày` = `1.100 IU/ngày` cho dạng tổng hợp và cả 2 este (*dl*-acetat, *dl*-succinat) hoặc `1.500 IU/ngày` cho dạng tự nhiên và cả 2 este (*d*-acetat, *d*-succinat). Link: <https://www.nationalacademies.org/read/9810/chapter/8>, <https://www.nationalacademies.org/read/9810/chapter/11>
  - NIH ODS – *Vitamin E Fact Sheet for Health Professionals* (cập nhật `October 19, 2026`, tra Chrome 25/11/2026): UL 1.000 mg/ngày (`1.500 IU/ngày` tự nhiên hoặc `1.100 IU/ngày` tổng hợp); RDA `1 IU tự nhiên = 0,67 mg`, `1 IU tổng hợp = 0,45 mg`; `1 mg` alpha-tocopherol = `1 mg RRR` = `2 mg all-rac`. Link: <https://ods.od.nih.gov/factsheets/VitaminE-HealthProfessional/>
  - FDA – *Guidance for Industry: Converting Units of Measure for Folate, Niacin, and Vitamins A, D, and E* (August 2019, `FDA-2016-D-4484`, 21 CFR 101.9 / 101.36, tra Chrome 25/11/2026): Bảng 2–6: folate `1 µg = 1,7 µg DFE`; niacin `1 mg = 1 mg NE`; vitamin D `1 IU = 0,025 µg`; vitamin A `1 IU = 0,30 µg RAE` (retinol và beta-caroten bổ sung; beta-caroten thực phẩm `0,05` đối chiếu ở việc 3); vitamin E `1 IU` tự nhiên (gồm este) `= 0,67 mg`, tổng hợp (gồm este) `= 0,45 mg`, `1 mg` nhãn FDA = `1 mg RRR` = `2 mg all-rac`. Link: <https://www.fda.gov/media/129863/download>
- **Vanadi ở mốc tuổi:**
  - NASEM – *Dietary Reference Intakes for Sodium and Potassium* (2019, Phụ lục J, tr. 576–578, tra Chrome 25/11/2026): Vanadi UL `14–18 tuổi` là `ND` (chú thích `d`, `f`: thiếu dữ liệu và lo ngại khả năng xử lý liều dư), `19+` không mang thai/cho con bú là `1,8 mg/ngày`, mang thai và cho con bú là `ND`. Link: <https://www.nationalacademies.org/read/25353/chapter/28>
- **Vận động và tập tăng cơ:**
  - HHS – *Physical Activity Guidelines for Americans*, bản 2 (2018, tr. 8, 56, 59–61, tra Chrome 25/11/2026): người lớn 150–300 phút vận động vừa (3,0–5,9 MET) hoặc 75–150 phút mạnh (≥6,0 MET), 1 phút mạnh ≈ 2 phút vừa; tập tăng cơ cường độ vừa trở lên ≥2 ngày/tuần (nêu rõ ví dụ nâng tạ, dây kháng lực, bài tập trọng lượng cơ thể như *push-ups, pull-ups, planks*; yoga có thể là tăng cơ tùy kiểu/tư thế như Vinyasa/power yoga; không nhắc Pilates hay circuit training). Link: <https://odphp.health.gov/sites/default/files/2019-09/Physical_Activity_Guidelines_2nd_edition.pdf>
- **Đường bổ sung:**
  - Dietary Guidelines for Americans 2025–2030 (trang 3, tra 24/11/2026): ≤10 g đường bổ sung mỗi bữa. Link: <https://cdn.realfood.gov/DGA.pdf>
- **Quy tắc của app** ([plan.md](../plan.md), [design/mvp-overview.md](../design/mvp-overview.md), [specs/encrypted-db.md](encrypted-db.md)):
  - 12 tháng trước mốc đổi nhóm tuổi (19, 31, 51, 71): giới hạn an toàn lấy mức thấp hơn giữa nhóm hiện tại và nhóm kế tiếp; mức khuyến nghị giữ theo nhóm hiện tại.
  - Bữa phụ có giờ ăn cách món phụ ngay trước dưới 30 phút thì nối chuỗi vào cùng bữa.
  - Dạng chưa rõ: phía mức khuyến nghị lấy số nhỏ nhất có thể (ghi "chưa chắc"), phía giới hạn lấy số lớn nhất có thể.

## Thiết kế kỹ thuật

### 1. Gói dữ liệu (`tools/build_pack.py`, `reference_pack.json`, `tools/verify_pack.py`)

Nâng `schema` của gói lên `2` và tăng `PACK_VERSION`.

- **`sources`:**
  - Giữ các nguồn hiện có, thống nhất link `pag_2` thành `https://odphp.health.gov/sites/default/files/2019-09/Physical_Activity_Guidelines_2nd_edition.pdf`.
  - Bổ sung 3 nguồn riêng thay cho việc gán `unitConversions` về `nasem_dri_summary`:
    - `fda_unit_conversions` (nhãn A): FDA *Guidance for Industry: Converting Units of Measure for Folate, Niacin, and Vitamins A, D, and E* (2019) và 21 CFR 101.9 / 101.36.
    - `nasem_vit_e_2000` (nhãn A): NASEM *Dietary Reference Intakes for Vitamin C, Vitamin E, Selenium, and Carotenoids* (2000), Chương 6.
    - `nih_ods_vit_e` (nhãn A, `retrieved: "2026-11-25"`, bản gốc cập nhật `2026-10-19`): NIH ODS *Vitamin E Fact Sheet for Health Professionals*.
- **`minProfileAge`:** đặt `18` trong gói cho MVP (đọc từ gói tại màn tạo/sửa hồ sơ thay cho viết cứng `18`). Giữ phân biệt với `minAge` nhỏ nhất của nhóm DRI (`14`), vì NASEM xếp tuổi 18 vào nhóm `14–18`.
- **`groups` chuyển thành danh sách đối tượng có cấu trúc:** mỗi phần tử gồm:
  - `id`: chuỗi (`m14_18`, `m19_30`…).
  - `sex`: `'male'`, `'female'`, hoặc `null` (dùng chung hai giới, sẵn cho nhóm trẻ em 1–8 tuổi ở giai đoạn 2).
  - `stage`: `'none'`, `'pregnant'`, `'lactating'`.
  - `minAge`: số nguyên.
  - `maxAge`: số nguyên hoặc `null` nếu không chặn trên (`m71`, `f71`, `p31_50`, `l31_50`).
  - `amdrKey`: khóa tra trong `amdr` (`'age4_18'` cho `14_18`; `'adult19'` cho các nhóm `19+`).
  - `proteinPerKg`: số thực hoặc `null` (`0.8` cho nhóm `19+` không mang thai, không cho con bú; `null` cho `14_18`, `pregnant`, `lactating` dùng giá trị g/ngày trong bảng `target`).
  - `eerType`: `'none'` | `'adult'` | `'pregnant'` | `'lactating'` (tất cả nhóm `14_18` đặt `'none'`; nhóm `19+` đặt đúng loại EER).
- **`unitConversions`:** giữ 6 hệ số FDA hiện có (gắn `source: "fda_unit_conversions"`), bổ sung nhóm hệ số UL vitamin E (gắn `ulSource: "nih_ods_vit_e"`, đối chiếu `nasem_vit_e_2000`):
  - `vitE_ul_natural_IU_to_mg`: `0.67` (bằng `vitE_natural_IU_to_mg`).
  - `vitE_ul_synthetic_IU_to_mg`: `1000 / 1100` (`≈ 0.9090909`).
  - Các trường tùy chọn trong schema cho việc 3 và 5 (để `null` / `{}` trong gói hiện tại, nhưng `ReferencePack` đọc được khi có):
    - `vitA_food_betacarotene_IU_to_ug_RAE`: `double?`.
    - `vitaminEEsters`: `Map<String, VitaminEEsterDef>`, mỗi mục gồm `{"tocopherolRatio": double, "origin": "natural" | "synthetic"}` (tỷ lệ tocopherol và nguồn `d-` tự nhiên hay `dl-` tổng hợp).
    - `compounds`: `Map<String, Map<String, double>>`, theo `nutrientId` → `form` hợp chất → tỷ lệ nguyên tố.
- **`pag` và `activities`:**
  - `ReferencePack` đọc đầy đủ các trường đã có trong `pag` (`moderateMinMet`, `vigorousMinMet`, `weeklyModerateMin`, `weeklyVigorousMin`, `strengthDaysPerWeek`).
  - Mỗi mục trong `activities` thêm trường boolean `muscleStrengthening` (`true` cho `02054`, `02050`, `02022`, `02020`, `02024`, `02035`, `02040`; `false` cho các hoạt động còn lại).
- **`tools/verify_pack.py`:**
  - Kiểm `groups` phủ liên tục từ `minAge` nhỏ nhất trong `groups` trở lên cho từng `(sex, stage)` không chồng lấn, mọi `amdrKey` có trong `amdr`, `pag` đủ trường, mọi hoạt động có `muscleStrengthening` kiểu `bool`.
  - Thêm ô `GOLDEN` cho `vitE_ul_natural_IU_to_mg`, `vitE_ul_synthetic_IU_to_mg`, các ngưỡng `pag`, và các mã hoạt động tập tăng cơ đã chốt.

### 2. Mô hình và Interface (`packages/health_engine`, `packages/journal_db`, `app`)

#### Quy ước mã dạng (`form`) dùng chung

Dùng thống nhất giữa `reference_pack.json`, `health_engine`, `tools/reference_engine.py`, và `intake_lines.form` (`abstract final class NutrientForm` trong Dart):

- Chung: `'unknown'` (khi đầu vào là `null` hoặc không rõ).
- Vitamin A: `'retinol'`, `'beta_carotene'`.
- Folate: `'folic_acid'`, `'natural_folate'` (folate tự nhiên/thức ăn).
- Vitamin E:
  - `'natural_2r'`: dạng tự nhiên *d*-alpha-tocopherol / *RRR* (cả `IU`, `mg` 2R FDA, lẫn `mg` khối lượng *d*-alpha-tocopherol vì khối lượng toàn phần bằng khối lượng 2R).
  - `'synthetic_2r'`: dạng tổng hợp đã quy về 2R (`IU` *dl*-alpha-tocopherol, hoặc nhãn FDA ghi `mg` alpha-tocopherol có nguồn tổng hợp).
  - `'synthetic_mass'`: `mg` khối lượng toàn phần của dạng tổng hợp (*dl*-alpha-tocopherol, gồm cả 8 đồng phân).
  - Este: tập 4 mã cố định `'d_alpha_tocopheryl_acetate'`, `'dl_alpha_tocopheryl_acetate'`, `'d_alpha_tocopheryl_succinate'`, `'dl_alpha_tocopheryl_succinate'` khai báo sẵn trong `NutrientForm` kèm phân biệt nguồn gốc `d-` (`natural`) / `dl-` (`synthetic`) (trùng khóa khi `pack.vitaminEEsters` có dữ liệu ở việc 5; trước việc 5 `pack.vitaminEEsters` là `{}` nên engine nhận diện este qua tập cố định này thay cho `pack.vitaminEEsters.containsKey(form)`).
- Khoáng chất: mã hợp chất trùng khóa trong `pack.compounds[nutrientId]` (vd. `'calcium_carbonate'`, `'calcium_citrate'`, `'magnesium_oxide'`), hoặc `'elemental'`, hoặc `'unknown'`.

#### `packages/health_engine`

- **`MealSlot`:** `enum MealSlot { breakfast, lunch, dinner, snack }`.
- **`CompoundKind`:** `enum CompoundKind { elemental, compound, unknown }` (tương ứng `is_compound` của bảng `ingredients`: nguyên tố dù có tên dạng, hợp chất theo khối lượng hợp chất, hay không rõ).
- **`LabelUnit`:** `enum LabelUnit { g, mg, ug, iu, ugRae, ugDfe, mgNe }`.
- **`IntakeItem`:**
  - Bắt buộc: `label`, `source`, `nutrients` (`Map<String, double>`).
  - Tùy chọn:
    - `ulNutrients` (`Map<String, double>?`): lượng tính vào giới hạn an toàn cho các khóa khác `nutrients`.
    - `meal` (`MealSlot?`): bữa ăn (thay thế `mealId`; bổ sung để trống `null`).
    - `at` (`DateTime?`): giờ ăn thực tế (dùng để nối chuỗi bữa phụ).
    - `addedSugarKnown` (`bool`, mặc định `true`): `false` khi món theo nhãn không ghi riêng đường bổ sung.
    - `entryId` (`String?`): mã định danh lần ghi gốc (vd. `'food:12'`) để khi một món tách thành nhiều `IntakeSource` (`food` và `fortified`) không đếm trùng vào danh sách món chưa rõ đường bổ sung và không làm sai phép nối chuỗi bữa phụ.
  - Phương thức: `double amount(String key)` và `double amountForUlKey(String key) => ulNutrients?[key] ?? nutrients[key] ?? 0`.
- **`WorkoutEntry`:** thêm `final String? day;` (`YYYY-MM-DD`, tùy chọn) để engine đếm số ngày phân biệt có tập tăng cơ.
- **`UlFlag`:**
  - `enum UlFlagKind { daily, sevenDayAverage, schedule }`
  - Trường: `nutrientId`, `kind`, `amount`, `ul`, `excess` (`amount - ul`), `percentOver` (`(amount - ul) / ul * 100`), `percentOfUl` (`amount / ul * 100`), `scope`, `dayCount` (`int?`, có giá trị khi `kind == UlFlagKind.sevenDayAverage`).
  - Getter tương thích `bool get isSevenDayAverage => kind == UlFlagKind.sevenDayAverage`.
- **`NutrientStatus`:**
  - `nutrientId`, `totalAmount` (cộng mọi nguồn), `foodAmount`, `fortifiedAmount`, `supplementAmount`, `target` (`Target?`, `null` với chất chỉ có UL như bo, niken, vanadi), `ul` (`double?`, đã xét quy tắc 12 tháng trước mốc tuổi), `ulAmount` (tổng tính vào UL theo `ulScope`, `ulKey` và `ulNutrients`), `ulScope`, `ulNutrientId` (`String?`, bằng `def.ulKey ?? def.id` khi `ul != null`).
  - Getter `double get amount => totalAmount;` và `double? get percentOfTarget`.
- **`MealSugarAlert` và `SugarCheck`:**
  - `MealSugarAlert`: `meal` (`MealSlot`), `grams`, `startAt` (`DateTime?`), `endAt` (`DateTime?`), `labels` (`List<String>`).
  - `SugarCheck`: `addedSugarG`, `percentEnergy`, `mealsOverLimit` (`List<MealSugarAlert>`), `unknownSugarFoods` (`List<String>`).
- **`ActivitySummary`:**
  - `moderateMinutes`, `vigorousMinutes`, `moderateEquivalentMinutes` (`moderate + 2 * vigorous`), `strengthDays` (số ngày phân biệt có ít nhất 1 hoạt động `muscleStrengthening`), `weeklyModerateMinRange` (`Range`), `strengthDaysTarget` (`int`), `suggestedLevel` (`ActivityLevel`).
- **`DailyReport`:**
  - Tham số hàm `dailyReport`:
    ```dart
    DailyReport dailyReport(
      ReferencePack pack,
      Profile p,
      List<IntakeItem> today, {
      List<WorkoutEntry> workouts = const [],
      List<List<IntakeItem>> last7Days = const [],
      List<WorkoutEntry> workouts7 = const [],
    })
    ```
  - Trường bổ sung: `loggedDaysCount` (`int`), `activity7Days` (`ActivitySummary`), `ulFlags` giữ **đủ** cả cờ `daily` và `sevenDayAverage` cho cùng một chất, và `nutrients` gồm đủ mọi chất có `target != null || ul != null` (loại trừ tập các khóa đích `ulKey` trong `pack.nutrients` như `retinol`, `folicAcid`, vì chất gốc `vitA`, `folate` đã trả cả hai tổng; xem mục 3.4).
- **`PeriodReport` và `averageReport` (cho chế độ `7 ngày`):**
  - Hàm:
    ```dart
    PeriodReport averageReport(
      ReferencePack pack,
      Profile p,
      List<List<IntakeItem>> loggedDays, {
      List<WorkoutEntry> workouts7 = const [],
    })
    ```
  - Trường của `PeriodReport`:
    - `int loggedDaysCount`: số ngày có ghi (sau khi lọc `d.isNotEmpty`).
    - `double averageEnergyInKcal`: trung bình năng lượng/ngày (`0` khi `loggedDaysCount == 0`).
    - `int? eerKcal`, `NotComputedReason? eerNotComputed`.
    - `List<MacroShare> macros`: `grams` là trung bình gram/ngày (`tổng / n`), còn `percentEnergy` tính trên **tổng gram của cả `n` ngày** (tương đương tính trên trung bình gram/ngày; không lấy trung bình cộng % từng ngày vốn bị lệch theo ngày ăn ít calo).
    - `double averageAddedSugarG`, `double addedSugarPercentEnergy`: `averageAddedSugarG = tổng đường bổ sung / n`; `addedSugarPercentEnergy` tính trên tổng `addedSugar * 4 / tổng energy * 100` của cả `n` ngày (cùng fallback Atwater khi tổng `energyKcal <= 0`). Không chứa `mealsOverLimit` hay `unknownSugarFoods` (chỉ kiểm theo từng bữa của ngày đang xem).
    - `List<NutrientStatus> nutrients`: trung bình/ngày (`tổng / n`) cho cả `totalAmount`, phân rã nguồn, và `ulAmount`.
    - `List<UlFlag> ulFlags`: kết quả từ `checkUlAverage`.
    - `ActivitySummary activity7Days`: tính từ `workouts7`.
- **`NotComputedReason`:** bổ sung 4 lý do cho `convertIntakeLine`: `missingFoodBetaCaroteneFactor`, `missingEsterRatio`, `missingCompoundRatio`, `missingNutrientInPack`.
- **`UnitConverter` / `convertIntakeLine`:**
  - `IntakeLineInput`: `nutrientId` (`String?`, null nếu chất ngoài gói), `freeName` (`String?`), `source` (`IntakeSource`), `form` (`String`, mặc định `NutrientForm.unknown`), `amount` (`double`), `unit` (`LabelUnit`), `compoundKind` (`CompoundKind`, mặc định `CompoundKind.elemental`), `secondaryFolicAcidUg` (`double?`, dùng khi nhãn folate ghi µg DFE kèm `(x µg axit folic)`).
  - `ConvertedIntakeLine`: `amounts` (`Map<String, double>`), `ulAmounts` (`Map<String, double>?`), `uncertain` (`bool`), `amountsNotComputed` (`NotComputedReason?`).

#### `packages/journal_db` và `app/` (đồng bộ cùng PR code)

- **`packages/journal_db/lib/src/intake.dart`:**
  - Đặt `const engineSupportsUlAmounts = true;`.
  - `_group`: bỏ ném lỗi, tổng hợp `ulAmounts`: với mọi khóa `k` xuất hiện trong `ulAmounts` của ít nhất một dòng thuộc nguồn đó, cộng `(l.ulAmounts?[k] ?? l.amounts[k] ?? 0)` trên tất cả các dòng của nguồn đó; nếu không dòng nào có `ulAmounts` thì để `null`.
  - Đổi `mealIdOf` → `mealSlotOf(FoodEntry f)` trả `MealSlot`.
  - `intakeItemsOfFood`: truyền `meal: mealSlotOf(f)`, `at: f.at`, `addedSugarKnown: f.addedSugarKnown`, `entryId: 'food:${f.id}'`. Nếu `f.lines.isEmpty && !f.addedSugarKnown`, vẫn sinh một `IntakeItem` rỗng chất (`source: IntakeSource.food`) để không mất món khỏi `unknownSugarFoods`.
  - `intakeItemsOfDose`: truyền `at: d.at`, `entryId: 'dose:${d.id}'`.
- **`DriftJournalRepository` và `InMemoryJournalRepository`:**
  - `workoutsOn` (và `InMemoryJournalRepository.addWorkout`) truyền `day` vào `WorkoutEntry(activityCode: ..., minutes: ..., day: day)` để `AppState._loadDay` có sẵn `day` cho `workouts7`.
- **`app/` (cập nhật tối thiểu khung tạm để biên dịch, qua CI và không dính lỗi vitamin E trên APK thử nội bộ):**
  - `AppState`: bỏ `_withMealLabel` kiểu chuỗi; truyền `workouts7: _data.workouts7` vào `dailyReport`; khi lưu từ `addItem` điền đúng `MealSlot`, `at`, `addedSugarKnown`.
  - `AddSupplementScreen`: nối qua `UnitConverter(pack).convertIntakeLine(...)` để sinh `IntakeLine` có đủ `form`, `uncertain`, `labelAmount`, `labelUnit`, `amounts`, `ulAmounts` (hết lỗi tính thiếu UL vitamin E tổng hợp trên khung tạm).
  - `TodayScreen`: lọc `n.target != null` ở danh sách vi chất (vì bo, niken, vanadi có `target == null`), đọc `UlFlag` (`kind`, `excess`, `percentOver`), `MealSugarAlert`, `unknownSugarFoods`.
  - `DiaryScreen`, `AddFoodScreen`, `app_state_test.dart`: đổi `mealId` sang `MealSlot`.
  - `ProfileScreen`: tuổi tối thiểu đọc từ `state.pack.minProfileAge`.
  - `labels.dart`: bổ sung 4 nhánh `NotComputedReason` mới cho `switch` đầy đủ.

### 3. Luồng xử lý và quy tắc tính toán

1. **Chọn nhóm tham chiếu hoàn toàn bằng dữ liệu (`driGroupDefFor`):**
   - Duyệt `pack.groups` tìm nhóm có `stage == p.stage`, `sex == null || sex == p.sex`, `minAge <= p.ageYears`, và `(maxAge == null || p.ageYears <= maxAge)`. Không khớp → ném `NotComputed(NotComputedReason.ageUnsupported)`.
   - `targetFor`: nếu `nutrientId == 'protein'` và `group.proteinPerKg != null` thì trả `_round1(group.proteinPerKg! * p.weightKg)`; ngược lại lấy `def.target[group.id]`.
   - `macroShares`: lấy `pack.amdr[group.amdrKey]`.
   - `eerKcal`: đọc `group.eerType` (`none` → `NotComputed(NotComputedReason.eerUnderAge19)`).

2. **Giới hạn an toàn ở 12 tháng trước mốc đổi nhóm tuổi (`ulFor` và `_checkUl`):**
   - Tìm `g1 = driGroupDefFor(pack, p)`. Nếu `g1.maxAge != null && p.ageYears == g1.maxAge`, tìm `g2 = driGroupDefFor(pack, p.copyWith(ageYears: p.ageYears + 1))`.
   - Giới hạn áp dụng cho `nutrientId` là giá trị nhỏ hơn giữa `def.ul[g1.id]` và `def.ul[g2.id]`; nếu chỉ một trong hai nhóm có UL và nhóm kia `null` (như vanadi ở tuổi 18: `14_18` là `null`, `19_30` là `1,8 mg`) thì lấy giá trị UL có đó.
   - Mức khuyến nghị `targetFor` vẫn lấy theo `g1` (nhóm hiện tại).

3. **Lượng tính vào giới hạn và cờ (`amountForUl`, `checkUlDay`, `checkUlAverage`, `checkUlSchedule`, `dailyReport`):**
   - `amountForUl(def, items)`: cộng `it.amountForUlKey(key)` (ưu tiên `ulNutrients[key]`, không có mới lấy `nutrients[key]`) cho các `it` khớp `def.ulScope`.
   - `checkUlAverage(pack, p, loggedDays)`: **tự lọc bên trong engine** `final nonEmpty = [for (final d in loggedDays) if (d.isNotEmpty) d]`. Nếu `nonEmpty.isEmpty` trả `[]`; ngược lại chia tổng cho `nonEmpty.length` và gán `dayCount = nonEmpty.length`.
   - `checkUlSchedule(pack, p, scheduledDailyItems)`: kiểm tra một ngày điển hình theo lịch (`UlFlagKind.schedule`).
   - `dailyReport`: gom **tất cả** cờ từ `checkUlDay(pack, p, today)` và `checkUlAverage(pack, p, last7Days)`, không dùng `putIfAbsent` theo `nutrientId` (một chất có thể có cả cờ `daily` và `sevenDayAverage`); trả `loggedDaysCount = nonEmpty.length`. Sắp xếp theo `percentOver` giảm dần (cùng tỷ lệ thì `daily` trước `sevenDayAverage`).
   - Khi `amount > ul`: `excess = amount - ul`, `percentOver = excess / ul * 100`. Không làm tròn `amount` trước khi trừ `ul` để tránh trường hợp `350,004 > 350` bị làm tròn thành `excess = 0`.

4. **Hai tổng cho mọi chất (`NutrientStatus`):**
   - Tính tập `final ulTargetKeys = {for (final n in pack.nutrients.values) if (n.ulKey != null) n.ulKey!};`.
   - Duyệt mọi chất trong `pack.nutrients` trừ các chất thuộc `ulTargetKeys` (hiện tại là `retinol`, `folicAcid`, vì chúng đã gắn vào `vitA.ulKey` và `folate.ulKey`).
   - Với mỗi chất còn lại (có `target != null` hoặc `ul != null`):
     - `totalAmount`, `foodAmount`, `fortifiedAmount`, `supplementAmount` lấy từ `nutrients[def.id]` theo từng `IntakeSource`.
     - `ulDef = def.ulKey != null ? pack.nutrients[def.ulKey!]! : def`.
     - `ul = ulFor(pack, p, ulDef.id)`, `ulAmount = amountForUl(ulDef, items)`.
   - Chất chỉ có UL (`bo`, `niken`, `vanadi`) có `target == null`, `ul != null` vẫn nằm trong danh sách để Chi tiết cảnh báo và Hôm nay đọc được hai tổng.

5. **Đường bổ sung (`sugarCheck`):**
   - Gom theo `entryId` trước (nếu khác `null`) để một món có nhiều nguồn (`food` + `fortified`) nằm chung một đơn vị món.
   - Ba bữa chính (`breakfast`, `lunch`, `dinner`): cộng tổng `addedSugar` của từng bữa; nếu `> addedSugarMaxGramsPerMeal` (`10 g`) thêm vào `mealsOverLimit`.
   - Bữa phụ (`snack`):
     - Các nhóm có `at != null`: sắp xếp ổn định theo `at` tăng dần; bắt đầu cụm mới khi chưa có cụm hoặc `nhóm.at - prev.at >= 30 phút` (tức `< 1800 giây` thì nối chuỗi vào cùng cụm).
     - Các nhóm có `at == null`: **mỗi nhóm là một bữa phụ riêng** (không gộp các món không rõ giờ vào cùng một bữa).
     - Cụm nào có tổng `addedSugar > 10 g` thêm vào `mealsOverLimit` với `startAt`, `endAt`, `labels`.
   - `unknownSugarFoods`: danh sách `label` duy nhất theo từng nhóm (`entryId` nếu khác `null`, ngược lại từng mục) có `addedSugarKnown == false`.

6. **Vận động (`activitySummary`, `dailyReport`):**
   - Từ danh sách buổi tập 7 ngày (`workouts7`):
     - Tính `moderateMinutes` (`moderateMinMet <= met < vigorousMinMet`), `vigorousMinutes` (`met >= vigorousMinMet`), `moderateEquivalentMinutes = moderate + 2 * vigorous`.
     - Đếm `strengthDays` cho các buổi có `activity.muscleStrengthening == true`: dùng tập các khóa ngày `w.day ?? '__anon_$i'` (với `w.day != null`, nhiều buổi cùng ngày chỉ tính 1 ngày; với buổi `day == null` truyền trực tiếp trong unit test, mỗi buổi tính là 1 ngày riêng).
     - Tính `suggestedLevel` bằng `moderateEquivalentMinutes / 7` so với `palSuggestionThresholds`.

7. **Đổi một dòng nhãn thành khóa engine (`convertIntakeLine`) — đủ 18 hàng từ [specs/encrypted-db.md](encrypted-db.md):**

Với các chất đổi đơn vị mét trước khi nhân tỷ lệ hoặc gán (`g` ↔ `mg` ↔ `µg`), đổi về đơn vị chuẩn của chất đó trong gói; `niacin` đổi `mg` = `mg NE` (1:1).

| # | Trường hợp đầu vào | `amounts` | `ulAmounts` | `uncertain` |
|---|---|---|---|---|
| 1 | Axit folic `x` µg (`supplement` hoặc `fortified`, `form: folic_acid` hoặc mặc định cho axit folic) | `folate: x × 1,7`, `folicAcid: x` | `null` | `false` |
| 2 | Folate `d` µg DFE kèm `secondaryFolicAcidUg = x`; hoặc `form: natural_folate` (tự nhiên) | Kèm `x`: `folate: d`, `folicAcid: x`; `natural_folate`: `folate: d` (không tính thành `folicAcid`) | `null` | `false` |
| 3 | Folate `d` µg DFE, `form: unknown` | `folate: d`, `folicAcid: d ÷ 1,7` | `null` | `true` |
| 4 | Vitamin A `form: retinol` (`x` µg RAE hoặc `IU × 0,3`) | `vitA: rae`, `retinol: rae` | `null` | `false` |
| 5 | Vitamin A `form: beta_carotene`: (a) `ugRae` (mọi nguồn) hoặc `iu` của `supplement` (`× 0,3`); (b) `iu` của `food`/`fortified` | (a) `vitA: rae`; (b) có `vitA_food_betacarotene_IU_to_ug_RAE` → `vitA: iu × hệ_số`; chưa có → `{}` + `missingFoodBetaCaroteneFactor` | `null` | `false` |
| 6 | Vitamin A `x` µg RAE, `form: unknown` | `vitA: x`, `retinol: x` | `null` | `true` |
| 7 | Vitamin A `iu` IU, `form: unknown`, `source: supplement` | `vitA: iu × 0,3`, `retinol: iu × 0,3` | `null` | `true` |
| 8 | Vitamin A `iu` IU, `form: unknown`, `source: food` hoặc `fortified` (món theo nhãn) | Có `vitA_food_betacarotene_IU_to_ug_RAE` → `vitA: iu × hệ_số`; chưa có → `{}` + `missingFoodBetaCaroteneFactor` | `retinol: iu × 0,3` | `true` |
| 9 | Vitamin E `iu` IU, biết nguồn (`natural_2r` / este `d-`, hoặc `synthetic_2r` / este `dl-`; nhận diện este qua tập cố định của `NutrientForm` và `pack.vitaminEEsters`) | `vitE: iu × e_rda(nguồn)` | Khác `amounts` (`synthetic`) → `vitE: iu × e_ul(synthetic)`; `natural` → `null` | `false` |
| 10 | Vitamin E `iu` IU, `form: unknown` | `vitE: iu × e_rda(synthetic)` | `vitE: iu × e_ul(synthetic)` | `true` |
| 11 | Vitamin E `mg`, `form: natural_2r` hoặc `synthetic_2r` (nhãn FDA mới) | `vitE: mg` | `synthetic_2r` → `vitE: mg ÷ e_rda(syn) × e_ul(syn)`; `natural_2r` → `null` | `false` |
| 12 | Vitamin E `mg`, `form: synthetic_mass` (`dl-alpha-tocopherol`) | `vitE: mg ÷ e_ul(syn) × e_rda(syn)` | `vitE: mg` | `false` |
| 13 | Vitamin E `mg`, `form` là este (khớp tập 4 mã cố định trong `NutrientForm` hoặc `pack.vitaminEEsters`) | Tra `pack.vitaminEEsters[form]`: có → đổi `tocopherolMg = mg × tocopherolRatio` rồi theo hàng 11 (`natural`) hoặc 12 (`synthetic`); `null` (trước việc 5) → `{}` + `missingEsterRatio` | Có trong `pack.vitaminEEsters` → theo hàng 11/12; `null` → `vitE: mg` | `false` |
| 14 | Vitamin E `mg`, `form: unknown` (vd. "Vitamin E 15 mg") | `vitE: min` của 3 cách hiểu (2R tự nhiên, 2R tổng hợp, khối lượng tổng hợp; không xét este) = `mg ÷ e_ul(syn) × e_rda(syn)` | `vitE: max` của 3 cách hiểu = `mg ÷ e_rda(syn) × e_ul(syn)` | `true` |
| 15 | Hợp chất, biết tên (`compoundKind == compound`, biết `form`) | Có `pack.compounds[id][form]` → `(lượng đổi sang đơn vị chuẩn của chất) × tỷ_lệ`; chưa có → `{}` + `missingCompoundRatio` | `null` | `false` |
| 16 | Không rõ hợp chất hay nguyên tố (`compoundKind == unknown`) | Có `pack.compounds[id]` khác rỗng → `(lượng đổi sang đơn vị chuẩn của chất) × min(tỷ_lệ)`; chưa có → `{}` + `missingCompoundRatio` | `chất: lượng đổi sang đơn vị chuẩn` (coi là nguyên tố) | `true` |
| 17 | Chất khác trong gói (`compoundKind == elemental`, kể cả khi có tên dạng như canxi carbonat ghi hàm lượng nguyên tố; đổi `g`/`mg`/`µg`, vitD `IU`, niacin `mg` = `mg NE`) | `chất: lượng đã đổi sang đơn vị chuẩn` | `null` | `false` |
| 18 | Chất không có trong gói (`nutrientId == null` hoặc không thuộc `pack.nutrients`) | `{}` + `missingNutrientInPack` | `null` | `false` |

### 4. Lỗi và biên

- Đọc gói có `schema != 2` → ném `FormatException`.
- Số lượng đầu vào âm (`amount < 0` hoặc `secondaryFolicAcidUg != null && secondaryFolicAcidUg < 0`) ở `convertIntakeLine` → ném `ArgumentError`.
- `loggedDays` rỗng hoặc toàn `[]` → `checkUlAverage` trả `[]`, `loggedDaysCount = 0`, `averageReport` trả các tổng `0` không chia cho `0`.
- Bữa phụ có hai món cách đúng `30 phút 00 giây` (`15:00` và `15:30`) → **2 bữa phụ riêng**, không nối chuỗi; `29 phút 59 giây` → cùng một bữa.
- `amount > ul` rất nhỏ (vd. `350,004 > 350`) → vẫn báo cờ, `excess > 0` không bị làm tròn về `0`.

## Tiêu chí đạt

Mọi phép tính có ca kiểm thử tương ứng trong `tools/reference_engine.py` → `cases.json` và `packages/health_engine/test/`, kèm kiểm cấu trúc + ô đối chiếu trong `tools/verify_pack.py`:

- [x] `verify_pack.py` qua đủ ô `GOLDEN` cũ + hệ số `vitE_ul_synthetic_IU_to_mg`, `vitE_ul_natural_IU_to_mg`, các nhóm cấu trúc, `pag`, hoạt động `muscleStrengthening`.
- [x] **Vitamin E tổng hợp:** 1.100 IU tổng hợp cho `ulAmount = 1.000 mg` (chưa vượt UL 1.000 mg), `amounts ≈ 495 mg`; 1.200 IU tổng hợp vượt UL (`ulAmount ≈ 1.090,9 mg`, `excess ≈ 90,9 mg`, `percentOver ≈ 9,1%`).
- [x] **Nhóm tham chiếu dữ liệu:** `driGroupDefFor`, `targetFor`, `macroShares`, `eerKcal`, `minProfileAge` không còn mốc tuổi viết cứng; chạy được với gói giả định có thêm nhóm tuổi mới mà không sửa code engine.
- [x] **12 tháng trước mốc đổi nhóm tuổi:** 18 tuổi → UL canxi 2.500 mg (thay vì 3.000), RDA canxi giữ 1.300 mg; 50 tuổi → UL canxi 2.000 mg (thay vì 2.500); 70 tuổi → UL phốt pho 3.000 mg (thay vì 4.000); 31/51/71 tuổi lấy đúng nhóm mới.
- [x] **Đủ loại cờ & hai tổng:** một chất vượt cả hôm nay và trung bình 7 ngày → `DailyReport.ulFlags` trả cả hai cờ kèm `excess`, `percentOver`, `dayCount`; `checkUlAverage` và `averageReport` nhận 7 phần tử gồm 5 ngày `[]` vẫn chia đúng cho 2 và trả `loggedDaysCount = 2`; `NutrientStatus` có `totalAmount`, phân rã nguồn, và `ulAmount` cho cả magie, niacin, vitamin E, vitamin A/retinol, folate/axit folic, bo/niken/vanadi kể cả khi chưa vượt; `PeriodReport` tính % macro trên tổng gram các ngày có ghi.
- [x] **Đường bổ sung:** nối chuỗi 15:00 (4 g) + 15:25 (4 g) + 15:50 (4 g) thành 1 bữa 12 g vượt 10 g; 15:00 (6 g) và 15:30 (6 g) tách 2 bữa không vượt; món `at == null` (kể cả khi một món tách `food` + `fortified` chung `entryId`) không gộp nhầm sang bữa phụ khác; món `addedSugarKnown == false` xuất hiện đúng 1 lần trong `unknownSugarFoods`.
- [x] **Vận động:** `ActivitySummary` trả đúng `moderateMinutes`, `vigorousMinutes`, `moderateEquivalentMinutes`, và `strengthDays` đếm theo ngày phân biệt (2 buổi tập tạ cùng một ngày = 1 ngày).
- [x] **Bảng đổi dòng thành khóa engine:** đủ 18 ca test (gồm `folate` `natural_folate` `ugDfe`, biên `secondaryFolicAcidUg < 0`, nhánh 5b `beta_carotene` `IU` món ăn, phân biệt `compoundKind` nguyên tố vs hợp chất với chất đơn vị `µg`, nhận diện 4 mã este vitamin E `IU`/`mg` cả khi `pack.vitaminEEsters` là `{}`, và các trường hợp chưa có hệ số việc 3/5 trả `NotComputed` phía RDA kèm `ulAmounts` thận trọng).
- [ ] **`packages/journal_db`:** `engineSupportsUlAmounts == true`; `_group` gộp đúng 1 dòng vitamin E tự nhiên + 1 dòng tổng hợp trong cùng sản phẩm (`nutrients` và `ulNutrients` cộng đầy đủ); món `lines` rỗng + `addedSugarKnown == false` vẫn vào `unknownSugarFoods`; `workoutsOn` điền đủ `WorkoutEntry.day`; `intake_test.dart` đã qua trên máy, còn `drift_repository` (SQLite3MultipleCiphers) chạy qua CI khi push PR.
- [ ] **`app/`:** cập nhật khung tạm khớp API mới (`AppState`, `AddSupplementScreen` qua `convertIntakeLine`, `TodayScreen` lọc `target != null`, `ProfileScreen` dùng `pack.minProfileAge`, `labels.dart`), `flutter analyze` đã qua (0 lỗi), còn `flutter test` chạy qua CI khi push PR (máy Windows chặn `impellerc.exe`).

## Ngoài phạm vi

- Thêm nhóm trẻ em 1–13 tuổi và phương trình EER trẻ em (giai đoạn 2).
- Hệ số beta-caroten trong thức ăn và thư viện món USDA/FPED (việc 3).
- Tỷ lệ nguyên tố của hợp chất khoáng chất và tỷ lệ tocopherol của este vitamin E (việc 5).
- Giao diện mới của màn Hôm nay, Chi tiết chất, Chi tiết cảnh báo, Đặt lịch uống (làm theo các việc/đặc tả tương ứng).

## Quyết định đã chốt (25/11/2026)

1. **`vitE_ul_synthetic_IU_to_mg` dùng `1000 / 1100` (`≈ 0,90909`):** để đúng mốc `1.100 IU` trong NASEM Bảng 9-1 và NIH ODS cho ra `1.000,0 mg` (chưa vượt UL), còn từ `1.101 IU` trở lên mới vượt.
2. **Hoạt động `muscleStrengthening = true`:** gồm 7 mã `02054`, `02050`, `02022`, `02020`, `02024` (plank, gập bụng theo ví dụ trực tiếp trong PAG bản 2 tr. 61), `02035`, `02040` (circuit training vừa/mạnh). Các mã `02160` (Power yoga), `02105` (Pilates), `02150` (Yoga Hatha), `02101` (Giãn cơ nhẹ) và nhóm aerobic giữ `false`.
3. **Vanadi ở tuổi 18 (12 tháng trước mốc 19 tuổi):** khi một nhóm `null` (`14_18`) và nhóm kế tiếp có UL (`19_30` = `1,8 mg/ngày`) thì lấy mức có đó (`1,8 mg/ngày`) theo nguyên tắc thận trọng.
4. **`minProfileAge = 18`:** tách riêng trong gói với `minAge = 14` của nhóm `14_18`.
