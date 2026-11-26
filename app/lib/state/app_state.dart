import 'dart:async';
import 'dart:convert';

import 'package:dsld_library/dsld_library.dart';
import 'package:flutter/foundation.dart';
import 'package:food_library/food_library.dart';
import 'package:health_engine/health_engine.dart';
import 'package:journal_db/journal_db.dart';

import '../platform/backup_provider.dart';
import '../platform/label_scanner.dart';
import '../platform/notification_scheduler.dart';
import 'db_session_controller.dart';
import 'diary_controller.dart';

export '../platform/backup_provider.dart';
export '../platform/label_scanner.dart';
export '../platform/notification_scheduler.dart';
export 'db_session_controller.dart'
    show DataStatus, DbSessionController, SessionStage, khungTamConsentVersion;
export 'diary_controller.dart'
    show DayJournalData, DiaryController, DoseLogged, DoseLogOutcome, DoseNeedsExpiredChoice, FoodLogFeedback;
export 'label_food_builder.dart';
export 'supplement_label_parser.dart';

/// Điều phối chung kết hợp [DbSessionController] và [DiaryController].
/// Giữ tương thích với khung tạm và các test cũ, đồng thời tách miền trạng thái sang `diary`.
class AppState extends ChangeNotifier {
  final ReferencePack pack;
  final DbSessionController session;
  final DiaryController diary;
  final OcrEngine ocrEngine;
  final BarcodeScanner? barcodeScanner;
  final NotificationScheduler notificationScheduler;
  final BackupFileProvider backupFileProvider;
  final Future<FoodLibraryRepository> Function()? _openFoodLibrary;
  final Future<DsldLibraryRepository> Function()? _openDsldLibrary;
  DsldLibraryRepository? _dsldLibrary;
  bool _dsldLibraryBroken = false;
  bool _dsldLibraryPreparing = false;

  AppState({
    required this.pack,
    required DbOpener opener,
    Future<FoodLibraryRepository> Function()? openFoodLibrary,
    FoodLibraryRepository? foodLibrary,
    Future<DsldLibraryRepository> Function()? openDsldLibrary,
    DsldLibraryRepository? dsldLibrary,
    OcrEngine? ocrEngine,
    this.barcodeScanner,
    NotificationScheduler? notificationScheduler,
    BackupFileProvider? backupFileProvider,
  })  : _openFoodLibrary = openFoodLibrary,
        _openDsldLibrary = openDsldLibrary,
        _dsldLibrary = dsldLibrary,
        ocrEngine = ocrEngine ?? MlKitOcrEngine(),
        notificationScheduler = notificationScheduler ?? FakeNotificationScheduler(),
        backupFileProvider = backupFileProvider ?? const AndroidBackupFileProvider(),
        session = DbSessionController(opener: opener),
        diary = DiaryController(pack: pack, foodLibrary: foodLibrary) {
    session.addListener(notifyListeners);
    diary.addListener(notifyListeners);
  }

  /// Dùng một nhật ký có sẵn (test giao diện với bản bộ nhớ).
  AppState.withRepository({
    required this.pack,
    required JournalRepository repo,
    FoodLibraryRepository? foodLibrary,
    DsldLibraryRepository? dsldLibrary,
    OcrEngine? ocrEngine,
    this.barcodeScanner,
    NotificationScheduler? notificationScheduler,
    BackupFileProvider? backupFileProvider,
  })  : _openFoodLibrary = null,
        _openDsldLibrary = null,
        _dsldLibrary = dsldLibrary,
        ocrEngine = ocrEngine ?? FakeOcrEngine(),
        notificationScheduler = notificationScheduler ?? FakeNotificationScheduler(),
        backupFileProvider = backupFileProvider ?? FakeBackupFileProvider(),
        session = DbSessionController(repo: repo, initialStatus: DataStatus.ready),
        diary = DiaryController(pack: pack, repo: repo, foodLibrary: foodLibrary) {
    session.addListener(notifyListeners);
    diary.addListener(notifyListeners);
  }

  /// Nền tảng chưa có kho khóa: không mở, không ghi gì.
  AppState.unsupportedPlatform({required this.pack})
      : _openFoodLibrary = null,
        _openDsldLibrary = null,
        _dsldLibrary = null,
        ocrEngine = FakeOcrEngine(),
        barcodeScanner = null,
        notificationScheduler = FakeNotificationScheduler(),
        backupFileProvider = FakeBackupFileProvider(),
        session = DbSessionController(initialStatus: DataStatus.unsupportedPlatform),
        diary = DiaryController(pack: pack) {
    session.addListener(notifyListeners);
    diary.addListener(notifyListeners);
  }

