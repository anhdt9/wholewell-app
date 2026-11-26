/// Trạng thái nhật ký ăn uống, thư viện món, phản hồi cảnh báo & truy vấn 7 ngày.
library;

import 'package:flutter/foundation.dart';
import 'package:food_library/food_library.dart';
import 'package:health_engine/health_engine.dart';
import 'package:journal_db/journal_db.dart';

import '../platform/notification_scheduler.dart';
import 'label_food_builder.dart';

class DayJournalData {
  final List<FoodEntry> foods;
  final List<DoseEntry> doses;
  final List<WorkoutRecord> workouts;
  final List<WaterRecord> waters;
  final List<List<IntakeItem>> last7;
  final List<WorkoutEntry> workouts7;

  const DayJournalData({
    required this.foods,
    required this.doses,
    required this.workouts,
    required this.waters,
    required this.last7,
    required this.workouts7,
  });

  static const empty = DayJournalData(
    foods: [],
    doses: [],
    workouts: [],
    waters: [],
    last7: [],
    workouts7: [],
  );
}

class FoodLogFeedback {
  final int? savedFoodId;
  final int? savedDoseId;
  final double stockShortfall;
  final int? shortfallProductId;
  final String summaryText;
  final List<UlFlag> newUlFlags;
  final List<String> stillOverUlLines;
  final List<MealSugarAlert> mealsOverSugar;
  final bool failed;

  const FoodLogFeedback({
    this.savedFoodId,
    this.savedDoseId,
    this.stockShortfall = 0,
    this.shortfallProductId,
    required this.summaryText,
    this.newUlFlags = const [],
    this.stillOverUlLines = const [],
    this.mealsOverSugar = const [],
    this.failed = false,
  });
}

sealed class DoseLogOutcome {
  const DoseLogOutcome();
}

final class DoseLogged extends DoseLogOutcome {
  final FoodLogFeedback feedback;
  const DoseLogged(this.feedback);
}

final class DoseNeedsExpiredChoice extends DoseLogOutcome {
  const DoseNeedsExpiredChoice();
}

class DiaryController extends ChangeNotifier {
  final ReferencePack pack;
  JournalRepository? _repo;
  FoodLibraryRepository? _foodLibrary;
  bool _foodLibraryBroken = false;

  Profile? _profile;
  bool _hideCalories = false;
  bool _caution = false;
  double _lastWaterMl = 250.0;
  int? _ageBumpedNotice;
  DayTimesSettings _dayTimesSettings = const DayTimesSettings();
  bool _notificationsEnabled = false;
  List<Schedule> _todaySchedules = const [];
  List<Schedule> _yesterdaySchedules = const [];
  List<Occurrence> _todayOccurrences = const [];
  List<Occurrence> _yesterdayOccurrences = const [];
  List<ProductSummary> _allProducts = const [];
  Map<int, List<ProductIngredient>> _ingredientsByProduct = const {};
  String? _dismissedScheduleNoticeSig;
  String? _hiddenTipDay;
  DateTime _day = _dateOnly(DateTime.now());
  DayJournalData _data = DayJournalData.empty;
  bool _saveFailed = false;
  bool _readFailed = false;
  int _loadGen = 0;

  DiaryController({
    required this.pack,
    JournalRepository? repo,
    FoodLibraryRepository? foodLibrary,
  })  : _repo = repo,
        _foodLibrary = foodLibrary;

  FoodLibraryRepository? get foodLibrary => _foodLibrary;
  bool get foodLibraryBroken => _foodLibraryBroken;
  Profile? get profile => _profile;
  bool get hideCalories => _hideCalories;
  bool get caution => _caution;
  double get lastWaterMl => _lastWaterMl;
  int? get ageBumpedNotice => _ageBumpedNotice;
  DayTimesSettings get dayTimesSettings => _dayTimesSettings;
  bool get notificationsEnabled => _notificationsEnabled;
  List<Schedule> get todaySchedules => _todaySchedules;
  List<Schedule> get yesterdaySchedules => _yesterdaySchedules;
  List<Occurrence> get todayOccurrences => _todayOccurrences;
  List<Occurrence> get yesterdayOccurrences => _yesterdayOccurrences;
  List<ProductSummary> get allProducts => _allProducts;
  Map<int, List<ProductIngredient>> get ingredientsByProduct => _ingredientsByProduct;
  String? get dismissedScheduleNoticeSig => _dismissedScheduleNoticeSig;
  bool get tipHiddenToday => _hiddenTipDay == dayKey(_day);
  DateTime get day => _day;
  bool get isViewingToday => dayKey(_day) == dayKey(DateTime.now());
  bool get saveFailed => _saveFailed;
  bool get readFailed => _readFailed;

  List<FoodEntry> get todayFoods => _data.foods;
  List<DoseEntry> get todayDoses => _data.doses;
  List<WorkoutRecord> get todayWorkouts => _data.workouts;
  List<WaterRecord> get todayWaters => _data.waters;
  double get todayWaterTotalMl => _data.waters.fold<double>(0, (s, w) => s + w.ml);
  List<WorkoutEntry> get todayWorkoutEntries => [for (final w in _data.workouts) w.workout];
  List<IntakeItem> get todayItems => intakeItemsFor(_data.foods, _data.doses);

  void attachRepository(JournalRepository? repo) {
    _repo = repo;
  }

  void setFoodLibrary({FoodLibraryRepository? repository, bool broken = false}) {
    _foodLibrary = repository;
    _foodLibraryBroken = broken;
    notifyListeners();
  }

  void clear() {
    _loadGen++;
    _profile = null;
    _hideCalories = false;
    _caution = false;
    _lastWaterMl = 250.0;
    _ageBumpedNotice = null;
    _dayTimesSettings = const DayTimesSettings();
    _notificationsEnabled = false;
    _todaySchedules = const [];
    _yesterdaySchedules = const [];
    _todayOccurrences = const [];
    _yesterdayOccurrences = const [];
    _allProducts = const [];
    _ingredientsByProduct = const {};
    _dismissedScheduleNoticeSig = null;
    _hiddenTipDay = null;
    _data = DayJournalData.empty;
    notifyListeners();
  }

  void clearSaveFailed() {
    _saveFailed = false;
    notifyListeners();
  }

