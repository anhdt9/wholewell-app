import 'dart:convert';
import 'dart:io';

import 'package:health_engine/health_engine.dart';
import 'package:test/test.dart';

/// Kết quả mong đợi sinh bởi tools/reference_engine.py (bản Python viết độc lập).
final Map<String, dynamic> cases =
    jsonDecode(File('test/fixtures/cases.json').readAsStringSync()) as Map<String, dynamic>;
final ReferencePack pack =
    ReferencePack.fromJsonString(File('assets/reference_pack.json').readAsStringSync());

Profile profileOf(Map<String, dynamic> j) => Profile(
      ageYears: j['age'] as int,
      sex: j['sex'] == 'male' ? Sex.male : Sex.female,
      heightCm: (j['height'] as num).toDouble(),
      weightKg: (j['weight'] as num).toDouble(),
      stage: switch (j['stage'] as String? ?? 'none') {
        'pregnant' => LifeStage.pregnant,
        'lactating' => LifeStage.lactating,
        _ => LifeStage.none,
      },
      gestationWeek: j['gestWeek'] as int?,
      monthsPostpartum: j['monthsPostpartum'] as int?,
      prePregnancyBmi: switch (j['bmi'] as String?) {
        'underweight' => BmiClass.underweight,
        'normal' => BmiClass.normal,
        'overweight' => BmiClass.overweight,
        'obese' => BmiClass.obese,
        _ => null,
      },
      activityLevel: ActivityLevel.values.byName(j['level'] as String? ?? 'inactive'),
    );

List<IntakeItem> dayOf(List<dynamic> j) => [
      for (final it in j.cast<Map<String, dynamic>>())
        IntakeItem(
          label: it['label'] as String,
          source: IntakeSource.values.byName(it['source'] as String),
          mealId: it['meal'] as String?,
          nutrients: {
            for (final e in (it['n'] as Map<String, dynamic>).entries)
              e.key: (e.value as num).toDouble(),
          },
        ),
    ];

List<WorkoutEntry> workoutsOf(List<dynamic> j) => [
      for (final w in j.cast<List<dynamic>>())
        WorkoutEntry(activityCode: w[0] as String, minutes: (w[1] as num).toDouble()),
    ];

