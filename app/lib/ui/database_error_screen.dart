import 'package:material_ui/material_ui.dart';

import '../data/open_database.dart';

/// Không mở được dữ liệu. App không tự xóa gì; xóa chỉ khi người dùng xác nhận hai lần.
class DatabaseErrorScreen extends StatelessWidget {
  final DatabaseOpenFailure failure;
  final VoidCallback onRetry;
  final Future<void> Function() onReset;

  const DatabaseErrorScreen({
    super.key,
    required this.failure,
    required this.onRetry,
    required this.onReset,
  });

  String get _message => switch (failure) {
        DatabaseOpenFailure.cipherUnavailable =>
          'Không mở được kho dữ liệu an toàn trên máy này, nên app không lưu gì để tránh lộ dữ liệu.',
        DatabaseOpenFailure.keyStoreUnavailable =>
          'Không đọc được khóa bảo mật của máy. Hãy thử lại; nếu vẫn lỗi, hãy khởi động lại máy.',
        DatabaseOpenFailure.keyMissing =>
          'Khóa mở dữ liệu trên máy không còn (thường do cài lại app hoặc xóa dữ liệu bảo mật). '
              'Dữ liệu cũ vẫn nằm trên máy nhưng không mở được.',
        DatabaseOpenFailure.wrongKeyOrCorrupt =>
          'Không mở được dữ liệu: khóa không khớp hoặc tệp dữ liệu bị hỏng. Dữ liệu cũ vẫn nằm trên máy.',
      };

  bool get _canReset =>
      failure == DatabaseOpenFailure.keyMissing || failure == DatabaseOpenFailure.wrongKeyOrCorrupt;

  Future<void> _confirmReset(BuildContext context) async {
    Future<bool> ask(String title, String body, String ok) async =>
        await showDialog<bool>(
          context: context,
          builder: (c) => AlertDialog(
            title: Text(title),
            content: Text(body),
            actions: [
              TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Hủy')),
              FilledButton(onPressed: () => Navigator.pop(c, true), child: Text(ok)),
            ],
          ),
        ) ??
        false;

    if (!await ask('Xóa dữ liệu?', 'Toàn bộ hồ sơ và nhật ký trên máy sẽ bị xóa.', 'Tiếp tục')) return;
    if (!context.mounted) return;
    if (!await ask('Chắc chắn xóa?', 'Không lấy lại được sau khi xóa.', 'Xóa và bắt đầu lại')) return;
    await onReset();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Không mở được dữ liệu')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(_message),
            const SizedBox(height: 24),
            if (failure != DatabaseOpenFailure.cipherUnavailable)
              FilledButton(onPressed: onRetry, child: const Text('Thử lại')),
            if (_canReset) ...[
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () => _confirmReset(context),
                child: const Text('Xóa dữ liệu và bắt đầu lại'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
