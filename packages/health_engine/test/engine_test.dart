import 'dart:convert';
import 'dart:io';

import 'package:health_engine/health_engine.dart';
import 'package:test/test.dart';

/// Kết quả mong đợi sinh bởi tools/reference_engine.py (bản Python viết độc lập).
final Map<String, dynamic> cases =
    jsonDecode(File('test/fixtures/cases.json').readAsStringSync()) as Map<String, dynamic>;
final Map<String, dynamic> rawPack =
    jsonDecode(File('assets/reference_pack.json').readAsStringSync()) as Map<String, dynamic>;
final ReferencePack pack = ReferencePack.fromJson(rawPack);

ReferencePack buildExtendedPack() {
  final copy = jsonDecode(jsonEncode(rawPack)) as Map<String, dynamic>;
  copy['unitConversions'] = cases['extendedUnitConversions'];
  return ReferencePack.fromJson(copy);
}

final ReferencePack extendedPack = buildExtendedPack();

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
          meal: it['meal'] == null ? null : MealSlot.values.byName(it['meal'] as String),
          at: it['at'] == null ? null : DateTime.parse(it['at'] as String),
          addedSugarKnown: it['addedSugarKnown'] as bool? ?? true,
          entryId: it['entryId'] as String?,
          nutrients: {
            for (final e in (it['n'] as Map<String, dynamic>).entries)
              e.key: (e.value as num).toDouble(),
          },
          ulNutrients: it['ulN'] == null
              ? null
              : {
                  for (final e in (it['ulN'] as Map<String, dynamic>).entries)
                    e.key: (e.value as num).toDouble(),
                },
        ),
    ];

List<WorkoutEntry> workoutsOf(List<dynamic> j) => [
      for (final w in j.cast<Map<String, dynamic>>())
        WorkoutEntry(
          activityCode: w['code'] as String,
          minutes: (w['minutes'] as num).toDouble(),
          day: w['day'] as String?,
        ),
    ];

IntakeLineInput lineInputOf(Map<String, dynamic> j) => IntakeLineInput(
      nutrientId: j['nutrientId'] as String?,
      freeName: j['freeName'] as String?,
      source: IntakeSource.values.byName(j['source'] as String),
      form: j['form'] as String? ?? NutrientForm.unknown,
      amount: (j['amount'] as num).toDouble(),
      unit: LabelUnit.values.byName(j['unit'] as String),
      compoundKind: CompoundKind.values.byName(j['compoundKind'] as String? ?? 'elemental'),
      secondaryFolicAcidUg: (j['secondaryFolicAcidUg'] as num?)?.toDouble(),
    );

void expectFlagsMatch(List<UlFlag> got, List<dynamic> rawWant) {
  final want = rawWant.cast<Map<String, dynamic>>();
  expect(got.length, want.length);
  for (var i = 0; i < want.length; i++) {
    final w = want[i];
    expect(got[i].nutrientId, w['id']);
    expect(got[i].kind.name, w['kind']);
    expect(got[i].amount, closeTo((w['amount'] as num).toDouble(), 1e-7));
    expect(got[i].ul, closeTo((w['ul'] as num).toDouble(), 1e-7));
    expect(got[i].excess, closeTo((w['excess'] as num).toDouble(), 1e-7));
    expect(got[i].percentOver, closeTo((w['percentOver'] as num).toDouble(), 1e-7));
    expect(got[i].percentOfUl, closeTo((w['percentOfUl'] as num).toDouble(), 1e-7));
    expect(got[i].scope.name, w['scope']);
    expect(got[i].dayCount, w['dayCount']);
  }
}

