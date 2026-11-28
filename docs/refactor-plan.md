# Kế hoạch tái cấu trúc theo chuẩn Flutter

Trạng thái: Đã duyệt (28/11/2026), bản 15. Chủ dự án duyệt mục 2 (quyết định kiến trúc), mục 5 (lộ trình) và các quyết định ở mục 7.

## 1. Mục tiêu

1. **WholeWell đúng chuẩn và nhanh:** tổ chức theo [Flutter App Architecture Guide](https://docs.flutter.dev/app-architecture/guide) và [17 khuyến nghị chính thức](https://docs.flutter.dev/app-architecture/recommendations) (đối chiếu ở mục 4). Mọi tối ưu hiệu năng phải có số đo trên máy thật, chạy ở chế độ `--profile`.
2. **Làm khung cho các app Flutter sau:** cấu trúc thư mục, package nền, CI, quy tắc cho agent và mẫu tạo tính năng tách được khỏi phần riêng của WholeWell (dinh dưỡng, gói dữ liệu, chuẩn NASEM, bảng màu).
3. **Không đổi hành vi.** Test hiện có là lưới an toàn. Chỉ có ba ngoại lệ, mỗi ngoại lệ chủ dự án duyệt riêng:
   - **GĐ1:** sửa an toàn khi AI đọc nhãn (đổi chữ hiển thị).
   - **Tiếng Việt cho widget hệ thống (PR 5c):** 9 lời gọi `showDatePicker`/`showTimePicker` đang hiện tiếng Anh vì app chưa khai `localizationsDelegates` (đổi chữ hiển thị).
   - **Đồng bộ nhắc giờ lúc 0 giờ (PR 5d):** chỉ có tác dụng khi app còn chạy lúc 0 giờ, và chỉ đổi kết quả với lịch bắt đầu hoặc kết thúc đúng ngày đó (vd. lịch tới `valid_to`, lịch sửa sang phiên bản mới). Qua 0 giờ chuông vẫn kêu như hiện nay, vì Kotlin tự đặt lại chuông cho ngày hôm sau từ danh sách khung giờ đã lưu ([ReminderReceiver.kt:21-22](../app/android/app/src/main/kotlin/vn/wholewell/app/ReminderReceiver.kt#L21-L22)).
     - **PR 5d không sửa lỗ hổng sau, ghi vào `docs/status.md` để làm sau:** khi người dùng không mở app, chuông vẫn kêu theo danh sách khung giờ cũ, kể cả cho lịch đã kết thúc, vì danh sách không có ngày hiệu lực. Muốn sửa thì phần native phải biết ngày hiệu lực của lịch, hoặc phải có việc chạy nền mỗi ngày (`BackgroundJobs`); đây là tính năng riêng, cần đặc tả.

Ràng buộc của `AGENTS.md` giữ nguyên: không máy chủ, không SDK phân tích hay báo lỗi, không quảng cáo, không Remote Config, dữ liệu mã hóa trên máy.

## 2. Quyết định kiến trúc (ADR, đã duyệt 28/11/2026)

Mỗi lớp chọn **một** giải pháp. Sau khi duyệt, mỗi dòng thành một tệp `docs/adr/NNNN-<tên>.md`.

| # | Lớp | Chọn | Không chọn | Lý do và ghi chú |
|---|---|---|---|---|
| 1 | Kiến trúc | MVVM theo Architecture Guide: View, ViewModel, Repository, Service; use case chỉ khi cần | Clean Architecture nhiều tầng | Mẫu chính thức. Phần tính toán nặng đã là package thuần Dart (`health_engine`) |
| 2 | State | `ChangeNotifier` + `ListenableBuilder`, mỗi màn một ViewModel, `Command` + `Result<T>` | Riverpod, Bloc | Không thêm thư viện quản lý state, chuyển dần từng màn được |
| 3 | DI | **`provider`**, chỉ để lắp phụ thuộc: `MultiProvider` ở gốc, khai trong `config/dependencies.dart` (service → repository). ViewModel của màn tạo trong builder của route, nhận repository qua constructor bằng `context.read()`. Không dùng `context.watch`/`Consumer`: widget nghe ViewModel bằng `ListenableBuilder` | `get_it`, singleton; `InheritedWidget` tự viết | Guide khuyên dùng `provider`, ví dụ Compass của guide dùng nó. Tự viết thì phải làm lại `read`, phạm vi, `dispose`. `provider` chỉ phụ thuộc `flutter/widgets`, không vướng `material_ui` |
| 4 | Điều hướng | `go_router`: route có kiểu, redirect theo trạng thái phiên, mở đúng màn từ thông báo | `Navigator.push` rải rác (51 chỗ) | **Thử trước** với `material_ui` (PR 5b) |
| 5 | Model | Class bất biến viết tay, `sealed`/`final class`, record | `freezed`, `built_value`, codegen cho model | Lệch khuyến nghị "Recommend" của guide, có lý do: không có `build_runner`, agent không phải đồng bộ tệp sinh. Mã sinh khác vẫn dùng (Pigeon, `gen-l10n`): commit vào repo, CI sinh lại rồi chạy `git diff --exit-code`, như với `reference_pack.json` |
| 6 | Lỗi | `Result<T>` từ repository trở lên; `sealed class AppException` ở tầng dữ liệu | Ném exception xuyên tầng, chuỗi lỗi trong state | UI tự chọn lời hiển thị |
| 7 | CSDL | Giữ drift + SQLite3MultipleCiphers, SQL viết tay, isolate nền | — | Đã duyệt trong `encrypted-db.md` |
| 8 | Thư viện chỉ đọc | Thư viện món và DSLD chạy ở isolate nền | `sqlite3` đồng bộ trên isolate giao diện | Tìm FTS trên 94 nghìn dòng không chặn khung hình |
| 9 | Native interop | **Pigeon**. Phần dùng chung (khóa, lưu/chọn tệp, mở cài đặt) là **Flutter plugin** `platform_bridge` có module Android. Nhắc giờ và AI đọc nhãn là phần riêng của WholeWell, khai Pigeon trong `app/` | `MethodChannel` viết tay; package Dart thuần chứa Pigeon | Mã Kotlin do Pigeon sinh phải nằm trong module Android. Plugin nhận alias và tên tệp khóa làm tham số. WholeWell giữ nguyên alias `wholewell_db_wrap_v1`, tệp `wholewell_db_key.bin` trong `noBackupFilesDir`, và luật loại khỏi sao lưu trong manifest của app (`allowBackup`, `fullBackupContent`, `data_extraction_rules.xml`); đổi một trong số này là mất CSDL trên máy đã cài |
| 10 | Monorepo và phiên bản | Pub Workspaces, một `pubspec.lock` ở gốc (commit). **Ghim Flutter 3.50.1** trong `.fvmrc`; máy dev dùng FVM, CI dùng `flutter-version-file: .fvmrc` (không dùng `pubspec.yaml` vì ở đó là khoảng `>=3.47.0`). Sàn theo `material_ui` 1.11.1: Dart `^3.13.0`, Flutter `>=3.47.0`. `hooks.user_defines` của sqlite3mc khai một lần ở gốc. **Mọi job CI dùng Flutter đã ghim**, kể cả job của package thuần Dart | `channel: stable` không ghim; `setup-dart` | Workspace giải phụ thuộc chung, nên `dart pub get` bằng Dart thuần lỗi vì `app` cần Flutter SDK; Dart của `setup-dart` cũng khác Dart đi kèm Flutter nên lock lệch |
| 11 | Chuỗi và ngôn ngữ | `localizationsDelegates` dùng **`GlobalMaterialLocalizations` của `material_ui`** (không dùng bản của `flutter_localizations`), `locale: vi`. `gen-l10n` (ARB `vi`): chuỗi mới vào ARB, chuỗi cũ chuyển dần theo tính năng | Chuyển hết trong một PR | **Thử trước** cùng `go_router` (PR 5b) |
| 12 | Flavor | `dev` (`vn.wholewell.app.dev`, "WholeWell Dev") và `prod`. Bản dev cần **thêm một Android OAuth client** (package + SHA-1 của khóa debug và khóa ký dev) **trong cùng dự án Google Cloud** | Một bản duy nhất | Thiếu client thì Drive không chạy trên bản dev |
| 13 | Lint | `very_good_analysis` + `strict-casts`/`strict-inference`/`strict-raw-types`, **một `analysis_options.yaml` ở gốc**; CI chạy `dart format --set-exit-if-changed` | `flutter_lints`, `lints`; tệp lint riêng từng package | Analyzer tự tìm tệp ở thư mục cha, nên một tệp áp cho mọi package |
| 14 | Phát hành | Ký bằng keystore lấy từ CI secrets; `--obfuscate --split-debug-info`, lưu symbol vào artifact | Ký bằng khóa debug | Play chấp nhận; đọc được stack trace từ Play Console. Đổi khóa ký thì phải thêm Android OAuth client cho SHA-1 mới, nếu không đăng nhập Drive lỗi (PR 0f) |
| 15 | Làm mới dữ liệu | Stream thay đổi theo bảng: `journal_db` báo tập bảng đã đổi kèm `seq`; `JournalDbService` phát một stream cố định qua mọi kết nối; repository làm mới khi bảng mà truy vấn của nó đọc bị đổi; cache chỉ giữ mục đang có người nghe, mỗi mục nhớ `seq` lúc đọc để bỏ sự kiện cũ; chỉ phát sự kiện khi lần ghi xong (chi tiết ở 3.4) | `watch()` của drift; làm mới thủ công sau mỗi lần ghi | `watch()` cần khai bảng cho drift, mà `journal_db` cố ý không có bảng nào (`allTables` rỗng, SQL viết tay theo ADR 7). Làm mới thủ công thì repository phải biết nhau, vì một lần ghi như `recordDose` đổi dữ liệu của JournalDay, Supplement và Schedule |

## 3. Kiến trúc đích

### 3.1. Repo

```text
pubspec.yaml                 # workspace gốc: name: _, workspace: [app, packages/*], hooks sqlite3mc
pubspec.lock                 # commit
analysis_options.yaml        # lint chung cho mọi package
.fvmrc                       # ghim Flutter 3.50.1
app/                         # app WholeWell; Pigeon riêng (nhắc giờ, AI nhãn), bảng màu WholeWell
packages/
  app_core/                  # [khung] Flutter package chỉ import flutter/foundation: Result, Command, AppException
  design_system/             # [khung] Flutter package: hàm dựng theme nhận bảng màu, spacing/radius, widget dùng chung, data_viz
  platform_bridge/           # [khung] Flutter plugin (Pigeon + Kotlin): khóa an toàn, lưu/chọn tệp, mở cài đặt + bản giả
  health_engine/             # [WholeWell] engine thuần Dart
  journal_db/                # [WholeWell] CSDL mã hóa; thư viện riêng models.dart
  food_library/              # [WholeWell] thư viện món chỉ đọc
  dsld_library/              # [WholeWell] thư viện bổ sung chỉ đọc
tools/perf/                  # script đo hiệu năng trên máy thật
docs/adr/, docs/architecture.md, docs/perf/*.json
```

- Package **[khung]** không import gì riêng của WholeWell. Có test kiểm toán bảo đảm.
- `app_core` là Flutter package vì `Command` là `ChangeNotifier` (nằm trong `flutter/foundation`); test kiểm toán bảo đảm nó không import gì khác của Flutter.
- **Thời gian** dùng [`package:clock`](https://pub.dev/packages/clock) của dart-lang (`clock.now()`), không tự viết lớp `Clock`; hẹn giờ dùng `Timer` thường. Test dùng [`fake_async`](https://pub.dev/packages/fake_async) (dev dependency): nó làm giả cả `Timer` lẫn `clock.now()`, còn widget test vốn chạy trong `FakeAsync` nên `tester.pump(duration)` cũng cho thời gian chạy tới.
  - **Đổi hết trong một PR (3a), không đổi dần.** `fake_async` lấy giờ thật lúc tạo làm mốc rồi cộng thời gian giả đã trôi, và `testWidgets` chạy mỗi test trong một `FakeAsync`. Nếu code còn dùng cả hai đồng hồ thì sau `tester.pump(const Duration(hours: 2))` hay `async.elapse(...)`, `clock.now()` đã tiến còn `DateTime.now()` vẫn là giờ thật: test qua 0 giờ ở PR 5d sẽ lỗi, hoặc qua mà kiểm sai. Trên bản thật thì không lệch, vì ngoài vùng giả lập `clock.now()` bằng `DateTime.now()`.
  - **Phạm vi:** 35 chỗ trong `app/lib`; trong `journal_db`, 13 chỗ của `InMemoryJournalRepository` và giá trị mặc định `DateTime.now` của `DriftJournalRepository`, `DbOpener` ([drift_repository.dart:74](../packages/journal_db/lib/src/drift_repository.dart#L74), [opener.dart:153](../packages/journal_db/lib/src/opener.dart#L153)) đổi thành `() => clock.now()` (`package:clock` thuần Dart nên `journal_db` dùng được); 16 chỗ trong `app/test`. `health_engine`, `food_library`, `dsld_library` không dùng.
  - **Không dùng tear-off `clock.now`.** `clock` là getter, mỗi lần đọc trả về đồng hồ của zone hiện tại. Viết `now ?? clock.now` là lấy hàm `now` của đồng hồ có sẵn lúc tạo đối tượng: nếu đối tượng được tạo ngoài `FakeAsync` (vd. trong `setUp()`, chạy ngoài zone giả của `testWidgets`) thì nó trả giờ thật mãi, `tester.pump(...)` hay `async.elapse(...)` không làm nó tiến. Viết `() => clock.now()` để mỗi lần gọi mới đọc `clock`. Cũng không lưu `clock` vào biến hay trường.
  - **Test kiểm toán** quét `app/lib`, `app/test` và `packages/*/lib`, bỏ qua chính tệp kiểm toán (trong đó có tên các mẫu). Quét cả `app/test` vì nếu không, test mới viết lại `DateTime.now()` thì không ai bắt, và lại lệch đồng hồ khi dùng `pump(duration)`.
  - Cấm ba mẫu. Dấu chấm phải escape, nếu không `.` khớp mọi ký tự và bắt nhầm các tham số `DateTime now`:
    - `DateTime\.now\b`: bắt cả cách viết có ngoặc lẫn không có ngoặc (vd. `now ?? DateTime.now`).
    - `DateTime\.timestamp\b`: hàm này cũng đọc giờ thật (trả giờ UTC). Hiện chưa dùng chỗ nào; cấm để không lách luật được.
    - `\bclock\.now\b(?!\s*\()`: bắt tear-off `clock.now`.
- `design_system` không chứa màu của WholeWell. 29 màu trong `tokens.dart` chuyển thành `WholeWellPalette` trong `app/lib/ui/core/`; app truyền bảng màu này vào hàm dựng theme.

### 3.2. `app/`

```text
lib/
  main_dev.dart, main_prod.dart  # gọi bootstrap(Flavor.x)
  bootstrap.dart                 # tải gói, mở phiên, lắp phụ thuộc, runApp
  config/dependencies.dart       # MultiProvider: service → repository → router → AppCoordinator
  config/app_coordinator.dart    # vòng đời app, thao tác từ thông báo, đồng bộ nhắc giờ
  config/flavor.dart
  data/services/                 # không giữ state nghiệp vụ; mỗi service bọc một nguồn: JournalDbService, NotificationService,
                                 # OcrService, LabelAiService, BarcodeService, DriveService, BackupFileService
  data/repositories/             # abstract interface + bản cài; có cache, nghe thay đổi theo bảng: SessionRepository,
                                 # ViewedDayRepository, JournalDayRepository, CustomFoodRepository, SupplementRepository,
                                 # ScheduleRepository, SettingsRepository, BackupRepository
  domain/use_cases/              # không giữ state; ghép nhiều repository hoặc nhiều ViewModel dùng chung (3.4)
  routing/                       # go_router: builder của route tạo ViewModel; redirect theo SessionStage; đường mở từ thông báo
  ui/core/                       # bảng màu WholeWell, labels, l10n, widget dùng chung của app
  ui/<feature>/view_models/      # <x>_view_model.dart → XViewModel
  ui/<feature>/widgets/          # <x>_screen.dart → XScreen, và widget con của tính năng
  l10n/app_vi.arb
  pigeons/                       # định nghĩa Pigeon riêng của app (nhắc giờ, AI nhãn)
testing/fakes/                   # bản giả của mọi repository và service, dùng chung cho unit test và widget test
test/                            # theo cấu trúc lib/ (data/, domain/, ui/)
```

- **Đặt tên** theo guide: `XViewModel`, `XScreen`, `XRepository`, `XService`, `XUseCase`. Widget dùng chung đặt trong `ui/core/`, không có thư mục `widgets/` chung. Không trùng tên lớp đã có trong package (vd. `FoodLibraryRepository` của `food_library`).
- **Kết nối CSDL do `JournalDbService` giữ.** Kết nối là tài nguyên, không phải state nghiệp vụ, nhưng bị thay giữa chừng: tạo lúc đồng ý lần đầu, thay lúc khôi phục, đóng lúc xóa toàn bộ. Vì repository không được biết nhau, cần một chủ chung ở tầng dưới.
  - `JournalDbService` bọc `DbOpener`, giữ `DriftJournalRepository` hiện tại và phát **một stream `changes` cố định** qua mọi kết nối (3.4).
  - `SessionRepository` gọi service này để mở, tạo, khôi phục, xóa, và giữ `SessionStage` (giống `AuthRepository` của Compass).
  - Các repository khác chỉ phụ thuộc `JournalDbService` và nghe stream cố định đó, nên không phải đăng ký lại khi kết nối đổi. Nhận sự kiện "mọi bảng" (kết nối vừa đổi) thì làm mới mọi mục đang giữ.
- **Ngày đang xem do `ViewedDayRepository` giữ.** Repository này chỉ giữ ngày, trong bộ nhớ như hiện nay, giống `ItineraryConfigRepository` của Compass là một repository riêng.
  - Ngày này không chỉ dùng cho món, nước, buổi tập: `reload()` còn đọc lịch và lần uống của ngày đó ([diary_controller.dart:280-281](../app/lib/state/diary_controller.dart#L280-L281)), câu "Bạn có biết" cũng so với nó ([diary_controller.dart:144](../app/lib/state/diary_controller.dart#L144)).
  - Vì repository không được biết nhau, JournalDay và Schedule nhận `day` làm tham số và cache theo ngày; ViewModel hoặc use case đọc ngày từ `ViewedDayRepository` rồi truyền vào. Settings không nhận `day` (3.4).
- **Vòng đời ViewModel:** builder của route tạo ViewModel bằng `ChangeNotifierProvider(create:, builder:)` của `provider` (ADR 3), nên không cần widget `ViewModelScope` riêng.
  - `create` chỉ chạy một lần khi màn vào cây, kể cả khi builder của route chạy lại (vd. `refreshListenable` của redirect bắn khi `SessionRepository` đổi). `provider` tự hủy ViewModel khi màn rời cây.
  - Dùng `ChangeNotifierProvider(create:)`, **không** dùng `.value`: bản `.value` không tự hủy ViewModel.
  - Route có tham số (vd. chi tiết sản phẩm theo `productId`) gắn `key: ValueKey(productId)` cho provider. Nếu không, khi tham số đổi mà màn vẫn ở cùng chỗ trong cây, `create` không chạy lại và màn giữ ViewModel của sản phẩm cũ.
  - `builder` đọc ViewModel bằng `context.read()` rồi truyền vào màn qua constructor. Màn chỉ nhận `key` và ViewModel, nên test vẫn dựng màn với ViewModel dùng bản giả như Compass.
  - PR 5b kiểm cả hai: builder của route chạy lại thì không tạo ViewModel mới, còn đổi tham số thì có tạo ViewModel mới.
  - Sheet và hộp thoại (24 chỗ) dùng ViewModel của màn mở nó. Sheet có logic hoặc thao tác ghi riêng thì có ViewModel riêng, do ViewModel của màn tạo qua một hàm (vd. `createEditBoxViewModel(boxId)`), vì ViewModel của màn đã có repository còn widget thì không được lấy repository (3.3). Màn gọi hàm này lúc mở sheet và hủy ViewModel con trong `finally` sau khi `showModalBottomSheet` trả về. Không khai sheet thành route của `go_router`: nặng hơn mà không được thêm gì.
- **`AppCoordinator`** (`config/app_coordinator.dart`) giữ các việc ở mức app, không gắn với màn nào, và sống suốt vòng đời app. `dependencies.dart` tạo nó sau router: router cần `SessionRepository` cho redirect, còn `AppCoordinator` cần router để mở màn. Các việc của nó:
  - Vòng đời (`AppLifecycleListener`, chuyển từ `main.dart`): khi quay lại tiền cảnh mà đang ở màn gốc, qua nửa đêm hoặc ở nền quá 5 phút thì đưa ngày đang xem về hôm nay; tự tăng tuổi; đọc lại khóa khi máy vừa mở khóa; thử lại xóa bản trên Drive.
  - Điều kiện "đang ở màn gốc" hiện dựa vào `Navigator.canPop()` ([main.dart:99](../app/lib/main.dart#L99)); sau khi có `go_router` thì đọc vị trí hiện tại của router.
  - Thao tác từ thông báo, cả lúc app đang chạy lẫn lúc khởi động nguội (`takePendingNotificationAction`), mở màn qua `go_router`.
  - Đồng bộ nhắc giờ: nghe Schedule, Supplement, Settings rồi gọi `ReminderSyncUseCase` và hủy khung nhắc đã xử lý. Thay 4 lời gọi `syncNotifications` và 3 lời gọi `cancelWindowIfHandled` đang nằm trong UI.
  - Đổi ngày nghe lúc 0 giờ: "hôm nay" và "hôm qua" thật đổi lúc 0 giờ, mà app đang mở thì không có sự kiện quay lại tiền cảnh nào. `AppCoordinator` hẹn giờ tới mốc 0 giờ kế tiếp, cộng với kiểm lại khi quay lại tiền cảnh.
    - Tính lại mốc 0 giờ sau mỗi lần hẹn, không hẹn chu kỳ 24 giờ, để đúng cả ở nơi có đổi giờ mùa hè (phần khung dùng cho app khác).
    - Dùng `clock.now()` và `Timer` thường; test bằng `fake_async` (3.1).
    - Hẹn giờ chỉ đổi các mục `AppCoordinator` nghe, không đổi ngày đang xem (giữ hành vi hiện nay). Việc đồng bộ lại nhắc giờ lúc 0 giờ là ngoại lệ thứ ba ở mục 1.

### 3.3. Luật phụ thuộc (có test kiểm toán)

```text
ui/<feature>/widgets → ui/<feature>/view_models → (domain/use_cases) → data/repositories → data/services → packages
```

- ViewModel dùng repository trực tiếp; use case chỉ chen giữa khi cần ghép nhiều repository hoặc nhiều ViewModel dùng chung (guide: ViewModel phụ thuộc một hay nhiều use case và một hay nhiều repository).
- **Repository không import repository khác. Service không import repository.** Phần ghép dữ liệu nằm ở use case, ViewModel hoặc `AppCoordinator`.
- Chỉ `routing/` được đọc ViewModel từ `provider`; màn và widget con nhận ViewModel qua constructor.
- ViewModel chỉ phụ thuộc repository trừu tượng và use case; không import `material_ui`, chỉ dùng `foundation`.
- `journal_db` có thêm thư viện **`package:journal_db/models.dart`**, chỉ export model (khoảng 630 dòng: `FoodEntry`, `DoseEntry`, `Product`, `Schedule`, `Meal`…). Widget và ViewModel được import `models.dart`, **không được** import `package:journal_db/journal_db.dart` (mở CSDL, repository, backup). Không re-export lách luật, không chép lại model.
- Widget không import `data/`, `mobile_scanner`, `google_mlkit_*`, `image_picker`, `MethodChannel`.
- Feature này không import feature khác; phần dùng chung đặt trong `ui/core` hoặc `design_system`.
- Hiện 21 tệp UI import `journal_db.dart`. PR 0c chuyển ngay các tệp chỉ dùng model sang `models.dart`; các tệp còn lại vào danh sách vi phạm của test kiểm toán. Danh sách chỉ được giảm, không được thêm.

### 3.4. Luồng dữ liệu và làm mới theo bảng

Phần này là chi tiết của ADR 15; PR 0d chép sang `docs/adr/0015-lam-moi-du-lieu.md` và để lại ở đây các điều kiện bắt buộc.

- **Báo thay đổi theo bảng (mức `journal_db`):** `DriftJournalRepository` đã có `Stream<void> changes` (bắn mỗi lần ghi) nhưng app chưa dùng. Nâng thành `Stream<JournalChange> changes`, mỗi sự kiện gồm `seq` và `tables`:
  - `tables`: đúng tập bảng đã đổi trong lần ghi đó, kể cả trong giao dịch, tính cả bảng bị xóa theo `ON DELETE CASCADE`.
  - `seq`: số thứ tự của kết nối, tăng **đồng bộ** trong `_changed()` trước khi phát sự kiện, nên khi hàm ghi trả về thì `lastChangeSeq` đã tăng.
  - `InMemoryJournalRepository` làm giống hệt.
- **Một stream cố định cho app (mức `JournalDbService`):** repository và `DiaryController` chỉ nghe `JournalDbService.changes`, không nghe thẳng kết nối. `seq` và `lastChangeSeq` cũng đọc từ service.
  - Mỗi kết nối là một **thế hệ**, có `base` = `lastChangeSeq` cũ của service cộng 1. Service đổi `seq` của sự kiện thành `base + seq`, và `lastChangeSeq` của service bằng `base` + `lastChangeSeq` của kết nối hiện tại, đọc đồng bộ. Như vậy `seq` tăng liên tục qua mọi kết nối.
  - **Không đánh số lúc nhận sự kiện.** Stream bất đồng bộ, nên sự kiện của chính lần ghi có thể tới sau khi `reload()` đã đọc `lastChangeSeq`. Nếu đánh số lúc nhận, sự kiện đó mang số lớn hơn số đã nhớ và gây reload thừa.
  - Thay kết nối theo thứ tự: hủy đăng ký kết nối cũ, gắn kết nối mới (thế hệ mới), rồi mới phát sự kiện "mọi bảng" mang số `base`. Service bỏ sự kiện tới muộn của thế hệ cũ.
  - Xóa toàn bộ: kết nối là `null` và service phát "mọi bảng". Repository nhận sự kiện này mà kết nối `null` thì coi là không có dữ liệu, không truy vấn.
- **Cache chỉ giữ mục đang có người nghe:** mỗi mục cache (vd. dữ liệu của một ngày ở JournalDay hay Schedule) phát một `Listenable` riêng cho ViewModel hoặc `AppCoordinator` đăng ký. Người nghe cuối cùng rời đi thì bỏ mục khỏi cache.
  - Repository không cần biết ngày nào đang được xem, chỉ cần biết mục nào đang dùng. Ngày đang xem luôn có ViewModel nghe; lịch của hôm nay và hôm qua thật luôn có `AppCoordinator` nghe (nhắc giờ).
  - Cache vì thế có giới hạn tự nhiên. Quay về một ngày vừa rời thì truy vấn lại ngày đó, vẫn nhẹ hơn hiện nay (`setDay()` chạy lại cả 23 truy vấn của `reload()`).
  - Chỗ chỉ đọc một lần mà không nghe thì truy vấn thẳng, không vào cache. Ví dụ: báo cáo của ngày khác khi sửa món sang ngày đó, báo cáo trước và sau khi ghi lần uống (hiện là `_reportForDay` trong `DiaryController`).
- **Bỏ qua sự kiện cũ bằng `seq`, theo từng mục cache, không dùng cờ:**
  - Mỗi mục cache nhớ `JournalDbService.lastChangeSeq` đọc ngay trước khi truy vấn mục đó. Khi có sự kiện, mục nào đọc bảng bị đổi và có `seq` đã nhớ nhỏ hơn `seq` của sự kiện thì làm mới ngay; mọi mục còn trong cache đều đang có người nghe.
  - Không dùng một số chung cho cả repository. Ví dụ JournalDay cache ngày 27 và 28: làm mới ngày 28 rồi bỏ mọi sự kiện có `seq` nhỏ hơn số đã nhớ thì lần ghi vào ngày 27 cũng bị bỏ, cache ngày 27 giữ số cũ. `DiaryController` chỉ có một bộ dữ liệu nên dùng một số.
  - Lần làm mới đã đọc dữ liệu mới nhất nên không sót gì, và lần ghi của chính nó không gây truy vấn hai lần. Cờ đơn giản không dùng được: stream bất đồng bộ nên sự kiện của chính lần ghi có thể tới sau khi đã làm mới.
- **Mỗi mục chỉ một truy vấn tại một thời điểm:** sự kiện tới khi mục đang truy vấn thì chỉ đánh dấu "cần làm lại"; truy vấn xong thì chạy lại đúng một lần. Như vậy kết quả cũ không đè lên kết quả mới. Code hiện tại tránh việc này bằng số thế hệ `_loadGen` ([diary_controller.dart:265](../app/lib/state/diary_controller.dart#L265), [:321](../app/lib/state/diary_controller.dart#L321)), nhưng cách đó vẫn chạy hai truy vấn song song rồi bỏ kết quả cũ.
  - Lời gọi làm mới (vd. sau khi ghi) chỉ trả về khi một truy vấn **bắt đầu sau lời gọi** đã xong. Nếu không, `LogFoodUseCase` có thể nhận kết quả của truy vấn đang chạy dở và so cờ vượt giới hạn trên số chưa có món vừa ghi.
  - Mỗi mục có cờ `disposed`. Người nghe cuối rời đi khi mục đang truy vấn thì kết quả trả về không được ghi vào cache, không báo cho ai, và mục không chạy lại dù đang mang dấu "cần làm lại"; nếu không, mục sống lại mà không còn người nghe.
  - Lời gọi làm mới đang chờ thì không được treo khi mục bị bỏ (vd. `LogFoodUseCase` đang chờ thì người dùng bấm quay lại). Lời gọi đó vẫn trả về bằng một truy vấn riêng, không ghi vào cache, như luật đọc một lần ở trên. Không trả `Result.error`: bên chờ thường cần số mới để báo vượt giới hạn an toàn sau khi ghi, và UI sẽ phải báo một lỗi không có thật.
  - Test ở 5a-3: sự kiện tới giữa lúc truy vấn; lời gọi làm mới chờ đúng truy vấn bắt đầu sau nó; mục bị bỏ giữa lúc truy vấn; mục bị bỏ khi có lời gọi làm mới đang chờ, lời gọi đó vẫn trả về số mới.
- **Chỉ phát sự kiện khi lần ghi xong:** `_changed()` chỉ chạy khi thân hàm ghi thành công, tức sau khi giao dịch đã xong ([drift_repository.dart:104](../packages/journal_db/lib/src/drift_repository.dart#L104)); không phát theo từng câu lệnh.
  - Hàm ghi nhiều câu lệnh phải nằm trong `db.transaction`, để lần ghi lỗi giữa chừng không để lại dữ liệu ghi dở (vd. lần uống đã ghi mà kho chưa trừ) và không có sự kiện nào. Mọi hàm ghi nhiều câu lệnh trong 43 hàm `write: true` hiện đều theo luật này; test kiểm toán ở 5a-1 giữ luật.
  - Không phát "mọi bảng" khi ghi lỗi: cách đó chỉ làm cache khớp với dữ liệu ghi dở chứ không sửa dữ liệu, và bắt mọi repository truy vấn lại đúng lúc CSDL đang lỗi (vd. máy đầy bộ nhớ).
- **Tự kiểm bằng test:** `sameIsolateExecutor` cố định `setup` ([journal_database.dart:46](../packages/journal_db/lib/src/journal_database.dart#L46)), nên test dùng một `ExecutorFactory` riêng: gọi `setUpConnection` rồi đăng ký `Database.updatesSync` (update hook của SQLite, có trong `sqlite3` 3.9.1; bản sync thu đủ sự kiện ngay sau mỗi lệnh ghi). Với mỗi phương thức ghi, test so tập bảng báo trong `changes` với tập bảng SQLite thực sự đổi, nên bảng ghi dưới đây không thể lệch khỏi code. Test của `JournalDbService` (5a-2) kiểm: thứ tự thay kết nối, bỏ sự kiện của thế hệ cũ, kết nối `null` khi xóa, và khi hàm ghi trả về thì `lastChangeSeq` của service đã tăng.
- **Chặn chỗ update hook không thấy:** SQLite không gọi update hook với bảng `WITHOUT ROWID`, với `DELETE FROM t` không có `WHERE`, và với dòng bị xóa do `REPLACE`. Code hiện chưa dùng trường hợp nào (`ON CONFLICT … DO UPDATE` vẫn được báo). Test kiểm toán quét lược đồ và SQL trong `journal_db`, cấm cả ba, để contract test không bỏ sót mà không báo lỗi.
- **Repository không biết nhau:** mỗi repository giữ cache và chỉ làm mới khi một bảng mà **truy vấn của chính nó đọc** bị đổi; gộp các lần báo trong cùng một microtask thành một lần làm mới. Không repository nào làm mới vì dữ liệu của repository khác.
- **ViewModel** nghe repository, gọi use case khi cần ghép, tính phần dẫn xuất một lần mỗi khi dữ liệu đổi, không tính trong `build()`. Mọi thao tác đi qua `Command`.

**Ghi gì thì đổi bảng nào** (contract test kiểm; PR 5a-1 hoàn thiện cho đủ mọi phương thức ghi):

| Thao tác ghi | Bảng bị đổi |
|---|---|
| Ghi, sửa, xóa món | `food_entries`, `intake_lines` (+ `custom_foods`, `custom_food_lines` khi lưu món) |
| `recordDose` / `updateDose` / xóa liều | `dose_entries`, `intake_lines`, `dose_box_deductions`, `boxes`, `dose_occurrences` |
| Sửa thành phần sản phẩm | `ingredients` |
| Tạo, sửa sản phẩm; thêm, sửa, xóa hộp | `products`, `boxes` |
| Lưu trữ sản phẩm | `products`, `schedules` (kết thúc lịch của sản phẩm) |
| Lịch: thêm, sửa, kết thúc | `schedules` |
| Bỏ qua, xóa đánh dấu, gắn lại lần uống vào lịch | `dose_occurrences` |
| Nước | `water_entries` |
| Buổi tập | `workout_entries` |
| Hồ sơ, chế độ thận trọng | `profile` (+ `consents` khi nâng cấp đồng ý) |
| Tự tăng tuổi | `profile`, `ui_state` (lời nhắc đã tăng tuổi) |
| Giờ trong ngày, ẩn calo, bật câu "Bạn có biết" | `settings` |
| Đồng ý nhắc giờ, đồng ý Drive | `consents` |
| `ui_state` (ẩn câu "Bạn có biết" hôm nay, đã đọc nhắc nhở, thời điểm sao lưu) | `ui_state` |
| Bước onboarding | `meta` |
| Khôi phục bản sao lưu, xóa toàn bộ | tất cả |

**Repository đọc bảng nào** (nháp; PR 5a-3 chốt theo truy vấn thật và khai trong code). Repository làm mới khi tập bảng bị đổi giao với tập bảng nó đọc:

| Repository | Bảng mà truy vấn của nó đọc |
|---|---|
| Session | **Không nghe `changes`**: stage chỉ đổi qua thao tác phiên. Đọc `consents`, `meta`, `profile` và `settings` (cờ ẩn calo, [db_session_controller.dart:96](../app/lib/state/db_session_controller.dart#L96)) khi mở, tạo, nâng cấp đồng ý, xong hồ sơ, khôi phục, xóa. `_syncStageFromRepo` có ghi (`saveHideCalories`, `saveOnboardingStep`), nên phát `changes` và làm Settings làm mới; đúng như mong muốn, contract test tính cả hai lần ghi này |
| ViewedDay | Không đọc CSDL; chỉ giữ ngày đang xem trong bộ nhớ |
| JournalDay | `food_entries`, `dose_entries`, `intake_lines`, `dose_box_deductions`, `water_entries`, `workout_entries` |
| CustomFood | `custom_foods`, `custom_food_lines` |
| Supplement | `products`, `ingredients`, `boxes`; tóm tắt sản phẩm còn đọc `schedules`, `dose_entries`, `intake_lines`, `dose_box_deductions` (lịch đang chạy, mức dùng 14 ngày) |
| Schedule | `schedules`, `dose_occurrences` |
| Settings | `profile`, `consents`, `settings`, `ui_state` |

JournalDay và Schedule nhận `day` làm tham số và cache theo ngày (Schedule giữ ngày đang xem, cùng hôm nay và hôm qua thật cho nhắc giờ); ngày lấy từ ViewedDay do ViewModel hoặc use case truyền vào. Settings không nhận `day` và chỉ có một cache: việc so `hidden_tip_day` với ngày đang xem (câu "Bạn có biết") do ViewModel làm.

**Phần ghép ở use case** (không giữ state; ViewModel hoặc `AppCoordinator` nghe các repository liên quan rồi gọi):

| Use case | Ghép từ | Kết quả, nơi dùng |
|---|---|---|
| `DailyReportUseCase` | JournalDay + Settings (hồ sơ) | Báo cáo ngày và 7 ngày: Hôm nay, Chi tiết chất, phản hồi sau khi ghi |
| `ScheduleSafetyUseCase` | Schedule + Supplement (thành phần) + Settings (giờ bữa, câu "Bạn có biết") | Cờ vượt giới hạn theo lịch, câu nhắc lịch, câu "Bạn có biết" |
| `ReminderSyncUseCase` | Schedule + Supplement (tên sản phẩm) + Settings (đồng ý, tùy chọn hiện tên) | Đồng bộ nhắc giờ; `AppCoordinator` gọi (3.2) |
| `LogFoodUseCase`, `LogDoseUseCase` | JournalDay, Supplement, Schedule + `DailyReportUseCase` | Ghi rồi so cờ trước và sau để ra phản hồi |

### 3.5. Hiệu năng: đo trên máy thật

- **Không** kiểm hiệu năng trong CI: runner Ubuntu không có máy thật, số đo trên máy ảo không có giá trị. CI chỉ kiểm **kích thước APK** (`--analyze-size`, báo lỗi khi vượt ngân sách).
- `tools/perf/run_perf.(ps1|sh)` chạy `integration_test` + `traceAction` ở `--profile` trên S24 Ultra, ghi `docs/perf/<ngày>-<nhánh>.json`.

| Chỉ số | Hiện tại | Mục tiêu |
|---|---|---|
| Khởi động nguội tới Hôm nay (S24 Ultra) | 869–1.048 ms | ≤ 600 ms |
| Lần mở đầu, giải nén thư viện | giải nén nguyên 113 MB trong RAM trên isolate giao diện | không chặn giao diện, RAM đỉnh tăng < 20 MB |
| Dựng khung hình p90 khi cuộn Hôm nay / Nhật ký | chưa đo | < 8 ms (120 Hz) |
| Gõ tìm món / DSLD | chưa đo | không mất khung hình |
| Widget dựng lại khi ghi nước | cả cây | chỉ thẻ Nước và tổng |
| APK arm64 | 70 MB | đặt ngân sách sau khi có mốc |

### 3.6. Test

- **Bản giả và test từng lớp:** mỗi repository và service cấp app là `abstract interface class`, có bản giả trong `app/testing/fakes/`, dùng chung cho unit test và widget test. Unit test cho mọi service, repository, use case và ViewModel; widget test cho mọi màn; `app/test/` theo cấu trúc `lib/`. `InMemoryJournalRepository` vẫn là bản giả ở tầng `journal_db`.
- **Một helper duy nhất** `app/test/helpers/pump_app.dart`. Hiện 14 tệp test tạo `AppState.withRepository`, 8 tệp tự dựng `AppScope` ở 9 chỗ, trong đó 4 tệp có hàm `_wrap` riêng. Khi đổi kiến trúc chỉ sửa helper này.
- **Trợ năng:** `pump_app` kiểm `meetsGuideline` (`androidTapTargetGuideline`, `labeledTapTargetGuideline`, `textContrastGuideline`) cho mọi màn; màn chưa đạt vào danh sách ngoại lệ, danh sách chỉ được giảm.
- **Viết lại test gọi thẳng state cũ:** 66 chỗ gọi `state.diary.*` được viết lại thành test ViewModel dùng bản giả trong PR của từng tính năng, **trước khi** xóa `AppState` (PR 6.9).
- **Golden test** chỉ chạy trên CI Linux (tag `golden`, bỏ qua trên Windows), nạp font `BeVietnamPro` trong `flutter_test_config.dart` để ảnh không lệch.

## 4. Đối chiếu với khuyến nghị chính thức

[17 khuyến nghị](https://docs.flutter.dev/app-architecture/recommendations) của Flutter, kèm mức khuyến nghị:

| # | Khuyến nghị (mức) | Plan |
|---|---|---|
| 1 | Tách rõ lớp dữ liệu và lớp UI (Strongly recommend) | Có: 3.2, 3.3 |
| 2 | Repository pattern: repository + service (Strongly recommend) | Có. **Lệch nhỏ có lý do:** guide ghi service *"hold no state"*, còn `JournalDbService` giữ kết nối CSDL hiện tại, vì kết nối bị thay khi khôi phục hoặc xóa và repository không được biết nhau (3.2). Các service khác không giữ state nghiệp vụ |
| 3 | MVVM ở lớp UI (Strongly recommend) | Có: ADR 1 |
| 4 | `ChangeNotifier`/`Listenable` để cập nhật widget (Conditional) | Có: ADR 2 |
| 5 | Không để logic trong widget (Strongly recommend) | Có: 3.4, 3.3 |
| 6 | Tầng domain (Conditional) | Có, chỉ khi ghép nhiều repository hoặc nhiều ViewModel dùng chung (3.4) |
| 7 | Luồng dữ liệu một chiều (Strongly recommend) | Có: 3.4 |
| 8 | `Command` cho sự kiện từ người dùng (Recommend) | Có: ADR 2, `app_core` |
| 9 | Model bất biến (Strongly recommend) | Có: ADR 5; model của `journal_db` đã dùng trường `final` |
| 10 | Sinh model bằng `freezed`/`built_value` (Recommend) | **Lệch có lý do:** ADR 5 |
| 11 | Tách model API và model domain (Conditional, app lớn) | **Không tách:** dữ liệu chỉ đến từ CSDL trên máy, model của `journal_db/models.dart` đóng vai trò model domain |
| 12 | Dependency injection, dùng `provider` (Strongly recommend) | Có: ADR 3. Compass tạo ViewModel thẳng trong builder của route; plan bọc bằng `ChangeNotifierProvider(create:)` để ViewModel không bị tạo lại khi builder chạy lại (3.2). Chỉ khác ở cách tạo, nguyên tắc giữ nguyên |
| 13 | `go_router` (Recommend) | Có: ADR 4 |
| 14 | Quy ước đặt tên lớp, tệp, thư mục (Recommend) | Có: 3.2 |
| 15 | Repository trừu tượng (Strongly recommend) | Có: 3.2, 3.6 |
| 16 | Test từng lớp và test kết hợp (Strongly recommend) | Có: 3.6 |
| 17 | Bản giả cho test (Strongly recommend) | Có: `app/testing/fakes/` (3.6) |

Mục của cẩm nang tham khảo không áp dụng vì trái `AGENTS.md` hoặc vì app offline:

- **Crashlytics/Sentry, Analytics, Remote Config, Feature Flags:** không. Chỉ ghi log cục bộ qua `FlutterError.onError` / `PlatformDispatcher.onError`; crash xem qua Play Console.
- **Backend proxy, retry mạng, banner mất mạng, deep link web, IAP:** không.
- **`flutter_secure_storage`, `SharedPreferences`:** không; dùng Keystore (đã duyệt) và SQLite mã hóa.
- **5 trạng thái màn:** còn 4 (không có Offline). **CI kiểm hiệu năng:** chỉ kiểm kích thước APK (3.5).

## 5. Lộ trình

Mỗi lần một PR, gộp xong PR trước mới mở PR sau. Bắt đầu từ `main` (nhánh `ui/refresh-p5-a11y-polish` đã gộp ở PR #44).

Bảng xếp theo **thứ tự làm**. PR 1 làm ngay sau 0a, trước phần còn lại của GĐ0: lỗi AI mặc định đơn vị `mg` có thể sai 1.000 lần và đang chạy trên máy. Đặc tả và thiết kế bổ sung cho PR 1 viết ngay từ bây giờ (chỉ là tài liệu), duyệt theo quy trình của `AGENTS.md`.

| GĐ | PR | Nội dung | Cần duyệt? |
|---|---|---|---|
| 0 | 0a | **Workspace và phiên bản:** Pub Workspaces, commit `pubspec.lock`, ghim Flutter 3.50.1 trong `.fvmrc`, sàn Dart `^3.13.0` / Flutter `>=3.47.0`. **Mọi job CI**, kể cả `release.yml`, dùng `flutter-action` với `flutter-version-file: .fvmrc`: `flutter pub get` một lần ở gốc; package thuần Dart chạy `dart analyze` / `dart test`, app vẫn chạy `flutter analyze` / `flutter test`. Sửa mục "Lệnh" của `AGENTS.md` ngay trong PR này (lệnh `cd packages/x && dart pub get` sai ngay khi chuyển sang workspace). Gỡ APK khỏi git; `dart format` trong CI | Không (hạ tầng) |
| 1 | 1 | **An toàn AI đọc nhãn:** đơn vị lạ không còn mặc định `mg`, đối chiếu số AI trả với chữ OCR, không tải mô hình giữa luồng quét | **Có**: bổ sung đặc tả và thiết kế `label-scan-inventory` |
| 0 | 0b | **Lint strict:** `analysis_options.yaml` ở gốc (`very_good_analysis` + `strict-*`, chuyển danh sách rule đang tắt của app lên đây). Khai `very_good_analysis` trong `dev_dependencies` của `pubspec.yaml` gốc; đổi `analyzer.exclude` thành đường dẫn tính từ gốc (`app/build/**`, `app/android/**`). Xóa tệp lint riêng của `app`, `health_engine`, `journal_db`; bỏ `lints`, `flutter_lints`; sửa hết cảnh báo, không đổi hành vi | Không |
| 0 | 0c | **Lưới test:** `pump_app.dart` cho mọi widget test, kèm kiểm `meetsGuideline` (danh sách ngoại lệ chỉ được giảm); hạ tầng golden; thư viện `journal_db/models.dart` và chuyển ngay các tệp UI chỉ dùng model; test kiểm toán luật phụ thuộc với danh sách vi phạm còn lại | Không |
| 0 | 0d | **Tài liệu khung:** `docs/architecture.md`, `docs/adr/` (15 ADR); sửa phần còn lại của `AGENTS.md`: quy tắc AI trên máy, cấu trúc repo, luật phụ thuộc, quy ước đặt tên, và **viết lại quy tắc 4** theo tên service ở 3.2 (hiện ghi `NotificationScheduler`, `OcrEngine`, `BarcodeScanner`, `GoogleAuth`, `BackupProvider`…), giữ câu "mỗi interface có bản giả" và giữ `BackgroundJobs`, `SpeechInput`, `HomeWidgetBridge` cho giai đoạn sau; chính sách quyền riêng tư nhắc AI trên máy | Không (tài liệu) |
| 0 | 0e | **Hiệu năng sớm** (rẻ, không phụ thuộc kiến trúc mới). Commit đầu: `tools/perf/` và số đo mốc trên `main`, trước khi sửa code. Sau đó: chạy `_ensureFoodLibrary()` song song với `diary.reload()` bằng `Future.wait` (ở `start()`, đồng ý lần đầu, nâng cấp đồng ý, khôi phục), thay vì chờ lần lượt; `BundledDbAssetStore` gộp 2 store, gunzip theo luồng, SHA-256 trong `Isolate.run`. Khởi động chỉ mất bằng việc lâu hơn trong hai việc; màn Ghi món không cần trạng thái mới | Không |
| 0 | 0f | **Build và phát hành:** ký bằng secrets, obfuscate + symbol, flavor dev/prod, CI kiểm kích thước APK. **OAuth cho bản prod:** client hiện tại gần như chắc chắn đăng ký SHA-1 của khóa debug (bản ký debug vẫn đăng nhập Drive được), nên phải thêm Android OAuth client cho SHA-1 của upload key, sau này thêm SHA-1 của khóa Play App Signing, cùng client cho bản dev, tất cả trong cùng dự án Google Cloud. Bản `vn.wholewell.app` đang cài ký bằng khóa debug nên không cài đè được (gỡ app là mất khóa Keystore và CSDL): tạo `.wwbackup`, gỡ, cài bản mới, khôi phục | Không. Chủ dự án tạo keystore và các OAuth client |
| 2 | 2 | **Engine:** chuyển logic phạm vi giới hạn an toàn từ app vào `health_engine` + `reference_engine.py`; chuyển `IntakeLine` sang engine; bỏ `?? 1.7` | Không (có ca golden) |
| 3 | 3a | **`app_core`** (Flutter package chỉ import `foundation`): `Result`, `Command`, `AppException` + test. **Đổi toàn bộ sang `clock.now()` trong một lần** (3.1): `app/lib`, `journal_db`, `app/test`, giá trị mặc định viết `() => clock.now()`; kèm test kiểm toán (quét cả `app/test`) cấm `DateTime.now`, `DateTime.timestamp` và tear-off `clock.now`; không đổi hành vi trên bản thật | Không |
| 3 | 3b | **`design_system`:** hàm dựng theme nhận bảng màu, spacing/radius, widget dùng chung, `data_viz`; `WholeWellPalette` ở lại app; golden test sáng/tối, 200% | Không |
| 4 | 4a | **`platform_bridge`** (Flutter plugin, Pigeon): khóa an toàn, lưu/chọn tệp, mở cài đặt + bản giả. Alias và tên tệp khóa là tham số, có test khóa cứng giá trị của WholeWell; tệp khóa vẫn nằm trong `noBackupFilesDir`, luật loại khỏi sao lưu trong manifest của app giữ nguyên (ADR 9). Chuyển test JVM `DbKeyRules` sang module plugin, CI chạy cả test của module này. **Tiêu chí đạt:** cài đè lên bản trước vẫn mở được CSDL (lặp lại bài thử 25/11/2026) | Không |
| 4 | 4b | **Pigeon riêng trong `app/`:** nhắc giờ, AI nhãn. Service: `BarcodeService` (bỏ import `mobile_scanner` khỏi UI), `LabelAiService` | Không |
| 5 | 5a-1 | **Thay đổi theo bảng trong `journal_db`:** `Stream<JournalChange>` (`seq` tăng đồng bộ, `tables`), contract test dùng update hook (kể cả các lần ghi trong `_syncStageFromRepo`), test kiểm toán cấm 3 trường hợp hook không thấy, test kiểm toán hàm ghi nhiều câu lệnh phải nằm trong `db.transaction`, contract test Drift/InMemory | Không |
| 5 | 5a-2 | **Phiên và kết nối:** thêm `provider` và `config/dependencies.dart`; `JournalDbService` với stream `changes` cố định (thế hệ, `base + seq`); `SessionRepository` nhận phần giữ phiên của `DbSessionController` (controller cũ gọi qua nó tới 6.9); bản giả; test của service theo 3.4 | Không |
| 5 | 5a-3 | **Repository và use case:** `ViewedDayRepository`; các repository còn lại (cache theo tập bảng đọc; JournalDay và Schedule cache theo ngày; cache chỉ giữ mục đang có người nghe, mỗi mục nhớ `seq` lúc đọc; đọc một lần thì truy vấn thẳng; nhận "mọi bảng" thì làm mới mọi mục; mỗi mục một truy vấn tại một thời điểm, có cờ `disposed`, kèm test theo 3.4); use case `DailyReport`, `ScheduleSafety`, `ReminderSync`; bản giả, unit test; `DiaryController` nghe `JournalDbService.changes` và dùng `ViewedDayRepository` (mục 6) | Không |
| 5 | 5a-4 | **Thư viện món và DSLD chạy isolate nền** (ADR 8) | Không |
| 5 | 5b | **Thử trước** trên một nhánh thử, báo kết quả: `go_router` + `GlobalMaterialLocalizations` của `material_ui`; builder của route chạy lại (vd. khi `refreshListenable` bắn) không tạo ViewModel mới; route có tham số gắn `ValueKey` thì đổi tham số có tạo ViewModel mới | Không |
| 5 | 5c | **Áp dụng:** `go_router` (builder của route tạo ViewModel, redirect theo `SessionStage`); `locale: vi` + `gen-l10n` | **Có**: duyệt việc đổi chữ bộ chọn ngày/giờ sang tiếng Việt |
| 5 | 5d | **`AppCoordinator`** (3.2): chuyển vòng đời app khỏi `main.dart` và `AppState`, điều kiện "đang ở màn gốc" đọc từ vị trí của router thay cho `Navigator.canPop()`; thao tác từ thông báo (cả khởi động nguội) mở màn qua `go_router`; đồng bộ nhắc giờ qua `ReminderSyncUseCase`, bỏ 4 lời gọi `syncNotifications` và 3 lời gọi `cancelWindowIfHandled` khỏi UI; hẹn giờ đổi ngày nghe lúc 0 giờ (3.2); test bằng bản giả và `fake_async`; ghi lỗ hổng "chuông vẫn kêu cho lịch đã kết thúc khi không mở app" vào `docs/status.md` (mục 1) | **Có**: duyệt việc đồng bộ lại nhắc giờ lúc 0 giờ (ngoại lệ ở mục 1) |
| 6 | 6.1–6.8 | **Chuyển từng tính năng sang MVVM**, theo thứ tự `me` → `backup` → `onboarding` → `diary` → `food` → `schedule` → `supplements` → `today`. `me` dùng để thử mẫu ViewModel/`Command`; `today` gom dữ liệu mọi miền nên làm cuối. Mỗi PR: ViewModel + `Command` (tạo trong builder của route, chỉ nhận repository trừu tượng và use case), viết lại test `state.diary.*` thành test ViewModel dùng bản giả, widget test cho màn, chuỗi mới vào ARB, widget tách tệp, rút tên tệp khỏi danh sách vi phạm | Không |
| 6 | 6.9 | Xóa `AppState`, `DiaryController`, `DbSessionController`, `AppScope`; `bootstrap` + `dependencies.dart` là gốc lắp ghép duy nhất | Không |
| 7 | 7 | **Hiệu năng:** đo lại bằng `tools/perf/`, xử lý chỗ vượt mục tiêu (`RepaintBoundary`, `ListView.builder`, `const`, isolate) | Không |
| 8 | 8 | **Rút khung:** `tools/new_feature.dart` (tạo `XViewModel`, `XScreen`, bản giả, test, ARB), hướng dẫn tách `app_core` + `design_system` + `platform_bridge` + CI + `AGENTS.md` khung | Không |

## 6. Quy tắc trong thời gian chuyển đổi

- Code mới viết theo kiến trúc đích ngay. Code cũ chỉ chuyển trong PR của giai đoạn tương ứng.
- **`AppScope` cũ và `provider` cùng tồn tại từ PR 5a-2 tới 6.9:** màn chưa chuyển vẫn dùng `AppScope`; màn đã chuyển chỉ dùng ViewModel của nó. Trong GĐ6, ViewModel được dùng tạm `AppState` qua lớp chuyển tiếp; lớp này xóa ở PR 6.9.
- **Một ngày đang xem:** từ PR 5a-3, `DiaryController.day` và `setDay` đọc, ghi qua `ViewedDayRepository`, để màn cũ và màn mới không lệch ngày; `AppCoordinator` (5d) cũng vậy.
- **Hai cache song song từ PR 5a-3 tới 6.9** (repository mới và `DiaryController`): `DiaryController` nghe stream cố định của `JournalDbService` và reload, để màn chưa chuyển không hiện số cũ (ví dụ sửa hồ sơ ở `me` đã chuyển, báo cáo trên Hôm nay chưa chuyển). Lần ghi của chính nó vẫn `await reload()` như hiện nay, vì phản hồi sau khi ghi cần số mới, và bỏ sự kiện của chính lần ghi đó theo quy tắc `seq` ở 3.4, nên không chạy 23 truy vấn hai lần.
- Mỗi PR: CI xanh, `flutter analyze` sạch, không đổi hành vi hay chữ hiển thị (trừ 3 ngoại lệ ở mục 1), cập nhật `docs/status.md`. PR chạm hiệu năng thì dán bảng số đo trước và sau (từ `docs/perf/`) vào mô tả PR.

## 7. Quyết định của chủ dự án (28/11/2026)

1. **Đã duyệt** 15 ADR ở mục 2.
2. **Đồng ý** lời mới cho quy tắc AI trong `AGENTS.md` (sửa ở PR 0d):
   > AI tạo sinh chỉ chạy trên máy (Gemini Nano qua Android AICore) để gợi ý tách thành phần từ chữ OCR trên nhãn; không gửi dữ liệu ra ngoài; người dùng xác nhận từng dòng; engine quyết định mọi số và cảnh báo.
3. **Không** viết lại lịch sử git; PR 0a chỉ gỡ APK khỏi git từ nay về sau.
4. **Chủ dự án tự làm, cần trước PR 0f:** tạo keystore phát hành và các Android OAuth client trong cùng dự án Google Cloud (chủ dự án tự làm): `vn.wholewell.app` với SHA-1 của upload key (sau này thêm SHA-1 của khóa Play App Signing), và `vn.wholewell.app.dev`.
5. GĐ8: tách khung thành repo template riêng, hay để trong repo này: **quyết sau**, trước GĐ8.

## 8. Lịch sử bản

- **Bản 1 (28/11/2026):** nháp đầu.
- **Bản 2 (28/11/2026), theo review lần 1:** luật import qua `models.dart`; làm mới theo bảng; ghim Flutter và sàn SDK; tiếng Việt cho widget hệ thống; OAuth client cho flavor dev; hiệu năng đo tay; `platform_bridge` là plugin; `design_system` không chứa màu; lưới test; hiệu năng sớm, GĐ6 từ `me` tới `today`, tách lint khỏi workspace.
- **Bản 3 (28/11/2026), theo review lần 2:** mọi job CI dùng Flutter đã ghim; một tệp lint ở gốc; `DiaryController` nghe `changes` trong thời gian chuyển đổi; sửa bảng ghi/làm mới (lưu trữ sản phẩm, tự tăng tuổi, bước onboarding, cascade) và tự kiểm bằng update hook; giữ alias và tên tệp khóa khi chuyển sang plugin; cài lại khi đổi khóa ký; đo mốc trước khi sửa ở 0e; đổi P1 thành 0e, build thành 0f; gộp phần trùng.
- **Bản 4 (28/11/2026), theo review của chủ dự án:** OAuth client cho bản prod (upload key, Play App Signing); bỏ qua sự kiện cũ bằng `seq`; sửa cơ chế contract test (`ExecutorFactory` riêng, `updatesSync`) và cấm 3 trường hợp update hook không thấy; PR 1 làm ngay sau 0a, đặc tả và thiết kế viết ngay; 0e chạy thư viện món song song với `reload()`; sửa mục "Lệnh" của `AGENTS.md` ngay ở 0a; ghi rõ `flutter-version-file: .fvmrc`, `release.yml`, lệnh analyze của app, `dev_dependencies` và `exclude` của lint gốc, `noBackupFilesDir` và manifest ở 4a.
- **Bản 5 (28/11/2026), đối chiếu 17 khuyến nghị chính thức:** DI dùng `provider`; repository không biết nhau (tách bảng ghi khỏi bảng đọc, phần ghép chuyển sang use case `DailyReport`, `ScheduleSafety`, `ReminderSync`); repository và service trừu tượng, bản giả trong `app/testing/fakes/`, test từng lớp; `app_core` là Flutter package chỉ import `foundation`; phiên chuyển sang `SessionRepository`, service không giữ state; ViewModel tạo trong builder của route; quy ước đặt tên; ADR 5 chỉ cấm codegen cho model, mã sinh của Pigeon và `gen-l10n` có CI kiểm; kiểm `meetsGuideline`; mục 4 đổi sang bảng 17 khuyến nghị.
- **Bản 6 (28/11/2026), theo review của chủ dự án:** `JournalDbService` giữ kết nối CSDL (ghi là chỗ lệch có lý do so với guide), repository làm lại cache và `changes` khi kết nối đổi; ngày đang xem ở `JournalDayRepository`; ViewModel tạo bằng `ChangeNotifierProvider(create:, builder:)` để không bị tạo lại khi builder của route chạy lại, PR 5b xác nhận; `AppCoordinator` giữ vòng đời app, thao tác từ thông báo và đồng bộ nhắc giờ (PR 5d); tách 5a thành 5a-1 đến 5a-4; Session không nghe `changes`.
- **Bản 7 (28/11/2026), theo review của chủ dự án:** ngày đang xem chuyển sang `ViewedDayRepository`, repository khác nhận `day` làm tham số; `JournalDbService` phát một stream `changes` cố định (thế hệ, `base + seq` tính đồng bộ, thứ tự thay kết nối, kết nối `null` khi xóa); cấm `ChangeNotifierProvider.value`, route có tham số gắn `ValueKey`, PR 5b kiểm cả hai; điều kiện "đang ở màn gốc" đọc từ router; ghi chú các lần ghi trong `_syncStageFromRepo`.
- **Bản 8 (28/11/2026):** thêm ADR 15 (làm mới dữ liệu) kèm lý do không chọn `watch()` của drift và làm mới thủ công; quy tắc `seq` chuyển từ mục 6 lên 3.4 và áp cho mọi bên tự làm mới sau lần ghi của chính nó; PR 0d viết lại quy tắc 4 của `AGENTS.md` theo tên service mới; mục 4 ghi chỗ plan khác Compass khi tạo ViewModel.
- **Bản 9 (28/11/2026), theo review của chủ dự án:** `seq` nhớ theo từng mục cache thay cho một số chung mỗi repository; chỉ phát sự kiện khi lần ghi xong, hàm ghi nhiều câu lệnh phải nằm trong `db.transaction`; ViewModel của sheet do ViewModel của màn tạo; thứ tự lắp ghép thêm router; Settings không nhận `day`.
- **Bản 10 (28/11/2026), theo review của chủ dự án:** cache chỉ giữ mục đang có người nghe (mỗi mục một `Listenable`, bỏ mục khi người nghe cuối rời đi), nên repository không cần biết ngày đang xem và cache có giới hạn; mục còn trong cache bị đổi thì làm mới ngay; đọc một lần thì truy vấn thẳng.
- **Bản 11 (28/11/2026), theo review của chủ dự án:** mỗi mục cache chỉ một truy vấn tại một thời điểm (đánh dấu "cần làm lại", lời gọi làm mới chờ truy vấn bắt đầu sau nó), cờ `disposed` cho mục bị bỏ giữa lúc truy vấn; `AppCoordinator` hẹn giờ đổi ngày nghe lúc 0 giờ; thêm ngoại lệ hành vi thứ ba (đồng bộ nhắc giờ lúc 0 giờ, PR 5d cần duyệt).
- **Bản 12 (28/11/2026), theo review của chủ dự án:** ghi đúng phạm vi của ngoại lệ thứ ba (chỉ khi app còn chạy lúc 0 giờ, chỉ lịch bắt đầu hoặc kết thúc ngày đó) và ghi lỗ hổng chuông vẫn kêu cho lịch đã kết thúc khi không mở app, để làm sau; lời gọi làm mới không treo khi mục bị bỏ, trả về bằng truy vấn riêng; bỏ lớp `Clock` tự viết, dùng `package:clock` và `fake_async`.
- **Bản 13 (28/11/2026), theo review của chủ dự án:** đổi toàn bộ `DateTime.now` sang `clock.now()` trong một lần ở PR 3a (gồm `journal_db` và `app/test`) thay vì đổi dần, kèm test kiểm toán bắt cả cách viết không có ngoặc.
- **Bản 14 (28/11/2026), theo review của chủ dự án:** giá trị mặc định viết `() => clock.now()` thay cho tear-off `clock.now` (tear-off giữ đồng hồ của lúc tạo đối tượng, test không giả được thời gian); test kiểm toán dùng mẫu đã escape `DateTime\.now\b` và cấm thêm tear-off `clock.now`.
- **Bản 15 (28/11/2026), theo review của chủ dự án:** test kiểm toán quét thêm `app/test` và cấm thêm `DateTime.timestamp`.
