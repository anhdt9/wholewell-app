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

  /// `null` khi chưa biết đơn vị: người dùng phải chọn theo nhãn trước khi xác nhận.
  LabelUnit? labelUnit;
  bool isCompound;
  IngredientOrigin origin;
  bool confirmed;

  /// Dòng AI chưa khớp chữ đọc từ ảnh; tắt khi người dùng xác nhận qua bảng sửa dòng.
  bool needsCheck;

  EditableIngredient({
    this.nutrientId,
    this.freeName,
    this.form = NutrientForm.unknown,
    this.labelAmount,
    this.labelUnit,
    this.isCompound = false,
    this.origin = IngredientOrigin.manual,
    this.confirmed = false,
    this.needsCheck = false,
  });

  factory EditableIngredient.fromParsed(ParsedIngredientLine p) {
    return EditableIngredient(
      nutrientId: p.nutrientId,
      freeName: p.freeName,
      form: p.form,
      labelAmount: p.amount,
      labelUnit: p.unit,
      isCompound: p.compoundKind != CompoundKind.elemental,
      origin: IngredientOrigin.ocr,
      confirmed: false,
      needsCheck: p.needsCheck,
    );
  }

  factory EditableIngredient.fromSaved(ProductIngredient i) {
    final unit = LabelUnit.values.where((u) => u.name == i.labelUnit).firstOrNull;
    return EditableIngredient(
      nutrientId: i.nutrientId,
      freeName: i.freeName,
      form: i.form,
      labelAmount: i.labelAmount,
      labelUnit: unit,
      isCompound: i.isCompound,
      origin: i.origin,
      confirmed: unit != null && i.confirmed,
    );
  }
}

/// Lý do một dòng phải kiểm qua bảng sửa dòng, theo thứ tự ưu tiên hiển thị.
enum _ReviewReason { noAmount, noUnit, unitIncompatible, notOnImage }

class ConfirmIngredientsScreen extends StatefulWidget {
  final List<EditableIngredient> initialLines;
  final List<String> rawOcrLines;
  final String? scannedBarcode;
  final int? editingProductId;
  final bool fromDsld;

  /// Danh sách có gợi ý của AI trên máy: hiện dòng ghi chú ở đầu màn.
  final bool showAiNote;
  final Future<void> Function(BuildContext ctx, List<IngredientDraft> drafts) onConfirmed;

