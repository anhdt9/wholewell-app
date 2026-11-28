# ADR 0003: DI

Trạng thái: Đã duyệt (28/11/2026). Nguồn: [refactor-plan.md](../refactor-plan.md), mục 2, dòng 3.

## Quyết định

**`provider`**, chỉ để lắp phụ thuộc: `MultiProvider` ở gốc, khai trong `config/dependencies.dart` (service → repository). ViewModel của màn tạo trong builder của route, nhận repository qua constructor bằng `context.read()`. Không dùng `context.watch`/`Consumer`: widget nghe ViewModel bằng `ListenableBuilder`

## Không chọn

`get_it`, singleton; `InheritedWidget` tự viết

## Lý do và hệ quả

Guide khuyên dùng `provider`, ví dụ Compass của guide dùng nó. Tự viết thì phải làm lại `read`, phạm vi, `dispose`. `provider` chỉ phụ thuộc `flutter/widgets`, không vướng `material_ui`

## Thực hiện

PR 5a-2 (`config/dependencies.dart`).