  void clearReadFailed() {
    _readFailed = false;
    notifyListeners();
  }

  static DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  /// Bữa mặc định theo giờ trong ngày (07:00, 12:00, 19:00 ± 1,5 giờ).
  static Meal defaultMealFor(DateTime now) {
    final mins = now.hour * 60 + now.minute;
    if ((mins - 7 * 60).abs() <= 90) return Meal.breakfast;
    if ((mins - 12 * 60).abs() <= 90) return Meal.lunch;
    if ((mins - 19 * 60).abs() <= 90) return Meal.dinner;
    return Meal.snack;
  }

  /// Giờ mặc định khi ghi cho [day] và [meal]: hôm nay -> giờ hiện tại; ngày cũ -> giờ đại diện bữa.
  static DateTime defaultAtFor(DateTime day, Meal meal, {DateTime? now}) {
    final current = now ?? DateTime.now();
    if (dayKey(day) == dayKey(current)) {
      return DateTime(day.year, day.month, day.day, current.hour, current.minute, current.second);
    }
    final (h, m) = switch (meal) {
      Meal.breakfast => (7, 0),
      Meal.lunch => (12, 0),
      Meal.dinner => (19, 0),
      Meal.snack => (15, 0),
    };
    return DateTime(day.year, day.month, day.day, h, m);
  }

  DateTime atNow() {
    final n = DateTime.now();
    return DateTime(_day.year, _day.month, _day.day, n.hour, n.minute, n.second);
  }

  Future<void> setDay(DateTime d) async {
    _day = _dateOnly(d);
    notifyListeners();
    await reload();
  }

  Future<void> reload() async {
    final repo = _repo;
    if (repo == null) return;
    final gen = ++_loadGen;
    final day = _day;
    final toDay = dayKey(day);
    final yesterdayKey = dayKey(day.subtract(const Duration(days: 1)));
    try {
      final results = await Future.wait([
        repo.loadProfile(),
        repo.loadHideCalories(),
        repo.loadConsentProfile(),
        repo.lastWaterMl(),
        repo.loadAgeBumpedNotice(),
        _loadDayAndWindow(repo, day),
        repo.loadDayTimesSettings(),
        repo.latestNotificationConsent(),
        repo.schedulesOn(toDay),
        repo.schedulesOn(yesterdayKey),
        repo.occurrencesOn(toDay),
        repo.occurrencesOn(yesterdayKey),
        repo.listProducts(),
        repo.getUiState('dismissed_schedule_notice_sig'),
        repo.getUiState('hidden_tip_day'),
      ]);
      if (gen != _loadGen) return;
      final products = results[12] as List<ProductSummary>;
      final details = await Future.wait([
        for (final p in products) repo.productDetail(p.product.id),
      ]);
      if (gen != _loadGen) return;
      _profile = results[0] as Profile?;
      _hideCalories = (results[1] as bool?) ?? false;
      final consentProfile = results[2] as ConsentProfileState?;
      _caution = consentProfile?.caution ?? false;
      _lastWaterMl = (results[3] as double?) ?? 250.0;
      _ageBumpedNotice = results[4] as int?;
      _data = results[5] as DayJournalData;
      _dayTimesSettings = results[6] as DayTimesSettings;
      _notificationsEnabled = results[7] != null;
      _todaySchedules = results[8] as List<Schedule>;
      _yesterdaySchedules = results[9] as List<Schedule>;
      _todayOccurrences = results[10] as List<Occurrence>;
      _yesterdayOccurrences = results[11] as List<Occurrence>;
      _allProducts = products;
      _ingredientsByProduct = {
        for (final d in details) d.product.id: d.ingredients,
      };
      _dismissedScheduleNoticeSig = results[13] as String?;
      _hiddenTipDay = results[14] as String?;
      _readFailed = false;
    } on JournalStorageException {
      if (gen == _loadGen) _readFailed = true;
    } on StorageFullException {
      if (gen == _loadGen) _readFailed = true;
    }
    notifyListeners();
  }

  /// Chỉ chạy 1 lần khi phiên vào trạng thái `ready` (`start()` / `onResume`), không gọi trong [reload].
  Future<void> checkAgeBumpOnReady({DateTime? now}) async {
    final repo = _repo;
    if (repo == null) return;
    try {
      final bumped = await repo.bumpAgeIfDue(now ?? DateTime.now());
      final notice = await repo.loadAgeBumpedNotice();
      final p = bumped == null ? _profile : await repo.loadProfile();
      if (bumped != null) _profile = p;
      _ageBumpedNotice = notice;
      notifyListeners();
    } on JournalStorageException {
      // Không chặn mở app nếu kiểm tra tự tăng tuổi lỗi tạm.
    } on StorageFullException {
      // Không chặn mở app nếu đầy bộ nhớ khi tự tăng tuổi.
    }
  }

  Future<void> dismissAgeBumpedNotice() async {
    final repo = _repo;
    _ageBumpedNotice = null;
    notifyListeners();
    if (repo == null) return;
    try {
      await repo.clearAgeBumpedNotice();
    } on JournalStorageException {
      // Bỏ qua nếu xóa khóa UI lỗi.
    } on StorageFullException {
      // Bỏ qua nếu đầy bộ nhớ.
    }
  }

  static Future<DayJournalData> _loadDayAndWindow(JournalRepository repo, DateTime day) async {
    final toDay = dayKey(day);
    final fromDay = dayKey(day.subtract(const Duration(days: 6)));

    final results = await Future.wait([
      repo.foodsBetween(fromDay, toDay),
      repo.dosesBetween(fromDay, toDay),
      repo.workoutsBetween(fromDay, toDay),
      repo.waterOn(toDay),
    ]);

    final allFoods = results[0] as List<FoodEntry>;
    final allDoses = results[1] as List<DoseEntry>;
    final allWorkouts = results[2] as List<WorkoutRecord>;
    final waters = results[3] as List<WaterRecord>;

    final foodsByDay = <String, List<FoodEntry>>{};
    for (final f in allFoods) {
      (foodsByDay[f.day] ??= []).add(f);
    }
    final dosesByDay = <String, List<DoseEntry>>{};
    for (final d in allDoses) {
      (dosesByDay[d.day] ??= []).add(d);
    }

    final last7 = <List<IntakeItem>>[];
    for (var i = 6; i >= 0; i--) {
      final k = dayKey(day.subtract(Duration(days: i)));
      final items = intakeItemsFor(foodsByDay[k] ?? const [], dosesByDay[k] ?? const []);
      if (items.isNotEmpty) last7.add(items);
    }

    return DayJournalData(
      foods: foodsByDay[toDay] ?? const [],
      doses: dosesByDay[toDay] ?? const [],
      workouts: [for (final w in allWorkouts) if (w.day == toDay) w],
      waters: waters,
      last7: last7,
      workouts7: [for (final w in allWorkouts) w.workout],
    );
  }

