import 'package:health_engine/health_engine.dart';
import 'package:journal_db/journal_db.dart';
import 'package:material_ui/material_ui.dart';

import '../state/app_scope.dart';
import '../state/diary_controller.dart';
import 'add_supplement_screen.dart';
import 'add_workout_screen.dart';
import 'common/common_widgets.dart';
import 'common/food_feedback_sheet.dart';
import 'edit_food_screen.dart';
import 'labels.dart';
import 'water_log_screen.dart';

enum _DiaryFilter { all, food, supplement, water, workout }

class DiaryScreen extends StatefulWidget {
  const DiaryScreen({super.key});

  @override
  State<DiaryScreen> createState() => _DiaryScreenState();
}

class _DiaryScreenState extends State<DiaryScreen> {
  _DiaryFilter _filter = _DiaryFilter.all;

  Future<bool> _confirmSwipeDelete(BuildContext context, String itemLabel) =>
      showConfirmDialog(
        context,
        title: 'Xóa $itemLabel?',
        message: 'Mục $itemLabel này sẽ bị xóa khỏi nhật ký.',
        confirmLabel: 'Xóa',
        destructive: true,
      );

  static String _mealSectionTitle(Meal m) => switch (m) {
        Meal.breakfast => 'Bữa sáng',
        Meal.lunch => 'Bữa trưa',
        Meal.dinner => 'Bữa tối',
        Meal.snack => 'Bữa phụ',
      };

  static String _foodSubtitle(FoodEntry f) {
    final slot = switch (f.meal) {
      Meal.breakfast => MealSlot.breakfast,
      Meal.lunch => MealSlot.lunch,
      Meal.dinner => MealSlot.dinner,
      Meal.snack => MealSlot.snack,
    };
    return '${fmt(f.portionQty)} ${f.portionUnit} · bữa ${mealLabel(slot)}';
  }

  Widget _groupedCard(BuildContext context, List<Widget> children) {
    final ww = context.wwColors;
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0)
              Divider(
                height: 1,
                color: ww.outlineSubtle.withValues(alpha: 0.5),
              ),
            children[i],
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final foods = state.diary.todayFoods;
    final doses = state.diary.todayDoses;
    final waters = state.todayWaters;
    final ws = state.diary.todayWorkouts;
    final t = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;

