import 'package:health_engine/health_engine.dart';
import 'package:material_ui/material_ui.dart';

import '../state/app_scope.dart';
import 'common/common_widgets.dart';
import 'labels.dart';
import 'profile_screen.dart';
import 'water_log_screen.dart';

/// Tổng kết ngày: cảnh báo UL, dòng thận trọng, nhắc tuổi, calo, đường, vi chất, nước.
class TodayScreen extends StatelessWidget {
  const TodayScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final r = state.report();
    if (r == null) return const SizedBox.shrink();
    final pack = state.pack;
    final t = Theme.of(context).textTheme;
    final hasFood = state.todayItems.isNotEmpty;
    final cl = CautionLabels(caution: state.caution);
    final bumpedAge = state.ageBumpedNotice;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
      children: [
        if (r.ulFlags.isNotEmpty) ...[
          _UlBanner(flags: r.ulFlags, pack: pack),
          const SizedBox(height: 12),
        ],
        if (state.caution) ...[
          const SafetyNote(message: cautionBannerMessage),
          const SizedBox(height: 12),
        ],
        if (bumpedAge != null) ...[
          _AgeBumpedBanner(
            age: bumpedAge,
            onEdit: () async {
              final nav = Navigator.of(context);
              await state.diary.dismissAgeBumpedNotice();
              if (context.mounted) {
                await nav.push(MaterialPageRoute<void>(builder: (_) => const ProfileScreen()));
              }
            },
            onDismiss: () => state.diary.dismissAgeBumpedNotice(),
          ),
          const SizedBox(height: 12),
        ],
        if (!state.hideCalories) ...[
          Text('Năng lượng', style: t.titleMedium),
          const SizedBox(height: 8),
          _EnergyCard(report: r, labels: cl),
          const SizedBox(height: 16),
        ],
        Text('Tỷ lệ đạm, béo, bột đường', style: t.titleMedium),
        const SizedBox(height: 4),
        Text(cl.macroShareSubtitle, style: t.bodySmall),
        const SizedBox(height: 8),
        if (!hasFood)
          const Text('Chưa ghi bữa ăn nào hôm nay.')
        else
          for (final m in r.macros) _MacroRow(share: m),
        const SizedBox(height: 16),
        Text('Đường bổ sung', style: t.titleMedium),
        const SizedBox(height: 8),
        _SugarCard(sugar: r.sugar, maxMeal: pack.addedSugarMaxGramsPerMeal),
        const SizedBox(height: 16),
        Text('Vitamin và khoáng chất', style: t.titleMedium),
        const SizedBox(height: 4),
        Text(cl.nutrientsSubtitle, style: t.bodySmall),
        const SizedBox(height: 8),
        for (final n in r.nutrients.where((n) => n.target != null && pack.nutrients[n.nutrientId]!.group != 'macro'))
          _NutrientRow(status: n, def: pack.nutrients[n.nutrientId]!),
        const SizedBox(height: 16),
        _WaterCard(
          totalMl: state.diary.todayWaterTotalMl,
          hasEntries: state.todayWaters.isNotEmpty,
          quickMl: state.lastWaterMl,
          onOpenLog: () => Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => const WaterLogScreen()),
          ),
          onQuickAdd: () async {
            final ml = state.lastWaterMl;
            final id = await state.diary.quickAddWater();
            if (id != null && context.mounted) {
              showUndoWaterSnack(
                context,
                ml: ml,
                onUndo: () => state.diary.deleteWater(id),
              );
            }
          },
        ),
        const SizedBox(height: 24),
        Text(
          'Số liệu chỉ để tham khảo, không thay cho chẩn đoán hay tư vấn của bác sĩ. '
          'Nguồn: NASEM (qua NIH ODS), Dietary Guidelines 2025–2030, 2024 Adult Compendium.',
          style: t.bodySmall,
        ),
      ],
    );
  }
}

