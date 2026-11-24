# Trạng thái dự án

Cập nhật 24/11/2026. Agent cập nhật tệp này khi xong một việc.

## Đã xong

- **Plan** ([plan.md](plan.md)), danh sách công cụ ([tools.md](tools.md)), quy trình đặc tả → UX → test → code có cổng duyệt ([AGENTS.md](../AGENTS.md)), mẫu đặc tả và thiết kế, nguyên tắc thiết kế.
- **Gói dữ liệu** (`tools/build_pack.py`): 40 chất × 16 nhóm (14–18 đến >70, mang thai, cho con bú), UL đúng phạm vi, EER 2023 (người lớn, mang thai quý 2–3, cho con bú), AMDR, giới hạn đường bổ sung mỗi bữa, 57 hoạt động có MET, hệ số đổi IU; 102 ô đối chiếu qua.
- **Engine Dart** (`packages/health_engine`): nhóm DRI, mục tiêu RDA/AI, cờ UL trong ngày và trung bình 7 ngày, EER, tỷ lệ đạm/béo/bột đường, đường bổ sung, calo buổi tập, phút vừa/mạnh, gợi ý mức vận động, đổi đơn vị. Test qua CI.
- **App Flutter khung tạm** (`app/`, chưa qua thiết kế UX): hồ sơ, nhật ký ăn, bổ sung, buổi tập, tổng kết ngày, ẩn số calo; lưu trong bộ nhớ.
- **CI** GitHub Actions; build APK debug. **Thư mục Android** (`vn.wholewell.app`).
- **Thiết kế UX tổng thể** ([design/mvp-overview.md](design/mvp-overview.md)): **chờ duyệt**.
- **Kiểm nguồn qua Claude in Chrome** (23/11/2026): 9 fact sheet NIH ODS cho quy tắc lịch; USDA FPED là U.S. Public Domain; link Physical Activity Guidelines (trang 8) và eCFR 21 CFR 101 đúng. Ngày 24/11/2026: fact sheet magie của NIH ODS (cập nhật 6/1/2026) và bài magie của LPI (duyệt 10/2025) vẫn ghi mức khuyến nghị 310–420 mg, giới hạn 350 mg từ bổ sung.

Kết quả kiểm sớm bằng tài liệu và các bài còn phải thử trên máy thật: [plan.md](plan.md), mục 6.

## Việc tiếp theo (theo thứ tự)

Mỗi việc cần đặc tả (và thiết kế UX nếu có giao diện) đã duyệt trước khi code.

1. **CSDL mã hóa** (đặc tả, không cần UX): drift + SQLite3MultipleCiphers, khóa trong flutter_secure_storage; loại khỏi sao lưu tự động của hệ điều hành; thay `InMemoryJournalRepository`. Lược đồ:
   - Hồ sơ: số tuổi, tuần thai, tháng sau sinh, mỗi số kèm ngày nhập; cân nặng trước khi mang thai (kg); bằng chứng đồng ý (ngày giờ, phiên bản nội dung).
   - Sản phẩm → nhiều thành phần {chất (id trong gói hoặc tên tự do), dạng hoặc "nhãn không ghi", lượng mỗi khẩu phần, đơn vị gốc, lượng gốc trên nhãn, nguyên tố hay hợp chất, nguồn dòng, đã xác nhận}; hộp (còn lại, hạn dùng).
   - Nhật ký (món, lần uống gắn với lần uống theo lịch nếu có, nước, buổi tập), lịch uống.
2. **Sửa engine** (đặc tả; làm trước hoặc cùng Lịch uống). Mỗi thay đổi sửa cả `tools/reference_engine.py` và sinh lại fixtures:
   - Nhóm tham chiếu là dữ liệu: bỏ mốc tuổi viết cứng (`driGroupFor` dùng 14, 19; đạm và AMDR dùng 19); tuổi tối thiểu tạo hồ sơ đọc từ gói.
   - Trả đủ các loại cờ mỗi chất (hiện `dailyReport` chỉ giữ một), mỗi cờ kèm lượng vượt và % so với giới hạn; trung bình 7 ngày nhận danh sách ngày có ghi và trả số ngày.
   - Mỗi chất trả cả hai tổng: tổng mọi nguồn (so mức khuyến nghị) và phần tính vào giới hạn theo phạm vi, kể cả khi chưa vượt.
   - Đường bổ sung: trả danh sách món "chưa rõ đường bổ sung".
   - Nhận cân nặng trước khi mang thai (kg), tự tính phân loại; cho con bú thiếu tháng sau sinh thì trả `NotComputed` (hiện đang mặc định 0).
   - Nhận thành phần theo từng dòng (chất, dạng); dạng chưa rõ trả hai số (tính giới hạn thận trọng, so mức khuyến nghị "chưa chắc").
   - Vận động: thêm số của Physical Activity Guidelines vào `build_pack.py`, đánh dấu hoạt động tập tăng cơ; trả phút tương đương vừa và số ngày tập tăng cơ.
3. **Thư viện món** (đặc tả + UX): nhập USDA FoodData Central (Foundation, SR Legacy, FNDDS) vào gói; đường bổ sung từ USDA FPED; trường axit folic, vitamin E bổ sung của USDA; danh sách món Việt không có trong USDA.
4. **Khảo sát ban đầu** (câu hỏi có/không, lưu ý an toàn) và nhập nước.
5. **Chụp nhãn, mã vạch, kho, hạn dùng** (thử OCR trên máy thật trước): tỷ lệ nguyên tố của hợp chất theo NIH ODS vào `build_pack.py` kèm ô đối chiếu; xác nhận từng dòng.
6. **Lịch uống, nhắc giờ Android, nút "Đã uống"**: kiểm giới hạn theo lịch; 5 quy tắc lịch (plan, mục 4) lưu dưới dạng dữ liệu trong gói, kèm câu hiện cho người dùng (dùng cho lưu ý lịch và thẻ "Bạn có biết"); gắn lần ghi với lần uống theo lịch.
7. **Sao lưu:** tệp mã hóa trước, Google Drive sau (khi đó mới tạo dự án Google Cloud).
8. **Cổng 2:** kiểm thử an toàn, bảng tự kiểm pháp lý, chính sách quyền riêng tư, lời văn màn đồng ý, thử nghiệm kín 12 người × 14 ngày.
