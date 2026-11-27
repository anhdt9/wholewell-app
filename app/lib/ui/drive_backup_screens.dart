import 'dart:async';

import 'package:journal_db/journal_db.dart';
import 'package:material_ui/material_ui.dart';

import '../platform/backup_provider.dart';
import '../state/app_scope.dart';
import 'backup_restore_screen.dart';
import 'common/common_widgets.dart';

/// Sheet chọn nguồn khôi phục khi bấm "Khôi phục từ bản sao lưu" ở Chào mừng hoặc màn lỗi khóa.
Future<void> showRestoreSourcePicker(
  BuildContext context, {
  required bool hasExistingData,
}) async {
  final choice = await showModalBottomSheet<String>(
    context: context,
    builder: (ctx) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Khôi phục từ bản sao lưu', style: Theme.of(ctx).textTheme.titleMedium),
            const SizedBox(height: 12),
            FilledButton.tonalIcon(
              style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
              onPressed: () => Navigator.of(ctx).pop('file'),
              icon: const Icon(LucideIcons.folderOpen),
              label: const Text('Từ tệp trên máy (.wwbackup)'),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
              onPressed: () => Navigator.of(ctx).pop('drive'),
              icon: const Icon(LucideIcons.cloudDownload),
              label: const Text('Từ Google Drive'),
            ),
          ],
        ),
      ),
    ),
  );
  if (!context.mounted || choice == null) return;
  if (choice == 'file') {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => RestoreBackupScreen(hasExistingData: hasExistingData),
      ),
    );
  } else if (choice == 'drive') {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => RestoreDriveBackupScreen(hasExistingData: hasExistingData),
      ),
    );
  }
}

/// Thẻ nhắc khi còn bản sao lưu trên Google Drive chưa xóa được (mất mạng hoặc hết phiên).
class PendingDriveDeleteCard extends StatefulWidget {
  const PendingDriveDeleteCard({super.key});

  @override
  State<PendingDriveDeleteCard> createState() => _PendingDriveDeleteCardState();
}

class _PendingDriveDeleteCardState extends State<PendingDriveDeleteCard> {
  bool _busy = false;
  String? _error;

  Future<void> _retry() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    final ok = await AppScope.of(context).resolvePendingDriveDelete(interactiveSignIn: true);
    if (!mounted) return;
    setState(() {
      _busy = false;
      if (!ok) {
        _error = 'Chưa xóa được bản trên Google Drive. Kiểm tra mạng hoặc thử lại.';
      }
    });
  }

  Future<void> _dismiss() async {
    setState(() => _busy = true);
    await AppScope.of(context).resolvePendingDriveDelete(interactiveSignIn: false);
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final cs = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    final needsReauth = state.drivePendingDeleteNeedsReauth;

    return SurfaceCard(
      color: cs.surfaceContainerHighest,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(LucideIcons.info, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  needsReauth
                      ? 'Chưa xóa được bản trên Google Drive do hết phiên đăng nhập.'
                      : 'Chưa xóa được bản trên Google Drive. App sẽ thử lại khi có mạng.',
                  style: t.bodyMedium,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Bạn có thể đăng nhập lại để xóa hoặc vào Google Drive → Cài đặt → Quản lý ứng dụng.',
            style: t.bodySmall?.copyWith(color: cs.onSurfaceVariant),
          ),
          if (_error != null) ...[
            const SizedBox(height: 6),
            Text(_error!, style: TextStyle(color: cs.error)),
          ],
          const SizedBox(height: 10),
          FilledButton.tonal(
            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
            onPressed: _busy ? null : _retry,
            child: _busy
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Đăng nhập để xóa'),
          ),
          TextButton(
            style: TextButton.styleFrom(minimumSize: const Size.fromHeight(48)),
            onPressed: _busy ? null : _dismiss,
            child: const Text('Đã tự xóa / Bỏ qua'),
          ),
        ],
      ),
    );
  }
}

/// Màn đồng ý riêng trước khi bật sao lưu Google Drive (`consents.kind = 'drive'`).
class DriveConsentScreen extends StatefulWidget {
  const DriveConsentScreen({super.key});

  @override
  State<DriveConsentScreen> createState() => _DriveConsentScreenState();
}

class _DriveConsentScreenState extends State<DriveConsentScreen> {
  bool _agreed = false;
  bool _busy = false;
  String? _errorText;

