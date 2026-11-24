# Đặc tả: CSDL mã hóa trên máy

Trạng thái: Nháp  <!-- Nháp | Đã duyệt -->
Thiết kế UX: không có màn riêng (hạ tầng). Các màn dùng dữ liệu theo [design/mvp-overview.md](../design/mvp-overview.md); trạng thái lỗi CSDL ở mục Trạng thái, dòng "Toàn app".
Thứ tự MVP: việc 1 trong [status.md](../status.md)

## Mục tiêu

Lưu mọi dữ liệu người dùng trên máy trong một CSDL mã hóa, thay `InMemoryJournalRepository`, để dữ liệu còn sau khi tắt app và làm nền cho kho, lịch uống, sao lưu.

## Người dùng và tình huống

- Người dùng không thấy CSDL. Họ chỉ thấy dữ liệu còn nguyên khi mở lại app, và thấy màn lỗi khi không mở được.
- Android trước (MVP); iOS dùng cùng thiết kế, khác cách giữ khóa.

## Ràng buộc

- Quy tắc trong AGENTS.md: dữ liệu chỉ ở máy, không máy chủ, không SDK phân tích hay báo lỗi.
- **Chưa đồng ý thì không ghi gì xuống đĩa** (thiết kế, luồng Lần đầu): câu trả lời màn Điều kiện chỉ ở bộ nhớ; CSDL và khóa chỉ được tạo sau khi đồng ý.
- **Khóa chỉ dùng được khi máy đã mở khóa** (chốt 24/11/2026). Nút "Đã uống" trên thông báo mở app, không ghi trong nền.
- **Loại khỏi sao lưu tự động của hệ điều hành** và chuyển dữ liệu giữa máy; sao lưu chỉ qua tính năng Sao lưu của app.
- Chỉ lưu câu trả lời Có/Không về thuốc, bệnh; không lưu tên bệnh, tên thuốc.
- Không lưu dữ liệu sức khỏe ngoài CSDL: cài đặt giao diện, dấu "cần xóa bản trên Drive", nội dung lưu kèm lịch nhắc (chỉ mã lần uống) không chứa dữ liệu sức khỏe.

## Nguồn

Đặc tả này không thêm con số hay quy tắc dinh dưỡng. Tài liệu kỹ thuật (kiểm lại phiên bản khi làm):

- drift, mã hóa: <https://drift.simonbinder.eu/platforms/encryption/>
- SQLite3MultipleCiphers: <https://utelle.github.io/SQLite3MultipleCiphers/>
- Android, loại khỏi sao lưu: <https://developer.android.com/identity/data/autobackup>
- Android Keystore, `setUnlockedDeviceRequired` (API 28+): <https://developer.android.com/reference/android/security/keystore/KeyGenParameterSpec.Builder#setUnlockedDeviceRequired(boolean)>
- iOS Keychain, `kSecAttrAccessibleWhenUnlockedThisDeviceOnly`: <https://developer.apple.com/documentation/security/ksecattraccessiblewhenunlockedthisdeviceonly>

## Thiết kế kỹ thuật

### Mã hóa và khóa

- CSDL: drift trên bản SQLite có SQLite3MultipleCiphers, thuật toán mặc định của thư viện. Mở bằng `PRAGMA key` ngay sau khi mở tệp, trước mọi truy vấn.
- Khóa CSDL: 32 byte ngẫu nhiên từ `Random.secure()`, tạo một lần sau khi đồng ý.
- Giữ khóa qua interface `SecureKeyStore` (có bản giả để test):
  - Android: khóa CSDL được mã hóa bằng một khóa AES trong Android Keystore tạo với `setUnlockedDeviceRequired(true)`; bản đã mã hóa lưu trong vùng riêng của app. flutter_secure_storage không có tùy chọn này nên viết phần native nhỏ.
  - iOS: Keychain với `kSecAttrAccessibleWhenUnlockedThisDeviceOnly` (không đồng bộ iCloud Keychain).
- Khóa không bao giờ ghi ra log, tệp xuất hay bản sao lưu. Bản sao lưu của app dùng khóa riêng do người dùng giữ (đặc tả Sao lưu).

### Vị trí tệp và loại khỏi sao lưu

- Tệp `wholewell.db` (kèm `-wal`, `-shm`) trong thư mục dữ liệu riêng của app.
- Android: `android:allowBackup="false"`, thêm `dataExtractionRules` (Android 12+) loại mọi dữ liệu khỏi sao lưu đám mây và chuyển máy.
- iOS: đặt `isExcludedFromBackup` cho thư mục chứa CSDL.

