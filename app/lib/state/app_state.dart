import 'package:flutter/foundation.dart';
import 'package:food_library/food_library.dart';
import 'package:health_engine/health_engine.dart';
import 'package:journal_db/journal_db.dart';

import 'db_session_controller.dart';
import 'diary_controller.dart';

export 'db_session_controller.dart'
    show DataStatus, DbSessionController, SessionStage, khungTamConsentVersion;
export 'diary_controller.dart' show DayJournalData, DiaryController, FoodLogFeedback;
export 'label_food_builder.dart';

/// Điều phối chung kết hợp [DbSessionController] và [DiaryController].
/// Giữ tương thích với khung tạm và các test cũ, đồng thời tách miền trạng thái sang `diary`.
class AppState extends ChangeNotifier {
  final ReferencePack pack;
  final DbSessionController session;
  final DiaryController diary;
  final Future<FoodLibraryRepository> Function()? _openFoodLibrary;

  AppState({
    required this.pack,
    required DbOpener opener,
    Future<FoodLibraryRepository> Function()? openFoodLibrary,
    FoodLibraryRepository? foodLibrary,
  })  : _openFoodLibrary = openFoodLibrary,
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
  })  : _openFoodLibrary = null,
        session = DbSessionController(repo: repo, initialStatus: DataStatus.ready),
        diary = DiaryController(pack: pack, repo: repo, foodLibrary: foodLibrary) {
    session.addListener(notifyListeners);
    diary.addListener(notifyListeners);
  }

  /// Nền tảng chưa có kho khóa: không mở, không ghi gì.
  AppState.unsupportedPlatform({required this.pack})
      : _openFoodLibrary = null,
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
  DateTime get day => diary.day;
  bool get saveFailed => diary.saveFailed;
  bool get readFailed => diary.readFailed;
  bool get foodLibraryBroken => diary.foodLibraryBroken;
  FoodLibraryRepository? get foodLibrary => diary.foodLibrary;

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
        await diary.reload();
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

  Future<void> startOver() => session.startOver(onCleared: () {
        diary.attachRepository(null);
        diary.clear();
      });

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

  @override
  void dispose() {
    session.removeListener(notifyListeners);
    diary.removeListener(notifyListeners);
    session.dispose();
    diary.dispose();
    super.dispose();
  }
}
