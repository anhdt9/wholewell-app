import 'package:health_engine/health_engine.dart';
import 'package:journal_db/journal_db.dart';
import 'package:material_ui/material_ui.dart';

import '../state/app_scope.dart';
import 'labels.dart';

class AddWorkoutScreen extends StatefulWidget {
  final WorkoutRecord? editing;
  const AddWorkoutScreen({super.key, this.editing});
  @override
  State<AddWorkoutScreen> createState() => _AddWorkoutScreenState();
}

class _AddWorkoutScreenState extends State<AddWorkoutScreen> {
  String? _code;
  final _minutes = TextEditingController(text: '30');
  String _query = '';
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final e = widget.editing;
    if (e != null) {
      _code = e.workout.activityCode;
      _minutes.text = fmt(e.workout.minutes);
    }
  }

  @override
  void dispose() {
    _minutes.dispose();
    super.dispose();
  }

  Future<void> _save(Activity selected, double minutes) async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      final state = AppScope.of(context);
      final e = widget.editing;
      final entry = WorkoutEntry(activityCode: selected.code, minutes: minutes);
      if (e != null) {
        await state.diary.updateWorkout(e.id, e.startAt, entry);
      } else {
        await state.addWorkout(entry);
      }
      if (!mounted) return;
      Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _delete() async {
    final e = widget.editing;
    if (e == null || _saving) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xóa buổi tập?'),
        content: const Text('Buổi tập này sẽ bị xóa khỏi nhật ký.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Hủy')),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
              foregroundColor: Theme.of(ctx).colorScheme.onError,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    setState(() => _saving = true);
    try {
      await AppScope.of(context).diary.deleteWorkout(e.id);
      if (!mounted) return;
      Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final acts = state.pack.activities.values
        .where((a) => a.nameVi.toLowerCase().contains(_query.toLowerCase()))
        .toList();
    final rawMinutes = double.tryParse(_minutes.text.trim().replaceAll(',', '.'));
    final minutes = (rawMinutes != null && rawMinutes.isFinite) ? rawMinutes : 0.0;
    final selected = _code == null ? null : state.pack.activities[_code!];
    final kcal = selected == null
        ? null
        : workoutKcal(state.pack, state.profile!, WorkoutEntry(activityCode: selected.code, minutes: minutes));

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.editing != null ? 'Sửa buổi tập' : 'Thêm buổi tập'),
        actions: [
          if (widget.editing != null)
            IconButton(
              tooltip: 'Xóa khỏi nhật ký',
              icon: Icon(Icons.delete_outline, color: Theme.of(context).colorScheme.error),
              onPressed: _saving ? null : _delete,
            ),
          TextButton(
            onPressed: _saving || selected == null || minutes <= 0
                ? null
                : () => _save(selected, minutes),
            child: const Text('Lưu'),
          ),
        ],
      ),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(children: [
            Expanded(
              child: TextField(
                decoration: const InputDecoration(labelText: 'Tìm hoạt động', prefixIcon: Icon(Icons.search)),
                onChanged: (s) => setState(() => _query = s),
              ),
            ),
            const SizedBox(width: 12),
            SizedBox(
              width: 90,
              child: TextField(
                controller: _minutes,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Phút'),
                onChanged: (_) => setState(() {}),
              ),
            ),
          ]),
        ),
        if (selected != null && !state.hideCalories)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text('${selected.nameVi}: MET ${fmt(selected.met)}, khoảng ${kcal!.round()} kcal'),
          ),
        Expanded(
          child: RadioGroup<String>(
            groupValue: _code,
            onChanged: (v) => setState(() => _code = v),
            child: ListView(children: [
              for (final a in acts)
                RadioListTile<String>(
                  value: a.code,
                  title: Text(a.nameVi),
                  subtitle: Text('MET ${fmt(a.met)}'),
                ),
            ]),
          ),
        ),
      ]),
    );
  }
}
