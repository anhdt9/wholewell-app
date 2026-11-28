# AGENTS.md – WholeWell

Tài liệu ngữ cảnh cho mọi agent (Claude Code, Gemini, Antigravity). `CLAUDE.md` và `GEMINI.md` chỉ trỏ về đây.
Plan đầy đủ: [docs/plan.md](docs/plan.md). Trạng thái và việc tiếp theo: [docs/status.md](docs/status.md).

## Giao tiếp

- Trả lời chủ dự án bằng **tiếng Việt, ngắn gọn, đi thẳng vào việc**. Ưu tiên đưa code hoặc tệp hoàn chỉnh thay vì giải thích dài.
- Giao diện app viết bằng tiếng Việt, dùng lời thường ("mục tiêu calo", "giới hạn an toàn"), không hiện tên viết tắt của chuẩn (RDA, UL, EER, AMDR) cho người dùng.

## Sản phẩm (đã chốt, không tự đổi)

- App tham chiếu dinh dưỡng cá nhân hóa cho người Việt, hướng tới **người khỏe mạnh** vì mức khuyến nghị và giới hạn của NASEM dành cho người khỏe mạnh. **MVP:** từ 18 tuổi, không mang thai, không cho con bú; người dùng thuốc theo chỉ định của bác sĩ hoặc có bệnh mạn tính vẫn dùng được ở **chế độ thận trọng** (dòng nhắc chung, ẩn ODA, không điều chỉnh số). **Giai đoạn 2:** trẻ em từ 1 tuổi, mang thai, cho con bú. Dưới 1 tuổi không hỗ trợ. App: so lượng nạp vi chất từ thực phẩm và thực phẩm bổ sung với chuẩn Mỹ, quản lý kho và lịch uống bổ sung, cảnh báo khi vượt mức tối đa an toàn.
- **Không** chẩn đoán, kê đơn, gợi ý liều; không bán, gợi ý hay quảng cáo nhãn hàng bổ sung. Không kiểm tương tác thuốc, xét nghiệm, CGM, gen, vi sinh.
- **Miễn phí toàn bộ.** **Mọi việc liên quan quảng cáo làm ở giai đoạn sau:** MVP không có quảng cáo, không SDK, không chừa chỗ trong bố cục, không interface. Khi làm: chỉ AdMob không cá nhân hóa; **không bao giờ** đặt ở màn Hôm nay, màn cảnh báo, chi tiết chất, thông báo, widget; yêu cầu quảng cáo không chứa dữ liệu sức khỏe.
- Thị trường đầu tiên: Việt Nam. Không thuê chuyên gia, không thuê luật sư: tự đối chiếu văn bản gốc, chỗ không chắc thì bỏ hoặc thu hẹp tính năng.

## Chuẩn tham chiếu (chỉ những chuẩn này)

| Nhóm | Chuẩn | Nguồn |
|---|---|---|
| Vi chất | RDA; chất chưa có RDA dùng AI và ghi "ước tính" | NASEM (báo cáo DRI gốc); NIH ODS để đối chiếu |
| Vi chất | UL (giới hạn an toàn), đúng phạm vi từng chất; cảnh báo khi **vượt** (lớn hơn UL) | NASEM (báo cáo DRI gốc); NIH ODS để đối chiếu |
| Vi chất | ODA, chỉ tham khảo, chỉ bật sau cổng 3 | Linus Pauling Institute |
| Năng lượng | Mục tiêu calo = EER (mức giữ cân), không có mục tiêu giảm cân | NASEM 2023 |
| Năng lượng | Tỷ lệ đạm, béo, bột đường = AMDR | NASEM |
| Năng lượng | Đường bổ sung ≤10 g/bữa (không có giới hạn theo % năng lượng/ngày) | Dietary Guidelines 2025–2030 |
| Vận động | MET | 2024 Adult Compendium |
| Vận động | Người lớn: 150–300 phút vận động vừa hoặc 75–150 phút vận động mạnh mỗi tuần (1 phút mạnh ≈ 2 phút vừa); tập tăng cơ ≥2 ngày/tuần | Physical Activity Guidelines for Americans, bản 2 (HHS) |
| Nhãn | Hệ số đổi đơn vị trên nhãn (IU, DFE, NE, RAE) | FDA (hướng dẫn đổi đơn vị 2019; 21 CFR 101.9, 101.36) |