void expectStatusesMatch(List<NutrientStatus> got, List<dynamic> rawWant) {
  final want = rawWant.cast<Map<String, dynamic>>();
  expect(got.map((s) => s.nutrientId).toList(), want.map((w) => w['id']).toList());
  for (var i = 0; i < want.length; i++) {
    final w = want[i];
    expect(got[i].totalAmount, closeTo((w['total'] as num).toDouble(), 1e-7), reason: got[i].nutrientId);
    expect(got[i].foodAmount, closeTo((w['food'] as num).toDouble(), 1e-7), reason: got[i].nutrientId);
    expect(got[i].fortifiedAmount, closeTo((w['fortified'] as num).toDouble(), 1e-7), reason: got[i].nutrientId);
    expect(got[i].supplementAmount, closeTo((w['supplement'] as num).toDouble(), 1e-7), reason: got[i].nutrientId);
    expect(got[i].ulAmount, closeTo((w['ulAmount'] as num).toDouble(), 1e-7), reason: got[i].nutrientId);
    if (w['target'] == null) {
      expect(got[i].target, isNull);
    } else {
      expect(got[i].target!.value, closeTo((w['target'] as num).toDouble(), 1e-7));
    }
    if (w['ul'] == null) {
      expect(got[i].ul, isNull);
    } else {
      expect(got[i].ul, closeTo((w['ul'] as num).toDouble(), 1e-7));
    }
    expect(got[i].ulNutrientId, w['ulNutrientId']);
  }
}

