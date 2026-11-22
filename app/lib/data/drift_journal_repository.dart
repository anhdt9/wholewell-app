import 'package:drift/drift.dart';
import 'package:health_engine/health_engine.dart';

import '../state/journal_repository.dart';
import 'database.dart';
import 'units.dart';

const _hideCaloriesKey = 'hideCalories';

/// [JournalRepository] trên CSDL mã hóa. Mọi lượng chất lưu kèm đơn vị của gói;
/// đọc ra mà đơn vị khác gói thì ném [UnitMismatch].
class DriftJournalRepository implements JournalRepository {
  final AppDatabase db;
  final Map<String, String> units;
  final DateTime Function() _now;

  DriftJournalRepository(this.db, ReferencePack pack, {DateTime Function()? now})
      : units = unitTable(pack),
        _now = now ?? DateTime.now;

  int get _nowMs => _now().toUtc().millisecondsSinceEpoch;

  int? _primaryId;

  Future<int> _primaryPerson() async {
    final cached = _primaryId;
    if (cached != null) return cached;
    final row = await (db.select(db.people)..where((p) => p.isPrimary.equals(true))).getSingleOrNull();
    final id = row?.id ??
        await db.into(db.people).insert(PeopleCompanion.insert(
              displayName: 'Tôi',
              isPrimary: const Value(true),
              createdAt: _nowMs,
            ));
    return _primaryId = id;
  }

  // ---- Hồ sơ ----

  @override
  Future<Profile?> loadProfile() async {
    final pid = await _primaryPerson();
    final r = await (db.select(db.profiles)..where((p) => p.personId.equals(pid))).getSingleOrNull();
    if (r == null) return null;
    return Profile(
      ageYears: r.ageYears,
      sex: r.sex,
      heightCm: r.heightCm,
      weightKg: r.weightKg,
      stage: r.stage,
      gestationWeek: r.gestationWeek,
      prePregnancyBmi: r.prePregnancyBmi,
      monthsPostpartum: r.monthsPostpartum,
      activityLevel: r.activityLevel,
    );
  }

  @override
  Future<void> saveProfile(Profile p) async {
    final pid = await _primaryPerson();
    await db.into(db.profiles).insertOnConflictUpdate(ProfilesCompanion.insert(
          personId: Value(pid),
          ageYears: p.ageYears,
          sex: p.sex,
          heightCm: p.heightCm,
          weightKg: p.weightKg,
          stage: p.stage,
          gestationWeek: Value(p.gestationWeek),
          prePregnancyBmi: Value(p.prePregnancyBmi),
          monthsPostpartum: Value(p.monthsPostpartum),
          activityLevel: p.activityLevel,
          updatedAt: _nowMs,
        ));
  }

  @override
  Future<bool> loadHideCalories() async {
    final r = await (db.select(db.settings)..where((s) => s.key.equals(_hideCaloriesKey))).getSingleOrNull();
    return r?.value == '1';
  }

  @override
  Future<void> saveHideCalories(bool v) => db
      .into(db.settings)
      .insertOnConflictUpdate(SettingsCompanion.insert(key: _hideCaloriesKey, value: v ? '1' : '0'));

  // ---- Món ăn, đồ uống, liều bổ sung ----

  @override
  Future<List<Stored<IntakeItem>>> itemsBetween(DateTime from, DateTime to) async {
    final pid = await _primaryPerson();
    final f = dayKey(from), t = dayKey(to);
    final entries = await (db.select(db.intakeEntries)
          ..where((e) => e.personId.equals(pid) & e.day.isBetweenValues(f, t))
          ..orderBy([(e) => OrderingTerm(expression: e.day), (e) => OrderingTerm(expression: e.id)]))
        .get();
    if (entries.isEmpty) return const [];

    final ids = db.selectOnly(db.intakeEntries)
      ..addColumns([db.intakeEntries.id])
      ..where(db.intakeEntries.personId.equals(pid) & db.intakeEntries.day.isBetweenValues(f, t));
    final rows = await (db.select(db.intakeNutrients)..where((n) => n.entryId.isInQuery(ids))).get();

    final byEntry = <int, Map<String, double>>{};
    for (final n in rows) {
      final expected = units[n.nutrientId];
      if (expected == null) throw UnknownNutrient(n.nutrientId);
      if (n.unit != expected) throw UnitMismatch(n.nutrientId, n.unit, expected);
      (byEntry[n.entryId] ??= {})[n.nutrientId] = n.amount;
    }

    return [
      for (final e in entries)
        Stored(
          e.id,
          parseDayKey(e.day),
          IntakeItem(
            label: e.label,
            source: e.source,
            mealId: e.mealId,
            nutrients: Map.unmodifiable(byEntry[e.id] ?? const <String, double>{}),
          ),
        ),
    ];
  }

  @override
  Future<int> addItem(DateTime day, IntakeItem it) async {
    for (final k in it.nutrients.keys) {
      if (!units.containsKey(k)) throw UnknownNutrient(k);
    }
    final pid = await _primaryPerson();
    return db.transaction(() async {
      final id = await db.into(db.intakeEntries).insert(IntakeEntriesCompanion.insert(
            personId: pid,
            day: dayKey(day),
            label: it.label,
            source: it.source,
            mealId: Value(it.mealId),
            createdAt: _nowMs,
          ));
      await db.batch((b) => b.insertAll(db.intakeNutrients, [
            for (final e in it.nutrients.entries)
              IntakeNutrientsCompanion.insert(
                entryId: id,
                nutrientId: e.key,
                amount: e.value,
                unit: units[e.key]!,
              ),
          ]));
      return id;
    });
  }

  @override
  Future<void> removeItem(int id) =>
      (db.delete(db.intakeEntries)..where((e) => e.id.equals(id))).go();

  // ---- Buổi tập ----

  @override
  Future<List<Stored<WorkoutEntry>>> workoutsBetween(DateTime from, DateTime to) async {
    final pid = await _primaryPerson();
    final rows = await (db.select(db.workouts)
          ..where((w) => w.personId.equals(pid) & w.day.isBetweenValues(dayKey(from), dayKey(to)))
          ..orderBy([(w) => OrderingTerm(expression: w.day), (w) => OrderingTerm(expression: w.id)]))
        .get();
    return [
      for (final w in rows)
        Stored(w.id, parseDayKey(w.day), WorkoutEntry(activityCode: w.activityCode, minutes: w.minutes)),
    ];
  }

  @override
  Future<int> addWorkout(DateTime day, WorkoutEntry w) async {
    final pid = await _primaryPerson();
    return db.into(db.workouts).insert(WorkoutsCompanion.insert(
          personId: pid,
          day: dayKey(day),
          activityCode: w.activityCode,
          minutes: w.minutes,
          createdAt: _nowMs,
        ));
  }

  @override
  Future<void> removeWorkout(int id) => (db.delete(db.workouts)..where((w) => w.id.equals(id))).go();
}
