/// Màn Sửa mục cho món ăn đã ghi (khẩu phần, bữa, ngày, giờ, xóa).
library;

import 'package:material_ui/material_ui.dart';
import 'package:food_library/food_library.dart';
import 'package:journal_db/journal_db.dart';

import '../state/app_scope.dart';
import '../state/diary_controller.dart';
import 'common/common_widgets.dart';
import 'labels.dart';

class EditFoodScreen extends StatefulWidget {
  final FoodEntry entry;
  const EditFoodScreen({super.key, required this.entry});

  @override
  State<EditFoodScreen> createState() => _EditFoodScreenState();
}

class _EditFoodScreenState extends State<EditFoodScreen> {
  static const _gramLabel = 'Gram';

  FoodDetail? _libraryDetail;
  bool _loadingLibrary = false;
  bool _missingFromLibrary = false;

  late String _unitLabel;
  late double _qty;
  late final TextEditingController _qtyCtrl;
  late Meal _meal;
  late DateTime _at;
  bool _saving = false;

  bool get _isLabelFood => widget.entry.labelBasisQty != null;

  @override
  void initState() {
    super.initState();
    _unitLabel = widget.entry.portionUnit;
    _qty = widget.entry.portionQty;
    _qtyCtrl = TextEditingController(text: fmt(_qty));
    _meal = widget.entry.meal;
    _at = widget.entry.at;

    final ref = widget.entry.foodRef;
    if (!_isLabelFood && ref != null && !ref.startsWith('custom:')) {
      _loadingLibrary = true;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_loadingLibrary) {
      _loadLibraryFood();
    }
  }

  Future<void> _loadLibraryFood() async {
    _loadingLibrary = false;
    final ref = widget.entry.foodRef;
    if (ref == null) return;
    final detail = await AppScope.of(context).diary.getLibraryFood(ref);
    if (!mounted) return;
    setState(() {
      _libraryDetail = detail;
      _missingFromLibrary = detail == null;
    });
  }

  @override
  void dispose() {
    _qtyCtrl.dispose();
    super.dispose();
  }

  double get _currentKcal {
    final baseKcal = widget.entry.lines.fold<double>(0, (s, l) => s + (l.amounts['energyKcal'] ?? 0));
    final detail = _libraryDetail;
    if (detail != null) {
      final grams = _selectedGrams(detail);
      if (grams != null) {
        final per100 = detail.displayAmountPer100g('energyKcal') ?? 0;
        return per100 * (grams / 100.0);
      }
    }
    return baseKcal * (_qty / widget.entry.portionQty);
  }

  double? _selectedGrams(FoodDetail detail) {
    if (_unitLabel.toLowerCase() == 'gram' || _unitLabel.toLowerCase() == 'g') return _qty;
    for (final p in detail.portions) {
      if (p.labelVi == _unitLabel) return _qty * p.grams;
    }
    return null;
  }

