import 'package:flutter_test/flutter_test.dart';
import 'package:health_engine/health_engine.dart';
import 'package:wholewell/data/drift_journal_repository.dart';
import 'package:wholewell/state/app_state.dart';
import 'package:wholewell/state/journal_repository.dart';

import 'data/helpers.dart';

void main() {
  final pack = testPack;
  final today = DateTime(2026, 3, 10, 9);
  const profile = Profile(ageYears: 30, sex: Sex.male, heightCm: 170, weightKg: 65);
  const magnesium = IntakeItem(
    label: 'Viên magie',
    source: IntakeSource.supplement,
    nutrients: {'magnesium': 500},
  );

  test('báo cáo ngày qua AppState, cờ UL trung bình 7 ngày', () async {
    final s = await AppState.load(pack: pack, repo: InMemoryJournalRepository(), today: today);
    expect(s.report(), isNull);
    await s.saveProfile(profile);
    await s.addItem(magnesium);
    await s.addWorkout(const WorkoutEntry(activityCode: '17200', minutes: 30));
    final r = s.report()!;
    expect(r.eerKcal, 2450);
    expect(r.ulFlags.map((f) => f.nutrientId), contains('magnesium'));
    expect(r.energyOutWorkoutKcal, closeTo(4.8 * 65 * 0.5, 1e-9));
  });

  test('ẩn số calo được lưu', () async {
    final repo = InMemoryJournalRepository();
    await (await AppState.load(pack: pack, repo: repo, today: today)).setHideCalories(true);
    expect((await AppState.load(pack: pack, repo: repo, today: today)).hideCalories, isTrue);
  });

  test('xóa theo vị trí trong ngày, không đụng ngày khác', () async {
    final s = await AppState.load(pack: pack, repo: InMemoryJournalRepository(), today: today);
    await s.addItem(const IntakeItem(label: 'Hôm nay A', source: IntakeSource.food, nutrients: {}));
    await s.addItem(const IntakeItem(label: 'Hôm nay B', source: IntakeSource.food, nutrients: {}));
    await s.setDay(DateTime(2026, 3, 9));
    await s.addItem(const IntakeItem(label: 'Hôm qua', source: IntakeSource.food, nutrients: {}));
    await s.setDay(today);
    await s.removeItem(0);
    expect(s.todayItems.map((i) => i.label), ['Hôm nay B']);
    await s.setDay(DateTime(2026, 3, 9));
    expect(s.todayItems.map((i) => i.label), ['Hôm qua']);
  });

  test('trung bình 7 ngày lấy cả các ngày trước ngày đang xem', () async {
    final repo = InMemoryJournalRepository();
    for (var i = 1; i <= 6; i++) {
      await repo.addItem(DateTime(2026, 3, 10 - i), magnesium);
    }
    final s = await AppState.load(pack: pack, repo: repo, today: today);
    await s.saveProfile(profile);
    expect(s.todayItems, isEmpty);
    // 6 × 500 mg / 7 ngày ≈ 429 mg > UL 350 mg (chỉ tính bổ sung).
    expect(s.report()!.ulFlags.map((f) => f.nutrientId), contains('magnesium'));
  });

  test('CSDL mã hóa: mở lại app, báo cáo như trước khi đóng', () async {
    final t = TempDb();
    addTearDown(t.dispose);

    var db = await t.open();
    var s = await AppState.load(pack: pack, repo: DriftJournalRepository(db, pack), today: today);
    await s.saveProfile(profile);
    await s.addItem(magnesium);
    await s.addItem(const IntakeItem(
      label: 'Bún chả',
      source: IntakeSource.food,
      nutrients: {'energyKcal': 550, 'protein': 25, 'fat': 20, 'carbohydrate': 65, 'addedSugar': 12},
    ));
    await s.addWorkout(const WorkoutEntry(activityCode: '17200', minutes: 30));
    final before = s.report()!;
    await db.close();

    db = await t.open();
    addTearDown(db.close);
    s = await AppState.load(pack: pack, repo: DriftJournalRepository(db, pack), today: today);
    final after = s.report()!;
    expect(s.todayItems, hasLength(2));
    expect(after.eerKcal, before.eerKcal);
    expect(after.energyInKcal, before.energyInKcal);
    expect(after.sugar.addedSugarG, before.sugar.addedSugarG);
    expect(after.ulFlags.map((f) => f.nutrientId), before.ulFlags.map((f) => f.nutrientId));
    expect(after.energyOutWorkoutKcal, before.energyOutWorkoutKcal);
  });
}
