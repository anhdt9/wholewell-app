/// Màn Xác nhận thành phần (sau OCR hoặc nhập tay / sửa thành phần sản phẩm).
library;

import 'package:health_engine/health_engine.dart';
import 'package:journal_db/journal_db.dart';
import 'package:material_ui/material_ui.dart';

import '../state/app_scope.dart';
import '../state/app_state.dart';
import 'common/common_widgets.dart';
import 'labels.dart';

class EditableIngredient {
  String? nutrientId;
  String? freeName;
  String form;
  double? labelAmount;
  LabelUnit labelUnit;
  bool isCompound;
  IngredientOrigin origin;
  bool confirmed;

  EditableIngredient({
    this.nutrientId,
    this.freeName,
    this.form = NutrientForm.unknown,
    this.labelAmount,
    this.labelUnit = LabelUnit.mg,
    this.isCompound = false,
    this.origin = IngredientOrigin.manual,
    this.confirmed = false,
  });

  factory EditableIngredient.fromParsed(ParsedIngredientLine p, ReferencePack pack) {
    final def = p.nutrientId == null ? null : pack.nutrients[p.nutrientId];
    return EditableIngredient(
      nutrientId: p.nutrientId,
      freeName: p.freeName,
      form: p.form,
      labelAmount: p.amount,
      labelUnit: p.unit ?? _defaultUnitFor(def?.unit),
      isCompound: p.compoundKind != CompoundKind.elemental,
      origin: IngredientOrigin.ocr,
      confirmed: false,
    );
  }

  factory EditableIngredient.fromSaved(ProductIngredient i) {
    return EditableIngredient(
      nutrientId: i.nutrientId,
      freeName: i.freeName,
      form: i.form,
      labelAmount: i.labelAmount,
      labelUnit: LabelUnit.values.where((u) => u.name == i.labelUnit).firstOrNull ?? LabelUnit.mg,
      isCompound: i.isCompound,
      origin: i.origin,
      confirmed: i.confirmed,
    );
  }

  static LabelUnit _defaultUnitFor(String? packUnit) => switch (packUnit) {
        'g' => LabelUnit.g,
        'mg' => LabelUnit.mg,
        'ug' => LabelUnit.ug,
        'ug_RAE' => LabelUnit.ugRae,
        'ug_DFE' => LabelUnit.ugDfe,
        'mg_NE' => LabelUnit.mgNe,
        _ => LabelUnit.mg,
      };
}

class ConfirmIngredientsScreen extends StatefulWidget {
  final List<EditableIngredient> initialLines;
  final List<String> rawOcrLines;
  final String? scannedBarcode;
  final int? editingProductId;
  final bool fromDsld;
  final Future<void> Function(BuildContext ctx, List<IngredientDraft> drafts) onConfirmed;

  const ConfirmIngredientsScreen({
    super.key,
    required this.initialLines,
    this.rawOcrLines = const [],
    this.scannedBarcode,
    this.editingProductId,
    this.fromDsld = false,
    required this.onConfirmed,
  });

  @override
  State<ConfirmIngredientsScreen> createState() => _ConfirmIngredientsScreenState();
}