**Không thêm chuẩn khác** (EAR, CDRR, mức đạm 1,2–1,6 g/kg của Dietary Guidelines…), không dùng dữ liệu Việt Nam, **chỉ theo chuẩn Mỹ**: không dùng EFSA, WHO/FAO hay bộ chuẩn nước khác, kể cả khi giới hạn của họ thận trọng hơn (đã cân nhắc và chốt 23/11/2026). Muốn thêm thì hỏi chủ dự án trước.

## Nguồn và pháp lý

- Chỉ nguồn uy tín, **miễn phí, dùng hợp pháp trong app có quảng cáo**. Nhãn A: cơ quan chính phủ Mỹ (NIH ODS, FDA, USDA, CDC, HHS), số liệu trong báo cáo DRI của NASEM, 2024 Compendium. Nhãn B: LPI (chỉ cho ODA). Không dùng nguồn trả phí, giấy phép NC, dữ liệu cộng đồng (vd. Open Food Facts), ý kiến, video, nội dung quảng cáo.
- **Bài nghiên cứu (PubMed, PMC) không làm nguồn** cho quy tắc hay con số trong app; chỉ để hiểu, giải thích quyết định. **Nguồn không nói rõ thì không có quy tắc** (vd. không có quy tắc canxi–magie).
- **Chỉ lưu con số** theo cấu trúc riêng, kèm nguồn và link. Không chép văn bản hay bố cục bảng của NASEM, LPI. Tự viết lời giải thích.
- **Kiểm nguồn bằng Claude in Chrome** (trình duyệt thật), vì NIH ODS chặn truy cập tự động: mỗi khi thêm hay đổi số, quy tắc, và mỗi quý, agent mở trang nguồn, đối chiếu câu gốc, ghi ngày tra. CI không kiểm link; CI chỉ kiểm mỗi số và quy tắc có đủ link, câu gốc ngắn, ngày tra.
- **Quy tắc lịch là dữ liệu** trong `build_pack.py` (loại, chất, ngưỡng, nguồn); thêm quy tắc cùng loại không sửa code.
- Không dùng tên hay nội dung NIH ODS trong quảng cáo.
- Dữ liệu thực phẩm: USDA FoodData Central (CC0), NIH DSLD (CC0).

## Dữ liệu người dùng và quyền riêng tư

- Mọi dữ liệu ở trên máy, SQLite mã hóa (SQLite3MultipleCiphers qua drift, khóa trong kho khóa của hệ điều hành: Android Keystore, iOS Keychain; xem đặc tả CSDL mã hóa). Không máy chủ, không iCloud, không thiết bị đeo, không Health Connect / HealthKit. Hoạt động do người dùng tự nhập.
- Sao lưu: tệp mã hóa (mặc định); Google Drive appDataFolder là tùy chọn, mã hóa Argon2id, khóa chỉ người dùng giữ. Mọi client OAuth (Android, iOS, desktop) phải nằm trong **một dự án Google Cloud duy nhất**.
- **Gói dữ liệu (số liệu, quy tắc) đi kèm bản cài đã ký**, cập nhật qua cửa hàng ứng dụng; không tải từ máy chủ.
- **Không nhúng SDK phân tích hay báo lỗi** của bên thứ ba. Theo dõi crash qua Play Console / App Store Connect.
- **AI tạo sinh chỉ chạy trên máy** (Gemini Nano qua Android AICore) để gợi ý tách thành phần từ chữ OCR trên nhãn; không gửi dữ liệu ra ngoài; người dùng xác nhận từng dòng; engine quyết định mọi số và cảnh báo (chủ dự án quyết 28/11/2026, thay quy tắc "không dùng AI tạo sinh" ngày 24/11/2026). Chỉ gọi khi mô hình đã có sẵn trên máy, không tự tải mô hình. Lời giải thích viết sẵn theo mẫu. App chỉ dựa vào chuẩn (mức khuyến nghị, giới hạn, ODA), không thêm lưu ý chuyên môn y tế riêng (bệnh, gen, hút thuốc, dị ứng); người nhạy cảm chỉ có dòng nhắc chung của chế độ thận trọng.
- Chỉ dùng dữ liệu giả lập khi phát triển và kiểm thử.