  Future<void> _continue() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _errorText = null;
    });
    final state = AppScope.of(context);
    try {
      final auth = await state.signInGoogleDrive();
      if (!mounted) return;
      switch (auth) {
        case GoogleAuthSignedIn():
          final saved = await state.grantDriveConsent(mvpConsentVersion);
          if (!mounted) return;
          if (!saved) {
            setState(() {
              _busy = false;
              _errorText = 'Chưa lưu được đồng ý. Thử lại.';
            });
            return;
          }
          await Navigator.of(context).pushReplacement(
            MaterialPageRoute<void>(builder: (_) => const CreateDriveBackupScreen()),
          );
        case GoogleAuthCancelled():
          setState(() => _busy = false);
        case GoogleAuthFailed(:final isNetworkError):
          setState(() {
            _busy = false;
            _errorText = isNetworkError
                ? 'Chưa kết nối được Google Drive. Kiểm tra mạng và thử lại.'
                : 'Không đăng nhập được Google Drive. Kiểm tra tài khoản Google hoặc thử lại.';
          });
      }
    } on Object {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _errorText = 'Chưa kết nối được Google Drive. Kiểm tra mạng và thử lại.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Sao lưu Google Drive')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Dữ liệu trên máy được mã hóa bằng mã do chỉ bạn giữ trước khi tải lên thư mục ẩn của app trên Google Drive.',
          ),
          const SizedBox(height: 12),
          const Text('• App chỉ truy cập thư mục ẩn riêng, không đọc tệp khác trên Drive của bạn.'),
          const SizedBox(height: 6),
          const Text('• Google và WholeWell không đọc được nội dung nếu không có mã khôi phục.'),
          const SizedBox(height: 6),
          const Text('• Bạn có thể tắt và xóa bản sao lưu bất cứ lúc nào trong Quyền riêng tư.'),
          const SizedBox(height: 16),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            value: _agreed,
            onChanged: _busy ? null : (v) => setState(() => _agreed = v ?? false),
            title: const Text('Tôi hiểu và đồng ý bật sao lưu qua Google Drive.'),
          ),
          if (_errorText != null) ...[
            const SizedBox(height: 8),
            Text(_errorText!, style: TextStyle(color: cs.error)),
          ],
          const SizedBox(height: 20),
          FilledButton(
            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
            onPressed: _agreed && !_busy ? _continue : null,
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
                      Text('Đang kết nối Google...'),
                    ],
                  )
                : const Text('Tiếp tục với Google'),
          ),
        ],
      ),
    );
  }
}

/// Màn Tạo bản sao lưu mã hóa và tải lên Google Drive `appDataFolder`.
class CreateDriveBackupScreen extends StatelessWidget {
  final int memoryKiB;
  final int iterations;

  const CreateDriveBackupScreen({
    super.key,
    this.memoryKiB = BackupCodec.defaultMemoryKiB,
    this.iterations = BackupCodec.defaultIterations,
  });

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final email = state.driveAccount?.email;
    final notice = [
      if (email != null) 'Tài khoản: $email',
      'Giữ tối đa 3 bản gần nhất trên Drive. Khóa bản sao lưu chỉ bạn giữ; quên mã sẽ không mở lại được.',
    ].join('\n');

