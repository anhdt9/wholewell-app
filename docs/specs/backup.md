# Đặc tả: Sao lưu tệp mã hóa, khôi phục và Quyền riêng tư

Trạng thái: Đã duyệt (26/11/2026)  <!-- Nháp | Đã duyệt -->
Thiết kế UX: [docs/design/backup.md](../design/backup.md)
Thứ tự MVP: Việc 7 trong [docs/status.md](../status.md) ("tệp mã hóa trước, Google Drive sau")

## Mục tiêu
Cho phép người dùng tự sao lưu toàn bộ dữ liệu nhật ký ra **tệp mã hóa** trên máy bằng khóa do chỉ người dùng giữ (Argon2id), khôi phục dữ liệu khi đổi máy hoặc mất khóa Keystore (từ màn Chào mừng, màn lỗi khóa, hoặc trong Tôi), đồng thời hoàn thiện màn **Quyền riêng tư** (rút đồng ý, xuất JSON đọc được có cảnh báo không mã hóa, xóa toàn bộ) và sẵn sàng interface `BackupProvider` / `GoogleAuth` cho bước Google Drive sau khi tạo dự án Google Cloud.

## Người dùng và tình huống
- **Tạo bản sao lưu định kỳ / trước khi đổi máy:** Người dùng vào `Tôi → Sao lưu và khôi phục → [ Tạo tệp sao lưu ]`, nhận hoặc nhập **mã khôi phục / mật khẩu**, rồi lưu tệp `.wwbackup` ra bộ nhớ ngoài/USB/máy khác qua trình chọn tệp hệ thống.
- **Khôi phục khi cài lại app / đổi máy / mất khóa:** Từ màn **Chào mừng** (`Khôi phục từ bản sao lưu`), màn lỗi khóa (`KeyLost`/`KeyUnavailable` 3 lần), hoặc `Tôi → Sao lưu và khôi phục → [ Khôi phục từ tệp ]`, người dùng chọn tệp `.wwbackup`, nhập mã khôi phục → CSDL hiện tại (nếu có) được thay an toàn qua tệp tạm, mở lại với khóa Keystore mới của máy và vào app.
- **Xuất dữ liệu / Rút đồng ý / Xóa toàn bộ:** Người dùng vào `Tôi → Quyền riêng tư` để xem ngày giờ đã đồng ý, xuất bản JSON đọc được (sau cảnh báo không mã hóa), rút đồng ý, hoặc gõ `XÓA` để xóa toàn bộ dữ liệu.

## Ràng buộc
- **Dữ liệu ở máy & mã hóa độc lập với Keystore (`AGENTS.md`, `docs/plan.md`):**
  - Tệp sao lưu `.wwbackup` **không** phụ thuộc khóa Keystore của máy cũ để có thể khôi phục sang máy khác.
  - Dẫn xuất khóa từ mã khôi phục / mật khẩu bằng **Argon2id** với muối ngẫu nhiên (`salt` 16 byte), mã hóa bằng AEAD **ChaCha20-Poly1305** (xác thực toàn vẹn tag 16 byte — nhập sai mã khôi phục hoặc hỏng tệp sẽ từ chối ngay trước khi đụng vào CSDL trên máy).
  - App **không bao giờ** lưu mã khôi phục của bản sao lưu trên máy hay gửi đi đâu.
- **Tạo bản sao lưu từ CSDL đang mở an toàn (`docs/specs/encrypted-db.md`):**
  - Thực hiện `PRAGMA wal_checkpoint(TRUNCATE)` và sao chép nguyên byte tệp CSDL trên máy vào tệp tạm bên trong hàng đợi ghi tuần tự của `DriftJournalRepository` để tránh background isolate ghi thêm vào `-wal` giữa lúc copy; **tuyệt đối không để sót tệp CSDL không mã hóa trên ổ đĩa** nếu app bị kill đột ngột (`backupTmp`, `restoreTmp` được đăng ký vào `DbFiles` để tự xóa mỗi lần mở/xóa).
  - Hàm dẫn xuất khóa Argon2id (`~0,5–2 giây` trên di động) và AEAD **bắt buộc** chạy trong `Isolate.run(...)` để không đơ UI / gây ANR.
