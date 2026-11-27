/// Màn Chọn khẩu phần cho món từ thư viện hoặc Món bạn đã lưu.
library;

import 'package:material_ui/material_ui.dart';
import 'package:food_library/food_library.dart';
import 'package:journal_db/journal_db.dart';

import '../state/app_scope.dart';
import '../state/diary_controller.dart';
import '../state/label_food_builder.dart';
import 'common/common_widgets.dart';
import 'common/food_feedback_sheet.dart';
import 'labels.dart';

class FoodPortionScreen extends StatefulWidget {
  final FoodDetail? libraryFood;
  final CustomFood? customFood;
  final Meal initialMeal;
  final DateTime initialAt;

  const FoodPortionScreen.library({
    super.key,
    required FoodDetail food,
    required this.initialMeal,
    required this.initialAt,
  })  : libraryFood = food,
        customFood = null;

  const FoodPortionScreen.custom({
    super.key,
    required CustomFood custom,
    required this.initialMeal,
    required this.initialAt,
  })  : customFood = custom,
        libraryFood = null;

  @override
  State<FoodPortionScreen> createState() => _FoodPortionScreenState();
}

class _FoodPortionScreenState extends State<FoodPortionScreen> {
  static const _gramId = '__gram__';
  String _selectedUnitId = _gramId;
  late double _qty;
  late final TextEditingController _qtyCtrl;
  bool _saving = false;

  bool get _isCustom => widget.customFood != null;

  @override
  void initState() {
    super.initState();
    final lib = widget.libraryFood;
    final cus = widget.customFood;
    if (cus != null) {
      _selectedUnitId = cus.labelBasisUnit;
      _qty = cus.labelBasisQty;
    } else if (lib != null) {
      final def = lib.defaultPortion;
      if (def != null) {
        _selectedUnitId = def.id;
        _qty = 1;
      } else {
        _selectedUnitId = _gramId;
        _qty = 100;
      }
    } else {
      _qty = 100;
    }
    _qtyCtrl = TextEditingController(text: _formatInput(_qty));
  }

  @override
  void dispose() {
    _qtyCtrl.dispose();
    super.dispose();
  }

  static String _formatInput(double v) => fmt(v);

  FoodPortion? get _currentPortion {
    final lib = widget.libraryFood;
    if (lib == null || _selectedUnitId == _gramId) return null;
    for (final p in lib.portions) {
      if (p.id == _selectedUnitId) return p;
    }
    return null;
  }

  String get _unitLabel {
    if (_isCustom) return widget.customFood!.labelBasisUnit;
    return _currentPortion?.labelVi ?? 'Gram';
  }

  double get _grams {
    final p = _currentPortion;
    return p == null ? _qty : _qty * p.grams;
  }

  void _selectUnit(String id) {
    setState(() {
      _selectedUnitId = id;
      _qty = id == _gramId ? 100 : 1;
      _qtyCtrl.text = _formatInput(_qty);
    });
  }

  void _stepQty(int dir) {
    final cus = widget.customFood;
    double next;
    if (_isCustom && cus != null) {
      final u = cus.labelBasisUnit.toLowerCase();
      final isWeightOrVol = u == 'g' || u == 'gram' || u == 'ml';
      if (isWeightOrVol) {
        if (dir > 0) {
          next = _qty < 100 ? _qty + 10 : _qty + 50;
        } else {
          next = _qty > 100 ? (_qty - 50).clamp(100, double.infinity) : (_qty - 10).clamp(10, double.infinity);
        }
      } else {
        final step = cus.labelBasisQty < 5 ? 0.5 : 1.0;
        next = (_qty + dir * step).clamp(step, double.infinity);
      }
    } else if (_selectedUnitId == _gramId) {
      if (dir > 0) {
        next = _qty < 100 ? _qty + 10 : _qty + 50;
      } else {
        if (_qty > 100) {
          next = (_qty - 50) < 100 ? 100 : _qty - 50;
        } else {
          next = (_qty - 10) < 10 ? 10 : _qty - 10;
        }
      }
    } else {
      next = (_qty + dir * 0.5) < 0.5 ? 0.5 : _qty + dir * 0.5;
    }
    setState(() {
      _qty = next;
      _qtyCtrl.text = _formatInput(_qty);
    });
  }

  void _onQtyTextChanged(String raw) {
    final parsed = double.tryParse(raw.trim().replaceAll(',', '.'));
    setState(() {
      _qty = (parsed != null && parsed.isFinite && parsed > 0) ? parsed : 0;
    });
  }

