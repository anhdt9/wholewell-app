# Đặc tả: Chụp nhãn, mã vạch, kho, hạn dùng

Trạng thái: Đã duyệt (25/11/2026)  <!-- Nháp | Đã duyệt -->
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
- **Không AI tạo sinh, dữ liệu ở máy:** OCR và quét mã vạch chạy hoàn toàn trên thiết bị (`on-device`), không gửi ảnh nhãn ra máy chủ. Không tự suy đoán hay tự động ghi thành phần vào CSDL khi người dùng chưa xác nhận từng dòng.
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
  - `Future<String?> captureLabelImage()` (chụp bằng camera)
  - `Future<String?> pickLabelImageFromGallery()` (chọn ảnh có sẵn)
  - `Future<OcrLabelResult> recognizeLabelFromImage(String imagePath)` (ML Kit Text Recognition v2 on-device trên Android; `FakeOcrEngine` cho Windows/test).
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
