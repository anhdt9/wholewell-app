# ADR 0011: Chuỗi và ngôn ngữ

Trạng thái: Đã duyệt (28/11/2026). Nguồn: [refactor-plan.md](../refactor-plan.md), mục 2, dòng 11.

## Quyết định

`localizationsDelegates` dùng **`GlobalMaterialLocalizations` của `material_ui`** (không dùng bản của `flutter_localizations`), `locale: vi`. `gen-l10n` (ARB `vi`): chuỗi mới vào ARB, chuỗi cũ chuyển dần theo tính năng

## Không chọn

Chuyển hết trong một PR

## Lý do và hệ quả

**Thử trước** cùng `go_router` (PR 5b)

## Thực hiện

Thử ở PR 5b, áp dụng ở PR 5c.
