import 'package:flutter/foundation.dart';
import 'package:health_engine/health_engine.dart';
import 'package:journal_db/journal_db.dart';

/// Màn trước khi vào app, theo kết quả mở CSDL (thiết kế tổng thể, dòng "Toàn app").
enum DataStatus {
  loading,
  welcome,
  ready,
  waitingForUnlock,
  keyStuck,
  cannotOpen,
  installBroken,
  needsUpdate,
  lowStorage,
}

/// Khung tạm chưa có màn Điều kiện, Đồng ý (việc 4): lần lưu hồ sơ đầu tiên là bước
/// đồng ý, câu thuốc, bệnh ghi "Không". Việc 4 thay bằng màn thật.
const khungTamConsentVersion = 'khung-tam-0';

class _Entry {
  final bool isDose;
  final int id;
  final List<IntakeItem> items;
  const _Entry(this.isDose, this.id, this.items);
}

/// Tên bữa của khung tạm. Bữa phụ hiện chung "phụ".
const _mealVi = {Meal.breakfast: 'sáng', Meal.lunch: 'trưa', Meal.dinner: 'tối', Meal.snack: 'phụ'};

Meal _mealOf(String? vi) =>
    _mealVi.entries.firstWhere((e) => e.value == vi, orElse: () => const MapEntry(Meal.snack, 'phụ')).key;

IntakeItem _withMealLabel(IntakeItem i) {
  final id = i.mealId;
  if (id == null) return i;
  final meal = id.startsWith('snack') ? Meal.snack : Meal.values.byName(id);
  return IntakeItem(label: i.label, source: i.source, mealId: _mealVi[meal], nutrients: i.nutrients);
}

/// Trạng thái app. Toàn bộ dữ liệu ở máy, trong CSDL mã hóa ([DbOpener]).
class AppState extends ChangeNotifier {
  final ReferencePack pack;
  final DbOpener? _opener;
  JournalRepository? _repo;
  DataStatus _status;

  Profile? _profile;
  bool _hideCalories = false;
  DateTime _day = _dateOnly(DateTime.now());
  List<_Entry> _entries = const [];
  List<WorkoutRecord> _workouts = const [];
  List<List<IntakeItem>> _last7 = const [];
  List<WorkoutEntry> _workouts7 = const [];
  bool _saveFailed = false;

  AppState({required this.pack, required DbOpener opener})
      : _opener = opener,
        _status = DataStatus.loading;

  /// Dùng một nhật ký có sẵn (test giao diện với bản bộ nhớ).
  AppState.withRepository({required this.pack, required JournalRepository repo})
      : _opener = null,
        _repo = repo,
        _status = DataStatus.ready;

  DataStatus get status => _status;
  Profile? get profile => _profile;
  bool get hideCalories => _hideCalories;
  DateTime get day => _day;

  /// Lần ghi gần nhất không lưu được: "Chưa lưu được. Thử lại".
  bool get saveFailed => _saveFailed;
  void clearSaveFailed() {
    _saveFailed = false;
    notifyListeners();
  }

  List<IntakeItem> get todayItems => [for (final e in _entries) ...e.items];
  List<WorkoutEntry> get todayWorkouts => [for (final w in _workouts) w.workout];

  /// Mở CSDL (khi app hiện lên, khi app trở lại, khi bấm [Thử lại]).
  Future<void> start() async {
    final o = _opener;
    if (o != null) {
      _status = DataStatus.loading;
      notifyListeners();
      _apply(await o.open());
    }
    if (_status == DataStatus.ready) await _reload();
    notifyListeners();
  }

  void _apply(OpenOutcome r) {
    _status = switch (r) {
      Opened() => DataStatus.ready,
      Welcome() => DataStatus.welcome,
      WaitingForUnlock() => DataStatus.waitingForUnlock,
      KeyStuck() => DataStatus.keyStuck,
      CannotOpen() => DataStatus.cannotOpen,
      InstallBroken() => DataStatus.installBroken,
      NeedsUpdate() => DataStatus.needsUpdate,
      LowStorage() => DataStatus.lowStorage,
    };
    if (r is Opened) _repo = r.repository;
  }

  /// [Bắt đầu lại] sau khi gõ XÓA: xóa dữ liệu trên máy, về lần đầu.
  Future<void> startOver() async {
    final o = _opener;
    if (o == null) return;
    await o.startOver();
    _repo = null;
    _profile = null;
    _hideCalories = false;
    _entries = const [];
    _workouts = const [];
    _last7 = const [];
    _workouts7 = const [];
    _status = DataStatus.welcome;
    notifyListeners();
  }