- **Tách pha theo `docs/status.md`:**
  - Phần 7a hoàn chỉnh: **Tệp sao lưu mã hóa (.wwbackup)**, **Khôi phục**, **Quyền riêng tư**, và interface `BackupProvider` / `GoogleAuth` + bản giả (`FakeBackupProvider`, `FakeGoogleAuth`) + dấu `drive_pending_delete` ngoài CSDL (không chứa dữ liệu sức khỏe).
  - Phần 7b (khi chủ dự án tạo **một dự án Google Cloud duy nhất**): cài đặt thật `GoogleAuth` + `DriveBackupProvider` (`appDataFolder`, giữ tối đa 3 bản mã hóa Argon2id, chạy khi mở/rời app, xóa bản trên Drive khi rút đồng ý/xóa toàn bộ).
- **Bảo vệ dữ liệu khi khôi phục lỗi:** Kiểm tra giải mã + `integrity_check` + `schemaVersion` trên tệp tạm **trước** khi thay CSDL hiện tại. Nếu giải mã sai hoặc phiên bản lược đồ cao hơn app hiện tại → giữ nguyên dữ liệu đang có trên máy.

## Nguồn & Pháp lý
- **Luật Bảo vệ dữ liệu cá nhân 91/2025/QH15, Nghị định 356/2025/NĐ-CP** (`docs/plan.md` mục 5): sức khỏe là dữ liệu nhạy cảm → có xem, sửa, xuất (cảnh báo rõ nếu tệp xuất không mã hóa), xóa ngay trên máy khi rút đồng ý; hỏi xóa bản sao lưu trên Drive nếu có (cơ chế dấu chờ xóa `drive_pending_delete` khi mất mạng).
- **Google Drive `appDataFolder` & Cross-Client Auth** (`docs/plan.md`): https://developers.google.com/workspace/drive/api/guides/appdata

## Thiết kế kỹ thuật

### 1. Định dạng tệp sao lưu `.wwbackup` & Mật mã (`packages/journal_db`)
- **Cấu trúc tệp nhị phân tự mô tả (versioned):**
  - Header (unencrypted AAD): `magic` (`WWBKUP01`, 8 byte) + `formatVersion` (`uint16`) + `schemaVersion` (`uint16`) + `argon2Params` (`memoryKiB: uint32`, `iterations: uint32`, `parallelism: uint16`) + `salt` (`16 byte`) + `nonce` (`12 byte`).
  - Payload mã hóa bằng **ChaCha20-Poly1305** (AAD = toàn bộ header): bản nén gzip của ảnh chụp cơ sở dữ liệu SQLite (`wholewell_snapshot.sqlite`, chứa toàn bộ các bảng trong `schema.dart`: `meta`, `consents`, `profile`, `settings`, `ui_state`, `food_entries`, `custom_foods`, `custom_food_lines`, `products`, `ingredients`, `boxes`, `schedules`, `dose_occurrences`, `dose_entries`, `dose_box_deductions`, `intake_lines`, `water_entries`, `workout_entries`), kèm 16 byte auth tag ở cuối.
- **Tham số Argon2id mặc định & chạy nền:** `memoryKiB = 19456` (~19 MiB), `iterations = 2`, `parallelism = 1` (lưu ngay trong header để giải mã được cả khi nâng tham số ở bản sau). `BackupCodec` chạy hoàn toàn trong `Isolate.run(...)` để không chặn UI thread.
- **Mã khôi phục (Recovery Key) / Mật khẩu:**
  - App hỗ trợ sinh sẵn **Mã khôi phục 24 ký tự Base32/Hex nhóm 4 ký tự** (ví dụ `ABCD-EFGH-...`, entropy 120 bit, đủ mạnh ngay cả khi không dùng mật khẩu dài) **hoặc** người dùng tự đặt mật khẩu tối thiểu 8 ký tự (khuyến nghị dùng Mã khôi phục sinh sẵn + nút `[Sao chép]`).

