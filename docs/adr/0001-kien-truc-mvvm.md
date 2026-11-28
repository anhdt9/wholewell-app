# ADR 0001: Kiến trúc

Trạng thái: Đã duyệt (28/11/2026). Nguồn: [refactor-plan.md](../refactor-plan.md), mục 2, dòng 1.

## Quyết định

MVVM theo Architecture Guide: View, ViewModel, Repository, Service; use case chỉ khi cần

## Không chọn

Clean Architecture nhiều tầng

## Lý do và hệ quả

Mẫu chính thức. Phần tính toán nặng đã là package thuần Dart (`health_engine`)

## Thực hiện

Chuyển dần từng tính năng ở GĐ6 (PR 6.1–6.9).
