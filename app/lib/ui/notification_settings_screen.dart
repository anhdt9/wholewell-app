/// Màn Nhắc giờ (`Tôi -> Nhắc giờ` hoặc màn xin đồng ý lần đầu sau khi đặt lịch).
library;

import 'package:material_ui/material_ui.dart';

import '../state/app_scope.dart';
import 'common/common_widgets.dart';

class NotificationSettingsScreen extends StatefulWidget {
  final bool firstSetupFlow;
  const NotificationSettingsScreen({super.key, this.firstSetupFlow = false});

  @override
  State<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  bool _checked = false;
  bool _hasPerm = true;
  bool _exactOk = true;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _refreshPermStatus());
  }

  Future<void> _refreshPermStatus() async {
    if (!mounted) return;
    final ns = AppScope.of(context).notificationScheduler;
    final hasPerm = await ns.hasPermission();
    final exactOk = await ns.canScheduleExactAlarms();
    if (!mounted) return;
    setState(() {
      _hasPerm = hasPerm;
      _exactOk = exactOk;
    });
  }

  Future<void> _enableFirstTime() async {
    if (_busy) return;
    setState(() => _busy = true);
    var granted = false;
    try {
      final state = AppScope.of(context);
      granted = await state.enableNotifications(consentVersion: 'notif-1');
      await _refreshPermStatus();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
    if (!mounted) return;
    if (widget.firstSetupFlow && granted) {
      Navigator.of(context).pop(true);
    }
  }

  Future<void> _toggle(bool v) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final state = AppScope.of(context);
      if (v) {
        await state.enableNotifications(consentVersion: 'notif-1');
      } else {
        await state.disableNotifications();
      }
      await _refreshPermStatus();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _toggleShowDetails(bool v) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final state = AppScope.of(context);
      final next = state.diary.dayTimesSettings.copyWith(reminderShowDetails: v);
      await state.diary.saveDayTimesSettings(next);
      await state.syncNotifications();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final enabled = state.notificationsEnabled;
    final showDetails = state.diary.dayTimesSettings.reminderShowDetails;
    final t = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Nhắc giờ')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Nhận thông báo khi tới giờ uống bổ sung.'),
          const SizedBox(height: 12),
          Text(
            '• Mặc định màn hình khóa chỉ hiện "Đến giờ uống", không hiện tên chất hay sản phẩm.\n'
            '• Nếu bật hiện tên sản phẩm, tên sản phẩm có thể thấy trên màn hình khóa; app vẫn không hiện tên chất hay liều lượng.\n'
            '• Bấm "Đã uống" cần mở khóa máy trước khi ghi.',
            style: t.bodySmall,
          ),
          const SizedBox(height: 16),
          if (!enabled) ...[
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              value: _checked,
              onChanged: _busy ? null : (v) => setState(() => _checked = v ?? false),
              title: const Text('Tôi đồng ý bật thông báo nhắc giờ trên máy này'),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: _checked && !_busy ? _enableFirstTime : null,
              child: const Text('Bật nhắc giờ'),
            ),
            if (widget.firstSetupFlow)
              TextButton(
                onPressed: _busy ? null : () => Navigator.of(context).pop(false),
                child: const Text('Để sau'),
              ),
          ] else ...[
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Thông báo nhắc giờ'),
              value: true,
              onChanged: _busy ? null : _toggle,
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Hiện tên sản phẩm trên thông báo'),
              subtitle: const Text('Ví dụ: "Đến giờ uống: Vitamin C 500 mg"'),
              value: showDetails,
              onChanged: _busy ? null : _toggleShowDetails,
            ),
            if (showDetails) ...[
              const SizedBox(height: 8),
              const SafetyNote(
                message:
                    'Tên sản phẩm bổ sung sẽ hiển thị trên thông báo và màn hình khóa. App vẫn không hiện tên chất hay liều lượng.',
              ),
            ],
          ],
          if (!_hasPerm) ...[
            const SizedBox(height: 12),
            const SafetyNote(message: 'Chưa có quyền gửi thông báo trên máy này.'),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () async {
                await state.notificationScheduler.openNotificationSettings();
                await _refreshPermStatus();
              },
              icon: const Icon(Icons.settings_outlined),
              label: const Text('Mở cài đặt'),
            ),
          ],
          if (enabled && _hasPerm && !_exactOk) ...[
            const SizedBox(height: 12),
            const SafetyNote(
              message: 'Thông báo có thể đến lệch vài phút theo chế độ tiết kiệm pin.',
            ),
          ],
        ],
      ),
    );
  }
}
