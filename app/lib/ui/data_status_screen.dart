import 'package:material_ui/material_ui.dart';

import '../state/app_scope.dart';
import '../state/app_state.dart';
import 'drive_backup_screens.dart';

/// Màn chặn khi CSDL chưa mở được (thiết kế tổng thể, mục Trạng thái, dòng "Toàn app").
class DataStatusScreen extends StatelessWidget {
  final DataStatus status;
  const DataStatusScreen({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final restore = FilledButton.tonal(
      onPressed: state.canRestoreFromFile
          ? () => showRestoreSourcePicker(context, hasExistingData: false)
          : null,
      child: const Text('Khôi phục từ bản sao lưu'),
    );
    final retry = FilledButton(onPressed: state.start, child: const Text('Thử lại'));
    final (String text, List<Widget> actions) = switch (status) {
      DataStatus.waitingForUnlock => ('Mở khóa máy để xem dữ liệu.', const <Widget>[]),
      DataStatus.keyStuck => ('Chưa đọc được khóa dữ liệu trên máy này.', [retry, restore]),
      DataStatus.cannotOpen => (
          'Không mở được dữ liệu đã lưu trên máy.',
          [
            restore,
            OutlinedButton(onPressed: () => _confirmStartOver(context, state), child: const Text('Bắt đầu lại')),
          ]
        ),
      DataStatus.installBroken => (
          'Không mở được dữ liệu đã lưu trên máy. Hãy cài lại WholeWell từ cửa hàng ứng dụng.',
          const <Widget>[]
        ),
      DataStatus.needsUpdate => (
          'Cần cập nhật WholeWell. Dữ liệu của bạn vẫn còn nguyên trên máy. '
              'Hãy cập nhật app từ cửa hàng ứng dụng.',
          const <Widget>[]
        ),
      DataStatus.lowStorage => ('Máy không còn đủ dung lượng. Hãy giải phóng bộ nhớ rồi mở lại.', [retry]),
      DataStatus.unsupportedPlatform => ('Bản này chưa chạy được trên thiết bị của bạn.', const <Widget>[]),
      _ => ('', const <Widget>[]),
    };
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: status == DataStatus.loading
                ? const CircularProgressIndicator()
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(text, style: Theme.of(context).textTheme.titleMedium, textAlign: TextAlign.center),
                      for (final a in actions) ...[const SizedBox(height: 12), a],
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  /// "Bắt đầu lại" hỏi lại và phải gõ XÓA vì dữ liệu cũ bị xóa.
  Future<void> _confirmStartOver(BuildContext context, AppState state) async {
    final c = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('Bắt đầu lại?'),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            const Text('Dữ liệu cũ trên máy sẽ bị xóa. Gõ XÓA để xác nhận.'),
            TextField(controller: c, autofocus: true, onChanged: (_) => setState(() {})),
          ]),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
            TextButton(
              onPressed: c.text.trim() == 'XÓA' ? () => Navigator.pop(ctx, true) : null,
              child: const Text('Bắt đầu lại'),
            ),
          ],
        ),
      ),
    );
    c.dispose();
    if (ok == true) await state.startOver();
  }
}