  Future<T?> _write<T>(Future<T> Function(JournalRepository repo) fn) async {
    final repo = _repo;
    if (repo == null) return null;
    try {
      final res = await fn(repo);
      _saveFailed = false;
      await reload();
      return res;
    } on StorageFullException {
      _saveFailed = true;
    } on JournalStorageException {
      _saveFailed = true;
    }
    notifyListeners();
    return null;
  }

  Future<bool> setHideCalories(bool v) async =>
      (await _write((repo) async {
        await repo.saveHideCalories(v);
        return true;
      })) ??
      false;

  Future<bool> saveBodyProfileForOnboarding(Profile p) async =>
      (await _write((repo) async {
        await repo.saveProfile(p);
        await repo.saveOnboardingStep(OnboardingStep.calorieDisplay);
        return true;
      })) ??
      false;

  Future<bool> completeCalorieDisplayOnboarding(bool hideCalories) async =>
      (await _write((repo) async {
        await repo.saveHideCalories(hideCalories);
        await repo.saveOnboardingStep(OnboardingStep.done);
        return true;
      })) ??
      false;

  Future<void> saveProfileAndDone(Profile p) => _write((repo) async {
        await repo.saveProfile(p);
        await repo.saveOnboardingStep(OnboardingStep.done);
      });

  Future<bool> saveProfileFromSettings(Profile p, {required bool caution}) async =>
      (await _write((repo) async {
        await repo.saveProfileWithCaution(p, caution: caution);
        await repo.clearAgeBumpedNotice();
        return true;
      })) ??
      false;

  DateTime defaultWaterAt([DateTime? now]) {
    final current = now ?? DateTime.now();
    if (dayKey(_day) == dayKey(current)) {
      return DateTime(_day.year, _day.month, _day.day, current.hour, current.minute, current.second);
    }
    return DateTime(_day.year, _day.month, _day.day, 12, 0);
  }

  Future<int?> addWater(DateTime at, double ml) => _write((repo) => repo.addWater(at, ml));

  Future<int?> quickAddWater({DateTime? now}) => addWater(defaultWaterAt(now), _lastWaterMl);

  Future<bool> updateWater(int id, {required DateTime at, required double ml}) async =>
      (await _write((repo) async {
        await repo.updateWater(id, at: at, ml: ml);
        return true;
      })) ??
      false;

  Future<bool> deleteWater(int id) async =>
      (await _write((repo) async {
        await repo.deleteWater(id);
        return true;
      })) ??
      false;

  Future<List<FoodEntry>> recentFoods({int limit = 10}) async {
    final repo = _repo;
    if (repo == null) return const [];
    return repo.recentFoods(limit: limit);
  }

  Future<List<FoodSummary>> searchLibrary(String query, {int limit = 30}) async {
    final fl = _foodLibrary;
    if (fl == null || _foodLibraryBroken) return const [];
    return fl.search(query, limit: limit);
  }

  Future<FoodDetail?> getLibraryFood(String foodRef) async {
    final fl = _foodLibrary;
    if (fl == null || _foodLibraryBroken) return null;
    return fl.getById(foodRef);
  }

  Future<List<CustomFood>> searchCustomFoods(String query, {int limit = 30}) async {
    final repo = _repo;
    if (repo == null) return const [];
    return repo.searchCustomFoods(query, limit: limit);
  }

  Future<void> archiveCustomFood(int id) => _write((repo) => repo.archiveCustomFood(id));

  /// Ghi món từ thư viện với khẩu phần đã chọn, trả phản hồi cho Snack/WarningSheet.
  Future<FoodLogFeedback> recordLibraryFood({
    required FoodDetail food,
    required String portionUnit,
    required double portionQty,
    required double grams,
    required Meal meal,
    required DateTime at,
    String summaryVerb = 'Đã ghi',
  }) async {
    final fl = _foodLibrary;
    if (fl == null || _foodLibraryBroken) {
      return const FoodLogFeedback(summaryText: 'Chưa lưu được. Thử lại', failed: true);
    }
    final lines = fl.computeLines(food, grams, pack: pack);
    final input = FoodEntryInput(
      at: at,
      meal: meal,
      name: food.nameVi,
      foodRef: food.id,
      portionUnit: portionUnit,
      portionQty: portionQty,
      addedSugarKnown: food.addedSugarKnown,
      packVersion: pack.version,
      lines: lines,
    );
    return _recordFoodEntry(input, summaryVerb: summaryVerb);
  }

  /// Ghi món gần đây (mở nhanh ≤3 chạm): món thư viện tính lại theo gói, món nhãn giữ nguyên.
  Future<FoodLogFeedback> logRecentFood(FoodEntry sample, {required Meal meal, DateTime? at}) async {
    final useAt = at ?? defaultAtFor(_day, meal);
    final ref = sample.foodRef;
    if (ref != null && !ref.startsWith('custom:') && _foodLibrary != null && !_foodLibraryBroken) {
      final detail = await _foodLibrary!.getById(ref);
      if (detail != null) {
        final grams = detail.gramsForPortion(sample.portionUnit, sample.portionQty);
        if (grams != null && grams > 0) {
          return recordLibraryFood(
            food: detail,
            portionUnit: sample.portionUnit,
            portionQty: sample.portionQty,
            grams: grams,
            meal: meal,
            at: useAt,
          );
        }
      }
    }
    // Fallback an toàn cho món nhãn, món custom hoặc món không còn trong thư viện mới.
    return _recordFoodEntry(FoodEntryInput(
      at: useAt,
      meal: meal,
      name: sample.name,
      foodRef: sample.foodRef,
      portionUnit: sample.portionUnit,
      portionQty: sample.portionQty,
      labelBasisQty: sample.labelBasisQty,
      labelBasisUnit: sample.labelBasisUnit,
      addedSugarKnown: sample.addedSugarKnown,
      packVersion: sample.packVersion,
      lines: sample.lines,
    ));
  }