void main() {
  final profiles = (cases['profiles'] as Map<String, dynamic>).cast<String, Map<String, dynamic>>();
  final days = (cases['days'] as Map<String, dynamic>).cast<String, List<dynamic>>();
  final expect_ = cases['expect'] as Map<String, dynamic>;

  group('gói dữ liệu', () {
    test('đọc được đủ nhóm cấu trúc, PAG và minProfileAge', () {
      expect(pack.minProfileAge, 18);
      expect(pack.groups.length, 16);
      expect(pack.nutrients.length, 40);
      expect(pack.weeklyModerateMin.min, 150);
      expect(pack.weeklyModerateMin.max, 300);
      expect(pack.weeklyVigorousMin.min, 75);
      expect(pack.weeklyVigorousMin.max, 150);
      expect(pack.strengthDaysPerWeek, 2);
      for (final n in pack.nutrients.values) {
        if (n.kind == TargetKind.none) continue;
        for (final g in pack.groups) {
          expect(n.target.containsKey(g.id), isTrue, reason: '${n.id} thiếu ${g.id}');
        }
        expect(pack.sources.containsKey(n.source), isTrue);
      }
    });

    test('từ chối schema cũ', () {
      expect(
        () => ReferencePack.fromJson({...rawPack, 'schema': 1}),
        throwsFormatException,
      );
    });

    test('nhóm tham chiếu hoàn toàn dữ liệu: thêm nhóm trẻ em không cần sửa engine', () {
      final copy = jsonDecode(jsonEncode(rawPack)) as Map<String, dynamic>;
      (copy['groups'] as List).insert(0, {
        'id': 'c4_8',
        'sex': null,
        'stage': 'none',
        'minAge': 4,
        'maxAge': 8,
        'amdrKey': 'age4_18',
        'proteinPerKg': null,
        'eerType': 'none',
      });
      for (final n in (copy['nutrients'] as List).cast<Map<String, dynamic>>()) {
        if (n['id'] == 'vitC') (n['target'] as Map<String, dynamic>)['c4_8'] = 25;
        if (n['id'] == 'protein') (n['target'] as Map<String, dynamic>)['c4_8'] = 19;
      }
      final customPack = ReferencePack.fromJson(copy);
      const child = Profile(ageYears: 6, sex: Sex.female, heightCm: 115, weightKg: 20);
      expect(driGroupFor(customPack, child), 'c4_8');
      expect(targetFor(customPack, child, 'vitC')!.value, 25);
      expect(targetFor(customPack, child, 'protein')!.value, 19);
      expect(() => eerKcal(customPack, child), throwsA(isA<NotComputed>()));
    });
  });

  group('nhóm DRI, mục tiêu và mốc tuổi UL', () {
    profiles.forEach((name, pj) {
      test(name, () {
        final p = profileOf(pj);
        expect(driGroupFor(pack, p), (expect_['group'] as Map)[name]);
        final targets = (expect_['targets'] as Map<String, dynamic>)[name] as Map<String, dynamic>;
        targets.forEach((nid, v) {
          final t = targetFor(pack, p, nid);
          if (v == null) {
            expect(t, isNull);
          } else {
            expect(t!.value, closeTo((v as num).toDouble(), 1e-9), reason: nid);
          }
        });
        final uls = (expect_['uls'] as Map<String, dynamic>)[name] as Map<String, dynamic>;
        uls.forEach((nid, v) {
          final u = ulFor(pack, p, nid);
          if (v == null) {
            expect(u, isNull, reason: nid);
          } else {
            expect(u, closeTo((v as num).toDouble(), 1e-9), reason: nid);
          }
        });
      });
    });

    test('dưới 14 tuổi không hỗ trợ', () {
      expect(
        () => driGroupFor(pack, const Profile(ageYears: 12, sex: Sex.male, heightCm: 150, weightKg: 40)),
        throwsA(isA<NotComputed>()),
      );
    });

    test('12 tháng trước mốc 19, 51, 71: UL thận trọng, RDA giữ nhóm hiện tại', () {
      const p18 = Profile(ageYears: 18, sex: Sex.male, heightCm: 170, weightKg: 60);
      expect(targetFor(pack, p18, 'calcium')!.value, 1300);
      expect(ulFor(pack, p18, 'calcium'), 2500);
      expect(ulFor(pack, p18, 'vanadium'), 1.8);

      const p50 = Profile(ageYears: 50, sex: Sex.female, heightCm: 160, weightKg: 55);
      expect(ulFor(pack, p50, 'calcium'), 2000);
      expect(targetFor(pack, p50, 'calcium')!.value, 1000);

      const p70 = Profile(ageYears: 70, sex: Sex.male, heightCm: 165, weightKg: 60);
      expect(ulFor(pack, p70, 'phosphorus'), 3000);
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

  group('UL và vitamin E tổng hợp', () {
    final ulDay = expect_['ulDay'] as Map<String, dynamic>;
    ulDay.forEach((key, flags) {
      test(key, () {
        final parts = key.split('|');
        final got = checkUlDay(pack, profileOf(profiles[parts[0]]!), dayOf(days[parts[1]]!));
        expectFlagsMatch(got, flags as List);
      });
    });

    test('trung bình 7 ngày đủ ngày và ngày thưa (lọc ngày rỗng)', () {
      final man30 = profileOf(profiles['man30']!);
      final fullWeek = [dayOf(days['supplements_heavy']!), for (var i = 0; i < 6; i++) dayOf(days['balanced']!)];
      expectFlagsMatch(
        checkUlAverage(pack, man30, fullWeek),
        (expect_['ulAvg'] as Map)['man30|1heavy6balanced'] as List,
      );

      final sparse = [
        dayOf(days['supplements_heavy']!),
        dayOf(days['balanced']!),
        for (var i = 0; i < 5; i++) <IntakeItem>[],
      ];
      expectFlagsMatch(
        checkUlAverage(pack, man30, sparse),
        (expect_['ulAvg'] as Map)['man30|sparse2of7'] as List,
      );
      expect(checkUlAverage(pack, man30, const [[], []]), isEmpty);
    });

    test('kiểm tra cờ theo lịch và ngưỡng sát UL 350,004 > 350', () {
      final man30 = profileOf(profiles['man30']!);
      final schedFlags = checkUlSchedule(pack, man30, const [
        IntakeItem(label: 'Magie', source: IntakeSource.supplement, nutrients: {'magnesium': 400}),
      ]);
      expect(schedFlags.single.kind, UlFlagKind.schedule);
      expect(schedFlags.single.excess, closeTo(50, 1e-9));

      final tiny = checkUlDay(pack, man30, const [
        IntakeItem(label: 'Magie', source: IntakeSource.supplement, nutrients: {'magnesium': 350.004}),
      ]);
      expect(tiny.single.excess, closeTo(0.004, 1e-9));
      expect(tiny.single.excess, greaterThan(0));
    });

    test('magie từ thực phẩm không tính vào UL', () {
      final p = profileOf(profiles['man30']!);
      final flags = checkUlDay(pack, p, const [
        IntakeItem(label: 'rau', source: IntakeSource.food, nutrients: {'magnesium': 900}),
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
          expect(s.grams, closeTo((w['grams'] as num).toDouble(), 1e-9), reason: s.macro);
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
        expect(got.addedSugarG, closeTo((w['addedSugarG'] as num).toDouble(), 1e-9));
        expect(got.percentEnergy, closeTo((w['pct'] as num).toDouble(), 1e-9));
        expect(got.unknownSugarFoods, (w['unknownSugarFoods'] as List).cast<String>());
        final wantMeals = (w['mealsOverLimit'] as List).cast<Map<String, dynamic>>();
        expect(got.mealsOverLimit.length, wantMeals.length);
        for (var i = 0; i < wantMeals.length; i++) {
          expect(got.mealsOverLimit[i].meal.name, wantMeals[i]['meal']);
          expect(got.mealsOverLimit[i].grams, closeTo((wantMeals[i]['grams'] as num).toDouble(), 1e-9));
          expect(got.mealsOverLimit[i].labels, (wantMeals[i]['labels'] as List).cast<String>());
          expect(got.mealsOverLimit[i].startAt?.toIso8601String().substring(0, 19), wantMeals[i]['startAt']);
          expect(got.mealsOverLimit[i].endAt?.toIso8601String().substring(0, 19), wantMeals[i]['endAt']);
        }
      });
    });
  });

  group('vận động', () {
    (expect_['activity'] as Map<String, dynamic>).forEach((wname, rawWant) {
      test('tổng hợp: $wname', () {
        final w = rawWant as Map<String, dynamic>;
        final ws = workoutsOf((cases['workoutSets'] as Map<String, dynamic>)[wname] as List);
        final got = activitySummary(pack, ws);
        expect(got.moderateMinutes, closeTo((w['moderateMinutes'] as num).toDouble(), 1e-9));
        expect(got.vigorousMinutes, closeTo((w['vigorousMinutes'] as num).toDouble(), 1e-9));
        expect(got.moderateEquivalentMinutes, closeTo((w['moderateEquivalentMinutes'] as num).toDouble(), 1e-9));
        expect(got.strengthDays, w['strengthDays']);
        expect(got.suggestedLevel.name, w['suggestedLevel']);
      });
    });

    test('buổi tập không có day đếm từng buổi tăng cơ riêng', () {
      final got = activitySummary(pack, const [
        WorkoutEntry(activityCode: '02050', minutes: 30),
        WorkoutEntry(activityCode: '02054', minutes: 20),
      ]);
      expect(got.strengthDays, 2);
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

  group('đổi dòng nhãn (convertIntakeLine) và đơn vị', () {
    final conv = UnitConverter(pack);
    final extConv = UnitConverter(extendedPack);
    final lineCases = (cases['lineCases'] as List).cast<Map<String, dynamic>>();
    final expectConv = expect_['convertLine'] as Map<String, dynamic>;

    for (final c in lineCases) {
      final name = c['name'] as String;
      final useExt = c['extended'] as bool;
      test(name, () {
        final got = (useExt ? extConv : conv).convertIntakeLine(
          lineInputOf(c['input'] as Map<String, dynamic>),
        );
        final w = expectConv[name] as Map<String, dynamic>;
        final wAmounts = (w['amounts'] as Map<String, dynamic>);
        expect(got.amounts.keys.toSet(), wAmounts.keys.toSet());
        for (final k in wAmounts.keys) {
          expect(got.amounts[k], closeTo((wAmounts[k] as num).toDouble(), 1e-7), reason: k);
        }
        if (w['ulAmounts'] == null) {
          expect(got.ulAmounts, isNull);
        } else {
          final wUl = w['ulAmounts'] as Map<String, dynamic>;
          expect(got.ulAmounts, isNotNull);
          expect(got.ulAmounts!.keys.toSet(), wUl.keys.toSet());
          for (final k in wUl.keys) {
            expect(got.ulAmounts![k], closeTo((wUl[k] as num).toDouble(), 1e-7), reason: k);
          }
        }
        expect(got.uncertain, w['uncertain']);
        expect(got.amountsNotComputed?.name, w['amountsNotComputed']);
      });
    }

    test('từ chối lượng âm và secondaryFolicAcidUg âm', () {
      expect(
        () => conv.convertIntakeLine(const IntakeLineInput(
          nutrientId: 'vitC',
          source: IntakeSource.supplement,
          amount: -1,
          unit: LabelUnit.mg,
        )),
        throwsArgumentError,
      );
      expect(
        () => conv.convertIntakeLine(const IntakeLineInput(
          nutrientId: 'folate',
          source: IntakeSource.fortified,
          amount: 400,
          unit: LabelUnit.ugDfe,
          secondaryFolicAcidUg: -10,
        )),
        throwsArgumentError,
      );
    });
  });

  group('báo cáo ngày và trung bình 7 ngày', () {
    final man30 = profileOf(profiles['man30']!);
    final sparse = [
      dayOf(days['supplements_heavy']!),
      dayOf(days['balanced']!),
      for (var i = 0; i < 5; i++) <IntakeItem>[],
    ];
    final bothWeek = [
      dayOf(days['supplements_heavy']!),
      dayOf(days['vitE_boundary']!),
      for (var i = 0; i < 5; i++) <IntakeItem>[],
    ];
    final athleteWs = workoutsOf((cases['workoutSets'] as Map<String, dynamic>)['athlete'] as List);

    test('dailyReport giữ đủ cả cờ daily và sevenDayAverage, hai tổng và vận động', () {
      final r = dailyReport(
        pack,
        man30,
        dayOf(days['supplements_heavy']!),
        workouts: const [WorkoutEntry(activityCode: '17200', minutes: 30, day: '2026-11-24')],
        last7Days: bothWeek,
        workouts7: athleteWs,
      );
      final w = (expect_['dailyReport'] as Map<String, dynamic>)['man30|heavy_both_flags'] as Map<String, dynamic>;
      expect(r.energyInKcal, closeTo((w['energyInKcal'] as num).toDouble(), 1e-9));
      expect(r.eerKcal, w['eerKcal']);
      expect(r.loggedDaysCount, w['loggedDaysCount']);
      expectFlagsMatch(r.ulFlags, w['ulFlags'] as List);
      expect(
        r.ulFlags.where((f) => f.nutrientId == 'vitE').map((f) => f.kind).toSet(),
        {UlFlagKind.daily, UlFlagKind.sevenDayAverage},
      );
      expectStatusesMatch(r.nutrients, w['nutrients'] as List);
      expect(r.activity7Days.strengthDays, (w['activity7Days'] as Map)['strengthDays']);
    });

    test('averageReport tính trung bình đúng số ngày có ghi và trường rỗng', () {
      final r = averageReport(pack, man30, sparse, workouts7: athleteWs);
      final w = (expect_['averageReport'] as Map<String, dynamic>)['man30|sparse2of7'] as Map<String, dynamic>;
      expect(r.loggedDaysCount, 2);
      expect(r.averageEnergyInKcal, closeTo((w['averageEnergyInKcal'] as num).toDouble(), 1e-7));
      expect(r.averageAddedSugarG, closeTo((w['averageAddedSugarG'] as num).toDouble(), 1e-7));
      expect(r.addedSugarPercentEnergy, closeTo((w['addedSugarPercentEnergy'] as num).toDouble(), 1e-7));
      for (final s in r.macros) {
        final mw = (w['macros'] as Map<String, dynamic>)[s.macro] as Map<String, dynamic>;
        expect(s.grams, closeTo((mw['grams'] as num).toDouble(), 1e-7));
        expect(s.percentEnergy, closeTo((mw['pct'] as num).toDouble(), 1e-7));
      }
      expectStatusesMatch(r.nutrients, w['nutrients'] as List);
      expectFlagsMatch(r.ulFlags, w['ulFlags'] as List);

      final empty = averageReport(pack, man30, const [[], []]);
      expect(empty.loggedDaysCount, 0);
      expect(empty.averageEnergyInKcal, 0);
      expect(empty.ulFlags, isEmpty);
      expect(empty.nutrients.every((n) => n.totalAmount == 0 && n.ulAmount == 0), isTrue);
    });
  });
}
