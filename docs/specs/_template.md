# Đặc tả: <tên tính năng>

Trạng thái: Nháp  <!-- Nháp | Đã duyệt -->
Thiết kế UX: [docs/design/<tên>.md](../design/<tên>.md)
Thứ tự MVP: <mục trong docs/status.md>

## Mục tiêu
Một hai câu: người dùng làm được gì, vì sao cần.

## Người dùng và tình huống
- Ai dùng, lúc nào, trên thiết bị nào (vd. mở app sau bữa trưa để ghi món).

## Ràng buộc
- Quy tắc trong AGENTS.md áp dụng (dữ liệu ở máy, không AI tạo sinh, chỉ chuẩn được dùng, không quảng cáo ở màn cảnh báo…).

## Nguồn
- Mỗi con số hay quy tắc: tên nguồn + link. Không có nguồn thì không có quy tắc.

## Thiết kế kỹ thuật
- **Dữ liệu:** bảng / trường mới, kiểu, ràng buộc, di chuyển lược đồ.
- **Interface:** interface nền tảng dùng tới (NotificationScheduler, OcrEngine…), hàm engine mới.
- **Luồng xử lý:** các bước từ thao tác người dùng tới kết quả.
- **Lỗi và biên:** thiếu quyền, mất dữ liệu, đơn vị lạ, giá trị sát UL.

## Tiêu chí đạt
- [ ] Tiêu chí đo được; mỗi dòng thành ít nhất một test.

## Ngoài phạm vi
- Những gì không làm trong lần này.

## Câu hỏi còn mở
- Điều cần chủ dự án quyết định trước khi duyệt.
