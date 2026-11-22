import 'package:material_ui/material_ui.dart';
import 'package:health_engine/health_engine.dart';

import '../state/app_scope.dart';
import 'add_food_screen.dart';
import 'add_supplement_screen.dart';
import 'add_workout_screen.dart';
import 'labels.dart';

class DiaryScreen extends StatelessWidget {
  const DiaryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final items = state.todayItems;
    final ws = state.todayWorkouts;
    final t = Theme.of(context).textTheme;

    void open(Widget page) =>
        Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page));

    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Ăn uống và bổ sung', style: t.titleMedium),
          if (items.isEmpty) const Padding(padding: EdgeInsets.all(8), child: Text('Chưa có.')),
          for (var i = 0; i < items.length; i++)
            Dismissible(
              key: ValueKey('item-$i-${items[i].label}'),
              onDismissed: (_) => state.removeItem(i),
              child: ListTile(
                leading: Icon(switch (items[i].source) {
                  IntakeSource.supplement => Icons.medication,
                  IntakeSource.fortified => Icons.local_drink,
                  IntakeSource.food => Icons.restaurant,
                }),
                title: Text(items[i].label),
                subtitle: Text(_summary(items[i], state.hideCalories)),
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
          Text('Vuốt sang bên để xóa một dòng.', style: t.bodySmall),
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

  static String _summary(IntakeItem it, bool hideCal) {
    final parts = <String>[
      if (!hideCal && it.amount('energyKcal') > 0) '${it.amount('energyKcal').round()} kcal',
      if (it.amount('protein') > 0) 'đạm ${fmt(it.amount('protein'))} g',
      if (it.mealId != null) 'bữa ${it.mealId}',
    ];
    final micro = it.nutrients.keys
        .where((k) => !const {'energyKcal', 'protein', 'fat', 'carbohydrate', 'addedSugar'}.contains(k))
        .length;
    if (micro > 0) parts.add('$micro vi chất');
    return parts.join(' · ');
  }
}
