# Đặc tả: Thư viện món và Ghi món (việc 3)

Trạng thái: Đã duyệt  <!-- Nháp | Đã duyệt -->
Thiết kế UX: [docs/design/food-library.md](../design/food-library.md) *(soạn và duyệt ở bước 2 sau khi chốt đặc tả này, trên khung [design/mvp-overview.md](../design/mvp-overview.md))*
Thứ tự MVP: việc 3 trong [status.md](../status.md)

## Mục tiêu

Xây dựng thư viện thực phẩm trên máy gồm dữ liệu USDA FoodData Central + FPED và bộ công thức món Việt tính từ nguyên liệu USDA, tách riêng khỏi `reference_pack.json` dưới dạng CSDL SQLite chỉ đọc kèm tìm kiếm FTS5; đồng thời hoàn thiện phần ghi, sửa, tính lại khẩu phần món ăn (món thư viện và Nhập theo nhãn) và bổ sung hệ số beta-caroten trong thức ăn vào gói chuẩn.

## Người dùng và tình huống

- Người dùng mở `Ghi → Món ăn` để tìm món (gõ có dấu hoặc không dấu tiếng Việt, tên tiếng Anh), chạm món gần đây, chọn khẩu phần quen thuộc (`bát`, `đĩa`, `ly`, `gram`…), hoặc chọn `Nhập theo nhãn` nếu món chưa có trong thư viện (có thể lưu vào kho món tự nhập để dùng lại).
- Người dùng mở một món trong `Nhật ký` để sửa khẩu phần, đổi bữa, đổi giờ/ngày hoặc xóa món; khi sửa khẩu phần món thư viện/công thức thì tính lại dòng chất theo gói dữ liệu đang cài, còn món theo nhãn tự nhân tỷ lệ và giữ nguyên số gốc trên nhãn.

## Ràng buộc

- **Chỉ dùng nguồn chuẩn Mỹ, miễn phí dùng thương mại (`AGENTS.md`):** USDA FoodData Central (Foundation Foods, SR Legacy, FNDDS — CC0) và USDA FPED (U.S. Public Domain). Tuyệt đối không dùng dữ liệu Việt Nam hay nguồn cộng đồng (Open Food Facts…).
- **Món Việt tự soạn từ nguyên liệu USDA:** tính từ công thức chuẩn với nguyên liệu USDA và khẩu phần quen thuộc, luôn gắn nhãn `"ước tính"`. Lập danh sách món đặc thù chưa có trong USDA hoặc chưa lập được công thức chuẩn ("chỉ có ở Việt Nam") để gợi ý Nhập theo nhãn hoặc chọn món gần nhất.
- **Không nhồi thư viện món vào `reference_pack.json`:** giữ `reference_pack.json` nhỏ gọn cho chuẩn và quy tắc (tránh decode hàng nghìn món vào RAM khi khởi động); thư viện món đóng gói thành tệp SQLite chỉ đọc riêng có chỉ mục FTS5 kèm bản cài đã ký, có kiểm mã băm/phiên bản trước khi mở.
- **Thực phẩm tăng cường và đường bổ sung:**
  - Món USDA dùng trường axit folic (`Folic acid`) và vitamin E bổ sung (`Vitamin E, added`) tách riêng `source = fortified` khỏi phần tự nhiên `source = food`. Niacin tăng cường trong USDA không tách được nên đưa vào `source = food` và ghi chú nguồn rõ ràng ở phần thông tin món/Nguồn số liệu.
  - Món `Nhập theo nhãn` có `niacin`, `vitE`, `folicAcid` (kể cả khi chọn `folate` với `form = folic_acid`) đều gán `source = fortified` (`plan.md`). Nhãn không ghi riêng đường bổ sung thì `added_sugar_known = false` ("chưa rõ đường bổ sung", không ghi `0 g`).
