/// Màn Ghi món: chọn bữa, món gần đây, món đã lưu, tìm kiếm FTS5 và chuyển sang Nhập theo nhãn.
library;

import 'dart:async';

import 'package:flutter/services.dart' show HapticFeedback;
import 'package:material_ui/material_ui.dart';
import 'package:food_library/food_library.dart';
import 'package:journal_db/models.dart';

import '../state/app_scope.dart';
import '../state/diary_controller.dart';
import 'common/common_widgets.dart';
import 'common/food_feedback_sheet.dart';
import 'edit_food_screen.dart';
import 'food_portion_screen.dart';
import 'label_food_screen.dart';
import 'labels.dart';

class AddFoodScreen extends StatefulWidget {
  const AddFoodScreen({super.key});

  @override
  State<AddFoodScreen> createState() => _AddFoodScreenState();
}

class _AddFoodScreenState extends State<AddFoodScreen> {
  final _searchCtrl = TextEditingController();
  late Meal _meal = DiaryController.defaultMealFor(DateTime.now());

  Timer? _debounce;
  Timer? _spinnerDelay;
  bool _loading = false;
  bool _showSpinner = false;
  bool _loggingRecent = false;

  List<FoodEntry> _recents = const [];
  List<CustomFood> _customs = const [];
  List<FoodSummary> _libraryHits = const [];
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      _meal = DiaryController.defaultMealFor(DateTime.now(), AppScope.of(context).diary.dayTimesSettings);
      unawaited(_refreshLists(''));
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _spinnerDelay?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _refreshLists(String query) async {
    final diary = AppScope.of(context).diary;
    _spinnerDelay?.cancel();
    _loading = true;
    _spinnerDelay = Timer(const Duration(milliseconds: 200), () {
      if (mounted && _loading) setState(() => _showSpinner = true);
    });

    final q = query.trim();
    if (q.isEmpty) {
      final res = await Future.wait([diary.recentFoods(limit: 8), diary.searchCustomFoods('', limit: 20)]);
      if (!mounted) return;
      _loading = false;
      _spinnerDelay?.cancel();
      setState(() {
        _showSpinner = false;
        _recents = res[0] as List<FoodEntry>;
        _customs = res[1] as List<CustomFood>;
        _libraryHits = const [];
      });
      return;
    }

    final res = await Future.wait([diary.searchCustomFoods(q, limit: 20), diary.searchLibrary(q, limit: 30)]);
    if (!mounted) return;
    _loading = false;
    _spinnerDelay?.cancel();
    setState(() {
      _showSpinner = false;
      _customs = res[0] as List<CustomFood>;
      _libraryHits = res[1] as List<FoodSummary>;
    });
  }

