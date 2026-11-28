/// Màn Giờ trong ngày (`Tôi -> Giờ trong ngày` hoặc bước xác nhận lần đầu khi Đặt lịch).
library;

import 'package:journal_db/models.dart';
import 'package:material_ui/material_ui.dart';

import '../state/app_scope.dart';
import 'common/common_widgets.dart';

String formatMinutesHhMm(int minutes) {
  final m = ((minutes % 1440) + 1440) % 1440;
  final h = (m ~/ 60).toString().padLeft(2, '0');
  final mm = (m % 60).toString().padLeft(2, '0');
  return '$h:$mm';
}

class DayTimesScreen extends StatefulWidget {
  final bool onboardingFlow;
  const DayTimesScreen({super.key, this.onboardingFlow = false});

  @override
  State<DayTimesScreen> createState() => _DayTimesScreenState();
}

class _DayTimesScreenState extends State<DayTimesScreen> {
  late DayTimesSettings _settings;
  bool _inited = false;
  bool _saving = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_inited) {
      _settings = AppScope.of(context).diary.dayTimesSettings;
      _inited = true;
    }
  }

  Future<void> _pickTime(int current, ValueChanged<int> onPicked) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: current ~/ 60, minute: current % 60),
    );
    if (picked != null && mounted) {
      setState(() => onPicked(picked.hour * 60 + picked.minute));
    }
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);
    final bool ok;
    try {
      ok = await AppScope.of(context).diary.saveDayTimesSettings(_settings.copyWith(dayTimesConfirmed: true));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
    if (!mounted) return;
    if (ok) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final allMealsOff = !_settings.hasBreakfast && !_settings.hasLunch && !_settings.hasDinner;
    return Scaffold(
      appBar: AppBar(title: const Text('Giờ trong ngày')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Dùng để tự chọn bữa ăn và gợi ý xếp lịch vitamin D, canxi.'),
          const SizedBox(height: 12),
          _timeRow('Thức dậy', _settings.wake, (v) => _settings = _settings.copyWith(wake: v)),
          _mealRow(
            label: 'Bữa sáng',
            enabled: _settings.hasBreakfast,
            mins: _settings.breakfast,
            onToggle: (v) => setState(() => _settings = _settings.copyWith(hasBreakfast: v)),
            onPicked: (v) => _settings = _settings.copyWith(breakfast: v),
          ),
          _mealRow(
            label: 'Bữa trưa',
            enabled: _settings.hasLunch,
            mins: _settings.lunch,
            onToggle: (v) => setState(() => _settings = _settings.copyWith(hasLunch: v)),
            onPicked: (v) => _settings = _settings.copyWith(lunch: v),
          ),
          _mealRow(
            label: 'Bữa tối',
            enabled: _settings.hasDinner,
            mins: _settings.dinner,
            onToggle: (v) => setState(() => _settings = _settings.copyWith(hasDinner: v)),
            onPicked: (v) => _settings = _settings.copyWith(dinner: v),
          ),
          _timeRow('Đi ngủ', _settings.sleep, (v) => _settings = _settings.copyWith(sleep: v)),
          if (allMealsOff) ...[
            const SizedBox(height: 12),
            const SafetyNote(message: 'Đã tắt hết bữa chính — món mới mặc định vào Phụ.'),
          ],
          const SizedBox(height: 20),
          FilledButton(
            onPressed: _saving ? null : _save,
            child: Text(widget.onboardingFlow ? 'Xác nhận và tiếp tục' : 'Lưu'),
          ),
        ],
      ),
    );
  }

  Widget _mealRow({
    required String label,
    required bool enabled,
    required int mins,
    required ValueChanged<bool> onToggle,
    required ValueChanged<int> onPicked,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(label, style: Theme.of(context).textTheme.bodyLarge)),
          if (enabled) ...[
            OutlinedButton(onPressed: () => _pickTime(mins, onPicked), child: Text(formatMinutesHhMm(mins))),
            const SizedBox(width: 8),
          ],
          Switch(value: enabled, onChanged: _saving ? null : onToggle),
        ],
      ),
    );
  }

  Widget _timeRow(String label, int mins, ValueChanged<int> onChanged) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(label),
      trailing: OutlinedButton(onPressed: () => _pickTime(mins, onChanged), child: Text(formatMinutesHhMm(mins))),
    );
  }
}
