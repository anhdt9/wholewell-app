# Trạng thái dự án

Cập nhật 23/11/2026. Agent cập nhật tệp này khi xong một việc.

## Đã xong

- **Plan** (`docs/plan.md`), danh sách công cụ (`docs/tools.md`).
- **Gói dữ liệu** (`tools/build_pack.py`): 40 chất × 16 nhóm (14–18 đến >70, mang thai, cho con bú), UL đúng phạm vi, phương trình EER 2023 (người lớn, mang thai quý 2–3, cho con bú), AMDR, giới hạn đường bổ sung, 57 hoạt động có MET, hệ số đổi IU. 102 ô đối chiếu bảng gốc qua.
- **Engine Dart** (`packages/health_engine`): nhóm DRI, mục tiêu RDA/AI, cờ UL theo ngày và trung bình 7 ngày, EER, tỷ lệ đạm/béo/bột đường, đường bổ sung theo ngày và theo bữa, calo buổi tập, phút vừa/mạnh, gợi ý mức vận động, đổi đơn vị. Test qua CI.
- **MVP Flutter** (`app/`): hồ sơ, nhật ký ăn (nhập tay), bổ sung (đổi IU), buổi tập, tổng kết ngày, ẩn số calo. Lưu trong bộ nhớ (`InMemoryJournalRepository`). Test qua CI.
- **CI** GitHub Actions; build APK debug.
- **Thư mục Android** (mã ứng dụng `vn.wholewell.app`, tên hiển thị WholeWell) – PR #3.
- **Quy trình đặc tả → UX → test → code** có cổng duyệt (AGENTS.md); mẫu `docs/specs/_template.md`, `docs/design/_template.md`, nguyên tắc `docs/design/README.md`.
- **UX tổng thể MVP** (`docs/design/mvp-overview.md`; bản sửa 23/11 đối chiếu với engine **đang chờ duyệt lại**): sơ đồ màn hình, thanh dưới 4 mục, 5 luồng chính, 3 loại cờ giới hạn an toàn (trong ngày, 7 ngày, theo lịch uống), thành phần bổ sung tính theo từng chất và dạng, bộ dữ liệu mẫu chung, bộ thành phần dùng chung. Mọi thiết kế tính năng sau theo khung này.

Lưu ý: màn hình trong `app/lib/ui/` là khung tạm để thử engine, chưa qua thiết kế UX.

### Kiểm sớm bằng tài liệu (chưa thử trên máy thật)

| Điểm | Kết quả | Còn phải thử trên máy |
|---|---|---|
| Giọng nói tiếng Việt trên máy | ML Kit Speech Recognition có vi-VN (beta), Basic: Android 12+; iOS có đọc chính tả trên máy | Độ chính xác với tên món Việt |
| OCR nhãn tiếng Việt | ML Kit Text Recognition v2 hỗ trợ chính thức; iOS Live Text có | 30 nhãn thật |
| AI trên máy | Apple Intelligence có tiếng Việt (iOS 26.1+); Gemini Nano Prompt API chưa công bố tiếng Việt | Chất lượng tiếng Việt của Gemini Nano |
| Sao lưu Drive đa nền tảng | appDataFolder theo dự án Google Cloud | Sao lưu Android → khôi phục iOS |
| Mã vạch | Chưa kiểm được | Quét 50 sản phẩm mua ở Việt Nam |

## Việc tiếp theo (theo thứ tự)

1. **CSDL mã hóa** (thứ tự MVP mục 2; cần đặc tả, không cần UX): drift + SQLite3MultipleCiphers, khóa trong flutter_secure_storage; lược đồ hồ sơ (số tuổi, tuần thai, tháng sau sinh, mỗi số kèm ngày nhập), nhật ký, sản phẩm → nhiều thành phần (chất, dạng, lượng, đơn vị gốc), kho, lịch uống; thay `InMemoryJournalRepository`; loại CSDL khỏi sao lưu tự động của hệ điều hành. Xem mục "Ghi cho đặc tả sau" trong `docs/design/mvp-overview.md`.
2. Từ đây mỗi mục cần **đặc tả + thiết kế UX đã duyệt** trước khi code.
   **Thư viện món:** script nhập USDA FoodData Central (Foundation, SR Legacy, FNDDS) vào gói dữ liệu; tra món, khẩu phần quen thuộc; danh sách món Việt không có trong USDA.
3. **Khảo sát ban đầu** (chỉ hỏi có/không), nhập nước.
4. **Chụp nhãn, mã vạch, kho, hạn dùng** (cần thử OCR trên máy thật trước). Đã chốt trong `docs/design/mvp-overview.md`: đổi hợp chất ra lượng nguyên tố theo tỷ lệ NIH ODS (thêm vào `build_pack.py`), nhãn không ghi dạng thì tính giới hạn theo cách thận trọng nhất.
5. **Lịch uống, nhắc giờ Android, nút "Đã uống"** trên thông báo và trong app. Engine thêm hàm kiểm giới hạn an toàn cho lịch uống, trả đủ các loại cờ mỗi chất (sửa cả `reference_engine.py`).
6. **Sao lưu:** tệp mã hóa trước, Google Drive sau (khi đó mới tạo dự án Google Cloud).
7. Cổng 2: kiểm thử an toàn, bảng tự kiểm tra pháp lý, chính sách quyền riêng tư, thử nghiệm kín 12 người × 14 ngày.

## Còn mở

- Đối chiếu phương trình EER 14–18 (hệ số tuổi của nữ −22,25) để bật mục tiêu calo cho người 18 tuổi.
- Danh sách thực phẩm Việt Nam không có trong USDA.
- Mức tham chiếu vận động (Physical Activity Guidelines của HHS) có trong plan nhưng không có trong bảng chuẩn của AGENTS.md: thêm hay bỏ.
- Kiểm giấy phép USDA FPED (nguồn đường bổ sung cho món FNDDS).
- Trước khi bật quảng cáo: quyết định có đặt ở màn Hôm nay không.
