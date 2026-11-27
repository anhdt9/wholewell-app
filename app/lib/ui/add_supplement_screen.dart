/// Màn Ghi bổ sung (từ sản phẩm có sẵn hoặc Ghi một lần) và Sửa lần uống.
library;

import 'dart:async';

import 'package:health_engine/health_engine.dart';
import 'package:journal_db/journal_db.dart';
import 'package:material_ui/material_ui.dart';

import '../state/app_scope.dart';
import '../state/app_state.dart';
import 'common/common_widgets.dart';
import 'common/food_feedback_sheet.dart';
import 'labels.dart';
import 'product_detail_screen.dart';

class AddSupplementScreen extends StatefulWidget {
  final int? initialProductId;
  final DoseEntry? existingDose;

  const AddSupplementScreen({
    super.key,
    this.initialProductId,
    this.existingDose,
  });

  @override
  State<AddSupplementScreen> createState() => _AddSupplementScreenState();
}

enum _Unit { standard, iu }

class _Line {
  String nutrientId;
  final TextEditingController amount = TextEditingController();
  _Unit unit = _Unit.standard;
  VitaminEForm eForm = VitaminEForm.natural;
  bool vitAPreformed = true;
  _Line(this.nutrientId);
}

class _AddSupplementScreenState extends State<AddSupplementScreen> {
  List<ProductSummary> _products = const [];
  ProductDetail? _selectedProduct;
  bool _oneOffMode = false;
  bool _inited = false;
  bool _loading = true;
  bool _saving = false;

  late TextEditingController _servingsCtrl;
  final _nameCtrl = TextEditingController();
  final List<_Line> _lines = [];
  late TimeOfDay _time;

  static const _iuCapable = {'vitD', 'vitA', 'vitE'};

  bool get _isEditing => widget.existingDose != null;

  @override
  void initState() {
    super.initState();
    final d = widget.existingDose;
    _servingsCtrl = TextEditingController(text: d == null ? '1' : fmt(d.servings));
    if (d != null) {
      _time = TimeOfDay(hour: d.at.hour, minute: d.at.minute);
      _nameCtrl.text = d.name ?? '';
      _oneOffMode = d.productId == null;
    } else {
      final now = DateTime.now();
      _time = TimeOfDay(hour: now.hour, minute: now.minute);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_inited) {
      _inited = true;
      unawaited(_initLoad());
    }
  }

  Future<void> _initLoad() async {
    final state = AppScope.of(context);
    final list = await state.diary.listProducts();
    ProductDetail? detail;
    final pid = widget.existingDose?.productId ?? widget.initialProductId;
    if (pid != null) {
      detail = await state.diary.getProductDetail(pid);
    } else if (widget.existingDose != null && _oneOffMode) {
      for (final line in widget.existingDose!.lines) {
        if (line.nutrientId == null) continue;
        final l = _Line(line.nutrientId!);
        final amt = line.labelAmount ?? line.amounts[line.nutrientId!];
        if (amt != null) l.amount.text = fmt(amt);
        if (line.labelUnit == LabelUnit.iu.name) l.unit = _Unit.iu;
        if (line.nutrientId == 'vitE') {
          l.eForm = (line.form == NutrientForm.synthetic2r || line.form == NutrientForm.syntheticMass)
              ? VitaminEForm.synthetic
              : VitaminEForm.natural;
        }
        if (line.nutrientId == 'vitA') {
          l.vitAPreformed = line.form != NutrientForm.betaCarotene;
        }
        _lines.add(l);
      }
    }
    if (!mounted) return;
    setState(() {
      _products = list;
      _selectedProduct = detail;
      _loading = false;
    });
  }

  @override
  void dispose() {
    _servingsCtrl.dispose();
    _nameCtrl.dispose();
    for (final l in _lines) {
      l.amount.dispose();
    }
    super.dispose();
  }

  Future<void> _pickProduct(int productId) async {
    final detail = await AppScope.of(context).diary.getProductDetail(productId);
    if (!mounted || detail == null) return;
    setState(() {
      _selectedProduct = detail;
      _oneOffMode = false;
    });
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(context: context, initialTime: _time);
    if (picked != null && mounted) setState(() => _time = picked);
  }