  void _stepQty(int dir) {
    final isGram = _unitLabel.toLowerCase() == 'gram' || _unitLabel.toLowerCase() == 'g' || _unitLabel.toLowerCase() == 'ml';
    double next;
    if (isGram) {
      if (dir > 0) {
        next = _qty < 100 ? _qty + 10 : _qty + 50;
      } else if (_qty > 100) {
        next = (_qty - 50) < 100 ? 100 : _qty - 50;
      } else {
        next = (_qty - 10) < 10 ? 10 : _qty - 10;
      }
    } else {
      next = (_qty + dir * 0.5) < 0.5 ? 0.5 : _qty + dir * 0.5;
    }
    setState(() {
      _qty = next;
      _qtyCtrl.text = fmt(_qty);
    });
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _at.isAfter(now) ? now : _at,
      firstDate: DateTime(2020),
      lastDate: now,
    );
    if (picked != null && mounted) {
      setState(() {
        _at = DateTime(picked.year, picked.month, picked.day, _at.hour, _at.minute);
      });
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: _at.hour, minute: _at.minute),
    );
    if (picked != null && mounted) {
      setState(() {
        _at = DateTime(_at.year, _at.month, _at.day, picked.hour, picked.minute);
      });
    }
  }

  Future<void> _save() async {
    if (_saving || _qty <= 0) return;
    setState(() => _saving = true);
    final diary = AppScope.of(context).diary;
    final fb = await diary.updateLoggedFood(
      widget.entry,
      newQty: _qty,
      newPortionUnit: _unitLabel,
      newGramsIfLibrary: _libraryDetail == null ? null : _selectedGrams(_libraryDetail!),
      newMeal: _meal,
      newAt: _at,
    );
    if (!mounted) return;
    setState(() => _saving = false);
    Navigator.of(context).pop(fb);
  }

  Future<void> _confirmDelete() async {
    final cs = Theme.of(context).colorScheme;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Xóa “${widget.entry.name}” khỏi nhật ký?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: cs.error),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    await AppScope.of(context).diary.deleteFoodEntry(widget.entry.id);
    if (!mounted) return;
    Navigator.of(context).pop(FoodLogFeedback(summaryText: 'Đã xóa ${widget.entry.name}'));
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    final detail = _libraryDetail;

    return Scaffold(
      appBar: AppBar(title: Text(widget.entry.name)),
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
                    Text(widget.entry.name, style: t.titleLarge),
                    if (detail?.isEstimate ?? (widget.entry.foodRef?.startsWith('recipe:') ?? false))
                      const EstimateChip(),
                  ],
                ),
                const SizedBox(height: 16),
                Text('Khẩu phần', style: t.titleSmall),
                const SizedBox(height: 8),
                if (detail != null)
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final p in detail.portions)
                        ChoiceChip(
                          label: Text(p.labelVi),
                          selected: _unitLabel == p.labelVi,
                          onSelected: (_) => setState(() {
                            _unitLabel = p.labelVi;
                            _qty = 1;
                            _qtyCtrl.text = fmt(_qty);
                          }),
                        ),
                      ChoiceChip(
                        label: const Text(_gramLabel),
                        selected: _unitLabel.toLowerCase() == 'gram',
                        onSelected: (_) => setState(() {
                          _unitLabel = _gramLabel;
                          _qty = 100;
                          _qtyCtrl.text = fmt(_qty);
                        }),
                      ),
                    ],
                  )
                else
                  Wrap(
                    spacing: 8,
                    children: [
                      ChoiceChip(label: Text(_unitLabel), selected: true, onSelected: (_) {}),
                    ],
                  ),
                const SizedBox(height: 12),
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
                          suffixText: _unitLabel,
                        ),
                        onChanged: (raw) {
                          final v = double.tryParse(raw.trim().replaceAll(',', '.'));
                          if (v != null && v > 0) setState(() => _qty = v);
                        },
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
                const SizedBox(height: 8),
                CalorieText(_currentKcal, prefix: 'Khoảng ', suffix: ' kcal', style: t.titleMedium),
                if (_missingFromLibrary) ...[
                  const SizedBox(height: 12),
                  const SafetyNote(
                    message: 'Món không còn trong thư viện hiện tại; chỉnh số lượng sẽ nhân theo tỷ lệ cũ.',
                  ),
                ],
                const SizedBox(height: 20),
                Text('Bữa', style: t.titleSmall),
                const SizedBox(height: 8),
                SegmentedButton<Meal>(
                  segments: const [
                    ButtonSegment(value: Meal.breakfast, label: Text('Sáng')),
                    ButtonSegment(value: Meal.lunch, label: Text('Trưa')),
                    ButtonSegment(value: Meal.dinner, label: Text('Tối')),
                    ButtonSegment(value: Meal.snack, label: Text('Phụ')),
                  ],
                  selected: {_meal},
                  onSelectionChanged: (s) => setState(() => _meal = s.first),
                ),
                const SizedBox(height: 16),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Ngày'),
                  trailing: Text(fmtShortDay(_at), style: t.bodyLarge),
                  onTap: _pickDate,
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Giờ'),
                  trailing: Text(fmtTime24(_at), style: t.bodyLarge),
                  onTap: _pickTime,
                ),
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: FilledButton(
                      onPressed: _saving || _qty <= 0 ? null : _save,
                      child: _saving
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Text('Lưu'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: TextButton(
                      onPressed: _confirmDelete,
                      style: TextButton.styleFrom(foregroundColor: cs.error),
                      child: const Text('Xóa khỏi nhật ký'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
