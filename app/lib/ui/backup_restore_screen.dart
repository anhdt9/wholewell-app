import 'package:flutter/services.dart';
import 'package:journal_db/journal_db.dart';
import 'package:material_ui/material_ui.dart';

import '../platform/backup_provider.dart';
import '../state/app_scope.dart';

String fmtBackupDateTime(DateTime t) {
  final l = t.toLocal();
  String p(int v) => v.toString().padLeft(2, '0');
  return '${p(l.day)}/${p(l.month)}/${l.year} ${p(l.hour)}:${p(l.minute)}';
}

/// Màn Sao lưu và khôi phục (`Tôi -> Sao lưu và khôi phục`).
class BackupRestoreScreen extends StatelessWidget {
  const BackupRestoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final t = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    final last = state.lastFileBackupAt;
    final statusText = last == null
        ? 'Chưa sao lưu qua tệp'
        : 'Lần gần nhất: ${fmtBackupDateTime(last)}';

    return Scaffold(
      appBar: AppBar(title: const Text('Sao lưu và khôi phục')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
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
            onPressed: state.canBackupToFile
                ? () => Navigator.of(context).push(
                      MaterialPageRoute<void>(builder: (_) => const CreateBackupScreen()),
                    )
                : null,
            child: const Text('Tạo tệp sao lưu'),
          ),
          const SizedBox(height: 10),
          OutlinedButton(
            style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
            onPressed: state.canRestoreFromFile
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
            'Chưa bật · Sẽ hỗ trợ sau khi hoàn tất cấu hình Google Cloud.',
            style: t.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

enum _BackupSecretMode { recoveryKey, customPassword }

/// Màn Tạo tệp sao lưu mã hóa (`.wwbackup`).
class CreateBackupScreen extends StatefulWidget {
  final int memoryKiB;
  final int iterations;

  const CreateBackupScreen({
    super.key,
    this.memoryKiB = BackupCodec.defaultMemoryKiB,
    this.iterations = BackupCodec.defaultIterations,
  });

  @override
  State<CreateBackupScreen> createState() => _CreateBackupScreenState();
}

class _CreateBackupScreenState extends State<CreateBackupScreen> {
  _BackupSecretMode _mode = _BackupSecretMode.recoveryKey;
  late String _recoveryKey;
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
    if (_mode != _BackupSecretMode.customPassword) return null;
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
      case _BackupSecretMode.recoveryKey:
        return _confirmedSaved;
      case _BackupSecretMode.customPassword:
        return _passCtl.text.length >= 8 && _passCtl.text == _confirmCtl.text;
    }
  }

  String get _activeSecret =>
      _mode == _BackupSecretMode.recoveryKey ? _recoveryKey : _passCtl.text;

  Future<void> _copyKey() async {
    await Clipboard.setData(ClipboardData(text: _recoveryKey));
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text('Đã sao chép mã khôi phục.')));
  }

  Future<void> _createAndSave() async {
    setState(() {
      _busy = true;
      _errorText = null;
    });
    final state = AppScope.of(context);
    try {
      final savedName = await state.createEncryptedBackupFile(
        secret: _activeSecret,
        memoryKiB: widget.memoryKiB,
        iterations: widget.iterations,
      );
      if (!mounted) return;
      if (savedName == null) {
        setState(() {
          _busy = false;
          _errorText = 'Chưa lưu được tệp sao lưu.';
        });
        return;
      }
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text('Đã lưu bản sao lưu mã hóa.')));
      Navigator.of(context).pop();
    } on Object {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _errorText = 'Chưa lưu được tệp sao lưu.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    final pwErr = _passwordError;

    return Scaffold(
      appBar: AppBar(title: const Text('Tạo tệp sao lưu mã hóa')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              'Khóa bản sao lưu chỉ bạn giữ. Quên mã hoặc mật khẩu sẽ không mở lại được tệp.',
            ),
          ),
          const SizedBox(height: 16),
          Text('Cách bảo vệ', style: t.titleSmall),
          const SizedBox(height: 8),
          _ModeChoiceTile(
            label: 'Mã khôi phục 24 ký tự',
            selected: _mode == _BackupSecretMode.recoveryKey,
            enabled: !_busy,
            onTap: () => setState(() {
              _mode = _BackupSecretMode.recoveryKey;
              _errorText = null;
            }),
          ),
          _ModeChoiceTile(
            label: 'Tự đặt mật khẩu',
            selected: _mode == _BackupSecretMode.customPassword,
            enabled: !_busy,
            onTap: () => setState(() {
              _mode = _BackupSecretMode.customPassword;
              _errorText = null;
            }),
          ),
          const SizedBox(height: 16),
          if (_mode == _BackupSecretMode.recoveryKey) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(color: cs.outlineVariant),
                borderRadius: BorderRadius.circular(12),
              ),
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
                      icon: const Icon(Icons.copy, size: 18),
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
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  tooltip: _obscurePass ? 'Hiện' : 'Ẩn',
                  onPressed: () => setState(() => _obscurePass = !_obscurePass),
                  icon: Icon(_obscurePass ? Icons.visibility_outlined : Icons.visibility_off_outlined),
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
                border: const OutlineInputBorder(),
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
            onPressed: _canSubmit ? _createAndSave : null,
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
                      Text('Đang mã hóa bản sao lưu...'),
                    ],
                  )
                : const Text('Chọn nơi lưu tệp'),
          ),
        ],
      ),
    );
  }
}

class _ModeChoiceTile extends StatelessWidget {
  final String label;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  const _ModeChoiceTile({
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
                  selected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
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
          ScaffoldMessenger.maybeOf(context)
            ?..hideCurrentSnackBar()
            ..showSnackBar(const SnackBar(content: Text('Đã khôi phục dữ liệu.')));
          Navigator.of(context).popUntil((r) => r.isFirst);
        case RestoreWrongSecret() || RestoreCorrupted():
          setState(() {
            _busy = false;
            _errorText = 'Mã khôi phục không đúng hoặc tệp đã bị hỏng.';
          });
        case RestoreNeedsUpdate():
          setState(() {
            _busy = false;
            _errorText =
                'Tệp sao lưu được tạo bởi phiên bản WholeWell mới hơn. Hãy cập nhật app trước khi khôi phục.';
          });
        case RestoreFailed():
          setState(() {
            _busy = false;
            _errorText = 'Chưa khôi phục được dữ liệu. Thử lại.';
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
            icon: const Icon(Icons.folder_open_outlined),
            label: const Text('Chọn tệp sao lưu'),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _secretCtl,
            enabled: !_busy,
            obscureText: _obscure,
            decoration: InputDecoration(
              labelText: 'Mã khôi phục / mật khẩu',
              border: const OutlineInputBorder(),
              suffixIcon: IconButton(
                tooltip: _obscure ? 'Hiện' : 'Ẩn',
                onPressed: () => setState(() => _obscure = !_obscure),
                icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined),
              ),
            ),
            onChanged: (_) => setState(() => _errorText = null),
          ),
          if (widget.hasExistingData) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, size: 18),
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
