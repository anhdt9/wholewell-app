import 'package:material_ui/material_ui.dart';
import 'package:health_engine/health_engine.dart';
import 'package:journal_db/journal_db.dart';

import '../state/app_scope.dart';
import '../state/diary_controller.dart';
import 'add_food_screen.dart';
import 'add_supplement_screen.dart';
import 'add_workout_screen.dart';
import 'common/common_widgets.dart';
import 'common/food_feedback_sheet.dart';
import 'edit_food_screen.dart';
import 'labels.dart';

class DiaryScreen extends StatelessWidget {
  const DiaryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final foods = state.diary.todayFoods;
    final doses = state.diary.todayDoses;
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

    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
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
                    '${state.hideCalories ? '' : ' · ${workoutKcal(state.pack, state.profile!, ws[i]).round()} kcal'}'),
              ),
            ),
          const SizedBox(height: 80),
          Text('Chạm món ăn để sửa; vuốt sang bên để xóa bổ sung hoặc buổi tập.', style: t.bodySmall),
        ],
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          FloatingActionButton.extended(
            heroTag: 'food',
            icon: const Icon(Icons.restaurant),
            label: const Text('Món ăn'),
            onPressed: () => open(const AddFoodScreen()),
          ),
          const SizedBox(height: 8),
          FloatingActionButton.extended(
            heroTag: 'supp',
            icon: const Icon(Icons.medication),
            label: const Text('Bổ sung'),
            onPressed: () => open(const AddSupplementScreen()),
          ),
          const SizedBox(height: 8),
          FloatingActionButton.extended(
            heroTag: 'workout',
            icon: const Icon(Icons.directions_run),
            label: const Text('Buổi tập'),
            onPressed: () => open(const AddWorkoutScreen()),
          ),
        ],
      ),
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