### Lược đồ v1

Thời điểm lưu dạng UTC kèm độ lệch múi giờ lúc ghi; cột `day` (YYYY-MM-DD theo giờ địa phương lúc uống, ăn) để truy vấn theo ngày, có chỉ mục. Lượng chất theo đơn vị chuẩn của gói dữ liệu.

| Bảng | Trường chính | Ghi chú |
|---|---|---|
| `meta` | schema_version, created_at | |
| `consents` | id, kind (`health_data`, `notifications`, `drive`), content_version, granted_at, withdrawn_at | Bằng chứng đồng ý |
| `profile` | age_years, age_entered_on, sex, height_cm, weight_kg, activity_level, caution (Có/Không), caution_answered_on, updated_at | Một dòng. Không có trường thai kỳ (giai đoạn 2 thêm bằng di chuyển lược đồ) |
| `settings` | hide_calories, show_tip_card, theme, wake, breakfast, lunch, dinner, sleep (phút từ 00:00), day_times_confirmed | Một dòng; giờ mặc định 06:00, 07:00, 12:00, 19:00, 22:30 |
| `products` | id, name, serving_label, created_at, archived | |
| `ingredients` | id, product_id, nutrient_id hoặc free_name, form hoặc `unknown`, amount_per_serving, unit, label_amount, label_unit, is_compound, origin (`manual`, `barcode`, `ocr`), confirmed | Mỗi dòng một chất, một dạng. Ràng buộc: có nutrient_id hoặc free_name |
| `boxes` | id, product_id, remaining (≥0), expiry_month (YYYY-MM), added_at | Số còn không âm |
| `schedules` | id, product_id, time_of_day (phút), servings, active | Mỗi ngày (MVP) |
| `food_entries` | id, at, tz_offset, day, meal (`breakfast`, `lunch`, `dinner`, `snack`), name, portion, nutrients (JSON), food_ref, pack_version | |
| `dose_entries` | id, at, tz_offset, day, product_id (null khi Ghi một lần), schedule_id, scheduled_day, servings, box_id, nutrients (JSON) | Gắn với lần theo lịch qua schedule_id + scheduled_day |
| `water_entries` | id, at, tz_offset, day, ml | |
| `workout_entries` | id, start_at, tz_offset, day, activity_code, minutes | |
| `ui_state` | key, value | Thẻ cảnh báo đã thu gọn, lưu ý lịch đã thu gọn, ngày ẩn thẻ "Bạn có biết" |

- **Lưu sẵn lượng chất của mỗi lần ghi** (`nutrients` JSON: id chất → lượng, kèm nguồn `food` / `fortified` / `supplement` theo phạm vi giới hạn). Gói dữ liệu hay thành phần sản phẩm đổi về sau thì lịch sử không đổi. Engine chỉ đọc các bản này.
- Di chuyển lược đồ bằng drift (`schemaVersion`, lưu bản lược đồ mỗi phiên bản, test di chuyển từ mọi bản cũ).

### Interface

- `SecureKeyStore`: `Future<Uint8List> getOrCreateDbKey()`, `Future<Uint8List?> readDbKey()`, `Future<void> deleteDbKey()`.
- `JournalRepository` đổi sang bất đồng bộ (`Future`, `Stream` theo ngày) và mở rộng theo lược đồ trên; `DriftJournalRepository` thay `InMemoryJournalRepository`. Bản bộ nhớ giữ lại để test giao diện.
- Engine (`packages/health_engine`) không đổi trong việc này: app đọc các lần ghi, đổi thành `IntakeItem`, `WorkoutEntry` rồi gọi engine.

### Luồng xử lý

1. **Lần đầu:** Điều kiện → Đồng ý. Bấm "Đồng ý và tiếp tục" thì tạo khóa, tạo CSDL, ghi `consents`, `profile` (tuổi, câu Có/Không), rồi các bước sau ghi tiếp.
2. **Mở app:** đọc khóa → mở CSDL → kiểm `schema_version`, di chuyển nếu cần → tải ngày đang xem.
3. **Ghi, sửa, xóa:** mỗi thao tác một giao dịch (vd. "Đã uống": thêm `dose_entries` và trừ `boxes` cùng giao dịch).
4. **Rút đồng ý, xóa toàn bộ:** đóng CSDL → xóa tệp (cả `-wal`, `-shm`) → xóa khóa → xóa `ui_state`, cài đặt → về Chào mừng. Bản trên Drive theo thiết kế (mục Quyền riêng tư).

