# ADR 0014: Phát hành

Trạng thái: Đã duyệt (28/11/2026). Nguồn: [refactor-plan.md](../refactor-plan.md), mục 2, dòng 14.

## Quyết định

Ký bằng keystore lấy từ CI secrets; `--obfuscate --split-debug-info`, lưu symbol vào artifact

## Không chọn

Ký bằng khóa debug

## Lý do và hệ quả

Play chấp nhận; đọc được stack trace từ Play Console. Đổi khóa ký thì phải thêm Android OAuth client cho SHA-1 mới, nếu không đăng nhập Drive lỗi (PR 0f)

## Thực hiện

PR 0f; chủ dự án tạo keystore và các Android OAuth client (plan, mục 7.4).
