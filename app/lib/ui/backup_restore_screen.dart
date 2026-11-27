import 'package:flutter/services.dart';
import 'package:journal_db/journal_db.dart';
import 'package:material_ui/material_ui.dart';

import '../platform/backup_provider.dart';
import '../state/app_scope.dart';
import 'common/common_widgets.dart';
import 'drive_backup_screens.dart';

/// Lỗi nghiệp vụ hiển thị trực tiếp thông điệp tiếng Việt trong [BackupSecretSection].
class BackupSubmitException implements Exception {
  final String message;
  const BackupSubmitException(this.message);
  @override
  String toString() => message;
}

String fmtBackupDateTime(DateTime t) {
  final l = t.toLocal();
  String p(int v) => v.toString().padLeft(2, '0');
  return '${p(l.day)}/${p(l.month)}/${l.year} ${p(l.hour)}:${p(l.minute)}';
}

String restoreOutcomeMessage(RestoreOutcome res) => switch (res) {
      RestoreSucceeded() => 'Đã khôi phục dữ liệu.',
      RestoreWrongSecret() || RestoreCorrupted() => 'Mã khôi phục không đúng hoặc tệp đã bị hỏng.',
      RestoreNeedsUpdate() =>
        'Tệp sao lưu được tạo bởi phiên bản WholeWell mới hơn. Hãy cập nhật app trước khi khôi phục.',
      RestoreFailed() => 'Chưa khôi phục được dữ liệu. Thử lại.',
    };

/// Màn Sao lưu và khôi phục (`Tôi -> Sao lưu và khôi phục`).
class BackupRestoreScreen extends StatefulWidget {
  const BackupRestoreScreen({super.key});

  @override
  State<BackupRestoreScreen> createState() => _BackupRestoreScreenState();
}

class _BackupRestoreScreenState extends State<BackupRestoreScreen> {
  bool _busy = false;

  Future<void> _disconnectDrive() async {
    var deleteRemote = false;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          final cs = Theme.of(ctx).colorScheme;
          return AlertDialog(
            title: const Text('Ngắt kết nối Google Drive?'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Tài khoản Google sẽ được ngắt khỏi WholeWell trên máy này.'),
                const SizedBox(height: 8),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  value: deleteRemote,
                  onChanged: (v) => setDialogState(() => deleteRemote = v ?? false),
                  title: const Text('Xóa cả bản sao lưu trên Google Drive'),
                ),
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
                child: const Text('Ngắt kết nối'),
              ),
            ],
          );
        },
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _busy = true);
    try {
      final cleared = await AppScope.of(context).disconnectGoogleDrive(
        deleteRemoteBackups: deleteRemote,
      );
      if (!mounted) return;
      final msg = !deleteRemote || cleared
          ? 'Đã ngắt kết nối Google Drive.'
          : 'Chưa xóa được bản trên Google Drive. App sẽ thử lại khi có mạng.';
      AppFeedback.showSnack(context, msg);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final t = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    final last = state.lastFileBackupAt;
    final statusText = last == null
        ? 'Chưa sao lưu qua tệp'
        : 'Lần gần nhất: ${fmtBackupDateTime(last)}';

    final lastDrive = state.lastDriveBackupAt;
    final driveEmail = state.driveAccount?.email;
    final driveStatus = state.driveEnabled
        ? [
            if (driveEmail != null) 'Tài khoản: $driveEmail',
            lastDrive == null
                ? 'Chưa sao lưu lên Drive'
                : 'Lần gần nhất: ${fmtBackupDateTime(lastDrive)}',
          ].join(' · ')
        : 'Dữ liệu gửi lên thư mục ẩn (appDataFolder) trên Google Drive ở dạng đã mã hóa.';

    return Scaffold(
      appBar: AppBar(title: const Text('Sao lưu và khôi phục')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (state.drivePendingDeleteActive) ...[
            const PendingDriveDeleteCard(),
            const SizedBox(height: 16),
          ],
          Text('Tệp mã hóa trên máy', style: t.titleMedium),
          const SizedBox(height: 6),
          Text(
            'Xuất ra tệp .wwbackup để tự giữ hoặc chép sang máy khác.',
            style: t.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
          ),
          const SizedBox(height: 6),
          Text(statusText, style: t.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
          const SizedBox(height: 16),
          FilledButton(
            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
            onPressed: state.canBackupToFile && !_busy
                ? () => Navigator.of(context).push(
                      MaterialPageRoute<void>(builder: (_) => const CreateBackupScreen()),
                    )
                : null,
            child: const Text('Tạo tệp sao lưu'),
          ),
          const SizedBox(height: 10),
          OutlinedButton(
            style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
            onPressed: state.canRestoreFromFile && !_busy
                ? () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const RestoreBackupScreen(hasExistingData: true),
                      ),
                    )
                : null,
            child: const Text('Khôi phục từ tệp'),
          ),
          const Divider(height: 32),
          Text('Google Drive (tùy chọn)', style: t.titleMedium),
          const SizedBox(height: 6),
          Text(
            driveStatus,
            style: t.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
          ),
          const SizedBox(height: 16),
          if (!state.driveEnabled)
            FilledButton.tonal(
              style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
              onPressed: state.canBackupToFile && !_busy
                  ? () => Navigator.of(context).push(
                        MaterialPageRoute<void>(builder: (_) => const DriveConsentScreen()),
                      )
                  : null,
              child: const Text('Kết nối Google Drive'),
            )
          else
            FilledButton.tonal(
              style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
              onPressed: state.canBackupToFile && !_busy
                  ? () => Navigator.of(context).push(
                        MaterialPageRoute<void>(builder: (_) => const CreateDriveBackupScreen()),
                      )
                  : null,
              child: const Text('Sao lưu lên Drive'),
            ),
          const SizedBox(height: 10),
          OutlinedButton(
            style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
            onPressed: state.canRestoreFromFile && !_busy
                ? () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const RestoreDriveBackupScreen(hasExistingData: true),
                      ),
                    )
                : null,
            child: const Text('Khôi phục từ Drive'),
          ),
          if (state.driveEnabled) ...[
            const SizedBox(height: 6),
            TextButton(
              style: TextButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
                foregroundColor: cs.error,
              ),
              onPressed: _busy ? null : _disconnectDrive,
              child: const Text('Ngắt kết nối Google Drive'),
            ),
          ],
        ],
      ),
    );
  }
}