## Cấu trúc repo

```
pubspec.yaml              Pub Workspace gốc (app + packages/*), hooks sqlite3mc, very_good_analysis
pubspec.lock              lock chung, commit
analysis_options.yaml     lint chung cho mọi package
.fvmrc                    ghim Flutter 3.50.1
docs/                     plan.md, refactor-plan.md, architecture.md, adr/, status.md, handoff.md, specs/ (đặc tả), design/ (thiết kế UX + nguyên tắc)
tools/                    Python: nguồn số liệu và kiểm tra
  build_pack.py           NGUỒN SỐ LIỆU DUY NHẤT → sinh reference_pack.json (engine + app)
  verify_pack.py          kiểm cấu trúc + ô đối chiếu bảng NASEM gốc
  reference_engine.py     engine viết lại bằng Python → packages/health_engine/test/fixtures/cases.json
packages/health_engine/   engine thuần Dart (không I/O, không Flutter, không mạng) + test
packages/journal_db/      CSDL mã hóa thuần Dart (drift + SQLite3MultipleCiphers); models.dart chỉ chứa model
packages/food_library/    thư viện món chỉ đọc (SQLite FTS5)
packages/dsld_library/    thư viện bổ sung NIH DSLD chỉ đọc (SQLite FTS5)
app/                      app Flutter (dùng package:material_ui, không dùng package:flutter/material.dart)
.github/workflows/        ci.yml (pack, analyze, test, format, golden), release.yml (tag v*)
```

Cấu trúc đích (thêm `app_core`, `design_system`, `platform_bridge`; `app/lib/` chia `data/`, `domain/`, `ui/<feature>/`): [docs/architecture.md](docs/architecture.md).

## Kiến trúc

Đọc [docs/architecture.md](docs/architecture.md) trước khi viết code; quyết định và lý do trong [docs/adr/](docs/adr/README.md). Đang chuyển dần theo [docs/refactor-plan.md](docs/refactor-plan.md) (đã duyệt 28/11/2026): code mới viết theo kiến trúc đích, code cũ chỉ chuyển trong PR của giai đoạn tương ứng.

- **MVVM:** View → ViewModel (`ChangeNotifier`, `Command`, `Result<T>`) → (use case) → Repository → Service → package. DI bằng `provider`, điều hướng bằng `go_router`, model viết tay, không codegen cho model.
- **Luật phụ thuộc:** repository không import repository khác; service không import repository; ViewModel không import `material_ui`; widget và ViewModel chỉ import `package:journal_db/models.dart`, không import `journal_db.dart`; widget không import `data/`, `mobile_scanner`, `google_mlkit_*`, `image_picker`, không dùng `MethodChannel`; feature không import feature khác. Test kiểm toán `app/test/architecture_rules_test.dart`: danh sách vi phạm chỉ được giảm, không thêm.
- **Đặt tên:** `XViewModel` (`x_view_model.dart`), `XScreen` (`x_screen.dart`), `XRepository`, `XService`, `XUseCase`; widget dùng chung ở `ui/core/`; không trùng tên lớp đã có trong package.

## Lệnh

Repo là **Pub Workspace** (`pubspec.yaml` gốc, một `pubspec.lock` chung ở gốc, commit vào repo). Flutter ghim trong `.fvmrc` (3.50.1); máy dev dùng FVM (`fvm flutter …`, `fvm dart …`) hoặc Flutter đúng bản đó. Package thuần Dart cũng dùng `dart` đi kèm Flutter, không dùng Dart SDK riêng.