  /// Ghi món từ Nhập theo nhãn (tùy chọn lưu vào `custom_foods`).
  Future<FoodLogFeedback> recordLabelFood(
    LabelFoodDraft draft, {
    required bool saveForReuse,
  }) async {
    final repo = _repo;
    if (repo == null) {
      return const FoodLogFeedback(summaryText: 'Chưa lưu được. Thử lại', failed: true);
    }
    final built = LabelFoodBuilder.build(draft, pack: pack, profile: _profile);
    final prevReport = report();
    try {
      String? ref;
      if (saveForReuse) {
        final cid = await repo.saveCustomFood(built.customFoodInput);
        ref = 'custom:$cid';
      }
      final input = FoodEntryInput(
        at: built.entryInput.at,
        meal: built.entryInput.meal,
        name: built.entryInput.name,
        foodRef: ref,
        portionUnit: built.entryInput.portionUnit,
        portionQty: built.entryInput.portionQty,
        labelBasisQty: built.entryInput.labelBasisQty,
        labelBasisUnit: built.entryInput.labelBasisUnit,
        addedSugarKnown: built.entryInput.addedSugarKnown,
        packVersion: built.entryInput.packVersion,
        lines: built.entryInput.lines,
      );
      final id = await repo.addFood(input);
      _saveFailed = false;
      await reload();
      return _feedbackAfterChange(
        savedFoodId: id,
        summaryText: 'Đã ghi ${input.name}, ${_qtyLabel(input.portionQty)} ${input.portionUnit}',
        prevReport: prevReport,
        nextReport: report(),
        addedLines: input.lines,
      );
    } on StorageFullException {
      _saveFailed = true;
    } on JournalStorageException {
      _saveFailed = true;
    }
    notifyListeners();
    return const FoodLogFeedback(summaryText: 'Chưa lưu được. Thử lại', failed: true);
  }

  /// Ghi món từ `Món bạn đã lưu` (`custom:<id>`).
  Future<FoodLogFeedback> recordCustomFood(
    CustomFood custom, {
    required double usedQty,
    required Meal meal,
    required DateTime at,
  }) {
    final input = LabelFoodBuilder.entryFromCustomFood(
      custom,
      usedQty: usedQty,
      meal: meal,
      at: at,
      pack: pack,
    );
    return _recordFoodEntry(input);
  }

  /// Sửa mục món ăn đã ghi (khẩu phần, bữa, ngày, giờ) trong một giao dịch duy nhất.
  Future<FoodLogFeedback> updateLoggedFood(
    FoodEntry old, {
    required double newQty,
    String? newPortionUnit,
    double? newGramsIfLibrary,
    required Meal newMeal,
    required DateTime newAt,
  }) async {
    final repo = _repo;
    if (repo == null) {
      return const FoodLogFeedback(summaryText: 'Chưa lưu được. Thử lại', failed: true);
    }
    final targetDayKey = dayKey(newAt);
    final isSameViewedDay = targetDayKey == dayKey(_day);
    final prevTargetReport = isSameViewedDay ? report() : await _reportForDay(repo, _dateOnly(newAt));
    final targetUnit = newPortionUnit ?? old.portionUnit;
    var updatedLines = old.lines;

    try {
      final qtyChanged = (newQty - old.portionQty).abs() > 1e-9 || targetUnit != old.portionUnit;
      final metaChanged = newMeal != old.meal || newAt != old.at;

      if (qtyChanged) {
        if (old.labelBasisQty != null) {
          await repo.scaleLabelFoodPortion(old.id, newQty, at: newAt, meal: newMeal);
          final reloaded = await repo.foodById(old.id);
          if (reloaded != null) updatedLines = reloaded.lines;
        } else {
          FoodDetail? detail;
          final ref = old.foodRef;
          if (ref != null && !ref.startsWith('custom:') && _foodLibrary != null && !_foodLibraryBroken) {
            detail = await _foodLibrary!.getById(ref);
          }
          final grams = detail == null
              ? null
              : (newGramsIfLibrary ?? detail.gramsForPortion(targetUnit, newQty));
          if (detail != null && grams != null && grams > 0) {
            updatedLines = _foodLibrary!.computeLines(detail, grams, pack: pack);
            await repo.replaceFoodLines(
              old.id,
              portionQty: newQty,
              portionUnit: targetUnit,
              at: newAt,
              meal: newMeal,
              lines: updatedLines,
              packVersion: pack.version,
            );
          } else {
            // Fallback an toàn nếu món hoặc tên khẩu phần cũ không còn trong thư viện mới.
            final factor = newQty / old.portionQty;
            updatedLines = [for (final l in old.lines) l.scaled(factor)];
            await repo.replaceFoodLines(
              old.id,
              portionQty: newQty,
              portionUnit: targetUnit,
              at: newAt,
              meal: newMeal,
              lines: updatedLines,
              packVersion: old.packVersion,
            );
          }
        }
      } else if (metaChanged) {
        await repo.updateFoodMeta(old.id, at: newAt, meal: newMeal);
      }

      _saveFailed = false;
      await reload();
      final nextTargetReport = isSameViewedDay ? report() : await _reportForDay(repo, _dateOnly(newAt));
      return _feedbackAfterChange(
        savedFoodId: old.id,
        summaryText: 'Đã lưu ${old.name}, ${_qtyLabel(newQty)} $targetUnit',
        prevReport: prevTargetReport,
        nextReport: nextTargetReport,
        addedLines: updatedLines,
      );
    } on StorageFullException {
      _saveFailed = true;
    } on JournalStorageException {
      _saveFailed = true;
    }
    notifyListeners();
    return const FoodLogFeedback(summaryText: 'Chưa lưu được. Thử lại', failed: true);
  }

  Future<DailyReport?> _reportForDay(JournalRepository repo, DateTime targetDate) async {
    final p = _profile ?? await repo.loadProfile();
    if (p == null) return null;
    final data = await _loadDayAndWindow(repo, targetDate);
    return dailyReport(
      pack,
      p,
      intakeItemsFor(data.foods, data.doses),
      workouts: [for (final w in data.workouts) w.workout],
      last7Days: data.last7,
      workouts7: data.workouts7,
    );
  }

