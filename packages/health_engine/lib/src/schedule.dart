/// Đánh giá 5 quy tắc lịch từ gói dữ liệu và khớp lần uống vào khung ±2 giờ.
library;

import 'reference_pack.dart';

class MealTimes {
  final int? breakfast;
  final int? lunch;
  final int? dinner;

  const MealTimes({
    this.breakfast,
    this.lunch,
    this.dinner,
  });
}

class ScheduledNutrient {
  final String nutrientId;
  final String form;
  final double amount;

  const ScheduledNutrient({
    required this.nutrientId,
    this.form = 'unknown',
    required this.amount,
  });
}

class ScheduledDoseInput {
  final int scheduleId;
  final int productId;
  final int timeOfDay;
  final List<ScheduledNutrient> nutrients;

  const ScheduledDoseInput({
    required this.scheduleId,
    required this.productId,
    required this.timeOfDay,
    required this.nutrients,
  });
}

class ScheduleNotice {
  final String ruleId;
  final String severity; // 'notice' | 'suggestion'
  final int timeOfDay;
  final List<int> productIds;
  final bool uncertain;
  final String messageVi;

  const ScheduleNotice({
    required this.ruleId,
    required this.severity,
    required this.timeOfDay,
    required this.productIds,
    required this.uncertain,
    required this.messageVi,
  });
}

class ScheduleCandidate {
  final int scheduleId;
  final int productId;
  final String day; // YYYY-MM-DD
  final int timeOfDay;

  const ScheduleCandidate({
    required this.scheduleId,
    required this.productId,
    required this.day,
    required this.timeOfDay,
  });
}

class ScheduleMatch {
  final int scheduleId;
  final String day;

  const ScheduleMatch({
    required this.scheduleId,
    required this.day,
  });
}

int _clockDiffMinutes(int a, int b) {
  final d = (a - b).abs() % 1440;
  return d < 1440 - d ? d : 1440 - d;
}

