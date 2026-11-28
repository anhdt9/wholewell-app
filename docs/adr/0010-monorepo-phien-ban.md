# ADR 0010: Monorepo và phiên bản

Trạng thái: Đã duyệt (28/11/2026). Nguồn: [refactor-plan.md](../refactor-plan.md), mục 2, dòng 10.

## Quyết định

Pub Workspaces, một `pubspec.lock` ở gốc (commit). **Ghim Flutter 3.50.1** trong `.fvmrc`; máy dev dùng FVM, CI dùng `flutter-version-file: .fvmrc` (không dùng `pubspec.yaml` vì ở đó là khoảng `>=3.47.0`). Sàn theo `material_ui` 1.11.1: Dart `^3.13.0`, Flutter `>=3.47.0`. `hooks.user_defines` của sqlite3mc khai một lần ở gốc. **Mọi job CI dùng Flutter đã ghim**, kể cả job của package thuần Dart

## Không chọn

`channel: stable` không ghim; `setup-dart`

## Lý do và hệ quả

Workspace giải phụ thuộc chung, nên `dart pub get` bằng Dart thuần lỗi vì `app` cần Flutter SDK; Dart của `setup-dart` cũng khác Dart đi kèm Flutter nên lock lệch

## Thực hiện

**Đã làm** ở PR 0a (#47, 29/11/2026).
