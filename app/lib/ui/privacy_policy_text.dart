/// Toàn văn Chính sách quyền riêng tư nhúng tĩnh trong app (khớp 100% với docs/privacy-policy.md).
const String kPrivacyPolicyMarkdown = r'''# Chính sách quyền riêng tư — WholeWell

Cập nhật lần cuối: 29/11/2026  
Nhà phát triển: Đặng Thế Anh  
Email liên hệ: wholewell.apps@gmail.com

## 1. Giới thiệu và phạm vi tham chiếu

WholeWell là ứng dụng hỗ trợ người dùng trưởng thành (từ 18 tuổi trở lên trong phiên bản hiện tại) tham chiếu lượng năng lượng, vi chất dinh dưỡng và vận động cá nhân so với các bộ chuẩn dinh dưỡng và vận động công khai của Hoa Kỳ (NASEM, NIH ODS, FDA, HHS, USDA).

WholeWell **không** phải thiết bị y tế, **không** chẩn đoán, **không** kê đơn, **không** gợi ý liều dùng và **không** thay thế tư vấn của bác sĩ hoặc dược sĩ.

## 2. Dữ liệu bạn nhập và mục đích xử lý

Ứng dụng chỉ xử lý những dữ liệu do chính bạn tự nguyện nhập vào trên thiết bị để thực hiện tính toán tham chiếu ngay trên máy:

- **Điều kiện & hồ sơ cơ thể:** số tuổi (tự động cộng 1 mỗi 12 tháng trên máy), giới tính sinh học, chiều cao, cân nặng, mức vận động, khung giờ thức/ngủ/bữa ăn và câu trả lời Có/Không về việc đang dùng thuốc theo chỉ định hoặc có bệnh mạn tính (chế độ thận trọng — ứng dụng **không** hỏi và **không** lưu tên bệnh hay tên thuốc).
- **Nhật ký ăn uống, nước uống & vận động:** món ăn, khẩu phần, lượng nước uống, buổi tập và thời điểm ghi nhận.
- **Thực phẩm bổ sung & lịch uống:** tên sản phẩm, thành phần dinh dưỡng đã được bạn xác nhận, số lượng hộp/hạn dùng, lịch uống và trạng thái đã uống/bỏ qua.
- **Bằng chứng đồng ý:** loại đồng ý (`health_data`, `notifications`, `drive`), phiên bản nội dung và thời điểm bạn xác nhận đồng ý.

WholeWell **không** đọc dữ liệu từ Health Connect, Apple HealthKit, thiết bị đeo, danh bạ hay vị trí của bạn. Camera chỉ dùng khi bạn chủ động chọn quét mã vạch hoặc chụp ảnh nhãn sản phẩm bổ sung; hình ảnh được nhận dạng trực tiếp trên máy bằng ML Kit. Nếu máy đã có sẵn mô hình AI của hệ điều hành (Gemini Nano qua Android AICore), ứng dụng dùng mô hình đó ngay trên máy để gợi ý tách các dòng thành phần từ chữ đọc được trên nhãn; ứng dụng không tự tải mô hình, và ảnh, chữ trên nhãn không được gửi ra khỏi thiết bị. Thành phần chỉ được lưu sau khi bạn kiểm tra, xác nhận từng dòng; mọi con số và cảnh báo do ứng dụng tính theo bộ chuẩn, không do AI quyết định.

## 3. Lưu trữ mã hóa trên thiết bị

- Toàn bộ dữ liệu của bạn được lưu cục bộ trên thiết bị trong cơ sở dữ liệu SQLite mã hóa bằng SQLite3MultipleCiphers (ChaCha20).
- Khóa mã hóa riêng của cơ sở dữ liệu được tạo ngẫu nhiên trên máy và bảo vệ bởi kho khóa của hệ điều hành (Android Keystore yêu cầu thiết bị đã mở khóa).
- Ứng dụng tắt cơ chế sao lưu tự động của hệ điều hành (`allowBackup="false"`, chặn chuyển dữ liệu ngoài ý muốn) để tránh rò rỉ dữ liệu chưa kiểm soát.
- **Thông báo nhắc giờ trên màn hình khóa:** Mặc định thông báo chỉ hiện `"Đến giờ uống"`, không hiển thị tên sản phẩm, tên chất hay liều lượng. Nếu bạn tự bật tùy chọn `"Hiện tên sản phẩm trên thông báo"` trong `Tôi → Nhắc giờ`, tên sản phẩm bổ sung có thể nhìn thấy trên màn hình khóa (ứng dụng vẫn không hiển thị tên chất hay liều lượng).
- WholeWell **không** vận hành máy chủ lưu trữ dữ liệu sức khỏe của bạn. Nhà phát triển không thể xem hay truy cập nhật ký của bạn.

## 4. Quyền của bạn (xem, sửa, xuất, rút đồng ý và xóa)

Theo quy định về bảo vệ dữ liệu cá nhân (bao gồm dữ liệu sức khỏe là dữ liệu cá nhân nhạy cảm), bạn toàn quyền kiểm soát dữ liệu của mình ngay trong ứng dụng:

- **Xem & sửa:** Xem và cập nhật thông tin cá nhân tại `Tôi → Hồ sơ`, hoặc chỉnh sửa từng mục nhật ký ăn, uống, vận động.
- **Xuất dữ liệu đọc được:** Xuất toàn bộ nhật ký sang tệp `.json` tại `Tôi → Quyền riêng tư → Xuất dữ liệu` (ứng dụng luôn cảnh báo trước vì tệp JSON không được mã hóa).
- **Rút đồng ý & Xóa toàn bộ:** Rút đồng ý xử lý dữ liệu hoặc xóa toàn bộ dữ liệu bất cứ lúc nào tại `Tôi → Quyền riêng tư`. Thao tác này xóa ngay khóa mã hóa và mọi tệp dữ liệu trên thiết bị.

## 5. Sao lưu tùy chọn (tệp mã hóa và Google Drive)

- **Sao lưu tệp mã hóa (`.wwbackup`):** Bạn có thể tự xuất tệp sao lưu được mã hóa bằng Argon2id + ChaCha20-Poly1305 thông qua khóa khôi phục 24 ký tự hoặc mật khẩu do chính bạn đặt. Ứng dụng không lưu khóa này.
- **Sao lưu Google Drive (`appDataFolder`, tùy chọn):** Chỉ kích hoạt sau khi bạn đọc giải thích và tự đánh dấu đồng ý riêng. WholeWell chỉ xin phạm vi quyền tối thiểu `https://www.googleapis.com/auth/drive.appdata` để lưu bản sao lưu đã mã hóa Argon2id vào thư mục ẩn riêng của ứng dụng trên Google Drive của bạn, giữ tối đa 3 bản gần nhất và không đọc các tệp khác trên Drive. Google và nhà phát triển không thể đọc nội dung bản sao lưu nếu không có mã khôi phục của bạn.
- Khi rút đồng ý hoặc xóa dữ liệu, bạn có thể chọn xóa cả bản sao lưu trên Google Drive; nếu lúc đó mất kết nối mạng, ứng dụng vẫn xóa ngay dữ liệu trên máy và chỉ lưu một dấu cờ kỹ thuật không chứa dữ liệu sức khỏe để thử xóa nốt bản trên Drive khi có mạng trở lại.

## 6. Không thu thập dữ liệu ngầm, không theo dõi, không quảng cáo

- Phiên bản hiện tại miễn phí hoàn toàn, **không** hiển thị quảng cáo và **không** nhúng SDK quảng cáo.
- Ứng dụng **không** nhúng SDK phân tích hành vi hay thu thập báo lỗi của bên thứ ba; thông số kỹ thuật tổng hợp (nếu có từ Google Play Console) không chứa bất kỳ dữ liệu sức khỏe hay nhật ký cá nhân nào.

## 7. Liên hệ

Nếu có câu hỏi hoặc yêu cầu liên quan đến quyền riêng tư và dữ liệu cá nhân trong ứng dụng WholeWell, vui lòng liên hệ:

- **Nhà phát triển:** Đặng Thế Anh
- **Email:** wholewell.apps@gmail.com
''';