  DataStatus get status => session.status;
  SessionStage get stage => session.stage;
  Profile? get profile => diary.profile;
  bool get hideCalories => diary.hideCalories;
  bool get caution => diary.caution;
  double get lastWaterMl => diary.lastWaterMl;
  int? get ageBumpedNotice => diary.ageBumpedNotice;
  DayTimesSettings get dayTimesSettings => diary.dayTimesSettings;
  bool get notificationsEnabled => diary.notificationsEnabled;
  DateTime get day => diary.day;
  bool get saveFailed => diary.saveFailed;
  bool get readFailed => diary.readFailed;
  bool get foodLibraryBroken => diary.foodLibraryBroken;
  FoodLibraryRepository? get foodLibrary => diary.foodLibrary;
  DsldLibraryRepository? get dsldLibrary => _dsldLibrary;
  bool get dsldLibraryBroken => _dsldLibraryBroken;
  bool get dsldLibraryPreparing => _dsldLibraryPreparing;

  List<IntakeItem> get todayItems => diary.todayItems;
  List<WorkoutEntry> get todayWorkouts => diary.todayWorkoutEntries;
  List<WaterRecord> get todayWaters => diary.todayWaters;

  void clearSaveFailed() => diary.clearSaveFailed();
  void clearReadFailed() => diary.clearReadFailed();

  Future<void> start() => session.start(onReady: () async {
        diary.attachRepository(session.repo);
        if (session.stage == SessionStage.ready) {
          await diary.checkAgeBumpOnReady();
        }
        await _ensureFoodLibrary();
        unawaited(_ensureDsldLibrary());
        await diary.reload();
        unawaited(syncNotifications());
      });

  /// Kiểm tra tự tăng tuổi khi app quay lại tiền cảnh ở trạng thái đã sẵn sàng.
  Future<void> onAppResume() async {
    if (status == DataStatus.waitingForUnlock || status == DataStatus.lowStorage) {
      await start();
      return;
    }
    if (status == DataStatus.ready && stage == SessionStage.ready) {
      await diary.checkAgeBumpOnReady();
    }
  }

  /// Hoàn tất bước Đồng ý lần đầu (chỉ tạo khóa & CSDL sau khi người dùng đồng ý).
  Future<bool> completeFirstConsent({required int ageYears, required bool caution}) async {
    try {
      final created = await session.ensureCreatedForConsent(
        ConsentInput(contentVersion: mvpConsentVersion, ageYears: ageYears, caution: caution),
        onAlreadyExists: start,
      );
      if (!created) return false;
      diary.attachRepository(session.repo);
      await _ensureFoodLibrary();
      unawaited(_ensureDsldLibrary());
      await diary.reload();
      return true;
    } on StorageFullException {
      return false;
    } on JournalStorageException {
      return false;
    }
  }

  /// Hoàn tất nâng cấp từ `khung-tam-0`.
  Future<bool> completeUpgradeConsent({required int ageYears, required bool caution}) async {
    try {
      final ok = await session.upgradeHealthConsent(ageYears: ageYears, caution: caution);
      if (!ok) return false;
      if (session.stage == SessionStage.ready) {
        await diary.checkAgeBumpOnReady();
      }
      await _ensureFoodLibrary();
      unawaited(_ensureDsldLibrary());
      await diary.reload();
      return true;
    } on StorageFullException {
      return false;
    } on JournalStorageException {
      return false;
    }
  }

  Future<int?> consentAgeYears() async => (await session.repo?.loadConsentProfile())?.ageYears;

  Future<bool> saveOnboardingBodyProfile(Profile p) async {
    final ok = await diary.saveBodyProfileForOnboarding(p);
    if (!ok) return false;
    session.setStage(SessionStage.onboardingCalorieDisplay);
    return true;
  }

  Future<bool> completeCalorieDisplayOnboarding(bool hideCalories) async {
    final ok = await diary.completeCalorieDisplayOnboarding(hideCalories);
    if (!ok) return false;
    session.setStage(SessionStage.ready);
    await diary.checkAgeBumpOnReady();
    return true;
  }

  Future<void> _ensureFoodLibrary() async {
    if (diary.foodLibrary != null || diary.foodLibraryBroken || _openFoodLibrary == null) return;
    try {
      final lib = await _openFoodLibrary();
      diary.setFoodLibrary(repository: lib, broken: false);
    } on FoodLibraryIntegrityException {
      diary.setFoodLibrary(repository: null, broken: true);
    } on Object {
      diary.setFoodLibrary(repository: null, broken: true);
    }
  }

  Future<void> startOver() async {
    await notificationScheduler.syncSchedules(const []);
    await session.startOver(onCleared: () {
      diary.attachRepository(null);
      diary.clear();
    });
  }

  Future<void> withdrawConsentAndReset() => startOver();

  Future<void> reload() => diary.reload();

  /// Lưu hồ sơ tương thích các test cũ dùng [InMemoryJournalRepository].
  Future<void> saveProfile(Profile p) async {
    if (session.repo == null) return;
    diary.attachRepository(session.repo);
    await _ensureFoodLibrary();
    await diary.saveProfileAndDone(p);
    session.setStage(SessionStage.ready);
  }

  Future<bool> saveProfileFromSettings(Profile p, {required bool caution}) =>
      diary.saveProfileFromSettings(p, caution: caution);

