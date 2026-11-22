# Trạng thái dự án

Cập nhật 23/11/2026. Agent cập nhật tệp này khi xong một việc.

## Đã xong

- **Plan** (`docs/plan.md`), danh sách công cụ (`docs/tools.md`).
- **Gói dữ liệu** (`tools/build_pack.py`): 40 chất × 16 nhóm (14–18 đến >70, mang thai, cho con bú), UL đúng phạm vi, phương trình EER 2023 (người lớn, mang thai quý 2–3, cho con bú), AMDR, giới hạn đường bổ sung, 57 hoạt động có MET, hệ số đổi IU. 102 ô đối chiếu bảng gốc qua.
- **Engine Dart** (`packages/health_engine`): nhóm DRI, mục tiêu RDA/AI, cờ UL theo ngày và trung bình 7 ngày, EER, tỷ lệ đạm/béo/bột đường, đường bổ sung theo ngày và theo bữa, calo buổi tập, phút vừa/mạnh, gợi ý mức vận động, đổi đơn vị. Test qua CI.
- **MVP Flutter** (`app/`): hồ sơ, nhật ký ăn (nhập tay), bổ sung (đổi IU), buổi tập, tổng kết ngày, ẩn số calo. Lưu trong bộ nhớ (`InMemoryJournalRepository`). Test qua CI.
- **CI** GitHub Actions: gói dữ liệu, engine, app (kiểm mã drift đã sinh, analyze, test, build APK debug).
- **Bước 1, chạy trên máy** (PR #3): package `wholewell`, thư mục `android/` với mã ứng dụng `vn.wholewell.app`. Chưa có thư mục Windows (cần Visual Studio).
- **Bước 2, CSDL mã hóa** ([đặc tả](specs/encrypted-db.md)): drift + SQLite3MultipleCiphers, khóa trong flutter_secure_storage qua `SecureKeyStore`; lược đồ phiên bản 1 với 12 bảng; `DriftJournalRepository` thay `InMemoryJournalRepository`; lưu kèm đơn vị; màn báo lỗi khi không mở được dữ liệu; Android tắt sao lưu tự động. 31 test qua trên Windows.

### Kiểm sớm bằng tài liệu (chưa thử trên máy thật)

| Điểm | Kết quả | Còn phải thử trên máy |
|---|---|---|
| Giọng nói tiếng Việt trên máy | ML Kit Speech Recognition có vi-VN (beta), Basic: Android 12+; iOS có đọc chính tả trên máy | Độ chính xác với tên món Việt |
| OCR nhãn tiếng Việt | ML Kit Text Recognition v2 hỗ trợ chính thức; iOS Live Text có | 30 nhãn thật |
| AI trên máy | Apple Intelligence có tiếng Việt (iOS 26.1+); Gemini Nano Prompt API chưa công bố tiếng Việt | Chất lượng tiếng Việt của Gemini Nano |
| Sao lưu Drive đa nền tảng | appDataFolder theo dự án Google Cloud | Sao lưu Android → khôi phục iOS |
| Mã vạch | Chưa kiểm được | Quét 50 sản phẩm mua ở Việt Nam |

## Việc tiếp theo (theo thứ tự)

1. **Chạy trên máy thật:** cài NDK qua Android Studio, chạy trên máy ảo và điện thoại; kiểm CSDL mở được trên Android, đo tốc độ đọc 7 ngày, xác nhận dữ liệu không vào sao lưu (`adb shell bmgr`). Thêm thư mục Windows khi có Visual Studio.
2. **Thư viện món:** script nhập USDA FoodData Central (Foundation, SR Legacy, FNDDS) vào gói dữ liệu; tra món, khẩu phần quen thuộc; danh sách món Việt không có trong USDA.
3. **Khảo sát ban đầu** (chỉ hỏi có/không), nhập nước.
4. **Chụp nhãn, mã vạch, kho, hạn dùng** (cần thử OCR trên máy thật trước).
5. **Lịch uống, nhắc giờ Android, nút "Đã uống"** trên thông báo và trong app.
6. **Sao lưu:** tệp mã hóa trước, Google Drive sau (khi đó mới tạo dự án Google Cloud).
7. Cổng 2: kiểm thử an toàn, bảng tự kiểm tra pháp lý, chính sách quyền riêng tư, thử nghiệm kín 12 người × 14 ngày.

## Còn mở

- **Tuổi trong hồ sơ:** đang lưu số tuổi, sang năm sẽ sai. Đề xuất lưu năm sinh (chờ chủ dự án duyệt).
- **Máy phát triển:** Windows Application Control chặn `sdkmanager` khi Gradle tự cài NDK; cài NDK bằng tay qua Android Studio.
- Đối chiếu phương trình EER 14–18 (hệ số tuổi của nữ −22,25) để bật mục tiêu calo cho người 18 tuổi.
- Danh sách thực phẩm Việt Nam không có trong USDA.
