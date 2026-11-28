# Bàn giao công việc

Cập nhật 28/11/2026. Dành cho người (hoặc agent) nhận tiếp dự án WholeWell. Đọc theo thứ tự: tệp này → [AGENTS.md](../AGENTS.md) (quy tắc bắt buộc) → [status.md](status.md) (đã xong, việc tiếp theo) → [refactor-plan.md](refactor-plan.md) (việc đang làm) → [plan.md](plan.md) → [design/mvp-overview.md](design/mvp-overview.md).

## 1. Dự án trong một đoạn

App tham chiếu dinh dưỡng, miễn phí, mọi dữ liệu nằm trên máy. App so lượng vi chất từ thức ăn và thực phẩm bổ sung với chuẩn Mỹ (NASEM: RDA/AI, UL, EER, AMDR; Dietary Guidelines 2025–2030 cho đường bổ sung; 2024 Compendium; Physical Activity Guidelines; hệ số đổi đơn vị của FDA). App cũng quản lý kho và lịch uống bổ sung, và cảnh báo khi vượt giới hạn an toàn.

- MVP: người khỏe mạnh từ 18 tuổi, không mang thai, không cho con bú. Người dùng thuốc theo chỉ định hoặc có bệnh mạn tính dùng **chế độ thận trọng**.
- Không máy chủ, không SDK phân tích hay báo lỗi, không quảng cáo.
- **AI tạo sinh chỉ chạy trên máy:** Gemini Nano qua Android AICore (`LabelGenAiExtractor.kt`) gợi ý tách thành phần từ chữ OCR trên nhãn. Chủ dự án quyết giữ tính năng này ngày 28/11/2026. `AGENTS.md` vẫn ghi "Không dùng AI tạo sinh"; dòng này sửa ở PR 0d theo lời đề xuất ở mục 7.2 của [refactor-plan.md](refactor-plan.md). Đừng gỡ tính năng.

## 2. Trạng thái (28/11/2026)

- Mọi việc MVP trong [status.md](status.md) (việc 1–19) đã gộp vào `main`. PR cuối là #44 (A11y 200%, Dark Mode). Không còn PR nào mở; trên remote chỉ còn nhánh `main` và nhánh `docs/refactor-plan` (chứa plan và tệp này).
- **Đang làm: kế hoạch tái cấu trúc** [refactor-plan.md](refactor-plan.md), bản 15, **nháp, chờ chủ dự án duyệt** mục 2 (15 ADR) và mục 5 (lộ trình). Chưa có dòng code nào của tái cấu trúc.
- Còn thử tay trên máy thật: status.md việc 1 (mở app trước lần mở khóa đầu sau khởi động lại, đổi hoặc xóa khóa màn hình, 2 năm dữ liệu) và việc 19 (kiểm thử trực quan, chụp ảnh Store).

## 3. Kế hoạch tái cấu trúc