    return Scaffold(
      appBar: AppBar(title: const Text('Sao lưu lên Google Drive')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          BackupSecretSection(
            noticeText: notice,
            primaryLabel: 'Tải bản sao lưu lên',
            busyLabel: 'Đang mã hóa và tải lên Drive...',
            onSubmit: (secret) async {
              try {
                await state.createDriveBackup(
                  secret: secret,
                  memoryKiB: memoryKiB,
                  iterations: iterations,
                );
              } on Object {
                throw const BackupSubmitException(
                  'Chưa tải được bản sao lưu lên Google Drive. Kiểm tra mạng và thử lại.',
                );
              }
              if (!context.mounted) return;
              AppFeedback.showSnack(context, 'Đã sao lưu lên Google Drive.');
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }
}

/// Màn Khôi phục từ Google Drive (không hỏi màn đồng ý bật Drive).
class RestoreDriveBackupScreen extends StatefulWidget {
  final bool hasExistingData;

  const RestoreDriveBackupScreen({super.key, required this.hasExistingData});

  @override
  State<RestoreDriveBackupScreen> createState() => _RestoreDriveBackupScreenState();
}

class _RestoreDriveBackupScreenState extends State<RestoreDriveBackupScreen> {
  List<CloudBackupInfo>? _backups;
  String? _selectedId;
  final _secretCtl = TextEditingController();
  bool _obscure = true;
  bool _loadingList = false;
  bool _busy = false;
  String? _errorText;
  bool _inited = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_inited) return;
    _inited = true;
    final state = AppScope.of(context);
    if (state.driveAccount != null) {
      unawaited(_loadBackups());
    }
  }

  @override
  void dispose() {
    _secretCtl.dispose();
    super.dispose();
  }

  Future<void> _signInAndLoad({bool switchAccount = false}) async {
    if (_loadingList || _busy) return;
    setState(() {
      _loadingList = true;
      _errorText = null;
    });
    final state = AppScope.of(context);
    try {
      final auth = switchAccount
          ? await state.switchGoogleDriveAccount()
          : await state.signInGoogleDrive();
      if (!mounted) return;
      switch (auth) {
        case GoogleAuthSignedIn():
          await _loadBackups();
        case GoogleAuthCancelled():
          setState(() => _loadingList = false);
        case GoogleAuthFailed():
          setState(() {
            _loadingList = false;
            _errorText = 'Chưa kết nối được Google Drive. Kiểm tra mạng và thử lại.';
          });
      }
    } on Object {
      if (!mounted) return;
      setState(() {
        _loadingList = false;
        _errorText = 'Chưa kết nối được Google Drive. Kiểm tra mạng và thử lại.';
      });
    }
  }

  Future<void> _loadBackups() async {
    setState(() {
      _loadingList = true;
      _errorText = null;
    });
    try {
      final list = await AppScope.of(context).listDriveBackups();
      if (!mounted) return;
      setState(() {
        _backups = list;
        _selectedId = list.isEmpty ? null : list.first.id;
        _loadingList = false;
      });
    } on Object {
      if (!mounted) return;
      setState(() {
        _loadingList = false;
        _errorText = 'Chưa kết nối được Google Drive. Kiểm tra mạng và thử lại.';
      });
    }
  }

  Future<void> _restore() async {
    if (_busy) return;
    final id = _selectedId;
    if (id == null || _secretCtl.text.trim().isEmpty) return;

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
    try {
      final res = await AppScope.of(context).restoreFromGoogleDrive(
        backupId: id,
        secret: _secretCtl.text.trim(),
      );
      if (!mounted) return;
      if (res is RestoreSucceeded) {
        AppFeedback.showSnack(context, 'Đã khôi phục dữ liệu.');
        Navigator.of(context).popUntil((r) => r.isFirst);
      } else {
        setState(() {
          _busy = false;
          _errorText = restoreOutcomeMessage(res);
        });
      }
    } on Object {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _errorText = 'Chưa kết nối được Google Drive. Kiểm tra mạng và thử lại.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final acc = state.driveAccount;
    final cs = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    final backups = _backups;
    final canRestore =
        !_busy && !_loadingList && acc != null && _selectedId != null && _secretCtl.text.trim().isNotEmpty;

    return Scaffold(
      appBar: AppBar(title: const Text('Khôi phục từ Google Drive')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (acc == null) ...[
            const Text('Đăng nhập tài khoản Google đã dùng để sao lưu dữ liệu.'),
            const SizedBox(height: 16),
            FilledButton.icon(
              style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
              onPressed: _loadingList ? null : _signInAndLoad,
              icon: const Icon(LucideIcons.logIn),
              label: const Text('Đăng nhập Google'),
            ),
          ] else ...[
            Row(
              children: [
                Expanded(child: Text('Tài khoản: ${acc.email}', style: t.bodyMedium)),
                TextButton(
                  onPressed: _busy || _loadingList ? null : () => _signInAndLoad(switchAccount: true),
                  child: const Text('Đổi tài khoản'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_loadingList)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
                child: Column(
                  children: [
                    LoadingSkeletonBox(height: 52),
                    SizedBox(height: AppSpacing.sm),
                    LoadingSkeletonBox(height: 52),
                  ],
                ),
              )
            else if (backups == null || backups.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text('Chưa có bản sao lưu nào trên tài khoản Google này.'),
              )
            else ...[
              Text('Chọn bản sao lưu', style: t.titleSmall),
              const SizedBox(height: 6),
              for (final b in backups)
                BackupRadioRow(
                  label:
                      '${fmtBackupDateTime(b.modifiedAt)} (${(b.sizeBytes / 1024).ceil()} KB)',
                  selected: _selectedId == b.id,
                  enabled: !_busy,
                  onTap: () => setState(() {
                    _selectedId = b.id;
                    _errorText = null;
                  }),
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
            ],
          ],
          if (_errorText != null) ...[
            const SizedBox(height: 12),
            Text(_errorText!, style: TextStyle(color: cs.error)),
          ],
          if (acc != null && backups != null && backups.isNotEmpty) ...[
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
                        Text('Đang tải và giải mã...'),
                      ],
                    )
                  : const Text('Khôi phục'),
            ),
          ],
        ],
      ),
    );
  }
}
