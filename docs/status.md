# Trạng thái dự án

Cập nhật 24/11/2026. Agent cập nhật tệp này khi xong một việc.

## Đã xong

- **Plan** ([plan.md](plan.md)), danh sách công cụ ([tools.md](tools.md)), quy trình đặc tả → UX → test → code có cổng duyệt ([AGENTS.md](../AGENTS.md)), mẫu đặc tả và thiết kế, nguyên tắc thiết kế.
- **Gói dữ liệu** (`tools/build_pack.py`): 40 chất × 16 nhóm (14–18 đến >70, mang thai, cho con bú), UL đúng phạm vi, EER 2023 (người lớn, mang thai quý 2–3, cho con bú), AMDR, giới hạn đường bổ sung mỗi bữa, 57 hoạt động có MET, hệ số đổi IU; 102 ô đối chiếu qua.
- **Engine Dart** (`packages/health_engine`): nhóm DRI, mục tiêu RDA/AI, cờ UL trong ngày và trung bình 7 ngày, EER, tỷ lệ đạm/béo/bột đường, đường bổ sung, calo buổi tập, phút vừa/mạnh, gợi ý mức vận động, đổi đơn vị. Test qua CI.
- **App Flutter khung tạm** (`app/`, chưa qua thiết kế UX): hồ sơ, nhật ký ăn, bổ sung, buổi tập, tổng kết ngày, ẩn số calo; lưu trong bộ nhớ.
- **CI** GitHub Actions; build APK debug. **Thư mục Android** (`vn.wholewell.app`).
- **Thiết kế UX tổng thể** ([design/mvp-overview.md](design/mvp-overview.md)): **đã duyệt** 24/11/2026.
- **Kiểm nguồn qua Claude in Chrome** (23/11/2026): 9 fact sheet NIH ODS cho quy tắc lịch; USDA FPED là U.S. Public Domain; link Physical Activity Guidelines (trang 8) và eCFR 21 CFR 101 đúng. Ngày 24/11/2026: fact sheet magie của NIH ODS (cập nhật 6/1/2026) và bài magie của LPI (duyệt 10/2025) vẫn ghi mức khuyến nghị 310–420 mg, giới hạn 350 mg từ bổ sung.

Kết quả kiểm sớm bằng tài liệu và các bài còn phải thử trên máy thật: [plan.md](plan.md), mục 6.

## Việc tiếp theo (theo thứ tự)

Mỗi việc cần đặc tả (và thiết kế UX nếu có giao diện) đã duyệt trước khi code.

1. **CSDL mã hóa** (đặc tả [specs/encrypted-db.md](specs/encrypted-db.md): **đã duyệt** 24/11/2026; không cần UX; **đang code** ở nhánh `feat/encrypted-db-v1`: gói `packages/journal_db`, khóa Android, app dùng CSDL; còn thử trên máy thật): drift + SQLite3MultipleCiphers (cipher `chacha20`, khóa thô, kiểm bản mã hóa mỗi lần mở); khóa đọc ra bốn trạng thái, không bao giờ tự ghi đè; loại khỏi sao lưu tự động của hệ điều hành; thay `InMemoryJournalRepository`. Lược đồ:
   - Khóa chỉ dùng được khi máy đã mở khóa: iOS dùng mức Keychain tương ứng; Android tự dùng Keystore với `setUnlockedDeviceRequired` (API 28+), flutter_secure_storage không có sẵn. Nút "Đã uống" trên thông báo mở app thay vì ghi trong nền. Thử trên máy thật.
   - Dấu "cần xóa bản trên Drive" lưu ngoài CSDL, không có dữ liệu sức khỏe; xóa xong bản trên Drive thì thu hồi quyền đăng nhập Google và xóa dấu.
   - Hồ sơ: số tuổi kèm ngày nhập; giờ thức, ba bữa, giờ ngủ; bằng chứng đồng ý (ngày giờ, phiên bản nội dung); câu trả lời Có/Không về thuốc theo chỉ định, bệnh mạn tính (chế độ thận trọng) kèm ngày.
   - Sản phẩm → nhiều thành phần {chất (id trong gói hoặc tên tự do), dạng hoặc "nhãn không ghi", lượng mỗi khẩu phần, đơn vị gốc, lượng gốc trên nhãn, nguyên tố hay hợp chất, nguồn dòng, đã xác nhận}; nhiều hộp (còn lại, hạn dùng).
   - Nhật ký (món, lần uống, nước, buổi tập); mỗi lần ghi lưu danh sách dòng chất (nguồn, dạng, lượng so mức khuyến nghị, lượng tính giới hạn, số trên nhãn) kèm dữ liệu gốc.
   - Lịch uống có ngày hiệu lực; trạng thái từng lần (đã uống, bỏ qua); trừ kho ghi theo từng hộp; sản phẩm có đơn vị đếm và số đơn vị mỗi khẩu phần.
