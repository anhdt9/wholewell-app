/// Màn Lần uống hôm nay: timeline theo khung giờ uống và nút Đã uống / Bỏ qua / Đánh dấu.
library;

import 'dart:async';

import 'package:flutter/services.dart' show HapticFeedback;
import 'package:journal_db/journal_db.dart';
import 'package:material_ui/material_ui.dart';

import '../state/app_scope.dart';
import 'add_supplement_screen.dart';
import 'common/common_widgets.dart';
import 'day_times_screen.dart';
import 'labels.dart';
import 'schedule_dose_helper.dart';

class TodayDosesScreen extends StatelessWidget {
  final DateTime? nowOverride;
  const TodayDosesScreen({super.key, this.nowOverride});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final diary = state.diary;
    final schedules = diary.actualTodaySchedules;
    final occMap = {for (final o in diary.actualTodayOccurrences) o.scheduleId: o};
    final doseMap = {for (final d in diary.actualTodayDoses) d.id: d};
    final prodMap = {for (final s in diary.allProducts) s.product.id: s.product};
    final notices = diary.scheduleNotices(overrideSchedules: schedules);
    final now = nowOverride ?? DateTime.now();
    final todayStr = dayKey(now);

    final byTime = <int, List<Schedule>>{};
    for (final s in schedules) {
      (byTime[s.timeOfDay] ??= []).add(s);
    }
    final times = byTime.keys.toList()..sort();

    return Scaffold(
      appBar: AppBar(title: const Text('Lần uống hôm nay')),
      body: schedules.isEmpty
          ? const EmptyState(
              icon: LucideIcons.clock,
              message: 'Chưa có lịch uống. Mở một sản phẩm để đặt lịch.',
            )
          : ListView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              children: [
                for (var ti = 0; ti < times.length; ti++)
                  _TimelineSlotGroup(
                    timeOfDay: times[ti],
                    schedules: byTime[times[ti]]!,
                    scheduleDay: todayStr,
                    prodMap: prodMap,
                    occMap: occMap,
                    doseMap: doseMap,
                    notices: [
                      for (final n in notices)
                        if (n.severity == 'notice' && n.timeOfDay == times[ti]) n.messageVi,
                    ],
                    now: now,
                    isLastSlot: ti == times.length - 1,
                  ),
              ],
            ),
    );
  }
}

class _TimelineSlotGroup extends StatelessWidget {
  final int timeOfDay;
  final List<Schedule> schedules;
  final String scheduleDay;
  final Map<int, Product> prodMap;
  final Map<int, Occurrence> occMap;
  final Map<int, DoseEntry> doseMap;
  final List<String> notices;
  final DateTime now;
  final bool isLastSlot;

  const _TimelineSlotGroup({
    required this.timeOfDay,
    required this.schedules,
    required this.scheduleDay,
    required this.prodMap,
    required this.occMap,
    required this.doseMap,
    required this.notices,
    required this.now,
    required this.isLastSlot,
  });

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    final ww = context.wwColors;

    final phases = [
      for (final s in schedules)
        classifySchedulePhase(
          schedule: s,
          scheduleDay: scheduleDay,
          now: now,
          occurrence: occMap[s.id],
        ),
    ];

    final allTaken = phases.every((p) => p == ScheduleWindowPhase.taken);
    final allHandled = phases.every(
      (p) => p == ScheduleWindowPhase.taken || p == ScheduleWindowPhase.skipped,
    );
    final anyActive = phases.any(
      (p) => p == ScheduleWindowPhase.inWindow || p == ScheduleWindowPhase.overdue,
    );