### 2. Quy trình Sao lưu, Khôi phục & Dọn tệp tạm (`packages/journal_db`)
- **Dọn tệp tạm (`DbFiles`):** Bổ sung `backupTmp` (`wholewell.db.backup-tmp`) và `restoreTmp` (`wholewell.db.restore-tmp`) kèm các tệp `-wal`/`-shm` tương ứng vào `DbFiles.allDataFiles()` để `DbOpener._open()` (khi khởi động lại sau crash) và `wipeAll()` luôn tự động xóa sạch mọi bản tạm chưa mã hóa còn sót.
- **`BackupCodec` (thuần Dart + `Isolate.run`):**
  - `Future<Uint8List> encryptSnapshot({required Uint8List plainSqliteBytes, required int schemaVersion, required String secret})`
  - `Future<({Uint8List plainSqliteBytes, int schemaVersion})> decryptSnapshot({required Uint8List backupBytes, required String secret})`
  - Ném lỗi phân biệt `BackupWrongSecretException` (tag Poly1305 sai / sai mã khôi phục) và `BackupCorruptedException` (magic/độ dài/gzip lỗi).
- **Sao lưu an toàn trên `DriftJournalRepository`:**
  - Chạy bên trong hàng đợi đồng bộ của `DriftJournalRepository`: `PRAGMA wal_checkpoint(TRUNCATE)` → copy nguyên byte `wholewell.db` sang `files.backupTmp` → mở `files.backupTmp` bằng khóa Keystore hiện tại → `PRAGMA rekey = ''` → đọc byte SQLite thuần vào `Uint8List`, đóng kết nối và `delete` ngay `files.backupTmp` trong `finally` → chạy `BackupCodec.encryptSnapshot(...)` trong `Isolate.run` và xóa trắng (`fillRange(0, ..., 0)`) buffer nguồn.
- **Khôi phục an toàn với 2 nhánh xử lý khóa (`DbOpener`):**
  - Bước kiểm trước (luôn chạy **trước** khi đụng vào khóa hoặc `wholewell.db` hiện tại): chạy `BackupCodec.decryptSnapshot` trong `Isolate.run` → kiểm `schemaVersion <= currentSchemaVersion` (lớn hơn thì báo `NeedsAppUpdate`) → ghi SQLite thuần vào `files.restoreTmp`, mở kiểm `PRAGMA integrity_check` = `ok`. Nếu bất kỳ bước nào lỗi, xóa `files.restoreTmp` và giữ nguyên dữ liệu cũ.
  - **Nhánh A — Máy đang mở được CSDL (từ `Tôi → Sao lưu và khôi phục`):** đóng kết nối CSDL đang mở → `PRAGMA rekey` tệp `files.restoreTmp` bằng **chính khóa Keystore hiện tại** (tránh gọi `createDbKey()` gây `KeyAlreadyExistsException` và bảo toàn dữ liệu cũ nếu có lỗi) → checkpoint/đóng `restoreTmp`, thay thế `wholewell.db` + xóa `-wal`/`-shm` → mở lại qua `DbOpener`.
  - **Nhánh B — Máy ở `Chào mừng` hoặc `KeyLost` / `KeyStuck` / `CannotOpen` (chưa có hoặc hỏng khóa):** sau khi tệp `files.restoreTmp` đã vượt `integrity_check` mới dọn `files.wipeMarker`, gọi `keys.deleteDbKey()` (nếu còn sót) rồi `keys.createDbKey()` → `PRAGMA rekey` tệp `files.restoreTmp` sang khóa mới vừa tạo → thay thế `wholewell.db` + xóa `-wal`/`-shm` → mở lại qua `DbOpener`.
  - Sau khi mở lại qua `DbOpener` (cả 2 nhánh): nếu `schemaVersion` của bản sao lưu cũ hơn `currentSchemaVersion` thì `DbOpener` tự di chuyển lược đồ; nếu `latestHealthConsent()` khác `mvpConsentVersion` thì chuyển sang bước xác nhận điều kiện & đồng ý. Cuối cùng gọi `syncNotifications()` an toàn (nếu máy mới chưa cấp `POST_NOTIFICATIONS` thì không crash, giữ trạng thái lịch để người dùng bật quyền sau).
