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

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final foods = state.diary.todayFoods;
    final doses = state.diary.todayDoses;
    final waters = state.todayWaters;
    final ws = state.diary.todayWorkouts;
    final t = Theme.of(context).textTheme;

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

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
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
        const SizedBox(height: 16),
        if (showFood) ...[
          Text('Món ăn', style: t.titleMedium),
          if (foods.isEmpty)
            const Padding(padding: EdgeInsets.all(8), child: Text('Chưa có món nào.')),
          for (final f in foods)
            EntryTile(
              leadingIcon: f.lines.any((l) => l.source == IntakeSource.fortified)
                  ? LucideIcons.cupSoda
                  : LucideIcons.utensils,
              title: f.name,
              subtitle: _foodSubtitle(f),
              timeText: fmtTime24(f.at),
              kcal: f.lines.fold<double>(0, (s, l) => s + (l.amounts['energyKcal'] ?? 0)),
              isEstimate: f.foodRef?.startsWith('recipe:') ?? false,
              onTap: () => editFood(f),
            ),
          const SizedBox(height: 16),
        ],
        if (showSupplement) ...[
          Text('Bổ sung', style: t.titleMedium),
          if (doses.isEmpty)
            const Padding(padding: EdgeInsets.all(8), child: Text('Chưa có.')),
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
          const SizedBox(height: 16),
        ],
        if (showWater) ...[
          Text(
            waters.isEmpty
                ? 'Nước'
                : 'Nước  ${fmtWaterMl(state.diary.todayWaterTotalMl)} ml (${waters.length} lần)',
            style: t.titleMedium,
          ),
          if (waters.isEmpty)
            Padding(
              padding: const EdgeInsets.all(8),
              child: Text(
                _filter == _DiaryFilter.water ? 'Chưa ghi nước trong ngày này.' : 'Chưa ghi nước.',
              ),
            ),
          for (final w in waters)
            EntryTile(
              leadingIcon: LucideIcons.droplet,
              title: '${fmtWaterMl(w.ml)} ml',
              subtitle: 'Nước uống',
              timeText: fmtTime24(w.at),
              onTap: () => open(WaterLogScreen(editing: w)),
            ),
          const SizedBox(height: 16),
        ],
        if (showWorkout) ...[
          Text('Buổi tập', style: t.titleMedium),
          if (ws.isEmpty) const Padding(padding: EdgeInsets.all(8), child: Text('Chưa có.')),
          for (final w in ws)
            Dismissible(
              key: ValueKey('workout-${w.id}'),
              confirmDismiss: (_) => _confirmSwipeDelete(context, 'buổi tập'),
              onDismissed: (_) => state.diary.deleteWorkout(w.id),
              child: EntryTile(
                leadingIcon: LucideIcons.footprints,
                title: state.pack.activities[w.workout.activityCode]?.nameVi ?? w.workout.activityCode,
                subtitle: '${fmt(w.workout.minutes)} phút',
                timeText: fmtTime24(w.startAt),
                kcal: state.profile == null
                    ? null
                    : workoutKcal(state.pack, state.profile!, w.workout),
                onTap: () => open(AddWorkoutScreen(editing: w)),
              ),
            ),
          const SizedBox(height: 16),
        ],
        Text('Chạm vào mục để sửa; vuốt sang bên để xóa bổ sung hoặc buổi tập.',
            style: t.bodySmall),
      ],
    );
  }

  static String _foodSubtitle(FoodEntry f) {
    final slot = switch (f.meal) {
      Meal.breakfast => MealSlot.breakfast,
      Meal.lunch => MealSlot.lunch,
      Meal.dinner => MealSlot.dinner,
      Meal.snack => MealSlot.snack,
    };
    return '${fmt(f.portionQty)} ${f.portionUnit} · bữa ${mealLabel(slot)}';
  }
}
