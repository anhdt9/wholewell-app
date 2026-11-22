/// Chọn nhóm DRI, mục tiêu RDA/AI và kiểm tra UL.
library;

import 'models.dart';
import 'reference_pack.dart';

/// Nhóm DRI theo tuổi, giới, thai kỳ. Ném [NotComputed] khi dưới 14 tuổi.
String driGroupFor(Profile p) {
  if (p.ageYears < 14) throw const NotComputed(NotComputedReason.ageUnsupported);
  final age = p.ageYears;
  if (p.stage != LifeStage.none) {
    final prefix = p.stage == LifeStage.pregnant ? 'p' : 'l';
    if (age <= 18) return '${prefix}14_18';
    if (age <= 30) return '${prefix}19_30';
    // Bảng DRI chỉ có thai kỳ đến 50 tuổi; trên 50 dùng nhóm 31–50.
    return '${prefix}31_50';
  }
  final s = p.sex == Sex.male ? 'm' : 'f';
  if (age <= 18) return '${s}14_18';
  if (age <= 30) return '${s}19_30';
  if (age <= 50) return '${s}31_50';
  if (age <= 70) return '${s}51_70';
  return '${s}71';
}

class Target {
  final String nutrientId;
  final double value;
  final TargetKind kind;

  /// true khi là AI: hiển thị "mức ước tính".
  bool get isEstimate => kind == TargetKind.ai;
  const Target(this.nutrientId, this.value, this.kind);
}

/// Mục tiêu RDA/AI cho [nutrientId]; null nếu chất không có mục tiêu.
///
/// Đạm: người 19+ không mang thai, không cho con bú dùng 0,8 g/kg cân nặng.
Target? targetFor(ReferencePack pack, Profile p, String nutrientId) {
  final def = pack.nutrients[nutrientId];
  if (def == null || def.kind == TargetKind.none) return null;
  final g = driGroupFor(p);
  if (nutrientId == 'protein' && p.ageYears >= 19 && p.stage == LifeStage.none) {
    return Target(nutrientId, _round1(pack.proteinPerKgAdult * p.weightKg), def.kind);
  }
  final v = def.target[g];
  return v == null ? null : Target(nutrientId, v, def.kind);
}

/// UL cho [nutrientId]; null nếu chưa xác định.
double? ulFor(ReferencePack pack, Profile p, String nutrientId) =>
    pack.nutrients[nutrientId]?.ul[driGroupFor(p)];

/// Lượng chất dùng để so với UL, đúng phạm vi UL của từng chất.
double amountForUl(NutrientDef def, Iterable<IntakeItem> items) {
  final key = def.ulKey ?? def.id;
  var sum = 0.0;
  for (final it in items) {
    final counts = switch (def.ulScope) {
      UlScope.total => true,
      UlScope.supplement => it.source == IntakeSource.supplement,
      UlScope.synthetic =>
        it.source == IntakeSource.supplement || it.source == IntakeSource.fortified,
    };
    if (counts) sum += it.amount(key);
  }
  return sum;
}

class UlFlag {
  final String nutrientId;
  final double amount;
  final double ul;
  final UlScope scope;

  /// true khi cờ tính theo trung bình 7 ngày.
  final bool sevenDayAverage;
  const UlFlag(this.nutrientId, this.amount, this.ul, this.scope, this.sevenDayAverage);

  double get percentOfUl => amount / ul * 100;
}

/// Kiểm tra UL cho một ngày.
List<UlFlag> checkUlDay(ReferencePack pack, Profile p, List<IntakeItem> day) =>
    _checkUl(pack, p, [day], average: false);

/// Kiểm tra UL theo trung bình các ngày (thường 7 ngày gần nhất).
List<UlFlag> checkUlAverage(ReferencePack pack, Profile p, List<List<IntakeItem>> days) =>
    _checkUl(pack, p, days, average: true);

List<UlFlag> _checkUl(ReferencePack pack, Profile p, List<List<IntakeItem>> days,
    {required bool average}) {
  if (days.isEmpty) return const [];
  final g = driGroupFor(p);
  final flags = <UlFlag>[];
  for (final def in pack.nutrients.values) {
    // Chất có ulKey (vitA, folate) được kiểm qua chất đích (retinol, folicAcid).
    if (def.ulKey != null) continue;
    final ul = def.ul[g];
    if (ul == null) continue;
    var total = 0.0;
    for (final d in days) {
      total += amountForUl(def, d);
    }
    final amount = total / days.length;
    if (amount > ul) {
      flags.add(UlFlag(def.id, _round2(amount), ul, def.ulScope, average));
    }
  }
  flags.sort((a, b) => b.percentOfUl.compareTo(a.percentOfUl));
  return flags;
}

double _round1(double v) => (v * 10).roundToDouble() / 10;
double _round2(double v) => (v * 100).roundToDouble() / 100;
