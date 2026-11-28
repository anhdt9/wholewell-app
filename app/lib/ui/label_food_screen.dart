/// Màn Nhập theo nhãn (theo `docs/design/food-library.md`).
library;

import 'dart:async';

import 'package:flutter/services.dart' show HapticFeedback;
import 'package:health_engine/health_engine.dart';
import 'package:journal_db/models.dart';
import 'package:material_ui/material_ui.dart';

import '../state/app_scope.dart';
import '../state/diary_controller.dart';
import '../state/label_food_builder.dart';
import 'common/common_widgets.dart';
import 'common/food_feedback_sheet.dart';
import 'labels.dart';

class _MicroFormRow {
  final String nutrientId;
  final TextEditingController amount = TextEditingController();
  final TextEditingController secondaryFolicAcid = TextEditingController();
  late LabelUnit unit;
  String form;
  LabelFolateMode? folateMode;

  _MicroFormRow(this.nutrientId, {required ReferencePack pack})
    : unit = _defaultUnit(nutrientId, pack),
      form = NutrientForm.unknown,
      folateMode = nutrientId == 'folate' ? LabelFolateMode.folateGeneral : null {
    if (nutrientId == 'folicAcid') {
      unit = LabelUnit.ug;
      form = NutrientForm.folicAcid;
      folateMode = LabelFolateMode.folicAcidOnly;
    }
  }

  static LabelUnit _defaultUnit(String id, ReferencePack pack) {
    final u = pack.nutrients[id]?.unit;
    return switch (u) {
      'g' => LabelUnit.g,
      'mg' || 'mg_NE' => LabelUnit.mg,
      'ug_DFE' => LabelUnit.ugDfe,
      _ => LabelUnit.ug,
    };
  }

  void dispose() {
    amount.dispose();
    secondaryFolicAcid.dispose();
  }
}

class LabelFoodScreen extends StatefulWidget {
  final Meal initialMeal;
  final String? initialName;

  const LabelFoodScreen({super.key, required this.initialMeal, this.initialName});

  @override
  State<LabelFoodScreen> createState() => _LabelFoodScreenState();
}

class _LabelFoodScreenState extends State<LabelFoodScreen> {
  final _formKey = GlobalKey<FormState>();
  final _scroll = ScrollController();

  late final TextEditingController _name = TextEditingController(text: widget.initialName ?? '');
  final _basisQty = TextEditingController(text: '100');
  final _usedQty = TextEditingController(text: '100');
  String _basisUnit = 'g';
  bool _usedManuallyEdited = false;

  late Meal _meal = widget.initialMeal;
  bool _saveForReuse = false;
  bool _saving = false;
  final Set<String> _flaggedNutrients = {};

  final _energy = TextEditingController();
  final _protein = TextEditingController();
  final _fat = TextEditingController();
  final _carb = TextEditingController();
  final _totalSugar = TextEditingController();
  final _addedSugar = TextEditingController();
  final _sodium = TextEditingController();
  final List<_MicroFormRow> _micros = [];

  static const _basisUnits = ['g', 'ml', 'khẩu phần', 'gói', 'hộp', 'viên', 'lọ'];

  @override
  void dispose() {
    _scroll.dispose();
    _name.dispose();
    _basisQty.dispose();
    _usedQty.dispose();
    _energy.dispose();
    _protein.dispose();
    _fat.dispose();
    _carb.dispose();
    _totalSugar.dispose();
    _addedSugar.dispose();
    _sodium.dispose();
    for (final m in _micros) {
      m.dispose();
    }
    super.dispose();
  }

  double? _parseOpt(TextEditingController c) {
    final s = c.text.trim().replaceAll(',', '.');
    if (s.isEmpty) return null;
    final v = double.tryParse(s);
    return (v != null && v.isFinite) ? v : null;
  }

  String? _validateNonNeg(String? s) {
    if (s == null || s.trim().isEmpty) return null;
    final v = double.tryParse(s.trim().replaceAll(',', '.'));
    if (v == null || !v.isFinite || v < 0) return 'Nhập số ≥ 0';
    return null;
  }