  const ConfirmIngredientsScreen({
    super.key,
    required this.initialLines,
    this.rawOcrLines = const [],
    this.scannedBarcode,
    this.editingProductId,
    this.fromDsld = false,
    this.showAiNote = false,
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

  _ReviewReason? _reviewReason(EditableIngredient l, ReferencePack pack) {
    final amount = l.labelAmount;
    if (amount == null || !amount.isFinite || amount <= 0) return _ReviewReason.noAmount;
    final unit = l.labelUnit;
    if (unit == null) return _ReviewReason.noUnit;
    final compatible = SupplementIngredientHelper.isUnitCompatible(
      pack,
      nutrientId: l.nutrientId,
      form: l.form,
      amount: amount,
      unit: unit,
      isCompound: l.isCompound,
    );
    if (!compatible) return _ReviewReason.unitIncompatible;
    if (l.needsCheck) return _ReviewReason.notOnImage;
    return null;
  }

  int _reviewCount(ReferencePack pack) => _lines.where((l) => _reviewReason(l, pack) != null).length;

  void _setAllConfirmed(bool value) {
    final pack = AppScope.of(context).pack;
    setState(() {
      for (final l in _lines) {
        if (!value) {
          l.confirmed = false;
        } else if (_reviewReason(l, pack) == null) {
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
    return _lines.every((l) => l.confirmed && _reviewReason(l, pack) == null);
  }

  IngredientDraft _toDraft(EditableIngredient l, ReferencePack pack) =>
      SupplementIngredientHelper.toDraft(
        pack,
        nutrientId: l.nutrientId,
        freeName: l.freeName,
        form: l.form,
        labelAmount: l.labelAmount,
        // `_allConfirmed` bảo đảm mọi dòng đã có đơn vị trước khi gửi.
        labelUnit: l.labelUnit!,
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
    final edited = await showAppModalSheet<EditableIngredient>(
      context: context,
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

  Widget _note(String text, {bool error = false}) {
    final cs = Theme.of(context).colorScheme;
    final ww = context.wwColors;
    final t = Theme.of(context).textTheme;
    return Container(
      margin: const EdgeInsets.only(top: AppSpacing.xs),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
      decoration: BoxDecoration(
        color: error ? cs.errorContainer : ww.warningContainer,
        borderRadius: AppRadius.controlRadius,
        border: error ? null : Border.all(color: ww.warningBorder),
      ),
      child: Text(
        '⚠ $text',
        style: t.bodySmall?.copyWith(color: error ? cs.onErrorContainer : ww.onWarningContainer),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final pack = state.pack;
    final cs = Theme.of(context).colorScheme;
    final confirmedCount = _lines.where((l) => l.confirmed).length;
    final reviewCount = _reviewCount(pack);

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
          if (widget.showAiNote) ...[
            const SizedBox(height: AppSpacing.sm),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(LucideIcons.info, size: 18, color: cs.onSurfaceVariant),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    'Gợi ý do AI trên máy tách từ chữ trên ảnh. Hãy so từng số với nhãn.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
          ],
          if (reviewCount > 0) ...[
            const SizedBox(height: AppSpacing.sm),
            _note('Còn $reviewCount dòng cần kiểm. Bấm Sửa ở từng dòng.'),
          ] else if (widget.fromDsld && _lines.isNotEmpty && !_allConfirmed) ...[
            const SizedBox(height: 12),
            FilledButton.tonalIcon(
              onPressed: _saving ? null : _confirmAllAndSubmit,
              icon: const Icon(LucideIcons.checkCheck),
              label: Text('Xác nhận tất cả (${_lines.length})'),
            ),
          ] else if (!widget.fromDsld && _lines.length > 1) ...[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: _saving ? null : () => _setAllConfirmed(!_allConfirmed),
                icon: Icon(_allConfirmed ? LucideIcons.circleX : LucideIcons.checkCheck),
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
            _buildLineTile(i, _lines[i], state, pack),
            const Divider(height: 1),
          ],
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _editOrAddLine,
            icon: const Icon(LucideIcons.plus),
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
  ) {
    final t = Theme.of(context).textTheme;
    final def = l.nutrientId == null ? null : pack.nutrients[l.nutrientId!];
    final title = def?.nameVi ?? (l.freeName ?? 'Chưa chọn chất');
    final reason = _reviewReason(l, pack);
    final sanity = reason == null ? _sanity(l, state).sanity : null;
    final unit = l.labelUnit;

    String subtitle = '';
    final amount = l.labelAmount;
    if (amount != null) {
      if (unit == null) {
        subtitle = '${fmt(amount)} · Chưa rõ đơn vị';
      } else {
        subtitle = '${fmt(amount)} ${unitLabel(unit.name)}';
        if (l.isCompound && l.nutrientId != null) {
          final meta = pack.compoundMeta[l.nutrientId!]?[l.form];
          if (meta != null && def != null) {
            final ratio = pack.compounds[l.nutrientId!]?[l.form];
            final elem = ratio == null ? null : amount * ratio;
            subtitle = elem != null
                ? '${meta.nameVi} · nhãn ${fmt(amount)} → nguyên tố ${fmt(elem)} ${unitLabel(def.unit)}'
                : '${meta.nameVi} · $subtitle';
          } else {
            subtitle = 'Chưa rõ dạng · $subtitle';
          }
        }
      }
    }

    final Widget? note = switch (reason) {
      _ReviewReason.noAmount => _note('Chưa có lượng. Bấm Sửa và nhập theo nhãn.'),
      _ReviewReason.noUnit => _note('Chưa đọc được đơn vị. Bấm Sửa và chọn đơn vị theo nhãn.'),
      _ReviewReason.unitIncompatible => _note(
          'Đơn vị "${unitLabel(unit!.name)}" chưa phù hợp với chất này. Bấm Sửa để chọn lại.',
          error: true,
        ),
      _ReviewReason.notOnImage =>
        _note('Chưa thấy số này trong chữ đọc từ ảnh. Bấm Sửa để so với nhãn.'),
      null => (sanity?.hasWarning ?? false)
          ? _note('Số này khá lớn so với mức thông thường, hãy kiểm lại đơn vị mg/µg trên nhãn.')
          : null,
    };

    final checkbox = Checkbox(
      value: reason == null && l.confirmed,
      onChanged: reason == null ? (v) => setState(() => l.confirmed = v ?? false) : null,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (reason == null)
            checkbox
          else
            Semantics(label: 'Cần kiểm, bấm Sửa', child: checkbox),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: t.titleSmall),
                if (subtitle.isNotEmpty) Text(subtitle, style: tabularNumberStyle(t.bodySmall)),
                ?note,
              ],
            ),
          ),
          TextButton(
            onPressed: () => _editOrAddLine(index),
            child: const Text('Sửa'),
          ),
          IconButton(
            tooltip: 'Xóa dòng',
            icon: const Icon(LucideIcons.trash2),
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
  LabelUnit? _unit;
  late String _form;
  late bool _isCompound;
  String? _amountError;
  String? _unitError;

  @override
  void initState() {
    super.initState();
    _nutrientId = widget.initial.nutrientId;
    _isFree = widget.initial.nutrientId == null && (widget.initial.freeName?.isNotEmpty ?? false);
    _freeName = TextEditingController(text: widget.initial.freeName ?? '');
    _amountCtrl = TextEditingController(
      text: widget.initial.labelAmount == null ? '' : '${widget.initial.labelAmount}',
    );
    final unit = widget.initial.labelUnit;
    // Đơn vị không hợp với chất thì để trống cho người dùng chọn, không tự đổi sang đơn vị khác.
    _unit = unit != null && _allowedUnitsFor(_nutrientId, _isFree).contains(unit) ? unit : null;
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

  void _dropUnitIfNotAllowed() {
    final unit = _unit;
    if (unit != null && !_allowedUnitsFor(_nutrientId, _isFree).contains(unit)) {
      _unit = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final nutrients = widget.pack.nutrients.values
        .where((d) => d.group != 'macro' && d.id != 'retinol')
        .toList();
    final compounds = _nutrientId == null ? null : widget.pack.compounds[_nutrientId!];
    final compoundMeta = _nutrientId == null ? null : widget.pack.compoundMeta[_nutrientId!];
    final allowedUnits = _allowedUnitsFor(_nutrientId, _isFree);
    final ww = context.wwColors;
    final t = Theme.of(context).textTheme;

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.85,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.md),
            child: Text('Sửa dòng thành phần', style: t.titleMedium),
          ),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (widget.initial.needsCheck) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: AppSpacing.xs,
                      ),
                      decoration: BoxDecoration(
                        color: ww.warningContainer,
                        borderRadius: AppRadius.controlRadius,
                        border: Border.all(color: ww.warningBorder),
                      ),
                      child: Text(
                        '⚠ Chưa thấy số này trong chữ đọc từ ảnh. So số và đơn vị với nhãn rồi bấm Xác nhận dòng này.',
                        style: t.bodySmall?.copyWith(color: ww.onWarningContainer),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                  ],
                  DropdownButtonFormField<String>(
                    isExpanded: true,
                    initialValue: _isFree ? '__free__' : _nutrientId,
                    decoration: const InputDecoration(labelText: 'Chất dinh dưỡng'),
                    items: [
                      for (final d in nutrients)
                        DropdownMenuItem(
                          value: d.id,
                          child: Text(d.nameVi, overflow: TextOverflow.ellipsis),
                        ),
                      const DropdownMenuItem(
                        value: '__free__',
                        child: Text('Chất khác (không tính giới hạn)', overflow: TextOverflow.ellipsis),
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
                        }
                        _dropUnitIfNotAllowed();
                      });
                    },
                  ),
                  if (_isFree) ...[
                    const SizedBox(height: AppSpacing.md),
                    TextField(
                      controller: _freeName,
                      decoration: const InputDecoration(labelText: 'Tên chất (vd. Coenzyme Q10)'),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 3,
                        child: TextField(
                          controller: _amountCtrl,
                          style: tabularNumberStyle(null),
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: InputDecoration(
                            labelText: 'Lượng mỗi khẩu phần',
                            errorText: _amountError,
                            errorMaxLines: 3,
                          ),
                          onChanged: (_) {
                            if (_amountError != null) setState(() => _amountError = null);
                          },
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        flex: 2,
                        child: InputDecorator(
                          decoration: InputDecoration(
                            labelText: 'Đơn vị',
                            floatingLabelBehavior: FloatingLabelBehavior.always,
                            errorText: _unitError,
                            errorMaxLines: 3,
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<LabelUnit>(
                              value: _unit,
                              isExpanded: true,
                              isDense: true,
                              hint: const Text('Chọn'),
                              items: [
                                for (final u in allowedUnits)
                                  DropdownMenuItem(value: u, child: Text(_unitDisplay(u))),
                              ],
                              onChanged: (u) {
                                if (u != null) {
                                  setState(() {
                                    _unit = u;
                                    _unitError = null;
                                  });
                                }
                              },
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (!_isFree && compounds != null && compounds.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.md),
                    DropdownButtonFormField<String>(
                      isExpanded: true,
                      initialValue: !_isCompound
                          ? '__elemental__'
                          : (compounds.containsKey(_form) ? _form : NutrientForm.unknown),
                      decoration: const InputDecoration(labelText: 'Dạng trên nhãn'),
                      items: [
                        const DropdownMenuItem(value: '__elemental__', child: Text('Nguyên tố (elemental)')),
                        for (final fid in compounds.keys)
                          DropdownMenuItem(
                            value: fid,
                            child: Text(compoundMeta?[fid]?.nameVi ?? fid, overflow: TextOverflow.ellipsis),
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
                    const SizedBox(height: AppSpacing.md),
                    DropdownButtonFormField<String>(
                      isExpanded: true,
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
                    const SizedBox(height: AppSpacing.md),
                    DropdownButtonFormField<String>(
                      isExpanded: true,
                      initialValue: _form == NutrientForm.retinol || _form == NutrientForm.betaCarotene
                          ? _form
                          : NutrientForm.unknown,
                      decoration: const InputDecoration(labelText: 'Dạng vitamin A'),
                      items: const [
                        DropdownMenuItem(
                          value: NutrientForm.retinol,
                          child: Text('Retinol / Retinyl (tính giới hạn)'),
                        ),
                        DropdownMenuItem(
                          value: NutrientForm.betaCarotene,
                          child: Text('Beta-caroten (không tính giới hạn)'),
                        ),
                        DropdownMenuItem(value: NutrientForm.unknown, child: Text('Chưa rõ dạng')),
                      ],
                      onChanged: (v) => setState(() => _form = v ?? NutrientForm.unknown),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.lg),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.lg),
            child: SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton(
                onPressed: _submitLine,
                child: const Text('Xác nhận dòng này'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _submitLine() {
    final amt = double.tryParse(_amountCtrl.text.trim().replaceAll(',', '.'));
    final amountOk = amt != null && amt.isFinite && amt > 0;
    final unit = _unit;
    setState(() {
      _amountError = amountOk ? null : 'Nhập lượng lớn hơn 0.';
      _unitError = unit == null ? 'Chọn đơn vị theo nhãn.' : null;
    });
    if (!amountOk || unit == null) return;
    if (!_isFree && _nutrientId == null) return;
    if (_isFree && _freeName.text.trim().isEmpty) return;
    if (!_isFree) {
      final ok = SupplementIngredientHelper.isUnitCompatible(
        widget.pack,
        nutrientId: _nutrientId,
        form: _form,
        amount: amt,
        unit: unit,
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
        labelUnit: unit,
        isCompound: _isCompound,
        origin: widget.initial.origin,
        confirmed: true,
      ),
    );
  }
}