  void _onSearchChanged(String v) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 120), () {
      if (mounted) unawaited(_refreshLists(v));
    });
  }

  Future<void> _finishWithFeedback(FoodLogFeedback fb) async {
    if (!mounted) return;
    final state = AppScope.of(context);
    final nav = Navigator.of(context);
    nav.pop(fb);
    if (!nav.mounted) return;
    await presentFoodFeedback(
      nav.context,
      feedback: fb,
      pack: state.pack,
      onUndo: fb.savedFoodId == null ? null : () => state.diary.deleteFoodEntry(fb.savedFoodId!),
      onEdit: fb.savedFoodId == null
          ? null
          : () async {
              final entry = await state.diary.foodById(fb.savedFoodId!);
              if (entry != null && nav.mounted) {
                final editFb = await nav.push<FoodLogFeedback>(
                  MaterialPageRoute(builder: (_) => EditFoodScreen(entry: entry)),
                );
                if (editFb != null && nav.mounted) {
                  await presentFoodFeedback(nav.context, feedback: editFb, pack: state.pack);
                }
              }
            },
    );
  }

  Future<void> _tapRecent(FoodEntry e) async {
    if (_loggingRecent) return;
    _loggingRecent = true;
    try {
      final diary = AppScope.of(context).diary;
      final fb = await diary.logRecentFood(e, meal: _meal);
      if (!fb.failed) unawaited(HapticFeedback.lightImpact());
      await _finishWithFeedback(fb);
    } finally {
      _loggingRecent = false;
    }
  }

  Future<void> _openLibraryDetail(FoodSummary s) async {
    final state = AppScope.of(context);
    final detail = await state.diary.getLibraryFood(s.id);
    if (!mounted) return;
    if (detail == null) {
      AppFeedback.showSnack(context, 'Chưa đọc được món này. Thử lại');
      return;
    }
    final fb = await Navigator.of(context).push<FoodLogFeedback>(
      MaterialPageRoute(
        builder: (_) => FoodPortionScreen.library(
          food: detail,
          initialMeal: _meal,
          initialAt: DiaryController.defaultAtFor(state.day, _meal, settings: state.dayTimesSettings),
        ),
      ),
    );
    if (fb != null) await _finishWithFeedback(fb);
  }

  Future<void> _openCustomPortion(CustomFood c) async {
    final state = AppScope.of(context);
    final fb = await Navigator.of(context).push<FoodLogFeedback>(
      MaterialPageRoute(
        builder: (_) => FoodPortionScreen.custom(
          custom: c,
          initialMeal: _meal,
          initialAt: DiaryController.defaultAtFor(state.day, _meal, settings: state.dayTimesSettings),
        ),
      ),
    );
    if (fb != null) await _finishWithFeedback(fb);
  }

  Future<void> _openLabelScreen() async {
    final q = _searchCtrl.text.trim();
    final fb = await Navigator.of(context).push<FoodLogFeedback>(
      MaterialPageRoute(
        builder: (_) => LabelFoodScreen(initialMeal: _meal, initialName: q.isEmpty ? null : q),
      ),
    );
    if (fb != null) await _finishWithFeedback(fb);
  }

  Future<void> _confirmArchiveCustom(CustomFood c) async {
    final ok = await showConfirmDialog(context, title: 'Bỏ lưu “${c.name}” khỏi danh sách?', confirmLabel: 'Bỏ lưu');
    if (!ok || !mounted) return;
    await AppScope.of(context).diary.archiveCustomFood(c.id);
    if (mounted) unawaited(_refreshLists(_searchCtrl.text));
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final t = Theme.of(context).textTheme;
    final isToday = dayKey(state.day) == dayKey(DateTime.now());
    final title = isToday ? 'Ghi món' : 'Ghi món · ${state.day.day}/${state.day.month}';

    if (state.foodLibraryBroken) {
      return Scaffold(
        appBar: AppBar(title: Text(title)),
        body: ErrorState(
          message: 'Không đọc được thư viện món ăn. Hãy cài lại WholeWell từ cửa hàng ứng dụng.',
          actionLabel: 'Nhập theo nhãn',
          onAction: _openLabelScreen,
        ),
      );
    }

    final query = _searchCtrl.text.trim();
    final isSearching = query.isNotEmpty;

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Column(
              children: [
                SegmentedButton<Meal>(
                  segments: enabledMealSegments(state.dayTimesSettings, alwaysInclude: _meal),
                  selected: {_meal},
                  onSelectionChanged: (s) => setState(() => _meal = s.first),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _searchCtrl,
                  onChanged: _onSearchChanged,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(LucideIcons.search),
                    hintText: 'Tìm món...',
                    suffixIcon: _showSpinner
                        ? const Padding(
                            padding: EdgeInsets.all(12),
                            child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                          )
                        : (isSearching
                              ? IconButton(
                                  tooltip: 'Xóa tìm kiếm',
                                  onPressed: () {
                                    _searchCtrl.clear();
                                    unawaited(_refreshLists(''));
                                  },
                                  icon: const Icon(LucideIcons.x),
                                )
                              : null),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                if (!isSearching) ...[
                  if (_recents.isEmpty && _customs.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Text('Gõ tên món để tìm trong thư viện hoặc tự nhập từ nhãn.'),
                    ),
                  if (_recents.isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text('Gần đây', style: t.titleSmall),
                    ),
                    for (final r in _recents) _buildRecentTile(r),
                  ],
                  if (_customs.isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.only(top: 12, bottom: 8),
                      child: Text('Món bạn đã lưu', style: t.titleSmall),
                    ),
                    for (final c in _customs) _buildCustomTile(c, showMenu: true),
                  ],
                ] else ...[
                  for (final c in _customs) _buildCustomTile(c, showMenu: false),
                  for (final s in _libraryHits) _buildSummaryTile(s),
                  if (_customs.isEmpty && _libraryHits.isEmpty && !_loading)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      child: Text('Không thấy “$query”. Thử tên khác hoặc nhập theo nhãn.'),
                    ),
                ],
                const SizedBox(height: 16),
                Text('Không thấy món?', style: t.bodySmall),
                const SizedBox(height: 8),
                SizedBox(
                  height: 48,
                  width: double.infinity,
                  child: OutlinedButton(onPressed: _openLabelScreen, child: const Text('Nhập theo nhãn')),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentTile(FoodEntry r) {
    final kcal = r.lines.fold<double>(0, (s, l) => s + (l.amounts['energyKcal'] ?? 0));
    final isRecipe = r.foodRef?.startsWith('recipe:') ?? false;
    final isCustom = r.foodRef?.startsWith('custom:') ?? r.labelBasisQty != null;
    return ListTile(
      minTileHeight: 56,
      contentPadding: EdgeInsets.zero,
      title: Wrap(
        spacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text('${r.name} · ${fmt(r.portionQty)} ${r.portionUnit}'),
          if (isRecipe) const EstimateChip(),
          if (isCustom) const EstimateChip(label: 'tự nhập'),
        ],
      ),
      trailing: kcal > 0 ? CalorieText(kcal, suffix: '') : null,
      onTap: () => _tapRecent(r),
    );
  }

  Widget _buildCustomTile(CustomFood c, {required bool showMenu}) {
    return ListTile(
      minTileHeight: 56,
      contentPadding: EdgeInsets.zero,
      title: Wrap(
        spacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text('${c.name} (${fmt(c.labelBasisQty)} ${c.labelBasisUnit})'),
          const EstimateChip(label: 'tự nhập'),
        ],
      ),
      trailing: showMenu
          ? IconButton(
              tooltip: 'Tùy chọn',
              icon: const Icon(LucideIcons.ellipsisVertical),
              onPressed: () => showModalBottomSheet<void>(
                context: context,
                builder: (ctx) => SafeArea(
                  child: ListTile(
                    leading: const Icon(LucideIcons.trash2),
                    title: const Text('Bỏ lưu món này'),
                    onTap: () {
                      Navigator.pop(ctx);
                      unawaited(_confirmArchiveCustom(c));
                    },
                  ),
                ),
              ),
            )
          : null,
      onTap: () => _openCustomPortion(c),
    );
  }

  Widget _buildSummaryTile(FoodSummary s) {
    final portionText = s.defaultPortionLabel != null && s.defaultPortionGrams != null
        ? '${s.defaultPortionLabel} (${fmt(s.defaultPortionGrams!)} g)'
        : '100 g';
    final displayKcal = s.defaultPortionGrams != null
        ? s.energyKcalPer100g * (s.defaultPortionGrams! / 100.0)
        : s.energyKcalPer100g;

    return ListTile(
      minTileHeight: 56,
      contentPadding: EdgeInsets.zero,
      title: Wrap(
        spacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [Text(s.nameVi), if (s.isEstimate) const EstimateChip()],
      ),
      subtitle: Text(s.nameEn != null && s.nameEn != s.nameVi ? '${s.nameEn} · $portionText' : portionText),
      trailing: displayKcal > 0 ? CalorieText(displayKcal, suffix: '') : null,
      onTap: () => _openLibraryDetail(s),
    );
  }
}
