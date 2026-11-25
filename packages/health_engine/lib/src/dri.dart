/// Chọn nhóm DRI từ dữ liệu gói, mục tiêu RDA/AI và kiểm tra UL.
library;

import 'dart:math' as math;

import 'models.dart';
import 'reference_pack.dart';

GroupDef? _findGroup(ReferencePack pack, Profile p) {
  for (final g in pack.groups) {
    if (g.stage != p.stage) continue;
    if (g.sex != null && g.sex != p.sex) continue;
    if (p.ageYears < g.minAge) continue;
    if (g.maxAge != null && p.ageYears > g.maxAge!) continue;
    return g;
  }
  return null;
}

/// Nhóm DRI theo dữ liệu gói. Ném [NotComputed] khi tuổi không khớp nhóm nào.
GroupDef driGroupDefFor(ReferencePack pack, Profile p) {
  final g = _findGroup(pack, p);
  if (g == null) throw const NotComputed(NotComputedReason.ageUnsupported);
  return g;
}

/// Mã nhóm DRI theo dữ liệu gói.
String driGroupFor(ReferencePack pack, Profile p) => driGroupDefFor(pack, p).id;

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
/// Đạm: nhóm có `proteinPerKg` trong gói tính theo cân nặng, còn lại đọc từ bảng.
Target? targetFor(ReferencePack pack, Profile p, String nutrientId) {
  final def = pack.nutrients[nutrientId];
  if (def == null || def.kind == TargetKind.none) return null;
  final g = driGroupDefFor(pack, p);
  if (nutrientId == 'protein' && g.proteinPerKg != null) {
    return Target(nutrientId, _round1(g.proteinPerKg! * p.weightKg), def.kind);
  }
  final v = def.target[g.id];
  return v == null ? null : Target(nutrientId, v, def.kind);
}

/// UL cho [nutrientId], đã xét quy tắc 12 tháng trước mốc đổi nhóm tuổi
/// (lấy mức thấp hơn giữa nhóm hiện tại và nhóm kế tiếp); null nếu chưa xác định.
double? ulFor(ReferencePack pack, Profile p, String nutrientId) {
  final def = pack.nutrients[nutrientId];
  if (def == null) return null;
  final g1 = driGroupDefFor(pack, p);
  final u1 = def.ul[g1.id];
  if (g1.maxAge != null && p.ageYears == g1.maxAge) {
    final g2 = _findGroup(pack, p.copyWith(ageYears: p.ageYears + 1));
    if (g2 != null && g2.id != g1.id) {
      final u2 = def.ul[g2.id];
      if (u1 != null && u2 != null) return math.min(u1, u2);
      return u1 ?? u2;
    }
  }
  return u1;
}

/// Lượng chất dùng để so với UL, đúng phạm vi UL của từng chất (ưu tiên [IntakeItem.ulNutrients]).
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
    if (counts) sum += it.amountForUlKey(key);
  }
  return sum;
}

enum UlFlagKind { daily, sevenDayAverage, schedule }

class UlFlag {
  final String nutrientId;
  final UlFlagKind kind;
  final double amount;
  final double ul;
  final UlScope scope;
  final int? dayCount;

  const UlFlag(
    this.nutrientId,
    this.kind,
    this.amount,
    this.ul,
    this.scope, [
    this.dayCount,
  ]);

  double get excess => amount - ul;
  double get percentOver => excess / ul * 100;
  double get percentOfUl => amount / ul * 100;
  bool get isSevenDayAverage => kind == UlFlagKind.sevenDayAverage;
}

/// Kiểm tra UL cho một ngày.
List<UlFlag> checkUlDay(ReferencePack pack, Profile p, List<IntakeItem> day) =>
    _checkUl(pack, p, [day], UlFlagKind.daily);

/// Kiểm tra UL theo trung bình các ngày có ghi (tự lọc bỏ ngày rỗng).
List<UlFlag> checkUlAverage(ReferencePack pack, Profile p, List<List<IntakeItem>> loggedDays) =>
    _checkUl(pack, p, [for (final d in loggedDays) if (d.isNotEmpty) d], UlFlagKind.sevenDayAverage);

/// Kiểm tra UL cho một ngày điển hình theo lịch uống.
List<UlFlag> checkUlSchedule(ReferencePack pack, Profile p, List<IntakeItem> scheduledDailyItems) =>
    _checkUl(pack, p, [scheduledDailyItems], UlFlagKind.schedule);

List<UlFlag> _checkUl(ReferencePack pack, Profile p, List<List<IntakeItem>> days, UlFlagKind kind) {
  if (days.isEmpty) return const [];
  driGroupDefFor(pack, p);
  final flags = <UlFlag>[];
  for (final def in pack.nutrients.values) {
    if (def.ulKey != null) continue;
    final ul = ulFor(pack, p, def.id);
    if (ul == null) continue;
    var total = 0.0;
    for (final d in days) {
      total += amountForUl(def, d);
    }
    final amount = total / days.length;
    if (amount > ul) {
      flags.add(UlFlag(
        def.id,
        kind,
        amount,
        ul,
        def.ulScope,
        kind == UlFlagKind.sevenDayAverage ? days.length : null,
      ));
    }
  }
  sortUlFlags(flags);
  return flags;
}

/// Sắp xếp cờ UL theo % vượt giảm dần; cùng tỷ lệ thì daily trước sevenDayAverage.
void sortUlFlags(List<UlFlag> flags) {
  flags.sort((a, b) {
    final cmp = b.percentOver.compareTo(a.percentOver);
    if (cmp != 0) return cmp;
    final kCmp = a.kind.index.compareTo(b.kind.index);
    return kCmp != 0 ? kCmp : a.nutrientId.compareTo(b.nutrientId);
  });
}

double _round1(double v) => (v * 10).roundToDouble() / 10;
