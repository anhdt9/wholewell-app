import 'dart:convert';
import 'dart:io';

import 'package:health_engine/health_engine.dart';
import 'package:test/test.dart';

void main() {
  final rawPack = jsonDecode(File('assets/reference_pack.json').readAsStringSync()) as Map<String, dynamic>;
  final pack = ReferencePack.fromJson(rawPack);
  final conv = UnitConverter(pack);

  group('Cổng 2: 0 lỗi đơn vị (Vitamin A, D, E, Folate, Niacin, Hợp chất)', () {
    test('Vitamin A: retinol IU/µg tính UL; beta-caroten không tính UL; unknown tính thận trọng UL', () {
      final retIu = conv.convertIntakeLine(const IntakeLineInput(
        nutrientId: 'vitA',
        source: IntakeSource.supplement,
        form: NutrientForm.retinol,
        amount: 10000,
        unit: LabelUnit.iu,
      ));
      expect(retIu.amounts['vitA'], closeTo(3000, 1e-9));
      expect(retIu.amounts['retinol'], closeTo(3000, 1e-9));
      expect(retIu.uncertain, isFalse);

      final betaSup = conv.convertIntakeLine(const IntakeLineInput(
        nutrientId: 'vitA',
        source: IntakeSource.supplement,
        form: NutrientForm.betaCarotene,
        amount: 20000,
        unit: LabelUnit.iu,
      ));
      expect(betaSup.amounts['vitA'], closeTo(6000, 1e-9));
      expect(betaSup.amounts.containsKey('retinol'), isFalse);

      final unkSup = conv.convertIntakeLine(const IntakeLineInput(
        nutrientId: 'vitA',
        source: IntakeSource.supplement,
        form: NutrientForm.unknown,
        amount: 5000,
        unit: LabelUnit.iu,
      ));
      expect(unkSup.amounts['retinol'], closeTo(1500, 1e-9));
      expect(unkSup.uncertain, isTrue);
    });

    test('Vitamin E: phân biệt tổng hợp (0.45 RDA / 0.90 UL mỗi IU) vs tự nhiên (0.67 mỗi IU)', () {
      final syn = conv.convertIntakeLine(const IntakeLineInput(
        nutrientId: 'vitE',
        source: IntakeSource.supplement,
        form: NutrientForm.synthetic2r,
        amount: 1000,
        unit: LabelUnit.iu,
      ));
      expect(syn.amounts['vitE'], closeTo(450, 1e-9));
      expect(syn.ulAmounts?['vitE'], closeTo(1000000 / 1100, 1e-9));

      final nat = conv.convertIntakeLine(const IntakeLineInput(
        nutrientId: 'vitE',
        source: IntakeSource.supplement,
        form: NutrientForm.natural2r,
        amount: 1000,
        unit: LabelUnit.iu,
      ));
      expect(nat.amounts['vitE'], closeTo(670, 1e-9));
      expect(nat.ulAmounts, isNull);
    });

    test('Folate: DFE bổ sung nhân hệ số UL, natural_folate không tính UL, nhãn kép giữ secondaryFolicAcidUg', () {
      final dfePair = conv.convertIntakeLine(const IntakeLineInput(
        nutrientId: 'folate',
        source: IntakeSource.supplement,
        form: NutrientForm.folicAcid,
        amount: 680,
        unit: LabelUnit.ugDfe,
        secondaryFolicAcidUg: 400,
      ));
      expect(dfePair.amounts['folate'], 680);
      expect(dfePair.amounts['folicAcid'], 400);

      final nat = conv.convertIntakeLine(const IntakeLineInput(
        nutrientId: 'folate',
        source: IntakeSource.food,
        form: NutrientForm.naturalFolate,
        amount: 500,
        unit: LabelUnit.ugDfe,
      ));
      expect(nat.amounts['folate'], 500);
      expect(nat.amounts.containsKey('folicAcid'), isFalse);
    });

    test('Vitamin D IU và tỷ lệ nguyên tố hợp chất canxi/sắt + unknown thận trọng', () {
      final vitD = conv.convertIntakeLine(const IntakeLineInput(
        nutrientId: 'vitD',
        source: IntakeSource.supplement,
        amount: 4000,
        unit: LabelUnit.iu,
      ));
      expect(vitD.amounts['vitD'], closeTo(100, 1e-9));

      final caCarb = conv.convertIntakeLine(const IntakeLineInput(
        nutrientId: 'calcium',
        source: IntakeSource.supplement,
        form: 'calcium_carbonate',
        amount: 1000,
        unit: LabelUnit.mg,
        compoundKind: CompoundKind.compound,
      ));
      expect(caCarb.amounts['calcium'], closeTo(400, 1e-9));

      final caCit = conv.convertIntakeLine(const IntakeLineInput(
        nutrientId: 'calcium',
        source: IntakeSource.supplement,
        form: 'calcium_citrate',
        amount: 1000,
        unit: LabelUnit.mg,
        compoundKind: CompoundKind.compound,
      ));
      expect(caCit.amounts['calcium'], closeTo(210, 1e-9));

      final feUnk = conv.convertIntakeLine(const IntakeLineInput(
        nutrientId: 'iron',
        source: IntakeSource.supplement,
        amount: 100,
        unit: LabelUnit.mg,
        compoundKind: CompoundKind.unknown,
      ));
      // Thận trọng: RDA lấy tỷ lệ nhỏ nhất (gluconate 12%), UL lấy nguyên tố tối đa (100%).
      expect(feUnk.amounts['iron'], closeTo(12, 1e-9));
      expect(feUnk.ulAmounts?['iron'], closeTo(100, 1e-9));
      expect(feUnk.uncertain, isTrue);
    });
  });

  group('Cổng 2: 0 vi phạm giới hạn UL đúng phạm vi & mốc chuyển nhóm tuổi', () {
    test('Magie, Vitamin E, Niacin, Folate, Vitamin A chỉ phạt đúng nguồn thuộc phạm vi UL', () {
      const p = Profile(
        ageYears: 30,
        sex: Sex.male,
        heightCm: 172,
        weightKg: 68,
        activityLevel: ActivityLevel.active,
      );

      // Lượng rất cao từ thực phẩm tự nhiên -> không bao giờ kích hoạt UL cho Mg, VitE, Niacin, Folate, Beta-carotene.
      final foodOnly = [
        IntakeItem(
          label: 'Thực phẩm tự nhiên dồi dào',
          source: IntakeSource.food,
          nutrients: {
            'magnesium': 900, // UL 350 mg chỉ áp dụng cho supplement
            'vitE': 1500, // UL 1000 mg chỉ áp dụng cho supplement + fortified
            'niacin': 80, // UL 35 mg chỉ áp dụng cho supplement + fortified
            'folate': 2000, // UL 1000 µg chỉ áp dụng cho folicAcid
            'vitA': 5000, // Không có retinol -> không kích hoạt UL retinol
          },
        ),
      ];
      expect(dailyReport(pack, p, foodOnly).ulFlags, isEmpty);

      // Vừa chạm đúng ngưỡng UL (== UL): chưa vượt -> chưa báo cờ.
      final atUl = [
        IntakeItem(
          label: 'Bổ sung đúng ngưỡng',
          source: IntakeSource.supplement,
          nutrients: {
            'magnesium': 350,
            'vitE': 1000,
            'niacin': 35,
            'folicAcid': 1000,
            'retinol': 3000,
          },
        ),
      ];
      expect(dailyReport(pack, p, atUl).ulFlags, isEmpty);

      // Vượt 0.1 trên ngưỡng UL (> UL): lập tức bắt đủ cả 5 chất.
      final overUl = [
        IntakeItem(
          label: 'Bổ sung vượt 0.1',
          source: IntakeSource.supplement,
          nutrients: {
            'magnesium': 350.1,
            'vitE': 1000.1,
            'niacin': 35.1,
            'folicAcid': 1000.1,
            'retinol': 3000.1,
          },
        ),
      ];
      final flagged = {for (final f in dailyReport(pack, p, overUl).ulFlags) f.nutrientId};
      expect(flagged, containsAll(['magnesium', 'vitE', 'niacin', 'folicAcid', 'retinol']));
    });

    test('Gần mốc 19 tuổi: lấy UL thấp hơn của nhóm 14-18 (2800 µg retinol thay vì 3000 µg)', () {
      const near19 = Profile(
        ageYears: 18,
        sex: Sex.female,
        heightCm: 160,
        weightKg: 52,
      );
      final day = [
        IntakeItem(
          label: 'Retinol 2850',
          source: IntakeSource.supplement,
          nutrients: {'retinol': 2850},
        ),
      ];
      final rep = dailyReport(pack, near19, day);
      expect(rep.ulFlags.any((f) => f.nutrientId == 'retinol'), isTrue);
      // Người 18 tuổi chưa tính EER trẻ em (theo AGENTS.md giới hạn đã biết).
      expect(rep.eerKcal, isNull);
      expect(rep.eerNotComputed, NotComputedReason.eerUnderAge19);
    });

    test('Đối chiếu các nhóm tuổi MVP 19..>70 với chuẩn DRI / EER', () {
      final samples = <Profile>[
        const Profile(ageYears: 25, sex: Sex.male, heightCm: 175, weightKg: 70, activityLevel: ActivityLevel.active),
        const Profile(ageYears: 35, sex: Sex.female, heightCm: 160, weightKg: 55, activityLevel: ActivityLevel.lowActive),
        const Profile(ageYears: 55, sex: Sex.male, heightCm: 170, weightKg: 68, activityLevel: ActivityLevel.inactive),
        const Profile(ageYears: 75, sex: Sex.female, heightCm: 155, weightKg: 50, activityLevel: ActivityLevel.lowActive),
      ];
      for (final p in samples) {
        final rep = dailyReport(pack, p, const []);
        expect(rep.eerKcal, isNotNull);
        expect(rep.eerKcal!, greaterThan(1000));
        expect(rep.eerKcal!, lessThan(4500));
        expect(rep.nutrients.length, greaterThanOrEqualTo(30));
      }
      // Mức sắt khuyến nghị nữ 35 tuổi là 18 mg, nữ 55 tuổi (mãn kinh) là 8 mg.
      final f35 = dailyReport(pack, samples[1], const [])
          .nutrients
          .firstWhere((n) => n.nutrientId == 'iron');
      final f75 = dailyReport(pack, samples[3], const [])
          .nutrients
          .firstWhere((n) => n.nutrientId == 'iron');
      expect(f35.target?.value, 18);
      expect(f75.target?.value, 8);
    });

    test('Đường bổ sung: ≤ 10 g/bữa chính và gộp chuỗi bữa phụ cách dưới 30 phút', () {
      const p = Profile(ageYears: 30, sex: Sex.male, heightCm: 170, weightKg: 65);
      final base = DateTime(2026, 11, 26, 15, 0);
      final day = [
        IntakeItem(
          label: 'Bữa sáng 10 g',
          source: IntakeSource.food,
          meal: MealSlot.breakfast,
          at: DateTime(2026, 11, 26, 7, 30),
          nutrients: {'addedSugar': 10},
        ),
        IntakeItem(
          label: 'Bữa phụ 1',
          source: IntakeSource.food,
          meal: MealSlot.snack,
          at: base,
          nutrients: {'addedSugar': 6},
        ),
        IntakeItem(
          label: 'Bữa phụ 2 (sau 20p -> gộp = 12 g > 10 g)',
          source: IntakeSource.food,
          meal: MealSlot.snack,
          at: base.add(const Duration(minutes: 20)),
          nutrients: {'addedSugar': 6},
        ),
      ];
      final rep = dailyReport(pack, p, day);
      expect(rep.sugar.mealsOverLimit.length, 1);
      expect(rep.sugar.mealsOverLimit.single.meal, MealSlot.snack);
      expect(rep.sugar.mealsOverLimit.single.grams, 12);
    });

    test('lineCountsTowardUl khớp phạm vi từng chất, ulKey và ulAmounts', () {
      final ca = pack.nutrients['calcium']!;
      final mg = pack.nutrients['magnesium']!;
      final vitE = pack.nutrients['vitE']!;
      final niacin = pack.nutrients['niacin']!;
      final vitA = pack.nutrients['vitA']!;
      final folate = pack.nutrients['folate']!;

      // total: mọi nguồn có > 0 đều tính.
      expect(lineCountsTowardUl(ca, source: IntakeSource.food, amounts: const {'calcium': 120}), isTrue);
      expect(lineCountsTowardUl(ca, source: IntakeSource.supplement, amounts: const {'calcium': 500}), isTrue);
      expect(lineCountsTowardUl(ca, source: IntakeSource.food, amounts: const {'calcium': 0}), isFalse);

      // supplement: chỉ supplement.
      expect(lineCountsTowardUl(mg, source: IntakeSource.food, amounts: const {'magnesium': 100}), isFalse);
      expect(lineCountsTowardUl(mg, source: IntakeSource.fortified, amounts: const {'magnesium': 100}), isFalse);
      expect(lineCountsTowardUl(mg, source: IntakeSource.supplement, amounts: const {'magnesium': 100}), isTrue);

      // synthetic: fortified và supplement, không tính food.
      expect(lineCountsTowardUl(vitE, source: IntakeSource.food, amounts: const {'vitE': 15}), isFalse);
      expect(lineCountsTowardUl(vitE, source: IntakeSource.fortified, amounts: const {'vitE': 15}), isTrue);
      expect(lineCountsTowardUl(niacin, source: IntakeSource.supplement, amounts: const {'niacin': 20}), isTrue);

      // ulKey: vitA -> retinol (ulScope total), folate -> folicAcid (ulScope total).
      expect(lineCountsTowardUl(vitA, source: IntakeSource.food, amounts: const {'vitA': 500}), isFalse);
      expect(
        lineCountsTowardUl(vitA, source: IntakeSource.food, amounts: const {'vitA': 500, 'retinol': 300}),
        isTrue,
      );
      expect(
        lineCountsTowardUl(
          vitA,
          source: IntakeSource.supplement,
          amounts: const {'vitA': 500},
          ulAmounts: const {'retinol': 500},
        ),
        isTrue,
      );
      expect(
        lineCountsTowardUl(folate, source: IntakeSource.food, amounts: const {'folate': 400}),
        isFalse,
      );
      expect(
        lineCountsTowardUl(folate, source: IntakeSource.fortified, amounts: const {'folate': 400, 'folicAcid': 200}),
        isTrue,
      );
    });
  });
}
