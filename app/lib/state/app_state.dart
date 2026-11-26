import 'dart:async';
import 'dart:convert';
import 'dart:io' show SocketException;

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
  final GoogleAuth googleAuth;
  final BackupProvider driveBackupProvider;
  final DrivePendingDeleteStore drivePendingDeleteStore;
  final Future<FoodLibraryRepository> Function()? _openFoodLibrary;
  final Future<DsldLibraryRepository> Function()? _openDsldLibrary;
  DsldLibraryRepository? _dsldLibrary;
  bool _dsldLibraryBroken = false;
  bool _dsldLibraryPreparing = false;
  GoogleAuthAccount? _driveAccount;
  bool _drivePendingDeleteActive = false;
  bool _drivePendingDeleteNeedsReauth = false;

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
    GoogleAuth? googleAuth,
    BackupProvider? driveBackupProvider,
    DrivePendingDeleteStore? drivePendingDeleteStore,
  })  : _openFoodLibrary = openFoodLibrary,
        _openDsldLibrary = openDsldLibrary,
        _dsldLibrary = dsldLibrary,
        ocrEngine = ocrEngine ?? MlKitOcrEngine(),
        notificationScheduler = notificationScheduler ?? FakeNotificationScheduler(),
        backupFileProvider = backupFileProvider ?? const AndroidBackupFileProvider(),
        googleAuth = googleAuth ?? FakeGoogleAuth(),
        driveBackupProvider = driveBackupProvider ?? FakeBackupProvider(),
        drivePendingDeleteStore = drivePendingDeleteStore ?? InMemoryDrivePendingDeleteStore(),
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
    GoogleAuth? googleAuth,
    BackupProvider? driveBackupProvider,
    DrivePendingDeleteStore? drivePendingDeleteStore,
  })  : _openFoodLibrary = null,
        _openDsldLibrary = null,
        _dsldLibrary = dsldLibrary,
        ocrEngine = ocrEngine ?? FakeOcrEngine(),
        notificationScheduler = notificationScheduler ?? FakeNotificationScheduler(),
        backupFileProvider = backupFileProvider ?? FakeBackupFileProvider(),
        googleAuth = googleAuth ?? FakeGoogleAuth(),
        driveBackupProvider = driveBackupProvider ?? FakeBackupProvider(),
        drivePendingDeleteStore = drivePendingDeleteStore ?? InMemoryDrivePendingDeleteStore(),
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
        googleAuth = FakeGoogleAuth(),
        driveBackupProvider = FakeBackupProvider(),
        drivePendingDeleteStore = InMemoryDrivePendingDeleteStore(),
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

  Future<void> start() async {
    await session.start(onReady: () async {
      diary.attachRepository(session.repo);
      if (session.stage == SessionStage.ready) {
        await diary.checkAgeBumpOnReady();
      }
      await _ensureFoodLibrary();
      unawaited(_ensureDsldLibrary());
      await diary.reload();
      unawaited(syncNotifications());
    });
    await _checkDriveStateAndPendingDelete();
  }

  /// Kiểm tra tự tăng tuổi và cờ chờ xóa Drive khi app quay lại tiền cảnh.
  Future<void> onAppResume() async {
    if (status == DataStatus.waitingForUnlock || status == DataStatus.lowStorage) {
      await start();
      return;
    }
    if (status == DataStatus.ready && stage == SessionStage.ready) {
      await diary.checkAgeBumpOnReady();
    }
    await _checkDriveStateAndPendingDelete();
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

  /// Xóa toàn bộ dữ liệu trên máy (luôn xóa ngay), tùy chọn xóa cả bản trên Google Drive nếu đã bật.
  /// Trả `false` nếu bản trên Drive chưa xóa được và đã lưu cờ chờ xóa để thử lại sau.
  Future<bool> withdrawConsentAndReset({bool deleteDriveBackup = false}) async {
    var remoteCleared = true;
    if (deleteDriveBackup) {
      remoteCleared = await _deleteDriveBackupsOnReset();
    }
    await startOver();
    return remoteCleared;
  }

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
  HealthConsentStatus? get driveConsent => diary.driveConsent;
  bool get driveEnabled => diary.driveConsent != null;
  DateTime? get lastDriveBackupAt => diary.lastDriveBackupAt;
  GoogleAuthAccount? get driveAccount => _driveAccount;
  bool get drivePendingDeleteActive => _drivePendingDeleteActive;
  bool get drivePendingDeleteNeedsReauth => _drivePendingDeleteNeedsReauth;

  Future<void> _checkDriveStateAndPendingDelete() async {
    final pending = await drivePendingDeleteStore.hasPendingDelete();
    _drivePendingDeleteActive = pending;
    if (pending) {
      await _attemptSilentPendingDelete();
      notifyListeners();
      return;
    }
    _drivePendingDeleteNeedsReauth = false;
    if (diary.driveConsent != null) {
      try {
        _driveAccount = await googleAuth.signInSilently() ?? await googleAuth.currentUser();
      } on Object {
        _driveAccount ??= await googleAuth.currentUser();
      }
    } else {
      _driveAccount = await googleAuth.currentUser();
    }
    notifyListeners();
  }

  Future<bool> _attemptSilentPendingDelete() async {
    try {
      final acc = await googleAuth.signInSilently();
      if (acc == null) {
        _driveAccount = null;
        _drivePendingDeleteNeedsReauth = true;
        return false;
      }
      _driveAccount = acc;
      await driveBackupProvider.deleteAll();
      await googleAuth.disconnect();
      await drivePendingDeleteStore.clearPendingDelete();
      _driveAccount = null;
      _drivePendingDeleteActive = false;
      _drivePendingDeleteNeedsReauth = false;
      return true;
    } on SocketException {
      _drivePendingDeleteNeedsReauth = false;
      return false;
    } on Object {
      // Lỗi mạng/tạm thời khác: giữ cờ pending để thử lại; không khẳng định hết phiên nếu chỉ lỗi I/O.
      _drivePendingDeleteNeedsReauth = false;
      return false;
    }
  }

  Future<bool> _deleteDriveBackupsOnReset() async {
    try {
      var acc = _driveAccount ?? await googleAuth.currentUser();
      acc ??= await googleAuth.signInSilently();
      if (acc == null) {
        await drivePendingDeleteStore.markPendingDelete();
        _drivePendingDeleteActive = true;
        _drivePendingDeleteNeedsReauth = true;
        _driveAccount = null;
        return false;
      }
      await driveBackupProvider.deleteAll();
      try {
        await googleAuth.disconnect();
      } on Object {
        // Nếu xóa dữ liệu Drive xong nhưng thu hồi token lỗi tạm, bỏ qua.
      }
      await drivePendingDeleteStore.clearPendingDelete();
      _driveAccount = null;
      _drivePendingDeleteActive = false;
      _drivePendingDeleteNeedsReauth = false;
      return true;
    } on Object {
      await drivePendingDeleteStore.markPendingDelete();
      _drivePendingDeleteActive = true;
      _drivePendingDeleteNeedsReauth = false;
      return false;
    }
  }

  Future<bool> grantDriveConsent(String contentVersion) =>
      diary.grantDriveConsent(contentVersion);

  Future<GoogleAuthOutcome> signInGoogleDrive() async {
    final res = await googleAuth.signIn();
    if (res is GoogleAuthSignedIn) {
      _driveAccount = res.account;
      notifyListeners();
    }
    return res;
  }

  Future<GoogleAuthOutcome> switchGoogleDriveAccount() async {
    try {
      await googleAuth.signOut();
    } on Object {
      // Tiếp tục thử đăng nhập lại.
    }
    _driveAccount = null;
    notifyListeners();
    return signInGoogleDrive();
  }

  Future<CloudBackupInfo> createDriveBackup({
    required String secret,
    int memoryKiB = BackupCodec.defaultMemoryKiB,
    int iterations = BackupCodec.defaultIterations,
    int parallelism = BackupCodec.defaultParallelism,
  }) async {
    final headers = await googleAuth.authHeaders(interactive: false);
    if (headers == null && await googleAuth.currentUser() == null) {
      final auth = await signInGoogleDrive();
      if (auth is! GoogleAuthSignedIn) {
        throw StateError('Chưa đăng nhập Google Drive.');
      }
    }
    final bytes = await session.exportBackup(
      secret: secret,
      memoryKiB: memoryKiB,
      iterations: iterations,
      parallelism: parallelism,
    );
    final info = await driveBackupProvider.upload(bytes);
    await diary.recordDriveBackupAt(info.modifiedAt);
    return info;
  }

  Future<List<CloudBackupInfo>> listDriveBackups() => driveBackupProvider.listBackups();

  Future<RestoreOutcome> restoreFromGoogleDrive({
    required String backupId,
    required String secret,
  }) async {
    final bytes = await driveBackupProvider.download(backupId);
    final outcome = await restoreEncryptedBackupFile(backupBytes: bytes, secret: secret);
    if (outcome is RestoreSucceeded) {
      unawaited(_checkDriveStateAndPendingDelete());
    }
    return outcome;
  }

  /// Tắt sao lưu Google Drive trên máy (tùy chọn xóa các bản sao lưu trên Drive).
  /// Trả `false` nếu người dùng chọn xóa Drive nhưng mạng lỗi và đã ghi cờ chờ xóa.
  Future<bool> disconnectGoogleDrive({required bool deleteRemoteBackups}) async {
    var remoteCleared = true;
    if (deleteRemoteBackups) {
      remoteCleared = await _deleteDriveBackupsOnReset();
    } else {
      try {
        await googleAuth.disconnect();
      } on Object {
        // Bỏ qua nếu đang offline.
      }
      _driveAccount = null;
    }
    await diary.withdrawDriveConsent();
    notifyListeners();
    return remoteCleared;
  }

  /// Xử lý cờ chờ xóa Drive (đăng nhập lại để xóa hoặc người dùng tự xóa/bỏ qua).
  Future<bool> resolvePendingDriveDelete({required bool interactiveSignIn}) async {
    if (!interactiveSignIn) {
      await drivePendingDeleteStore.clearPendingDelete();
      _drivePendingDeleteActive = false;
      _drivePendingDeleteNeedsReauth = false;
      notifyListeners();
      return true;
    }
    final auth = await googleAuth.signIn();
    if (auth is! GoogleAuthSignedIn) {
      return false;
    }
    try {
      await driveBackupProvider.deleteAll();
      await googleAuth.disconnect();
      await drivePendingDeleteStore.clearPendingDelete();
      _driveAccount = null;
      _drivePendingDeleteActive = false;
      _drivePendingDeleteNeedsReauth = false;
      notifyListeners();
      return true;
    } on Object {
      notifyListeners();
      return false;
    }
  }

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