  Future<void> _reload() async {
    final repo = _repo;
    if (repo == null) return;
    try {
      _profile = await repo.loadProfile();
      _hideCalories = await repo.loadHideCalories() ?? false;
      await _loadDay(repo);
    } on JournalStorageException {
      _status = DataStatus.cannotOpen;
    }
  }

  Future<void> _loadDay(JournalRepository repo) async {
    final day = dayKey(_day);
    _entries = [
      for (final f in await repo.foodsOn(day)) _Entry(false, f.id, [for (final i in intakeItemsOfFood(f)) _withMealLabel(i)]),
      for (final d in await repo.dosesOn(day)) _Entry(true, d.id, intakeItemsOfDose(d)),
    ];
    _workouts = await repo.workoutsOn(day);
    final last7 = <List<IntakeItem>>[];
    final ws = <WorkoutEntry>[];
    for (var i = 6; i >= 0; i--) {
      final d = dayKey(_day.subtract(Duration(days: i)));
      last7.add([
        for (final x in intakeItemsFor(await repo.foodsOn(d), await repo.dosesOn(d))) _withMealLabel(x),
      ]);
      ws.addAll([for (final w in await repo.workoutsOn(d)) w.workout]);
    }
    _last7 = last7;
    _workouts7 = ws;
  }

  Future<void> _write(Future<void> Function(JournalRepository repo) f) async {
    final repo = _repo;
    if (repo == null) return;
    try {
      await f(repo);
      _saveFailed = false;
    } on StorageFullException {
      _saveFailed = true;
    } on JournalStorageException {
      _saveFailed = true;
    }
    await _reload();
    notifyListeners();
  }

  /// Khung tạm: lần lưu hồ sơ đầu tiên tạo CSDL (bước đồng ý).
  Future<void> saveProfile(Profile p) async {
    final o = _opener;
    if (_repo == null && o != null && _status == DataStatus.welcome) {
      _apply(await o.createNew(
          ConsentInput(contentVersion: khungTamConsentVersion, ageYears: p.ageYears, caution: false)));
      if (_repo == null) {
        notifyListeners();
        return;
      }
    }
    await _write((repo) async {
      await repo.saveProfile(p);
      await repo.saveOnboardingStep(OnboardingStep.done);
    });
  }

  Future<void> setHideCalories(bool v) => _write((repo) => repo.saveHideCalories(v));

  Future<void> setDay(DateTime d) async {
    _day = _dateOnly(d);
    notifyListeners();
    await _reload();
    notifyListeners();
  }

  /// Giờ ghi: ngày đang xem, giờ hiện tại.
  DateTime _atNow() {
    final n = DateTime.now();
    return DateTime(_day.year, _day.month, _day.day, n.hour, n.minute, n.second);
  }

  Future<void> addItem(IntakeItem it) {
    final lines = [
      for (final e in it.nutrients.entries)
        IntakeLine(nutrientId: e.key, source: it.source, amounts: {e.key: e.value}),
    ];
    final at = _atNow();
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
          meal: _mealOf(it.mealId),
          name: it.label,
          portionUnit: 'phần',
          portionQty: 1,
          addedSugarKnown: it.nutrients.containsKey('addedSugar'),
          packVersion: pack.version,
          lines: lines,
        )));
  }

  Future<void> removeItem(int index) {
    var i = index;
    for (final e in _entries) {
      if (i < e.items.length) {
        return _write((repo) => e.isDose ? repo.deleteDose(e.id) : repo.deleteFood(e.id));
      }
      i -= e.items.length;
    }
    return Future.value();
  }

  Future<void> addWorkout(WorkoutEntry w) => _write((repo) => repo.addWorkout(_atNow(), w));

  Future<void> removeWorkout(int index) {
    if (index < 0 || index >= _workouts.length) return Future.value();
    final id = _workouts[index].id;
    return _write((repo) => repo.deleteWorkout(id));
  }

  /// Báo cáo cho ngày đang xem; null khi chưa có hồ sơ.
  DailyReport? report() {
    final p = _profile;
    if (p == null) return null;
    return dailyReport(pack, p, todayItems, workouts: todayWorkouts, last7Days: _last7);
  }

  /// Gợi ý mức vận động từ buổi tập 7 ngày gần nhất.
  ActivityLevel suggestedLevel() => suggestActivityLevel(pack, _workouts7);

  static DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);
}
