# Quyết định kiến trúc (ADR)

Mỗi tệp là một quyết định đã duyệt ngày 28/11/2026 trong [refactor-plan.md](../refactor-plan.md), mục 2. Tổng quan kiến trúc: [architecture.md](../architecture.md).

Đổi một quyết định: viết ADR mới thay thế (ghi số ADR cũ), chủ dự án duyệt; không sửa nội dung ADR đã duyệt, chỉ cập nhật mục "Thực hiện".

| ADR | Lớp | Chọn |
|---|---|---|
| [0001](0001-kien-truc-mvvm.md) | Kiến trúc | MVVM theo Flutter App Architecture Guide |
| [0002](0002-state-changenotifier-command.md) | State | `ChangeNotifier` + `ListenableBuilder`, `Command` + `Result<T>` |
| [0003](0003-di-provider.md) | DI | `provider`, chỉ để lắp phụ thuộc |
| [0004](0004-dieu-huong-go-router.md) | Điều hướng | `go_router` |
| [0005](0005-model-viet-tay.md) | Model | Class bất biến viết tay, không codegen cho model |
| [0006](0006-loi-result.md) | Lỗi | `Result<T>` từ repository trở lên, `sealed class AppException` |
| [0007](0007-csdl-drift-sqlite3mc.md) | CSDL | Giữ drift + SQLite3MultipleCiphers, SQL viết tay |
| [0008](0008-thu-vien-chi-doc-isolate.md) | Thư viện chỉ đọc | Thư viện món và DSLD chạy ở isolate nền |
| [0009](0009-native-pigeon.md) | Native interop | Pigeon; plugin `platform_bridge` cho phần dùng chung |
| [0010](0010-monorepo-phien-ban.md) | Monorepo và phiên bản | Pub Workspaces, ghim Flutter 3.50.1 trong `.fvmrc` |
| [0011](0011-chuoi-ngon-ngu.md) | Chuỗi và ngôn ngữ | `GlobalMaterialLocalizations` của `material_ui`, `gen-l10n` (ARB `vi`) |
| [0012](0012-flavor.md) | Flavor | Flavor `dev` và `prod` |
| [0013](0013-lint.md) | Lint | `very_good_analysis` + strict, một tệp lint ở gốc |
| [0014](0014-phat-hanh.md) | Phát hành | Ký bằng keystore từ CI secrets, obfuscate + symbol |
| [0015](0015-lam-moi-du-lieu.md) | Làm mới dữ liệu | Stream thay đổi theo bảng, cache theo người nghe |