class _ConfirmIngredientsScreenState extends State<ConfirmIngredientsScreen> {
  late List<EditableIngredient> _lines;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _lines = [for (final l in widget.initialLines) l];
  }

  bool _isUnitCompatible(EditableIngredient l, ReferencePack pack) =>
      SupplementIngredientHelper.isUnitCompatible(
        pack,
        nutrientId: l.nutrientId,
        form: l.form,
        amount: l.labelAmount,
        unit: l.labelUnit,
        isCompound: l.isCompound,
      );

  bool get _allUnitCompatible {
    if (_lines.isEmpty) return false;
    final pack = AppScope.of(context).pack;
    return _lines.every(
      (l) => (l.labelAmount ?? 0) > 0 && _isUnitCompatible(l, pack),
    );
  }

  void _setAllConfirmed(bool value) {
    final pack = AppScope.of(context).pack;
    setState(() {
      for (final l in _lines) {
        if (!value) {
          l.confirmed = false;
        } else if ((l.labelAmount ?? 0) > 0 && _isUnitCompatible(l, pack)) {
          l.confirmed = true;
        }
      }
    });
  }

  Future<void> _confirmAllAndSubmit() async {
    _setAllConfirmed(true);
    if (_allConfirmed && !_saving) {
      await _submit();
    }
  }

  bool get _allConfirmed {
    if (_lines.isEmpty) return false;
    final pack = AppScope.of(context).pack;
    return _lines.every(
      (l) => l.confirmed && (l.labelAmount ?? 0) > 0 && _isUnitCompatible(l, pack),
    );
  }

  IngredientDraft _toDraft(EditableIngredient l, ReferencePack pack) =>
      SupplementIngredientHelper.toDraft(
        pack,
        nutrientId: l.nutrientId,
        freeName: l.freeName,
        form: l.form,
        labelAmount: l.labelAmount,
        labelUnit: l.labelUnit,
        isCompound: l.isCompound,
        origin: l.origin,
        confirmed: l.confirmed,
      );

  ({IngredientSanityResult sanity, bool unitIncompatible}) _sanity(
    EditableIngredient l,
    AppState state,
  ) =>
      SupplementIngredientHelper.checkSanity(
        state.pack,
        profile: state.profile,
        nutrientId: l.nutrientId,
        form: l.form,
        amount: l.labelAmount,
        unit: l.labelUnit,
        isCompound: l.isCompound,
      );

  Future<void> _editOrAddLine([int? index]) async {
    final pack = AppScope.of(context).pack;
    final initial = index == null ? EditableIngredient() : _lines[index];
    final edited = await showModalBottomSheet<EditableIngredient>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _EditIngredientSheet(pack: pack, initial: initial),
    );
    if (edited == null) return;
    setState(() {
      if (index == null) {
        _lines.add(edited);
      } else {
        _lines[index] = edited;
      }
    });
  }

  Future<void> _submit() async {
    if (!_allConfirmed || _saving) return;
    setState(() => _saving = true);
    try {
      final pack = AppScope.of(context).pack;
      final drafts = [for (final l in _lines) _toDraft(l, pack)];
      await widget.onConfirmed(context, drafts);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final pack = state.pack;
    final cs = Theme.of(context).colorScheme;
    final confirmedCount = _lines.where((l) => l.confirmed).length;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.editingProductId != null ? 'Sửa thành phần' : 'Xác nhận thành phần'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
        children: [
          Text(
            widget.editingProductId != null
                ? 'Thay đổi thành phần chỉ áp dụng cho lần uống mới.'
                : widget.fromDsld
                    ? 'Điền sẵn từ thư viện nhãn Mỹ (NIH DSLD). Kiểm tra lại trước khi lưu.'
                    : 'Kiểm tra và đánh dấu xác nhận từng dòng trước khi lưu.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          if (widget.fromDsld && _lines.isNotEmpty && !_allConfirmed && _allUnitCompatible) ...[
            const SizedBox(height: 12),
            FilledButton.tonalIcon(
              onPressed: _saving ? null : _confirmAllAndSubmit,
              icon: const Icon(Icons.done_all),
              label: Text('Xác nhận tất cả (${_lines.length})'),
            ),
          ] else if (!widget.fromDsld && _lines.length > 1 && _allUnitCompatible) ...[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: _saving ? null : () => _setAllConfirmed(!_allConfirmed),
                icon: Icon(_allConfirmed ? Icons.remove_done : Icons.done_all),
                label: Text(_allConfirmed ? 'Bỏ chọn tất cả' : 'Chọn tất cả (${_lines.length})'),
              ),
            ),
          ],
          const SizedBox(height: 12),
          if (_lines.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(child: Text('Chưa có dòng thành phần nào.')),
            ),
          for (var i = 0; i < _lines.length; i++) ...[
            _buildLineTile(i, _lines[i], state, pack, cs),
            const Divider(height: 1),
          ],
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _editOrAddLine,
            icon: const Icon(Icons.add),
            label: const Text('Thêm dòng thành phần'),
          ),
          if (widget.rawOcrLines.isNotEmpty) ...[
            const SizedBox(height: 12),
            ExpansionTile(
              title: Text('Chữ đã đọc từ ảnh (${widget.rawOcrLines.length} dòng)'),
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: SelectableText(widget.rawOcrLines.join('\n')),
                ),
              ],
            ),
          ],
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: FilledButton(
            onPressed: _allConfirmed && !_saving ? _submit : null,
            child: Text(
              widget.editingProductId != null
                  ? 'Lưu thành phần ($confirmedCount/${_lines.length})'
                  : 'Tiếp tục ($confirmedCount/${_lines.length} đã xác nhận)',
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLineTile(
    int index,
    EditableIngredient l,
    AppState state,
    ReferencePack pack,
    ColorScheme cs,
  ) {
    final def = l.nutrientId == null ? null : pack.nutrients[l.nutrientId!];
    final title = def?.nameVi ?? (l.freeName ?? 'Chưa chọn chất');
    final check = _sanity(l, state);
    final sanity = check.sanity;
    final unitBad = check.unitIncompatible;

    String subtitle = '';
    if (l.labelAmount != null) {
      subtitle = '${fmt(l.labelAmount!)} ${unitLabel(l.labelUnit.name)}';
      if (l.isCompound && l.nutrientId != null) {
        final meta = pack.compoundMeta[l.nutrientId!]?[l.form];
        if (meta != null) {
          final ratio = pack.compounds[l.nutrientId!]?[l.form];
          final elem = ratio == null ? null : l.labelAmount! * ratio;
          subtitle = elem != null
              ? '${meta.nameVi} · nhãn ${fmt(l.labelAmount!)} → nguyên tố ${fmt(elem)} ${unitLabel(def?.unit ?? 'mg')}'
              : '${meta.nameVi} · $subtitle';
        } else {
          subtitle = 'Chưa rõ dạng · $subtitle';
        }
      }
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Checkbox(
            value: !unitBad && l.confirmed,
            onChanged: !unitBad && (l.labelAmount ?? 0) > 0
                ? (v) => setState(() => l.confirmed = v ?? false)
                : null,
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleSmall),
                if (subtitle.isNotEmpty)
                  Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
                if (unitBad)
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: cs.errorContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '⚠ Đơn vị "${unitLabel(l.labelUnit.name)}" chưa phù hợp với chất này. Bấm Sửa để chọn lại.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: cs.onErrorContainer),
                    ),
                  )
                else if (sanity.hasWarning)
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: cs.secondaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '⚠ Số này khá lớn so với mức thông thường, hãy kiểm lại đơn vị mg/µg trên nhãn.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
              ],
            ),
          ),
          TextButton(
            onPressed: () => _editOrAddLine(index),
            child: const Text('Sửa'),
          ),
          IconButton(
            tooltip: 'Xóa dòng',
            icon: const Icon(Icons.delete_outline),
            onPressed: () => setState(() => _lines.removeAt(index)),
          ),
        ],
      ),
    );
  }
}

