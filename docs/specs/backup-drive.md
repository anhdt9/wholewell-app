# Đặc tả: Sao lưu Google Drive (`appDataFolder`) — Phần 7b

Trạng thái: Đã duyệt (26/11/2026)  <!-- Nháp | Đã duyệt -->
Thiết kế UX: [docs/design/backup-drive.md](../design/backup-drive.md)
Thứ tự MVP: Việc 7 (Phần 7b) trong [docs/status.md](../status.md)

## Mục tiêu
Cho phép người dùng tùy chọn sao lưu và khôi phục bản `.wwbackup` đã mã hóa Argon2id + ChaCha20-Poly1305 qua **Google Drive `appDataFolder`** (thư mục ẩn của riêng app trên tài khoản Google của người dùng), đồng thời hỗ trợ thu hồi/xóa bản sao lưu trên Drive kể cả khi thiết bị tạm mất mạng (`DrivePendingDeleteStore`).

## Người dùng và tình huống
- **Bật sao lưu Google Drive (tùy chọn):** Từ `Tôi → Sao lưu và khôi phục`, người dùng xem phần `Google Drive`, đọc màn đồng ý riêng (`consents.kind = 'drive'`), đăng nhập tài khoản Google (chỉ xin quyền `drive.appdata`), nhập/nhận mã khôi phục và tải bản `.wwbackup` mã hóa lên Drive.
- **Khôi phục từ Google Drive:** Từ màn `Chào mừng`, màn lỗi khóa (`KeyStuck` / `CannotOpen`), hoặc `Tôi → Sao lưu và khôi phục`, người dùng chọn `Khôi phục từ Google Drive`, đăng nhập đúng tài khoản Google đã sao lưu, chọn bản gần nhất (trong tối đa 3 bản), nhập mã khôi phục/mật khẩu để giải mã và khôi phục.
- **Tắt Drive / Rút đồng ý / Xóa toàn bộ dữ liệu:**
  - Tắt riêng Drive trong `Tôi → Sao lưu và khôi phục`: hỏi có xóa các bản sao lưu trên Drive hay không, thu hồi đăng nhập Google và rút `consents.kind = 'drive'`.
  - `Rút đồng ý` hoặc `Xóa toàn bộ dữ liệu` trong `Tôi → Quyền riêng tư`: xóa ngay dữ liệu trên máy; nếu đang bật Drive thì gọi xóa toàn bộ bản trên Drive và đăng xuất. Nếu lúc đó mất mạng hoặc hết phiên, lưu cờ `DrivePendingDeleteStore` ngoài CSDL để thử xóa lại ở các lần mở app sau.

## Ràng buộc
- **Một dự án Google Cloud duy nhất (`AGENTS.md`):** Mọi client OAuth (Android hiện tại; iOS/desktop sau này) dùng chung một Google Cloud Project, chỉ xin scope tối thiểu `https://www.googleapis.com/auth/drive.appdata` (không xin quyền đọc tệp cá nhân khác trên Drive).
- **Bảo mật & khóa chỉ người dùng giữ (`docs/specs/backup.md`):**
  - Tệp tải lên `appDataFolder` dùng đúng định dạng `.wwbackup` của Phần 7a (`BackupCodec` chạy trong `Isolate.run`, Argon2id + ChaCha20-Poly1305).
  - App **không** lưu mã khôi phục/mật khẩu bản sao lưu lên Drive hay lên máy; **không** đưa dữ liệu sức khỏe hay tên chất vào tên tệp, `appProperties` hoặc log.
- **Tách interface nền tảng (`AGENTS.md`, quy tắc 4):**
  - Toàn bộ giao tiếp thật đi qua `GoogleAuth` và `BackupProvider` (khai báo tại `app/lib/platform/backup_provider.dart`), mở rộng interface và cập nhật `FakeGoogleAuth`, `FakeBackupProvider`, `InMemoryDrivePendingDeleteStore` tương ứng để test không cần mạng thật.
- **Miễn phí, không SDK phân tích/báo lỗi bên thứ ba, không quảng cáo.**

## Nguồn
- **Google Drive API `appDataFolder`:** https://developers.google.com/workspace/drive/api/guides/appdata
- **Luật Bảo vệ dữ liệu cá nhân 91/2025/QH15, Nghị định 356/2025/NĐ-CP** (`docs/plan.md` mục 5): quyền rút đồng ý, xóa dữ liệu đã sao lưu và xử lý khi mất mạng qua cờ chờ xóa ngoài CSDL.

## Thiết kế kỹ thuật

### 1. Dữ liệu (`packages/journal_db`)
- Bảng `consents` trong `schema.dart` đã có sẵn `kind IN ('health_data', 'notifications', 'drive')`.
- Bổ sung lên `JournalRepository` (cài cho cả `DriftJournalRepository` và `InMemoryJournalRepository`):
  - `Future<HealthConsentStatus?> latestDriveConsent()`
  - `Future<void> grantDriveConsent(String contentVersion)`
  - `Future<void> withdrawDriveConsent()`
