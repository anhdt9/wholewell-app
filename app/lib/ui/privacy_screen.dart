import 'package:material_ui/material_ui.dart';

import '../state/app_scope.dart';
import '../state/app_state.dart';
import 'backup_restore_screen.dart';
import 'common/common_widgets.dart';
import 'drive_backup_screens.dart';
import 'privacy_policy_screen.dart';

/// Hiện hộp thoại xác nhận Xóa toàn bộ dữ liệu (kèm tùy chọn Drive nếu đang bật),
/// chờ `withdrawConsentAndReset` xong rồi mới quay về màn gốc.
Future<void> confirmAndWipeAllData(
  BuildContext context, {
  required bool Function() isMounted,
  void Function(bool busy)? onBusyChanged,
}) async {
  final state = AppScope.of(context);
  final nav = Navigator.of(context);
  final messenger = ScaffoldMessenger.maybeOf(context);
  final hasDrive = state.driveEnabled;
  final bool? ok;
  var deleteDrive = false;

  if (!hasDrive) {
    ok = await showWipeConfirmDialog(
      context,
      message: 'Mọi dữ liệu trên máy này sẽ bị xóa và không lấy lại được, trừ khi bạn có bản sao lưu.',
    );
  } else {
    var typed = '';
    ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          final cs = Theme.of(ctx).colorScheme;
          final canConfirm = typed.trim() == 'XÓA';
          return AlertDialog(
            title: const Text('Xóa toàn bộ dữ liệu?'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Mọi dữ liệu trên máy này sẽ bị xóa và không lấy lại được, trừ khi bạn có bản sao lưu.',
                  ),
                  const SizedBox(height: 8),
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                    value: deleteDrive,
                    onChanged: (v) => setDialogState(() => deleteDrive = v ?? false),
                    title: const Text('Xóa cả bản sao lưu trên Google Drive'),
                  ),
                  Text(
                    'Tệp sao lưu bạn đã xuất ra ngoài thì app không xóa được.',
                    style: Theme.of(ctx).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 12),
                  const Text('Gõ XÓA để xác nhận.'),
                  const SizedBox(height: 8),
                  TextField(
                    autofocus: true,
                    textCapitalization: TextCapitalization.characters,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'XÓA',
                    ),
                    onChanged: (v) => setDialogState(() => typed = v),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Hủy')),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: cs.error,
                  foregroundColor: cs.onError,
                ),
                onPressed: canConfirm ? () => Navigator.of(ctx).pop(true) : null,
                child: const Text('Xóa toàn bộ'),
              ),
            ],
          );
        },
      ),
    );
  }

  if (ok != true || !isMounted()) return;
  await _executeResetAndReturnToRoot(
    state: state,
    nav: nav,
    messenger: messenger,
    deleteDriveBackup: deleteDrive,
    isMounted: isMounted,
    onBusyChanged: onBusyChanged,
  );
}

/// Thực thi xóa dữ liệu trên máy (và bản Drive nếu chọn) trước khi `popUntil` về màn gốc.
Future<void> _executeResetAndReturnToRoot({
  required AppState state,
  required NavigatorState nav,
  required ScaffoldMessengerState? messenger,
  required bool deleteDriveBackup,
  required bool Function() isMounted,
  void Function(bool busy)? onBusyChanged,
}) async {
  onBusyChanged?.call(true);
  try {
    final remoteCleared = await state.withdrawConsentAndReset(
      deleteDriveBackup: deleteDriveBackup,
    );
    if (isMounted()) nav.popUntil((r) => r.isFirst);
    if (deleteDriveBackup && !remoteCleared) {
      messenger
        ?..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('Chưa xóa được bản trên Google Drive. App sẽ thử lại khi có mạng.'),
          ),
        );
    }
  } finally {
    if (isMounted()) onBusyChanged?.call(false);
  }
}

/// Màn Quyền riêng tư (`Tôi -> Quyền riêng tư`).
class PrivacyScreen extends StatefulWidget {
  const PrivacyScreen({super.key});

  @override
  State<PrivacyScreen> createState() => _PrivacyScreenState();
}

class _PrivacyScreenState extends State<PrivacyScreen> {
  bool _busy = false;