  Future<void> deleteFoodEntry(int id) => _write((repo) => repo.deleteFood(id));

  Future<FoodLogFeedback> _recordFoodEntry(
    FoodEntryInput input, {
    String summaryVerb = 'Đã ghi',
  }) async {
    final repo = _repo;
    if (repo == null) {
      return const FoodLogFeedback(summaryText: 'Chưa lưu được. Thử lại', failed: true);
    }
    final prevReport = report();
    try {
      final id = await repo.addFood(input);
      _saveFailed = false;
      await reload();
      return _feedbackAfterChange(
        savedFoodId: id,
        summaryText: '$summaryVerb ${input.name}, ${_qtyLabel(input.portionQty)} ${input.portionUnit}',
        prevReport: prevReport,
        nextReport: report(),
        addedLines: input.lines,
      );
    } on StorageFullException {
      _saveFailed = true;
    } on JournalStorageException {
      _saveFailed = true;
    }
    notifyListeners();
    return const FoodLogFeedback(summaryText: 'Chưa lưu được. Thử lại', failed: true);
  }

  FoodLogFeedback _feedbackAfterChange({
    required int savedFoodId,
    required String summaryText,
    required DailyReport? prevReport,
    required DailyReport? nextReport,
    required List<IntakeLine> addedLines,
  }) {
    if (nextReport == null) {
      return FoodLogFeedback(savedFoodId: savedFoodId, summaryText: summaryText);
    }
    final prevKeys = {
      for (final f in prevReport?.ulFlags ?? const <UlFlag>[]) (f.nutrientId, f.kind),
    };
    final newFlags = [
      for (final f in nextReport.ulFlags)
        if (!prevKeys.contains((f.nutrientId, f.kind))) f,
    ];
    final addedKeys = {
      for (final l in addedLines) ...l.amounts.keys,
      for (final l in addedLines) ...?l.ulAmounts?.keys,
    };
    final stillOver = <String>[];
    if (newFlags.isEmpty) {
      final seenNut = <String>{};
      for (final f in nextReport.ulFlags) {
        if (f.kind == UlFlagKind.daily && seenNut.add(f.nutrientId)) {
          final ulDef = pack.nutrients[f.nutrientId];
          final touches = addedKeys.contains(f.nutrientId) ||
              (ulDef?.id == 'retinol' && addedKeys.contains('retinol')) ||
              (ulDef?.id == 'folicAcid' && addedKeys.contains('folicAcid'));
          if (touches && ulDef != null) {
            stillOver.add('${ulDef.nameVi} vẫn vượt giới hạn: ${_qtyLabel(f.amount)} ${ulDef.unit}');
          }
        }
      }
    }
    return FoodLogFeedback(
      savedFoodId: savedFoodId,
      summaryText: summaryText,
      newUlFlags: newFlags,
      stillOverUlLines: stillOver,
      mealsOverSugar: nextReport.sugar.mealsOverLimit,
    );
  }

  static String _qtyLabel(double v) {
    if ((v - v.roundToDouble()).abs() < 1e-6) return v.round().toString();
    return v.toStringAsFixed(2).replaceAll(RegExp(r'\.?0+$'), '').replaceAll('.', ',');
  }

  // ---- Các API tương thích với khung tạm cũ ----

  Future<void> addItem(IntakeItem it) {
    final keys = {...it.nutrients.keys, ...?it.ulNutrients?.keys};
    final lines = [
      for (final k in keys)
        IntakeLine(
          nutrientId: k,
          source: it.source,
          amounts: it.nutrients.containsKey(k) ? {k: it.nutrients[k]!} : const {},
          ulAmounts: it.ulNutrients != null && it.ulNutrients!.containsKey(k)
              ? {k: it.ulNutrients![k]!}
              : null,
        ),
    ];
    final at = it.at ?? atNow();
    if (it.source == IntakeSource.supplement) {
      return _write((repo) => repo.recordDose(DoseInput(
            at: at,
            name: it.label,
            kind: DoseKind.oneOff,
            servings: 1,
            packVersion: pack.version,
            lines: lines,
          )));
    }
    return _write((repo) => repo.addFood(FoodEntryInput(
          at: at,
          meal: _mealFromSlot(it.meal),
          name: it.label,
          portionUnit: 'phần',
          portionQty: 1,
          addedSugarKnown: it.addedSugarKnown,
          packVersion: pack.version,
          lines: lines,
        )));
  }

  Future<void> recordDose(String name, List<IntakeLine> lines) => _write((repo) => repo.recordDose(DoseInput(
        at: atNow(),
        name: name,
        kind: DoseKind.oneOff,
        servings: 1,
        packVersion: pack.version,
        lines: lines,
      )));

  Future<void> deleteDoseEntry(int id) => _write((repo) => repo.deleteDose(id));

  // ---- Sản phẩm bổ sung, kho, hộp, ghi/sửa lần uống (Việc 5) ----

  Future<List<ProductSummary>> listProducts({bool includeArchived = false}) async {
    final repo = _repo;
    if (repo == null) return const [];
    try {
      return await repo.listProducts(includeArchived: includeArchived);
    } on Object {
      return const [];
    }
  }

  Future<ProductDetail?> getProductDetail(int productId) async {
    final repo = _repo;
    if (repo == null) return null;
    try {
      return await repo.productDetail(productId);
    } on Object {
      return null;
    }
  }

  Future<Product?> findProductByBarcode(String barcode) async {
    final repo = _repo;
    if (repo == null) return null;
    try {
      return await repo.productByBarcode(barcode);
    } on Object {
      return null;
    }
  }

  Future<int?> createProductWithIngredientsAndBox({
    required String name,
    required CountUnit countUnit,
    required double unitsPerServing,
    String? barcode,
    required List<IngredientDraft> ingredients,
    double? initialBoxRemaining,
    String? initialBoxExpiryMonth,
  }) =>
      _write((repo) async {
        final pid = await repo.addProduct(
          name,
          countUnit,
          unitsPerServing,
          barcode: barcode,
        );
        await repo.saveProductIngredients(pid, ingredients);
        if (initialBoxRemaining != null && initialBoxRemaining >= 0) {
          await repo.addBox(pid, initialBoxRemaining, expiryMonth: initialBoxExpiryMonth);
        }
        return pid;
      });