  Future<void> _save() async {
    if (_saving || _qty <= 0) return;
    setState(() => _saving = true);
    final state = AppScope.of(context);
    final diary = state.diary;

    late final FoodLogFeedback fb;
    try {
      if (_isCustom) {
        fb = await diary.recordCustomFood(
          widget.customFood!,
          usedQty: _qty,
          meal: widget.initialMeal,
          at: widget.initialAt,
        );
      } else {
        fb = await diary.recordLibraryFood(
          food: widget.libraryFood!,
          portionUnit: _unitLabel,
          portionQty: _qty,
          grams: _grams,
          meal: widget.initialMeal,
          at: widget.initialAt,
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }

    if (!mounted) return;

    if (fb.failed) {
      await presentFoodFeedback(context, feedback: fb, pack: state.pack);
      return;
    }

    // Đóng màn Chọn khẩu phần và Ghi món về màn trước, rồi hiện đúng 1 phản hồi.
    final nav = Navigator.of(context);
    nav.pop(fb);
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final t = Theme.of(context).textTheme;
    final lib = widget.libraryFood;
    final cus = widget.customFood;
    final title = lib?.nameVi ?? cus!.name;

    // Tính tóm tắt dinh dưỡng tức thì theo khẩu phần hiện tại.
    double kcal = 0;
    double protein = 0;
    double fat = 0;
    double carb = 0;
    double addedSugar = 0;
    double? totalSugar;
    bool sugarKnown;

    if (cus != null) {
      sugarKnown = cus.addedSugarKnown;
      final input = LabelFoodBuilder.entryFromCustomFood(
        cus,
        usedQty: _qty,
        meal: widget.initialMeal,
        at: widget.initialAt,
        pack: state.pack,
      );
      for (final l in input.lines) {
        kcal += l.amounts['energyKcal'] ?? 0;
        protein += l.amounts['protein'] ?? 0;
        fat += l.amounts['fat'] ?? 0;
        carb += l.amounts['carbohydrate'] ?? 0;
        addedSugar += l.amounts['addedSugar'] ?? 0;
      }
      for (final cl in cus.lines) {
        if (cl.nutrientId == 'totalSugar') {
          totalSugar = (totalSugar ?? 0) + cl.labelAmount * (_qty / cus.labelBasisQty);
        }
      }
    } else {
      final f = lib!;
      sugarKnown = f.addedSugarKnown;
      final lines = state.foodLibrary?.computeLines(f, _grams, pack: state.pack) ??
          computeFoodIntakeLines(f, _grams, pack: state.pack);
      for (final l in lines) {
        kcal += l.amounts['energyKcal'] ?? 0;
        protein += l.amounts['protein'] ?? 0;
        fat += l.amounts['fat'] ?? 0;
        carb += l.amounts['carbohydrate'] ?? 0;
        addedSugar += l.amounts['addedSugar'] ?? 0;
      }
      final rawTs = f.displayAmountPer100g('totalSugar');
      if (rawTs != null) totalSugar = rawTs * (_grams / 100.0);
    }

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Wrap(
                  spacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(title, style: t.titleLarge),
                    if (lib != null && lib.isEstimate) const EstimateChip(),
                    if (_isCustom) const EstimateChip(label: 'tự nhập'),
                  ],
                ),
                if (lib?.nameEn != null && lib!.nameEn!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(lib.nameEn!, style: t.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
                ],
                const SizedBox(height: 16),
                Text('Khẩu phần', style: t.titleSmall),
                const SizedBox(height: 8),
                if (_isCustom)
                  Wrap(
                    spacing: 8,
                    children: [
                      ChoiceChip(
                        label: Text(cus!.labelBasisUnit),
                        selected: true,
                        onSelected: (_) {},
                      ),
                    ],
                  )
                else
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final p in lib!.portions)
                        ChoiceChip(
                          label: Text(p.labelVi),
                          selected: _selectedUnitId == p.id,
                          onSelected: (_) => _selectUnit(p.id),
                        ),
                      ChoiceChip(
                        label: const Text('Gram'),
                        selected: _selectedUnitId == _gramId,
                        onSelected: (_) => _selectUnit(_gramId),
                      ),
                    ],
                  ),
                const SizedBox(height: 16),
                Text('Số lượng', style: t.titleSmall),
                const SizedBox(height: 8),
                Row(
                  children: [
                    SizedBox(
                      width: 48,
                      height: 48,
                      child: OutlinedButton(
                        onPressed: () => _stepQty(-1),
                        style: OutlinedButton.styleFrom(padding: EdgeInsets.zero),
                        child: const Icon(Icons.remove),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _qtyCtrl,
                        textAlign: TextAlign.center,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: InputDecoration(
                          border: const OutlineInputBorder(),
                          suffixText: _isCustom || _selectedUnitId == _gramId ? _unitLabel : null,
                        ),
                        onChanged: _onQtyTextChanged,
                      ),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      width: 48,
                      height: 48,
                      child: OutlinedButton(
                        onPressed: () => _stepQty(1),
                        style: OutlinedButton.styleFrom(padding: EdgeInsets.zero),
                        child: const Icon(Icons.add),
                      ),
                    ),
                  ],
                ),
                if (!_isCustom && _selectedUnitId != _gramId) ...[
                  const SizedBox(height: 6),
                  Text('(= ${fmt(_grams)} g)', style: t.bodySmall),
                ],
                const SizedBox(height: 20),
                CalorieText(
                  kcal,
                  prefix: 'Khoảng ',
                  suffix: ' kcal',
                  style: t.titleMedium,
                ),
                const SizedBox(height: 6),
                Text(
                  'Đạm ${fmt(protein)} g · Béo ${fmt(fat)} g · Bột đường ${fmt(carb)} g',
                  style: t.bodyMedium,
                ),
                const SizedBox(height: 4),
                if (sugarKnown)
                  Text('Đường bổ sung: ${fmt(addedSugar)} g', style: t.bodyMedium),
                if (totalSugar != null && (!sugarKnown || (totalSugar - addedSugar).abs() > 0.05))
                  Text('Đường tổng: ${fmt(totalSugar)} g', style: t.bodySmall),
                if (!sugarKnown) ...[
                  const SizedBox(height: 12),
                  const SafetyNote(message: 'Chưa rõ đường bổ sung (nguồn dữ liệu không tách riêng).'),
                ],
                if (lib != null && lib.folateUnseparated) ...[
                  const SizedBox(height: 8),
                  const SafetyNote(message: 'Folate tổng, chưa tách riêng phần tăng cường.'),
                ],
                if (lib != null && lib.niacinFortifiedUnseparated) ...[
                  const SizedBox(height: 8),
                  const SafetyNote(message: 'Niacin tăng cường chưa tách riêng khỏi thực phẩm.'),
                ],
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
                  onPressed: _saving || _qty <= 0 ? null : _save,
                  child: _saving
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Lưu'),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