2. **Sửa engine** (đặc tả; **phải xong trước mọi đường ghi có thể sinh lượng tính giới hạn riêng**: Nhập theo nhãn, Ghi một lần, chụp nhãn, mã vạch, tức trước việc 3; xem đặc tả CSDL, mục Lượng đã ghi). Mỗi thay đổi sửa cả `tools/reference_engine.py` và sinh lại fixtures:
   - Nhóm tham chiếu là dữ liệu: bỏ mốc tuổi viết cứng (`driGroupFor` dùng 14, 19; đạm và AMDR dùng 19); tuổi tối thiểu tạo hồ sơ đọc từ gói.
   - Gần mốc đổi nhóm tuổi (12 tháng trước 19, 31, 51, 71): giới hạn lấy mức thấp hơn của hai nhóm.
   - Đường bổ sung: giới hạn 10 g theo từng bữa chính; món bữa phụ cách món phụ ngay trước dưới 30 phút thì vào cùng bữa (nối chuỗi).
   - Trả đủ các loại cờ mỗi chất (hiện `dailyReport` chỉ giữ một), mỗi cờ kèm lượng vượt và % so với giới hạn; cờ tính cho ngày được chọn; trung bình 7 ngày nhận danh sách ngày có ghi và trả số ngày.
   - Mỗi chất trả cả hai tổng: tổng mọi nguồn (so mức khuyến nghị) và phần tính vào giới hạn theo phạm vi, kể cả khi chưa vượt.
   - Đường bổ sung: trả danh sách món "chưa rõ đường bổ sung".
   - Nhận thành phần theo từng dòng (chất, dạng); dạng chưa rõ trả hai số (tính giới hạn thận trọng, so mức khuyến nghị "chưa chắc"). `IntakeItem` thêm bảng lượng tính giới hạn tùy chọn, `amountForUl` dùng khi có (xem đặc tả CSDL, mục Lượng đã ghi).
   - **Sửa lỗi vitamin E tổng hợp:** giới hạn áp cho mọi dạng alpha-tocopherol bổ sung (1.000 mg ≈ 1.100 IU tổng hợp, ≈ 1.500 IU tự nhiên theo NIH ODS), nhưng gói và engine đang dùng 0,45 mg/IU cho cả phía giới hạn nên tính thiếu khoảng một nửa. Thêm hệ số tính giới hạn riêng vào `build_pack.py` sau khi đối chiếu báo cáo DRI gốc, kèm ô đối chiếu và ca test.
   - Vận động: thêm số của Physical Activity Guidelines vào `build_pack.py`, đánh dấu hoạt động tập tăng cơ; trả phút tương đương vừa và số ngày tập tăng cơ.
3. **Thư viện món** (đặc tả + UX): nhập USDA FoodData Central (Foundation, SR Legacy, FNDDS) vào gói; đường bổ sung từ USDA FPED; trường axit folic, vitamin E bổ sung của USDA; danh sách món Việt không có trong USDA.
4. **Điều kiện dùng app, chế độ thận trọng** (màn trước màn đồng ý, câu trong Hồ sơ) và nhập nước.
5. **Chụp nhãn, mã vạch, kho, hạn dùng** (thử OCR trên máy thật trước): tỷ lệ nguyên tố của hợp chất theo NIH ODS vào `build_pack.py` kèm ô đối chiếu; xác nhận từng dòng.
6. **Lịch uống, nhắc giờ Android, nút "Đã uống"**: kiểm giới hạn theo lịch; 5 quy tắc lịch (plan, mục 4) lưu dưới dạng dữ liệu trong gói, kèm câu hiện cho người dùng (dùng cho lưu ý lịch và thẻ "Bạn có biết"); gắn lần ghi với lần uống theo lịch (khung ±2 giờ theo lịch của ngày được chọn, xét cả lần của ngày trước có khung qua nửa đêm, tính lại khi đổi giờ hoặc ngày); lần uống luôn tính vào giới hạn dù kho hết; nội dung lưu kèm lịch nhắc chỉ có mã lần uống (thư viện nhắc giờ lưu ngoài CSDL mã hóa); Android tự gỡ thông báo khi hết khung.
7. **Sao lưu:** tệp mã hóa trước, Google Drive sau (khi đó mới tạo dự án Google Cloud).
8. **Cổng 2:** kiểm thử an toàn, bảng tự kiểm pháp lý, chính sách quyền riêng tư, lời văn màn đồng ý, thử nghiệm kín 12 người × 14 ngày.

## Để sau MVP (giai đoạn 2)

- **Trẻ em từ 1 tuổi** (plan, mục 2): thêm nhóm 1–3, 4–8, nam và nữ 9–13 vào gói kèm ô đối chiếu; phương trình EER trẻ em (NASEM 2023); hồ sơ do phụ huynh quản lý (cùng nhiều hồ sơ trên một máy), đồng ý thay con; rà pháp lý dữ liệu trẻ em.
- **Mang thai, cho con bú** (chế độ thận trọng): engine nhận cân nặng trước khi mang thai (kg) và tự tính phân loại; cho con bú thiếu tháng sau sinh thì trả `NotComputed` (hiện đang mặc định 0); lược đồ thêm tuần thai, tháng sau sinh kèm ngày nhập.