enum BackupSecretMode { recoveryKey, customPassword }

/// Phần chọn mã khôi phục 24 ký tự hoặc mật khẩu tự đặt dùng chung cho sao lưu tệp và Drive.
class BackupSecretSection extends StatefulWidget {
  final String noticeText;
  final String primaryLabel;
  final String busyLabel;
  final Future<void> Function(String secret) onSubmit;

  const BackupSecretSection({
    super.key,
    this.noticeText =
        'Khóa bản sao lưu chỉ bạn giữ. Quên mã hoặc mật khẩu sẽ không mở lại được tệp.',
    required this.primaryLabel,
    required this.busyLabel,
    required this.onSubmit,
  });

  @override
  State<BackupSecretSection> createState() => _BackupSecretSectionState();
}

class _BackupSecretSectionState extends State<BackupSecretSection> {
  BackupSecretMode _mode = BackupSecretMode.recoveryKey;
  late final String _recoveryKey;
  bool _confirmedSaved = false;
  final _passCtl = TextEditingController();
  final _confirmCtl = TextEditingController();
  bool _obscurePass = true;
  bool _busy = false;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _recoveryKey = BackupCodec.generateRecoveryKey();
  }

  @override
  void dispose() {
    _passCtl.dispose();
    _confirmCtl.dispose();
    super.dispose();
  }

  String? get _passwordError {
    if (_mode != BackupSecretMode.customPassword) return null;
    final p = _passCtl.text;
    final c = _confirmCtl.text;
    if (p.isEmpty && c.isEmpty) return null;
    if (p.length < 8) return 'Mật khẩu tối thiểu 8 ký tự.';
    if (c.isNotEmpty && p != c) return 'Mật khẩu nhập lại chưa khớp.';
    return null;
  }

  bool get _canSubmit {
    if (_busy) return false;
    switch (_mode) {
      case BackupSecretMode.recoveryKey:
        return _confirmedSaved;
      case BackupSecretMode.customPassword:
        return _passCtl.text.length >= 8 && _passCtl.text == _confirmCtl.text;
    }
  }

  String get _activeSecret =>
      _mode == BackupSecretMode.recoveryKey ? _recoveryKey : _passCtl.text;

  Future<void> _copyKey() async {
    await Clipboard.setData(ClipboardData(text: _recoveryKey));
    if (!mounted) return;
    AppFeedback.showSnack(context, 'Đã sao chép mã khôi phục.');
  }

  Future<void> _handleSubmit() async {
    setState(() {
      _busy = true;
      _errorText = null;
    });
    try {
      await widget.onSubmit(_activeSecret);
    } on BackupSubmitException catch (e) {
      if (mounted) {
        setState(() {
          _busy = false;
          _errorText = e.message;
        });
      }
      return;
    } on Object catch (e) {
      if (mounted) {
        setState(() {
          _busy = false;
          _errorText = e.toString();
        });
      }
      return;
    }
    if (mounted) {
      setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    final pwErr = _passwordError;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SurfaceCard(
          color: cs.surfaceContainerHighest,
          borderColor: cs.surfaceContainerHighest,
          child: Text(widget.noticeText),
        ),
        const SizedBox(height: 16),
        Text('Cách bảo vệ', style: t.titleSmall),
        const SizedBox(height: 8),
        BackupRadioRow(
          label: 'Mã khôi phục 24 ký tự',
          selected: _mode == BackupSecretMode.recoveryKey,
          enabled: !_busy,
          onTap: () => setState(() {
            _mode = BackupSecretMode.recoveryKey;
            _errorText = null;
          }),
        ),
        BackupRadioRow(
          label: 'Tự đặt mật khẩu',
          selected: _mode == BackupSecretMode.customPassword,
          enabled: !_busy,
          onTap: () => setState(() {
            _mode = BackupSecretMode.customPassword;
            _errorText = null;
          }),
        ),
        const SizedBox(height: 16),
        if (_mode == BackupSecretMode.recoveryKey) ...[
          SurfaceCard(
            color: Colors.transparent,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SelectableText(
                  _recoveryKey,
                  style: t.titleMedium?.copyWith(fontFamily: 'monospace', letterSpacing: 1.1),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: _busy ? null : _copyKey,
                    icon: const Icon(LucideIcons.copy, size: 18),
                    label: const Text('Sao chép'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            value: _confirmedSaved,
            onChanged: _busy ? null : (v) => setState(() => _confirmedSaved = v ?? false),
            title: const Text('Tôi đã lưu mã này ở nơi an toàn.'),
          ),
        ] else ...[
          TextField(
            controller: _passCtl,
            enabled: !_busy,
            obscureText: _obscurePass,
            decoration: InputDecoration(
              labelText: 'Mật khẩu (tối thiểu 8 ký tự)',
              suffixIcon: IconButton(
                tooltip: _obscurePass ? 'Hiện' : 'Ẩn',
                onPressed: () => setState(() => _obscurePass = !_obscurePass),
                icon: Icon(_obscurePass ? LucideIcons.eye : LucideIcons.eyeOff),
              ),
            ),
            onChanged: (_) => setState(() => _errorText = null),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _confirmCtl,
            enabled: !_busy,
            obscureText: _obscurePass,
            decoration: InputDecoration(
              labelText: 'Nhập lại mật khẩu',
              errorText: pwErr,
            ),
            onChanged: (_) => setState(() => _errorText = null),
          ),
        ],
        if (_errorText != null) ...[
          const SizedBox(height: 12),
          Text(_errorText!, style: TextStyle(color: cs.error)),
        ],
        const SizedBox(height: 20),
        FilledButton(
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
          onPressed: _canSubmit ? _handleSubmit : null,
          child: _busy
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    const SizedBox(width: 12),
                    Text(widget.busyLabel),
                  ],
                )
              : Text(widget.primaryLabel),
        ),
      ],
    );
  }
}

