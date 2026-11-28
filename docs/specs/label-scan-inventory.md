# Đặc tả: Chụp nhãn, mã vạch, kho, hạn dùng

Trạng thái: Đã duyệt (25/11/2026; Bổ sung 1: 28/11/2026)  <!-- Nháp | Đã duyệt -->
Thiết kế UX: [docs/design/label-scan-inventory.md](../design/label-scan-inventory.md)
Thứ tự MVP: Việc 5 trong [docs/status.md](../status.md)

## Mục tiêu
Giúp người dùng thêm sản phẩm thực phẩm bổ sung vào tủ thuốc cá nhân bằng quét mã vạch, chụp/chọn ảnh nhãn (OCR trên máy) hoặc nhập tay, chuẩn hóa từng thành phần theo chất và dạng (kể cả tỷ lệ nguyên tố hợp chất và quy đổi FDA), đồng thời quản lý kho theo từng hộp (số còn lại, hạn dùng, dự kiến ngày hết) và ghi lần uống kèm trừ kho.

## Người dùng và tình huống
- Người dùng mở tab **Bổ sung** (hoặc chọn **Bổ sung** từ nút nổi **Ghi**) để:
  1. Thêm một sản phẩm mới đang cầm trên tay (hộp vitamin tổng hợp, canxi, sắt, magie, kẽm...) bằng cách quét mã vạch hoặc chụp/chọn ảnh bảng thành phần (*Supplement Facts* / *Thành phần dinh dưỡng*), rà soát và xác nhận từng dòng rồi lưu.
  2. Nhập thêm hộp mới cho sản phẩm đã có khi mua thêm, theo dõi số viên/gói/ml còn lại, hạn dùng (`MM/YYYY`), cảnh báo sắp hết (≤7 ngày) hoặc đã hết hạn.
  3. Ghi một lần uống (từ sản phẩm có sẵn hoặc ghi một lần không lưu sản phẩm), trừ vào hộp còn hạn sớm nhất (hoặc hỏi người dùng khi chỉ còn hộp hết hạn).

## Ràng buộc
- **AI chỉ chạy trên máy, dữ liệu ở máy** (sửa ở Bổ sung 1, theo quyết định ngày 28/11/2026): OCR, quét mã vạch và AI tạo sinh (Gemini Nano qua Android AICore, chỉ để gợi ý tách thành phần từ chữ OCR) chạy hoàn toàn trên thiết bị, không gửi ảnh hay chữ trên nhãn ra ngoài. Không tự suy đoán hay tự động ghi thành phần vào CSDL khi người dùng chưa xác nhận từng dòng; engine quyết định mọi số và cảnh báo.
- **Chuẩn tham chiếu & phạm vi UL:**
  - Quy đổi đơn vị nhãn (IU, DFE, NE, RAE) và hợp chất qua `UnitConverter.convertIntakeLine(IntakeLineInput)` có sẵn trong `packages/health_engine/lib/src/units.dart`.
  - Tỷ lệ nguyên tố của hợp chất (canxi, sắt, kẽm, magie...) chỉ thêm vào `tools/build_pack.py` sau khi đối chiếu trực tiếp trang Fact Sheet của NIH ODS bằng trình duyệt thật, kèm ô đối chiếu trong `tools/verify_pack.py`.
  - Dạng chưa rõ (`CompoundKind.unknown` / `form == 'unknown'`): `UnitConverter.convertIntakeLine` tính giới hạn an toàn (UL) theo cách thận trọng nhất (số lớn nhất có thể), so mức khuyến nghị lấy số nhỏ nhất có thể và đánh dấu `uncertain = true` ("chưa chắc").
  - **Lần uống luôn được ghi và luôn tính vào giới hạn an toàn**, kể cả khi kho bằng 0 (`shortfall > 0`) hoặc người dùng chọn không trừ vào hộp hết hạn (`ExpiredBoxChoice.skip`). Số lượng còn lại trong hộp không bao giờ âm.
- **Chế độ thận trọng & ẩn calo:** Không dùng từ "mục tiêu"; bảng cảnh báo giữ nguyên khi vượt UL.
- **Không link cửa hàng / không gợi ý nhãn hàng / không kiểm tương tác thuốc.**
- **Interface nền tảng:** Mọi phụ thuộc camera/chọn ảnh/OCR/mã vạch đi qua interface (`OcrEngine`, `BarcodeScanner`), có bản giả (`FakeOcrEngine`, `FakeBarcodeScanner`) để unit/widget test không cần thiết bị thật.

## Nguồn
- **NIH Office of Dietary Supplements (ODS) — Health Professional Fact Sheets** (kiểm chứng trực tiếp qua trình duyệt trước khi chốt số vào `tools/build_pack.py`):
  - Canxi: `https://ods.od.nih.gov/factsheets/Calcium-HealthProfessional/` (canxi carbonat 40%, canxi citrat 21%, ...).
  - Sắt: `https://ods.od.nih.gov/factsheets/Iron-HealthProfessional/` (ferrous fumarate 33%, ferrous sulfate 20%, ferrous gluconate 12%, ...).
  - Kẽm: `https://ods.od.nih.gov/factsheets/Zinc-HealthProfessional/` (zinc sulfate, zinc gluconate, zinc acetate nếu nêu rõ).
  - Magie: `https://ods.od.nih.gov/factsheets/Magnesium-HealthProfessional/` (kiểm xem Fact Sheet có nêu % nguyên tố hay không; nếu không nói rõ thì không đặt hệ số cố định).
- **FDA 21 CFR 101.9 / 101.36 & Hướng dẫn đổi đơn vị 2019:** hệ số IU ↔ µg/mg, DFE, NE, RAE (đã có trong `reference_pack.json`).
- **NIH Dietary Supplement Label Database (DSLD):** `https://dsldapi.od.nih.gov/` (CC0) — xem Câu hỏi còn mở #2.

## Thiết kế kỹ thuật