    void open(Widget page) =>
        Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page));

    Future<void> editFood(FoodEntry f) async {
      final fb = await Navigator.of(context).push<FoodLogFeedback>(
        MaterialPageRoute(builder: (_) => EditFoodScreen(entry: f)),
      );
      if (fb != null && context.mounted) {
        await presentFoodFeedback(context, feedback: fb, pack: state.pack);
      }
    }

    final showFood = _filter == _DiaryFilter.all || _filter == _DiaryFilter.food;
    final showSupplement = _filter == _DiaryFilter.all || _filter == _DiaryFilter.supplement;
    final showWater = _filter == _DiaryFilter.all || _filter == _DiaryFilter.water;
    final showWorkout = _filter == _DiaryFilter.all || _filter == _DiaryFilter.workout;

    final foodsByMeal = <Meal, List<FoodEntry>>{
      for (final m in Meal.values)
        m: [
          for (final f in foods)
            if (f.meal == m) f,
        ],
    };

    return ListView(
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, 96),
      children: [
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            for (final item in const [
              (_DiaryFilter.all, 'Tất cả'),
              (_DiaryFilter.food, 'Món ăn'),
              (_DiaryFilter.supplement, 'Bổ sung'),
              (_DiaryFilter.water, 'Nước'),
              (_DiaryFilter.workout, 'Buổi tập'),
            ])
              ChoiceChip(
                label: Text(item.$2),
                selected: _filter == item.$1,
                materialTapTargetSize: MaterialTapTargetSize.padded,
                onSelected: (_) => setState(() => _filter = item.$1),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        if (showFood) ...[
          Text('Món ăn', style: t.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          if (foods.isEmpty)
            Padding(
              padding: const EdgeInsets.all(AppSpacing.sm),
              child: Text(
                'Chưa có món nào.',
                style: t.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
              ),
            )
          else
            for (final meal in Meal.values)
              if (foodsByMeal[meal]!.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                  child: Text(
                    _mealSectionTitle(meal),
                    style: t.labelLarge?.copyWith(color: cs.onSurfaceVariant),
                  ),
                ),
                _groupedCard(context, [
                  for (final f in foodsByMeal[meal]!)
                    EntryTile(
                      leadingIcon: f.lines.any((l) => l.source == IntakeSource.fortified)
                          ? LucideIcons.cupSoda
                          : LucideIcons.utensils,
                      title: f.name,
                      subtitle: _foodSubtitle(f),
                      timeText: fmtTime24(f.at),
                      kcal: f.lines.fold<double>(
                        0,
                        (s, l) => s + (l.amounts['energyKcal'] ?? 0),
                      ),
                      isEstimate: f.foodRef?.startsWith('recipe:') ?? false,
                      onTap: () => editFood(f),
                    ),
                ]),
                const SizedBox(height: AppSpacing.md),
              ],
          const SizedBox(height: AppSpacing.sm),
        ],
        if (showSupplement) ...[
          Text('Bổ sung', style: t.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          if (doses.isEmpty)
            Padding(
              padding: const EdgeInsets.all(AppSpacing.sm),
              child: Text('Chưa có.', style: t.bodyMedium?.copyWith(color: cs.onSurfaceVariant)),
            )
          else
            _groupedCard(context, [
              for (final d in doses)
                Dismissible(
                  key: ValueKey('dose-${d.id}'),
                  confirmDismiss: (_) => _confirmSwipeDelete(context, 'lần uống bổ sung'),
                  onDismissed: (_) => state.diary.deleteDoseEntry(d.id),
                  child: EntryTile(
                    leadingIcon: LucideIcons.pill,
                    title: d.name ?? 'Bổ sung',
                    subtitle: '${fmt(d.servings)} lần · ${d.lines.length} chất',
                    timeText: fmtTime24(d.at),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => AddSupplementScreen(existingDose: d),
                      ),
                    ),
                  ),
                ),
            ]),
          const SizedBox(height: AppSpacing.lg),
        ],
        if (showWater) ...[
          Text(
            waters.isEmpty
                ? 'Nước'
                : 'Nước  ${fmtWaterMl(state.diary.todayWaterTotalMl)} ml (${waters.length} lần)',
            style: tabularNumberStyle(t.titleMedium),
          ),
          const SizedBox(height: AppSpacing.sm),
          if (waters.isEmpty)
            Padding(
              padding: const EdgeInsets.all(AppSpacing.sm),
              child: Text(
                _filter == _DiaryFilter.water ? 'Chưa ghi nước trong ngày này.' : 'Chưa ghi nước.',
                style: t.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
              ),
            )
          else
            _groupedCard(context, [
              for (final w in waters)
                EntryTile(
                  leadingIcon: LucideIcons.droplet,
                  title: '${fmtWaterMl(w.ml)} ml',
                  subtitle: 'Nước uống',
                  timeText: fmtTime24(w.at),
                  onTap: () => open(WaterLogScreen(editing: w)),
                ),
            ]),
          const SizedBox(height: AppSpacing.lg),
        ],
        if (showWorkout) ...[
          Text('Buổi tập', style: t.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          if (ws.isEmpty)
            Padding(
              padding: const EdgeInsets.all(AppSpacing.sm),
              child: Text('Chưa có.', style: t.bodyMedium?.copyWith(color: cs.onSurfaceVariant)),
            )
          else
            _groupedCard(context, [
              for (final w in ws)
                Dismissible(
                  key: ValueKey('workout-${w.id}'),
                  confirmDismiss: (_) => _confirmSwipeDelete(context, 'buổi tập'),
                  onDismissed: (_) => state.diary.deleteWorkout(w.id),
                  child: EntryTile(
                    leadingIcon: LucideIcons.footprints,
                    title: state.pack.activities[w.workout.activityCode]?.nameVi ??
                        w.workout.activityCode,
                    subtitle: '${fmt(w.workout.minutes)} phút',
                    timeText: fmtTime24(w.startAt),
                    kcal: state.profile == null
                        ? null
                        : workoutKcal(state.pack, state.profile!, w.workout),
                    onTap: () => open(AddWorkoutScreen(editing: w)),
                  ),
                ),
            ]),
          const SizedBox(height: AppSpacing.lg),
        ],
        Text(
          'Chạm vào mục để sửa; vuốt sang bên để xóa bổ sung hoặc buổi tập.',
          style: t.bodySmall?.copyWith(color: cs.onSurfaceVariant),
        ),
      ],
    );
  }
}
