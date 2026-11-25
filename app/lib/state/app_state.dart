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

  /// Nền tảng chưa có kho khóa (iOS, máy tính): chưa làm trong MVP.
  unsupportedPlatform,
}

/// Khung tạm chưa có màn Điều kiện, Đồng ý (việc 4): lần lưu hồ sơ đầu tiên là bước
/// đồng ý, câu thuốc, bệnh ghi "Không". **Chỉ để thử nội bộ, không phát cho người
/// thử bên ngoài.** Việc 4 phải phát hiện phiên bản này và hỏi lại cả màn Điều kiện
/// lẫn Đồng ý.
const khungTamConsentVersion = 'khung-tam-0';

class _Entry {
  final bool isDose;
  final int id;
  final List<IntakeItem> items;
  const _Entry(this.isDose, this.id, this.items);
}

class _DayData {
  final List<_Entry> entries;
  final List<WorkoutRecord> workouts;
  final List<List<IntakeItem>> last7;
  final List<WorkoutEntry> workouts7;
  const _DayData(this.entries, this.workouts, this.last7, this.workouts7);
}

Meal _mealFromSlot(MealSlot? s) => switch (s) {
      MealSlot.breakfast => Meal.breakfast,
      MealSlot.lunch => Meal.lunch,
      MealSlot.dinner => Meal.dinner,
      MealSlot.snack || null => Meal.snack,
    };

/// Trạng thái app. Toàn bộ dữ liệu ở máy, trong CSDL mã hóa ([DbOpener]).
class AppState extends ChangeNotifier {
  final ReferencePack pack;
  final DbOpener? _opener;
  JournalRepository? _repo;
  DataStatus _status;

  Profile? _profile;
  bool _hideCalories = false;
  DateTime _day = _dateOnly(DateTime.now());
  _DayData _data = const _DayData([], [], [], []);
  bool _saveFailed = false;
  bool _readFailed = false;

  /// Mỗi lần đọc lấy một số thế hệ; kết quả của lần đọc cũ hơn bị bỏ.
  int _loadGen = 0;
  Future<void>? _starting;

  AppState({required this.pack, required DbOpener opener})
      : _opener = opener,
        _status = DataStatus.loading;

  /// Dùng một nhật ký có sẵn (test giao diện với bản bộ nhớ).
  AppState.withRepository({required this.pack, required JournalRepository repo})
      : _opener = null,
        _repo = repo,
        _status = DataStatus.ready;

  /// Nền tảng chưa có kho khóa: không mở, không ghi gì.
  AppState.unsupportedPlatform({required this.pack})
      : _opener = null,
        _status = DataStatus.unsupportedPlatform;

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

  /// Lần đọc gần nhất lỗi (CSDL vẫn mở): báo kèm [Thử lại], không dẫn tới [Bắt đầu lại].
  bool get readFailed => _readFailed;
  void clearReadFailed() {
    _readFailed = false;
    notifyListeners();
  }

  List<IntakeItem> get todayItems => [for (final e in _data.entries) ...e.items];
  List<WorkoutEntry> get todayWorkouts => [for (final w in _data.workouts) w.workout];

  /// Mở CSDL (khi app hiện lên, khi app trở lại, khi bấm [Thử lại]). Gọi chồng thì
  /// dùng chung lần đang chạy.
  Future<void> start() => _starting ??= _start().whenComplete(() => _starting = null);

  Future<void> _start() async {
    final o = _opener;
    if (o != null) {
      final old = _repo;
      _repo = null;
      if (old != null) await old.close();
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

  /// [Bắt đầu lại] sau khi gõ XÓA: đóng nhật ký nếu đang mở, xóa dữ liệu trên máy.
  Future<void> startOver() async {
    final o = _opener;
    if (o == null) return;
    final repo = _repo;
    _repo = null;
    await o.startOver(openRepository: repo);
    _loadGen++;
    _profile = null;
    _hideCalories = false;
    _data = const _DayData([], [], [], []);
    _status = DataStatus.welcome;
    notifyListeners();
  }

  /// [Thử lại] sau khi đọc lỗi.
  Future<void> reload() async {
    await _reload();
    notifyListeners();
  }

  Future<void> _reload() async {
    final repo = _repo;
    if (repo == null) return;
    final gen = ++_loadGen;
    final day = _day;
    try {
      final profile = await repo.loadProfile();
      final hide = await repo.loadHideCalories() ?? false;
      final data = await _loadDay(repo, day);
      if (gen != _loadGen) return;
      _profile = profile;
      _hideCalories = hide;
      _data = data;
      _readFailed = false;
    } on JournalStorageException {
      if (gen == _loadGen) _readFailed = true;
    } on StorageFullException {
      if (gen == _loadGen) _readFailed = true;
    }
  }

  static Future<_DayData> _loadDay(JournalRepository repo, DateTime day) async {
    final key = dayKey(day);
    final entries = [
      for (final f in await repo.foodsOn(key)) _Entry(false, f.id, intakeItemsOfFood(f)),
      for (final d in await repo.dosesOn(key)) _Entry(true, d.id, intakeItemsOfDose(d)),
    ];
    final workouts = await repo.workoutsOn(key);
    final last7 = <List<IntakeItem>>[];
    final ws = <WorkoutEntry>[];
    for (var i = 6; i >= 0; i--) {
      final d = dayKey(day.subtract(Duration(days: i)));
      final items = intakeItemsFor(await repo.foodsOn(d), await repo.dosesOn(d));
      if (items.isNotEmpty) last7.add(items);
      ws.addAll([for (final w in await repo.workoutsOn(d)) w.workout]);
    }
    return _DayData(entries, workouts, last7, ws);
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
      try {
        _apply(await o.createNew(
            ConsentInput(contentVersion: khungTamConsentVersion, ageYears: p.ageYears, caution: false)));
      } on DbAlreadyExistsException {
        // Đã có CSDL (không đúng màn Chào mừng): mở lại theo luồng thường.
        await start();
        return;
      }
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
    final at = it.at ?? _atNow();
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

  /// Ghi một lần bổ sung với danh sách [IntakeLine] đã quy đổi sẵn (gồm cả `ulAmounts`).
  Future<void> recordDose(String name, List<IntakeLine> lines) => _write((repo) => repo.recordDose(DoseInput(
        at: _atNow(),
        name: name,
        kind: DoseKind.oneOff,
        servings: 1,
        packVersion: pack.version,
        lines: lines,
      )));

  Future<void> removeItem(int index) {
    var i = index;
    for (final e in _data.entries) {
      if (i < e.items.length) {
        return _write((repo) => e.isDose ? repo.deleteDose(e.id) : repo.deleteFood(e.id));
      }
      i -= e.items.length;
    }
    return Future.value();
  }

  Future<void> addWorkout(WorkoutEntry w) => _write((repo) => repo.addWorkout(_atNow(), w));

  Future<void> removeWorkout(int index) {
    final ws = _data.workouts;
    if (index < 0 || index >= ws.length) return Future.value();
    final id = ws[index].id;
    return _write((repo) => repo.deleteWorkout(id));
  }

  /// Báo cáo cho ngày đang xem; null khi chưa có hồ sơ.
  DailyReport? report() {
    final p = _profile;
    if (p == null) return null;
    return dailyReport(
      pack,
      p,
      todayItems,
      workouts: todayWorkouts,
      last7Days: _data.last7,
      workouts7: _data.workouts7,
    );
  }

  /// Gợi ý mức vận động từ buổi tập 7 ngày gần nhất.
  ActivityLevel suggestedLevel() => suggestActivityLevel(pack, _data.workouts7);

  static DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);
}
