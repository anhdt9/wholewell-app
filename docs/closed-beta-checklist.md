# Checklist kiểm thử máy thật & Thử nghiệm kín 12 người × 14 ngày (Cổng 2)

Cập nhật: 26/11/2026 · Tổng hợp từ `docs/plan.md` mục 6–7 và `docs/status.md`

## 1. Bài kiểm thử thủ công trên máy thật Android (trước khi mở thử nghiệm kín)

### CSDL mã hóa & Khóa màn hình
- [ ] **BFU (Before First Unlock):** Khởi động lại máy, mở app **trước** khi mở khóa màn hình lần đầu hoặc ngay lúc khóa → không crash, chờ người dùng mở khóa rồi mở bình thường.
- [ ] **Đổi / xóa khóa màn hình:** Thử đổi PIN/mật khẩu màn hình, và thử trường hợp máy tắt khóa màn hình → quan sát `AndroidDbKeyStore` (`KeyLost` / `KeyUnavailable` vs giữ nguyên dữ liệu).
- [ ] **Hiệu năng truy vấn:** Nạp dữ liệu giả lập 2 năm, đo thời gian truy vấn báo cáo 1 ngày < 50 ms.

### Thực phẩm, Nhãn bổ sung (OCR & Mã vạch)
- [ ] **30 ảnh nhãn thật (Việt Nam + hàng nhập):** Chụp/chọn ảnh thật, kiểm tra tốc độ nhận diện ML Kit, kiểm tỷ lệ nhận đúng đơn vị (`IU`, `mg`, `µg`, `DFE`, `NE`, `RAE`) và hợp chất (`carbonate`, `citrate`, `fumarate`, `sulfate`, `gluconate`), bảo đảm **0 dòng chưa xác nhận** lọt vào DB.
- [ ] **50 mã vạch hàng mua tại Việt Nam:** Đo tỷ lệ khớp DSLD / FoodData Central và đường dự phòng chụp nhãn.

### Nhắc giờ & Thông báo Android (ít nhất 7 ngày trên vài hãng: Samsung, Xiaomi, Pixel)
- [ ] **App đã đóng hẳn (cold start):** Bấm `"Đã uống"` trên thông báo → app mở lên (yêu cầu mở khóa nếu màn hình đang khóa) → hiện sheet xác nhận nhanh và trừ kho / kiểm lại UL đúng giờ thực tế.
- [ ] **Reboot & Đổi múi giờ:** Khởi động lại máy (`BOOT_COMPLETED`), đổi múi giờ/giờ hệ thống (`TIME_SET` / `TIMEZONE_CHANGED`) → kiểm tra `ReminderReceiver` lập lại đầy đủ lịch nhắc.
- [ ] **Tiết kiệm pin hãng (Samsung/Xiaomi):** Kiểm tra hành vi khi bị hạn chế nền (báo gần đúng thay exact alarm nếu chưa cấp quyền) và thông báo màn hình khóa **không** hiện tên chất hay tên sản phẩm.

### Sao lưu tệp & Google Drive thật
- [ ] **Xuất & khôi phục `.wwbackup` qua Android SAF:** Xuất sang thư mục Downloads / Google Drive app, xóa dữ liệu, khôi phục lại từ `Chào mừng`, kiểm tra sai mật khẩu giữ nguyên dữ liệu cũ.
- [ ] **Google Drive (`appDataFolder`) với OAuth thật:** Gắn SHA-1 debug/release lên Google Cloud Project duy nhất → đăng nhập → tải lên 4 lần (kiểm tra còn đúng 3 bản) → khôi phục sang máy thứ 2 → thử rút đồng ý lúc bật chế độ máy bay rồi bật lại mạng để xác minh xóa sạch bản Drive qua `FileDrivePendingDeleteStore`.

## 2. Theo dõi thử nghiệm kín (Google Play Closed Testing: tối thiểu 12 người × 14 ngày)

- **Tiêu chí tuyển người thử:** Trưởng thành (≥ 18 tuổi), có cả người ăn thông thường, người uống 1–3 loại bổ sung, và người chú ý ẩn số calo / chế độ thận trọng.
- **Không cần hướng dẫn trực tiếp:** Quan sát xem người thử có tự nhập được bữa ăn, quét/chụp nhãn bổ sung, đặt lịch uống và tự xuất bản sao lưu `.wwbackup` mà không cần chỉ tay hay không.
- **Tiêu chí qua để mở phát hành từng phần:**
  - **0 sự cố ANR / crash không xử lý** liên quan mã hóa DB, Argon2id, OCR hoặc thông báo trên Play Console.
  - **0 phản hồi sai đơn vị / sót cảnh báo UL** sau đối chiếu log mô tả từ người thử.
  - **100% người thử hiểu nút sửa/xuất/xóa** trong `Tôi → Quyền riêng tư`.