  Future<bool> updateProductInfo(
    int id, {
    required String name,
    required CountUnit countUnit,
    required double unitsPerServing,
    String? barcode,
  }) async =>
      await _write((repo) async {
        await repo.updateProduct(
          id,
          name: name,
          countUnit: countUnit,
          unitsPerServing: unitsPerServing,
          barcode: barcode,
        );
        return true;
      }) ??
      false;

  Future<bool> saveProductIngredients(int productId, List<IngredientDraft> items) async =>
      await _write((repo) async {
        await repo.saveProductIngredients(productId, items);
        return true;
      }) ??
      false;

  Future<bool> archiveProduct(int id) async =>
      await _write((repo) async {
        await repo.archiveProduct(id);
        return true;
      }) ??
      false;

  Future<int?> addProductBox(
    int productId, {
    required double remaining,
    String? expiryMonth,
  }) =>
      _write((repo) => repo.addBox(productId, remaining, expiryMonth: expiryMonth));

  Future<bool> updateProductBox(
    int boxId, {
    required double remaining,
    String? expiryMonth,
  }) async =>
      await _write((repo) async {
        await repo.updateBox(boxId, remaining: remaining, expiryMonth: expiryMonth);
        return true;
      }) ??
      false;

  Future<bool> deleteProductBox(int boxId) async =>
      await _write((repo) async {
        await repo.deleteBox(boxId);
        return true;
      }) ??
      false;

  /// Chuyển danh sách thành phần sản phẩm thành `IntakeLine` cho [servings] khẩu phần.
  List<IntakeLine> buildDoseLinesFromIngredients(
    List<ProductIngredient> ingredients,
    double servings,
  ) {
    final conv = UnitConverter(pack);
    final out = <IntakeLine>[];
    for (final ing in ingredients) {
      if (ing.nutrientId == null || ing.labelAmount == null || ing.labelUnit == null) {
        if (ing.freeName != null && ing.freeName!.trim().isNotEmpty) {
          out.add(IntakeLine(
            freeName: ing.freeName,
            source: IntakeSource.supplement,
            form: ing.form,
            labelAmount: ing.labelAmount == null ? null : ing.labelAmount! * servings,
            labelUnit: ing.labelUnit,
            amounts: const {},
          ));
        }
        continue;
      }
      final lu = LabelUnit.values.where((u) => u.name == ing.labelUnit).firstOrNull;
      if (lu == null) continue;
      final converted = conv.convertIntakeLine(IntakeLineInput(
        nutrientId: ing.nutrientId,
        source: IntakeSource.supplement,
        form: ing.form,
        amount: ing.labelAmount! * servings,
        unit: lu,
        compoundKind: ing.isCompound
            ? (ing.form == NutrientForm.unknown ? CompoundKind.unknown : CompoundKind.compound)
            : CompoundKind.elemental,
      ));
      out.add(IntakeLine(
        nutrientId: ing.nutrientId,
        source: IntakeSource.supplement,
        form: ing.form,
        uncertain: converted.uncertain,
        labelAmount: ing.labelAmount! * servings,
        labelUnit: ing.labelUnit,
        amounts: converted.amounts,
        ulAmounts: converted.ulAmounts,
      ));
    }
    return out;
  }

  Future<DoseLogOutcome> recordSupplementDose({
    int? productId,
    String? name,
    required double servings,
    required DateTime at,
    required List<IntakeLine> lines,
    ExpiredBoxChoice expiredBoxes = ExpiredBoxChoice.ask,
    OccurrenceRef? occurrence,
    bool skipAutoMatch = false,
    required String summaryLabel,
  }) async {
    final repo = _repo;
    if (repo == null) {
      return const DoseLogged(FoodLogFeedback(summaryText: 'Không lưu được.', failed: true));
    }
    try {
      OccurrenceRef? resolvedOcc = occurrence;
      if (resolvedOcc == null && !skipAutoMatch && productId != null) {
        final match = await findUnmarkedWindowMatch(productId: productId, at: at);
        if (match != null) {
          resolvedOcc = OccurrenceRef(match.scheduleId, match.day);
        }
      }
      final before = await _reportForDay(repo, at);
      final res = await repo.recordDose(DoseInput(
        at: at,
        productId: productId,
        name: name,
        kind: resolvedOcc != null
            ? DoseKind.scheduled
            : (productId == null ? DoseKind.oneOff : DoseKind.extra),
        servings: servings,
        packVersion: pack.version,
        lines: lines,
        expiredBoxes: expiredBoxes,
        occurrence: resolvedOcc,
      ));
      if (res is NeedsExpiredChoice) {
        return const DoseNeedsExpiredChoice();
      }
      final recorded = res as DoseRecorded;
      final after = await _reportForDay(repo, at);
      await reload();
      return DoseLogged(_buildDoseFeedback(
        doseId: recorded.id,
        shortfall: recorded.shortfall,
        productId: productId,
        summaryLabel: summaryLabel,
        before: before,
        after: after,
      ));
    } on StorageFullException {
      _saveFailed = true;
      notifyListeners();
      return const DoseLogged(FoodLogFeedback(
        summaryText: 'Máy không còn đủ dung lượng. Hãy giải phóng bộ nhớ.',
        failed: true,
      ));
    } on JournalStorageException {
      _saveFailed = true;
      notifyListeners();
      return const DoseLogged(FoodLogFeedback(summaryText: 'Không lưu được.', failed: true));
    }
  }

