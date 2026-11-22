# Công cụ cần cho dự án

Từ bây giờ đến khi phát hành và có doanh thu quảng cáo. Ưu tiên công cụ miễn phí; chỗ nào phải trả tiền đều ghi rõ.
Tra cứu ngày 22/11/2026, giá và điều kiện có thể đổi.

## Theo từng giai đoạn

| Giai đoạn | Cần có | Chi phí | Dùng để |
|---|---|---|---|
| **Luôn dùng** | GitHub (repo này, Issues, Projects, Actions) | Miễn phí | Lưu mọi thứ của dự án, theo dõi việc, CI |
| | Claude (plan, code, review) | Gói bạn đang dùng | Viết, kiểm tra plan và code theo từng bước SDLC |
| **Phát triển** | Flutter SDK (kênh stable), Dart | Miễn phí | App và engine |
| | Android Studio (Android SDK, máy ảo, JDK) | Miễn phí | Build, chạy, ký bản Android |
| | VS Code + extension Flutter, Dart | Miễn phí | Soạn code |
| | Python 3 | Miễn phí | `tools/`: sinh và kiểm tra gói dữ liệu |
| | Máy Mac + Xcode | Mua máy nếu chưa có | Bắt buộc để chạy thử và ký bản iOS, macOS. Codemagic build được iOS trên máy Mac của họ, nhưng vẫn cần iPhone thật để thử |
| **Thiết bị thử** | Android tầm trung, Android 12 trở lên | Có sẵn | Nhận dạng giọng nói tiếng Việt (chế độ Basic), OCR, thông báo, pin |
| | Android có Gemini Nano (Pixel 10 hoặc máy chip Snapdragon, Exynos đầu bảng) | Có sẵn hoặc mượn | AI trên máy, giọng nói chế độ Advanced |
| | iPhone có Apple Intelligence, iOS 26.1 trở lên | Khi làm bản iOS | Foundation Models tiếng Việt, OCR, sao lưu chéo nền tảng |
| **Dữ liệu** | USDA FoodData Central (tải về), NIH DSLD | Miễn phí, CC0 | Thành phần thực phẩm, nhãn bổ sung |
| | NIH ODS, NASEM, Linus Pauling Institute, 2024 Compendium | Miễn phí | Số liệu RDA, UL, EER, AMDR, ODA, MET (chỉ lưu số, có nguồn) |
| **Chất lượng** | `dart test`, `flutter test`, `integration_test`, `dart analyze` | Miễn phí | Kiểm engine (0 vi phạm UL, 0 lỗi đơn vị), giao diện, luồng chính |
| | GitHub Actions | Miễn phí trong hạn mức | Chạy test và kiểm gói dữ liệu ở mỗi lần push |
| | Dependabot, secret scanning của GitHub | Miễn phí | Cảnh báo gói phụ thuộc có lỗ hổng, lộ khóa |
| **Thiết kế** | Figma bản miễn phí hoặc Claude Design | Miễn phí | Mockup màn hình, ảnh cửa hàng |
| | flutter_launcher_icons | Miễn phí | Icon app cho mọi nền tảng |
| **Phát hành** | Google Play Console | 25 USD một lần | Phát hành Android. Tài khoản cá nhân mới phải chạy thử kín với ít nhất 12 người liên tục 14 ngày trước khi xin phát hành chính thức |
| | Apple Developer Program | 99 USD mỗi năm | Phát hành iOS, macOS |
| | Codemagic hoặc fastlane | Codemagic: 500 phút build macOS miễn phí mỗi tháng (tài khoản cá nhân); fastlane miễn phí | Build, ký, đẩy lên cửa hàng tự động |
| | GitHub Pages | Miễn phí | Trang chính sách quyền riêng tư, hỗ trợ, điều khoản (cửa hàng bắt buộc có) |
| **Quảng cáo, doanh thu** | Google AdMob + plugin `google_mobile_ads` | Miễn phí | Hiển thị quảng cáo, nhận tiền |
| | Website nhà phát triển + tệp `app-ads.txt` ở gốc tên miền | Tên miền riêng, khoảng vài trăm nghìn đồng/năm | AdMob dùng tên miền khai trên cửa hàng để xác minh chủ app. Nên dùng tên miền riêng trỏ về GitHub Pages; tên miền con kiểu `*.github.io` có thể không được chấp nhận |
| | UMP (User Messaging Platform) của Google | Miễn phí | Hỏi đồng ý quảng cáo cá nhân hóa; iOS cần thêm hộp thoại App Tracking Transparency |
| | Thông tin thuế, tài khoản ngân hàng trong AdMob | Miễn phí | Nhận thanh toán |
| **Vận hành** | Android vitals (Play Console), số liệu và báo lỗi của App Store Connect | Miễn phí | Theo dõi crash, ANR mà không nhúng SDK phân tích vào app (đúng plan) |
| | GitHub Issues + email hỗ trợ | Miễn phí | Nhận phản hồi, báo lỗi |

## Chi phí tối thiểu

- **Chỉ Android:** 25 USD (Play Console), cộng tên miền.
- **Thêm iOS, macOS:** cộng 99 USD mỗi năm và một máy Mac.

## Việc cần chuẩn bị sớm

1. **Tìm 15–20 người thử Android** trước khi xong MVP, vì quy định 12 người trong 14 ngày liên tục.
2. **Tạo một dự án Google Cloud duy nhất** cho mọi client ID (Android, iOS, desktop), để bản sao lưu Drive dùng chung được.
3. **Mua tên miền**, dựng trang chính sách và đặt `app-ads.txt` trước khi bật quảng cáo.
4. **Mượn hoặc mua máy có Gemini Nano** để thử AI trên máy tiếng Việt sớm, vì đây là điểm rủi ro lớn nhất trên Android.

## Nguồn

- [Yêu cầu thử nghiệm cho tài khoản cá nhân mới – Google Play](https://support.google.com/googleplay/android-developer/answer/14151465)
- [Bảng giá Codemagic](https://docs.codemagic.io/billing/pricing/)
- [Thiết lập app-ads.txt – AdMob](https://support.google.com/admob/answer/9363762)