### Lỗi và biên

| Tình huống | Xử lý |
|---|---|
| Có tệp nhưng không có khóa (khóa Keystore bị xóa, cài lại app có giữ dữ liệu) | Màn "Không mở được dữ liệu đã lưu trên máy." + [Khôi phục từ bản sao lưu] [Bắt đầu lại] (gõ XÓA) |
| Sai khóa, tệp hỏng | Như trên |
| Di chuyển lược đồ lỗi | Không ghi đè tệp cũ; như trên; lỗi giữ trong máy, không gửi đi |
| Hết dung lượng | "Chưa lưu được. Thử lại"; giao dịch hoàn tác, không mất dữ liệu cũ |
| Có khóa nhưng không có tệp | Tạo CSDL mới (coi như chưa có dữ liệu) |
| App mở khi máy đang khóa (từ thông báo) | Hệ điều hành yêu cầu mở khóa trước; app chỉ mở CSDL khi đã mở khóa |

## Tiêu chí đạt

- [ ] Trước khi bấm "Đồng ý và tiếp tục", thư mục dữ liệu của app không có tệp CSDL và chưa có khóa.
- [ ] 16 byte đầu tệp `wholewell.db` không phải `SQLite format 3`; mở bằng sqlite3 thường không đọc được bảng nào.
- [ ] Mở với khóa sai thì lỗi, không tạo dữ liệu mới, không ghi đè tệp.
- [ ] Ghi hồ sơ, món, lần uống, nước, buổi tập; tắt hẳn app rồi mở lại: dữ liệu và báo cáo ngày giống hệt trước khi tắt.
- [ ] "Đã uống" trừ đúng hộp trong cùng giao dịch; lỗi giữa chừng thì không có lần ghi nào và kho không đổi.
- [ ] Số còn trong `boxes` không âm (ràng buộc CSDL).
- [ ] Lượng chất lưu sẵn: đổi thành phần sản phẩm sau khi ghi không làm đổi tổng của ngày đã ghi.
- [ ] Rút đồng ý, xóa toàn bộ: không còn `wholewell.db`, `-wal`, `-shm`, không còn khóa; mở lại app ở màn Chào mừng.
- [ ] Bảng `profile` không có cột chứa tên bệnh, tên thuốc; câu thuốc, bệnh chỉ là Có/Không.
- [ ] AndroidManifest có `allowBackup="false"` và `dataExtractionRules` loại toàn bộ dữ liệu (kiểm bằng test tệp cấu hình).
- [ ] Test di chuyển lược đồ chạy được từ v1 (khung cho các bản sau).
- [ ] Truy vấn một ngày với 2 năm dữ liệu giả lập dưới 50 ms trên máy tầm trung (thử máy thật).
- [ ] Thử máy thật: Android 12+, mở khóa và khóa máy, khởi động lại máy, cài đè bản mới.

## Ngoài phạm vi

- Sao lưu tệp, Google Drive, khôi phục (đặc tả Sao lưu); xuất dữ liệu đọc được (đặc tả Quyền riêng tư).
- Giao diện kho, lịch uống, nhắc giờ, chụp nhãn (các đặc tả sau; lược đồ đã có bảng).
- Trường thai kỳ, hồ sơ trẻ em, nhiều hồ sơ trên một máy (giai đoạn 2).
- Sửa engine (việc 2 trong status).
- iOS: chỉ ghi cách giữ khóa; làm khi có bản iOS.

## Câu hỏi còn mở

1. **Android tối thiểu API 28 (Android 9)?** `setUnlockedDeviceRequired` cần API 28. Hiện app dùng mặc định của Flutter (thấp hơn). Đề xuất đặt `minSdk = 28`; máy thấp hơn rất ít và không giữ được yêu cầu "khóa chỉ dùng khi máy mở khóa".
2. **Lưu sẵn lượng chất mỗi lần ghi** (đề xuất ở trên) thay vì tính lại từ gói dữ liệu khi đọc. Lợi: lịch sử không đổi khi gói cập nhật; hại: số cũ không tự sửa nếu gói sửa lỗi. Đề xuất lưu sẵn kèm `pack_version` để sau này có thể tính lại có chủ đích.