### 1. Gói dữ liệu (`tools/build_pack.py`, `tools/verify_pack.py`) & Engine (`packages/health_engine`)
- **Cấu trúc `compounds`:** Giữ nguyên `UNIT_CONVERSIONS["compounds"]` (và `unitConversions.compounds` trong `ReferencePack`) là `Map<String, Map<String, double>>` (`{nutrient_id: {form_id: elemental_ratio}}`) để tương thích hoàn toàn với `_numMap()` trong `reference_pack.dart`. Nguồn, link và ngày tra đặt trong `SOURCES`; nếu cần tên tiếng Việt hoặc trích dẫn cho UI/hiển thị, đặt ở mục metadata riêng (vd. `compoundMeta` tách biệt khỏi `unitConversions.compounds`).
- **Quy đổi & kiểm tra hợp lý:** Tái sử dụng `UnitConverter.convertIntakeLine(IntakeLineInput)` trong `packages/health_engine/lib/src/units.dart` (đã xử lý `CompoundKind.elemental`, `CompoundKind.compound`, `CompoundKind.unknown`, vitA, vitE, vitD, folate). Chỉ bổ sung hàm kiểm tra hợp lý (*sanity check*, viết cả ở `tools/reference_engine.py` và `health_engine`):
  - Cảnh báo không chặn khi nghi nhầm `mg` ↔ `µg` (ví dụ nhập số quá lớn ở đơn vị `mg` cho chất có chuẩn `µg` như vitamin D, B12, selen, folate, hoặc một khẩu phần đã vượt giới hạn an toàn UL của chất đó).

### 2. Cơ sở dữ liệu (`packages/journal_db`)
Các bảng trong `schemaV1` (`products`, `ingredients`, `boxes`, `dose_entries`, `dose_box_deductions`, `intake_lines`) đã có sẵn; `DriftJournalRepository` đã có phần nền (`addProduct`, `productById`, `addBox`, `boxesOf`, `recordDose`, `moveDose`, `deleteDose`). Việc 5 mở rộng đồng bộ lên interface **`JournalRepository`** và cài đặt đầy đủ cho **`InMemoryJournalRepository`** (cùng integration test qua SQLite3MultipleCiphers cho mọi hàm mới):
- **Sản phẩm & thành phần:**
  - Migration `schema_version = 2`: thêm cột `barcode TEXT` vào bảng `products` (`ALTER TABLE products ADD COLUMN barcode TEXT`), kèm integration test di chuyển lược đồ `v1 -> v2` trên SQLite3MultipleCiphers.
  - Đưa `addProduct`, `productById`, `addBox`, `boxesOf`, `recordDose`, `moveDose`, `deleteDose` lên `JournalRepository` và cài đặt trên `InMemoryJournalRepository`.
  - Thêm `listProducts({bool includeArchived = false})`, `productByBarcode(String barcode)`, `productDetail(int productId)` (trả sản phẩm + `ingredients` + `boxes`), `updateProduct(...)`, `saveProductIngredients(int productId, List<IngredientDraft> items)`.
  - **Không hồi tố lịch sử:** Khi sửa `ingredients` của sản phẩm đã lưu, chỉ cập nhật bảng `ingredients` cho các lần uống **mới**; mọi `dose_entries` cũ giữ nguyên `intake_lines` đã lưu tại thời điểm uống.
  - `archiveProduct(int productId)`: đặt `products.archived = 1`; nếu sản phẩm đang có dòng trong `schedules` với `valid_to IS NULL OR valid_to >= today`, đóng luôn bằng `valid_to = today` (trong cùng giao dịch) để tránh lịch mồ côi ở Việc 6.
- **Kho, hộp (`boxes`) & hạn dùng:**
  - Thêm `updateBox(int boxId, {double? remaining, String? expiryMonth})` và `deleteBox(int boxId)`.
  - **Định dạng hạn dùng:** UI nhập `MM/YYYY` (kiểm hợp lệ tháng `01..12` và năm 4 chữ số), chuyển sang `YYYY-MM` trước khi lưu vào `boxes.expiry_month` (khớp ràng buộc `GLOB '[0-9][0-9][0-9][0-9]-[0-9][0-9]'` trong `schema.dart`).
  - Phân loại hộp theo tháng hiện tại `YYYY-MM`:
    - Còn hạn: `expiryMonth == null || expiryMonth >= currentMonth`
    - Hết hạn: `expiryMonth != null && expiryMonth < currentMonth` ("qua tháng ghi trên hộp").
  - **Biên tính ngày dự kiến hết:** Tổng `remaining` các hộp **còn hạn** chia cho lượng dùng trung bình/ngày (từ lịch đang hiệu lực nếu có, hoặc trung bình 14 ngày gần nhất từ `dose_entries`). Trong Việc 5 khi chưa có lịch và 14 ngày gần nhất chưa uống (hoặc trung bình/ngày = 0), **không tính ngày dự kiến hết** — chỉ hiển thị `"Còn {n} {đơn vị}"`, tránh chia cho 0 hoặc ước lượng sai. Gắn nhãn `"Sắp hết"` khi ngày dự kiến hết ≤ 7 ngày.
- **Ghi & sửa lần uống (`dose_entries` + `dose_box_deductions` + `intake_lines`):**
  - `recordDose(DoseInput)` xử lý trừ kho trong một giao dịch (trừ hộp còn hạn hết hạn sớm nhất -> nếu chỉ còn hộp hết hạn trả `NeedsExpiredChoice` -> nếu đủ hoặc thiếu vẫn ghi `dose_entry` + `intake_lines` và trả `DoseRecorded` kèm `shortfall`).
  - Bổ sung `Future<DoseResult> updateDose(int doseId, {required double servings, required DateTime at, ExpiredBoxChoice? expiredBoxChoice})`: trong cùng một giao dịch, nếu chỉ còn hộp hết hạn và chưa có `expiredBoxChoice`, trả về **`NeedsExpiredChoice`** mà **chưa sửa lần uống hay hoàn/trừ kho cũ**; khi đủ điều kiện hoặc đã có lựa chọn, hoàn trả toàn bộ `dose_box_deductions` cũ về `boxes.remaining`, trừ lại theo `servings` mới (`shortfall` nếu thiếu) và tính lại `intake_lines` theo thành phần hiện tại của sản phẩm (nếu gắn `productId`).

