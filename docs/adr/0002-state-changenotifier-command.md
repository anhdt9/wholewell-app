# ADR 0002: State

Trạng thái: Đã duyệt (28/11/2026). Nguồn: [refactor-plan.md](../refactor-plan.md), mục 2, dòng 2.

## Quyết định

`ChangeNotifier` + `ListenableBuilder`, mỗi màn một ViewModel, `Command` + `Result<T>`

## Không chọn

Riverpod, Bloc

## Lý do và hệ quả

Không thêm thư viện quản lý state, chuyển dần từng màn được

## Thực hiện

`Command`, `Result` ở PR 3a (`app_core`); ViewModel ở GĐ6.
