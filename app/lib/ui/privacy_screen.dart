import 'package:material_ui/material_ui.dart';

import '../state/app_scope.dart';
import 'backup_restore_screen.dart';
import 'common/common_widgets.dart';

/// Màn Quyền riêng tư (`Tôi -> Quyền riêng tư`).
class PrivacyScreen extends StatefulWidget {
  const PrivacyScreen({super.key});

  @override
  State<PrivacyScreen> createState() => _PrivacyScreenState();
}

class _PrivacyScreenState extends State<PrivacyScreen> {
  bool _busy = false;

  Future<void> _withdrawConsent() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final cs = Theme.of(ctx).colorScheme;
        return AlertDialog(
          title: const Text('Rút đồng ý?'),
          content: const Text(
            'Rút đồng ý sẽ xóa mọi dữ liệu trên máy này. Nếu có bản sao lưu, bạn có thể khôi phục sau.',
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
    );
    if (ok != true || !mounted) return;
    await _resetAndReturnToRoot();
  }

  Future<void> _resetAndReturnToRoot() async {
    final state = AppScope.of(context);
    final nav = Navigator.of(context);
    setState(() => _busy = true);
    try {
      await state.withdrawConsentAndReset();
      if (mounted) nav.popUntil((r) => r.isFirst);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

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
      ScaffoldMessenger.maybeOf(context)
        ?..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(saved == null ? 'Chưa xuất được dữ liệu.' : 'Đã xuất dữ liệu JSON.'),
          ),
        );
    } on Object {
      if (!mounted) return;
      ScaffoldMessenger.maybeOf(context)
        ?..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text('Chưa xuất được dữ liệu.')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _wipeAll() async {
    final ok = await showWipeConfirmDialog(
      context,
      message: 'Mọi dữ liệu trên máy này sẽ bị xóa và không lấy lại được, trừ khi bạn có bản sao lưu.',
    );
    if (!ok || !mounted) return;
    await _resetAndReturnToRoot();
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final t = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    final consent = state.healthConsent;
    final grantedLabel =
        consent == null ? 'Chưa có thông tin' : fmtBackupDateTime(consent.grantedAt);

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
            'Google Drive: chưa bật',
            style: t.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
          ),
          const Divider(height: 32),
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
