import 'package:material_ui/material_ui.dart';
import 'package:health_engine/health_engine.dart';

import '../state/app_scope.dart';
import 'labels.dart';

class ProfileScreen extends StatefulWidget {
  final bool firstRun;
  const ProfileScreen({super.key, this.firstRun = false});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _form = GlobalKey<FormState>();
  final _age = TextEditingController();
  final _height = TextEditingController();
  final _weight = TextEditingController();
  final _week = TextEditingController();
  final _months = TextEditingController();
  Sex _sex = Sex.female;
  LifeStage _stage = LifeStage.none;
  BmiClass? _bmi;
  ActivityLevel _level = ActivityLevel.inactive;
  bool _loaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_loaded) return;
    _loaded = true;
    final p = AppScope.of(context).profile;
    if (p != null) {
      _age.text = '${p.ageYears}';
      _height.text = fmt(p.heightCm);
      _weight.text = fmt(p.weightKg);
      _sex = p.sex;
      _stage = p.stage;
      _bmi = p.prePregnancyBmi;
      _level = p.activityLevel;
      if (p.gestationWeek != null) _week.text = '${p.gestationWeek}';
      if (p.monthsPostpartum != null) _months.text = '${p.monthsPostpartum}';
    }
  }

  @override
  void dispose() {
    for (final c in [_age, _height, _weight, _week, _months]) {
      c.dispose();
    }
    super.dispose();
  }

  double? _d(TextEditingController c) => double.tryParse(c.text.trim().replaceAll(',', '.'));

  String? _range(String? s, double min, double max, String what) {
    final v = double.tryParse((s ?? '').trim().replaceAll(',', '.'));
    if (v == null || v < min || v > max) return '$what từ ${fmt(min)} đến ${fmt(max)}';
    return null;
  }

  void _save() {
    if (!_form.currentState!.validate()) return;
    AppScope.of(context).saveProfile(Profile(
      ageYears: int.parse(_age.text.trim()),
      sex: _sex,
      heightCm: _d(_height)!,
      weightKg: _d(_weight)!,
      stage: _sex == Sex.female ? _stage : LifeStage.none,
      gestationWeek: _stage == LifeStage.pregnant ? int.tryParse(_week.text.trim()) : null,
      prePregnancyBmi: _stage == LifeStage.pregnant ? _bmi : null,
      monthsPostpartum: _stage == LifeStage.lactating ? int.tryParse(_months.text.trim()) : null,
      activityLevel: _level,
    ));
    if (!widget.firstRun) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã lưu hồ sơ.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final suggested = state.profile == null ? null : state.suggestedLevel();
    final minAge = state.pack.minProfileAge;
    final body = Form(
      key: _form,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (widget.firstRun)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Text('Dữ liệu chỉ lưu trên máy này. App dành cho người từ $minAge tuổi, '
                  'chỉ để tham khảo, không chẩn đoán hay kê đơn.'),
            ),
          TextFormField(
            controller: _age,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Tuổi'),
            validator: (s) {
              final v = int.tryParse((s ?? '').trim());
              if (v == null || v < minAge || v > 110) return 'Tuổi từ $minAge đến 110';
              return null;
            },
          ),
          const SizedBox(height: 12),
          SegmentedButton<Sex>(
            segments: const [
              ButtonSegment(value: Sex.female, label: Text('Nữ')),
              ButtonSegment(value: Sex.male, label: Text('Nam')),
            ],
            selected: {_sex},
            onSelectionChanged: (s) => setState(() => _sex = s.first),
          ),
          TextFormField(
            controller: _height,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(labelText: 'Chiều cao (cm)'),
            validator: (s) => _range(s, 120, 230, 'Chiều cao'),
          ),
          TextFormField(
            controller: _weight,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(labelText: 'Cân nặng (kg)'),
            validator: (s) => _range(s, 30, 250, 'Cân nặng'),
          ),
          if (_sex == Sex.female) ...[
            const SizedBox(height: 12),
            DropdownButtonFormField<LifeStage>(
              key: ValueKey(_stage),
              initialValue: _stage,
              decoration: const InputDecoration(labelText: 'Mang thai hoặc cho con bú'),
              items: [
                for (final s in LifeStage.values) DropdownMenuItem(value: s, child: Text(stageLabel(s))),
              ],
              onChanged: (s) => setState(() => _stage = s!),
            ),
            if (_stage == LifeStage.pregnant) ...[
              TextFormField(
                controller: _week,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Tuần thai'),
                validator: (s) => _range(s, 1, 42, 'Tuần thai'),
              ),
              DropdownButtonFormField<BmiClass>(
                key: ValueKey(_bmi),
                initialValue: _bmi,
                decoration: const InputDecoration(labelText: 'Cân nặng trước khi mang thai'),
                items: [
                  for (final b in BmiClass.values) DropdownMenuItem(value: b, child: Text(bmiLabel(b))),
                ],
                onChanged: (b) => setState(() => _bmi = b),
              ),
            ],
            if (_stage == LifeStage.lactating)
              TextFormField(
                controller: _months,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Số tháng sau sinh'),
                validator: (s) => _range(s, 0, 36, 'Số tháng'),
              ),
          ],
          const SizedBox(height: 12),
          DropdownButtonFormField<ActivityLevel>(
            key: ValueKey(_level),
            initialValue: _level,
            decoration: const InputDecoration(labelText: 'Mức vận động thường ngày'),
            items: [
              for (final l in ActivityLevel.values) DropdownMenuItem(value: l, child: Text(levelLabel(l))),
            ],
            onChanged: (l) => setState(() => _level = l!),
          ),
          if (suggested != null && suggested != _level)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(children: [
                Expanded(child: Text('Theo buổi tập 7 ngày qua, gợi ý: ${levelLabel(suggested)}.')),
                TextButton(onPressed: () => setState(() => _level = suggested), child: const Text('Dùng')),
              ]),
            ),
          if (!widget.firstRun) ...[
            const Divider(height: 32),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Ẩn số calo'),
              subtitle: const Text('Không hiện calo ở mọi màn hình'),
              value: state.hideCalories,
              onChanged: state.setHideCalories,
            ),
          ],
          const SizedBox(height: 16),
          FilledButton(onPressed: _save, child: Text(widget.firstRun ? 'Bắt đầu' : 'Lưu hồ sơ')),
        ],
      ),
    );
    return widget.firstRun ? Scaffold(appBar: AppBar(title: const Text('Hồ sơ')), body: body) : body;
  }
}
