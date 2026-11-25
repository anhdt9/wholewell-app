import 'package:health_engine/health_engine.dart';
import 'package:journal_db/journal_db.dart';
import 'package:material_ui/material_ui.dart';

import '../state/app_scope.dart';
import '../state/diary_controller.dart';
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

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final foods = state.diary.todayFoods;
    final doses = state.diary.todayDoses;
    final waters = state.todayWaters;
    final ws = state.todayWorkouts;
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
                  ? Icons.local_drink
                  : Icons.restaurant,
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
              onDismissed: (_) => state.diary.deleteDoseEntry(d.id),
              child: EntryTile(
                leadingIcon: Icons.medication,
                title: d.name ?? 'Bổ sung',
                subtitle: '${fmt(d.servings)} lần · ${d.lines.length} chất',
                timeText: fmtTime24(d.at),
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
              leadingIcon: Icons.water_drop_outlined,
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
          for (var i = 0; i < ws.length; i++)
            Dismissible(
              key: ValueKey('w-$i-${ws[i].activityCode}'),
              onDismissed: (_) => state.removeWorkout(i),
              child: ListTile(
                leading: const Icon(Icons.directions_run),
                title: Text(state.pack.activities[ws[i].activityCode]?.nameVi ?? ws[i].activityCode),
                subtitle: Text('${fmt(ws[i].minutes)} phút'
                    '${state.hideCalories || state.profile == null ? '' : ' · ${workoutKcal(state.pack, state.profile!, ws[i]).round()} kcal'}'),
              ),
            ),
          const SizedBox(height: 16),
        ],
        Text('Chạm món ăn hoặc lần uống nước để sửa; vuốt sang bên để xóa bổ sung hoặc buổi tập.',
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
