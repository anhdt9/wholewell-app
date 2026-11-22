import 'package:flutter_test/flutter_test.dart';
import 'package:health_engine/health_engine.dart';
import 'package:wholewell/data/database.dart';
import 'package:wholewell/data/drift_journal_repository.dart';
import 'package:wholewell/state/journal_repository.dart';

import 'helpers.dart';

/// Một cách tạo repository; [reopen] mô phỏng tắt app rồi mở lại.
abstract class RepoHarness {
  Future<JournalRepository> open();
  Future<JournalRepository> reopen();
  Future<void> dispose();
}

class InMemoryHarness implements RepoHarness {
  final repo = InMemoryJournalRepository();
  @override
  Future<JournalRepository> open() async => repo;
  @override
  Future<JournalRepository> reopen() async => repo;
  @override
  Future<void> dispose() async {}
}

class DriftHarness implements RepoHarness {
  final t = TempDb();
  AppDatabase? _db;

  @override
  Future<JournalRepository> open() async {
    _db = await t.open();
    return DriftJournalRepository(_db!, testPack);
  }

  @override
  Future<JournalRepository> reopen() async {
    await _db?.close();
    return open();
  }

  @override
  Future<void> dispose() async {
    await _db?.close();
    t.dispose();
  }
}

void main() {
  runContract('trong bộ nhớ', InMemoryHarness.new);
  runContract('drift, CSDL mã hóa', DriftHarness.new);
}

void runContract(String name, RepoHarness Function() make) {
  group('JournalRepository ($name)', () {
    late RepoHarness h;
    setUp(() => h = make());
    tearDown(() => h.dispose());

    final d1 = DateTime(2026, 3, 9);
    final d2 = DateTime(2026, 3, 10);

    test('chưa có gì: không hồ sơ, không ẩn calo, không món', () async {
      final r = await h.open();
      expect(await r.loadProfile(), isNull);
      expect(await r.loadHideCalories(), isFalse);
      expect(await r.itemsBetween(d1, d2), isEmpty);
      expect(await r.workoutsBetween(d1, d2), isEmpty);
    });

    test('hồ sơ đủ trường, ghi đè được, còn sau khi mở lại', () async {
      var r = await h.open();
      const p = Profile(
        ageYears: 29,
        sex: Sex.female,
        heightCm: 158.5,
        weightKg: 52.25,
        stage: LifeStage.pregnant,
        gestationWeek: 20,
        prePregnancyBmi: BmiClass.normal,
        activityLevel: ActivityLevel.lowActive,
      );
      await r.saveProfile(const Profile(ageYears: 30, sex: Sex.male, heightCm: 170, weightKg: 65));
      await r.saveProfile(p);
      r = await h.reopen();
      final got = (await r.loadProfile())!;
      expect(got.ageYears, p.ageYears);
      expect(got.sex, p.sex);
      expect(got.heightCm, p.heightCm);
      expect(got.weightKg, p.weightKg);
      expect(got.stage, p.stage);
      expect(got.gestationWeek, p.gestationWeek);
      expect(got.prePregnancyBmi, p.prePregnancyBmi);
      expect(got.monthsPostpartum, isNull);
      expect(got.activityLevel, p.activityLevel);
    });

    test('cờ ẩn calo còn sau khi mở lại', () async {
      var r = await h.open();
      await r.saveHideCalories(true);
      r = await h.reopen();
      expect(await r.loadHideCalories(), isTrue);
      await r.saveHideCalories(false);
      expect(await r.loadHideCalories(), isFalse);
    });

    test('món ăn đọc ra bằng hệt, theo khoảng ngày gồm hai đầu', () async {
      var r = await h.open();
      const a = IntakeItem(
        label: 'Cơm tấm',
        source: IntakeSource.food,
        mealId: 'trua',
        nutrients: {'energyKcal': 620, 'protein': 28.5, 'fat': 22, 'carbohydrate': 80, 'addedSugar': 6, 'iron': 2.1},
      );
      const b = IntakeItem(
        label: 'Viên magie',
        source: IntakeSource.supplement,
        nutrients: {'magnesium': 250},
      );
      const c = IntakeItem(label: 'Ngũ cốc tăng cường', source: IntakeSource.fortified, nutrients: {'folicAcid': 100});
      final idA = await r.addItem(d1, a);
      final idB = await r.addItem(DateTime(2026, 3, 10, 21, 30), b); // giờ phút bị bỏ
      await r.addItem(DateTime(2026, 3, 11), c);
      r = await h.reopen();

      final got = await r.itemsBetween(d1, d2);
      expect(got.map((s) => s.id), [idA, idB]);
      expect(got.map((s) => s.day), [d1, d2]);
      void same(IntakeItem x, IntakeItem y) {
        expect(x.label, y.label);
        expect(x.source, y.source);
        expect(x.mealId, y.mealId);
        expect(x.nutrients, y.nutrients);
      }

      same(got[0].value, a);
      same(got[1].value, b);
      expect((await r.itemsBetween(d2, d2)).single.id, idB);
    });

    test('xóa món theo id', () async {
      final r = await h.open();
      final x = await r.addItem(d1, const IntakeItem(label: 'A', source: IntakeSource.food, nutrients: {'vitC': 10}));
      final y = await r.addItem(d1, const IntakeItem(label: 'B', source: IntakeSource.food, nutrients: {'vitC': 20}));
      await r.removeItem(x);
      expect((await r.itemsBetween(d1, d1)).map((s) => s.id), [y]);
    });

    test('buổi tập ghi, đọc, xóa, còn sau khi mở lại', () async {
      var r = await h.open();
      final w1 = await r.addWorkout(d1, const WorkoutEntry(activityCode: '17200', minutes: 30));
      final w2 = await r.addWorkout(d2, const WorkoutEntry(activityCode: '12150', minutes: 45.5));
      r = await h.reopen();
      final got = await r.workoutsBetween(d1, d2);
      expect(got.map((s) => s.id), [w1, w2]);
      expect(got[1].value.activityCode, '12150');
      expect(got[1].value.minutes, 45.5);
      await r.removeWorkout(w1);
      expect((await r.workoutsBetween(d1, d2)).map((s) => s.id), [w2]);
    });
  });
}
