# ADR 0004: Điều hướng

Trạng thái: Đã duyệt (28/11/2026). Nguồn: [refactor-plan.md](../refactor-plan.md), mục 2, dòng 4.

## Quyết định

`go_router`: route có kiểu, redirect theo trạng thái phiên, mở đúng màn từ thông báo

## Không chọn

`Navigator.push` rải rác (51 chỗ)

## Lý do và hệ quả

**Thử trước** với `material_ui` (PR 5b)

## Thực hiện

Thử ở PR 5b, áp dụng ở PR 5c.
