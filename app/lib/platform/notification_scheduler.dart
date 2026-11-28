/// Interface nền tảng cho nhắc giờ uống bổ sung (Android AlarmManager/Notification, bản giả cho test).
library;

import 'dart:async';

import 'package:flutter/services.dart';

enum NotificationActionKind { markTaken, openTodayDoses, openUlAlerts }

class NotificationAction {
  final NotificationActionKind kind;
  final int? timeOfDayMinutes;
  final List<int> scheduleIds;

  const NotificationAction({required this.kind, this.timeOfDayMinutes, this.scheduleIds = const []});

  factory NotificationAction.fromMap(Map<Object?, Object?> map) {
    final kindStr = map['kind'] as String? ?? 'openTodayDoses';
    final kind = switch (kindStr) {
      'markTaken' => NotificationActionKind.markTaken,
      'openUlAlerts' => NotificationActionKind.openUlAlerts,
      _ => NotificationActionKind.openTodayDoses,
    };
    final rawIds = (map['scheduleIds'] as List?) ?? const [];
    return NotificationAction(
      kind: kind,
      timeOfDayMinutes: (map['timeOfDayMinutes'] as num?)?.toInt(),
      scheduleIds: [for (final id in rawIds) (id as num).toInt()],
    );
  }
}

class ScheduledReminderSlot {
  final int timeOfDayMinutes;
  final int itemCount;
  final List<int> scheduleIds;
  final String? detailText;

  const ScheduledReminderSlot({
    required this.timeOfDayMinutes,
    required this.itemCount,
    required this.scheduleIds,
    this.detailText,
  });

  Map<String, Object?> toMap() => {
    'timeOfDayMinutes': timeOfDayMinutes,
    'itemCount': itemCount,
    'scheduleIds': scheduleIds,
    if (detailText != null && detailText!.isNotEmpty) 'detailText': detailText,
  };
}

abstract interface class NotificationScheduler {
  Future<bool> hasPermission();
  Future<bool> requestPermission();
  Future<bool> canScheduleExactAlarms();
  Future<void> openNotificationSettings();
  Future<void> syncSchedules(List<ScheduledReminderSlot> slots);
  Future<void> cancelWindow(int timeOfDayMinutes);
  Future<void> showUlAlertNotice();
  Stream<NotificationAction> get onNotificationAction;
  Future<NotificationAction?> takePendingNotificationAction();
  Future<void> dispose();
}

/// Bản cài đặt Android qua MethodChannel (`AlarmManager` + `Notification.Builder.setTimeoutAfter`).
class AndroidNotificationScheduler implements NotificationScheduler {
  static const _channel = MethodChannel('vn.wholewell.app/notifications');
  final _ctrl = StreamController<NotificationAction>.broadcast();
  NotificationAction? _queued;

  AndroidNotificationScheduler() {
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'onNotificationAction' && call.arguments is Map) {
        final action = NotificationAction.fromMap(call.arguments as Map<Object?, Object?>);
        if (_ctrl.hasListener) {
          _ctrl.add(action);
        } else {
          _queued = action;
        }
      }
    });
  }

  @override
  Future<bool> hasPermission() async => await _channel.invokeMethod<bool>('hasPermission') ?? true;

  @override
  Future<bool> requestPermission() async => await _channel.invokeMethod<bool>('requestPermission') ?? false;

  @override
  Future<bool> canScheduleExactAlarms() async => await _channel.invokeMethod<bool>('canScheduleExactAlarms') ?? true;

  @override
  Future<void> openNotificationSettings() => _channel.invokeMethod<void>('openNotificationSettings');

  @override
  Future<void> syncSchedules(List<ScheduledReminderSlot> slots) =>
      _channel.invokeMethod<void>('syncSchedules', [for (final s in slots) s.toMap()]);

  @override
  Future<void> cancelWindow(int timeOfDayMinutes) =>
      _channel.invokeMethod<void>('cancelWindow', {'timeOfDayMinutes': timeOfDayMinutes});

  @override
  Future<void> showUlAlertNotice() => _channel.invokeMethod<void>('showUlAlertNotice');

  @override
  Stream<NotificationAction> get onNotificationAction => _ctrl.stream;

  @override
  Future<NotificationAction?> takePendingNotificationAction() async {
    final local = _queued;
    _queued = null;
    if (local != null) return local;
    final raw = await _channel.invokeMethod<Map<Object?, Object?>>('takePendingAction');
    if (raw == null) return null;
    return NotificationAction.fromMap(raw);
  }

  @override
  Future<void> dispose() async {
    _channel.setMethodCallHandler(null);
    await _ctrl.close();
  }
}

/// Bản giả lập cho widget test (hỗ trợ cả warm start stream lẫn cold start `pendingAction`).
class FakeNotificationScheduler implements NotificationScheduler {
  bool granted;
  bool exactAlarmsGranted;
  NotificationAction? pendingAction;
  List<ScheduledReminderSlot> syncedSlots = const [];
  final List<int> canceledWindows = [];
  int ulAlertCount = 0;
  int openedSettingsCount = 0;
  final _ctrl = StreamController<NotificationAction>.broadcast();

  FakeNotificationScheduler({this.granted = true, this.exactAlarmsGranted = true, this.pendingAction});

  void emitAction(NotificationAction action) {
    if (_ctrl.hasListener) {
      _ctrl.add(action);
    } else {
      pendingAction = action;
    }
  }

  @override
  Future<bool> hasPermission() async => granted;

  @override
  Future<bool> requestPermission() async => granted;

  @override
  Future<bool> canScheduleExactAlarms() async => exactAlarmsGranted;

  @override
  Future<void> openNotificationSettings() async {
    openedSettingsCount++;
  }

  @override
  Future<void> syncSchedules(List<ScheduledReminderSlot> slots) async {
    syncedSlots = List.unmodifiable(slots);
  }

  @override
  Future<void> cancelWindow(int timeOfDayMinutes) async {
    canceledWindows.add(timeOfDayMinutes);
  }

  @override
  Future<void> showUlAlertNotice() async {
    ulAlertCount++;
  }

  @override
  Stream<NotificationAction> get onNotificationAction => _ctrl.stream;

  @override
  Future<NotificationAction?> takePendingNotificationAction() async {
    final p = pendingAction;
    pendingAction = null;
    return p;
  }

  @override
  Future<void> dispose() => _ctrl.close();
}
