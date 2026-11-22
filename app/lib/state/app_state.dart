import 'package:flutter/foundation.dart';
import 'package:health_engine/health_engine.dart';

import 'journal_repository.dart';

/// Trạng thái app. Toàn bộ dữ liệu ở máy; lưu trữ qua [JournalRepository].
class AppState extends ChangeNotifier {
  final ReferencePack pack;
  final JournalRepository repo;

  Profile? _profile;
  bool _hideCalories = false;
  DateTime _day = _dateOnly(DateTime.now());

  AppState({required this.pack, required this.repo}) {
    _profile = repo.loadProfile();
    _hideCalories = repo.loadHideCalories();
  }

  Profile? get profile => _profile;
  bool get hideCalories => _hideCalories;
  DateTime get day => _day;

  List<IntakeItem> get todayItems => repo.itemsOn(_day);
  List<WorkoutEntry> get todayWorkouts => repo.workoutsOn(_day);

  void saveProfile(Profile p) {
    _profile = p;
    repo.saveProfile(p);
    notifyListeners();
  }

  void setHideCalories(bool v) {
    _hideCalories = v;
    repo.saveHideCalories(v);
    notifyListeners();
  }

  void setDay(DateTime d) {
    _day = _dateOnly(d);
    notifyListeners();
  }

  void addItem(IntakeItem it) {
    repo.addItem(_day, it);
    notifyListeners();
  }

  void removeItem(int index) {
    repo.removeItem(_day, index);
    notifyListeners();
  }

  void addWorkout(WorkoutEntry w) {
    repo.addWorkout(_day, w);
    notifyListeners();
  }

  void removeWorkout(int index) {
    repo.removeWorkout(_day, index);
    notifyListeners();
  }

  /// Báo cáo cho ngày đang xem; null khi chưa có hồ sơ.
  DailyReport? report() {
    final p = _profile;
    if (p == null) return null;
    final last7 = [
      for (var i = 6; i >= 0; i--) repo.itemsOn(_day.subtract(Duration(days: i))),
    ];
    return dailyReport(pack, p, todayItems, workouts: todayWorkouts, last7Days: last7);
  }

  /// Gợi ý mức vận động từ buổi tập 7 ngày gần nhất.
  ActivityLevel suggestedLevel() {
    final ws = [
      for (var i = 6; i >= 0; i--) ...repo.workoutsOn(_day.subtract(Duration(days: i))),
    ];
    return suggestActivityLevel(pack, ws);
  }

  static DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);
}
