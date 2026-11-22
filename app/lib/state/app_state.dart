import 'package:flutter/foundation.dart';
import 'package:health_engine/health_engine.dart';

import 'journal_repository.dart';

/// Trạng thái app. Toàn bộ dữ liệu ở máy; lưu trữ qua [JournalRepository].
///
/// Giữ bộ đệm 7 ngày tính đến ngày đang xem để giao diện đọc đồng bộ;
/// mọi thay đổi ghi xuống repository rồi nạp lại bộ đệm.
class AppState extends ChangeNotifier {
  final ReferencePack pack;
  final JournalRepository repo;

  Profile? _profile;
  bool _hideCalories = false;
  DateTime _day;
  List<Stored<IntakeItem>> _items = const [];
  List<Stored<WorkoutEntry>> _workouts = const [];
  int _loadGeneration = 0;

  AppState._(this.pack, this.repo, DateTime today) : _day = dateOnly(today);

  /// Nạp hồ sơ, cài đặt và 7 ngày gần nhất từ [repo].
  static Future<AppState> load({
    required ReferencePack pack,
    required JournalRepository repo,
    DateTime? today,
  }) async {
    final s = AppState._(pack, repo, today ?? DateTime.now());
    s._profile = await repo.loadProfile();
    s._hideCalories = await repo.loadHideCalories();
    await s._reloadWindow();
    return s;
  }

  Profile? get profile => _profile;
  bool get hideCalories => _hideCalories;
  DateTime get day => _day;

  /// Lùi theo ngày lịch (không theo 24 giờ, để đúng cả khi đổi giờ mùa hè).
  DateTime _daysBefore(int n) => DateTime(_day.year, _day.month, _day.day - n);

  List<IntakeItem> get todayItems => [for (final s in _items) if (s.day == _day) s.value];
  List<WorkoutEntry> get todayWorkouts => [for (final s in _workouts) if (s.day == _day) s.value];

  Future<void> _reloadWindow() async {
    final gen = ++_loadGeneration;
    final from = _daysBefore(6);
    final items = await repo.itemsBetween(from, _day);
    final workouts = await repo.workoutsBetween(from, _day);
    if (gen != _loadGeneration) return; // đã đổi ngày trong lúc nạp
    _items = items;
    _workouts = workouts;
  }

  Future<void> saveProfile(Profile p) async {
    await repo.saveProfile(p);
    _profile = p;
    notifyListeners();
  }

  Future<void> setHideCalories(bool v) async {
    await repo.saveHideCalories(v);
    _hideCalories = v;
    notifyListeners();
  }

  Future<void> setDay(DateTime d) async {
    _day = dateOnly(d);
    notifyListeners();
    await _reloadWindow();
    notifyListeners();
  }

  Future<void> addItem(IntakeItem it) async {
    await repo.addItem(_day, it);
    await _reloadWindow();
    notifyListeners();
  }

  /// [index] là vị trí trong [todayItems]. Bỏ khỏi bộ đệm ngay (cho Dismissible),
  /// rồi xóa trong repository.
  Future<void> removeItem(int index) async {
    final today = [for (final s in _items) if (s.day == _day) s];
    final target = today[index];
    _items = [for (final s in _items) if (s.id != target.id) s];
    notifyListeners();
    await repo.removeItem(target.id);
  }

  Future<void> addWorkout(WorkoutEntry w) async {
    await repo.addWorkout(_day, w);
    await _reloadWindow();
    notifyListeners();
  }

  /// [index] là vị trí trong [todayWorkouts].
  Future<void> removeWorkout(int index) async {
    final today = [for (final s in _workouts) if (s.day == _day) s];
    final target = today[index];
    _workouts = [for (final s in _workouts) if (s.id != target.id) s];
    notifyListeners();
    await repo.removeWorkout(target.id);
  }

  /// Báo cáo cho ngày đang xem; null khi chưa có hồ sơ.
  DailyReport? report() {
    final p = _profile;
    if (p == null) return null;
    final last7 = [
      for (var i = 6; i >= 0; i--)
        [
          for (final s in _items)
            if (s.day == _daysBefore(i)) s.value,
        ],
    ];
    return dailyReport(pack, p, todayItems, workouts: todayWorkouts, last7Days: last7);
  }

  /// Gợi ý mức vận động từ buổi tập 7 ngày gần nhất.
  ActivityLevel suggestedLevel() => suggestActivityLevel(pack, [for (final s in _workouts) s.value]);
}
