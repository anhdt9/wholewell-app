import 'package:flutter/material.dart';
import 'package:health_engine/health_engine.dart';

import '../state/app_scope.dart';
import 'labels.dart';

/// Nhập tay một món: năng lượng, đạm/béo/bột đường, đường bổ sung, vi chất tùy chọn.
/// Bản sau sẽ thêm tra USDA FoodData Central và chụp nhãn (OCR).
class AddFoodScreen extends StatefulWidget {
  const AddFoodScreen({super.key});
  @override
  State<AddFoodScreen> createState() => _AddFoodScreenState();
}

class _AddFoodScreenState extends State<AddFoodScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  String _meal = 'sáng';
  bool _fortified = false;
  final Map<String, TextEditingController> _c = {
    for (final k in ['energyKcal', 'protein', 'fat', 'carbohydrate', 'addedSugar', 'fiber'])
      k: TextEditingController(),
  };
  final Map<String, TextEditingController> _micro = {};

  static const _labels = {
    'energyKcal': 'Năng lượng (kcal)',
    'protein': 'Đạm (g)',
    'fat': 'Béo (g)',
    'carbohydrate': 'Bột đường (g)',
    'addedSugar': 'Đường bổ sung (g)',
    'fiber': 'Chất xơ (g)',
  };

  @override
  void dispose() {
    _name.dispose();
    for (final c in [..._c.values, ..._micro.values]) {
      c.dispose();
    }
    super.dispose();
  }

  double? _num(TextEditingController c) => double.tryParse(c.text.trim().replaceAll(',', '.'));

  void _save() {
    if (!_form.currentState!.validate()) return;
    final n = <String, double>{};
    for (final e in [..._c.entries, ..._micro.entries]) {
      final v = _num(e.value);
      if (v != null && v > 0) n[e.key] = v;
    }
    AppScope.of(context).addItem(IntakeItem(
      label: _name.text.trim(),
      source: _fortified ? IntakeSource.fortified : IntakeSource.food,
      mealId: _meal,
      nutrients: n,
    ));
    Navigator.of(context).pop();
  }

  Future<void> _pickMicro() async {
    final pack = AppScope.of(context).pack;
    final options = pack.nutrients.values
        .where((d) => d.group != 'macro' && !_micro.containsKey(d.id))
        .toList();
    final picked = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => ListView(children: [
        for (final d in options)
          ListTile(title: Text(d.nameVi), trailing: Text(unitLabel(d.unit)), onTap: () => Navigator.pop(ctx, d.id)),
      ]),
    );
    if (picked != null) setState(() => _micro[picked] = TextEditingController());
  }

  String? _validateNum(String? s) {
    if (s == null || s.trim().isEmpty) return null;
    final v = double.tryParse(s.trim().replaceAll(',', '.'));
    if (v == null || v < 0) return 'Nhập số ≥ 0';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final pack = AppScope.of(context).pack;
    return Scaffold(
      appBar: AppBar(title: const Text('Thêm món ăn'), actions: [
        TextButton(onPressed: _save, child: const Text('Lưu')),
      ]),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _name,
              decoration: const InputDecoration(labelText: 'Tên món'),
              validator: (s) => (s == null || s.trim().isEmpty) ? 'Nhập tên món' : null,
            ),
            const SizedBox(height: 12),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'sáng', label: Text('Sáng')),
                ButtonSegment(value: 'trưa', label: Text('Trưa')),
                ButtonSegment(value: 'tối', label: Text('Tối')),
                ButtonSegment(value: 'phụ', label: Text('Phụ')),
              ],
              selected: {_meal},
              onSelectionChanged: (s) => setState(() => _meal = s.first),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Thực phẩm có tăng cường vi chất'),
              subtitle: const Text('Vd. sữa, ngũ cốc ghi "bổ sung vitamin" trên nhãn'),
              value: _fortified,
              onChanged: (v) => setState(() => _fortified = v),
            ),
            for (final e in _c.entries)
              TextFormField(
                controller: e.value,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(labelText: _labels[e.key]),
                validator: _validateNum,
              ),
            const SizedBox(height: 16),
            for (final e in _micro.entries)
              TextFormField(
                controller: e.value,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                    labelText: '${pack.nutrients[e.key]!.nameVi} (${unitLabel(pack.nutrients[e.key]!.unit)})'),
                validator: _validateNum,
              ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _pickMicro,
              icon: const Icon(Icons.add),
              label: const Text('Thêm vitamin hoặc khoáng chất'),
            ),
          ],
        ),
      ),
    );
  }
}
