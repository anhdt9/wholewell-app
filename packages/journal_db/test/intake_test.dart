// Đổi lần ghi thành IntakeItem (thuần Dart, không cần SQLite).
import 'dart:io';

import 'package:health_engine/health_engine.dart';
import 'package:journal_db/journal_db.dart';
import 'package:test/test.dart';

final _pack = ReferencePack.fromJsonString(File('../health_engine/assets/reference_pack.json').readAsStringSync());

const _adult = Profile(ageYears: 35, sex: Sex.female, heightCm: 160, weightKg: 55);

FoodEntry _food(int id, Meal meal, List<IntakeLine> lines, {bool addedSugarKnown = true}) => FoodEntry(
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
      addedSugarKnown: addedSugarKnown,
      packVersion: 'p',
      lines: lines,
    );

void main() {
  test('gộp dòng theo nguồn: món tăng cường giữ chung entryId và đúng bữa', () {
    final f = _food(1, Meal.lunch, const [
      IntakeLine(nutrientId: 'folate', source: IntakeSource.food, amounts: {'folate': 100}),
      IntakeLine(nutrientId: 'folicAcid', source: IntakeSource.fortified, amounts: {'folate': 680, 'folicAcid': 400}),
    ], addedSugarKnown: false);
    final items = intakeItemsOfFood(f);
    expect(items.map((i) => (i.source, i.meal, i.entryId)), [
      (IntakeSource.food, MealSlot.lunch, 'food:1'),
      (IntakeSource.fortified, MealSlot.lunch, 'food:1'),
    ]);
    expect(items[0].nutrients, {'folate': 100.0});
    expect(items[1].nutrients, {'folate': 680.0, 'folicAcid': 400.0});
    expect(sugarCheck(_pack, items).unknownSugarFoods, ['Món 1']);
  });

  test('món không có dòng chất nhưng chưa rõ đường bổ sung vẫn được đếm', () {
    final f = _food(9, Meal.breakfast, const [], addedSugarKnown: false);
    final items = intakeItemsOfFood(f);
    expect(items.length, 1);
    expect(sugarCheck(_pack, items).unknownSugarFoods, ['Món 9']);
  });

  test('mealSlotOf chuyển đúng bữa ăn', () {
    expect(mealSlotOf(_food(7, Meal.snack, const [])), MealSlot.snack);
    expect(mealSlotOf(_food(8, Meal.dinner, const [])), MealSlot.dinner);
  });

  test('magie từ thức ăn không tính vào giới hạn (phạm vi theo nguồn)', () {
    final items = intakeItemsFor([
      _food(1, Meal.lunch, const [
        IntakeLine(nutrientId: 'magnesium', source: IntakeSource.food, amounts: {'magnesium': 900}),
      ]),
    ], const []);
    expect(checkUlDay(_pack, _adult, items).map((f) => f.nutrientId), isNot(contains('magnesium')));
  });

  test('engine hỗ trợ ulAmounts: gộp chung nguồn cả dòng thường và dòng có ulAmounts', () async {
    expect(engineSupportsUlAmounts, isTrue);
    final repo = InMemoryJournalRepository();
    await repo.recordDose(DoseInput(
      at: DateTime(2026, 11, 24),
      name: 'Hỗn hợp E',
      kind: DoseKind.oneOff,
      servings: 1,
      packVersion: 'p',
      lines: const [
        IntakeLine(nutrientId: 'vitE', source: IntakeSource.supplement, form: NutrientForm.natural2r, amounts: {'vitE': 100}),
        IntakeLine(
          nutrientId: 'vitE',
          source: IntakeSource.supplement,
          form: NutrientForm.synthetic2r,
          amounts: {'vitE': 450},
          ulAmounts: {'vitE': 909.0909},
        ),
      ],
    ));
    final doses = await repo.dosesOn('2026-11-24');
    final items = intakeItemsFor(const [], doses);
    expect(items.single.nutrients['vitE'], closeTo(550, 1e-9));
    expect(items.single.ulNutrients?['vitE'], closeTo(1009.0909, 1e-4));
    final flags = checkUlDay(_pack, _adult, items);
    expect(flags.single.nutrientId, 'vitE');
    expect(flags.single.amount, closeTo(1009.0909, 1e-4));
  });

  test('InMemoryJournalRepository.workoutsOn truyền đủ WorkoutEntry.day', () async {
    final repo = InMemoryJournalRepository();
    await repo.addWorkout(DateTime(2026, 11, 24, 18), const WorkoutEntry(activityCode: '02054', minutes: 40));
    final ws = await repo.workoutsOn('2026-11-24');
    expect(ws.single.workout.day, '2026-11-24');
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
