# ADR 0005: Model

Trạng thái: Đã duyệt (28/11/2026). Nguồn: [refactor-plan.md](../refactor-plan.md), mục 2, dòng 5.

## Quyết định

Class bất biến viết tay, `sealed`/`final class`, record

## Không chọn

`freezed`, `built_value`, codegen cho model

## Lý do và hệ quả

Lệch khuyến nghị "Recommend" của guide, có lý do: không có `build_runner`, agent không phải đồng bộ tệp sinh. Mã sinh khác vẫn dùng (Pigeon, `gen-l10n`): commit vào repo, CI sinh lại rồi chạy `git diff --exit-code`, như với `reference_pack.json`

## Thực hiện

Đang theo: model của `journal_db` và `health_engine` viết tay.
