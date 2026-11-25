import 'package:material_ui/material_ui.dart';

import '../../state/app_scope.dart';
import '../add_food_screen.dart';
import '../add_supplement_screen.dart';
import '../add_workout_screen.dart';
import '../water_log_screen.dart';
import 'common_widgets.dart';

/// Bảng Ghi 4 ô (`Món ăn`, `Bổ sung`, `Nước`, `Buổi tập`), mỗi ô ≥ 96 dp.
Future<void> showLogSheet(BuildContext context) {
  final state = AppScope.of(context);
  final d = state.day;
  final isToday = state.diary.isViewingToday;
  final dayLabel = fmtShortDay(d);
  final t = Theme.of(context).textTheme;

  void open(Widget page) {
    Navigator.of(context).pop();
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page));
  }

  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (ctx) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Ghi cho $dayLabel',
              style: (t.titleMedium ?? const TextStyle()).copyWith(
                fontWeight: isToday ? FontWeight.w500 : FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _LogTile(
                    icon: Icons.restaurant,
                    label: 'Món ăn',
                    onTap: () => open(const AddFoodScreen()),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _LogTile(
                    icon: Icons.medication_outlined,
                    label: 'Bổ sung',
                    onTap: () => open(const AddSupplementScreen()),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _LogTile(
                    icon: Icons.water_drop_outlined,
                    label: 'Nước',
                    onTap: () => open(const WaterLogScreen()),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _LogTile(
                    icon: Icons.directions_run,
                    label: 'Buổi tập',
                    onTap: () => open(const AddWorkoutScreen()),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

class _LogTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _LogTile({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: cs.surfaceContainerLow,
      borderRadius: BorderRadius.circular(14),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 96),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 28, color: cs.primary),
                const SizedBox(height: 8),
                Text(label, textAlign: TextAlign.center),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
