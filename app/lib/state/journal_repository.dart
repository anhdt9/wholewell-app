import 'package:health_engine/health_engine.dart';

/// Một bản ghi đã lưu: id trong kho lưu trữ, ngày, giá trị.
class Stored<T> {
  final int id;
  final DateTime day;
  final T value;
  const Stored(this.id, this.day, this.value);
}

/// Lưu trữ nhật ký của người dùng chính. Bản thật: [DriftJournalRepository]
/// (CSDL mã hóa); bản giả: [InMemoryJournalRepository].
///
/// Ngày luôn là ngày theo giờ máy (bỏ giờ phút). Khoảng ngày gồm cả hai đầu.
abstract class JournalRepository {
  Future<Profile?> loadProfile();
  Future<void> saveProfile(Profile p);
  Future<bool> loadHideCalories();
  Future<void> saveHideCalories(bool v);

  Future<List<Stored<IntakeItem>>> itemsBetween(DateTime from, DateTime to);
  Future<int> addItem(DateTime day, IntakeItem it);
  Future<void> removeItem(int id);

  Future<List<Stored<WorkoutEntry>>> workoutsBetween(DateTime from, DateTime to);
  Future<int> addWorkout(DateTime day, WorkoutEntry w);
  Future<void> removeWorkout(int id);
}

DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

class InMemoryJournalRepository implements JournalRepository {
  Profile? _profile;
  bool _hide = false;
  int _nextId = 1;
  final List<Stored<IntakeItem>> _items = [];
  final List<Stored<WorkoutEntry>> _workouts = [];

  @override
  Future<Profile?> loadProfile() async => _profile;
  @override
  Future<void> saveProfile(Profile p) async => _profile = p;
  @override
  Future<bool> loadHideCalories() async => _hide;
  @override
  Future<void> saveHideCalories(bool v) async => _hide = v;

  static bool _within(DateTime d, DateTime from, DateTime to) =>
      !d.isBefore(dateOnly(from)) && !d.isAfter(dateOnly(to));

  @override
  Future<List<Stored<IntakeItem>>> itemsBetween(DateTime from, DateTime to) async =>
      [for (final s in _items) if (_within(s.day, from, to)) s];

  @override
  Future<int> addItem(DateTime day, IntakeItem it) async {
    final id = _nextId++;
    _items.add(Stored(id, dateOnly(day), it));
    return id;
  }

  @override
  Future<void> removeItem(int id) async => _items.removeWhere((s) => s.id == id);

  @override
  Future<List<Stored<WorkoutEntry>>> workoutsBetween(DateTime from, DateTime to) async =>
      [for (final s in _workouts) if (_within(s.day, from, to)) s];

  @override
  Future<int> addWorkout(DateTime day, WorkoutEntry w) async {
    final id = _nextId++;
    _workouts.add(Stored(id, dateOnly(day), w));
    return id;
  }

  @override
  Future<void> removeWorkout(int id) async => _workouts.removeWhere((s) => s.id == id);
}
