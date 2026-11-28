# ADR 0006: Lỗi

Trạng thái: Đã duyệt (28/11/2026). Nguồn: [refactor-plan.md](../refactor-plan.md), mục 2, dòng 6.

## Quyết định

`Result<T>` từ repository trở lên; `sealed class AppException` ở tầng dữ liệu

## Không chọn

Ném exception xuyên tầng, chuỗi lỗi trong state

## Lý do và hệ quả

UI tự chọn lời hiển thị

## Thực hiện

PR 3a (`app_core`); repository trả `Result` từ GĐ5.