  Future<DoseLogOutcome> updateSupplementDose({
    required int doseId,
    int? productId,
    String? name,
    required double servings,
    required DateTime at,
    required List<IntakeLine> lines,
    ExpiredBoxChoice expiredBoxes = ExpiredBoxChoice.ask,
    bool relinkSchedule = true,
    required String summaryLabel,
  }) async {
    final repo = _repo;
    if (repo == null) {
      return const DoseLogged(FoodLogFeedback(summaryText: 'Không lưu được.', failed: true));
    }
    try {
      final before = await _reportForDay(repo, at);
      final res = await repo.updateDose(UpdateDoseInput(
        doseId: doseId,
        name: name,
        servings: servings,
        at: at,
        packVersion: pack.version,
        lines: lines,
        expiredBoxes: expiredBoxes,
      ));
      if (res is NeedsExpiredChoice) {
        return const DoseNeedsExpiredChoice();
      }
      if (relinkSchedule && productId != null) {
        final match = await findUnmarkedWindowMatch(
          productId: productId,
          at: at,
          ignoringDoseId: doseId,
        );
        await repo.relinkDoseOccurrence(
          doseId,
          match == null ? null : OccurrenceRef(match.scheduleId, match.day),
        );
      }
      final recorded = res as DoseRecorded;
      final after = await _reportForDay(repo, at);
      await reload();
      return DoseLogged(_buildDoseFeedback(
        doseId: recorded.id,
        shortfall: recorded.shortfall,
        productId: productId,
        summaryLabel: summaryLabel,
        before: before,
        after: after,
      ));
    } on StorageFullException {
      _saveFailed = true;
      notifyListeners();
      return const DoseLogged(FoodLogFeedback(
        summaryText: 'Máy không còn đủ dung lượng. Hãy giải phóng bộ nhớ.',
        failed: true,
      ));
    } on JournalStorageException {
      _saveFailed = true;
      notifyListeners();
      return const DoseLogged(FoodLogFeedback(summaryText: 'Không lưu được.', failed: true));
    }
  }

  FoodLogFeedback _buildDoseFeedback({
    required int doseId,
    required double shortfall,
    required int? productId,
    required String summaryLabel,
    required DailyReport? before,
    required DailyReport? after,
  }) {
    final beforeKeys = {
      for (final f in before?.ulFlags ?? const <UlFlag>[]) (f.nutrientId, f.kind),
    };
    final newFlags = [
      for (final f in after?.ulFlags ?? const <UlFlag>[])
        if (!beforeKeys.contains((f.nutrientId, f.kind))) f,
    ];
    final stillOver = <String>[];
    if (newFlags.isEmpty && after != null) {
      for (final f in after.ulFlags) {
        final name = pack.nutrients[f.nutrientId]?.nameVi ?? f.nutrientId;
        stillOver.add('Đã vượt giới hạn $name');
      }
    }
    final summary = shortfall > 0 && newFlags.isEmpty
        ? 'Đã ghi $summaryLabel · Kho đã hết'
        : 'Đã ghi $summaryLabel';
    return FoodLogFeedback(
      savedDoseId: doseId,
      stockShortfall: shortfall,
      shortfallProductId: shortfall > 0 ? productId : null,
      summaryText: summary,
      newUlFlags: newFlags,
      stillOverUlLines: stillOver,
    );
  }

  Future<void> removeItemByIndex(int index) {
    var i = index;
    for (final f in _data.foods) {
      final items = intakeItemsOfFood(f);
      if (i < items.length) return deleteFoodEntry(f.id);
      i -= items.length;
    }
    for (final d in _data.doses) {
      final items = intakeItemsOfDose(d);
      if (i < items.length) return deleteDoseEntry(d.id);
      i -= items.length;
    }
    return Future.value();
  }

  Future<void> addWorkout(WorkoutEntry w) => _write((repo) => repo.addWorkout(atNow(), w));

  Future<void> removeWorkoutByIndex(int index) {
    final ws = _data.workouts;
    if (index < 0 || index >= ws.length) return Future.value();
    return _write((repo) => repo.deleteWorkout(ws[index].id));
  }

  DailyReport? report() {
    final p = _profile;
    if (p == null) return null;
    return dailyReport(
      pack,
      p,
      todayItems,
      workouts: todayWorkoutEntries,
      last7Days: _data.last7,
      workouts7: _data.workouts7,
    );
  }

  ActivityLevel suggestedLevel() => suggestActivityLevel(pack, _data.workouts7);

  // ---- Lịch uống, Giờ trong ngày, Nhắc giờ & Bạn có biết (Việc 6) ----

  Future<bool> saveDayTimesSettings(DayTimesSettings settings) async =>
      (await _write((repo) async {
        await repo.saveDayTimesSettings(settings);
        return true;
      })) ??
      false;

  Future<bool> saveShowTipCard(bool show) async =>
      (await _write((repo) async {
        await repo.saveShowTipCard(show);
        return true;
      })) ??
      false;

  Future<bool> grantNotificationConsent(String contentVersion) async =>
      (await _write((repo) async {
        await repo.grantNotificationConsent(contentVersion);
        return true;
      })) ??
      false;

  Future<bool> withdrawNotificationConsent() async =>
      (await _write((repo) async {
        await repo.withdrawNotificationConsent();
        return true;
      })) ??
      false;

  Future<void> dismissScheduleNotices(String signature) =>
      _write((repo) => repo.setUiState('dismissed_schedule_notice_sig', signature));

  Future<void> hideTipCardForToday() =>
      _write((repo) => repo.setUiState('hidden_tip_day', dayKey(_day)));

  Future<int?> addSchedule(int productId, int timeOfDay, double servings, {required String validFrom}) =>
      _write((repo) => repo.addSchedule(productId, timeOfDay, servings, validFrom: validFrom));

  Future<ScheduleChange?> updateSchedule(
    int id, {
    int? timeOfDay,
    double? servings,
    required String today,
  }) =>
      _write((repo) => repo.updateSchedule(id, timeOfDay: timeOfDay, servings: servings, today: today));

  Future<void> endSchedule(int id, {required String today}) =>
      _write((repo) => repo.endSchedule(id, today: today));

  Future<void> skipOccurrence(OccurrenceRef o) =>
      _write((repo) => repo.skipOccurrence(o));

  Future<void> clearOccurrence(OccurrenceRef o) =>
      _write((repo) => repo.clearOccurrence(o));

