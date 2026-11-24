# Nguyên tắc thiết kế UX

Mọi thiết kế trong `docs/design/` tuân các nguyên tắc dưới đây. Rút từ plan (`docs/plan.md`, mục An toàn người dùng và Doanh thu).

## Vai trò và lời lẽ

- App là **công cụ tham chiếu**, không phải bác sĩ: dùng "so với mức khuyến nghị", "vượt giới hạn an toàn"; không dùng "bạn bị thiếu", "nên uống", "điều trị".
- Tiếng Việt thường ngày, câu ngắn. Không hiện tên viết tắt của chuẩn (RDA, UL, EER, AMDR) trên giao diện; chỉ ghi nguồn ở màn "Nguồn số liệu".
- Mức chưa chính thức (AI) ghi "ước tính".
- Không phán xét: không màu đỏ cho việc ăn nhiều hay ít calo, không "tốt/xấu", không chuỗi ngày liên tiếp, không huy hiệu.

## An toàn

- Cảnh báo vượt giới hạn an toàn là thông tin quan trọng nhất trên màn hình: nổi bật nhưng bình tĩnh, nói rõ chất nào, bao nhiêu, tính từ nguồn nào (bổ sung, thực phẩm tăng cường), và gợi ý hỏi bác sĩ hoặc dược sĩ.
- Có tùy chọn **ẩn số calo** ở mọi màn hình. Không có mục tiêu giảm cân; không hiện "được ăn thêm vì đã tập".
- Thông báo trên màn hình khóa chỉ hiện nội dung chung ("Đến giờ uống, 2 loại"), không hiện tên chất.
- Mọi dòng do OCR đọc phải được người dùng xác nhận trước khi lưu.

## Quảng cáo (khi đã bật)

- Chỉ ở màn danh sách, thống kê. Không ở màn cảnh báo, không trong thông báo, widget; không chèn toàn màn hình lúc bấm "Đã uống".
- MVP không có quảng cáo và không chừa chỗ; vị trí quảng cáo thiết kế ở giai đoạn sau. Không bao giờ đặt ở màn Hôm nay.

## Dễ dùng

- Ghi một món hoặc một lần uống trong **tối đa 3 lần chạm** từ màn chính.
- Chữ đọc được khi phóng to cỡ chữ hệ thống tới 200%; vùng chạm tối thiểu 48 dp; độ tương phản đạt WCAG AA; không dùng chỉ màu để truyền nghĩa.
- Chạy được hoàn toàn không cần mạng.
- Mỗi màn có đủ trạng thái: trống (lần đầu), có dữ liệu, đang xử lý, lỗi, cảnh báo.

## Hệ thống thiết kế

- Material 3 qua `package:material_ui`, màu gốc một màu (hiện là teal), hỗ trợ chế độ tối.
- Bộ thành phần dùng chung đặt trong `app/lib/ui/common/` khi bắt đầu làm lại giao diện: thẻ chỉ số, thanh tiến độ có nhãn, thẻ cảnh báo, dòng vi chất.
- Mockup trực quan (nếu cần) làm ở Figma hoặc Claude Design; tệp thiết kế trong repo vẫn là bản chính (wireframe + nội dung chữ).
