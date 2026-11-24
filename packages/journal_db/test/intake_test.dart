// Đổi lần ghi thành IntakeItem (thuần Dart, không cần SQLite).
import 'dart:io';

import 'package:health_engine/health_engine.dart';
import 'package:journal_db/journal_db.dart';
import 'package:test/test.dart';

final _pack = ReferencePack.fromJsonString(File('../health_engine/assets/reference_pack.json').readAsStringSync());

const _adult = Profile(ageYears: 35, sex: Sex.female, heightCm: 160, weightKg: 55);

FoodEntry _food(int id, Meal meal, List<IntakeLine> lines) => FoodEntry(
      id: id,
      at: DateTime(2026, 11, 24, 12),
      day: '2026-11-24',
      meal: meal,
      name: 'Món $id',
      foodRef: null,
      portionUnit: 'bát',
      portionQty: 1,
      labelBasisQty: null,
      labelBasisUnit: null,
      addedSugarKnown: true,
      packVersion: 'p',
      lines: lines,
    );

void main() {
  test('gộp dòng theo nguồn: món tăng cường có phần thường và phần tăng cường', () {
    final f = _food(1, Meal.lunch, const [
      IntakeLine(nutrientId: 'folate', source: IntakeSource.food, amounts: {'folate': 100}),
      IntakeLine(nutrientId: 'folicAcid', source: IntakeSource.fortified, amounts: {'folate': 680, 'folicAcid': 400}),
    ]);
    final items = intakeItemsOfFood(f);
    expect(items.map((i) => (i.source, i.mealId)), [
      (IntakeSource.food, 'lunch'),
      (IntakeSource.fortified, 'lunch'),
    ]);
    expect(items[0].nutrients, {'folate': 100.0});
    expect(items[1].nutrients, {'folate': 680.0, 'folicAcid': 400.0});
  });

  test('bữa Phụ: mỗi món một mã bữa cho tới khi engine nối chuỗi (việc 2)', () {
    expect(mealIdOf(_food(7, Meal.snack, const [])), 'snack:7');
    expect(mealIdOf(_food(8, Meal.dinner, const [])), 'dinner');
  });

  test('magie từ thức ăn không tính vào giới hạn (phạm vi theo nguồn)', () {
    final items = intakeItemsFor([
      _food(1, Meal.lunch, const [
        IntakeLine(nutrientId: 'magnesium', source: IntakeSource.food, amounts: {'magnesium': 900}),
      ]),
    ], const []);
    expect(checkUlDay(_pack, _adult, items).map((f) => f.nutrientId), isNot(contains('magnesium')));
  });

  test('dòng có lượng tính giới hạn riêng: đổi sang IntakeItem thì lỗi, không bỏ qua lặng lẽ', () {
    const ul = IntakeLine(
        nutrientId: 'vitE', source: IntakeSource.supplement, uncertain: true,
        amounts: {'vitE': 45}, ulAmounts: {'vitE': 91});
    expect(engineSupportsUlAmounts, isFalse);
    expect(() => intakeItemsOfFood(_food(1, Meal.lunch, const [ul])), throwsA(isA<UlAmountsNotSupported>()));
    expect(() => checkLinesWritable(const [ul]), throwsA(isA<UlAmountsNotSupported>()));
    expect(() => checkLinesWritable(const [IntakeLine(nutrientId: 'vitE', source: IntakeSource.supplement,
        amounts: {'vitE': 45}, ulAmounts: {})]), returnsNormally);
  });

  test('bản bộ nhớ cũng từ chối dòng có lượng tính giới hạn riêng', () async {
    final repo = InMemoryJournalRepository();
    await expectLater(
      repo.recordDose(DoseInput(
        at: DateTime(2026, 11, 24),
        kind: DoseKind.oneOff,
        servings: 1,
        packVersion: 'p',
        lines: const [
          IntakeLine(nutrientId: 'vitE', source: IntakeSource.supplement, amounts: {'vitE': 45}, ulAmounts: {'vitE': 91}),
        ],
      )),
      throwsA(isA<UlAmountsNotSupported>()),
    );
    expect(await repo.dosesOn('2026-11-24'), isEmpty);
  });

  test('ngày theo giờ địa phương; ngày kế tiếp qua tháng, năm', () {
    expect(dayKey(DateTime(2026, 1, 5, 23, 59)), '2026-01-05');
    expect(monthKey(DateTime(2026, 1, 5)), '2026-01');
    expect(nextDay('2026-11-30'), '2026-12-01');
    expect(nextDay('2026-12-31'), '2027-01-01');
  });

  test('khóa giả: tạo một lần, đọc bốn trạng thái', () async {
    final k = FakeSecureKeyStore();
    expect(await k.readDbKey(), isA<KeyAbsent>());
    final key = await k.createDbKey();
    expect(key.length, dbKeyLength);
    expect(await k.readDbKey(), isA<KeyPresent>());
    k.unavailableReads = 1;
    expect(await k.readDbKey(), isA<KeyUnavailable>());
    expect(await k.readDbKey(), isA<KeyPresent>());
    k.lost = true;
    expect(await k.readDbKey(), isA<KeyLost>());
  });
}
