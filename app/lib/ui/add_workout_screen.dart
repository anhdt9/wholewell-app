import 'package:flutter/material.dart';
import 'package:health_engine/health_engine.dart';

import '../state/app_scope.dart';
import 'labels.dart';

class AddWorkoutScreen extends StatefulWidget {
  const AddWorkoutScreen({super.key});
  @override
  State<AddWorkoutScreen> createState() => _AddWorkoutScreenState();
}

class _AddWorkoutScreenState extends State<AddWorkoutScreen> {
  String? _code;
  final _minutes = TextEditingController(text: '30');
  String _query = '';

  @override
  void dispose() {
    _minutes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final acts = state.pack.activities.values
        .where((a) => a.nameVi.toLowerCase().contains(_query.toLowerCase()))
        .toList();
    final minutes = double.tryParse(_minutes.text.replaceAll(',', '.')) ?? 0;
    final selected = _code == null ? null : state.pack.activities[_code!];
    final kcal = selected == null
        ? null
        : workoutKcal(state.pack, state.profile!, WorkoutEntry(activityCode: selected.code, minutes: minutes));

    return Scaffold(
      appBar: AppBar(title: const Text('Thêm buổi tập'), actions: [
        TextButton(
          onPressed: selected == null || minutes <= 0
              ? null
              : () {
                  state.addWorkout(WorkoutEntry(activityCode: selected.code, minutes: minutes));
                  Navigator.of(context).pop();
                },
          child: const Text('Lưu'),
        ),
      ]),
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
          child: ListView(children: [
            for (final a in acts)
              RadioListTile<String>(
                value: a.code,
                groupValue: _code,
                onChanged: (v) => setState(() => _code = v),
                title: Text(a.nameVi),
                subtitle: Text('MET ${fmt(a.met)}'),
              ),
          ]),
        ),
      ]),
    );
  }
}