  /// Khớp lần ghi lúc [at] vào một lần theo lịch chưa đánh dấu trong khung ±2 giờ (xét cả ngày trước).
  Future<ScheduleMatch?> findUnmarkedWindowMatch({
    required int productId,
    required DateTime at,
    int? ignoringDoseId,
  }) async {
    final repo = _repo;
    if (repo == null) return null;
    final dStr = dayKey(at);
    final prevStr = dayKey(at.subtract(const Duration(days: 1)));
    final res = await Future.wait([
      repo.schedulesOn(dStr),
      repo.schedulesOn(prevStr),
      repo.occurrencesOn(dStr),
      repo.occurrencesOn(prevStr),
    ]);
    final sToday = res[0] as List<Schedule>;
    final sPrev = res[1] as List<Schedule>;
    final oToday = res[2] as List<Occurrence>;
    final oPrev = res[3] as List<Occurrence>;

    final markedToday = {
      for (final o in oToday)
        if (ignoringDoseId == null || o.doseEntryId != ignoringDoseId) o.scheduleId,
    };
    final markedPrev = {
      for (final o in oPrev)
        if (ignoringDoseId == null || o.doseEntryId != ignoringDoseId) o.scheduleId,
    };

    final candidates = <ScheduleCandidate>[
      for (final s in sPrev)
        if (!markedPrev.contains(s.id))
          ScheduleCandidate(scheduleId: s.id, productId: s.productId, day: prevStr, timeOfDay: s.timeOfDay),
      for (final s in sToday)
        if (!markedToday.contains(s.id))
          ScheduleCandidate(scheduleId: s.id, productId: s.productId, day: dStr, timeOfDay: s.timeOfDay),
    ];
    return matchDoseToScheduleWindow(at, productId, candidates);
  }

  /// Kiểm tra vượt UL theo tổng lịch hằng ngày (kèm override cho màn Đặt lịch xem trước).
  List<UlFlag> scheduledUlFlags({List<Schedule>? overrideSchedules}) {
    final p = _profile;
    if (p == null) return const [];
    final scheds = overrideSchedules ?? _todaySchedules;
    if (scheds.isEmpty) return const [];
    final prodMap = {for (final s in _allProducts) s.product.id: s.product.name};
    final items = <IntakeItem>[];
    for (final s in scheds) {
      final ings = _ingredientsByProduct[s.productId];
      if (ings == null || ings.isEmpty) continue;
      final lines = buildDoseLinesFromIngredients(ings, s.servings);
      final nuts = <String, double>{};
      final ulNuts = <String, double>{};
      for (final l in lines) {
        if (l.nutrientId == null) continue;
        l.amounts.forEach((k, v) {
          nuts[k] = (nuts[k] ?? 0) + v;
        });
        l.ulAmounts?.forEach((k, v) {
          ulNuts[k] = (ulNuts[k] ?? 0) + v;
        });
      }
      if (nuts.isNotEmpty) {
        items.add(IntakeItem(
          label: prodMap[s.productId] ?? 'Bổ sung #${s.productId}',
          source: IntakeSource.supplement,
          nutrients: nuts,
          ulNutrients: ulNuts.isEmpty ? null : ulNuts,
        ));
      }
    }
    return checkUlSchedule(pack, p, items);
  }

  /// Đánh giá 5 quy tắc lịch từ gói dữ liệu (thuần dữ liệu).
  List<ScheduleNotice> scheduleNotices({List<Schedule>? overrideSchedules}) {
    final scheds = overrideSchedules ?? _todaySchedules;
    if (scheds.isEmpty) return const [];
    final mealTimes = MealTimes(
      breakfast: _dayTimesSettings.breakfast,
      lunch: _dayTimesSettings.lunch,
      dinner: _dayTimesSettings.dinner,
    );
    final inputs = <ScheduledDoseInput>[];
    for (final s in scheds) {
      final ings = _ingredientsByProduct[s.productId] ?? const [];
      final lines = buildDoseLinesFromIngredients(ings, s.servings);
      final nuts = <ScheduledNutrient>[];
      for (final l in lines) {
        if (l.nutrientId == null) continue;
        final val = l.amounts[l.nutrientId!];
        if (val != null && val > 0) {
          nuts.add(ScheduledNutrient(nutrientId: l.nutrientId!, form: l.form ?? 'unknown', amount: val));
        }
      }
      inputs.add(ScheduledDoseInput(
        scheduleId: s.id,
        productId: s.productId,
        timeOfDay: s.timeOfDay,
        nutrients: nuts,
      ));
    }
    return evaluateScheduleRules(pack, mealTimes, inputs);
  }

  String scheduleNoticeSignature(List<ScheduleNotice> notices) {
    final keys = [
      for (final n in notices) '${n.ruleId}@${n.timeOfDay}@${n.productIds.join(",")}',
    ]..sort();
    return keys.join('|');
  }

  /// Chọn câu "Bạn có biết" cho hôm nay (1 câu/ngày, ẩn nếu vượt UL hoặc đã bấm Ẩn).
  ScheduleRule? todayTipRule({required bool hasUlWarnings}) {
    if (!isViewingToday || !_dayTimesSettings.showTipCard || hasUlWarnings || tipHiddenToday) {
      return null;
    }
    final activeRuleIds = {
      for (final n in scheduleNotices())
        if (n.severity == 'notice') n.ruleId,
    };
    final inStockNutrients = <String>{};
    for (final s in _allProducts) {
      for (final ing in _ingredientsByProduct[s.product.id] ?? const <ProductIngredient>[]) {
        if (ing.nutrientId != null) inStockNutrients.add(ing.nutrientId!);
      }
    }
    final eligible = [
      for (final r in pack.scheduleRules)
        if (!activeRuleIds.contains(r.id) && r.nutrients.every(inStockNutrients.contains)) r,
    ];
    if (eligible.isEmpty) return null;
    final dayIdx = _day.difference(DateTime(2026, 1, 1)).inDays.abs();
    return eligible[dayIdx % eligible.length];
  }

  List<ScheduledReminderSlot> buildReminderSlots() {
    final byTime = <int, List<int>>{};
    for (final s in _todaySchedules) {
      (byTime[s.timeOfDay] ??= []).add(s.id);
    }
    final times = byTime.keys.toList()..sort();
    return [
      for (final t in times)
        ScheduledReminderSlot(
          timeOfDayMinutes: t,
          itemCount: byTime[t]!.length,
          scheduleIds: byTime[t]!,
        ),
    ];
  }

  static Meal _mealFromSlot(MealSlot? s) => switch (s) {
        MealSlot.breakfast => Meal.breakfast,
        MealSlot.lunch => Meal.lunch,
        MealSlot.dinner => Meal.dinner,
        MealSlot.snack || null => Meal.snack,
      };
}
