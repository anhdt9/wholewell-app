import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:health_engine/health_engine.dart';
import 'package:journal_db/journal_db.dart';
import 'package:wholewell/state/app_state.dart';

void main() {
  final pack = ReferencePack.fromJsonString(File('assets/reference_pack.json').readAsStringSync());
  const profile = Profile(ageYears: 30, sex: Sex.male, heightCm: 170, weightKg: 65);

  test('báo cáo ngày qua AppState, cờ UL trung bình 7 ngày', () async {
    final s = AppState.withRepository(pack: pack, repo: InMemoryJournalRepository());
    await s.start();
    expect(s.report(), isNull);
    await s.saveProfile(profile);
    await s.addItem(const IntakeItem(
      label: 'Viên magie',
      source: IntakeSource.supplement,
      nutrients: {'magnesium': 500},
    ));
    await s.addWorkout(const WorkoutEntry(activityCode: '17200', minutes: 30));
    final r = s.report()!;
    expect(r.eerKcal, 2450);
    expect(r.ulFlags.map((f) => f.nutrientId), contains('magnesium'));
    expect(r.energyOutWorkoutKcal, closeTo(4.8 * 65 * 0.5, 1e-9));
  });

  test('ẩn số calo, nhật ký được lưu qua nhật ký và đọc lại khi mở lại', () async {
    final repo = InMemoryJournalRepository();
    final a = AppState.withRepository(pack: pack, repo: repo);
    await a.start();
    await a.saveProfile(profile);
    await a.setHideCalories(true);
    await a.addItem(const IntakeItem(
      label: 'Cơm',
      source: IntakeSource.food,
      mealId: 'trưa',
      nutrients: {'energyKcal': 200, 'protein': 4},
    ));
    final b = AppState.withRepository(pack: pack, repo: repo);
    await b.start();
    expect(b.hideCalories, isTrue);
    expect(b.profile?.weightKg, 65);
    expect(b.todayItems.single.mealId, 'trưa');
    expect(b.todayItems.single.nutrients, {'energyKcal': 200.0, 'protein': 4.0});
  });

  test('xóa mục theo vị trí trong danh sách', () async {
    final s = AppState.withRepository(pack: pack, repo: InMemoryJournalRepository());
    await s.start();
    await s.addItem(const IntakeItem(label: 'A', source: IntakeSource.food, mealId: 'sáng', nutrients: {'protein': 1}));
    await s.addItem(const IntakeItem(label: 'B', source: IntakeSource.supplement, nutrients: {'zinc': 5}));
    expect(s.todayItems.map((i) => i.label), ['A', 'B']);
    await s.removeItem(1);
    expect(s.todayItems.map((i) => i.label), ['A']);
  });

  test('mở CSDL: chưa có dữ liệu thì về lần đầu; máy đang khóa thì chờ', () async {
    final dir = Directory.systemTemp.createTempSync('wholewell_app_');
    addTearDown(() => dir.deleteSync(recursive: true));
    final keys = FakeSecureKeyStore();
    final opener = DbOpener(files: DbFiles(dir), keys: keys, retryDelay: Duration.zero);
    final s = AppState(pack: pack, opener: opener);
    await s.start();
    expect(s.status, DataStatus.welcome);
    keys
      ..unavailableReads = -1
      ..unlocked = false;
    await s.start();
    expect(s.status, DataStatus.waitingForUnlock);
    expect(dir.listSync(), isEmpty);
  });
}
