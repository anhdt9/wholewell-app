/// Màn Lần uống hôm nay: hiển thị các khung giờ uống theo lịch và nút Đã uống / Bỏ qua / Đánh dấu.
library;

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
              message: 'Chưa có lịch uống. Mở một sản phẩm để đặt lịch.',
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                for (final tod in times) ...[
                  Text(
                    formatMinutesHhMm(tod),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 6),
                  for (final s in byTime[tod]!)
                    _ScheduleOccurrenceTile(
                      schedule: s,
                      scheduleDay: todayStr,
                      product: prodMap[s.productId],
                      occurrence: occMap[s.id],
                      dose: occMap[s.id]?.doseEntryId == null
                          ? null
                          : doseMap[occMap[s.id]!.doseEntryId!],
                      now: now,
                    ),
                  for (final n in notices)
                    if (n.severity == 'notice' && n.timeOfDay == tod) ...[
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: SafetyNote(message: n.messageVi),
                      ),
                    ],
                  const Divider(height: 20),
                ],
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
          contentPadding: EdgeInsets.zero,
          leading: const Icon(LucideIcons.circleCheck),
          title: Text('$name · $doseLabel'),
          subtitle: Text('Đã uống$timeStr'),
          trailing: dose == null ? null : const Icon(LucideIcons.chevronRight),
          onTap: dose == null
              ? null
              : () => Navigator.of(context).push(
                    MaterialPageRoute<void>(builder: (_) => AddSupplementScreen(existingDose: dose)),
                  ),
        );

      case ScheduleWindowPhase.skipped:
        return ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(LucideIcons.circleMinus),
          title: Text('$name · $doseLabel'),
          subtitle: const Text('Đã bỏ qua'),
          trailing: TextButton(
            onPressed: _busy
                ? null
                : () => _runGuarded(() => diary.clearOccurrence(OccurrenceRef(schedule.id, scheduleDay))),
            child: const Text('Hủy bỏ qua'),
          ),
        );

      case ScheduleWindowPhase.overdue:
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('$name · $doseLabel', style: Theme.of(context).textTheme.bodyLarge),
                    const Text('Chưa đánh dấu'),
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
              const SizedBox(width: 4),
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
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              Expanded(
                child: Text('$name · $doseLabel', style: Theme.of(context).textTheme.bodyLarge),
              ),
              FilledButton.tonal(
                onPressed: _busy
                    ? null
                    : () => _runGuarded(
                          () => markScheduledDoseTaken(
                            context,
                            schedule: schedule,
                            scheduleDay: scheduleDay,
                            at: now,
                          ),
                        ),
                child: const Text('Đã uống'),
              ),
              const SizedBox(width: 4),
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
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              Expanded(
                child: Text('$name · $doseLabel', style: Theme.of(context).textTheme.bodyLarge),
              ),
              OutlinedButton(
                onPressed: _busy
                    ? null
                    : () => _runGuarded(() async {
                          final asExtra = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: Text(
                                  'Ghi cho lần ${formatMinutesHhMm(schedule.timeOfDay)} theo lịch hay lần uống thêm?'),
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
              const SizedBox(width: 4),
              TextButton(
                onPressed: _busy
                    ? null
                    : () => _runGuarded(() => diary.skipOccurrence(OccurrenceRef(schedule.id, scheduleDay))),
                child: const Text('Bỏ qua'),
              ),
            ],
          ),
        );
    }
  }
}