- `ui_state`: dùng khóa `'last_drive_backup_at'` (epoch UTC ms) để hiện mốc sao lưu Drive gần nhất trên `Tôi → Sao lưu và khôi phục` và `Tôi → Quyền riêng tư`.
- Ngoài CSDL: `FileDrivePendingDeleteStore` (tệp JSON nhỏ nằm trong thư mục hỗ trợ app, **không** đưa vào `DbOpener.extraFilesToWipe` vì `extraFilesToWipe` bị xóa ngay lúc xóa cục bộ; chỉ xóa qua `drivePendingDeleteStore.clearPendingDelete()` sau khi `deleteAll()` thành công hoặc người dùng xác nhận bỏ qua khi hết phiên; không chứa dữ liệu sức khỏe).

### 2. Interface nền tảng (`app/lib/platform/`)
- `GoogleAuth` (bổ sung vào interface hiện có và cập nhật `FakeGoogleAuth`) → cài đặt thật `GoogleSignInAuth` (dùng `google_sign_in`, scope `['https://www.googleapis.com/auth/drive.appdata']`): giữ `currentUser()`, `signIn()`, `signOut()`, và bổ sung `signInSilently()`, `disconnect()`, `authHeaders()`.
- `BackupProvider` (bổ sung vào interface hiện có và cập nhật `FakeBackupProvider`) → cài đặt thật `GoogleDriveBackupProvider` (dùng `googleapis/drive/v3.dart`):
  - `listBackups()` (bổ sung) và `latestBackup()`: liệt kê tối đa 10 tệp trong `spaces: 'appDataFolder'` sắp giảm dần theo `modifiedTime`.
  - `upload(Uint8List encryptedBackupBytes)`: tải lên tệp mới (`wholewell-YYYYMMDD-HHmm.wwbackup`, `parents: ['appDataFolder']`), sau khi tải lên thành công mới xóa các bản cũ vượt quá **3 bản** gần nhất.
  - `download(String id)`: tải `Media` byte `.wwbackup` về RAM (`Uint8List`), đưa thẳng vào `DbOpener.restoreFromBackup(...)`.
  - `deleteAll()`: liệt kê mọi tệp trong `appDataFolder` của app và xóa lần lượt.

### 3. Luồng xử lý
- **Tạo bản sao lưu lên Drive:**
  1. Nếu chưa có `latestDriveConsent()`, hiện màn đồng ý riêng (`consents.kind = 'drive'`).
  2. Gọi `googleAuth.signIn()`. Nếu hủy → dừng nhẹ nhàng; nếu lỗi → báo lỗi thân thiện.
  3. Người dùng nhận mã khôi phục 24 ký tự (hoặc tự đặt mật khẩu ≥ 8 ký tự) và xác nhận đã lưu mã (tương tự `CreateBackupScreen`).
  4. `DbOpener.exportBackup(...)` → `GoogleDriveBackupProvider.upload(...)` → ghi `last_drive_backup_at`.
- **Khôi phục từ Drive:**
  1. Ở màn `Chào mừng` / `KeyStuck` / `CannotOpen` (máy chưa có hoặc chưa mở được CSDL): **không** hỏi màn đồng ý bật Drive (`consents.kind = 'drive'`); chỉ đăng nhập Google để tải tệp sao lưu về giải mã. Sau khi khôi phục xong, trạng thái `consents.kind = 'drive'` đi theo dữ liệu trong bản sao lưu vừa giải mã.
  2. Gọi `googleAuth.signIn()` → `backupProvider.listBackups()` (chọn trong tối đa 3 bản gần nhất, mặc định chọn bản mới nhất).
  3. Nhập mã khôi phục / mật khẩu → `backupProvider.download(id)` → `AppState.restoreEncryptedBackupFile(...)` (dùng chung 2 nhánh xử lý khóa Keystore của Phần 7a).