/// Màn Tạo tệp sao lưu mã hóa (`.wwbackup`).
class CreateBackupScreen extends StatelessWidget {
  final int memoryKiB;
  final int iterations;

  const CreateBackupScreen({
    super.key,
    this.memoryKiB = BackupCodec.defaultMemoryKiB,
    this.iterations = BackupCodec.defaultIterations,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tạo tệp sao lưu mã hóa')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          BackupSecretSection(
            primaryLabel: 'Chọn nơi lưu tệp',
            busyLabel: 'Đang mã hóa bản sao lưu...',
            onSubmit: (secret) async {
              final state = AppScope.of(context);
              final savedName = await state.createEncryptedBackupFile(
                secret: secret,
                memoryKiB: memoryKiB,
                iterations: iterations,
              );
              if (savedName == null) {
                throw const BackupSubmitException('Chưa lưu được tệp sao lưu.');
              }
              if (!context.mounted) return;
              AppFeedback.showSnack(context, 'Đã lưu bản sao lưu mã hóa.');
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }
}

class BackupRadioRow extends StatelessWidget {
  final String label;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  const BackupRadioRow({
    super.key,
    required this.label,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Semantics(
      inMutuallyExclusiveGroup: true,
      selected: selected,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(8),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            child: Row(
              children: [
                Icon(
                  selected ? LucideIcons.circleDot : LucideIcons.circle,
                  color: selected ? cs.primary : cs.onSurfaceVariant,
                ),
                const SizedBox(width: 12),
                Expanded(child: Text(label)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Màn Khôi phục từ tệp (`.wwbackup`), dùng được từ Chào mừng, Màn lỗi khóa, và Tab Tôi.
class RestoreBackupScreen extends StatefulWidget {
  final bool hasExistingData;

  const RestoreBackupScreen({super.key, required this.hasExistingData});

  @override
  State<RestoreBackupScreen> createState() => _RestoreBackupScreenState();
}

class _RestoreBackupScreenState extends State<RestoreBackupScreen> {
  PickedBackupFile? _picked;
  final _secretCtl = TextEditingController();
  bool _obscure = true;
  bool _busy = false;
  String? _errorText;

  @override
  void dispose() {
    _secretCtl.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    setState(() => _errorText = null);
    try {
      final f = await AppScope.of(context).backupFileProvider.pickFile();
      if (!mounted) return;
      if (f != null) {
        setState(() => _picked = f);
      }
    } on Object {
      if (!mounted) return;
      setState(() => _errorText = 'Chưa đọc được tệp sao lưu.');
    }
  }

  Future<void> _restore() async {
    if (_busy) return;
    final file = _picked;
    if (file == null || _secretCtl.text.trim().isEmpty) return;

    if (widget.hasExistingData) {
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Thay dữ liệu hiện tại?'),
          content: const Text(
            'Dữ liệu hiện tại trên máy này sẽ được thay bằng bản sao lưu. Tiếp tục?',
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Hủy')),
            FilledButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Khôi phục')),
          ],
        ),
      );
      if (ok != true || !mounted) return;
    }

    setState(() {
      _busy = true;
      _errorText = null;
    });
    final state = AppScope.of(context);
    try {
      final res = await state.restoreEncryptedBackupFile(
        backupBytes: file.bytes,
        secret: _secretCtl.text.trim(),
      );
      if (!mounted) return;
      switch (res) {
        case RestoreSucceeded():
          AppFeedback.showSnack(context, 'Đã khôi phục dữ liệu.');
          Navigator.of(context).popUntil((r) => r.isFirst);
        case RestoreWrongSecret() || RestoreCorrupted() || RestoreNeedsUpdate() || RestoreFailed():
          setState(() {
            _busy = false;
            _errorText = restoreOutcomeMessage(res);
          });
      }
    } on Object {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _errorText = 'Chưa khôi phục được dữ liệu. Thử lại.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    final canRestore = !_busy && _picked != null && _secretCtl.text.trim().isNotEmpty;

    return Scaffold(
      appBar: AppBar(title: const Text('Khôi phục từ bản sao lưu')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Chọn tệp .wwbackup và nhập mã khôi phục hoặc mật khẩu.'),
          const SizedBox(height: 16),
          if (_picked != null) ...[
            Text('Tệp: ${_picked!.name}', style: t.bodyMedium),
            const SizedBox(height: 8),
          ],
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
            onPressed: _busy ? null : _pickFile,
            icon: const Icon(LucideIcons.folderOpen),
            label: const Text('Chọn tệp sao lưu'),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _secretCtl,
            enabled: !_busy,
            obscureText: _obscure,
            decoration: InputDecoration(
              labelText: 'Mã khôi phục / mật khẩu',
              suffixIcon: IconButton(
                tooltip: _obscure ? 'Hiện' : 'Ẩn',
                onPressed: () => setState(() => _obscure = !_obscure),
                icon: Icon(_obscure ? LucideIcons.eye : LucideIcons.eyeOff),
              ),
            ),
            onChanged: (_) => setState(() => _errorText = null),
          ),
          if (widget.hasExistingData) ...[
            const SizedBox(height: 16),
            SurfaceCard(
              color: cs.surfaceContainerHighest,
              borderColor: cs.surfaceContainerHighest,
              child: const Row(
                children: [
                  Icon(LucideIcons.info, size: 18),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text('Khôi phục sẽ thay dữ liệu hiện tại trên máy này.'),
                  ),
                ],
              ),
            ),
          ],
          if (_errorText != null) ...[
            const SizedBox(height: 12),
            Text(_errorText!, style: TextStyle(color: cs.error)),
          ],
          const SizedBox(height: 20),
          FilledButton(
            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
            onPressed: canRestore ? _restore : null,
            child: _busy
                ? const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      SizedBox(width: 12),
                      Text('Đang giải mã và kiểm tra...'),
                    ],
                  )
                : const Text('Khôi phục'),
          ),
        ],
      ),
    );
  }
}
