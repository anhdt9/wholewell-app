import 'dart:async';

import 'package:flutter/services.dart' show HapticFeedback;
import 'package:material_ui/material_ui.dart';

import '../state/app_scope.dart';
import '../state/app_state.dart';
import 'common/common_widgets.dart';
import 'common/log_sheet.dart';
import 'design_system/tokens.dart';
import 'diary_screen.dart';
import 'me_screen.dart';
import 'schedule_dose_helper.dart';
import 'supplements_screen.dart';
import 'today_doses_screen.dart';
import 'today_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _tab = 0;
  StreamSubscription<NotificationAction>? _notifSub;
  bool _checkedPending = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final state = AppScope.of(context);
    _notifSub ??= state.notificationScheduler.onNotificationAction.listen(_handleNotifAction);
    if (!_checkedPending && state.diary.profile != null) {
      _checkedPending = true;
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        final pending = await state.notificationScheduler.takePendingNotificationAction();
        if (pending != null && mounted) {
          await _handleNotifAction(pending);
        }
      });
    }
  }

  Future<void> _handleNotifAction(NotificationAction action) async {
    if (!mounted) return;
    switch (action.kind) {
      case NotificationActionKind.markTaken:
        final tod = action.timeOfDayMinutes;
        if (tod != null) {
          await showReminderQuickConfirmSheet(
            context,
            timeOfDayMinutes: tod,
            scheduleIds: action.scheduleIds,
          );
        } else {
          await Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => const TodayDosesScreen()),
          );
        }
      case NotificationActionKind.openTodayDoses:
        await Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => const TodayDosesScreen()),
        );
      case NotificationActionKind.openUlAlerts:
        setState(() => _tab = 0);
    }
  }

  @override
  void dispose() {
    unawaited(_notifSub?.cancel());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final d = state.day;
    const pages = [TodayScreen(), DiaryScreen(), SupplementsScreen(), MeScreen()];
    return Scaffold(
      appBar: AppBar(
        title: Text(['Hôm nay', 'Nhật ký', 'Bổ sung', 'Tôi'][_tab]),
        actions: [
          if (_tab < 2)
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.md),
              child: _DaySwitcherPill(
                day: d,
                isToday: state.diary.isViewingToday,
                onSelectDay: (target) => unawaited(state.setDay(target)),
                onPickDate: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: d,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                  );
                  if (picked != null) unawaited(state.setDay(picked));
                },
              ),
            ),
        ],
      ),
      body: pages[_tab],
      floatingActionButton: _tab < 2
          ? FloatingActionButton.extended(
              heroTag: 'log_sheet',
              icon: const Icon(LucideIcons.plus),
              label: const Text('Ghi'),
              onPressed: () => showLogSheet(context),
            )
          : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) {
          if (i == 0 && _tab == 0 && !state.diary.isViewingToday) {
            unawaited(HapticFeedback.selectionClick());
            unawaited(state.resetToToday());
          }
          if (i != _tab) {
            unawaited(HapticFeedback.selectionClick());
            setState(() => _tab = i);
          }
        },
        destinations: const [
          NavigationDestination(icon: Icon(LucideIcons.activity), label: 'Hôm nay'),
          NavigationDestination(icon: Icon(LucideIcons.utensils), label: 'Nhật ký'),
          NavigationDestination(icon: Icon(LucideIcons.pill), label: 'Bổ sung'),
          NavigationDestination(icon: Icon(LucideIcons.user), label: 'Tôi'),
        ],
      ),
    );
  }
}

class _DaySwitcherPill extends StatelessWidget {
  final DateTime day;
  final bool isToday;
  final ValueChanged<DateTime> onSelectDay;
  final VoidCallback onPickDate;

  const _DaySwitcherPill({
    required this.day,
    required this.isToday,
    required this.onSelectDay,
    required this.onPickDate,
  });

  String _pillLabel() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(day.year, day.month, day.day);
    final diff = today.difference(target).inDays;
    if (diff == 0) return 'Hôm nay, ${day.day}/${day.month}';
    if (diff == 1) return 'Hôm qua, ${day.day}/${day.month}';
    return '${day.day}/${day.month}/${day.year}';
  }

  @override
  Widget build(BuildContext context) {
    final ww = context.wwColors;
    final cs = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    final canPrev = day.isAfter(DateTime(2020, 1, 2));

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 230),
      child: Material(
        color: ww.subtleSurface,
        shape: StadiumBorder(side: BorderSide(color: ww.outlineSubtle)),
        clipBehavior: Clip.antiAlias,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              tooltip: 'Ngày trước',
              constraints: const BoxConstraints(minWidth: 40, minHeight: 44),
              padding: EdgeInsets.zero,
              icon: Icon(
                LucideIcons.chevronLeft,
                size: 16,
                color: canPrev ? cs.onSurface : cs.onSurfaceVariant.withValues(alpha: 0.4),
              ),
              onPressed: canPrev
                  ? () => onSelectDay(day.subtract(const Duration(days: 1)))
                  : null,
            ),
            Flexible(
              child: InkWell(
                onTap: onPickDate,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                  child: Text(
                    _pillLabel(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: tabularNumberStyle(
                      t.labelLarge?.copyWith(color: cs.onSurface),
                    ),
                  ),
                ),
              ),
            ),
            IconButton(
              tooltip: 'Ngày sau',
              constraints: const BoxConstraints(minWidth: 40, minHeight: 44),
              padding: EdgeInsets.zero,
              icon: Icon(
                LucideIcons.chevronRight,
                size: 16,
                color: isToday ? cs.onSurfaceVariant.withValues(alpha: 0.4) : cs.onSurface,
              ),
              onPressed: isToday
                  ? null
                  : () => onSelectDay(day.add(const Duration(days: 1))),
            ),
          ],
        ),
      ),
    );
  }
}