```bash
# Phụ thuộc: chạy MỘT lần ở gốc repo, không chạy `dart pub get` trong từng package
flutter pub get

# Gói dữ liệu (chạy mỗi khi sửa tools/ hoặc logic engine)
python tools/build_pack.py && python tools/verify_pack.py && python tools/reference_engine.py

# Định dạng (CI chạy --set-exit-if-changed; độ rộng 120 khai trong analysis_options.yaml)
dart format app packages

# Engine, CSDL mã hóa (test cần SQLite3MultipleCiphers qua build hook), thư viện món, thư viện DSLD
cd packages/health_engine && dart analyze && dart test
cd packages/journal_db && dart analyze && dart test
cd packages/food_library && dart analyze && dart test
cd packages/dsld_library && dart analyze && dart test

# App
cd app && flutter analyze && flutter test && flutter run
```

Test app: dựng trạng thái và màn qua `app/test/helpers/pump_app.dart` (`testAppState`, `pumpApp`), không tự dựng `AppScope`; `pumpApp` kiểm trợ năng, danh sách ngoại lệ chỉ được giảm. Golden test (tag `golden`) chỉ chạy trên Linux; sinh lại ảnh mẫu bằng workflow CI chạy tay với `update_goldens`. Lint: một `analysis_options.yaml` ở gốc cho mọi package (`very_good_analysis` + strict), không thêm tệp lint riêng trong package. `flutter analyze` trong CI thất bại cả với mức info (vd. API đã ngừng dùng), nên phải sạch hoàn toàn. Đổi phụ thuộc thì chạy lại `flutter pub get` ở gốc và commit `pubspec.lock`; CI dùng `--enforce-lockfile`.

## Quy tắc khi sửa code

1. **Số liệu chỉ sửa trong `tools/build_pack.py`**, không sửa tay `reference_pack.json` hay `cases.json`. Mỗi số mới phải có nguồn kiểm được; thêm ô đối chiếu vào `verify_pack.py`. Không đoán số: nếu nguồn chưa rõ, để engine trả `NotComputed` kèm lý do.
2. **Đổi logic engine thì đổi cả `tools/reference_engine.py`** và sinh lại fixtures; test Dart so với kết quả Python.
3. Tiêu chí bắt buộc: **0 vi phạm UL, 0 lỗi đơn vị**. UL đúng phạm vi: magie chỉ tính bổ sung; niacin, vitamin E chỉ tính từ bổ sung + thực phẩm tăng cường (theo nguồn, kể cả vitamin E tự nhiên trong viên); vitamin A chỉ retinol; folate chỉ axit folic. Thành phần bổ sung tính theo từng chất và dạng; dạng chưa rõ thì tính giới hạn theo cách thận trọng nhất.
4. Engine không gọi nền tảng. Giao diện và ViewModel chỉ tới phần phụ thuộc nền tảng qua service (`app/lib/data/services/`): `JournalDbService`, `NotificationService`, `OcrService`, `LabelAiService`, `BarcodeService`, `DriveService`, `BackupFileService`; khóa an toàn, lưu/chọn tệp, mở cài đặt qua plugin `platform_bridge`. Giai đoạn sau thêm `BackgroundJobs`, `SpeechInput`, `HomeWidgetBridge` (`AdService` chỉ thêm ở giai đoạn có quảng cáo). Mỗi interface có bản giả để test (`app/testing/fakes/`). Tới khi chuyển xong (PR 4a, 4b, 5a-2), interface cũ trong `app/lib/platform/` (`NotificationScheduler`, `OcrEngine`, `BarcodeScanner`, `GoogleAuth`, `BackupProvider`, `BackupFileProvider`) và `SecureKeyStore` của `journal_db` vẫn dùng, mỗi cái có bản giả.
5. **Không code tính năng khi chưa có đặc tả và thiết kế UX đã duyệt** (xem mục "Quy trình bắt buộc" bên dưới). Chủ dự án duyệt và gộp; agent không tự gộp vào `main`, không tự phát hành.
6. Commit nhỏ, thông điệp tiếng Việt, mô tả việc đã làm.
7. Xong việc nào thì cập nhật `docs/status.md` trong cùng PR.