  Future<void> _addOneOffLine() async {
    final pack = AppScope.of(context).pack;
    final options =
        pack.nutrients.values.where((d) => d.group != 'macro' && d.id != 'retinol').toList();
    final picked = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => ListView(
        children: [
          for (final d in options)
            ListTile(
              title: Text(d.nameVi),
              trailing: Text(unitLabel(d.unit)),
              onTap: () => Navigator.pop(ctx, d.id),
            ),
        ],
      ),
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

  List<IntakeLine> _buildOneOffLines(ReferencePack pack) {
    final out = <IntakeLine>[];
    for (final l in _lines) {
      final raw = double.tryParse(l.amount.text.trim().replaceAll(',', '.'));
      if (raw == null || !raw.isFinite || raw <= 0) continue;
      final def = pack.nutrients[l.nutrientId]!;
      final labelUnit = l.unit == _Unit.iu ? LabelUnit.iu : _stdLabelUnit(def.unit);
      final form = switch (l.nutrientId) {
        'vitE' => l.eForm == VitaminEForm.natural ? NutrientForm.natural2r : NutrientForm.synthetic2r,
        'vitA' => l.vitAPreformed ? NutrientForm.retinol : NutrientForm.betaCarotene,
        'folicAcid' => NutrientForm.folicAcid,
        _ => NutrientForm.unknown,
      };
      final line = SupplementIngredientHelper.toOneOffIntakeLine(
        pack,
        nutrientId: l.nutrientId,
        form: form,
        amount: raw,
        unit: labelUnit,
      );
      if (line != null) out.add(line);
    }
    return out;
  }

  Future<void> _save({ExpiredBoxChoice expiredChoice = ExpiredBoxChoice.ask}) async {
    if (_saving) return;
    final state = AppScope.of(context);
    final d = widget.existingDose?.at ?? state.day;
    final at = DateTime(d.year, d.month, d.day, _time.hour, _time.minute);

    double servings = 1.0;
    late List<IntakeLine> lines;
    String summaryLabel;
    int? productId;
    String? name;

    if (_selectedProduct != null) {
      final parsedServings = double.tryParse(_servingsCtrl.text.trim().replaceAll(',', '.'));
      if (parsedServings == null || !parsedServings.isFinite || parsedServings <= 0) {
        AppFeedback.showSnack(context, 'Nhập số khẩu phần lớn hơn 0.');
        return;
      }
      servings = parsedServings;
      productId = _selectedProduct!.product.id;
      name = _selectedProduct!.product.name;
      summaryLabel = name;
      lines = state.diary.buildDoseLinesFromIngredients(_selectedProduct!.ingredients, servings);
    } else {
      lines = _buildOneOffLines(state.pack);
      if (lines.isEmpty) {
        AppFeedback.showSnack(context, 'Nhập ít nhất một chất.');
        return;
      }
      name = _nameCtrl.text.trim().isEmpty ? 'Bổ sung' : _nameCtrl.text.trim();
      summaryLabel = name;
    }

    setState(() => _saving = true);
    final DoseLogOutcome outcome;
    try {
      if (_isEditing) {
        outcome = await state.diary.updateSupplementDose(
          doseId: widget.existingDose!.id,
          productId: productId,
          name: name,
          servings: servings,
          at: at,
          lines: lines,
          expiredBoxes: expiredChoice,
          summaryLabel: summaryLabel,
        );
      } else {
        outcome = await state.diary.recordSupplementDose(
          productId: productId,
          name: name,
          servings: servings,
          at: at,
          lines: lines,
          expiredBoxes: expiredChoice,
          summaryLabel: summaryLabel,
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }

    if (!mounted) return;

    if (outcome is DoseNeedsExpiredChoice) {
      final choice = await showDialog<ExpiredBoxChoice>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Trừ vào hộp đã hết hạn?'),
          content: const Text(
            'Sản phẩm này không còn hộp còn hạn. Bạn muốn trừ vào hộp đã hết hạn hay chỉ ghi lần uống?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, ExpiredBoxChoice.skip),
              child: const Text('Không trừ'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, ExpiredBoxChoice.deduct),
              child: const Text('Trừ'),
            ),
          ],
        ),
      );
      if (choice != null && mounted) {
        await _save(expiredChoice: choice);
      }
      return;
    }

    final feedback = (outcome as DoseLogged).feedback;
    final navigator = Navigator.of(context);
    final rootCtx = navigator.context;
    navigator.pop();
    if (!rootCtx.mounted) return;
    final productForBox = _selectedProduct?.product;
    await presentFoodFeedback(
      rootCtx,
      feedback: feedback,
      pack: state.pack,
      onUndo: feedback.savedDoseId == null
          ? null
          : () => state.diary.deleteDoseEntry(feedback.savedDoseId!),
      onAddBox: productForBox == null
          ? null
          : () => navigator.push(
                MaterialPageRoute<void>(
                  builder: (_) => ProductBoxesScreen(product: productForBox),
                ),
              ),
    );
  }