  Future<void> setHideCalories(bool v) => diary.setHideCalories(v);
  Future<void> setDay(DateTime d) => diary.setDay(d);
  Future<void> addItem(IntakeItem it) => diary.addItem(it);
  Future<void> recordDose(String name, List<IntakeLine> lines) => diary.recordDose(name, lines);
  Future<void> removeItem(int index) => diary.removeItemByIndex(index);
  Future<void> addWorkout(WorkoutEntry w) => diary.addWorkout(w);
  Future<void> removeWorkout(int index) => diary.removeWorkoutByIndex(index);

  DailyReport? report() => diary.report();
  ActivityLevel suggestedLevel() => diary.suggestedLevel();

  Future<void> _ensureDsldLibrary() async {
    if (_dsldLibrary != null || _dsldLibraryBroken || _dsldLibraryPreparing || _openDsldLibrary == null) {
      return;
    }
    _dsldLibraryPreparing = true;
    notifyListeners();
    try {
      _dsldLibrary = await _openDsldLibrary();
      _dsldLibraryBroken = false;
    } on DsldLibraryIntegrityException {
      _dsldLibrary = null;
      _dsldLibraryBroken = true;
    } on Object {
      _dsldLibrary = null;
      _dsldLibraryBroken = true;
    } finally {
      _dsldLibraryPreparing = false;
      notifyListeners();
    }
  }

  Future<void> syncNotifications() async {
    if (!diary.notificationsEnabled) {
      await notificationScheduler.syncSchedules(const []);
      return;
    }
    if (!await notificationScheduler.hasPermission()) return;
    await notificationScheduler.syncSchedules(diary.buildReminderSlots());
  }

  Future<void> cancelWindowIfHandled(int timeOfDay) async {
    final slots = diary.actualTodaySchedules.where((s) => s.timeOfDay == timeOfDay).toList();
    if (slots.isEmpty) return;
    final markedIds = {for (final o in diary.actualTodayOccurrences) o.scheduleId};
    if (slots.every((s) => markedIds.contains(s.id))) {
      await notificationScheduler.cancelWindow(timeOfDay);
    }
  }

  Future<bool> enableNotifications({required String consentVersion}) async {
    final granted = await notificationScheduler.requestPermission();
    final saved = await diary.grantNotificationConsent(consentVersion);
    if (saved && granted) {
      await syncNotifications();
    }
    return granted;
  }

  Future<void> disableNotifications() async {
    await notificationScheduler.syncSchedules(const []);
    await diary.withdrawNotificationConsent();
  }

  bool get canBackupToFile => session.hasOpener && session.repo is DriftJournalRepository;
  bool get canRestoreFromFile => session.hasOpener;
  DateTime? get lastFileBackupAt => diary.lastFileBackupAt;
  HealthConsentStatus? get healthConsent => diary.healthConsent;

  Future<String?> createEncryptedBackupFile({
    required String secret,
    int memoryKiB = BackupCodec.defaultMemoryKiB,
    int iterations = BackupCodec.defaultIterations,
    int parallelism = BackupCodec.defaultParallelism,
  }) async {
    final bytes = await session.exportBackup(
      secret: secret,
      memoryKiB: memoryKiB,
      iterations: iterations,
      parallelism: parallelism,
    );
    final n = DateTime.now();
    final name =
        'wholewell-${n.year}${n.month.toString().padLeft(2, '0')}${n.day.toString().padLeft(2, '0')}-${n.hour.toString().padLeft(2, '0')}${n.minute.toString().padLeft(2, '0')}.wwbackup';
    final saved = await backupFileProvider.saveFile(
      suggestedName: name,
      mimeType: 'application/octet-stream',
      bytes: bytes,
    );
    if (saved != null) {
      await diary.recordFileBackupAt(n);
    }
    return saved;
  }

  Future<RestoreOutcome> restoreEncryptedBackupFile({
    required Uint8List backupBytes,
    required String secret,
  }) async {
    return session.restoreFromBackup(
      backupBytes: backupBytes,
      secret: secret,
      onRestored: () async {
        diary.attachRepository(session.repo);
        if (session.stage == SessionStage.ready) {
          await diary.checkAgeBumpOnReady();
        }
        await _ensureFoodLibrary();
        unawaited(_ensureDsldLibrary());
        await diary.reload();
        unawaited(syncNotifications());
      },
    );
  }

  Future<String?> exportReadableJsonFile() async {
    final repo = session.repo;
    if (repo == null) return null;
    final data = await repo.exportReadableJson();
    final encoded = const JsonEncoder.withIndent('  ').convert(data);
    final n = DateTime.now();
    final name =
        'wholewell-export-${n.year}${n.month.toString().padLeft(2, '0')}${n.day.toString().padLeft(2, '0')}.json';
    return backupFileProvider.saveFile(
      suggestedName: name,
      mimeType: 'application/json',
      bytes: Uint8List.fromList(utf8.encode(encoded)),
    );
  }

  @override
  void dispose() {
    _dsldLibrary?.close();
    unawaited(notificationScheduler.dispose());
    session.removeListener(notifyListeners);
    diary.removeListener(notifyListeners);
    session.dispose();
    diary.dispose();
    super.dispose();
  }
}