- **Không đoán số (`AGENTS.md`):** bổ sung hệ số `vitA_food_betacarotene_IU_to_ug_RAE = 0.05` từ FDA 2019 (kèm ô đối chiếu `verify_pack.py`) vào `tools/build_pack.py`.
- **Kiến trúc `app/lib/state/` và truy vấn khoảng ngày:** bổ sung truy vấn theo khoảng ngày (`foodsBetween`, `dosesBetween`, `workoutsBetween`) trong `packages/journal_db` để bỏ N+1 khi nạp 7 ngày và lấy "Món gần đây"; bắt đầu tách state phần nhật ký/thư viện món khỏi `AppState`. Mọi truy vấn mới của `journal_db` phải có test chạy qua SQLite3MultipleCiphers trên CI.

## Nguồn

- **USDA FoodData Central** (CC0 1.0 Universal, <https://fdc.nal.usda.gov/api-guide>, <https://fdc.nal.usda.gov/download-datasets>, đã đối chiếu Chrome 25/11/2026; trích dẫn: *"U.S. Department of Agriculture, Agricultural Research Service. FoodData Central, 2019. fdc.nal.usda.gov."*):
  - **Foundation Foods (`10/2026`):** `424` món (JSON `681K` nén / `9M` giải nén: <https://fdc.nal.usda.gov/fdc-datasets/FoodData_Central_foundation_food_json_2026-10-29.zip>; bản CSV có bản sửa v2 ngày `11/19/2026` / v16.1). Không có `Vitamin E, added (1242)`, `Folic acid (1186)`, `Folate, food (1187)`, `Folate, DFE (1190)`, `Sugars, added (1235)`; chỉ có `Folate, total (1177)` (và `5-methyltetrahydrofolate`) cùng `Sugars, Total (1063)`.
  - **SR Legacy (`04/2018`, archive sửa `foodPortions.amount` ngày `04/24/2025` v13.0):** `7.793` món (JSON `12,3M` nén / `205M` giải nén: <https://fdc.nal.usda.gov/fdc-datasets/FoodData_Central_sr_legacy_food_json_2018-04.zip>). Có `1186/1187/1190`, `1242`, `Sugars, Total (2000)`; không có `1235`.
  - **FNDDS `2021–2023` (`10/2024`):** `5.432` mã món / `5.428` món tra cứu được trên FDC (JSON `3,7M` nén / `64M` giải nén: <https://fdc.nal.usda.gov/fdc-datasets/FoodData_Central_survey_food_json_2024-10-31.zip>; bỏ qua mã `11000000 Milk, human` vì không có hồ sơ dinh dưỡng). Có `1186/1187/1190`, `1242`, `Sugars, Total (2000)`; không có `1235`.
  - **Quy tắc `Vitamin E, added` (ID `1242` / `#573`):** `SR28 Documentation` tr. 27–28 (<https://fdc.nal.usda.gov/fdc-datasets/SR-Legacy-Archive/sr28_doc.pdf>, dẫn từ `SR-Legacy_Doc.pdf` tr. 6: <https://www.ars.usda.gov/ARSUserFiles/80400525/Data/SR-Legacy/SR-Legacy_Doc.pdf>). Cả `#323`/`1109` (`Vitamin E (alpha-tocopherol)`) lẫn `#573`/`1242` (`Vitamin E, added`) đều ghi theo **mg *2R*-α-tocopherol**. Riêng `#573`, USDA nêu rõ phần lớn món bổ sung dạng *all rac*-α-tocopherol nên cần nhân 2 cho UL (*"these values should be multiplied by 2 to relate intakes of this form to the UL"*); món có chú thích (footnote) bổ sung *RRR*-α-tocopherol thì dùng trực tiếp `1×` cho UL.
- **USDA FPED `2021–2023`** (U.S. Public Domain, khớp trực tiếp với FNDDS `2021–2023`, trang tài liệu cập nhật `10/21/2026`, đã đối chiếu Chrome 25/11/2026): <https://www.ars.usda.gov/northeast-area/beltsville-md-bhnrc/beltsville-human-nutrition-research-center/food-surveys-research-group/docs/fped-doc-and-datasets/> và <https://www.ars.usda.gov/ARSUserFiles/80400530/pdf/fped/FPED_2123_Documentation.pdf> (tr. 6, 31–32, 39: *"Added sugars (g) / 4.2 = teaspoon equivalents of added sugars"*, *"amount in 1 teaspoon granulated sugar (4.2 g)"*; số liệu FPED `2021–2023` làm tròn 1 chữ số thập phân).
- **FDA Guidance for Industry (August 2019, `FDA-2016-D-4484`, PDF tr. 19 Bảng 3, đã đối chiếu Chrome 25/11/2026):** <https://www.fda.gov/media/129863/download> — `Dietary β-carotene (IU) → mcg RAE = 0,05` (`1 IU = 0,6 µg` beta-caroten thực phẩm; `1 µg RAE = 12 µg` beta-caroten thực phẩm).

## Thiết kế kỹ thuật

### 1. Gói chuẩn (`tools/build_pack.py`, `tools/verify_pack.py`, `tools/reference_engine.py`)

- Cập nhật `UNIT_CONVERSIONS["vitA_food_betacarotene_IU_to_ug_RAE"] = 0.05` (gắn nguồn `fda_unit_conversions`, đã kiểm Chrome).
- Thêm kiểm tra ô `GOLDEN` cho `vitA_food_betacarotene_IU_to_ug_RAE == 0.05` trong `tools/verify_pack.py`.
- Cập nhật `tools/reference_engine.py` và sinh lại `cases.json` cho 2 ca trước đây thiếu hệ số ở [specs/engine-v2.md](engine-v2.md) (`row5b_vitA_bc_food_iu_*`, `row8_vitA_food_iu_unknown_*`) → trả đúng `vitA = IU × 0,05` (và `ulAmounts.retinol = IU × 0,3` ở hàng 8).

### 2. Đóng gói thư viện món SQLite chỉ đọc (`tools/build_food_library.py` → `app/assets/food_library.db`)

Công cụ Python `tools/build_food_library.py` đọc dữ liệu tải về của USDA FDC + FPED và tệp công thức món Việt nguồn mở trong repo (vd. `tools/data/vn_recipes.json`), chuẩn hóa và xuất tệp SQLite chỉ đọc (`food_library.db`) cùng mã băm SHA-256 ghi vào gói/manifest để app kiểm toàn vẹn trước khi mở:

- **Bảng trong `food_library.db`:**
  - `meta`: `library_version`, `usda_release`, `fped_release`, `built_at`, `pack_version`.
  - `foods`:
    - `id` (`TEXT PRIMARY KEY`: `usda:<fdc_id>` hoặc `recipe:<slug>`)
    - `kind` (`usda_foundation` | `usda_sr` | `usda_fndds` | `recipe`)
    - `name_vi`, `name_en`, `aliases_vi`, `search_ascii` (chuỗi không dấu phục vụ tìm tiếng Việt không dấu)
    - `is_estimate` (`0 | 1`; `1` cho mọi `recipe`)
    - `added_sugar_known` (`0 | 1`), `default_portion_id`
    - `niacin_fortified_unseparated` (`0 | 1`), `folate_unseparated` (`0 | 1`; `1` cho món Foundation Foods hoặc món SR Legacy chỉ có `Folate, total` `1177` mà thiếu `1186`/`1187`/`1190`)
  - `food_portions`: `id`, `food_id`, `label_vi`, `grams` (khối lượng 1 đơn vị khẩu phần, vd. `1 bát = 200 g`; luôn cho chọn thêm `gram`).
  - `food_nutrients_per_100g`: `food_id`, `nutrient_id`, `source` (`food` | `fortified`), `form` (`TEXT`, nullable: `folic_acid`, `natural_folate`, `retinol`, `synthetic_2r`, `natural_2r`…), `amount` (`REAL`), `ul_amount` (`REAL`, nullable — lưu giá trị tính vào UL nếu khác `amount`, vd. `val × 2` cho `vitE` `fortified` không có footnote *RRR*; `NULL` khi dùng trực tiếp `amount` hoặc không tính vào UL), `unit` (`TEXT`).
  - **Bộ khóa chuẩn trong `food_nutrients_per_100g`:**
    - Các khóa trong `pack.nutrients` (bao gồm cả `retinol`, `folicAcid`, `carbohydrate`, `protein`, `fiber`, `linoleic`, `ala`, các vitamin & khoáng chất);
    - 3 khóa tính toán ngoài `pack.nutrients` của engine (`assessment.dart`): `energyKcal` (`kcal`), `fat` (`g`), `addedSugar` (`g`);
    - 1 khóa chỉ dùng để hiển thị thông tin dinh dưỡng món ăn (không đưa vào tính toán hay giới hạn của engine): `totalSugar` (`g`, từ USDA `2000` / `1063`).
  - `foods_fts` (`VIRTUAL TABLE ... USING fts5(...)`): chỉ mục trên `name_vi`, `aliases_vi`, `search_ascii`, `name_en` để truy vấn dưới 20 ms trên máy tầm trung mà không nạp toàn bộ bảng vào bộ nhớ.
- **Tách nguồn dinh dưỡng khi nhập USDA FDC + FPED:**
  - **Đạm, béo, bột đường, năng lượng, chất xơ, khoáng chất, vitamin thường:** gán `source = food` theo giá trị /100 g. `Sugars, Total` đọc cả ID `2000` (SR Legacy, FNDDS) lẫn ID `1063` (Foundation Foods) và lưu dưới khóa hiển thị `totalSugar`.
  - **Folate:**
    - **SR Legacy & FNDDS** (khi có `1186` hoặc `1187`): nếu `Folic acid` (ID `1186`) > 0 → sinh dòng `source = fortified`, `form = 'folic_acid'` (`folate: x × 1,7`, `folicAcid: x`); `Folate, food` (ID `1187`) → dòng `source = food`, `form = 'natural_folate'` (`folate: y`).
    - **Foundation Foods & fallback SR Legacy thiếu `1186`/`1187`** (một số món SR Legacy cũ và toàn bộ Foundation Foods chỉ có `Folate, total` ID `1177` — kể cả bánh mì trắng tăng cường `FDC #2758993` cũng chỉ có `1177 = 157 µg`): đưa `1177` vào `source = food` (`folate = giá trị 1177`, không rơi mất thành `0`) và **không gán `folicAcid`**; đánh dấu `foods.folate_unseparated = 1` để UI hiện nhãn "folate tổng, chưa tách nguồn". Nếu cần tách chính xác nguồn axit folic cho UL, ưu tiên dùng bản ghi SR Legacy / FNDDS có tách `1186`/`1187` khi trùng tên món (xem Câu hỏi đã chốt 2).
  - **Vitamin E (đã chốt theo `sr28_doc.pdf` tr. 27–28, đối chiếu Chrome 25/11/2026):**
    - `Vitamin E, added` (ID `1242`) **chỉ có ở SR Legacy và FNDDS** (Foundation Foods: 0 mục).
    - ID `1242` ghi theo **mg *2R*-α-tocopherol** (đã quy đổi từ hàm lượng *all rac* bằng hệ số `0,45`). USDA nêu rõ: *"the form added is all rac-α-tocopherol; these values should be multiplied by 2 to relate intakes of this form to the UL"* (`sr28_doc.pdf` tr. 28).
    - Quy tắc khi `1242 > 0`:
      - Dòng `source = fortified`: `nutrient_id = 'vitE'`, `amount = val`:
        - Mặc định (không có footnote *RRR*): `form = 'synthetic_2r'`, **`ul_amount = val × 2`** (nhân 2 nguyên văn theo USDA) → `computeLines` xuất `amounts: {'vitE': val}`, `ulAmounts: {'vitE': val × 2}`.
        - Ngoại lệ (món có chú thích bổ sung *RRR*-α-tocopherol): `form = 'natural_2r'`, `ul_amount = NULL` → `computeLines` xuất `amounts: {'vitE': val}`, `ulAmounts: null` (tính `1×` trực tiếp từ `amounts`).
    - Dòng `source = food` (phần tự nhiên): `amount = max(0, ID_1109 − ID_1242)`, `ul_amount = NULL` (vitamin E tự nhiên từ thức ăn không tính vào UL).
    - Foundation Foods chỉ có `ID_1109` → toàn bộ gán `source = food`, `ul_amount = NULL`.
  - **Vitamin A:** `Vitamin A, RAE` (ID `1106`) → `vitA` (`source = food`); `Retinol` (ID `1105`) → `retinol` (`source = food`, `form = 'retinol'`, vì UL vitamin A tính retinol mọi nguồn).
  - **Đường bổ sung (đã kiểm Chrome 25/11/2026 — Foundation, SR Legacy, FNDDS đều không có `Sugars, added` ID `1235`; chỉ Branded Foods mới có):**
    - **FNDDS `2021–2023`:** ghép qua mã WWEIA/FNDDS trong **FPED `2021–2023`** (`addedSugar = ADD_SUGARS × 4,2 g / 100 g`, `added_sugar_known = 1`).
    - **Foundation Foods & SR Legacy:** không có FPED, không có `1235` → xử lý theo Câu hỏi đã chốt 1 (nhóm nguyên liệu thô/tươi: `addedSugar = 0`, `added_sugar_known = 1`; còn lại `added_sugar_known = 0`).
- **Danh sách món Việt & báo cáo kiểm khớp (`tools/check_vietnamese_foods.py`):**
  - Danh sách kiểm sớm 200 thực phẩm phổ biến + 30 công thức món Việt đầu tiên (`tools/data/vn_recipes.json`) và danh sách "món chỉ có ở Việt Nam" chưa có công thức chuẩn (`tools/data/vn_only_foods.json`) để UI/tài liệu tham chiếu.

### 3. Interface và lớp dữ liệu (`packages/food_library`, `packages/journal_db`, `app`)

- **Gói mới hoặc mô-đun `packages/food_library` (thuần Dart, hoặc tích hợp interface rõ ràng):**
  - `abstract interface class FoodLibraryRepository`:
    - `Future<List<FoodSummary>> search(String query, {int limit = 30})`
    - `Future<FoodDetail?> getById(String foodRef)`
    - `List<IntakeLine> computeLines(FoodDetail food, double grams, {required ReferencePack pack})` (đọc thẳng `amount`, `ul_amount`, `form`, `source` từ `food_nutrients_per_100g` để nhân theo `grams / 100` và sinh `amounts`, `ulAmounts`).
  - **Cách mở `food_library.db` trên Android / thiết bị:** vì `sqlite3` không mở trực tiếp tệp `.db` nén trong asset APK bằng đường dẫn, `SqliteFoodLibraryRepository` khi khởi tạo (thông qua interface `FoodLibraryAssetStore` để test không cần Flutter binding) phải giải nén/copy `assets/food_library.db` ra thư mục cục bộ của app theo phiên bản (`<appSupportDir>/food_library_<library_version>.db`, xóa bản phiên bản cũ nếu có), **kiểm SHA-256 trên tệp cục bộ đã giải nén** rồi mới mở qua `sqlite3.open(..., mode: OpenMode.readOnly)` (không giữ toàn bộ danh sách món trong RAM). Kèm `FakeFoodLibraryRepository` cho unit/widget test.
- **Mở rộng `JournalRepository`, `DriftJournalRepository` và `InMemoryJournalRepository` (`packages/journal_db`):**
  - Đưa các hàm sửa món hiện mới có trên `DriftJournalRepository` lên cả interface `JournalRepository` và cài đặt cho `InMemoryJournalRepository`:
    - `Future<FoodEntry?> foodById(int id)`
    - `Future<void> moveFood(int id, DateTime at)`
    - `Future<void> updateFoodMeta(int id, {required DateTime at, required MealSlot meal})` (đổi giờ/ngày + bữa ăn và đồng bộ `intake_lines.day` trong một giao dịch)
    - `Future<void> scaleLabelFoodPortion(int id, double newQty)`
    - `Future<void> replaceFoodLines(int id, {required double portionQty, required List<IntakeLine> lines, required String packVersion})`
  - Truy vấn khoảng ngày và món gần đây:
    - `Future<List<FoodEntry>> foodsBetween(String fromDay, String toDay)`
    - `Future<List<DoseEntry>> dosesBetween(String fromDay, String toDay)`
    - `Future<List<WorkoutRecord>> workoutsBetween(String fromDay, String toDay)`
    - `Future<List<FoodEntry>> recentFoods({int limit = 20})` (lấy các món gần đây theo `food_ref` / tên gần nhất để ghi trong ≤3 chạm, bỏ N+1).
  - Quản lý món tự lưu ("Nhập theo nhãn" có tick `"Lưu để dùng lại"` — giữ nguyên `custom_foods` và `custom_food_lines` của `schemaV1`, **không cần di chuyển lược đồ CSDL**):
    - `Future<int> saveCustomFood(CustomFoodInput input)` / `Future<List<CustomFood>> searchCustomFoods(String query)` / `Future<void> archiveCustomFood(int id)`.
    - **Quy ước phân biệt đường bổ sung và khóa phạm vi `custom_food_lines` (`schemaV1`):**
      - Bảng `custom_foods` không có cột `added_sugar_known`. Vì vậy, khi người dùng **nhập `0`** ở ô Đường bổ sung và lưu món dùng lại → bắt buộc ghi một dòng `nutrient_id = 'addedSugar', label_amount = 0, label_unit = 'g', source = 'food'` vào `custom_food_lines` (không bỏ qua số `<= 0` như khung tạm `add_food_screen.dart` cũ). Khi **bỏ trống** ô Đường bổ sung → **không** ghi dòng `addedSugar`. Khi đọc lại `CustomFood` để tạo `FoodEntryInput`: có dòng `addedSugar` (dù `0`) ⇒ `addedSugarKnown = true`, vắng mặt ⇒ `addedSugarKnown = false`.
      - Vì `custom_food_lines` đặt `nutrient_id TEXT NOT NULL` và không có `compound_kind`, `secondary_folic_acid_ug`: khóa phạm vi `Nhập theo nhãn` chỉ chọn chất trong danh sách cố định của gói + `energyKcal`, `fat`, `addedSugar`, `totalSugar` (không nhập tên chất tự do — tên tự do dành cho thực phẩm bổ sung ở việc 5); khoáng chất nhập theo hàm lượng nguyên tố; nhãn ghi folate dạng `x µg DFE (y µg axit folic)` thì tách lưu thành dòng `folicAcid` (`y µg`, `source = fortified`) và dòng `folate` phần tự nhiên (`max(0, x − y × 1,7) µg DFE`, `source = food`).
- **Tách state theo miền trong `app/lib/state/`:**
  - Giữ `AppState` (hoặc tách dần thành `DbSessionController` và `DiaryController` dùng interface `JournalRepository` + `FoodLibraryRepository`), gọi `foodsBetween`/`dosesBetween`/`workoutsBetween` thay cho vòng lặp 7 ngày tuần tự.

### 4. Luồng xử lý

1. **Tìm và ghi món từ thư viện (`Ghi món → Chọn khẩu phần`):**
   - Mở `Ghi món`: tự chọn bữa theo `Giờ trong ngày` (±1,5 giờ quanh Sáng/Trưa/Tối, ngoài ra là Phụ; mặc định sẵn `settings` nếu chưa chỉnh), hiện danh sách **Món gần đây** (USDA, công thức, và `custom_foods` đã lưu).
   - Chạm món gần đây → ghi ngay với khẩu phần lần trước, hiện `UndoSnack` 7 giây (`Hoàn tác` xóa món vừa ghi; `Sửa` mở `Sửa mục`).
   - Gõ tìm → FTS5 trên `food_library.db` + tìm trong `custom_foods`; chọn món → mở `Chọn khẩu phần` (chọn đơn vị quen thuộc hoặc `gram`, `[−] {số lượng} [+]`, xem calo ước tính qua `CalorieText`, bấm `Lưu`).
   - Lưu → tính dòng chất bằng `computeLines` với `pack` hiện hành → `repo.addFood(...)` → kiểm tra cờ vượt UL và đường bổ sung >10 g/bữa.
2. **Nhập theo nhãn:**
   - Nhập tên món, quy mô nhãn (`vd. 100 ml` hoặc `1 gói`), lượng đã dùng (`vd. 180 ml`), các trường năng lượng / đạm / béo / bột đường / đường tổng / đường bổ sung (tùy chọn, có giải thích chỉ nhập khi nhãn ghi riêng) / natri / `+ Thêm vi chất trên nhãn` (chỉ chọn chất có trong gói, khoáng chất nhập theo hàm lượng nguyên tố).
   - Quy đổi từng dòng qua `UnitConverter.convertIntakeLine` (`niacin`, `vitE`, `folicAcid`, và `folate` khi chọn `form = 'folic_acid'` tự động đặt `source = fortified`).
   - Kiểm hợp lý đơn vị trước khi lưu (xem Câu hỏi đã chốt 4): nếu nghi nhầm đơn vị, nhắc ngay dưới ô/hộp thoại xác nhận, không chặn lưu khi người dùng xác nhận đúng.
   - Nếu tick `"Lưu để dùng lại"`: lưu `custom_foods` + `custom_food_lines` cùng giao dịch hoặc trước khi ghi `food_entries` với `food_ref = 'custom:<id>'`. Khi ô Đường bổ sung nhập `0` phải lưu dòng `addedSugar = 0 g` vào `custom_food_lines`; bỏ trống mới không lưu dòng này.
3. **Sửa món đã ghi (`Sửa mục`):**
   - Đổi khẩu phần: món theo nhãn gọi `scaleLabelFoodPortion`; món `usda:` / `recipe:` đọc `FoodDetail` từ thư viện tính lại dòng chất theo `pack` hiện tại và gọi `replaceFoodLines(..., packVersion: pack.version)`.
   - Đổi giờ/bữa/ngày: cập nhật `at`, `meal`, `day` (và `intake_lines.day`) trong một giao dịch qua `updateFoodMeta` / `moveFood`, tải lại cả ngày cũ và ngày mới nếu đổi ngày, kiểm lại cờ UL và đường bổ sung.

### 5. Lỗi và biên

- **Tệp `food_library.db` thiếu, không giải nén được hoặc sai SHA-256 trên tệp cục bộ (lỗi cài đặt):** màn chặn không hiện số món hỏng ("Không đọc được thư viện món ăn. Hãy cài lại WholeWell từ cửa hàng ứng dụng.").
- **Món USDA/công thức bị bỏ khỏi bản thư viện mới khi người dùng bấm sửa khẩu phần một bản ghi cũ:** vẫn cho giữ/xóa/đổi giờ/bữa, hoặc hiện thông báo không tìm thấy món gốc trong thư viện để tính lại (nhân tỷ lệ `newQty / oldQty` từ `intake_lines` hiện có như fallback an toàn kèm ghi chú nếu `FoodDetail` không còn trong bản thư viện mới để người dùng không bị kẹt).
- **Tìm kiếm không dấu / ký tự đặc biệt FTS5:** thoát chuỗi truy vấn (`"..."` hoặc tách token chữ-số) để gõ dấu ngoặc kép, dấu gạch ngang, `%` không gây lỗi cú pháp SQLite FTS5.
- **Nhập theo nhãn để trống ô Đường bổ sung:** `added_sugar_known = false`, vào danh sách `unknownSugarFoods` ("Chưa tính đường bổ sung của {n} món"). Nhập `0`: `added_sugar_known = true` (`0 g`).
- **Sửa món làm vượt UL hoặc vượt 10 g đường/bữa:** hiện phản hồi đúng nguyên tắc "chỉ một phản hồi" của `mvp-overview.md`.

## Tiêu chí đạt

- [ ] `tools/build_pack.py` + `verify_pack.py` + `reference_engine.py` có `vitA_food_betacarotene_IU_to_ug_RAE = 0.05` (từ FDA 2019), hàng 5b và hàng 8 `convertIntakeLine` qua test Python & Dart.
- [ ] `tools/build_food_library.py` dựng được `food_library.db` (FTS5) từ USDA FDC + FPED + ít nhất 30 công thức món Việt tự soạn từ nguyên liệu USDA; lưu đủ `form`, `ul_amount` trên `food_nutrients_per_100g` và `folate_unseparated` trên `foods` (kể cả fallback `1177` cho SR Legacy thiếu `1186`/`1187`); có kiểm khớp 200 thực phẩm và danh sách món chỉ có ở Việt Nam.
- [ ] Khi khởi tạo trên thiết bị, `food_library.db` được giải nén ra thư mục cục bộ theo `library_version` và kiểm SHA-256 trên tệp đã giải nén trước khi `sqlite3` mở; gõ ký tự đặc biệt vào ô tìm (`"`, `*`, `-`, `(`, `)`) không văng lỗi FTS5; tìm không dấu tiếng Việt khớp đúng món (`pho bo` → `Phở bò`).
- [ ] Món USDA có `Folic acid` / `Vitamin E, added` sinh đủ 2 dòng `food` và `fortified` (`ul_amount` của `vitE` nhân 2 trừ ngoại lệ *RRR*); `folicAcid` và `vitE` cộng đúng vào UL phạm vi `total`/`synthetic`.
- [ ] Món FNDDS lấy đường bổ sung từ `FPED ADD_SUGARS × 4,2 g`; món `recipe` gắn `is_estimate = true`; Nhập theo nhãn chọn `folate` + `form = folic_acid` tự gán `source = fortified`; để trống đường bổ sung → `added_sugar_known = false`, nhập `0` → `added_sugar_known = true` (kể cả khi lưu/tải lại từ `custom_foods`/`custom_food_lines`).
- [ ] `JournalRepository` và `InMemoryJournalRepository` có đủ `foodById`, `moveFood`, `updateFoodMeta`, `scaleLabelFoodPortion`, `replaceFoodLines`, `foodsBetween`, `dosesBetween`, `workoutsBetween`, `recentFoods`, `saveCustomFood`, `searchCustomFoods`, `archiveCustomFood`; `DriftJournalRepository` có test SQLite3MultipleCiphers qua CI.
- [ ] Sửa khẩu phần món USDA/công thức gọi `replaceFoodLines` tính lại từ thư viện món và lưu `pack_version` mới; sửa khẩu phần món nhãn gọi `scaleLabelFoodPortion`; nếu món thư viện cũ không còn trong `food_library.db` vẫn sửa được khẩu phần an toàn.
- [ ] Kiểm hợp lý đơn vị ở Nhập theo nhãn nhắc người dùng khi vượt ngưỡng nhưng không chặn lưu nếu người dùng xác nhận.

## Ngoài phạm vi

- Màn Điều kiện, Đồng ý, chế độ thận trọng và Ghi nước (việc 4).
- Quét mã vạch USDA/DSLD và chụp nhãn OCR (việc 5).
- Nhập giọng nói tiếng Việt trên máy (cần kiểm sớm riêng trên thiết bị thật).
- Thiết kế giao diện chi tiết màn Ghi món / Chọn khẩu phần / Nhập theo nhãn / Sửa mục (thuộc bước 2: `docs/design/food-library.md` sau khi đặc tả này được duyệt).

## Câu hỏi đã chốt (duyệt 25/11/2026)

1. **Đường bổ sung Foundation Foods & SR Legacy → Đề xuất A (thận trọng vừa):** gán `added_sugar_known = true (0 g)` cho các nhóm nguyên liệu thô/tươi không pha trộn (theo danh sách `food_group`/`food_category` USDA công bố rõ, liệt kê cứng trong `build_food_library.py`); mọi món chế biến/pha trộn không có FPED đều đặt `added_sugar_known = false`.
2. **Foundation Foods & SR Legacy thiếu `1186`/`1187`:** fallback dùng `1177` làm `folate` (`source = food`), đánh dấu `foods.folate_unseparated = 1`; ưu tiên bản ghi SR Legacy / FNDDS có tách `1186`/`1187` khi trùng tên món để tách nguồn axit folic cho UL.
3. **Dung lượng APK và ổ cứng:** đo thử cả kích thước nén trong APK (≤ `4 MB`) lẫn kích thước thực tế sau giải nén trên ổ cứng; nếu đạt ngưỡng gọn thì giữ đủ cả 3 bộ (~`13.645` món); nếu nặng hơn thì chọn lọc (bỏ SR Legacy trùng Foundation/FNDDS).
4. **Ngưỡng nhắc nhầm đơn vị Nhập theo nhãn:** `> 100% UL` (chất có UL) hoặc `> 10× RDA/AI` (chất không UL) → hiện nhắc nhẹ *"Số liệu cao bất thường, kiểm tra lại mg và µg"*, cho xác nhận để lưu.
