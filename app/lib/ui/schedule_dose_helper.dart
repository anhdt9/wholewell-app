/// Hàm dùng chung ghi lần uống theo lịch (có hỏi hộp hết hạn, phản hồi UL, Sheet Xác nhận từ thông báo).
library;

import 'package:journal_db/journal_db.dart';
import 'package:material_ui/material_ui.dart';

import '../state/app_scope.dart';
import '../state/app_state.dart';
import 'common/food_feedback_sheet.dart';
import 'day_times_screen.dart';
import 'labels.dart';
import 'product_detail_screen.dart';

enum ScheduleWindowPhase { early, inWindow, overdue, taken, skipped }

ScheduleWindowPhase classifySchedulePhase({
  required Schedule schedule,
  required String scheduleDay,
  required DateTime now,
  Occurrence? occurrence,
}) {
  if (occurrence != null) {
    return occurrence.status == OccurrenceStatus.taken
        ? ScheduleWindowPhase.taken
        : ScheduleWindowPhase.skipped;
  }
  final p = scheduleDay.split('-');
  final schedAt = DateTime(
    int.parse(p[0]),
    int.parse(p[1]),
    int.parse(p[2]),
    schedule.timeOfDay ~/ 60,
    schedule.timeOfDay % 60,
  );
  final diffMin = now.difference(schedAt).inMinutes;
  if (diffMin < -120) return ScheduleWindowPhase.early;
  if (diffMin <= 120) return ScheduleWindowPhase.inWindow;
  return ScheduleWindowPhase.overdue;
}

Future<void> markScheduledDoseTaken(
  BuildContext context, {
  required Schedule schedule,
  required String scheduleDay,
  required DateTime at,
  bool asExtra = false,
  bool fromNotification = false,
  ExpiredBoxChoice expiredChoice = ExpiredBoxChoice.ask,
}) async {
  final state = AppScope.of(context);
  final diary = state.diary;
  final detail = await diary.getProductDetail(schedule.productId);
  if (detail == null || !context.mounted) return;
  final lines = diary.buildDoseLinesFromIngredients(detail.ingredients, schedule.servings);

  final outcome = await diary.recordSupplementDose(
    productId: detail.product.id,
    name: detail.product.name,
    servings: schedule.servings,
    at: at,
    lines: lines,
    expiredBoxes: expiredChoice,
    occurrence: asExtra ? null : OccurrenceRef(schedule.id, scheduleDay),
    skipAutoMatch: asExtra,
    summaryLabel: asExtra
        ? 'lần uống thêm'
        : 'lần uống ${formatMinutesHhMm(schedule.timeOfDay)} theo lịch',
  );
  if (!context.mounted) return;

  if (outcome is DoseNeedsExpiredChoice) {
    final choice = await showDialog<ExpiredBoxChoice>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Trừ vào hộp đã hết hạn?'),
        content: const Text(
          'Sản phẩm này không còn hộp còn hạn. Bạn muốn trừ vào hộp đã hết hạn hay chỉ ghi lần uống?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, ExpiredBoxChoice.skip),
            child: const Text('Không trừ'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, ExpiredBoxChoice.deduct),
            child: const Text('Trừ'),
          ),
        ],
      ),
    );
    if (choice != null && context.mounted) {
      await markScheduledDoseTaken(
        context,
        schedule: schedule,
        scheduleDay: scheduleDay,
        at: at,
        asExtra: asExtra,
        fromNotification: fromNotification,
        expiredChoice: choice,
      );
    }
    return;
  }

  final fb = (outcome as DoseLogged).feedback;
  if (!asExtra) {
    await state.cancelWindowIfHandled(schedule.timeOfDay);
  }
  if (fromNotification && fb.newUlFlags.isNotEmpty) {
    await state.notificationScheduler.showUlAlertNotice();
  }
  if (!context.mounted) return;
  await presentFoodFeedback(
    context,
    feedback: fb,
    pack: state.pack,
    onUndo: fb.savedDoseId == null ? null : () => diary.deleteDoseEntry(fb.savedDoseId!),
    onAddBox: () => Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => ProductBoxesScreen(product: detail.product)),
    ),
  );
}

