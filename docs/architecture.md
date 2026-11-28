# Kiến trúc WholeWell

Cập nhật 29/11/2026. Tài liệu tham chiếu cho người và agent viết code. Quyết định và lý do: [adr/](adr/README.md) (15 ADR, đã duyệt 28/11/2026). Lộ trình chuyển đổi từ code hiện tại: [refactor-plan.md](refactor-plan.md), mục 5.

## 1. Tổng quan

App tổ chức theo **MVVM** của [Flutter App Architecture Guide](https://docs.flutter.dev/app-architecture/guide) (ADR 0001):

```text
View (widget) → ViewModel → (use case) → Repository → Service → package (health_engine, journal_db, food_library, dsld_library)
```

- **View**: widget, không logic nghiệp vụ; nghe ViewModel bằng `ListenableBuilder`.
- **ViewModel**: `ChangeNotifier`, mọi thao tác đi qua `Command`, lỗi trả bằng `Result<T>` (ADR 0002, 0006). Chỉ dùng `flutter/foundation`.
- **Use case**: không giữ state; chỉ có khi cần ghép nhiều repository hoặc nhiều ViewModel dùng chung.
- **Repository**: nguồn dữ liệu đúng cho app; có cache, làm mới theo bảng (ADR 0015).
- **Service**: bọc một nguồn bên ngoài (CSDL, thông báo, OCR, AI nhãn, mã vạch, Drive, tệp), không giữ state nghiệp vụ.
- Phần tính toán (chuẩn dinh dưỡng, cờ vượt giới hạn) nằm trong `health_engine`, package Dart thuần, không I/O.

## 2. Repo

```text
pubspec.yaml                 # Pub Workspace gốc; hooks sqlite3mc; very_good_analysis (ADR 0010, 0013)
pubspec.lock                 # chung cho mọi package, commit
analysis_options.yaml        # lint chung, độ rộng dòng 120
.fvmrc                       # ghim Flutter 3.50.1
app/                         # app WholeWell
packages/
  app_core/                  # [khung, PR 3a] Result, Command, AppException; chỉ import flutter/foundation
  design_system/             # [khung, PR 3b] hàm dựng theme nhận bảng màu, spacing/radius, widget dùng chung, data_viz
  platform_bridge/           # [khung, PR 4a] Flutter plugin (Pigeon + Kotlin): khóa an toàn, lưu/chọn tệp, mở cài đặt
  health_engine/             # engine thuần Dart
  journal_db/                # CSDL mã hóa; thư viện models.dart chỉ chứa model
  food_library/              # thư viện món chỉ đọc (FTS5)
  dsld_library/              # thư viện bổ sung NIH DSLD chỉ đọc (FTS5)
tools/                       # Python: gói dữ liệu và engine tham chiếu; tools/perf/ (PR 0e)
docs/                        # plan, đặc tả, thiết kế, ADR, tài liệu này
```

Package **[khung]** không import gì riêng của WholeWell, để tách thành khung cho app Flutter khác (GĐ8).

## 3. `app/` (đích)

```text
lib/
  main_dev.dart, main_prod.dart  # gọi bootstrap(Flavor.x)
  bootstrap.dart                 # tải gói, mở phiên, lắp phụ thuộc, runApp
  config/dependencies.dart       # MultiProvider: service → repository → router → AppCoordinator
  config/app_coordinator.dart    # vòng đời app, thao tác từ thông báo, đồng bộ nhắc giờ
  data/services/                 # JournalDbService, NotificationService, OcrService, LabelAiService,
                                 # BarcodeService, DriveService, BackupFileService
  data/repositories/             # SessionRepository, ViewedDayRepository, JournalDayRepository, CustomFoodRepository,
                                 # SupplementRepository, ScheduleRepository, SettingsRepository, BackupRepository
  domain/use_cases/              # DailyReportUseCase, ScheduleSafetyUseCase, ReminderSyncUseCase, LogFoodUseCase…
  routing/                       # go_router; builder của route tạo ViewModel
  ui/core/                       # bảng màu WholeWell, labels, l10n, widget dùng chung của app
  ui/<feature>/view_models/      # <x>_view_model.dart → XViewModel
  ui/<feature>/widgets/          # <x>_screen.dart → XScreen và widget con
  l10n/app_vi.arb
  pigeons/                       # Pigeon riêng của app (nhắc giờ, AI nhãn)
testing/fakes/                   # bản giả mọi repository và service
test/                            # theo cấu trúc lib/
```

**Đặt tên:** `XViewModel`, `XScreen`, `XRepository`, `XService`, `XUseCase`; tệp `x_view_model.dart`, `x_screen.dart`… Widget dùng chung đặt trong `ui/core/`, không có thư mục `widgets/` chung. Không trùng tên lớp đã có trong package (vd. `FoodLibraryRepository` của `food_library`). Repository và service là `abstract interface class`, bản cài tên theo nguồn (vd. `DriftJournalDbService`).

**Vòng đời ViewModel:** builder của route tạo ViewModel bằng `ChangeNotifierProvider(create:, builder:)` (không dùng `.value`), đọc bằng `context.read()` rồi truyền vào màn qua constructor. Route có tham số gắn `ValueKey` theo tham số. Sheet và hộp thoại dùng ViewModel của màn mở nó; sheet có thao tác ghi riêng thì ViewModel của màn tạo ViewModel con và hủy nó khi sheet đóng.

**`AppCoordinator`** giữ việc mức app: vòng đời (quay lại tiền cảnh, qua 0 giờ, tự tăng tuổi, đọc lại khóa), mở màn từ thông báo, đồng bộ nhắc giờ qua `ReminderSyncUseCase`.

## 4. Luật phụ thuộc

```text
ui/<feature>/widgets → ui/<feature>/view_models → (domain/use_cases) → data/repositories → data/services → packages
```

- Repository không import repository khác. Service không import repository. Phần ghép nằm ở use case, ViewModel hoặc `AppCoordinator`.
- Chỉ `routing/` đọc ViewModel từ `provider`; màn và widget con nhận ViewModel qua constructor.
- ViewModel chỉ phụ thuộc repository trừu tượng và use case; không import `material_ui`.
- Widget và ViewModel import `package:journal_db/models.dart`, **không** import `package:journal_db/journal_db.dart`. Không re-export để lách luật, không chép lại model.
- Widget không import `data/`, `mobile_scanner`, `google_mlkit_*`, `image_picker`, không dùng `MethodChannel`.
- Feature không import feature khác; phần dùng chung đặt trong `ui/core` hoặc `design_system`.
- Engine (`health_engine`) không gọi service, không I/O.

**Test kiểm toán** [app/test/architecture_rules_test.dart](../app/test/architecture_rules_test.dart) giữ các luật đang áp được với code hiện tại, mỗi luật có danh sách vi phạm **chỉ được giảm**. Luật về `data/`, ViewModel, feature thêm vào test này khi thư mục tương ứng ra đời.

## 5. Luồng dữ liệu

Chi tiết trong [ADR 0015](adr/0015-lam-moi-du-lieu.md). Tóm tắt:

- `journal_db` báo mỗi lần ghi xong bằng `Stream<JournalChange>` (`seq`, tập bảng đã đổi). `JournalDbService` phát một stream cố định qua mọi kết nối.
- Repository làm mới mục cache khi bảng mà truy vấn của chính nó đọc bị đổi; cache chỉ giữ mục đang có người nghe; bỏ sự kiện cũ bằng `seq` theo từng mục.
- Hàm ghi nhiều câu lệnh nằm trong `db.transaction`; chỉ phát sự kiện khi ghi xong.
- ViewModel tính phần dẫn xuất một lần mỗi khi dữ liệu đổi, không tính trong `build()`.

## 6. Nền tảng

- Mọi phần phụ thuộc nền tảng đi qua service (mục 3) hoặc `platform_bridge`; mỗi service có bản giả trong `app/testing/fakes/`.
- Native interop dùng Pigeon (ADR 0009). Không đổi alias `wholewell_db_wrap_v1`, tệp `wholewell_db_key.bin` trong `noBackupFilesDir`, luật loại khỏi sao lưu trong manifest: đổi là mất CSDL trên máy đã cài.
- AI tạo sinh chỉ chạy trên máy (Gemini Nano qua Android AICore), chỉ gợi ý tách thành phần từ chữ OCR trên nhãn; chỉ gọi khi mô hình đã có sẵn, không tự tải; người dùng xác nhận từng dòng; engine quyết định mọi số và cảnh báo.

## 7. Test

- Unit test cho mọi service, repository, use case, ViewModel; widget test cho mọi màn; `app/test/` theo cấu trúc `lib/`.
- Một helper duy nhất [app/test/helpers/pump_app.dart](../app/test/helpers/pump_app.dart): `testAppState`, `pumpApp`, `wrapApp`, `pumpWholeWellApp`. `pumpApp` kiểm 3 hướng dẫn trợ năng của Flutter; ngoại lệ trong [a11y_exceptions.dart](../app/test/helpers/a11y_exceptions.dart), chỉ được giảm.
- Golden test (tag `golden`) chỉ chạy trên Linux; ảnh mẫu sinh bằng workflow CI chạy tay với `update_goldens` ([golden.dart](../app/test/helpers/golden.dart)).
- Thời gian dùng `clock.now()` (viết `() => clock.now()`, không tear-off) và `fake_async`; cấm `DateTime.now` (PR 3a).
- Engine: test Dart so với kết quả của `tools/reference_engine.py`.

## 8. Hiện trạng chuyển đổi (29/11/2026)

Code hiện tại chưa theo mục 3. Tới PR 6.9 còn:

- `AppState`, `DiaryController`, `DbSessionController` trong `app/lib/state/`, đưa xuống cây bằng `AppScope` (`InheritedNotifier`); màn trong `app/lib/ui/` đọc trạng thái qua `AppScope.of(context)`.
- Interface nền tảng cũ trong `app/lib/platform/`: `NotificationScheduler`, `OcrEngine` (gồm cả AI nhãn), `BarcodeScanner`, `GoogleAuth`, `BackupProvider`, `BackupFileProvider`, `DrivePendingDeleteStore`; khóa CSDL qua `SecureKeyStore` của `journal_db` (bản Android `AndroidDbKeyStore`). Mỗi cái có bản giả. Chuyển thành service hoặc `platform_bridge` ở PR 4a, 4b, 5a-2.
- Vi phạm còn lại (test kiểm toán giữ): 2 màn sao lưu import `journal_db.dart`; `supplements_screen.dart` dùng `mobile_scanner`.

Quy tắc trong thời gian chuyển đổi: [refactor-plan.md](refactor-plan.md), mục 6. Code mới viết theo kiến trúc đích ngay.