Mục tiêu: tổ chức lại theo [Flutter App Architecture Guide](https://docs.flutter.dev/app-architecture/guide) (MVVM) để app nhanh hơn và dùng làm khung cho các app Flutter sau. Mọi PR không đổi hành vi, trừ 3 ngoại lệ ở mục 1 của plan.

### 3.1. Đã chốt qua các vòng review, đừng tự đổi lại

Plan qua 15 bản, mỗi bản sửa theo một vòng review của chủ dự án; mục 8 của plan ghi lại từng bản. Những điểm dễ bị đề xuất đổi lại:

- **DI** dùng `provider`. ViewModel tạo bằng `ChangeNotifierProvider(create:)` trong builder của route: không dùng `.value`; route có tham số gắn `ValueKey`.
- **Repository không biết nhau**; phần ghép dữ liệu nằm ở use case hoặc ViewModel. Ngày đang xem ở `ViewedDayRepository` riêng.
- **Kết nối CSDL** do `JournalDbService` giữ. Đây là chỗ lệch có lý do so với guide (guide ghi service *"hold no state"*).
- **Làm mới dữ liệu** (ADR 15):
  - Stream thay đổi theo bảng; `seq` tăng đồng bộ lúc ghi, không đánh số lúc nhận sự kiện.
  - Cache chỉ giữ mục đang có người nghe; mỗi mục chỉ chạy một truy vấn tại một thời điểm.
  - Hàm ghi nhiều câu lệnh phải nằm trong `db.transaction`.
- **Thời gian** dùng `package:clock` và `fake_async`; đổi hết `DateTime.now` trong PR 3a, viết `() => clock.now()`, không dùng tear-off.

### 3.2. Việc tiếp theo, theo thứ tự

1. **Chủ dự án** duyệt mục 2 và mục 5 của plan, quyết các mục 7.2–7.5, tạo keystore và các Android OAuth client (mục 7.4).
2. **Viết bổ sung đặc tả và thiết kế** `label-scan-inventory` cho PR 1 ngay, chỉ là tài liệu, dừng chờ duyệt theo quy trình của `AGENTS.md`. Đặc tả phải chốt sửa cả 6 chỗ mặc định đơn vị `mg` hay chỉ chỗ của AI:
   - [supplement_label_parser.dart:436](../app/lib/state/supplement_label_parser.dart#L436) (đọc kết quả AI)
   - [dsld_ingredient_mapper.dart:144](../app/lib/state/dsld_ingredient_mapper.dart#L144)
   - [label_food_builder.dart:181](../app/lib/state/label_food_builder.dart#L181)
   - [add_supplement_screen.dart:168](../app/lib/ui/add_supplement_screen.dart#L168)
   - [confirm_ingredients_screen.dart:54](../app/lib/ui/confirm_ingredients_screen.dart#L54) và [:68](../app/lib/ui/confirm_ingredients_screen.dart#L68)
3. **PR 0a** (workspace, ghim Flutter 3.50.1 trong `.fvmrc`, mọi job CI dùng Flutter đã ghim, sửa mục "Lệnh" của `AGENTS.md`), rồi **PR 1**, rồi 0b… theo bảng ở mục 5 của plan.

### 3.3. Khi chủ dự án gửi review

Kiểm từng điểm với code và tài liệu gốc trước khi sửa, không nhận ngay. Nhiều vòng có điểm review chưa đúng, ví dụ "guide không yêu cầu service không giữ state", "Session không đọc `settings`", "service đánh số `seq` lúc nhận sự kiện". Chủ dự án muốn kết quả đúng best practice và đúng code hiện tại, không cần làm theo nguyên văn góp ý.

- Nguyên văn guide (trang web hay bị cắt khi đọc tự động):
  `gh api "repos/flutter/website/contents/sites/docs/src/content/app-architecture/guide.md" -H "Accept: application/vnd.github.raw"`
- Mã nguồn package có sẵn trong `~/AppData/Local/Pub/Cache/hosted/pub.dev/`; Flutter SDK ở `C:\SETUP\flutter`.
- Đếm bằng grep thì escape dấu chấm (`DateTime\.now\b`), nếu không sẽ bắt nhầm.

## 4. Quyết định đã chốt (đừng tự đổi)

Chi tiết và lý do ở AGENTS.md, plan.md, đặc tả. Những điểm hay bị hỏi lại:

- **Chỉ chuẩn Mỹ**, không dữ liệu Việt Nam, không EFSA, WHO. Bài nghiên cứu không làm nguồn cho số liệu. Nguồn không nói rõ thì không có quy tắc.
- **Cảnh báo chỉ ghi số:** lượng, giới hạn, mức vượt (đơn vị và %), phạm vi, nguồn đóng góp, kèm dòng "Hỏi bác sĩ hoặc dược sĩ nếu cần."
- **ODA** (Linus Pauling Institute) chỉ để tham khảo, chỉ bật từ giai đoạn 3.
- **Đường bổ sung** chỉ có giới hạn ≤10 g mỗi bữa, không có giới hạn theo % năng lượng.
- **Dạng chưa rõ:** so mức khuyến nghị lấy số nhỏ nhất, tính giới hạn lấy số lớn nhất, ghi "chưa chắc". Đây là quy tắc của app.
- **AI tạo sinh chỉ trên máy**, chỉ để gợi ý; người dùng xác nhận từng dòng, engine quyết định mọi số và cảnh báo. Không lưu tên bệnh, tên thuốc.
- **Lưu sẵn lượng chất mỗi lần ghi**, kèm dữ liệu gốc và `pack_version`.
- **Sửa lịch** có hiệu lực từ hôm nay; nếu hôm nay đã đánh dấu lần uống theo lịch cũ thì từ ngày mai.

## 5. Rủi ro và việc treo

- **Lỗi đơn vị đang chạy trên máy:** AI đọc nhãn mặc định `mg` khi gặp đơn vị lạ, có thể sai 1.000 lần. Sửa ở PR 1 (mục 3.2).
- **Nhắc giờ cho lịch đã kết thúc:** khi người dùng không mở app, chuông vẫn kêu theo danh sách khung giờ cũ, kể cả cho lịch đã kết thúc. Kotlin tự đặt lại chuông mỗi ngày từ danh sách đã lưu ([ReminderReceiver.kt:21-22](../app/android/app/src/main/kotlin/vn/wholewell/app/ReminderReceiver.kt#L21-L22)), mà danh sách không có ngày hiệu lực. Chưa ghi vào status.md (plan hẹn PR 5d ghi); muốn sửa cần đặc tả riêng.
- **Phát hành:** bản release đang ký bằng khóa debug, và `app/build/app/outputs/flutter-apk/app-arm64-v8a-release.apk` nằm trong git. Đổi khóa ký (PR 0f) thì phải thêm Android OAuth client cho SHA-1 mới, và bản đang cài không cài đè được: tạo `.wwbackup`, gỡ, cài bản mới, khôi phục.
- Chưa có iOS (Keychain, Application Support).

## 6. Cách làm việc (thực tế trên máy này)

- **Giao tiếp:** tiếng Việt, ngắn gọn. Giao diện dùng lời thường, không hiện tên viết tắt của chuẩn. Chủ dự án không thích hộp chọn bật lên; chọn mặc định hợp lý rồi liệt kê để duyệt.
- **Git:**
  - Mỗi lúc chỉ một PR mở. Trước khi đẩy lên nhánh của PR, kiểm PR còn mở không (`gh pr view <n> --json state`), vì chủ dự án gộp nhanh.
  - Không đẩy thẳng vào `main`. Agent không tự gộp.
  - Commit bằng tiếng Việt.
- **Máy phát triển (Windows):** Flutter 3.50.1 ở `C:\SETUP\flutter` (plan ghim đúng bản này). Ghi chú cũ ngày 24/11 chưa kiểm lại: Application Control chặn `dart test`; test thuần Dart chạy trực tiếp được bằng `dart test/<tệp>_test.dart`; test cần SQLite3MultipleCiphers chỉ chạy trên CI.
- **Python:** chạy `python -I`. Script sửa nhiều dòng thì ghi ra tệp rồi chạy, vì heredoc trong bash hay lỗi.
- **Kiểm nguồn:** đọc NIH ODS bằng Claude in Chrome, vì trang chặn truy cập tự động. Ghi ngày tra.
- **CI:** xem log bằng `gh api --allow-escape-sequences repos/anhdt9/wholewell-app/actions/jobs/<id>/logs`.