void main() {
  final profiles = (cases['profiles'] as Map<String, dynamic>).cast<String, Map<String, dynamic>>();
  final days = (cases['days'] as Map<String, dynamic>).cast<String, List<dynamic>>();
  final expect_ = cases['expect'] as Map<String, dynamic>;

  group('gói dữ liệu', () {
    test('đọc được và đủ nhóm', () {
      expect(pack.groups.length, 16);
      expect(pack.nutrients.length, greaterThanOrEqualTo(40));
      for (final n in pack.nutrients.values) {
        if (n.kind == TargetKind.none) continue;
        for (final g in pack.groups) {
          expect(n.target.containsKey(g), isTrue, reason: '${n.id} thiếu $g');
        }
        expect(pack.sources.containsKey(n.source), isTrue);
      }
    });
  });

  group('nhóm DRI và mục tiêu', () {
    profiles.forEach((name, pj) {
      test(name, () {
        final p = profileOf(pj);
        expect(driGroupFor(p), (expect_['group'] as Map)[name]);
        final targets = (expect_['targets'] as Map<String, dynamic>)[name] as Map<String, dynamic>;
        targets.forEach((nid, v) {
          final t = targetFor(pack, p, nid);
          if (v == null) {
            expect(t, isNull);
          } else {
            expect(t!.value, closeTo((v as num).toDouble(), 1e-9), reason: nid);
          }
        });
      });
    });
    test('dưới 14 tuổi không hỗ trợ', () {
      expect(
        () => driGroupFor(const Profile(ageYears: 12, sex: Sex.male, heightCm: 150, weightKg: 40)),
        throwsA(isA<NotComputed>()),
      );
    });
    test('AI được đánh dấu là ước tính', () {
      final p = profileOf(profiles['man30']!);
      expect(targetFor(pack, p, 'vitK')!.isEstimate, isTrue);
      expect(targetFor(pack, p, 'iron')!.isEstimate, isFalse);
    });
  });

  group('EER', () {
    profiles.forEach((name, pj) {
      test(name, () {
        final p = profileOf(pj);
        final e = (expect_['eer'] as Map<String, dynamic>)[name] as Map<String, dynamic>;
        if (e['kcal'] == null) {
          expect(
            () => eerKcal(pack, p),
            throwsA(isA<NotComputed>().having((x) => x.reason.name, 'reason', e['reason'])),
          );
        } else {
          expect(eerKcal(pack, p), e['kcal']);
        }
      });
    });
  });

  group('UL', () {
    final ulDay = expect_['ulDay'] as Map<String, dynamic>;
    ulDay.forEach((key, flags) {
      test(key, () {
        final parts = key.split('|');
        final got = checkUlDay(pack, profileOf(profiles[parts[0]]!), dayOf(days[parts[1]]!));
        final want = (flags as List).cast<Map<String, dynamic>>();
        expect(got.map((f) => f.nutrientId).toList(), want.map((f) => f['id']).toList());
        for (var i = 0; i < want.length; i++) {
          expect(got[i].amount, closeTo((want[i]['amount'] as num).toDouble(), 1e-9));
          expect(got[i].ul, closeTo((want[i]['ul'] as num).toDouble(), 1e-9));
        }
      });
    });
    test('trung bình 7 ngày', () {
      final week = [dayOf(days['supplements_heavy']!), for (var i = 0; i < 6; i++) dayOf(days['balanced']!)];
      final got = checkUlAverage(pack, profileOf(profiles['man30']!), week);
      final want = ((expect_['ulAvg'] as Map)['man30|1heavy6balanced'] as List);
      expect(got.length, want.length);
    });
    test('magie từ thực phẩm không tính vào UL', () {
      final p = profileOf(profiles['man30']!);
      final flags = checkUlDay(pack, p, [
        const IntakeItem(label: 'rau', source: IntakeSource.food, nutrients: {'magnesium': 900}),
      ]);
      expect(flags, isEmpty);
    });
  });

  group('tỷ lệ đạm, béo, bột đường', () {
    final m = expect_['macros'] as Map<String, dynamic>;
    m.forEach((key, want) {
      test(key, () {
        final parts = key.split('|');
        final got = macroShares(pack, profileOf(profiles[parts[0]]!), dayOf(days[parts[1]]!));
        for (final s in got) {
          final w = (want as Map<String, dynamic>)[s.macro] as Map<String, dynamic>;
          expect(s.percentEnergy, closeTo((w['pct'] as num).toDouble(), 1e-9), reason: s.macro);
          expect(s.status.name, w['status'], reason: s.macro);
        }
      });
    });
  });

  group('đường bổ sung', () {
    (expect_['sugar'] as Map<String, dynamic>).forEach((dname, want) {
      test(dname, () {
        final w = want as Map<String, dynamic>;
        final got = sugarCheck(pack, dayOf(days[dname]!));
        expect(got.percentEnergy, closeTo((w['pct'] as num).toDouble(), 1e-9));
        expect(got.overDailyLimit, w['overDaily']);
        expect(got.mealsOverLimit.keys.toList()..sort(), (w['mealsOver'] as List).cast<String>());
      });
    });
  });

  group('vận động', () {
    (expect_['suggest'] as Map<String, dynamic>).forEach((wname, want) {
      test('gợi ý mức vận động: $wname', () {
        final ws = workoutsOf((cases['workoutSets'] as Map<String, dynamic>)[wname] as List);
        expect(suggestActivityLevel(pack, ws).name, want);
      });
    });
    test('kcal buổi chạy: 60 kg, MET 9,3, 30 phút ≈ 279', () {
      final p = profileOf(profiles['man30']!).copyWith(weightKg: 60);
      expect(workoutKcal(pack, p, const WorkoutEntry(activityCode: '12050', minutes: 30)),
          closeTo(279, 1e-9));
    });
    test('mã hoạt động lạ', () {
      final p = profileOf(profiles['man30']!);
      expect(() => workoutKcal(pack, p, const WorkoutEntry(activityCode: 'x', minutes: 10)),
          throwsA(isA<NotComputed>()));
    });
  });

  group('đơn vị', () {
    final u = UnitConverter(pack);
    test('vitamin D 1000 IU = 25 µg', () => expect(u.vitDIuToUg(1000), closeTo(25, 1e-9)));
    test('vitamin A retinol 10000 IU = 3000 µg', () => expect(u.vitARetinolIuToUgRae(10000), closeTo(3000, 1e-9)));
    test('vitamin E 400 IU tự nhiên = 268 mg', () => expect(u.vitEIuToMg(400, VitaminEForm.natural), closeTo(268, 1e-9)));
    test('vitamin E 400 IU tổng hợp = 180 mg', () => expect(u.vitEIuToMg(400, VitaminEForm.synthetic), closeTo(180, 1e-9)));
    test('beta-caroten bổ sung 5000 IU = 1500 µg RAE',
        () => expect(u.vitABetaCaroteneSupplementIuToUgRae(5000), closeTo(1500, 1e-9)));
    test('axit folic 400 µg = 680 µg DFE', () => expect(u.folicAcidToDfe(400), closeTo(680, 1e-9)));
  });

  group('báo cáo ngày', () {
    test('ghép đủ phần', () {
      final p = profileOf(profiles['woman18']!);
      final r = dailyReport(pack, p, dayOf(days['balanced']!),
          workouts: const [WorkoutEntry(activityCode: '17200', minutes: 30)]);
      expect(r.eerKcal, isNull);
      expect(r.eerNotComputed, NotComputedReason.eerUnderAge19);
      expect(r.energyInKcal, 1950);
      expect(r.energyOutWorkoutKcal, closeTo(4.8 * 48 * 0.5, 1e-9));
      expect(r.nutrients.any((n) => n.nutrientId == 'iron'), isTrue);
      expect(r.macros.length, 3);
    });
  });
}