class _EditIngredientSheet extends StatefulWidget {
  final ReferencePack pack;
  final EditableIngredient initial;
  const _EditIngredientSheet({required this.pack, required this.initial});

  @override
  State<_EditIngredientSheet> createState() => _EditIngredientSheetState();
}

class _EditIngredientSheetState extends State<_EditIngredientSheet> {
  String? _nutrientId;
  bool _isFree = false;
  late TextEditingController _freeName;
  late TextEditingController _amountCtrl;
  late LabelUnit _unit;
  late String _form;
  late bool _isCompound;

  @override
  void initState() {
    super.initState();
    _nutrientId = widget.initial.nutrientId;
    _isFree = widget.initial.nutrientId == null && (widget.initial.freeName?.isNotEmpty ?? false);
    _freeName = TextEditingController(text: widget.initial.freeName ?? '');
    _amountCtrl = TextEditingController(
      text: widget.initial.labelAmount == null ? '' : '${widget.initial.labelAmount}',
    );
    _unit = widget.initial.labelUnit;
    _form = widget.initial.form;
    _isCompound = widget.initial.isCompound;
  }

  @override
  void dispose() {
    _freeName.dispose();
    _amountCtrl.dispose();
    super.dispose();
  }

  List<LabelUnit> _allowedUnitsFor(String? nid, bool isFree) {
    if (isFree || nid == null) {
      return const [LabelUnit.mg, LabelUnit.ug, LabelUnit.iu, LabelUnit.g];
    }
    return switch (nid) {
      'folate' => const [LabelUnit.ugDfe, LabelUnit.ug],
      'folicAcid' => const [LabelUnit.ug, LabelUnit.mg],
      'vitA' => const [LabelUnit.ugRae, LabelUnit.ug, LabelUnit.iu],
      'niacin' => const [LabelUnit.mgNe, LabelUnit.mg],
      'vitD' => const [LabelUnit.ug, LabelUnit.iu, LabelUnit.mg],
      'vitE' => const [LabelUnit.mg, LabelUnit.iu],
      _ => switch (widget.pack.nutrients[nid]?.unit) {
          'g' => const [LabelUnit.g, LabelUnit.mg],
          'ug' => const [LabelUnit.ug, LabelUnit.mg],
          _ => const [LabelUnit.mg, LabelUnit.ug, LabelUnit.g],
        },
    };
  }

