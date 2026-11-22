import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:health_engine/health_engine.dart';
import 'package:suc_khoe_app/state/app_state.dart';
import 'package:suc_khoe_app/state/journal_repository.dart';

void main() {
  final pack = ReferencePack.fromJsonString(File('assets/reference_pack.json').readAsStringSync());

  test('báo cáo ngày qua AppState, cờ UL trung bình 7 ngày', () {
    final s = AppState(pack: pack, repo: InMemoryJournalRepository());
    expect(s.report(), isNull);
    s.saveProfile(const Profile(ageYears: 30, sex: Sex.male, heightCm: 170, weightKg: 65));
    s.addItem(const IntakeItem(
      label: 'Viên magie',
      source: IntakeSource.supplement,
      nutrients: {'magnesium': 500},
    ));
    s.addWorkout(const WorkoutEntry(activityCode: '17200', minutes: 30));
    final r = s.report()!;
    expect(r.eerKcal, 2450);
    expect(r.ulFlags.map((f) => f.nutrientId), contains('magnesium'));
    expect(r.energyOutWorkoutKcal, closeTo(4.8 * 65 * 0.5, 1e-9));
  });

  test('ẩn số calo được lưu', () {
    final repo = InMemoryJournalRepository();
    AppState(pack: pack, repo: repo).setHideCalories(true);
    expect(AppState(pack: pack, repo: repo).hideCalories, isTrue);
  });
}
