# ADR 0008: Thư viện chỉ đọc

Trạng thái: Đã duyệt (28/11/2026). Nguồn: [refactor-plan.md](../refactor-plan.md), mục 2, dòng 8.

## Quyết định

Thư viện món và DSLD chạy ở isolate nền

## Không chọn

`sqlite3` đồng bộ trên isolate giao diện

## Lý do và hệ quả

Tìm FTS trên 94 nghìn dòng không chặn khung hình

## Thực hiện

PR 5a-4.