### 3. Interface nền tảng & Thử OCR trên máy thật (`app/lib/platform/`)
- `OcrEngine`: tách rõ 2 đường lấy ảnh + bước nhận dạng chữ để khi người dùng từ chối quyền Camera vẫn chọn ảnh từ thư viện hoặc nhập tay được:
  - `captureLabelImage()` (Document Scanner on-device làm phẳng nhãn, fallback Camera), `pickLabelImageFromGallery()`, `recognizeLabelFromImages(...)` (ML Kit Text Recognition v2 on-device), và `extractLabelJsonWithOnDeviceAi(...)` (Gemini Nano on-device qua Android AICore khi thiết bị hỗ trợ; fallback tự động về `SupplementLabelParser` → nhập tay; không gửi ảnh ra ngoài).
- Bộ phân tích nhãn thuần Dart (`SupplementLabelParser`): tách chuỗi OCR thô thành các dòng tiềm năng `{rawLine, nutrientId?, form?, amount?, unit?, isCompound}` để người dùng rà soát, chỉnh sửa và xác nhận từng dòng.
- `BarcodeScanner`: `Future<String?> scanBarcode()`.
- Kiểm thử sớm: chạy thử nghiệm `google_mlkit_text_recognition` + `mobile_scanner` trên Galaxy S24 Ultra với 5–10 ảnh nhãn thật trước khi chốt parser.

### 4. Luồng xử lý & Màn hình chính
- **Thanh điều hướng 4 tab:** mở rộng `HomeScreen` thành `Hôm nay · Nhật ký · Bổ sung · Tôi`.
- **Tab Bổ sung (`supplements_screen.dart`):** danh sách sản phẩm trong tủ (kèm tổng còn lại của hộp còn hạn, HSD gần nhất, trạng thái `Sắp hết` / `Đã hết hạn`), nút `[+ Thêm sản phẩm]`.
- **Thêm / Sửa sản phẩm:** Quét mã vạch (tìm sản phẩm đã có hoặc chuyển tiếp) → Chụp ảnh nhãn / Chọn từ thư viện (hoặc Nhập tay) → Màn **Xác nhận thành phần** (chọn chất trong gói hoặc tên tự do, dạng/hợp chất/nguyên tố, lượng, đơn vị, kiểm hợp lý, đánh dấu xác nhận từng dòng) → Thông tin sản phẩm (tên, đơn vị đếm, số đơn vị/khẩu phần, hộp đầu tiên) → Lưu.
- **Chi tiết sản phẩm & Quản lý hộp:** xem thành phần chuẩn hóa + số gốc, sửa thành phần, xem/thêm/sửa/xóa từng hộp (`MM/YYYY` ↔ `YYYY-MM`).
- **Ghi bổ sung (từ Bảng `Ghi` → `Bổ sung` hoặc từ Chi tiết sản phẩm):**
  1. Chọn sản phẩm (hoặc `Ghi một lần` không lưu kho), nhập số khẩu phần và giờ uống, bấm Lưu.
  2. Gọi `recordDose`: nếu trả về **`NeedsExpiredChoice`**, hiển thị hộp thoại `"Trừ vào hộp đã hết hạn?"` (`[Trừ]` / `[Không trừ]`), rồi gọi lại `recordDose` với `ExpiredBoxChoice.deduct` hoặc `ExpiredBoxChoice.skip`.
  3. Khi trả về **`DoseRecorded`**:
     - Luôn chạy kiểm tra giới hạn an toàn (ngày & 7 ngày) và hiển thị `FoodFeedbackSheet` / `WarningCard` nếu vượt.
     - Nếu `shortfall > 0`, hiển thị nhắc `"Kho đã hết · Thêm hộp"` (kèm lối mở thêm hộp). Khi vừa `shortfall > 0` vừa vượt UL, giữ nguyên tắc mỗi lần ghi chỉ 1 phản hồi chính: ưu tiên bảng cảnh báo UL, dòng nhắc `"Kho đã hết · Thêm hộp"` đi kèm gọn bên trong (chi tiết bố cục ở Bước 2 Thiết kế UX).

### 5. Lỗi và biên
- Từ chối quyền Camera: gợi ý chọn ảnh từ thư viện hoặc nhập tay từng dòng, không kẹt luồng.
- OCR không đọc được chữ / ảnh mờ: cho phép chụp lại, chọn ảnh khác hoặc nhập tay.
- Nhãn nghi nhầm đơn vị (`mg` ↔ `µg`) hoặc 1 khẩu phần vượt UL: hiện cảnh báo kiểm lại ngay trên dòng đó, không tự sửa số của người dùng.
- Chất không có trong gói (vd. Coenzyme Q10, Glucosamine): lưu `nutrient_id = null, free_name = ...`, hiển thị trong Chi tiết sản phẩm, không tính vào RDA/UL.

## Tiêu chí đạt
- [ ] `tools/build_pack.py` giữ `unitConversions.compounds` là `{nutrient_id: {form_id: ratio}}`, đối chiếu trực tiếp NIH ODS qua trình duyệt thật, kèm `compoundMeta` (nếu cần), ô đối chiếu trong `tools/verify_pack.py` và sanity check trong `tools/reference_engine.py` + `packages/health_engine` (tái sử dụng `UnitConverter.convertIntakeLine`).
- [ ] `JournalRepository` (cả `InMemory` và `Drift`) có đủ CRUD sản phẩm, thành phần (không hồi tố lịch sử), hộp (`MM/YYYY` ↔ `YYYY-MM`), `archiveProduct` đóng lịch mở, `recordDose` và `updateDose` (hoàn trả `dose_box_deductions`), pass integration test qua SQLite3MultipleCiphers.
- [ ] Giao diện 4 tab (`Hôm nay · Nhật ký · Bổ sung · Tôi`), xử lý trọn vẹn `NeedsExpiredChoice` (`[Trừ]` / `[Không trừ]`), `DoseRecorded.shortfall > 0` (`"Kho đã hết · Thêm hộp"`), và kiểm tra UL sau khi ghi.
- [ ] `OcrEngine` tách chụp camera / chọn thư viện / nhận dạng chữ, có `FakeOcrEngine` & `FakeBarcodeScanner` để widget test chạy offline trên mọi nền tảng.
- [ ] Chạy qua toàn bộ `build_pack.py && verify_pack.py && reference_engine.py`, `dart analyze/test` ở `health_engine`, `journal_db`, và `flutter analyze/test` ở `app`.

