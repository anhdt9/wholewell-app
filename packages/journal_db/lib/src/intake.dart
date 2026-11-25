/// Đổi các lần ghi thành `IntakeItem` cho engine (đặc tả encrypted-db & engine-v2).
library;

import 'package:health_engine/health_engine.dart';

import 'models.dart';

/// Engine đã đọc được lượng tính giới hạn riêng (việc 2).
const engineSupportsUlAmounts = true;

/// Lỗi khi gặp `ulAmounts` mà engine chưa hỗ trợ (giữ lại cho tương thích kiểu).
class UlAmountsNotSupported extends UnsupportedError {
  UlAmountsNotSupported()
      : super('Lượng tính giới hạn riêng chưa dùng được: cần sửa engine (việc 2) trước');
}

bool _hasUl(IntakeLine l) => l.ulAmounts != null && l.ulAmounts!.isNotEmpty;

/// Ném [UlAmountsNotSupported] nếu có dòng mang `ulAmounts` khi [engineSupportsUlAmounts] là false.
void checkLinesWritable(Iterable<IntakeLine> lines) {
  if (!engineSupportsUlAmounts && lines.any(_hasUl)) throw UlAmountsNotSupported();
}

MealSlot mealSlotOf(FoodEntry f) => switch (f.meal) {
      Meal.breakfast => MealSlot.breakfast,
      Meal.lunch => MealSlot.lunch,
      Meal.dinner => MealSlot.dinner,
      Meal.snack => MealSlot.snack,
    };

List<IntakeItem> _group(
  String label,
  MealSlot? meal,
  DateTime at,
  bool addedSugarKnown,
  String entryId,
  List<IntakeLine> lines,
) {
  checkLinesWritable(lines);
  final bySource = <IntakeSource, List<IntakeLine>>{};
  for (final l in lines) {
    (bySource[l.source] ??= []).add(l);
  }
  return [
    for (final entry in bySource.entries)
      _buildItem(label, entry.key, meal, at, addedSugarKnown, entryId, entry.value),
  ];
}

IntakeItem _buildItem(
  String label,
  IntakeSource source,
  MealSlot? meal,
  DateTime at,
  bool addedSugarKnown,
  String entryId,
  List<IntakeLine> groupLines,
) {
  final amounts = <String, double>{};
  final ulKeys = <String>{};
  for (final l in groupLines) {
    for (final e in l.amounts.entries) {
      amounts[e.key] = (amounts[e.key] ?? 0) + e.value;
    }
    if (l.ulAmounts != null && l.ulAmounts!.isNotEmpty) {
      ulKeys.addAll(l.ulAmounts!.keys);
    }
  }
  Map<String, double>? ulNutrients;
  if (ulKeys.isNotEmpty) {
    ulNutrients = {
      for (final k in ulKeys)
        k: groupLines.fold(0.0, (s, l) => s + (l.ulAmounts?[k] ?? l.amounts[k] ?? 0.0)),
    };
  }
  return IntakeItem(
    label: label,
    source: source,
    meal: meal,
    at: at,
    addedSugarKnown: addedSugarKnown,
    entryId: entryId,
    nutrients: amounts,
    ulNutrients: ulNutrients,
  );
}

List<IntakeItem> intakeItemsOfFood(FoodEntry f) {
  if (f.lines.isEmpty && !f.addedSugarKnown) {
    return [
      IntakeItem(
        label: f.name,
        source: IntakeSource.food,
        meal: mealSlotOf(f),
        at: f.at,
        addedSugarKnown: false,
        entryId: 'food:${f.id}',
        nutrients: const {},
      ),
    ];
  }
  return _group(f.name, mealSlotOf(f), f.at, f.addedSugarKnown, 'food:${f.id}', f.lines);
}

List<IntakeItem> intakeItemsOfDose(DoseEntry d) =>
    _group(d.name ?? 'Bổ sung', null, d.at, true, 'dose:${d.id}', d.lines);

/// Mọi `IntakeItem` của một ngày.
List<IntakeItem> intakeItemsFor(Iterable<FoodEntry> foods, Iterable<DoseEntry> doses) => [
      for (final f in foods) ...intakeItemsOfFood(f),
      for (final d in doses) ...intakeItemsOfDose(d),
    ];