- **Xuất dữ liệu đọc được (`JournalRepository`):**
  - Đưa `Future<Map<String, Object?>> exportReadableJson()` lên interface `JournalRepository` và cài đặt trên **cả** `DriftJournalRepository` lẫn `InMemoryJournalRepository` (chứa đủ hồ sơ, món ăn, lần uống, nước, buổi tập, sản phẩm, lịch) để màn `Quyền riêng tư` hỗ trợ xuất tệp JSON và test in-memory được.

### 3. Interface nền tảng & Điểm nối giao diện (`app/`)
- `BackupFileProvider` + `FakeBackupFileProvider`:
  - Trên Android dùng **Storage Access Framework (SAF)** (`ACTION_CREATE_DOCUMENT` / `ACTION_OPEN_DOCUMENT` qua `MethodChannel` hoặc `ActivityResultContracts`), **không** thêm quyền `READ_EXTERNAL_STORAGE` / `WRITE_EXTERNAL_STORAGE` vào `AndroidManifest.xml`.
- `GoogleAuth` + `FakeGoogleAuth` (`signIn`, `signOut`, `currentAccount`, `revokeAccess`) và `BackupProvider` + `FakeBackupProvider` (`uploadBackup`, `listBackups`, `downloadBackup`, `deleteAllBackups`).
- Dấu chờ xóa ngoài CSDL: `DrivePendingDeleteStore` (chỉ lưu 1 cờ không nhạy cảm ngoài `DbFiles`).
- Điểm nối UI hiện có:
  - Bật lại nút `Khôi phục từ bản sao lưu` ở màn `Chào mừng` và ở trạng thái `KeyLost` / `KeyStuck` / `CannotOpen` (hiện đang tắt trong `data_status_screen.dart`).
  - Hoàn thiện `Tôi → Sao lưu và khôi phục` (tạo tệp `.wwbackup`, khôi phục từ tệp, trạng thái chờ của Google Drive) và `Tôi → Quyền riêng tư` (rút đồng ý, xuất dữ liệu kèm cảnh báo `"Tệp này không được mã hóa. Ai có tệp đều đọc được."`, và chuyển/đồng bộ hộp thoại `XÓA` theo `mvp-overview.md` dòng 806: `"Mọi dữ liệu trên máy này sẽ bị xóa và không lấy lại được, trừ khi bạn có bản sao lưu. Gõ XÓA để xác nhận."`).

### 4. Lỗi và biên
- **Nhập sai mã khôi phục / mật khẩu:** Không chạm tới CSDL đang có; báo `"Mã khôi phục không đúng hoặc tệp đã bị hỏng."` và cho nhập lại.
- **Tệp sao lưu từ phiên bản app mới hơn (`schemaVersion > currentSchemaVersion`):** Từ chối khôi phục an toàn, báo `"Tệp sao lưu được tạo bởi phiên bản WholeWell mới hơn. Hãy cập nhật app trước khi khôi phục."`
- **Tệp sao lưu chứa đồng ý phiên bản cũ (vd. `khung-tam-0`):** Khôi phục xong dữ liệu, nhưng thay vì vào thẳng `Hôm nay`, app chuyển sang luồng nâng cấp điều kiện & đồng ý (`mvpConsentVersion`) giống `DbSessionController` đang làm!
- **Máy tắt đột ngột giữa chừng khi đang khôi phục:** Tệp chính chỉ được thay thế sau bước giải mã + `rekey` + `integrity_check` hoàn tất trên tệp tạm; nếu lỗi trước đó thì CSDL cũ vẫn còn nguyên vẹn.
- **Rút đồng ý / Xóa toàn bộ khi đã từng bật Drive (Phần 7b):** Nếu mất mạng hoặc hết phiên đăng nhập lúc xóa bản trên Drive → luôn xóa ngay dữ liệu trên máy, ghi `drive_pending_delete` (ngoài CSDL) để thử lại ở các lần mở app sau (`docs/design/mvp-overview.md` dòng 716).