  Future<void> _deleteExisting() async {
    final dose = widget.existingDose;
    if (dose == null) return;
    await AppScope.of(context).diary.deleteDoseEntry(dose.id);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Ghi bổ sung')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    // Bước chọn sản phẩm (khi mở từ Bảng Ghi -> Bổ sung mà chưa chọn sản phẩm).
    if (_selectedProduct == null && !_oneOffMode && !_isEditing) {
      return Scaffold(
        appBar: AppBar(title: const Text('Ghi bổ sung')),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (_products.isNotEmpty) ...[
              Text('Chọn sản phẩm', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 8),
              for (final s in _products)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(s.product.name),
                  subtitle: Text(
                    s.validRemaining > 0
                        ? 'Còn ${fmt(s.validRemaining)} ${countUnitLabel(s.product.countUnit)}'
                        : 'Kho đã hết',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _pickProduct(s.product.id),
                ),
              const Divider(),
            ] else
              const Padding(
                padding: EdgeInsets.only(bottom: 12),
                child: Text('Chưa có sản phẩm nào trong tủ.'),
              ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.edit_note),
              title: const Text('Ghi một lần (không lưu tủ)'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => setState(() => _oneOffMode = true),
            ),
          ],
        ),
      );
    }

    final timeStr =
        '${_time.hour.toString().padLeft(2, '0')}:${_time.minute.toString().padLeft(2, '0')}';

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing
            ? 'Sửa lần uống'
            : (_selectedProduct?.product.name ?? 'Ghi một lần')),
        actions: [
          if (_isEditing)
            IconButton(
              tooltip: 'Xóa',
              icon: Icon(Icons.delete_outline, color: Theme.of(context).colorScheme.error),
              onPressed: _deleteExisting,
            ),
          TextButton(onPressed: _saving ? null : _save, child: const Text('Lưu')),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.schedule),
            title: const Text('Giờ uống'),
            trailing: Text(timeStr, style: Theme.of(context).textTheme.titleMedium),
            onTap: _pickTime,
          ),
          const Divider(),
          if (_selectedProduct != null) ...[
            TextField(
              controller: _servingsCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText:
                    'Số khẩu phần (1 khẩu phần = ${fmt(_selectedProduct!.product.unitsPerServing)} ${countUnitLabel(_selectedProduct!.product.countUnit)})',
              ),
            ),
          ] else ...[
            TextField(
              controller: _nameCtrl,
              decoration: const InputDecoration(labelText: 'Tên sản phẩm (tùy chọn)'),
            ),
            const SizedBox(height: 8),
            const Text('Nhập đúng lượng trong một lần dùng, theo nhãn.'),
            for (final l in _lines) ...[
              const Divider(),
              Text(
                AppScope.of(context).pack.nutrients[l.nutrientId]!.nameVi,
                style: Theme.of(context).textTheme.titleSmall,
              ),
              Row(
                children: [
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
                        DropdownMenuItem(
                          value: _Unit.standard,
                          child: Text(unitLabel(AppScope.of(context).pack.nutrients[l.nutrientId]!.unit)),
                        ),
                        const DropdownMenuItem(value: _Unit.iu, child: Text('IU')),
                      ],
                      onChanged: (u) => setState(() => l.unit = u!),
                    )
                  else
                    Text(unitLabel(AppScope.of(context).pack.nutrients[l.nutrientId]!.unit)),
                ],
              ),
              if (l.nutrientId == 'vitE')
                DropdownButton<VitaminEForm>(
                  value: l.eForm,
                  items: const [
                    DropdownMenuItem(
                      value: VitaminEForm.natural,
                      child: Text('Dạng tự nhiên (d-alpha)'),
                    ),
                    DropdownMenuItem(
                      value: VitaminEForm.synthetic,
                      child: Text('Dạng tổng hợp (dl-alpha)'),
                    ),
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
            OutlinedButton.icon(
              onPressed: _addOneOffLine,
              icon: const Icon(Icons.add),
              label: const Text('Thêm chất'),
            ),
          ],
          const SizedBox(height: 20),
          FilledButton(
            onPressed: _saving ? null : _save,
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
  }
}