class _AgeBumpedBanner extends StatelessWidget {
  final int age;
  final VoidCallback onEdit;
  final VoidCallback onDismiss;
  const _AgeBumpedBanner({required this.age, required this.onEdit, required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Wrap(
        spacing: 8,
        runSpacing: 4,
        crossAxisAlignment: WrapCrossAlignment.center,
        alignment: WrapAlignment.spaceBetween,
        children: [
          Text('Tuổi trong hồ sơ đã được cập nhật thành $age.'),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextButton(onPressed: onEdit, child: const Text('Sửa')),
              IconButton(
                tooltip: 'Đóng',
                icon: const Icon(Icons.close, size: 18),
                onPressed: onDismiss,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _WaterCard extends StatelessWidget {
  final double totalMl;
  final bool hasEntries;
  final double quickMl;
  final VoidCallback onOpenLog;
  final VoidCallback onQuickAdd;

  const _WaterCard({
    required this.totalMl,
    required this.hasEntries,
    required this.quickMl,
    required this.onOpenLog,
    required this.onQuickAdd,
  });

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onOpenLog,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Nước', style: t.titleMedium),
              const SizedBox(height: 8),
              Wrap(
                spacing: 12,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                alignment: WrapAlignment.spaceBetween,
                children: [
                  Text(
                    hasEntries ? 'Đã uống ${fmtWaterMl(totalMl)} ml' : 'Chưa ghi nước hôm nay',
                    style: t.bodyLarge,
                  ),
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(minimumSize: const Size(48, 48)),
                    onPressed: onQuickAdd,
                    child: Text('+${fmtWaterMl(quickMl)} ml'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EnergyCard extends StatelessWidget {
  final DailyReport report;
  final CautionLabels labels;
  const _EnergyCard({required this.report, required this.labels});

  @override
  Widget build(BuildContext context) {
    final r = report;
    final eer = r.eerKcal;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Expanded(child: _Stat(label: 'Calo nạp', value: '${r.energyInKcal.round()} kcal')),
              Expanded(child: _Stat(label: labels.calorieGoalLabel, value: eer == null ? '—' : '$eer kcal')),
              Expanded(child: _Stat(label: 'Tiêu hao khi tập', value: '${r.energyOutWorkoutKcal.round()} kcal')),
            ]),
            if (eer != null) ...[
              const SizedBox(height: 12),
              LinearProgressIndicator(value: (r.energyInKcal / eer).clamp(0, 1).toDouble()),
              const SizedBox(height: 8),
              Text(labels.calorieGoalExplainer, style: Theme.of(context).textTheme.bodySmall),
            ],
            if (r.eerNotComputed != null) ...[
              const SizedBox(height: 8),
              Text(
                reasonLabel(r.eerNotComputed!, caution: labels.caution),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String label, value;
  const _Stat({required this.label, required this.value});
  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodySmall),
          Text(value, style: Theme.of(context).textTheme.titleMedium),
        ],
      );
}

class _MacroRow extends StatelessWidget {
  final MacroShare share;
  const _MacroRow({required this.share});
  @override
  Widget build(BuildContext context) {
    final s = share;
    final color = switch (s.status) {
      RangeStatus.within => Colors.green,
      RangeStatus.below => Colors.orange,
      RangeStatus.above => Colors.orange,
    };
    final note = switch (s.status) {
      RangeStatus.within => 'trong khoảng',
      RangeStatus.below => 'thấp hơn khoảng',
      RangeStatus.above => 'cao hơn khoảng',
    };
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(children: [
        SizedBox(width: 80, child: Text(macroLabel(s.macro))),
        Expanded(
          child: LinearProgressIndicator(value: (s.percentEnergy / 100).clamp(0, 1).toDouble(), color: color),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 150,
          child: Text('${s.percentEnergy.round()}% · ${s.amdr.min.round()}–${s.amdr.max.round()}% · $note',
              style: Theme.of(context).textTheme.bodySmall),
        ),
      ]),
    );
  }
}

class _SugarCard extends StatelessWidget {
  final SugarCheck sugar;
  final double maxMeal;
  const _SugarCard({required this.sugar, required this.maxMeal});
  @override
  Widget build(BuildContext context) {
    final lines = <String>[
      '${fmt(sugar.addedSugarG)} g, khoảng ${sugar.percentEnergy.round()}% năng lượng.',
      for (final a in sugar.mealsOverLimit)
        'Bữa ${mealLabel(a.meal)}: ${fmt(a.grams)} g, vượt ${fmt(maxMeal)} g mỗi bữa.',
      if (sugar.unknownSugarFoods.isNotEmpty)
        'Chưa tính đường bổ sung của ${sugar.unknownSugarFoods.length} món (nhãn không ghi riêng).',
    ];
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [for (final l in lines) Text(l)]),
      ),
    );
  }
}

class _NutrientRow extends StatelessWidget {
  final NutrientStatus status;
  final NutrientDef def;
  const _NutrientRow({required this.status, required this.def});
  @override
  Widget build(BuildContext context) {
    final pct = status.percentOfTarget ?? 0;
    final target = status.target!;
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      title: Text(def.nameVi + (target.isEstimate ? ' (ước tính)' : '')),
      subtitle: LinearProgressIndicator(value: (pct / 100).clamp(0, 1).toDouble()),
      trailing: Text(
          '${fmt(status.totalAmount)}/${fmt(target.value)} ${unitLabel(def.unit)}\n${pct.round()}%',
          textAlign: TextAlign.right),
    );
  }
}

class _UlBanner extends StatelessWidget {
  final List<UlFlag> flags;
  final ReferencePack pack;
  const _UlBanner({required this.flags, required this.pack});

  String _scope(UlScope s) => switch (s) {
        UlScope.total => 'tính mọi nguồn',
        UlScope.supplement => 'chỉ tính từ thuốc, thực phẩm bổ sung',
        UlScope.synthetic => 'chỉ tính dạng tổng hợp (bổ sung, thực phẩm tăng cường)',
      };

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      color: cs.errorContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Vượt giới hạn an toàn', style: TextStyle(fontWeight: FontWeight.bold, color: cs.onErrorContainer)),
            const SizedBox(height: 8),
            for (final f in flags)
              Text(
                '${pack.nutrients[f.nutrientId]!.nameVi}: ${fmt(f.amount)} / ${fmt(f.ul)} '
                '${unitLabel(pack.nutrients[f.nutrientId]!.unit)}'
                '${f.isSevenDayAverage ? ' (trung bình ${f.dayCount} ngày)' : ''}, ${_scope(f.scope)}'
                ' · Vượt ${fmt(f.excess)} (${f.percentOver.round()}%).',
                style: TextStyle(color: cs.onErrorContainer),
              ),
            const SizedBox(height: 8),
            Text('Xem lại liều bổ sung; hỏi bác sĩ hoặc dược sĩ nếu đang dùng theo đơn.',
                style: TextStyle(color: cs.onErrorContainer)),
          ],
        ),
      ),
    );
  }
}