  String? _validatePos(String? s) {
    final v = double.tryParse((s ?? '').trim().replaceAll(',', '.'));
    if (v == null || !v.isFinite || v <= 0) return 'Nhập số > 0';
    return null;
  }

  Future<void> _pickMicro() async {
    final pack = AppScope.of(context).pack;
    final existing = _micros.map((m) => m.nutrientId).toSet();
    final options = [
      for (final d in pack.nutrients.values)
        if (d.group != 'macro' && d.id != 'sodium' && d.id != 'retinol' && !existing.contains(d.id)) d,
    ];
    var filter = '';
    final picked = await showAppModalSheet<String>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) {
          final q = normalizeSearchAscii(filter);
          final shown = [
            for (final d in options)
              if (q.isEmpty || normalizeSearchAscii(d.nameVi).contains(q)) d,
          ];
          return SizedBox(
            height: MediaQuery.of(ctx).size.height * 0.65,
            child: Column(
              children: [
                Text('Chọn chất trên nhãn', style: Theme.of(ctx).textTheme.titleMedium),
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: TextField(
                    decoration: const InputDecoration(
                      prefixIcon: Icon(LucideIcons.search),
                      hintText: 'Tìm vitamin, khoáng chất...',
                    ),
                    onChanged: (v) => setSheet(() => filter = v),
                  ),
                ),
                Expanded(
                  child: ListView(
                    children: [
                      for (final d in shown)
                        ListTile(
                          minTileHeight: 48,
                          title: Text(d.nameVi),
                          subtitle: d.group == 'mineral' ? const Text('Nhập theo lượng nguyên tố ghi trên nhãn') : null,
                          onTap: () => Navigator.pop(ctx, d.id),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
    if (picked != null && mounted) {
      setState(() => _micros.add(_MicroFormRow(picked, pack: pack)));
    }
  }

  Future<void> _submit() async {
    if (_saving) return;
    if (!_formKey.currentState!.validate()) return;
    final state = AppScope.of(context);
    final pack = state.pack;

    final basis = _parseOpt(_basisQty)!;
    final used = _parseOpt(_usedQty)!;

    final draft = LabelFoodDraft(
      name: _name.text.trim(),
      meal: _meal,
      at: DiaryController.defaultAtFor(state.day, _meal, settings: state.dayTimesSettings),
      labelBasisQty: basis,
      labelBasisUnit: _basisUnit,
      usedQty: used,
      energyKcal: _parseOpt(_energy),
      proteinG: _parseOpt(_protein),
      fatG: _parseOpt(_fat),
      carbG: _parseOpt(_carb),
      totalSugarG: _parseOpt(_totalSugar),
      addedSugarG: _parseOpt(_addedSugar),
      sodiumMg: _parseOpt(_sodium),
      micros: [
        for (final row in _micros)
          if ((_parseOpt(row.amount) ?? 0) > 0)
            LabelMicroEntry(
              nutrientId: row.nutrientId,
              labelAmount: _parseOpt(row.amount)!,
              unit: row.unit,
              form: row.form,
              folateMode: row.folateMode,
              secondaryFolicAcidUg: row.folateMode == LabelFolateMode.folateWithFolicAcid
                  ? (_parseOpt(row.secondaryFolicAcid) ?? 0)
                  : null,
            ),
      ],
    );

    final built = LabelFoodBuilder.build(draft, pack: pack, profile: state.profile);
    if (built.warnings.isNotEmpty) {
      setState(() {
        _flaggedNutrients.clear();
        for (final w in built.warnings) {
          _flaggedNutrients.add(w.nutrientId);
          if (w.nutrientId == 'retinol') _flaggedNutrients.add('vitA');
          if (w.nutrientId == 'folicAcid') _flaggedNutrients.add('folate');
        }
      });
      final proceed = await _confirmUnitWarnings(built.warnings);
      if (proceed != true || !mounted) return;
    }

    setState(() => _saving = true);
    final FoodLogFeedback fb;
    try {
      fb = await state.diary.recordLabelFood(draft, saveForReuse: _saveForReuse);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
    if (!mounted) return;

    if (fb.failed) {
      await presentFoodFeedback(context, feedback: fb, pack: pack);
      return;
    }
    unawaited(HapticFeedback.lightImpact());
    Navigator.of(context).pop(fb);
  }

  Future<bool?> _confirmUnitWarnings(List<UnitPlausibilityWarning> warnings) => showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Kiểm tra lại đơn vị'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final w in warnings)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text('${w.nutrientNameVi}: ${fmt(w.displayAmount)} ${unitLabel(w.displayUnit)}'),
            ),
          const SizedBox(height: 8),
          const Text('Số liệu cao bất thường, kiểm tra lại mg và µg.'),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Kiểm tra lại')),
        FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Vẫn lưu')),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final pack = state.pack;
    final t = Theme.of(context).textTheme;
    final isToday = dayKey(state.day) == dayKey(DateTime.now());
    final title = isToday ? 'Nhập theo nhãn' : 'Nhập theo nhãn · ${state.day.day}/${state.day.month}';

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            Expanded(
              child: ListView(
                controller: _scroll,
                padding: const EdgeInsets.all(16),
                children: [
                  TextFormField(
                    controller: _name,
                    decoration: const InputDecoration(labelText: 'Tên món'),
                    validator: (s) => (s == null || s.trim().isEmpty) ? 'Nhập tên món' : null,
                  ),
                  const SizedBox(height: 12),
                  SegmentedButton<Meal>(
                    segments: enabledMealSegments(state.dayTimesSettings, alwaysInclude: _meal),
                    selected: {_meal},
                    onSelectionChanged: (s) => setState(() => _meal = s.first),
                  ),
                  const SizedBox(height: 16),
                  Text('Số trên nhãn tính cho', style: t.titleSmall),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _basisQty,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: const InputDecoration(),
                          validator: _validatePos,
                          onChanged: (v) {
                            if (!_usedManuallyEdited) _usedQty.text = v;
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          isExpanded: true,
                          initialValue: _basisUnit,
                          decoration: const InputDecoration(),
                          items: [for (final u in _basisUnits) DropdownMenuItem(value: u, child: Text(u))],
                          onChanged: (u) {
                            if (u != null) setState(() => _basisUnit = u);
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _usedQty,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(labelText: 'Bạn đã dùng', suffixText: _basisUnit),
                    validator: _validatePos,
                    onChanged: (_) => _usedManuallyEdited = true,
                  ),
                  const SizedBox(height: 16),
                  _numField(_energy, 'Năng lượng (kcal)'),
                  _numField(_protein, 'Đạm (g)'),
                  _numField(_fat, 'Béo (g)'),
                  _numField(_carb, 'Bột đường (g)'),
                  _numField(_totalSugar, 'Đường (tổng) (g)'),
                  _numField(
                    _addedSugar,
                    'Đường bổ sung (g)',
                    helper: 'Chỉ nhập nếu nhãn ghi riêng; bỏ trống nếu chỉ ghi đường tổng (nhập 0 nếu là 0 g).',
                  ),
                  _numField(_sodium, 'Natri (mg)'),
                  const SizedBox(height: 16),
                  Text('Vi chất khác trên nhãn', style: t.titleSmall),
                  const SizedBox(height: 8),
                  for (var i = 0; i < _micros.length; i++) _buildMicroCard(i, _micros[i], pack),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 48,
                    child: OutlinedButton.icon(
                      onPressed: _pickMicro,
                      icon: const Icon(LucideIcons.plus),
                      label: const Text('Thêm vi chất trên nhãn'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    value: _saveForReuse,
                    onChanged: (v) => setState(() => _saveForReuse = v ?? false),
                    title: const Text('Lưu để dùng lại'),
                  ),
                ],
              ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: FilledButton(
                    onPressed: _saving ? null : _submit,
                    child: _saving
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Text('Lưu'),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _numField(TextEditingController ctrl, String label, {String? helper}) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: TextFormField(
      controller: ctrl,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(labelText: label, helperText: helper, helperMaxLines: 3),
      validator: _validateNonNeg,
    ),
  );

  Widget _buildMicroCard(int index, _MicroFormRow row, ReferencePack pack) {
    final def = pack.nutrients[row.nutrientId]!;
    final isMineral = def.group == 'mineral';
    final isFlagged = _flaggedNutrients.contains(row.nutrientId);
    final cs = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    isMineral ? '${def.nameVi} (nguyên tố)' : def.nameVi,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
                IconButton(
                  onPressed: () {
                    setState(() {
                      _micros.removeAt(index).dispose();
                    });
                  },
                  icon: const Icon(LucideIcons.x),
                  tooltip: 'Xóa dòng chất',
                ),
              ],
            ),
            if (row.nutrientId == 'folate') ...[
              const SizedBox(height: 6),
              DropdownButtonFormField<LabelFolateMode>(
                isExpanded: true,
                initialValue: row.folateMode ?? LabelFolateMode.folateGeneral,
                decoration: const InputDecoration(labelText: 'Cách ghi trên nhãn'),
                items: const [
                  DropdownMenuItem(value: LabelFolateMode.folicAcidOnly, child: Text('Axit folic')),
                  DropdownMenuItem(
                    value: LabelFolateMode.folateWithFolicAcid,
                    child: Text('Folate tổng (có tách axit folic)'),
                  ),
                  DropdownMenuItem(value: LabelFolateMode.folateGeneral, child: Text('Folate')),
                ],
                onChanged: (m) {
                  if (m == null) return;
                  setState(() {
                    row.folateMode = m;
                    if (m == LabelFolateMode.folicAcidOnly) {
                      row.unit = LabelUnit.ug;
                      row.form = NutrientForm.folicAcid;
                    } else if (m == LabelFolateMode.folateWithFolicAcid) {
                      row.unit = LabelUnit.ugDfe;
                      row.form = NutrientForm.unknown;
                    } else {
                      row.unit = LabelUnit.ug;
                      row.form = NutrientForm.unknown;
                    }
                  });
                },
              ),
              const SizedBox(height: 8),
            ],
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: row.amount,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: 'Lượng trên nhãn',
                      errorText: isFlagged ? 'Kiểm tra lại mg và µg' : null,
                    ),
                    validator: _validateNonNeg,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(child: _unitSelector(row, def)),
              ],
            ),
            if (row.nutrientId == 'folate' && row.folateMode == LabelFolateMode.folateWithFolicAcid) ...[
              const SizedBox(height: 8),
              TextFormField(
                controller: row.secondaryFolicAcid,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Trong đó axit folic (µg)'),
                validator: _validateNonNeg,
              ),
            ],
            if (_needsFormDropdown(row)) ...[const SizedBox(height: 8), _formSelector(row)],
            if (isMineral)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  'Nhập theo lượng nguyên tố ghi trên nhãn',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _unitSelector(_MicroFormRow row, NutrientDef def) {
    final items = <DropdownMenuItem<LabelUnit>>[];
    if (row.nutrientId == 'vitA') {
      items.addAll(const [
        DropdownMenuItem(value: LabelUnit.ug, child: Text('µg')),
        DropdownMenuItem(value: LabelUnit.iu, child: Text('IU')),
      ]);
    } else if (row.nutrientId == 'vitD') {
      items.addAll(const [
        DropdownMenuItem(value: LabelUnit.ug, child: Text('µg')),
        DropdownMenuItem(value: LabelUnit.iu, child: Text('IU')),
      ]);
    } else if (row.nutrientId == 'vitE') {
      items.addAll(const [
        DropdownMenuItem(value: LabelUnit.mg, child: Text('mg')),
        DropdownMenuItem(value: LabelUnit.iu, child: Text('IU')),
      ]);
    } else if (row.nutrientId == 'folate') {
      if (row.folateMode == LabelFolateMode.folicAcidOnly) {
        items.add(const DropdownMenuItem(value: LabelUnit.ug, child: Text('µg')));
      } else if (row.folateMode == LabelFolateMode.folateWithFolicAcid) {
        items.add(const DropdownMenuItem(value: LabelUnit.ugDfe, child: Text('µg (đã quy đổi trên nhãn)')));
      } else {
        items.addAll(const [
          DropdownMenuItem(value: LabelUnit.ug, child: Text('µg (lượng thực tế)')),
          DropdownMenuItem(value: LabelUnit.ugDfe, child: Text('µg (đã quy đổi trên nhãn)')),
        ]);
      }
    } else {
      final defUnit = _MicroFormRow._defaultUnit(row.nutrientId, AppScope.of(context).pack);
      if (defUnit == LabelUnit.ug) {
        items.addAll(const [
          DropdownMenuItem(value: LabelUnit.ug, child: Text('µg')),
          DropdownMenuItem(value: LabelUnit.mg, child: Text('mg')),
        ]);
      } else {
        items.addAll(const [
          DropdownMenuItem(value: LabelUnit.mg, child: Text('mg')),
          DropdownMenuItem(value: LabelUnit.ug, child: Text('µg')),
        ]);
      }
    }
    return DropdownButtonFormField<LabelUnit>(
      isExpanded: true,
      key: ValueKey('unit-${row.nutrientId}-${row.folateMode}-${row.unit}'),
      initialValue: items.any((i) => i.value == row.unit) ? row.unit : items.first.value,
      decoration: const InputDecoration(),
      items: items,
      onChanged: (u) {
        if (u != null) {
          setState(() {
            row.unit = u;
            if (row.nutrientId == 'vitE' && u == LabelUnit.iu && row.form == NutrientForm.syntheticMass) {
              row.form = NutrientForm.synthetic2r;
            }
          });
        }
      },
    );
  }

  bool _needsFormDropdown(_MicroFormRow row) =>
      row.nutrientId == 'vitA' ||
      row.nutrientId == 'vitE' ||
      (row.nutrientId == 'folate' && row.folateMode == LabelFolateMode.folateGeneral);

  Widget _formSelector(_MicroFormRow row) {
    final items = <DropdownMenuItem<String>>[];
    if (row.nutrientId == 'vitA') {
      items.addAll(const [
        DropdownMenuItem(value: NutrientForm.unknown, child: Text('Nhãn không ghi rõ')),
        DropdownMenuItem(value: NutrientForm.retinol, child: Text('Retinol / từ động vật')),
        DropdownMenuItem(value: NutrientForm.betaCarotene, child: Text('Beta-caroten / từ thực vật')),
      ]);
    } else if (row.nutrientId == 'vitE') {
      if (row.unit == LabelUnit.iu) {
        items.addAll(const [
          DropdownMenuItem(value: NutrientForm.unknown, child: Text('Nhãn không ghi rõ')),
          DropdownMenuItem(value: NutrientForm.natural2r, child: Text('Tự nhiên (d-alpha)')),
          DropdownMenuItem(value: NutrientForm.synthetic2r, child: Text('Tổng hợp (dl-alpha)')),
        ]);
      } else {
        items.addAll(const [
          DropdownMenuItem(value: NutrientForm.unknown, child: Text('Nhãn không ghi rõ')),
          DropdownMenuItem(value: NutrientForm.natural2r, child: Text('Tự nhiên (d-alpha)')),
          DropdownMenuItem(value: NutrientForm.synthetic2r, child: Text('Tổng hợp (dl-alpha, theo hoạt lực)')),
          DropdownMenuItem(value: NutrientForm.syntheticMass, child: Text('Tổng hợp (dl-alpha, theo khối lượng)')),
        ]);
      }
    } else if (row.nutrientId == 'folate' && row.folateMode == LabelFolateMode.folateGeneral) {
      items.addAll(const [
        DropdownMenuItem(value: NutrientForm.unknown, child: Text('Không rõ nguồn')),
        DropdownMenuItem(value: NutrientForm.folicAcid, child: Text('Nhãn ghi là axit folic')),
      ]);
    }

    return DropdownButtonFormField<String>(
      isExpanded: true,
      key: ValueKey('form-${row.nutrientId}-${row.folateMode}-${row.unit}-${row.form}'),
      initialValue: items.any((i) => i.value == row.form) ? row.form : items.first.value,
      decoration: const InputDecoration(labelText: 'Dạng'),
      items: items,
      onChanged: (v) {
        if (v != null) setState(() => row.form = v);
      },
    );
  }
}
