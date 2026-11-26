# Bảng tự kiểm pháp lý & an toàn trước phát hành (Cổng 2)

Cập nhật: 26/11/2026 · Áp dụng cho MVP Android (`wholewell-app`, `mvpConsentVersion = 'mvp-1'`)

## 1. Luật Bảo vệ dữ liệu cá nhân 91/2025/QH15 & Nghị định 356/2025/NĐ-CP

| Yêu cầu | Cách WholeWell đáp ứng | Nơi kiểm chứng trong repo | Trạng thái |
|---|---|---|---|
| Dữ liệu sức khỏe là dữ liệu nhạy cảm: cần sự đồng ý rõ ràng, không đánh sẵn ô, tách riêng từng mục đích | Ba điểm đồng ý tách biệt, ô tích mặc định `false`: (1) `health_data` ở màn Đồng ý `2/4`, (2) `notifications` ở màn `Nhắc giờ`, (3) `drive` ở `DriveConsentScreen` | `onboarding_flow.dart`, `notification_settings_screen.dart`, `drive_backup_screens.dart` | Đạt (đã có widget test) |
| Lưu bằng chứng đồng ý (phiên bản, thời điểm, loại đồng ý) | Bảng `consents` lưu `kind`, `content_version`, `granted_at`, `withdrawn_at` trong CSDL mã hóa | `packages/journal_db/lib/src/schema.dart`, `drift_repository.dart` | Đạt |
| Quyền xem, sửa, xuất dữ liệu | Xem/sửa tại `Tôi → Hồ sơ` và `Nhật ký`; xuất JSON tại `Tôi → Quyền riêng tư → Xuất dữ liệu` (kèm cảnh báo không mã hóa) | `profile_screen.dart`, `privacy_screen.dart`, `backup_privacy_test.dart` | Đạt |
| Quyền rút đồng ý & xóa ngay trên thiết bị, hỗ trợ xóa bản trên Drive | Xóa ngay khóa Keystore + các tệp CSDL khi rút đồng ý/xóa toàn bộ; hộp thoại có ô `"Xóa cả bản sao lưu trên Google Drive"`; mất mạng ghi `FileDrivePendingDeleteStore` ngoài CSDL | `opener.dart`, `privacy_screen.dart`, `app_state.dart`, `backup_privacy_test.dart` | Đạt |
| Bảo mật dữ liệu trên máy & khi sao lưu | SQLite3MultipleCiphers (ChaCha20) + Android Keystore (`setUnlockedDeviceRequired`); sao lưu Argon2id + ChaCha20-Poly1305 chạy trong `Isolate.run`, khóa chỉ người dùng giữ | `connection.dart`, `backup_codec.dart`, `DbKeyStore.kt`, `android_config_test.dart` | Đạt |
| Không thu thập ngầm / minh bạch quyền riêng tư | Toàn văn `docs/privacy-policy.md` đọc được offline trong `Tôi → Quyền riêng tư → Chính sách quyền riêng tư` và màn Đồng ý | `docs/privacy-policy.md`, `privacy_screen.dart`, `gate2_privacy_audit_test.dart` | Đạt |

### Mẫu hồ sơ tự đánh giá tác động xử lý dữ liệu cá nhân nhạy cảm (lưu nội bộ)
- **Chủ thể xử lý tại thiết bị:** Người dùng tự vận hành trên thiết bị cá nhân; nhà phát triển **Đặng Thế Anh** (`wholewell.apps@gmail.com`) **không** thu thập, **không** truyền về máy chủ và **không** có khả năng truy cập dữ liệu sức khỏe của người dùng.
- **Loại dữ liệu nhạy cảm xử lý cục bộ:** Tuổi, giới tính sinh học, chiều cao, cân nặng, mức vận động, cờ thận trọng Có/Không (không lưu tên bệnh/thuốc), nhật ký ăn/uống/bổ sung/vận động.
- **Tác động & Biện pháp giảm thiểu rủi ro:**
  - *Rò rỉ từ thiết bị mất/bị truy cập trái phép:* Mã hóa toàn bộ CSDL bằng ChaCha20; khóa chỉ mở khi thiết bị đã mở khóa (`minSdk 28`, `setUnlockedDeviceRequired`).
  - *Rò rỉ qua sao lưu đám mây hệ điều hành:* Tắt `android:allowBackup="false"`, `fullBackupContent="false"`, `dataExtractionRules` chặn cả cloud backup lẫn chuyển máy.
  - *Rò rỉ qua thông báo màn hình khóa:* `ReminderLogic.kt` chỉ hiển thị số loại đến giờ (`"Đến giờ uống, X loại"`), không ghi tên chất hay tên sản phẩm.
  - *Rò rỉ qua Google Drive:* Chỉ dùng phạm vi `drive.appdata` ẩn danh mục, dữ liệu mã hóa Argon2id trước khi rời máy bằng mã do người dùng tự giữ.

## 2. Nghị định 98/2021/NĐ-CP & Phân định công cụ tham chiếu

