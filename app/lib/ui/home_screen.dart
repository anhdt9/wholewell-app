import 'dart:async';

import 'package:material_ui/material_ui.dart';

import '../state/app_scope.dart';
import '../state/app_state.dart';
import 'common/log_sheet.dart';
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
            TextButton.icon(
              icon: const Icon(Icons.calendar_today, size: 18),
              label: Text('${d.day}/${d.month}/${d.year}'),
              onPressed: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: d,
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now(),
                );
                if (picked != null) unawaited(state.setDay(picked));
              },
            ),
        ],
      ),
      body: pages[_tab],
      floatingActionButton: _tab < 2
          ? FloatingActionButton.extended(
              heroTag: 'log_sheet',
              icon: const Icon(Icons.add),
              label: const Text('Ghi'),
              onPressed: () => showLogSheet(context),
            )
          : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) {
          if (i == 0 && _tab == 0 && !state.diary.isViewingToday) {
            unawaited(state.resetToToday());
          }
          if (i != _tab) {
            setState(() => _tab = i);
          }
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.insights), label: 'Hôm nay'),
          NavigationDestination(icon: Icon(Icons.restaurant), label: 'Nhật ký'),
          NavigationDestination(icon: Icon(Icons.medication_outlined), label: 'Bổ sung'),
          NavigationDestination(icon: Icon(Icons.person), label: 'Tôi'),
        ],
      ),
    );
  }
}
