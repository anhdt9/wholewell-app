import 'package:material_ui/material_ui.dart';
import 'package:health_engine/health_engine.dart';
import 'package:journal_db/journal_db.dart';

import '../state/app_scope.dart';
import 'labels.dart';

/// Nhập một liều bổ sung. Đổi đơn vị qua [UnitConverter.convertIntakeLine] để tính đúng `ulAmounts`.
class AddSupplementScreen extends StatefulWidget {
  const AddSupplementScreen({super.key});
  @override
  State<AddSupplementScreen> createState() => _AddSupplementScreenState();
}

enum _Unit { standard, iu }

class _Line {
  String nutrientId;
  final TextEditingController amount = TextEditingController();
  _Unit unit = _Unit.standard;
  VitaminEForm eForm = VitaminEForm.natural;

  /// Vitamin A: true = dạng có sẵn (retinol, retinyl), false = beta-caroten.
  bool vitAPreformed = true;
  _Line(this.nutrientId);
}

class _AddSupplementScreenState extends State<AddSupplementScreen> {
  final _name = TextEditingController();
  final List<_Line> _lines = [];

  static const _iuCapable = {'vitD', 'vitA', 'vitE'};

  @override
  void dispose() {
    _name.dispose();
    for (final l in _lines) {
      l.amount.dispose();
    }
    super.dispose();
  }

  Future<void> _addLine() async {
    final pack = AppScope.of(context).pack;
    final options = pack.nutrients.values.where((d) => d.group != 'macro' && d.id != 'retinol').toList();
    final picked = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => ListView(children: [
        for (final d in options)
          ListTile(title: Text(d.nameVi), trailing: Text(unitLabel(d.unit)), onTap: () => Navigator.pop(ctx, d.id)),
      ]),
    );
    if (picked != null) setState(() => _lines.add(_Line(picked)));
  }

  LabelUnit _stdLabelUnit(String packUnit) => switch (packUnit) {
        'g' => LabelUnit.g,
        'mg' => LabelUnit.mg,
        'ug' => LabelUnit.ug,
        'ug_RAE' => LabelUnit.ugRae,
        'ug_DFE' => LabelUnit.ugDfe,
        'mg_NE' => LabelUnit.mgNe,
        _ => LabelUnit.mg,
      };

  void _save() {
    final state = AppScope.of(context);
    final conv = UnitConverter(state.pack);
    final out = <IntakeLine>[];
    for (final l in _lines) {
      final raw = double.tryParse(l.amount.text.trim().replaceAll(',', '.'));
      if (raw == null || raw <= 0) continue;
      final def = state.pack.nutrients[l.nutrientId]!;
      final labelUnit = l.unit == _Unit.iu ? LabelUnit.iu : _stdLabelUnit(def.unit);
      final form = switch (l.nutrientId) {
        'vitE' => l.eForm == VitaminEForm.natural ? NutrientForm.natural2r : NutrientForm.synthetic2r,
        'vitA' => l.vitAPreformed ? NutrientForm.retinol : NutrientForm.betaCarotene,
        'folicAcid' => NutrientForm.folicAcid,
        _ => NutrientForm.unknown,
      };
      final converted = conv.convertIntakeLine(IntakeLineInput(
        nutrientId: l.nutrientId,
        source: IntakeSource.supplement,
        form: form,
        amount: raw,
        unit: labelUnit,
      ));
      if (converted.amounts.isEmpty) continue;
      out.add(IntakeLine(
        nutrientId: l.nutrientId,
        source: IntakeSource.supplement,
        form: form,
        uncertain: converted.uncertain,
        labelAmount: raw,
        labelUnit: labelUnit.name,
        amounts: converted.amounts,
        ulAmounts: converted.ulAmounts,
      ));
    }
    if (out.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Nhập ít nhất một chất.')));
      return;
    }
    state.recordDose(_name.text.trim().isEmpty ? 'Bổ sung' : _name.text.trim(), out);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final pack = AppScope.of(context).pack;
    return Scaffold(
      appBar: AppBar(title: const Text('Thêm bổ sung'), actions: [
        TextButton(onPressed: _save, child: const Text('Lưu')),
      ]),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(controller: _name, decoration: const InputDecoration(labelText: 'Tên sản phẩm (tùy chọn)')),
          const SizedBox(height: 8),
          const Text('Nhập đúng lượng trong một lần dùng, theo nhãn. '
              'Với folate, chọn "Axit folic" nếu nhãn ghi folic acid.'),
          for (final l in _lines) ...[
            const Divider(),
            Text(pack.nutrients[l.nutrientId]!.nameVi, style: Theme.of(context).textTheme.titleSmall),
            Row(children: [
              Expanded(
                child: TextField(
                  controller: l.amount,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'Lượng'),
                ),
              ),
              const SizedBox(width: 12),
              if (_iuCapable.contains(l.nutrientId))
                DropdownButton<_Unit>(
                  value: l.unit,
                  items: [
                    DropdownMenuItem(value: _Unit.standard, child: Text(unitLabel(pack.nutrients[l.nutrientId]!.unit))),
                    const DropdownMenuItem(value: _Unit.iu, child: Text('IU')),
                  ],
                  onChanged: (u) => setState(() => l.unit = u!),
                )
              else
                Text(unitLabel(pack.nutrients[l.nutrientId]!.unit)),
            ]),
            if (l.nutrientId == 'vitE')
              DropdownButton<VitaminEForm>(
                value: l.eForm,
                items: const [
                  DropdownMenuItem(value: VitaminEForm.natural, child: Text('Dạng tự nhiên (d-alpha)')),
                  DropdownMenuItem(value: VitaminEForm.synthetic, child: Text('Dạng tổng hợp (dl-alpha)')),
                ],
                onChanged: (f) => setState(() => l.eForm = f!),
              ),
            if (l.nutrientId == 'vitA')
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Dạng có sẵn (retinol, retinyl)'),
                subtitle: const Text('Tắt nếu nhãn ghi beta-caroten'),
                value: l.vitAPreformed,
                onChanged: (v) => setState(() => l.vitAPreformed = v),
              ),
          ],
          const SizedBox(height: 12),
          OutlinedButton.icon(onPressed: _addLine, icon: const Icon(Icons.add), label: const Text('Thêm chất')),
        ],
      ),
    );
  }
}
