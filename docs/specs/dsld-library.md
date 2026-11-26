# Đặc tả: Thư viện thực phẩm bổ sung NIH DSLD (mã vạch & tìm kiếm offline)

Trạng thái: Đã duyệt  <!-- Nháp | Đã duyệt -->
Thiết kế UX: [docs/design/dsld-library.md](../design/dsld-library.md)
Thứ tự MVP: Bổ sung sau Việc 5 trong [docs/status.md](../status.md)

## Mục tiêu
Cho phép người dùng quét mã vạch (hoặc tìm theo tên) các sản phẩm thực phẩm bổ sung bán tại Mỹ từ cơ sở dữ liệu mở **NIH Dietary Supplement Label Database (DSLD)** hoàn toàn offline trên máy, tự động điền bảng thành phần chuẩn hóa và khẩu phần vào màn xác nhận trước khi lưu vào tủ thuốc cá nhân.

## Người dùng và tình huống
- Người dùng mở tab **Bổ sung → Thêm sản phẩm**, đưa mã vạch UPC/EAN trên lọ thực phẩm bổ sung (hàng Mỹ như Sports Research, NOW Foods, Nature Made, Kirkland, Doctor's Best…) vào khung quét.
- Thay vì phải chụp ảnh nhãn và chỉnh sửa từng dòng OCR, app tra ra ngay tên sản phẩm, khẩu phần, đơn vị đếm và danh sách thành phần từ gói `dsld_library.db` đi kèm bản cài.

## Ràng buộc
- **Nguồn hợp pháp & miễn phí (CC0):** Chỉ dùng dữ liệu từ **NIH DSLD** (`https://dsld.od.nih.gov/`, `https://dsldapi.od.nih.gov/`, giấy phép CC0 1.0 Universal). Không dùng Open Food Facts hay nguồn cộng đồng/trả phí.
- **Đóng gói sẵn trong bản cài (`AGENTS.md`):** Dữ liệu đi kèm bản cài đã ký, chạy 100% offline, không tải ngầm từ máy chủ.
- **Kiểm soát dung lượng APK/AAB:** Lọc chỉ giữ `Market Status = On Market` có mã vạch hợp lệ (8–14 chữ số). Giữ các cột cần cho tra cứu, tính toán và tham khảo nhãn (`dsld_id`, `barcode`, `product_name`, `brand_name`, `serving_size`, `supplement_form`, `net_contents`, `suggested_use`, `other_ingredients`, và bảng `facts`); loại bỏ `LabelStatements` (tuyên bố pháp lý), `CompanyInformation` (địa chỉ công ty). Đóng gói dạng nén `app/assets/dsld_library.db.gz`, giải nén 1 lần vào bộ nhớ ứng dụng khi khởi động.
- **Tá dược (`other_ingredients`):** Chỉ hiển thị nguyên văn mục *"Thành phần khác (theo nhãn)"* để người dùng tự đọc và tham khảo; tuyệt đối **không** tự suy diễn hay gắn cảnh báo độc tính/y tế (vì không thuộc chuẩn NASEM/UL).
- **An toàn & xác nhận:** Mọi thành phần nạp từ DSLD vẫn đi qua `UnitConverter.convertIntakeLine`, kiểm tra hợp lý (`checkIngredientSanity`) và màn **Xác nhận thành phần** để người dùng kiểm tra trước khi lưu (không tự động lưu mù vào kho).

## Nguồn
- **NIH Office of Dietary Supplements — Dietary Supplement Label Database (DSLD):**
  - Trang chủ & Bulk Download (JSON/CSV): `https://dsld.od.nih.gov/`
  - REST API tham chiếu: `https://dsldapi.od.nih.gov/`
  - Giấy phép: CC0 1.0 Universal (Public Domain).

## Thiết kế kỹ thuật

### 1. Bộ dựng gói Python (`tools/build_dsld.py`)
- Tải và đọc bản bulk JSON/CSV chính thức từ NIH DSLD (lưu cache cục bộ ngoài git hoặc trong thư mục tạm khi build).
- Chuẩn hóa mã vạch (`upc`/`barcode`): bỏ khoảng trắng, gạch ngang, chuẩn hóa cả dạng 12 số (UPC-A) và 13 số (EAN-13 thêm `0` đầu) để quét mã nào cũng khớp.
- Ánh xạ tên chất DSLD → `nutrient_id` của `reference_pack.json` (tái sử dụng từ điển ánh xạ chuẩn, tách `Vitamin A` / `beta-caroten` / `retinol`, `Folate` µg DFE vs `Folic Acid` µg, `Vitamin E` d-alpha vs dl-alpha, hợp chất canxi/sắt). Chất không có trong gói giữ `free_name`.
- Xuất `app/assets/dsld_library.db.gz` (nén gzip từ SQLite chỉ đọc có index trên `barcode`, `facts(dsld_id)` và `FTS5` trên `product_name`, `brand_name`) và `app/assets/dsld_library_manifest.json` (chứa `sha256` bản nén và bản giải nén, số lượng sản phẩm, ngày dữ liệu DSLD).
- Theo khảo sát thực tế bản CSV ngày 16/01/2026: `94.612` sản phẩm `On Market` có mã vạch 8–14 số, `819.817` dòng thành phần, `88.160` dòng `other_ingredients` → file SQLite chưa nén `107,68 MB`.

### 2. Gói Dart `packages/dsld_library`
- Tương tự `packages/food_library`: kiểm tra `SHA-256` từ `dsld_library_manifest.json` trước khi mở chỉ đọc (`OpenMode.readOnly`).
- API chính:
  - `Future<DsldProduct?> findByBarcode(String barcode)` (tra cả `barcode`, `0 + barcode`, hoặc bỏ `0` đầu nếu dài 13 ký tự).
  - `Future<List<DsldProductSummary>> searchByName(String query, {int limit = 30})`.
  - `Future<DsldProductDetail?> getDetail(int dsldId)`.

### 3. Luồng tra cứu trong `app/`
- Tại `ScanProductScreen`:
  1. Quét mã vạch → kiểm `diary.findProductByBarcode(code)` (sản phẩm đã lưu trong máy) → nếu có, mở thẳng `ProductDetailScreen`.
  2. Nếu chưa có trong máy → kiểm `dsldLibrary?.findByBarcode(code)` → nếu tìm thấy, chuyển sang `ConfirmIngredientsScreen` điền sẵn đầy đủ thành phần, tên sản phẩm, đơn vị đếm, `unitsPerServing`, `barcode` (và nút `[Xác nhận tất cả]` để duyệt nhanh trong 1 chạm).
  3. Nếu chưa có trong DSLD → tiếp tục chụp ảnh nhãn (Document Scanner + OCR) hoặc nhập tay như hiện tại.

### 4. Lỗi và biên
- Tệp `dsld_library.db` hỏng / sai SHA-256: báo trạng thái nhẹ không mở thư viện DSLD, app vẫn chạy bình thường với OCR và nhập tay (không crash).
- Mã vạch có nhiều phiên bản/lô `On Market` trên DSLD (cùng UPC): cho chọn phiên bản trên sheet (toàn bộ `dsld_library.db.gz` chỉ chứa `On Market`, loại bỏ hoàn toàn `Off Market`).
- Sản phẩm DSLD có chất không rõ dạng (`vitE`, `calcium` dạng chưa rõ...): giữ `form = unknown` để engine tính thận trọng và đánh dấu trên màn xác nhận.

## Tiêu chí đạt
- [ ] `tools/build_dsld.py` dựng được `dsld_library.db` + `dsld_library_manifest.json` từ dữ liệu bulk NIH DSLD thật, kèm script kiểm tra mẫu ngẫu nhiên.
- [ ] `packages/dsld_library` kiểm `SHA-256`, tra cứu `findByBarcode` (UPC-A 12 số & EAN-13 13 số) và `searchByName`, có unit test pass.
- [ ] `ScanProductScreen` tra tuần tự: máy → DSLD → OCR → nhập tay, có widget test với `FakeDsldLibrary` / DB mẫu nhỏ.
- [ ] Toàn bộ CI (`dart analyze/test`, `flutter analyze/test`) pass và dung lượng APK nằm trong giới hạn hợp lý.

## Ngoài phạm vi
- **Gọi API mạng `dsldapi.od.nih.gov` lúc chạy app:** App giữ 100% offline ở MVP (nếu muốn tra API online khi không có trong gói sẽ bàn riêng).
- **Hàng Úc / Nhật / Việt Nam không có trong DSLD:** Vẫn dùng OCR + nhập tay (hoặc bổ sung bảng riêng ở bước sau).

## Quyết định đã chốt (26/11/2026)
1. **Phạm vi lọc dữ liệu (Phương án B):** Chỉ giữ các sản phẩm **`onMarket = true` có mã vạch hợp lệ (8–14 chữ số)** (`94.612` sản phẩm, `819.817` dòng thành phần từ bản CSV ngày 16/01/2026).
2. **Giữ `other_ingredients`:** Giữ cột `other_ingredients` (`+9,35 MB` chưa nén) để hiển thị nguyên văn *"Thành phần khác (theo nhãn)"*, không gắn cảnh báo y tế.
3. **Nén gói tài sản:** Đóng gói `app/assets/dsld_library.db.gz` và giải nén 1 lần sang thư mục dữ liệu ứng dụng khi mở lần đầu.
4. **Thứ tự Git:** PR #17 đã gộp vào `main`; triển khai trên nhánh mới `feat/dsld-library`.
