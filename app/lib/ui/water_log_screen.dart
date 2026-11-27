import 'package:journal_db/journal_db.dart';
import 'package:material_ui/material_ui.dart';

import '../state/app_scope.dart';
import 'common/common_widgets.dart';
import 'labels.dart';

/// Ghi nước mới hoặc sửa/xóa một lần uống nước đã ghi.
class WaterLogScreen extends StatefulWidget {
  final WaterRecord? editing;
  const WaterLogScreen({super.key, this.editing});

  @override
  State<WaterLogScreen> createState() => _WaterLogScreenState();
}

class _WaterLogScreenState extends State<WaterLogScreen> {
  static const _quickPresets = [150.0, 250.0, 500.0];

  final _customCtl = TextEditingController();
  double? _presetMl;
  late DateTime _at;
  bool _inited = false;
  bool _saving = false;
  String? _errorText;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_inited) return;
    _inited = true;
    final diary = AppScope.of(context).diary;
    final e = widget.editing;
    final initialMl = e?.ml ?? diary.lastWaterMl;
    _at = e?.at ?? diary.defaultWaterAt();
    if (_quickPresets.any((p) => (p - initialMl).abs() < 0.01)) {
      _presetMl = _quickPresets.firstWhere((p) => (p - initialMl).abs() < 0.01);
    } else {
      _presetMl = null;
      _customCtl.text = _plainNumber(initialMl);
    }
  }

  @override
  void dispose() {
    _customCtl.dispose();
    super.dispose();
  }

  static String _plainNumber(double v) => (v - v.roundToDouble()).abs() < 0.05
      ? '${v.round()}'
      : v.toString().replaceAll('.', ',');

  double? _parsedMl() {
    if (_presetMl != null) return _presetMl;
    final raw = _customCtl.text.trim().replaceAll(',', '.');
    if (raw.isEmpty) return null;
    return double.tryParse(raw);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_at),
    );
    if (picked != null && mounted) {
      setState(() => _at =
          DateTime(_at.year, _at.month, _at.day, picked.hour, picked.minute));
    }
  }

  Future<void> _save() async {
    if (_saving) return;
    final ml = _parsedMl();
    if (ml == null || !ml.isFinite || ml <= 0 || ml > 5000) {
      setState(() => _errorText = 'Nhập lượng nước từ 1 đến 5.000 ml.');
      return;
    }
    setState(() {
      _errorText = null;
      _saving = true;
    });
    final state = AppScope.of(context);
    final diary = state.diary;
    final e = widget.editing;
    try {
      if (e == null) {
        final id = await diary.addWater(_at, ml);
        if (!mounted || id == null) return;
        final nav = Navigator.of(context);
        showUndoWaterSnack(context,
            ml: ml, onUndo: () => diary.deleteWater(id));
        nav.pop();
      } else {
        final ok = await diary.updateWater(e.id, at: _at, ml: ml);
        if (mounted && ok) Navigator.of(context).pop();
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _delete() async {
    if (_saving) return;
    final e = widget.editing;
    if (e == null) return;
    final confirm = await showConfirmDialog(
      context,
      message: 'Xóa lần uống ${fmtWaterMl(e.ml)} ml khỏi nhật ký?',
      confirmLabel: 'Xóa',
      destructive: true,
    );
    if (!confirm || !mounted) return;
    setState(() => _saving = true);
    try {
      final ok = await AppScope.of(context).diary.deleteWater(e.id);
      if (mounted && ok) Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final diary = AppScope.of(context).diary;
    final cs = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    final isEditing = widget.editing != null;

    return Scaffold(
      appBar: AppBar(title: Text(isEditing ? 'Sửa lần uống nước' : 'Ghi nước')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (!isEditing && !diary.isViewingToday) ...[
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                'Đang ghi cho ${diary.day.day}/${diary.day.month}',
                style: t.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
          ],
          Text('Chọn nhanh', style: t.titleSmall),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final preset in _quickPresets)
                ChoiceChip(
                  label: Text('${preset.round()} ml'),
                  selected: _presetMl == preset,
                  materialTapTargetSize: MaterialTapTargetSize.padded,
                  onSelected: _saving
                      ? null
                      : (_) => setState(() {
                            _presetMl = preset;
                            _customCtl.clear();
                            _errorText = null;
                          }),
                ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _customCtl,
            enabled: !_saving,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: 'Số khác',
              suffixText: 'ml',
              border: const OutlineInputBorder(),
              errorText: _errorText,
            ),
            onChanged: (v) {
              setState(() {
                if (v.trim().isNotEmpty) _presetMl = null;
                _errorText = null;
              });
            },
          ),
          const SizedBox(height: 12),
          ListTile(
            minTileHeight: 56,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: BorderSide(color: cs.outlineVariant),
            ),
            leading: const Icon(Icons.access_time),
            title: const Text('Giờ'),
            trailing: Text(fmtTime24(_at), style: t.titleMedium),
            onTap: _saving ? null : _pickTime,
          ),
          const SizedBox(height: 24),
          FilledButton(
            style:
                FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Lưu'),
          ),
          if (isEditing) ...[
            const SizedBox(height: 12),
            TextButton(
              style: TextButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
                foregroundColor: cs.error,
              ),
              onPressed: _saving ? null : _delete,
              child: const Text('Xóa khỏi nhật ký'),
            ),
          ],
        ],
      ),
    );
  }
}
