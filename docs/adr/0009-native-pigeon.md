# ADR 0009: Native interop

Trạng thái: Đã duyệt (28/11/2026). Nguồn: [refactor-plan.md](../refactor-plan.md), mục 2, dòng 9.

## Quyết định

**Pigeon**. Phần dùng chung (khóa, lưu/chọn tệp, mở cài đặt) là **Flutter plugin** `platform_bridge` có module Android. Nhắc giờ và AI đọc nhãn là phần riêng của WholeWell, khai Pigeon trong `app/`

## Không chọn

`MethodChannel` viết tay; package Dart thuần chứa Pigeon

## Lý do và hệ quả

Mã Kotlin do Pigeon sinh phải nằm trong module Android. Plugin nhận alias và tên tệp khóa làm tham số. WholeWell giữ nguyên alias `wholewell_db_wrap_v1`, tệp `wholewell_db_key.bin` trong `noBackupFilesDir`, và luật loại khỏi sao lưu trong manifest của app (`allowBackup`, `fullBackupContent`, `data_extraction_rules.xml`); đổi một trong số này là mất CSDL trên máy đã cài

## Thực hiện

PR 4a (`platform_bridge`), PR 4b (Pigeon riêng trong `app/`).