    final Color badgeBg;
    final Color badgeFg;
    final IconData statusIcon;
    if (allTaken) {
      badgeBg = ww.inRange;
      badgeFg = cs.onPrimary;
      statusIcon = LucideIcons.check;
    } else if (allHandled) {
      badgeBg = ww.subtleSurface;
      badgeFg = cs.onSurfaceVariant;
      statusIcon = LucideIcons.minus;
    } else if (anyActive) {
      badgeBg = cs.primaryContainer;
      badgeFg = cs.onPrimaryContainer;
      statusIcon = LucideIcons.clock;
    } else {
      badgeBg = ww.subtleSurface;
      badgeFg = cs.onSurfaceVariant;
      statusIcon = LucideIcons.circle;
    }

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 56,
            child: Column(
              children: [
                Text(
                  formatMinutesHhMm(timeOfDay),
                  style: tabularNumberStyle(
                    t.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: badgeBg,
                    shape: BoxShape.circle,
                    border: allTaken || anyActive
                        ? null
                        : Border.all(color: ww.outlineSubtle),
                  ),
                  child: Icon(statusIcon, size: 16, color: badgeFg),
                ),
                if (!isLastSlot)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                      color: ww.outlineSubtle,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLastSlot ? 0 : AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Card(
                    margin: EdgeInsets.zero,
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      children: [
                        for (var i = 0; i < schedules.length; i++) ...[
                          if (i > 0)
                            Divider(
                              height: 1,
                              color: ww.outlineSubtle.withValues(alpha: 0.5),
                            ),
                          _ScheduleOccurrenceTile(
                            schedule: schedules[i],
                            scheduleDay: scheduleDay,
                            product: prodMap[schedules[i].productId],
                            occurrence: occMap[schedules[i].id],
                            dose: occMap[schedules[i].id]?.doseEntryId == null
                                ? null
                                : doseMap[occMap[schedules[i].id]!.doseEntryId!],
                            now: now,
                          ),
                        ],
                      ],
                    ),
                  ),
                  for (final msg in notices) ...[
                    const SizedBox(height: AppSpacing.sm),
                    SafetyNote(message: msg),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ScheduleOccurrenceTile extends StatefulWidget {
  final Schedule schedule;
  final String scheduleDay;
  final Product? product;
  final Occurrence? occurrence;
  final DoseEntry? dose;
  final DateTime now;

  const _ScheduleOccurrenceTile({
    required this.schedule,
    required this.scheduleDay,
    required this.product,
    required this.occurrence,
    required this.dose,
    required this.now,
  });

  @override
  State<_ScheduleOccurrenceTile> createState() => _ScheduleOccurrenceTileState();
}

class _ScheduleOccurrenceTileState extends State<_ScheduleOccurrenceTile> {
  bool _busy = false;

  Future<void> _runGuarded(Future<void> Function() action) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final schedule = widget.schedule;
    final scheduleDay = widget.scheduleDay;
    final product = widget.product;
    final occurrence = widget.occurrence;
    final dose = widget.dose;
    final now = widget.now;

    final diary = AppScope.of(context).diary;
    final t = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    final ww = context.wwColors;
    final phase = classifySchedulePhase(
      schedule: schedule,
      scheduleDay: scheduleDay,
      now: now,
      occurrence: occurrence,
    );
    final name = product?.name ?? 'Sản phẩm #${schedule.productId}';
    final doseLabel = product == null
        ? '${fmt(schedule.servings)} khẩu phần'
        : '${fmt(schedule.servings * product.unitsPerServing)} ${countUnitLabel(product.countUnit)}';

    switch (phase) {
      case ScheduleWindowPhase.taken:
        final timeStr = dose == null
            ? ''
            : ' ${dose.at.hour.toString().padLeft(2, '0')}:${dose.at.minute.toString().padLeft(2, '0')}';
        return ListTile(
          leading: Icon(LucideIcons.circleCheck, color: ww.inRange),
          title: Text('$name · $doseLabel', style: tabularNumberStyle(t.bodyLarge)),
          subtitle: Text('Đã uống$timeStr', style: tabularNumberStyle(t.bodySmall)),
          trailing: dose == null ? null : const Icon(LucideIcons.chevronRight),
          onTap: dose == null
              ? null
              : () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => AddSupplementScreen(existingDose: dose),
                    ),
                  ),
        );

      case ScheduleWindowPhase.skipped:
        return ListTile(
          leading: Icon(LucideIcons.circleMinus, color: cs.onSurfaceVariant),
          title: Text('$name · $doseLabel', style: tabularNumberStyle(t.bodyLarge)),
          subtitle: const Text('Đã bỏ qua'),
          trailing: TextButton(
            onPressed: _busy
                ? null
                : () => _runGuarded(
                      () => diary.clearOccurrence(OccurrenceRef(schedule.id, scheduleDay)),
                    ),
            child: const Text('Hủy bỏ qua'),
          ),
        );

      case ScheduleWindowPhase.overdue:
        return Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('$name · $doseLabel', style: tabularNumberStyle(t.bodyLarge)),
                    Text(
                      'Chưa đánh dấu',
                      style: t.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              OutlinedButton(
                onPressed: _busy
                    ? null
                    : () => _runGuarded(() async {
                          final picked = await showTimePicker(
                            context: context,
                            initialTime: TimeOfDay(hour: now.hour, minute: now.minute),
                          );
                          if (picked == null || !context.mounted) return;
                          final at = DateTime(
                            now.year,
                            now.month,
                            now.day,
                            picked.hour,
                            picked.minute,
                          );
                          await markScheduledDoseTaken(
                            context,
                            schedule: schedule,
                            scheduleDay: scheduleDay,
                            at: at,
                          );
                        }),
                child: const Text('Đánh dấu'),
              ),
              const SizedBox(width: AppSpacing.xs),
              TextButton(
                onPressed: _busy
                    ? null
                    : () => _runGuarded(() async {
                          await diary.skipOccurrence(OccurrenceRef(schedule.id, scheduleDay));
                          if (context.mounted) {
                            await AppScope.of(context).cancelWindowIfHandled(schedule.timeOfDay);
                          }
                        }),
                child: const Text('Bỏ qua'),
              ),
            ],
          ),
        );

