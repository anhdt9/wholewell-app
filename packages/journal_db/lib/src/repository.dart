/// Lưu trữ nhật ký, bất đồng bộ (đặc tả encrypted-db, mục Interface).
library;

import 'dart:async';

import 'package:health_engine/health_engine.dart';

import 'intake.dart';
import 'models.dart';

/// Phần lưu trữ mà trạng thái app dùng. Kho, lịch uống chỉ có ở bản CSDL
/// ([DriftJournalRepository]); bản bộ nhớ dùng để test giao diện.
abstract interface class JournalRepository {
  /// Phát sau mỗi lần ghi.
  Stream<void> get changes;

  /// null khi chưa xong Hồ sơ cơ thể (giới tính, chiều cao, cân nặng còn trống).
  Future<Profile?> loadProfile();
  Future<void> saveProfile(Profile p);

  /// null: chưa chọn (màn Hiển thị calo không chọn sẵn).
  Future<bool?> loadHideCalories();
  Future<void> saveHideCalories(bool v);

  Future<OnboardingStep> loadOnboardingStep();
  Future<void> saveOnboardingStep(OnboardingStep s);

  Future<int> addFood(FoodEntryInput e);
  Future<void> deleteFood(int id);
  Future<List<FoodEntry>> foodsOn(String day);

  Future<DoseResult> recordDose(DoseInput d);
  Future<void> deleteDose(int id);
  Future<List<DoseEntry>> dosesOn(String day);

  Future<int> addWorkout(DateTime startAt, WorkoutEntry w);
  Future<void> deleteWorkout(int id);
  Future<List<WorkoutRecord>> workoutsOn(String day);

  Future<void> close();
}

/// Bản bộ nhớ (test giao diện). Không có kho: lần uống không trừ hộp nào.
class InMemoryJournalRepository implements JournalRepository {
  final _changes = StreamController<void>.broadcast();
  Profile? _profile;
  bool? _hide;
  OnboardingStep _step = OnboardingStep.bodyProfile;
  final _foods = <FoodEntry>[];
  final _doses = <DoseEntry>[];
  final _workouts = <WorkoutRecord>[];
  int _nextId = 1;

  void _changed() => _changes.add(null);

  @override
  Stream<void> get changes => _changes.stream;

  @override
  Future<Profile?> loadProfile() async => _profile;
  @override
  Future<void> saveProfile(Profile p) async {
    _profile = p;
    _changed();
  }

  @override
  Future<bool?> loadHideCalories() async => _hide;
  @override
  Future<void> saveHideCalories(bool v) async {
    _hide = v;
    _changed();
  }

  @override
  Future<OnboardingStep> loadOnboardingStep() async => _step;
  @override
  Future<void> saveOnboardingStep(OnboardingStep s) async {
    _step = s;
    _changed();
  }

  @override
  Future<int> addFood(FoodEntryInput e) async {
    checkLinesWritable(e.lines);
    final id = _nextId++;
    _foods.add(FoodEntry(
      id: id,
      at: e.at,
      day: dayKey(e.at),
      meal: e.meal,
      name: e.name,
      foodRef: e.foodRef,
      portionUnit: e.portionUnit,
      portionQty: e.portionQty,
      labelBasisQty: e.labelBasisQty,
      labelBasisUnit: e.labelBasisUnit,
      addedSugarKnown: e.addedSugarKnown,
      packVersion: e.packVersion,
      lines: List.unmodifiable(e.lines),
    ));
    _changed();
    return id;
  }

  @override
  Future<void> deleteFood(int id) async {
    _foods.removeWhere((f) => f.id == id);
    _changed();
  }

  @override
  Future<List<FoodEntry>> foodsOn(String day) async =>
      [for (final f in _foods) if (f.day == day) f]..sort((a, b) => a.at.compareTo(b.at));

  @override
  Future<DoseResult> recordDose(DoseInput d) async {
    checkLinesWritable(d.lines);
    final id = _nextId++;
    _doses.add(DoseEntry(
      id: id,
      at: d.at,
      day: dayKey(d.at),
      productId: d.productId,
      name: d.name,
      kind: d.kind,
      servings: d.servings,
      packVersion: d.packVersion,
      lines: List.unmodifiable(d.lines),
      deductions: const [],
    ));
    _changed();
    return DoseRecorded(id, 0);
  }

  @override
  Future<void> deleteDose(int id) async {
    _doses.removeWhere((d) => d.id == id);
    _changed();
  }

  @override
  Future<List<DoseEntry>> dosesOn(String day) async =>
      [for (final d in _doses) if (d.day == day) d]..sort((a, b) => a.at.compareTo(b.at));

  @override
  Future<int> addWorkout(DateTime startAt, WorkoutEntry w) async {
    final id = _nextId++;
    _workouts.add(WorkoutRecord(id, startAt, dayKey(startAt), w));
    _changed();
    return id;
  }

  @override
  Future<void> deleteWorkout(int id) async {
    _workouts.removeWhere((w) => w.id == id);
    _changed();
  }

  @override
  Future<List<WorkoutRecord>> workoutsOn(String day) async =>
      [for (final w in _workouts) if (w.day == day) w]..sort((a, b) => a.startAt.compareTo(b.startAt));

  @override
  Future<void> close() async => _changes.close();
}
