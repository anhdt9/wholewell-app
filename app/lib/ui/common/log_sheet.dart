import 'dart:async';

import 'package:flutter/services.dart' show HapticFeedback;
import 'package:material_ui/material_ui.dart';

import '../../state/app_scope.dart';
import '../add_food_screen.dart';
import '../add_supplement_screen.dart';
import '../add_workout_screen.dart';
import '../water_log_screen.dart';
import 'common_widgets.dart';

/// Bảng Ghi 4 ô (`Món ăn`, `Bổ sung`, `Nước`, `Buổi tập`), bo 16 dp, mỗi ô ≥ 96 dp.
Future<void> showLogSheet(BuildContext context) {
  final state = AppScope.of(context);
  final d = state.day;
  final isToday = state.diary.isViewingToday;
  final dayLabel = fmtShortDay(d);
  final t = Theme.of(context).textTheme;
  final cs = Theme.of(context).colorScheme;
  final ww = context.wwColors;

  void open(Widget page) {
    unawaited(HapticFeedback.selectionClick());
    Navigator.of(context).pop();
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page));
  }

  return showAppModalSheet<void>(
    context: context,
    builder: (ctx) => SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.xs, AppSpacing.lg, AppSpacing.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Ghi cho $dayLabel',
            style: (t.titleMedium ?? const TextStyle()).copyWith(
              fontWeight: isToday ? FontWeight.w600 : FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: _LogTile(
                  icon: LucideIcons.utensils,
                  accent: ww.macroProtein,
                  label: 'Món ăn',
                  onTap: () => open(const AddFoodScreen()),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _LogTile(
                  icon: LucideIcons.pill,
                  accent: ww.supplementSource,
                  label: 'Bổ sung',
                  onTap: () => open(const AddSupplementScreen()),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: _LogTile(
                  icon: LucideIcons.droplet,
                  accent: cs.primary,
                  label: 'Nước',
                  onTap: () => open(const WaterLogScreen()),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _LogTile(
                  icon: LucideIcons.footprints,
                  accent: ww.macroFat,
                  label: 'Buổi tập',
                  onTap: () => open(const AddWorkoutScreen()),
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

class _LogTile extends StatelessWidget {
  final IconData icon;
  final Color accent;
  final String label;
  final VoidCallback onTap;

  const _LogTile({required this.icon, required this.accent, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final ww = context.wwColors;
    final t = Theme.of(context).textTheme;
    return Material(
      color: ww.cardSurface,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.cardRadius,
        side: BorderSide(color: ww.outlineSubtle),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 100),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(color: accent.withValues(alpha: 0.14), shape: BoxShape.circle),
                  child: Icon(icon, size: 22, color: accent),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(label, style: t.titleSmall, textAlign: TextAlign.center),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
