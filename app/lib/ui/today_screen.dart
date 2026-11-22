import 'package:flutter/material.dart';
import 'package:health_engine/health_engine.dart';

import '../state/app_scope.dart';
import 'labels.dart';

/// Tổng kết ngày: calo, tỷ lệ đạm/béo/bột đường, đường bổ sung, cảnh báo UL, vi chất.
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

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (r.ulFlags.isNotEmpty) _UlBanner(flags: r.ulFlags, pack: pack),
        if (!state.hideCalories) ...[
          Text('Năng lượng', style: t.titleMedium),
          const SizedBox(height: 8),
          _EnergyCard(report: r),
          const SizedBox(height: 16),
        ],
        Text('Tỷ lệ đạm, béo, bột đường', style: t.titleMedium),
        const SizedBox(height: 4),
        Text('So với khoảng khuyến nghị (% năng lượng)', style: t.bodySmall),
        const SizedBox(height: 8),
        if (!hasFood)
          const Text('Chưa ghi bữa ăn nào hôm nay.')
        else
          for (final m in r.macros) _MacroRow(share: m),
        const SizedBox(height: 16),
        Text('Đường bổ sung', style: t.titleMedium),
        const SizedBox(height: 8),
        _SugarCard(sugar: r.sugar, maxPct: pack.addedSugarMaxPercent, maxMeal: pack.addedSugarMaxGramsPerMeal),
        const SizedBox(height: 16),
        Text('Vitamin và khoáng chất', style: t.titleMedium),
        const SizedBox(height: 4),
        Text('% so với mức khuyến nghị hằng ngày. "ước tính" là chất chưa có mức khuyến nghị chính thức.',
            style: t.bodySmall),
        const SizedBox(height: 8),
        for (final n in r.nutrients.where((n) => pack.nutrients[n.nutrientId]!.group != 'macro'))
          _NutrientRow(status: n, def: pack.nutrients[n.nutrientId]!),
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

class _EnergyCard extends StatelessWidget {
  final DailyReport report;
  const _EnergyCard({required this.report});

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
              Expanded(child: _Stat(label: 'Mục tiêu calo', value: eer == null ? '—' : '$eer kcal')),
              Expanded(child: _Stat(label: 'Tiêu hao khi tập', value: '${r.energyOutWorkoutKcal.round()} kcal')),
            ]),
            if (eer != null) ...[
              const SizedBox(height: 12),
              LinearProgressIndicator(value: (r.energyInKcal / eer).clamp(0, 1).toDouble()),
              const SizedBox(height: 8),
              Text('Mục tiêu là mức giữ cân, đã tính mức vận động trong hồ sơ.',
                  style: Theme.of(context).textTheme.bodySmall),
            ],
            if (r.eerNotComputed != null) ...[
              const SizedBox(height: 8),
              Text(reasonLabel(r.eerNotComputed!), style: Theme.of(context).textTheme.bodySmall),
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
  final double maxPct, maxMeal;
  const _SugarCard({required this.sugar, required this.maxPct, required this.maxMeal});
  @override
  Widget build(BuildContext context) {
    final lines = <String>[
      '${fmt(sugar.addedSugarG)} g, khoảng ${sugar.percentEnergy.round()}% năng lượng (giới hạn ${maxPct.round()}%).',
      if (sugar.overDailyLimit) 'Đã vượt giới hạn trong ngày.',
      for (final e in sugar.mealsOverLimit.entries)
        'Bữa "${e.key}": ${fmt(e.value)} g, vượt ${fmt(maxMeal)} g mỗi bữa.',
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
    final pct = status.percentOfTarget;
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      title: Text(def.nameVi + (status.target.isEstimate ? ' (ước tính)' : '')),
      subtitle: LinearProgressIndicator(value: (pct / 100).clamp(0, 1).toDouble()),
      trailing: Text(
          '${fmt(status.amount)}/${fmt(status.target.value)} ${unitLabel(def.unit)}\n${pct.round()}%',
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
                '${f.sevenDayAverage ? ' (trung bình 7 ngày)' : ''}, ${_scope(f.scope)}.',
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