## Tiêu chí đạt
- [ ] `packages/journal_db`: `BackupCodec` chạy Argon2id + ChaCha20-Poly1305 trong `Isolate.run`, test mã đúng/sai/sửa 1 byte; test sao lưu & khôi phục qua `SQLite3MultipleCiphers` cho cả 2 nhánh (máy đang mở khóa dùng lại khóa hiện tại; máy mất/hỏng khóa xóa khóa sót và tạo khóa mới), dọn sạch `backupTmp`/`restoreTmp` sau crash mô phỏng.
- [ ] `packages/journal_db`: `exportReadableJson()` trên cả `Drift` và `InMemory`; khôi phục bản lược đồ cũ tự di chuyển lên mới nhất; từ chối an toàn bản `schemaVersion` mới hơn.
- [ ] `app/`: có interface `BackupFileProvider` (Android SAF không cần quyền lưu trữ ngoài), `GoogleAuth`, `BackupProvider` + các bản giả (`Fake*`); bật nút `Khôi phục từ bản sao lưu` ở Chào mừng + `KeyStuck`/`CannotOpen`, màn `Sao lưu và khôi phục`, `Tôi → Quyền riêng tư` (`Rút đồng ý`, `Xuất dữ liệu` kèm cảnh báo không mã hóa, `Xóa toàn bộ dữ liệu` gõ `XÓA` theo `mvp-overview.md`); gọi `syncNotifications()` an toàn khi thiếu quyền.
- [ ] Toàn bộ `dart analyze/test` (`journal_db`, `health_engine`) và `flutter analyze/test` (`app`) pass.

## Ngoài phạm vi (Phần 7a này)
- **Tích hợp Google Drive API thật (`google_sign_in` + `googleapis` + Google Cloud OAuth Client ID):** Làm ở **Phần 7b** ngay sau khi chủ dự án tạo dự án Google Cloud (interface `GoogleAuth`, `BackupProvider` và dấu `drive_pending_delete` đã được dựng sẵn ở Phần 7a).
- **Khôi phục chéo nền tảng (Android ↔ iOS/Desktop):** Giai đoạn 2 (định dạng `.wwbackup` đã thiết kế độc lập nền tảng để hỗ trợ thẳng).

## Câu hỏi còn mở
1. **Chia làm 2 PR nhỏ (7a: Tệp mã hóa + Khôi phục + Quyền riêng tư + interface; 7b: Google Drive khi có dự án Google Cloud):** Bạn đồng ý chốt triển khai **Phần 7a** trước như `docs/status.md` ghi ("tệp mã hóa trước, Google Drive sau") đúng không?
2. **Thư viện Argon2id & ChaCha20-Poly1305 trong Dart:** Sử dụng gói `cryptography` + `argon2` (hoặc `pointycastle` / `cryptography_flutter`?) — khuyến nghị dùng `cryptography` (hỗ trợ sẵn ChaCha20-Poly1305 + Argon2id thuần Dart và tối ưu phần cứng trên Android/iOS). Bạn có ưu tiên gói nào khác không?
3. **Mã khôi phục khi sao lưu:** App mặc định tự sinh **Mã khôi phục 24 ký tự** (kèm nút sao chép / hướng dẫn ghi lại), hay cho phép người dùng **tự đặt mật khẩu** (≥ 8 ký tự)? *(Khuyến nghị: cho chọn 1 trong 2 hoặc mặc định sinh Mã khôi phục 24 ký tự mạnh, kèm tùy chọn nhập mật khẩu riêng nếu muốn dễ nhớ).*