## Ngoài phạm vi
- **Lịch uống định kỳ, nhắc giờ thông báo Android, nút "Đã uống" từ thông báo, 5 quy tắc lịch & thẻ "Bạn có biết"**: làm ở **Việc 6**.
- **Lưu tệp ảnh nhãn trên máy & nút `Ảnh nhãn ›` trên Chi tiết sản phẩm**: chưa lưu tệp ảnh nhãn lên thiết bị trong Việc 5 (tránh phát sinh mã hóa tệp ảnh ngoài CSDL và dọn dẹp khi sao lưu/xóa dữ liệu); để sau nếu cần.
- **Hiển thị chi tiết chất (2 tổng mọi nguồn / UL) & chi tiết cảnh báo riêng**: hoàn thiện ở Việc 6.
- **Tài khoản / đồng bộ kho gia đình**: giai đoạn sau.

## Quyết định đã chốt (25/11/2026)
1. **Thử OCR trên máy thật trước:** Chạy thử `google_mlkit_text_recognition` on-device trên Galaxy S24 Ultra với 5–10 ảnh nhãn thật trước khi chốt `SupplementLabelParser` (Windows/test dùng `FakeOcrEngine`).
2. **Mã vạch (Phương án A):** Quét mã vạch đối chiếu sản phẩm đã lưu trong máy (`productByBarcode`) để mở nhanh / thêm hộp mới; chưa có thì chuyển sang chụp nhãn OCR, giữ app 100% offline ở Việc 5.
3. **Migration `schema_version = 2`:** Thêm cột `barcode TEXT` vào bảng `products` kèm test migrate `v1 -> v2`.
4. **Lưu tệp ảnh nhãn (`Ảnh nhãn ›`):** Để ngoài phạm vi Việc 5.

## Bổ sung 1: An toàn khi AI đọc nhãn (PR 1)

Trạng thái phần này: Đã duyệt 28/11/2026 (quyết định ở B1.10). Thiết kế UX đi kèm: mục "Bổ sung 1" trong [docs/design/label-scan-inventory.md](../design/label-scan-inventory.md). Thứ tự làm: PR 1 trong [docs/refactor-plan.md](../refactor-plan.md), mục 5 (ngay sau PR 0a).

### B1.1. Mục tiêu

1. Không còn chỗ nào tự đoán đơn vị. Dòng có đơn vị không đọc được thì để trống, người dùng chọn theo nhãn rồi mới xác nhận được.
2. Số do AI trên máy gợi ý được đối chiếu với chữ đọc từ ảnh. Dòng chưa khớp phải kiểm riêng từng dòng, không xác nhận hàng loạt được. Chất mà AI bỏ sót nhưng bộ đọc chữ thấy thì vẫn hiện.
3. Quét nhãn không chờ tải mô hình AI. Máy chưa có sẵn mô hình thì dùng ngay bộ đọc chữ.

### B1.2. Vì sao (lỗi đang chạy trên máy)