  Future<void> _withdrawConsent() async {
    final state = AppScope.of(context);
    final hasDrive = state.driveEnabled;
    var deleteDrive = hasDrive; // Rút đồng ý: đánh sẵn theo mvp-overview.md dòng 716.
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          final cs = Theme.of(ctx).colorScheme;
          return AlertDialog(
            title: const Text('Rút đồng ý?'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Rút đồng ý sẽ xóa mọi dữ liệu trên máy này. Nếu có bản sao lưu, bạn có thể khôi phục sau.',
                ),
                if (hasDrive) ...[
                  const SizedBox(height: 8),
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                    value: deleteDrive,
                    onChanged: (v) => setDialogState(() => deleteDrive = v ?? false),
                    title: const Text('Xóa cả bản sao lưu trên Google Drive'),
                  ),
                  Text(
                    'Tệp sao lưu bạn đã xuất ra ngoài thì app không xóa được.',
                    style: Theme.of(ctx).textTheme.bodySmall,
                  ),
                ],
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Hủy')),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: cs.error,
                  foregroundColor: cs.onError,
                ),
                onPressed: () => Navigator.of(ctx).pop(true),
                child: const Text('Rút đồng ý'),
              ),
            ],
          );
        },
      ),
    );
    if (ok != true || !mounted) return;
    await _resetAndReturnToRoot(deleteDriveBackup: hasDrive && deleteDrive);
  }

  Future<void> _resetAndReturnToRoot({required bool deleteDriveBackup}) =>
      _executeResetAndReturnToRoot(
        state: AppScope.of(context),
        nav: Navigator.of(context),
        messenger: ScaffoldMessenger.maybeOf(context),
        deleteDriveBackup: deleteDriveBackup,
        isMounted: () => mounted,
        onBusyChanged: (b) => setState(() => _busy = b),
      );

  Future<void> _exportData() async {
    final go = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xuất dữ liệu'),
        content: const Text('Tệp này không được mã hóa. Ai có tệp đều đọc được.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Hủy')),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Tiếp tục xuất'),
          ),
        ],
      ),
    );
    if (go != true || !mounted) return;
    setState(() => _busy = true);
    try {
      final saved = await AppScope.of(context).exportReadableJsonFile();
      if (!mounted) return;
      AppFeedback.showSnack(
        context,
        saved == null ? 'Chưa xuất được dữ liệu.' : 'Đã xuất dữ liệu JSON.',
      );
    } on Object {
      if (!mounted) return;
      AppFeedback.showSnack(context, 'Chưa xuất được dữ liệu.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _wipeAll() => confirmAndWipeAllData(
        context,
        isMounted: () => mounted,
        onBusyChanged: (b) => setState(() => _busy = b),
      );

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final t = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    final consent = state.healthConsent;
    final grantedLabel =
        consent == null ? 'Chưa có thông tin' : fmtBackupDateTime(consent.grantedAt);
    final driveText = state.driveEnabled
        ? 'Google Drive: Đang bật (${state.driveAccount?.email ?? 'đã kết nối'})'
        : 'Google Drive: chưa bật';

    return Scaffold(
      appBar: AppBar(title: const Text('Quyền riêng tư')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Đồng ý đã cho', style: t.titleMedium),
          const SizedBox(height: 8),
          Text('Xử lý dữ liệu sức khỏe', style: t.bodyLarge),
          const SizedBox(height: 2),
          Text(grantedLabel, style: t.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
          const SizedBox(height: 12),
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
              foregroundColor: cs.error,
            ),
            onPressed: _busy ? null : _withdrawConsent,
            child: const Text('Rút đồng ý'),
          ),
          const Divider(height: 32),
          Text('Sao lưu đám mây', style: t.titleMedium),
          const SizedBox(height: 6),
          Text(
            driveText,
            style: t.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
          ),
          if (state.drivePendingDeleteActive) ...[
            const SizedBox(height: 12),
            const PendingDriveDeleteCard(),
          ],
          const Divider(height: 32),
          Text('Tài liệu', style: t.titleMedium),
          const SizedBox(height: 4),
          ListTile(
            contentPadding: EdgeInsets.zero,
            minTileHeight: 56,
            title: const Text('Chính sách quyền riêng tư'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const PrivacyPolicyScreen()),
            ),
          ),
          const Divider(height: 24),
          Text('Dữ liệu của bạn', style: t.titleMedium),
          const SizedBox(height: 12),
          OutlinedButton(
            style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
            onPressed: _busy ? null : _exportData,
            child: const Text('Xuất dữ liệu'),
          ),
          const SizedBox(height: 10),
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
              foregroundColor: cs.error,
            ),
            onPressed: _busy ? null : _wipeAll,
            child: const Text('Xóa toàn bộ dữ liệu'),
          ),
        ],
      ),
    );
  }
}
