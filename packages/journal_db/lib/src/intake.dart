/// Đổi các lần ghi thành `IntakeItem` cho engine (đặc tả encrypted-db, mục Lượng đã ghi).
library;

import 'package:health_engine/health_engine.dart';

import 'models.dart';

/// Engine đã đọc được lượng tính giới hạn riêng chưa (việc 2 trong status).
///
/// Khi còn `false`: dòng có `ulAmounts` không được ghi, và đổi một dòng như vậy
/// sang `IntakeItem` thì ném lỗi, không bỏ qua lặng lẽ (tính thiếu vào giới hạn).
const engineSupportsUlAmounts = false;

/// Lỗi khi gặp `ulAmounts` mà engine chưa hỗ trợ.
class UlAmountsNotSupported extends UnsupportedError {
  UlAmountsNotSupported()
      : super('Lượng tính giới hạn riêng chưa dùng được: cần sửa engine (việc 2) trước');
}

bool _hasUl(IntakeLine l) => l.ulAmounts != null && l.ulAmounts!.isNotEmpty;

/// Ném [UlAmountsNotSupported] nếu có dòng mang `ulAmounts` khi engine chưa hỗ trợ.
void checkLinesWritable(Iterable<IntakeLine> lines) {
  if (!engineSupportsUlAmounts && lines.any(_hasUl)) throw UlAmountsNotSupported();
}

/// Gộp các dòng của một lần ghi theo nguồn thành một `IntakeItem` mỗi nguồn.
List<IntakeItem> _group(String label, String? mealId, List<IntakeLine> lines) {
  final bySource = <IntakeSource, Map<String, double>>{};
  for (final l in lines) {
    if (_hasUl(l)) throw UlAmountsNotSupported();
    final m = bySource.putIfAbsent(l.source, () => {});
    for (final e in l.amounts.entries) {
      m[e.key] = (m[e.key] ?? 0) + e.value;
    }
  }
  return [
    for (final e in bySource.entries)
      IntakeItem(label: label, source: e.key, mealId: mealId, nutrients: e.value),
  ];
}

/// Mã bữa cho engine. Bữa Phụ: mỗi món một bữa cho tới khi engine nối chuỗi bữa
/// phụ dưới 30 phút (việc 2).
String mealIdOf(FoodEntry f) => f.meal == Meal.snack ? 'snack:${f.id}' : f.meal.name;

List<IntakeItem> intakeItemsOfFood(FoodEntry f) => _group(f.name, mealIdOf(f), f.lines);

List<IntakeItem> intakeItemsOfDose(DoseEntry d) =>
    _group(d.name ?? 'Bổ sung', null, d.lines);

/// Mọi `IntakeItem` của một ngày.
List<IntakeItem> intakeItemsFor(Iterable<FoodEntry> foods, Iterable<DoseEntry> doses) => [
      for (final f in foods) ...intakeItemsOfFood(f),
      for (final d in doses) ...intakeItemsOfDose(d),
    ];
