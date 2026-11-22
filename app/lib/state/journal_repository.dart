import 'package:health_engine/health_engine.dart';

/// Lưu trữ nhật ký. Bản MVP dùng bộ nhớ; bản sau thay bằng drift +
/// SQLite3MultipleCiphers (khóa trong flutter_secure_storage) theo plan.
abstract class JournalRepository {
  Profile? loadProfile();
  void saveProfile(Profile p);
  bool loadHideCalories();
  void saveHideCalories(bool v);

  List<IntakeItem> itemsOn(DateTime day);
  void addItem(DateTime day, IntakeItem it);
  void removeItem(DateTime day, int index);

  List<WorkoutEntry> workoutsOn(DateTime day);
  void addWorkout(DateTime day, WorkoutEntry w);
  void removeWorkout(DateTime day, int index);
}

class InMemoryJournalRepository implements JournalRepository {
  Profile? _profile;
  bool _hide = false;
  final Map<DateTime, List<IntakeItem>> _items = {};
  final Map<DateTime, List<WorkoutEntry>> _workouts = {};

  @override
  Profile? loadProfile() => _profile;
  @override
  void saveProfile(Profile p) => _profile = p;
  @override
  bool loadHideCalories() => _hide;
  @override
  void saveHideCalories(bool v) => _hide = v;

  @override
  List<IntakeItem> itemsOn(DateTime day) => List.unmodifiable(_items[day] ?? const []);
  @override
  void addItem(DateTime day, IntakeItem it) => (_items[day] ??= []).add(it);
  @override
  void removeItem(DateTime day, int index) => _items[day]?.removeAt(index);

  @override
  List<WorkoutEntry> workoutsOn(DateTime day) => List.unmodifiable(_workouts[day] ?? const []);
  @override
  void addWorkout(DateTime day, WorkoutEntry w) => (_workouts[day] ??= []).add(w);
  @override
  void removeWorkout(DateTime day, int index) => _workouts[day]?.removeAt(index);
}