/// Sheet Xác nhận nhanh khi chạm nút "Đã uống" trên thông báo Android (hỗ trợ 1 hoặc nhiều loại).
Future<void> showReminderQuickConfirmSheet(
  BuildContext context, {
  required int timeOfDayMinutes,
  required List<int> scheduleIds,
  DateTime? nowOverride,
}) async {
  final state = AppScope.of(context);
  final diary = state.diary;
  final now = nowOverride ?? DateTime.now();
  final todayKey = dayKey(now);
  final prevKey = dayKey(now.subtract(const Duration(days: 1)));

  final occToday = {for (final o in diary.actualTodayOccurrences) o.scheduleId: o};
  final occPrev = {for (final o in diary.actualYesterdayOccurrences) o.scheduleId: o};

  // Ưu tiên lịch ngày hôm nay; nếu không thấy trong hôm nay hoặc hôm qua có lịch qua nửa đêm chưa đánh dấu thì dùng hôm qua.
  final items = <({Schedule schedule, String day, Product? product})>[];
  final prodMap = {for (final s in diary.allProducts) s.product.id: s.product};

  for (final s in diary.actualTodaySchedules) {
    final matchesId = scheduleIds.isEmpty || scheduleIds.contains(s.id);
    if (s.timeOfDay == timeOfDayMinutes && matchesId && !occToday.containsKey(s.id)) {
      items.add((schedule: s, day: todayKey, product: prodMap[s.productId]));
    }
  }
  if (items.isEmpty) {
    for (final s in diary.actualYesterdaySchedules) {
      final matchesId = scheduleIds.isEmpty || scheduleIds.contains(s.id);
      if (s.timeOfDay == timeOfDayMinutes && matchesId && !occPrev.containsKey(s.id)) {
        items.add((schedule: s, day: prevKey, product: prodMap[s.productId]));
      }
    }
  }
  if (items.isEmpty || !context.mounted) return;

  final selected = {for (final it in items) it.schedule.id: true};
  var pickedTime = TimeOfDay(hour: now.hour, minute: now.minute);

  final confirmed = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setSheetState) {
        final count = selected.values.where((v) => v).length;
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Đến giờ uống · ${formatMinutesHhMm(timeOfDayMinutes)}',
                  style: Theme.of(ctx).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                for (final it in items)
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    value: selected[it.schedule.id] ?? true,
                    onChanged: (v) => setSheetState(() => selected[it.schedule.id] = v ?? false),
                    title: Text(it.product?.name ?? 'Sản phẩm #${it.schedule.productId}'),
                    subtitle: Text(
                      '${fmt(it.schedule.servings * (it.product?.unitsPerServing ?? 1))} '
                      '${it.product == null ? 'đơn vị' : countUnitLabel(it.product!.countUnit)}',
                    ),
                  ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Text('Giờ uống: '),
                    OutlinedButton(
                      onPressed: () async {
                        final t = await showTimePicker(context: ctx, initialTime: pickedTime);
                        if (t != null && ctx.mounted) setSheetState(() => pickedTime = t);
                      },
                      child: Text(formatMinutesHhMm(pickedTime.hour * 60 + pickedTime.minute)),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: count > 0 ? () => Navigator.pop(ctx, true) : null,
                    child: Text('Ghi đã chọn ($count)'),
                  ),
                ),
                Center(
                  child: TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: const Text('Để sau'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    ),
  );

  if (confirmed != true || !context.mounted) return;
  final logAt = DateTime(now.year, now.month, now.day, pickedTime.hour, pickedTime.minute);
  for (final it in items) {
    if (selected[it.schedule.id] != true || !context.mounted) continue;
    await markScheduledDoseTaken(
      context,
      schedule: it.schedule,
      scheduleDay: it.day,
      at: logAt,
      fromNotification: true,
    );
  }
}