/// Đánh giá toàn bộ `scheduleRules` trong [pack] thuần bằng dữ liệu.
List<ScheduleNotice> evaluateScheduleRules(
  ReferencePack pack,
  MealTimes mealTimes,
  List<ScheduledDoseInput> doses,
) {
  final meals = <int>[
    if (mealTimes.breakfast != null) mealTimes.breakfast!,
    if (mealTimes.lunch != null) mealTimes.lunch!,
    if (mealTimes.dinner != null) mealTimes.dinner!,
  ];
  final out = <ScheduleNotice>[];

  for (final r in pack.scheduleRules) {
    final reqForms = r.forms.toSet();
    final window = r.windowMinutes;

    switch (r.type) {
      case 'single_dose_max':
        final targetNid = r.nutrients.first;
        final threshold = r.threshold ?? 0;
        final byTime = <int, ({double amount, Set<int> productIds})>{};
        for (final d in doses) {
          var total = 0.0;
          for (final item in d.nutrients) {
            if (item.nutrientId == targetNid &&
                (reqForms.isEmpty || reqForms.contains(item.form))) {
              total += item.amount;
            }
          }
          if (total > 0) {
            final cur = byTime[d.timeOfDay] ?? (amount: 0.0, productIds: <int>{});
            cur.productIds.add(d.productId);
            byTime[d.timeOfDay] = (amount: cur.amount + total, productIds: cur.productIds);
          }
        }
        final times = byTime.keys.toList()..sort();
        for (final t in times) {
          final entry = byTime[t]!;
          if (entry.amount > threshold) {
            final pids = entry.productIds.toList()..sort();
            out.add(ScheduleNotice(
              ruleId: r.id,
              severity: r.severity,
              timeOfDay: t,
              productIds: pids,
              uncertain: r.uncertain,
              messageVi: r.messageVi,
            ));
          }
        }

      case 'take_with_meal':
        final targetNid = r.nutrients.first;
        for (final d in doses) {
          final matched = d.nutrients.any(
            (it) =>
                it.nutrientId == targetNid &&
                it.amount > 0 &&
                (reqForms.isEmpty || reqForms.contains(it.form)),
          );
          if (!matched) continue;
          final nearMeal = meals.any((m) => _clockDiffMinutes(d.timeOfDay, m) <= window);
          if (!nearMeal) {
            out.add(ScheduleNotice(
              ruleId: r.id,
              severity: r.severity,
              timeOfDay: d.timeOfDay,
              productIds: [d.productId],
              uncertain: r.uncertain,
              messageVi: r.messageVi,
            ));
          }
        }

      case 'co_timing_caution':
        final nA = r.nutrients[0];
        final nB = r.nutrients[1];
        final listA = [
          for (final d in doses)
            if (d.nutrients.any((it) => it.nutrientId == nA && it.amount > 0)) d,
        ];
        final listB = [
          for (final d in doses)
            if (d.nutrients.any((it) => it.nutrientId == nB && it.amount > 0)) d,
        ];
        final seen = <(int, int)>{};
        for (final da in listA) {
          for (final db in listB) {
            if (_clockDiffMinutes(da.timeOfDay, db.timeOfDay) <= window) {
              final lo = da.timeOfDay < db.timeOfDay ? da.timeOfDay : db.timeOfDay;
              final hi = da.timeOfDay < db.timeOfDay ? db.timeOfDay : da.timeOfDay;
              if (!seen.add((lo, hi))) continue;
              final pids = ({da.productId, db.productId}).toList()..sort();
              out.add(ScheduleNotice(
                ruleId: r.id,
                severity: r.severity,
                timeOfDay: da.timeOfDay,
                productIds: pids,
                uncertain: r.uncertain,
                messageVi: r.messageVi,
              ));
            }
          }
        }

      case 'co_timing_threshold':
        final nTrigger = r.nutrients[0];
        final nAffected = r.nutrients[1];
        final threshold = r.threshold ?? 0;
        final listAff = [
          for (final d in doses)
            if (d.nutrients.any((it) => it.nutrientId == nAffected && it.amount > 0)) d,
        ];
        final listTrig = [
          for (final d in doses)
            if (d.nutrients.any((it) => it.nutrientId == nTrigger && it.amount > 0)) d,
        ];
        final seenTimes = <int>{};
        for (final da in listAff) {
          var trigSum = 0.0;
          final pids = <int>{da.productId};
          for (final dt in listTrig) {
            if (_clockDiffMinutes(da.timeOfDay, dt.timeOfDay) <= window) {
              var amt = 0.0;
              for (final it in dt.nutrients) {
                if (it.nutrientId == nTrigger) amt += it.amount;
              }
              if (amt > 0) {
                trigSum += amt;
                pids.add(dt.productId);
              }
            }
          }
          if (trigSum >= threshold && seenTimes.add(da.timeOfDay)) {
            final sortedPids = pids.toList()..sort();
            out.add(ScheduleNotice(
              ruleId: r.id,
              severity: r.severity,
              timeOfDay: da.timeOfDay,
              productIds: sortedPids,
              uncertain: r.uncertain,
              messageVi: r.messageVi,
            ));
          }
        }
    }
  }
  return out;
}

/// Khớp một lần ghi [doseAt] của [productId] với lần uống theo lịch chưa đánh dấu
/// trong khung ±2 giờ (kể cả lịch ngày trước kéo qua nửa đêm). Chọn lần gần giờ nhất.
ScheduleMatch? matchDoseToScheduleWindow(
  DateTime doseAt,
  int productId,
  List<ScheduleCandidate> unmarkedCandidates,
) {
  double? bestDiff;
  DateTime? bestSchedAt;
  ScheduleCandidate? best;

  for (final c in unmarkedCandidates) {
    if (c.productId != productId) continue;
    final parts = c.day.split('-');
    if (parts.length != 3) continue;
    final schedAt = DateTime(
      int.parse(parts[0]),
      int.parse(parts[1]),
      int.parse(parts[2]),
      c.timeOfDay ~/ 60,
      c.timeOfDay % 60,
    );
    final diffMin = (doseAt.difference(schedAt).inSeconds).abs() / 60.0;
    if (diffMin <= 120.0 + 1e-9) {
      final better = best == null ||
          diffMin < bestDiff! - 1e-9 ||
          ((diffMin - bestDiff).abs() <= 1e-9 &&
              (schedAt.isBefore(bestSchedAt!) ||
                  (schedAt.isAtSameMomentAs(bestSchedAt) && c.scheduleId < best.scheduleId)));
      if (better) {
        bestDiff = diffMin;
        bestSchedAt = schedAt;
        best = c;
      }
    }
  }
  return best == null ? null : ScheduleMatch(scheduleId: best.scheduleId, day: best.day);
}