  String _unitDisplay(LabelUnit u) => switch (u) {
        LabelUnit.mg => 'mg',
        LabelUnit.ug => 'µg',
        LabelUnit.iu => 'IU',
        LabelUnit.g => 'g',
        LabelUnit.ugDfe => 'µg DFE',
        LabelUnit.ugRae => 'µg RAE',
        LabelUnit.mgNe => 'mg NE',
      };

  @override
  Widget build(BuildContext context) {
    final nutrients = widget.pack.nutrients.values
        .where((d) => d.group != 'macro' && d.id != 'retinol')
        .toList();
    final compounds = _nutrientId == null ? null : widget.pack.compounds[_nutrientId!];
    final compoundMeta = _nutrientId == null ? null : widget.pack.compoundMeta[_nutrientId!];
    final allowedUnits = _allowedUnitsFor(_nutrientId, _isFree);
    if (!allowedUnits.contains(_unit)) {
      _unit = allowedUnits.first;
    }

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 8, 16, MediaQuery.of(context).viewInsets.bottom + 20),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Sửa dòng thành phần', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _isFree ? '__free__' : _nutrientId,
              decoration: const InputDecoration(labelText: 'Chất dinh dưỡng'),
              items: [
                for (final d in nutrients)
                  DropdownMenuItem(value: d.id, child: Text(d.nameVi)),
                const DropdownMenuItem(
                  value: '__free__',
                  child: Text('Chất khác (không tính giới hạn)'),
                ),
              ],
              onChanged: (v) {
                setState(() {
                  if (v == '__free__') {
                    _isFree = true;
                    _nutrientId = null;
                    _isCompound = false;
                    _form = NutrientForm.unknown;
                  } else {
                    _isFree = false;
                    _nutrientId = v;
                    _form = NutrientForm.unknown;
                    _isCompound = false;
                    final allowed = _allowedUnitsFor(_nutrientId, false);
                    if (!allowed.contains(_unit)) _unit = allowed.first;
                  }
                });
              },
            ),
            if (_isFree) ...[
              const SizedBox(height: 8),
              TextField(
                controller: _freeName,
                decoration: const InputDecoration(labelText: 'Tên chất (vd. Coenzyme Q10)'),
              ),
            ],
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _amountCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Lượng mỗi khẩu phần'),
                  ),
                ),
                const SizedBox(width: 12),
                DropdownButton<LabelUnit>(
                  value: _unit,
                  items: [
                    for (final u in allowedUnits)
                      DropdownMenuItem(value: u, child: Text(_unitDisplay(u))),
                  ],
                  onChanged: (u) {
                    if (u != null) setState(() => _unit = u);
                  },
                ),
              ],
            ),
            if (!_isFree && compounds != null && compounds.isNotEmpty) ...[
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: !_isCompound
                    ? '__elemental__'
                    : (compounds.containsKey(_form) ? _form : NutrientForm.unknown),
                decoration: const InputDecoration(labelText: 'Dạng trên nhãn'),
                items: [
                  const DropdownMenuItem(value: '__elemental__', child: Text('Nguyên tố (elemental)')),
                  for (final fid in compounds.keys)
                    DropdownMenuItem(
                      value: fid,
                      child: Text(compoundMeta?[fid]?.nameVi ?? fid),
                    ),
                  const DropdownMenuItem(
                    value: NutrientForm.unknown,
                    child: Text('Chưa rõ dạng (tính thận trọng)'),
                  ),
                ],
                onChanged: (v) {
                  setState(() {
                    if (v == '__elemental__' || v == null) {
                      _isCompound = false;
                      _form = NutrientForm.unknown;
                    } else {
                      _isCompound = true;
                      _form = v;
                    }
                  });
                },
              ),
            ],
            if (!_isFree && _nutrientId == 'vitE') ...[
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: _form == NutrientForm.natural2r || _form == NutrientForm.synthetic2r
                    ? _form
                    : NutrientForm.unknown,
                decoration: const InputDecoration(labelText: 'Dạng vitamin E'),
                items: const [
                  DropdownMenuItem(value: NutrientForm.natural2r, child: Text('Tự nhiên (d-alpha)')),
                  DropdownMenuItem(value: NutrientForm.synthetic2r, child: Text('Tổng hợp (dl-alpha)')),
                  DropdownMenuItem(value: NutrientForm.unknown, child: Text('Chưa rõ dạng')),
                ],
                onChanged: (v) => setState(() => _form = v ?? NutrientForm.unknown),
              ),
            ],
            if (!_isFree && _nutrientId == 'vitA') ...[
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: _form == NutrientForm.retinol || _form == NutrientForm.betaCarotene
                    ? _form
                    : NutrientForm.unknown,
                decoration: const InputDecoration(labelText: 'Dạng vitamin A'),
                items: const [
                  DropdownMenuItem(value: NutrientForm.retinol, child: Text('Retinol / Retinyl (tính giới hạn)')),
                  DropdownMenuItem(value: NutrientForm.betaCarotene, child: Text('Beta-caroten (không tính giới hạn)')),
                  DropdownMenuItem(value: NutrientForm.unknown, child: Text('Chưa rõ dạng')),
                ],
                onChanged: (v) => setState(() => _form = v ?? NutrientForm.unknown),
              ),
            ],
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () {
                final amt = double.tryParse(_amountCtrl.text.trim().replaceAll(',', '.'));
                if (amt == null || !amt.isFinite || amt <= 0) return;
                if (!_isFree && _nutrientId == null) return;
                if (_isFree && _freeName.text.trim().isEmpty) return;
                if (!_isFree) {
                  final ok = SupplementIngredientHelper.isUnitCompatible(
                    widget.pack,
                    nutrientId: _nutrientId,
                    form: _form,
                    amount: amt,
                    unit: _unit,
                    isCompound: _isCompound,
                  );
                  if (!ok) {
                    AppFeedback.showSnack(context, 'Đơn vị này không phù hợp với chất đã chọn.');
                    return;
                  }
                }
                Navigator.pop(
                  context,
                  EditableIngredient(
                    nutrientId: _isFree ? null : _nutrientId,
                    freeName: _isFree ? _freeName.text.trim() : null,
                    form: _form,
                    labelAmount: amt,
                    labelUnit: _unit,
                    isCompound: _isCompound,
                    origin: widget.initial.origin,
                    confirmed: true,
                  ),
                );
              },
              child: const Text('Xác nhận dòng này'),
            ),
          ],
        ),
      ),
    );
  }
}