- [x] Không chẩn đoán bệnh, không kê đơn, không gợi ý liều dùng cá nhân theo bệnh lý (`AGENTS.md`, `docs/design/README.md`).
- [x] Màn Điều kiện (`1/4`) chặn dưới 18 tuổi, mang thai, cho con bú; nhóm dùng thuốc theo chỉ định hoặc có bệnh mạn tính dùng ở chế độ thận trọng với thông báo cố định hỏi ý kiến bác sĩ/dược sĩ.
- [x] Cảnh báo UL chỉ cung cấp thông tin số, phạm vi tính, mục góp vào và câu `"Hỏi bác sĩ hoặc dược sĩ nếu cần."`; không suy diễn tác hại hay điều trị.

## 3. Luật Sở hữu trí tuệ (Điều 15) & Nguồn dữ liệu

- [x] Chỉ lưu con số tham chiếu (DRI của NASEM, EER 2023, AMDR, Compendium 2024, Dietary Guidelines 2025–2030, FDA 21 CFR 101), không sao chép văn bản/bố cục gốc; giải thích tiếng Việt tự viết.
- [x] Mọi số liệu và 5 quy tắc lịch trong `tools/build_pack.py` đều có `source`, `url`, `quote`, `accessedDate` được kiểm qua `tools/verify_pack.py`.
- [x] Thực phẩm (USDA FoodData Central / FNDDS / SR Legacy / FPED) và Thực phẩm bổ sung (NIH DSLD) là dữ liệu phạm vi công cộng Hoa Kỳ / CC0.

## 4. Google Play Store & Google API User Data Policy

- **Google Play Data safety (`support.google.com/googleplay/answer/11416267`):**
  - Xử lý thuần trên thiết bị không tính là "Data collected"; chỉ khai phần tùy chọn Google Drive `appDataFolder` nếu người dùng bật, nêu rõ dữ liệu được mã hóa đầu cuối bởi người dùng (`Argon2id` + `ChaCha20-Poly1305`) trước khi tải lên.
  - Không có SDK bên thứ ba thu thập crash/analytics/ads.
- **Google Play Health apps declaration (`support.google.com/googleplay/android-developer/answer/16555673`):**
  - Khai đúng nhóm công cụ tham chiếu dinh dưỡng & vận động (Nutrition and fitness / Health reference), không phải thiết bị y tế, gắn URL trang Chính sách quyền riêng tư xuất bản từ `docs/privacy-policy.md`.
- **Google API User Data Policy (OAuth Consent Screen):**
  - Dùng một Google Cloud Project duy nhất cho mọi client OAuth; chỉ khai duy nhất scope non-sensitive/app-specific `https://www.googleapis.com/auth/drive.appdata`.

## 5. Rà soát bảo mật theo OWASP Mobile Top 10

| Hạng mục | Kiểm tra trên WholeWell | Kết quả |
|---|---|---|
| **M1** Improper Credential Usage | Không lưu mật khẩu/mã khôi phục `.wwbackup` hay OAuth secret cứng trong app | Đạt |
| **M2** Inadequate Supply Chain Security | Chỉ dùng gói chính thức Flutter/Dart + thư viện đối chiếu SHA-256 cho `food_library.db` và `dsld_library.db.gz`; CI khóa kiểm định mỗi PR | Đạt |
| **M3** Insecure Authentication / Authorization | Dữ liệu sức khỏe dùng khóa thiết bị (`isDeviceUnlocked` + `setUnlockedDeviceRequired`); Drive dùng OAuth2 `google_sign_in` chuẩn | Đạt |
| **M4** Insufficient Input / Output Validation | Kiểm tra hợp lý thành phần (`checkIngredientSanity`), ràng buộc SQLite `CHECK`, xác nhận từng dòng OCR trước khi ghi DB, kiểm header + AEAD + `PRAGMA integrity_check` trước khi thay DB khôi phục | Đạt |
| **M5** Insecure Communication | App offline trừ Google Drive API dùng HTTPS chính thức với Bearer token ngắn hạn | Đạt |
| **M6** Inadequate Privacy Controls | Tắt `allowBackup`, che tên sản phẩm/chất trên thông báo khóa, không log câu SQL/giá trị nhạy cảm trong `JournalStorageException`, không SDK bên thứ ba | Đạt |
| **M7** Insufficient Binary Protections | Tệp CSDL kiểm `PRAGMA cipher` & header, gói thư viện kiểm SHA-256 trước khi mở | Đạt |
| **M8** Security Misconfiguration | `AndroidManifest.xml` bỏ quyền bộ nhớ ngoài (`READ_EXTERNAL_STORAGE` / `WRITE_EXTERNAL_STORAGE`), dùng Android SAF | Đạt |
| **M9** Insecure Data Storage | SQLite3MultipleCiphers ChaCha20; tệp tạm `backupTmp`/`restoreTmp`/`creating` được dọn tự động ở `_open()` và `wipeAll()` | Đạt |
| **M10** Insufficient Cryptography | ChaCha20-Poly1305 + Argon2id (`19456 KiB`, `t=2`, `p=1`, salt 16 byte ngẫu nhiên, AAD toàn bộ header) | Đạt |