- **Xử lý `DrivePendingDeleteStore` và hộp thoại xóa khi đã bật Drive (`mvp-overview.md` dòng 716 & 806):**
  - Khi người dùng bấm `Rút đồng ý` hoặc `Xóa toàn bộ dữ liệu` trên máy đang bật Drive: hộp thoại xác nhận hiển thị thêm ô chọn `"Xóa cả bản sao lưu trên Google Drive"` (**rút đồng ý: đánh sẵn**; **xóa toàn bộ: không đánh sẵn**) và dòng `"Tệp sao lưu bạn đã xuất ra ngoài thì app không xóa được."`
  - Dữ liệu trên máy **luôn xóa ngay**. Nếu người dùng chọn xóa bản trên Drive: gọi `backupProvider.deleteAll()` rồi `googleAuth.disconnect()`. Nếu mất mạng → ghi `drivePendingDeleteStore.markPendingDelete()`, báo `"Chưa xóa được bản trên Google Drive. App sẽ thử lại khi có mạng."` và thử lại mỗi lần mở app; nếu hết phiên đăng nhập / thu hồi quyền → hiện `[Đăng nhập để xóa]` và hướng dẫn tự xóa trong Google Drive (`Cài đặt → Quản lý ứng dụng`).
  - Ở `AppState.start()` / `onAppResume()`: nếu `await drivePendingDeleteStore.hasPendingDelete()` là `true`, thử im lặng `signInSilently()`:
    - Nếu đăng nhập im lặng được: gọi `deleteAll()` → `disconnect()` → `clearPendingDelete()`.
    - Nếu lỗi mạng tạm thời: giữ nguyên cờ `pendingDelete`, thử lại ở lần mở app sau.
    - Nếu `signInSilently()` trả `null` hoặc lỗi thu hồi quyền (người dùng đã đăng xuất hoặc thu hồi quyền app từ cài đặt Google Account): hiện nhắc ở màn hình hiện tại (kèm `[Đăng nhập để xóa]`, hướng dẫn tự xóa trong Google Drive `Cài đặt → Quản lý ứng dụng`, và nút `[Đã tự xóa / Bỏ qua]` để gọi `clearPendingDelete()` tránh kẹt cờ vĩnh viễn).

### 4. Lỗi và biên
- **Mất mạng / hết hạn phiên Google:** Không mất dữ liệu trên máy; báo rõ `"Chưa kết nối được Google Drive. Kiểm tra mạng và thử lại."`.
- **Không tìm thấy bản sao lưu trên `appDataFolder`:** Báo `"Chưa có bản sao lưu nào trên tài khoản Google này."` và gợi ý đổi tài khoản khác hoặc khôi phục từ tệp `.wwbackup`.
- **Đổi tài khoản Google khác / sai mã khôi phục:** Giữ nguyên dữ liệu đang có trên máy (`RestoreWrongSecret`), cho phép nhập lại mã hoặc đổi tài khoản.
- **Thiếu cấu hình OAuth SHA-1 / Web Client ID trên thiết bị thử:** Xử lý `PlatformException` từ `google_sign_in` thành `GoogleAuthFailed`, không crash app.

## Tiêu chí đạt
- [ ] `packages/journal_db`: có `latestDriveConsent`, `grantDriveConsent`, `withdrawDriveConsent` trên `JournalRepository` (`Drift` + `InMemory`) kèm unit test.
- [ ] `app/`: mở rộng `GoogleAuth` (`signInSilently`, `disconnect`, `authHeaders`) & `BackupProvider` (`listBackups`), cập nhật `FakeGoogleAuth` & `FakeBackupProvider`; cài đặt `GoogleSignInAuth` & `GoogleDriveBackupProvider` với scope `drive.appdata`, giữ tối đa 3 bản khi upload, không dùng quyền bộ nhớ ngoài.
- [ ] `app/`: luồng bật Drive (có màn đồng ý riêng), sao lưu lên Drive, khôi phục từ Drive (từ Chào mừng, màn lỗi khóa, và `Tôi`), tắt Drive, và xử lý `DrivePendingDeleteStore` khi mất mạng lúc rút đồng ý/xóa toàn bộ.
- [ ] Toàn bộ test với `FakeGoogleAuth` & `FakeBackupProvider` chạy offline, `dart analyze/test` + `flutter analyze/test` + Android unit test qua 100%.

## Ngoài phạm vi
- Sao lưu tự động chạy ngầm định kỳ bằng `WorkManager` (vì mã khôi phục không lưu trên máy; nếu tự động hóa sau này sẽ cần cơ chế khóa riêng).
- Cấu hình OAuth Client ID cho iOS/Desktop (chỉ làm khi phát hành các nền tảng đó, dùng chung Google Cloud Project).

## Câu hỏi còn mở
1. **Cấu hình Google Cloud Project & OAuth Client ID:** Bạn đã tạo sẵn dự án Google Cloud và OAuth Client ID (Android debug/release SHA-1) chưa, hay mình cài xong code + test offline bằng `Fake*` trước và ghi hướng dẫn điền `SHA-1` / `google-services` để bạn nối khi tạo dự án?
2. **Tần suất sao lưu Drive:** Bản 7b này chạy **theo thao tác người dùng** (`[ Sao lưu lên Drive ngay ]` giống tệp `.wwbackup` để người dùng luôn giữ mã khôi phục, không lưu mật khẩu trên máy) là hợp lý nhất — bạn đồng ý chốt hướng này chứ?
3. **Số bản lưu trên `appDataFolder`:** Giữ tối đa **3 bản** gần nhất (tải xong bản mới mới xóa bản cũ thứ 4) — bạn đồng ý mức này chứ?