      case ScheduleWindowPhase.inWindow:
        return Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              Expanded(
                child: Text('$name · $doseLabel', style: tabularNumberStyle(t.bodyLarge)),
              ),
              FilledButton.tonal(
                onPressed: _busy
                    ? null
                    : () {
                        unawaited(HapticFeedback.selectionClick());
                        unawaited(
                          _runGuarded(
                            () => markScheduledDoseTaken(
                              context,
                              schedule: schedule,
                              scheduleDay: scheduleDay,
                              at: now,
                            ),
                          ),
                        );
                      },
                child: const Text('Đã uống'),
              ),
              const SizedBox(width: AppSpacing.xs),
              TextButton(
                onPressed: _busy
                    ? null
                    : () => _runGuarded(() async {
                          await diary.skipOccurrence(OccurrenceRef(schedule.id, scheduleDay));
                          if (context.mounted) {
                            await AppScope.of(context).cancelWindowIfHandled(schedule.timeOfDay);
                          }
                        }),
                child: const Text('Bỏ qua'),
              ),
            ],
          ),
        );

      case ScheduleWindowPhase.early:
        return Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              Expanded(
                child: Text('$name · $doseLabel', style: tabularNumberStyle(t.bodyLarge)),
              ),
              OutlinedButton(
                onPressed: _busy
                    ? null
                    : () => _runGuarded(() async {
                          final asExtra = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: Text(
                                'Ghi cho lần ${formatMinutesHhMm(schedule.timeOfDay)} theo lịch hay lần uống thêm?',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx, true),
                                  child: const Text('Lần uống thêm'),
                                ),
                                FilledButton(
                                  onPressed: () => Navigator.pop(ctx, false),
                                  child: Text('Lần ${formatMinutesHhMm(schedule.timeOfDay)} theo lịch'),
                                ),
                              ],
                            ),
                          );
                          if (asExtra == null || !context.mounted) return;
                          await markScheduledDoseTaken(
                            context,
                            schedule: schedule,
                            scheduleDay: scheduleDay,
                            at: now,
                            asExtra: asExtra,
                          );
                        }),
                child: const Text('Uống sớm?'),
              ),
              const SizedBox(width: AppSpacing.xs),
              TextButton(
                onPressed: _busy
                    ? null
                    : () => _runGuarded(
                          () => diary.skipOccurrence(OccurrenceRef(schedule.id, scheduleDay)),
                        ),
                child: const Text('Bỏ qua'),
              ),
            ],
          ),
        );
    }
  }
}