## Quy trình bắt buộc cho mỗi tính năng

Agent **dừng lại chờ chủ dự án duyệt** ở cuối bước 1 và bước 2. Không gộp các bước, không làm trước bước sau.

| Bước | Đầu ra | Dừng chờ duyệt |
|---|---|---|
| 1. Đặc tả | `docs/specs/<tính-năng>.md` theo `_template.md`: mục tiêu, ràng buộc, nguồn, thiết kế kỹ thuật (dữ liệu, interface, luồng xử lý), tiêu chí đạt, ngoài phạm vi | **Có** |
| 2. Thiết kế UX | `docs/design/<tính-năng>.md` theo `docs/design/_template.md`: luồng người dùng, danh sách màn hình, wireframe từng màn (ASCII hoặc Mermaid), mọi trạng thái (trống, đang tải, lỗi, cảnh báo), nội dung chữ tiếng Việt; tuân `docs/design/README.md` | **Có** |
| 3. Test | Chuyển tiêu chí đạt thành test (engine: thêm vào `reference_engine.py` và fixtures) | Không |
| 4. Code | Trên nhánh riêng, tới khi test và CI qua | Không |
| 5. PR | Mô tả liên kết đặc tả và thiết kế; chủ dự án duyệt và gộp | **Có** |

- Đặc tả và thiết kế được coi là đã duyệt khi dòng `Trạng thái` ở đầu tệp là `Đã duyệt` (chủ dự án đổi, hoặc agent đổi sau khi chủ dự án nói rõ "duyệt").
- Việc không cần bước 1–2: hạ tầng (CI, thư mục nền tảng, nâng phiên bản gói), sửa lỗi nhỏ không đổi giao diện hay hành vi, sửa tài liệu. Ghi rõ trong PR là việc loại này.
- Màn hình trong `app/lib/ui/` hiện tại là **khung tạm** để thử engine, chưa qua thiết kế UX; sẽ làm lại theo thiết kế đã duyệt.
- Khi được giao một tính năng mà chưa có đặc tả, câu trả lời đầu tiên của agent là bản nháp đặc tả, không phải code.

## Giới hạn đã biết

- **MVP chỉ dùng nhóm người lớn.** NASEM xếp người 18 tuổi vào nhóm 14–18, nên app giữ RDA/UL của nhóm này cho người 18 tuổi, nhưng **không có mục tiêu calo** cho tuổi 18 (phương trình EER trẻ em làm ở giai đoạn 2).
- **Đối tượng mở rộng được bằng dữ liệu:** nhóm tham chiếu (tuổi, giới, mang thai, cho con bú) và việc nhóm nào có mục tiêu calo, khoảng AMDR, cách tính đạm được định nghĩa trong gói dữ liệu, không viết cứng mốc tuổi trong engine. Thêm đối tượng = thêm số liệu có nguồn, ô đối chiếu, ca test, chủ dự án duyệt, phát hành bản cập nhật. Hồ sơ dưới 18 tuổi, mang thai, cho con bú: từ giai đoạn 2 (trẻ em do phụ huynh quản lý, sau khi rà pháp lý dữ liệu trẻ em).
- Mang thai, cho con bú: số liệu có sẵn trong gói và engine; MVP không dùng, mở ở giai đoạn 2 với chế độ thận trọng (chốt 24/11/2026).
- Gợi ý mức vận động từ buổi tập là **quy tắc của app**, không phải chuẩn (phút tương đương vừa/ngày: ≥30 nhẹ, ≥60 vừa, ≥120 nhiều); người dùng tự xác nhận.