- **AI trả đơn vị lạ hoặc thiếu đơn vị thì app ghi `mg`** ([supplement_label_parser.dart:427](../../app/lib/state/supplement_label_parser.dart#L427), [:436](../../app/lib/state/supplement_label_parser.dart#L436)). Code chỉ so ký tự micro `µ` (U+00B5); nếu AI trả `μg` với chữ mu Hy Lạp (U+03BC) thì `25 μg` vitamin D thành `25 mg`, gấp 1.000 lần. Ngược lại, AI bỏ trống đơn vị của `1 g` vitamin C thì thành `1 mg`, thiếu 1.000 lần, và cảnh báo vượt giới hạn có thể không hiện.
- **Không có bước so số AI với chữ trên ảnh.** AI có thể đọc sai số hoặc gán số của chất này cho chất khác. Người dùng vẫn phải xác nhận, nhưng nút `Chọn tất cả` cho xác nhận mọi dòng trong một chạm.
- **AI bỏ sót một chất thì chất đó mất hẳn**, vì khi AI trả kết quả, app không dùng kết quả của bộ đọc chữ ([supplements_screen.dart:620-625](../../app/lib/ui/supplements_screen.dart#L620-L625)). Bỏ sót một chất có giới hạn an toàn là tính thiếu.
- **Thư viện nhãn DSLD:** trong 260.626 dòng nhóm vitamin, khoáng chất, 14.624 dòng có đơn vị app chưa đọc được (đếm trên `dsld_library.db` bản 16/01/2026). Hiện app lấy đơn vị chuẩn của chất ([dsld_ingredient_mapper.dart:117](../../app/lib/state/dsld_ingredient_mapper.dart#L117)). Ví dụ có trong thư viện:
  - `Folate 1.7 mg DFE` thành 1,7 µg DFE (thiếu 1.000 lần);
  - `Vitamin D3 5000 UI` thành 5.000 µg (gấp 40 lần);
  - `Vitamin C 25 %` (phần trăm giá trị hằng ngày, không phải lượng) thành 25 mg;
  - còn có `mg RAE` (6 dòng), `ng` (18), `gm` (3), `IU mg` (9); 14.063 dòng không ghi đơn vị, trong đó 104 dòng có lượng.
- **Tải mô hình giữa luồng quét:** máy chưa có Gemini Nano thì Kotlin gọi `download()` và bắt người dùng chờ tới 25 giây ([LabelGenAiExtractor.kt:50-63](../../app/android/app/src/main/kotlin/vn/wholewell/app/LabelGenAiExtractor.kt#L50-L63)), tải bằng mạng của người dùng mà không hỏi.

### B1.3. Ràng buộc

- Giữ mọi ràng buộc của phần gốc. AI chỉ gợi ý; người dùng xác nhận từng dòng; engine quyết định mọi số và cảnh báo.
- **Không đoán đơn vị ở bất kỳ đâu.** Đơn vị chỉ đến từ chữ trên nhãn (OCR, AI, DSLD) khớp một danh sách cố định, hoặc do người dùng chọn.
- Không đổi số người dùng đã nhập. Không đổi engine, lược đồ CSDL. Gói dữ liệu chỉ thêm nguồn và quy tắc của B1.8.
- Không đổi hành vi với dữ liệu hợp lệ: nhãn đọc được đủ đơn vị và AI khớp chữ trên ảnh thì kết quả như hiện nay.

### B1.4. Phạm vi: 7 chỗ đang đoán đơn vị

Handoff liệt kê 6 chỗ; khi rà code thấy thêm chỗ số 5 (bảng sửa dòng tự đổi đơn vị). **Đề xuất sửa cả 7**, theo hai cách:

- Chỗ mà dữ liệu thật có tới (số 1, 2, 3, 5): đơn vị để trống, người dùng chọn.
- Chỗ chỉ có tới khi dữ liệu đã lưu bị hỏng (số 4, 6, 7, vì mọi chỗ ghi đều dùng hàm đổi đủ mọi đơn vị): báo lỗi rõ thay cho đoán, kèm test khứ hồi bảo đảm không xảy ra.

| # | Chỗ | Đang làm | Dữ liệu thật có tới? | Sửa |
|---|---|---|---|---|
| 1 | [supplement_label_parser.dart:427](../../app/lib/state/supplement_label_parser.dart#L427), [:436](../../app/lib/state/supplement_label_parser.dart#L436) (đọc JSON của AI) | Thiếu hoặc lạ thì `mg` | Có | Đọc qua `LabelUnitText.parse` (B1.5); không khớp thì đơn vị trống |
| 2 | [dsld_ingredient_mapper.dart:117](../../app/lib/state/dsld_ingredient_mapper.dart#L117), [:144](../../app/lib/state/dsld_ingredient_mapper.dart#L144) | Lạ thì lấy đơn vị chuẩn của chất; chất ngoài gói thì `mg` | Có (14.624 dòng) | Đọc qua `LabelUnitText.parse`; không khớp thì đơn vị trống. Đơn vị `%` thì bỏ cả lượng (lượng trống), vì đó là phần trăm giá trị hằng ngày |
| 3 | [confirm_ingredients_screen.dart:41](../../app/lib/ui/confirm_ingredients_screen.dart#L41), [:68](../../app/lib/ui/confirm_ingredients_screen.dart#L68) (`fromParsed`) | Bộ đọc chữ không ra đơn vị thì lấy đơn vị chuẩn hoặc `mg` | Có (vd. `mcgdfe` viết liền) | Giữ đơn vị trống. Bộ đọc chữ bỏ khoảng trắng trước khi so (`mcgdfe`, `mgne` đọc được) và nhận thêm `μg` (U+03BC) |
| 4 | [confirm_ingredients_screen.dart:54](../../app/lib/ui/confirm_ingredients_screen.dart#L54) (`fromSaved`) | Tên đơn vị đã lưu không đọc được thì `mg` | Không: mọi chỗ ghi dùng `LabelUnit.name` | Đơn vị trống và bỏ dấu đã xác nhận của dòng đó; người dùng chọn lại khi sửa thành phần |
| 5 | [confirm_ingredients_screen.dart:28](../../app/lib/ui/confirm_ingredients_screen.dart#L28), [:470](../../app/lib/ui/confirm_ingredients_screen.dart#L470), [:516](../../app/lib/ui/confirm_ingredients_screen.dart#L516) (dòng mới, bảng sửa dòng) | Dòng mới mặc định `mg`; đơn vị không hợp với chất thì lặng lẽ đổi sang đơn vị đầu danh sách | Có | Dòng mới và khi đổi chất mà đơn vị không hợp: đơn vị trống tới khi người dùng chọn |
| 6 | [add_supplement_screen.dart:168](../../app/lib/ui/add_supplement_screen.dart#L168) (`Ghi một lần`) | Đơn vị chuẩn trong gói lạ thì `mg` | Không: mọi chất (trừ đa lượng) có đơn vị trong danh sách | Gộp 3 bản sao `_stdLabelUnit`/`_defaultUnitFor` thành `SupplementIngredientHelper.labelUnitForPackUnit` trả `null` khi lạ; chất trả `null` không hiện trong danh sách chọn |
| 7 | [label_food_builder.dart:181](../../app/lib/state/label_food_builder.dart#L181) (`unitFromWire`, món đã lưu) | Lạ thì `mg` | Không: chỉ ghi qua `unitWireName` | Trả `null`; `entryFromCustomFood` ném `FormatException`; màn chọn khẩu phần báo lỗi, ghi món trả `failed` |

### B1.5. Thiết kế kỹ thuật

**Đọc đơn vị một chỗ (`LabelUnitText`, trong `app/lib/state/`)**

- `LabelUnitText.parse(String? raw) → LabelUnit?` dùng chung cho JSON của AI và DSLD. Chuẩn hóa: chữ thường, bỏ khoảng trắng và `_` hai đầu, gộp khoảng trắng và `_` giữa chữ thành một dấu cách.
- Danh sách cố định (chỉ những cách viết không thể hiểu khác):

| `LabelUnit` | Chữ nhận |
|---|---|
| `mg` | `mg`, `milligram`, `milligrams` |
| `ug` | `ug`, `mcg`, `µg` (U+00B5), `μg` (U+03BC), `microgram`, `micrograms` |
| `g` | `g`, `gram`, `grams`, `gram(s)` |
| `iu` | `iu`, `international unit`, `international units` |
| `ugDfe` | `ug dfe`, `mcg dfe`, `µg dfe`, `μg dfe` |
| `ugRae` | `ug rae`, `mcg rae`, `µg rae`, `μg rae` |
| `mgNe` | `mg ne` |

- Không nhận thêm: `UI`, `gm`, `mgs`, `ng`, `RE`, `alpha-TE`, `mg DFE`, `mg RAE`. Các chữ này hoặc là đơn vị engine không đổi được, hoặc trong DSLD thấy dùng sai (vd. `Magnesium 190 gm`), nên để người dùng chọn theo nhãn.
- Bộ đọc chữ OCR giữ bảng riêng (có các lỗi nhận nhầm như `mq`, `meg`, `1u`), chỉ sửa hai điểm ở dòng 3 của bảng B1.4.
- `SupplementIngredientHelper.labelUnitForPackUnit(String packUnit) → LabelUnit?`: `g`, `mg`, `ug`, `ug_RAE`, `ug_DFE`, `mg_NE`; còn lại `null`.

**Dữ liệu trong bộ nhớ (không đổi CSDL)**

- `ParsedIngredientLine`: thêm `needsCheck` (mặc định `false`), chỉ bật cho dòng AI chưa khớp chữ trên ảnh.
- `ParsedLabelPackage`: thêm `fromOnDeviceAi`.
- `EditableIngredient`: `labelUnit` đổi thành `LabelUnit?` (mặc định `null`); thêm `needsCheck`.
- `SupplementIngredientHelper.isUnitCompatible`, `checkSanity` nhận `LabelUnit?`. Với dòng có chất trong gói, đơn vị `null` coi là chưa dùng được. `toDraft` chỉ được gọi khi mọi dòng đủ lượng và đơn vị (đã có điều kiện xác nhận chặn).
- Chỉ dòng đã xác nhận mới được lưu, nên CSDL không bao giờ có dòng mang `needsCheck` hay đơn vị trống. Không đổi lược đồ; `ingredients.origin` vẫn là `ocr` cho dòng từ AI.

**Đối chiếu dòng AI với chữ đọc từ ảnh**

Luồng ở `_analyzeImages` ([supplements_screen.dart:603](../../app/lib/ui/supplements_screen.dart#L603)):

1. OCR ra các dòng chữ.
2. **Luôn chạy bộ đọc chữ:** `parsed = parsePackage(lines)`.
3. Gọi AI. AI không chạy hoặc JSON lỗi thì dùng `parsed` như hiện nay.
4. Có kết quả AI thì `SupplementLabelParser.crossCheckAi(ai, parsed, lines)`:
   - **Mảnh số trên ảnh:** mọi cặp (số, đơn vị) mà `_amountUnitRe` bắt được trong các đoạn của `_splitSegments(lines)`, đọc số bằng `_parseNumber` (nên `1,000`, `1.000`, `1000` là một số; `2,5` là 2,5).
   - Hai số bằng nhau khi lệch không quá `1e-9 × max(1, |số|)`. Hai đơn vị phải là cùng một `LabelUnit` (`ug` khác `ugDfe`).
   - **Dòng AI khớp** khi cả ba điều kiện sau đúng (sửa theo review PR 1):
     - có mảnh số trên ảnh bằng đúng số và đơn vị của dòng;
     - nếu bộ đọc chữ có dòng mang đúng số và đơn vị đó thì ít nhất một dòng như vậy cùng chất với dòng AI. Số nằm trên dòng tên tự do (vd. `Coenzyme Q10 100 mg`) coi là đã thuộc dòng khác. Điều kiện này bắt trường hợp AI gán số của chất này cho chất khác;
     - bộ đọc chữ không đọc cùng chất đó với số khác, trừ khi nhãn ghi cùng chất bằng đơn vị khác trên cùng dòng (vd. `Vitamin D3 25 mcg (1,000 IU)`, xem 21 CFR 101.36(b)(2)(ii)(B)). Điều kiện này bắt trường hợp AI lấy nhầm số của chất khác hay khối lượng nguồn trong ngoặc.
   - Dòng AI không khớp thì `needsCheck = true`. Dòng AI có đơn vị trống thì không khớp được, và đã phải chọn đơn vị.
   - **Chất AI bỏ sót:** dòng của bộ đọc chữ có chất trong gói mà không dòng AI nào cùng chất thì thêm vào cuối danh sách, như khi chỉ dùng bộ đọc chữ. Dòng chất ngoài gói của bộ đọc chữ chỉ bỏ khi đã có dòng AI chất ngoài gói khớp ảnh mang cùng số và đơn vị. So theo chất, không theo số, để nhãn ghi `25 mcg (1,000 IU)` không ra hai dòng vitamin D.
   - Tên sản phẩm, số viên, khẩu phần: lấy của AI như hiện nay; AI không có thì lấy của bộ đọc chữ.
5. Mở màn Xác nhận thành phần.

**Xác nhận dòng**

- Một dòng **cần kiểm** khi: chưa có lượng, đơn vị trống, đơn vị không hợp với chất (đã có), hoặc `needsCheck`.
- Ô đánh dấu của dòng cần kiểm bị khóa. Người dùng bấm `Sửa`, xem số và đơn vị, rồi bấm `Xác nhận dòng này`; bảng sửa trả dòng đã xác nhận và tắt `needsCheck`, như hiện nay.
- `Chọn tất cả` (OCR, AI) và `Xác nhận tất cả` (DSLD) chỉ hiện khi không còn dòng cần kiểm. Đây là điều kiện hiện có (`_allUnitCompatible`) mở rộng thêm.
- Bảng sửa dòng: chưa chọn đơn vị thì `Xác nhận dòng này` báo `Chọn đơn vị theo nhãn.`, không đóng bảng.

**Không tải mô hình giữa luồng quét (Kotlin)**

- `LabelGenAiExtractor` chỉ gọi mô hình khi `checkStatus()` trả `AVAILABLE`. Mọi trạng thái khác (`DOWNLOADABLE`, `DOWNLOADING`, `UNAVAILABLE`) trả `null` ngay để Flutter dùng bộ đọc chữ. Bỏ lời gọi `download()` và lần chờ 25 giây.
- Tách luật thành hàm thuần `LabelGenAiRules.shouldRun(status: Int): Boolean`, có test JVM như `DbKeyRules` (CI đã chạy `:app:testDebugUnitTest`).
- Giữ giới hạn 20 giây cho bước tạo kết quả.
- Sửa lời nhắc gửi mô hình (chạy trên máy): "chép số đúng như in trên nhãn, không đổi đơn vị; `unit` để `null` nếu nhãn không ghi hoặc không thuộc danh sách". Lời nhắc chỉ giúp AI ít sai hơn; an toàn vẫn dựa vào bước đối chiếu ở trên.
- PR này không tự tải mô hình ở chỗ nào khác (xem Câu hỏi B1.10, số 2).

**Món đã lưu có đơn vị không đọc được (chỗ số 7)**

- `FoodPortionScreen` bắt `FormatException` khi dựng tóm tắt, hiện `ErrorState` và khóa nút `Lưu`.
- `DiaryController.recordCustomFood` bắt lỗi này, trả `FoodLogFeedback(failed: true)` như các lỗi ghi khác.

### B1.6. Lỗi và biên

- AI trả JSON không hợp lệ, rỗng, hay `amount` không phải số: dùng kết quả bộ đọc chữ (như hiện nay).
- AI trả dòng có số nhưng không có tên: bỏ dòng (như hiện nay).
- Ảnh có hai cột cách xa nên số và đơn vị nằm ở hai hàng: bộ đọc chữ không bắt được mảnh số, dòng AI thành "cần kiểm". Đây là hướng an toàn (người dùng xem lại), không phải lỗi.
- Nhãn ghi cùng một chất hai lần với hai đơn vị (`25 mcg (1,000 IU)`): dòng AI khớp nếu số AI chọn có trên ảnh; không thêm dòng trùng chất từ bộ đọc chữ.
- Người dùng bỏ dấu một dòng đã sửa: dòng trở lại như dòng thường, không bật lại `needsCheck`.

### B1.7. Tiêu chí đạt

Mỗi dòng thành ít nhất một test (`app/test/label_ai_safety_test.dart` mới, sửa `label_scan_inventory_test.dart`, test JVM `LabelGenAiRulesTest.kt`).

- [ ] `LabelUnitText.parse`: mọi chữ trong bảng B1.5 ra đúng `LabelUnit`, kể cả viết hoa, có `_`, khoảng trắng thừa; `null`, chuỗi rỗng, `UI`, `gm`, `ng`, `%`, `mg DFE`, `mg/day` ra `null`. Không chữ nào ra `mg` nếu không phải `mg`/`milligram(s)`.
- [ ] `parseAiJson`: thiếu `unit` hoặc `unit` lạ thì dòng có đơn vị trống; `μg` (U+03BC) và `mcg` ra `ug`.
- [ ] Bộ đọc chữ: `Folate 667 mcgDFE` ra `ugDfe`; `Vitamin D 25 μg` ra `ug`; các test hiện có giữ nguyên kết quả.
- [ ] `crossCheckAi`:
  - số và đơn vị có trên ảnh thì khớp, với `1,000` / `1.000` / `1000` và `2,5`;
  - lệch số, lệch đơn vị (`ug` so với `ugDfe`), hay đơn vị trống thì `needsCheck`;
  - AI đổi số của B2 (10 mg) và B6 (5 mg) cho nhau thì cả hai dòng `needsCheck`;
  - AI bỏ sót vitamin A mà bộ đọc chữ thấy thì dòng vitamin A được thêm;
  - nhãn `Vitamin D3 25 mcg (1,000 IU)`, AI trả `1000 IU`: một dòng vitamin D, khớp.
- [ ] DSLD: `mcg` ra `ug`; `mg DFE`, `UI`, `gm`, chuỗi rỗng ra đơn vị trống; `%` ra lượng trống và đơn vị trống. Sản phẩm có dòng như vậy thì không hiện `Xác nhận tất cả`.
- [ ] `EditableIngredient`: `fromParsed` giữ đơn vị trống; `fromSaved` với tên đơn vị lạ cho đơn vị trống và `confirmed = false`; dòng mới có đơn vị trống.
- [ ] Màn Xác nhận thành phần (widget test):
  - dòng đơn vị trống, dòng chưa có lượng, dòng `needsCheck` có ô đánh dấu bị khóa và hiện đúng lời nhắc;
  - còn dòng cần kiểm thì không hiện `Chọn tất cả` / `Xác nhận tất cả`, nút `Tiếp tục` khóa;
  - sửa dòng `needsCheck` qua bảng sửa thì dòng được xác nhận;
  - bảng sửa không đóng khi chưa chọn đơn vị và hiện `Chọn đơn vị theo nhãn.`;
  - đổi chất sang chất mà đơn vị cũ không hợp thì đơn vị trống, không tự chọn;
  - có dòng từ AI thì hiện dòng ghi chú AI ở đầu màn.
- [ ] `labelUnitForPackUnit`: mọi chất trong gói (trừ nhóm đa lượng) ra đơn vị khác `null`; `L` và chuỗi lạ ra `null`.
- [ ] `unitWireName` rồi `unitFromWire` trả lại đúng mọi `LabelUnit`; chữ lạ ra `null`; `entryFromCustomFood` ném `FormatException`; `FoodPortionScreen` hiện `ErrorState` thay vì lỗi đỏ.
- [ ] `LabelGenAiRules.shouldRun`: chỉ `AVAILABLE` ra `true`.
- [ ] Test kiểm toán quét `app/lib`, cấm `_ => LabelUnit.mg`, `?? LabelUnit.mg` và `?? 'mg'`, danh sách ngoại lệ rỗng. Chỗ hiển thị `def?.unit ?? 'mg'` ([confirm_ingredients_screen.dart:316](../../app/lib/ui/confirm_ingredients_screen.dart#L316)) chỉ là chữ và `def` luôn có ở đó, nên đổi luôn để không cần ngoại lệ.
- [ ] Thử trên S24 Ultra với 5 nhãn thật: ghi lại số dòng AI khớp và cần kiểm cho từng nhãn; tắt mạng, máy chưa có mô hình thì đọc nhãn không chờ.
- [ ] CI xanh, `flutter analyze` sạch.

### B1.8. Lượng ghi trên bảng Supplement Facts là lượng nguyên tố (làm trong PR 1)

**Phát hiện khi rà code.** Bộ đọc chữ và AI coi `Calcium (as calcium carbonate) 500 mg` là 500 mg hợp chất, tính 200 mg canxi. Test hiện có khóa cách hiểu này ([label_scan_inventory_test.dart:19](../../app/test/label_scan_inventory_test.dart#L19), [:30](../../app/test/label_scan_inventory_test.dart#L30)). App đang:

- tính thiếu 60% với canxi carbonat, 79% với canxi citrat;
- tính thiếu 67–88% với sắt fumarat, sulfat, gluconat.

Đây là chiều không an toàn cho giới hạn. Ví dụ `Iron (as ferrous gluconate) 27 mg` được tính 3,2 mg sắt. Chủ dự án xác nhận ngày 28/11/2026: `Calcium (as calcium carbonate) 500 mg` là 500 mg canxi nguyên tố.

**Nguồn (nhãn A):** 21 CFR 101.36, quy định nhãn thực phẩm bổ sung của FDA.

- (b)(2)(ii), nguyên văn: "The quantitative amounts by weight shall represent the weight of the dietary ingredient rather than the weight of the source of the dietary ingredient (e.g., the weight of calcium rather than that of calcium carbonate)."
- (d): tên nguồn có thể ghi trong ngoặc, sau chữ "as" hoặc "from", ví dụ "Calcium (as calcium carbonate)".
- Đối chiếu nguyên văn ngày 28/11/2026 bằng Claude in Chrome qua API chính thức của eCFR (`api/versioner/v1/full/2026-11-20/title-21.xml?part=101&section=101.36`), vì trang eCFR cho người đọc đòi CAPTCHA. Bản hiện hành: sửa đổi gần nhất 83 FR 65502 (21/12/2018). Mục 101.36 nằm ở subpart C.
- (b)(2)(ii)(B) còn ghi lượng vitamin D tính bằng IU, nếu có, nằm trong ngoặc sau lượng tính bằng mcg: đây là căn cứ để coi `25 mcg (1,000 IU)` là một chất ghi hai đơn vị.

**Quy tắc** (chỉ cho chất có hợp chất trong gói, hiện là canxi và sắt):

| Cách ghi trên nhãn | Ví dụ | Hiểu là |
|---|---|---|
| Tên chất rồi `(as …)`, `(from …)`, `as …` | `Calcium (as calcium carbonate) 500 mg` | Lượng nguyên tố, giữ dạng hợp chất (quy tắc lịch "uống canxi carbonat cùng bữa ăn" lọc theo dạng) |
| Bắt đầu bằng tên hợp chất, không có tên chất đứng riêng trước | `Calcium carbonate 1250 mg`, `Canxi carbonat 1250mg` | Khối lượng hợp chất (như hiện nay) |
| Có cả tên chất và tên hợp chất nhưng không rõ cách ghi | `Iron (ferrous fumarate) 100 mg`, `Canxi (canxi carbonat) 500mg` | Chưa rõ dạng: giới hạn tính cả con số, so mức khuyến nghị lấy số nhỏ nhất, ghi "chưa chắc" (quy tắc có sẵn của app) |

- **Dòng AI:** dòng khớp chữ trên ảnh thì xét theo đoạn chữ đó trên ảnh. Dòng không khớp mà AI ghi hợp chất (trong `name` hoặc `form`) và không ghi `elemental: true` thì coi là chưa rõ dạng.
- **Khối lượng nguồn trong ngoặc:** `Calcium 500 mg (as calcium carbonate 1250 mg)`: số trong ngoặc là khối lượng nguồn của cùng chất trên cùng dòng nhãn, không thành thêm một dòng canxi; dòng 500 mg lấy dạng `calcium_carbonate`.
- **Dữ liệu có nguồn:** thêm nguồn `fda_21cfr_101_36` vào `SOURCES` và mục `supplementFactsElemental` (`source`, `quote`, `accessedDate`, các chữ đánh dấu `as`/`from`) vào `build_pack.py`, kèm ô kiểm ở `verify_pack.py`. Như vậy quy tắc là dữ liệu có nguồn, đúng `AGENTS.md`.
- **Biểu diễn:** lượng nguyên tố là `isCompound = false`, `form` giữ dạng ghi trong `(as …)` (vd. `calcium_carbonate`; engine bỏ qua dạng khi tính lượng nguyên tố); chưa rõ dạng là `isCompound = true`, `form = unknown` (như khi người dùng chọn `Chưa rõ dạng` trong bảng sửa dòng). Không đổi engine.
- **Hệ quả:** đổi kết quả với nhãn Mỹ có `(as …)` (số tính vào giới hạn tăng) và với dòng như `Iron (ferrous fumarate) 100 mg`. Phải sửa test ở [label_scan_inventory_test.dart:15-38](../../app/test/label_scan_inventory_test.dart#L15-L38), và ghi rõ trong mô tả PR.

### B1.9. Ngoài phạm vi

- Nhập tay nhãn thực phẩm ([label_food_screen.dart:41](../../app/lib/ui/label_food_screen.dart#L41)): giữ đơn vị chọn sẵn theo chất. Bảng Nutrition Facts ghi mỗi chất một đơn vị cố định, và người dùng thấy đơn vị trên ô nhập; đây không phải đoán từ dữ liệu.
- Tự tải Gemini Nano, hay cài đặt bật/tắt AI.
- Đổi lược đồ CSDL; thêm `origin = 'ai'`.
- Đơn vị `RE`, `alpha-TE` (engine chưa đổi được): người dùng chọn đơn vị khác theo nhãn hoặc nhập theo số đã đổi.

### B1.10. Quyết định đã chốt (28/11/2026)

1. Mục B1.8 làm trong PR 1. Chủ dự án xác nhận `Calcium (as calcium carbonate) 500 mg` là 500 mg canxi nguyên tố.
2. Không tự tải mô hình AI ở chỗ nào. Nếu sau này muốn thì làm đặc tả riêng, có hỏi người dùng trước khi tải.
3. Sửa cả 7 chỗ ở B1.4.
