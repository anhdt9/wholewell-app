/// Màn Đặt lịch uống & Bảng cảnh báo giới hạn theo lịch.
library;

import 'package:health_engine/health_engine.dart';
import 'package:journal_db/models.dart';
import 'package:material_ui/material_ui.dart';

import '../state/app_scope.dart';
import '../state/app_state.dart';
import 'common/common_widgets.dart';
import 'day_times_screen.dart';
import 'labels.dart';
import 'notification_settings_screen.dart';

class EditScheduleScreen extends StatefulWidget {
  final Product product;
  final Schedule? existingSchedule;

  const EditScheduleScreen({super.key, required this.product, this.existingSchedule});

  @override
  State<EditScheduleScreen> createState() => _EditScheduleScreenState();
}

class _EditScheduleScreenState extends State<EditScheduleScreen> {
  late int _timeOfDay;
  late TextEditingController _servingsCtrl;
  String? _error;
  bool _saving = false;
  bool _inited = false;

  bool get _isEdit => widget.existingSchedule != null;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_inited) {
      final ex = widget.existingSchedule;
      final settings = AppScope.of(context).diary.dayTimesSettings;
      _timeOfDay = ex?.timeOfDay ?? _defaultScheduleTime(settings);
      _servingsCtrl = TextEditingController(text: fmt(ex?.servings ?? 1.0));
      _inited = true;
    }
  }

  static int _defaultScheduleTime(DayTimesSettings s) {
    if (s.hasBreakfast) return s.breakfast;
    if (s.hasLunch) return s.lunch;
    if (s.hasDinner) return s.dinner;
    final now = DateTime.now();
    return now.hour * 60 + now.minute;
  }

  @override
  void dispose() {
    _servingsCtrl.dispose();
    super.dispose();
  }

  double? get _parsedServings {
    final v = double.tryParse(_servingsCtrl.text.trim().replaceAll(',', '.'));
    if (v == null || !v.isFinite || v <= 0) return null;
    return v;
  }

  List<Schedule> _previewSchedules(DiaryController diary) {
    final s = _parsedServings ?? 1.0;
    final list = <Schedule>[];
    final ex = widget.existingSchedule;
    for (final cur in diary.actualTodaySchedules) {
      if (ex != null && cur.id == ex.id) continue;
      list.add(cur);
    }
    list.add(Schedule(ex?.id ?? -1, widget.product.id, _timeOfDay, s, dayKey(DateTime.now()), null));
    return list;
  }

  Future<bool?> _showScheduleUlWarningDialog(
    BuildContext context,
    AppState state,
    List<UlFlag> flags,
    List<Schedule> preview,
  ) {
    final t = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    final pack = state.pack;
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('⚠ Lịch này vượt giới hạn an toàn', style: t.titleMedium),
              if (state.caution) ...[const SizedBox(height: 8), const SafetyNote(message: cautionBannerMessage)],
              const SizedBox(height: 12),
              for (final f in flags) ...[
                SurfaceCard(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(14),
                  color: cs.errorContainer,
                  borderColor: cs.errorContainer,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${pack.nutrients[f.nutrientId]?.nameVi ?? f.nutrientId} theo lịch: '
                        '${fmt(f.amount)} ${unitLabel(pack.nutrients[f.nutrientId]?.unit ?? '')}/ngày',
                        style: t.titleSmall?.copyWith(color: cs.onErrorContainer, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Giới hạn: ${fmt(f.ul)}/ngày · Vượt: ${fmt(f.excess)} (${f.percentOver.round()}%)',
                        style: t.bodyMedium?.copyWith(color: cs.onErrorContainer),
                      ),
                      if (f.scope == UlScope.total) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Chưa tính thức ăn; thức ăn sẽ cộng thêm khi bạn ghi nhật ký.',
                          style: t.bodySmall?.copyWith(color: cs.onErrorContainer),
                        ),
                      ],
                      const SizedBox(height: 4),
                      Text(
                        'Hỏi bác sĩ hoặc dược sĩ nếu cần.',
                        style: t.bodySmall?.copyWith(color: cs.onErrorContainer),
                      ),
                    ],
                  ),
                ),
              ],
              Row(
                children: [
                  Expanded(
                    child: FilledButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Sửa lịch')),
                  ),
                  const SizedBox(width: 12),
                  TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Vẫn lưu')),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (_saving) return;
    final servings = _parsedServings;
    if (servings == null) {
      setState(() => _error = 'Số khẩu phần phải lớn hơn 0.');
      return;
    }
    setState(() {
      _error = null;
      _saving = true;
    });

    try {
      final state = AppScope.of(context);
      final diary = state.diary;
      final preview = _previewSchedules(diary);
      final ulFlags = diary.scheduledUlFlags(overrideSchedules: preview);
      if (ulFlags.isNotEmpty) {
        final keep = await _showScheduleUlWarningDialog(context, state, ulFlags, preview);
        if (!mounted || keep != true) return;
      }

      final todayStr = dayKey(DateTime.now());
      final ex = widget.existingSchedule;
      if (ex == null) {
        await diary.addSchedule(widget.product.id, _timeOfDay, servings, validFrom: todayStr);
      } else {
        await diary.updateSchedule(ex.id, timeOfDay: _timeOfDay, servings: servings, today: todayStr);
      }
      await state.syncNotifications();
      if (!mounted) return;

      if (!diary.notificationsEnabled) {
        await Navigator.of(context)
            .push(MaterialPageRoute<void>(builder: (_) => const NotificationSettingsScreen(firstSetupFlow: true)));
      }
      if (mounted) Navigator.of(context).pop(true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _delete() async {
    if (_saving) return;
    final ex = widget.existingSchedule;
    if (ex == null) return;
    final ok = await showConfirmDialog(
      context,
      title: 'Kết thúc lịch uống lúc ${formatMinutesHhMm(ex.timeOfDay)}?',
      message: 'Lịch sử đã uống trước đó vẫn được giữ.',
      confirmLabel: 'Xóa lịch',
    );
    if (!ok || !mounted) return;
    setState(() => _saving = true);
    try {
      final state = AppScope.of(context);
      await state.diary.endSchedule(ex.id, today: dayKey(DateTime.now()));
      await state.syncNotifications();
      if (mounted) Navigator.of(context).pop(true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final diary = state.diary;
    final settings = diary.dayTimesSettings;
    final preview = _previewSchedules(diary);
    final allNotices = diary.scheduleNotices(overrideSchedules: preview);
    final relevantNotices = [
      for (final n in allNotices)
        if (n.productIds.contains(widget.product.id)) n,
    ];
    final notices = [
      for (final n in relevantNotices)
        if (n.severity == 'notice') n,
    ];
    final suggestions = [
      for (final n in relevantNotices)
        if (n.severity == 'suggestion') n,
    ];

    return Scaffold(
      appBar: AppBar(title: Text('Đặt lịch: ${widget.product.name}')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Giờ uống'),
            trailing: OutlinedButton(
              onPressed: () async {
                final picked = await showTimePicker(
                  context: context,
                  initialTime: TimeOfDay(hour: _timeOfDay ~/ 60, minute: _timeOfDay % 60),
                );
                if (picked != null && mounted) {
                  setState(() => _timeOfDay = picked.hour * 60 + picked.minute);
                }
              },
              child: Text(formatMinutesHhMm(_timeOfDay)),
            ),
          ),
          if (settings.hasBreakfast || settings.hasLunch || settings.hasDinner)
            Wrap(
              spacing: 8,
              children: [
                if (settings.hasBreakfast)
                  ActionChip(
                    label: Text('Sáng ${formatMinutesHhMm(settings.breakfast)}'),
                    onPressed: () => setState(() => _timeOfDay = settings.breakfast),
                  ),
                if (settings.hasLunch)
                  ActionChip(
                    label: Text('Trưa ${formatMinutesHhMm(settings.lunch)}'),
                    onPressed: () => setState(() => _timeOfDay = settings.lunch),
                  ),
                if (settings.hasDinner)
                  ActionChip(
                    label: Text('Tối ${formatMinutesHhMm(settings.dinner)}'),
                    onPressed: () => setState(() => _timeOfDay = settings.dinner),
                  ),
              ],
            ),
          const SizedBox(height: 16),
          TextField(
            controller: _servingsCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              labelText: 'Số khẩu phần mỗi lần *',
              helperText:
                  '1 khẩu phần = ${fmt(widget.product.unitsPerServing)} ${countUnitLabel(widget.product.countUnit)}',
              errorText: _error,
            ),
          ),
          const SizedBox(height: 16),
          for (final n in notices) ...[SafetyNote(message: n.messageVi), const SizedBox(height: 8)],
          for (final s in suggestions) ...[SafetyNote(message: 'Gợi ý: ${s.messageVi}'), const SizedBox(height: 8)],
          const SizedBox(height: 12),
          FilledButton(onPressed: _saving ? null : _save, child: const Text('Lưu lịch')),
          if (_isEdit) ...[
            const SizedBox(height: 8),
            TextButton(onPressed: _saving ? null : _delete, child: const Text('Xóa lịch này')),
          ],
        ],
      ),
    );
  }
}
