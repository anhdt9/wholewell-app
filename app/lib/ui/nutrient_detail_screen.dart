/// Màn Chi tiết chất: 2 tổng (mức khuyến nghị vs giới hạn an toàn), đóng góp hôm nay & 7 ngày qua.
library;

import 'package:health_engine/health_engine.dart';
import 'package:journal_db/journal_db.dart';
import 'package:material_ui/material_ui.dart';

import '../state/app_scope.dart';
import '../state/app_state.dart';
import 'common/common_widgets.dart';
import 'labels.dart';
import 'sources_screen.dart';

class NutrientDetailScreen extends StatefulWidget {
  final String nutrientId;
  const NutrientDetailScreen({super.key, required this.nutrientId});

  @override
  State<NutrientDetailScreen> createState() => _NutrientDetailScreenState();
}

class _NutrientDetailScreenState extends State<NutrientDetailScreen> {
  bool _sevenDayMode = false;

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final pack = state.pack;
    final def = pack.nutrients[widget.nutrientId];
    final daily = state.report();
    final period = state.periodReport7Days();
    final profile = state.profile;
    if (def == null || daily == null || profile == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Chi tiết chất')),
        body: const Center(child: Text('Chưa có dữ liệu cho chất này.')),
      );
    }

    final statusToday = daily.nutrients.where((n) => n.nutrientId == def.id).firstOrNull;
    final statusPeriod = period?.nutrients.where((n) => n.nutrientId == def.id).firstOrNull;
    final activeStatus = _sevenDayMode ? (statusPeriod ?? statusToday) : statusToday;
    if (activeStatus == null) {
      return Scaffold(
        appBar: AppBar(title: Text(def.nameVi)),
        body: const Center(child: Text('Chưa có dữ liệu cho chất này.')),
      );
    }

    final cl = CautionLabels(caution: state.caution);
    final t = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    final u = unitLabel(def.unit);
    final target = activeStatus.target;
    final foodAndFortified = activeStatus.foodAmount + activeStatus.fortifiedAmount;
    final hasScopedUl = def.ulScope != UlScope.total || def.ulKey != null;

    final contribs = _buildTodayContributions(state, def);
    final group = driGroupDefFor(pack, profile);
    final groupText = _groupDescription(group);

    return Scaffold(
      appBar: AppBar(title: Text(def.nameVi)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        children: [
          if (state.caution) ...[
            const SafetyNote(message: cautionBannerMessage),
            const SizedBox(height: 12),
          ],
          Wrap(
            spacing: 8,
            children: [
              ChoiceChip(
                label: const Text('Hôm nay'),
                selected: !_sevenDayMode,
                materialTapTargetSize: MaterialTapTargetSize.padded,
                onSelected: (_) => setState(() => _sevenDayMode = false),
              ),
              ChoiceChip(
                label: const Text('7 ngày'),
                selected: _sevenDayMode,
                materialTapTargetSize: MaterialTapTargetSize.padded,
                onSelected: (_) => setState(() => _sevenDayMode = true),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _sevenDayMode
                        ? 'Trung bình ${period?.loggedDaysCount ?? 0} ngày có ghi: ${fmt(activeStatus.totalAmount)} $u/ngày'
                        : 'Tổng mọi nguồn: ${fmt(activeStatus.totalAmount)} $u',
                    style: t.titleMedium,
                  ),
                  if (target != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      _targetLine(activeStatus, target, u, cl),
                      style: t.bodyMedium,
                    ),
                    const SizedBox(height: 10),
                    TwoSegmentProgressBar(
                      foodAmount: foodAndFortified,
                      supplementAmount: activeStatus.supplementAmount,
                      targetAmount: target.value,
                      semanticsLabel:
                          '${def.nameVi}, ${fmt(activeStatus.totalAmount)} trên ${fmt(target.value)} $u',
                    ),
                    if (target.isEstimate) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Chưa đủ dữ liệu để đặt mức khuyến nghị chính thức; đây là mức ước tính.',
                        style: t.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                      ),
                    ],
                  ],
                  const SizedBox(height: 8),
                  Text(
                    'Thực phẩm ${fmt(foodAndFortified)} · bổ sung ${fmt(activeStatus.supplementAmount)} $u',
                    style: t.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Tính vào giới hạn an toàn', style: t.titleSmall),
                  const SizedBox(height: 4),
                  if (activeStatus.ul != null) ...[
                    Text(
                      '${fmt(activeStatus.ulAmount)} / ${fmt(activeStatus.ul!)} $u'
                      '${activeStatus.ulAmount > activeStatus.ul! ? ' · Vượt giới hạn an toàn' : ''}',
                      style: t.titleMedium?.copyWith(
                        color: activeStatus.ulAmount > activeStatus.ul! ? cs.error : null,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _ulScopeDescription(def),
                      style: t.bodySmall,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'App không tính thuốc, trừ khi bạn ghi.',
                      style: t.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                    ),
                  ] else
                    Text(
                      'Chưa có giới hạn an toàn được đặt cho chất này.',
                      style: t.bodySmall,
                    ),
                ],
              ),
            ),
          ),
          if (def.id == 'iron') ...[
            const SizedBox(height: 12),
            const SafetyNote(
              message: 'Vitamin C hỗ trợ hấp thu sắt không heme (sắt từ nguồn thực vật).',
            ),
          ],
          const SizedBox(height: 16),
          if (!_sevenDayMode) ...[
            Text('Đóng góp hôm nay', style: t.titleMedium),
            const SizedBox(height: 8),
            if (contribs.isEmpty)
              Text(
                'Chưa có mục nào đóng góp ${def.nameVi} trong ngày này.',
                style: t.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
              )
            else
              for (final c in contribs)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(c.title),
                  subtitle: Text(
                    [
                      if (c.detail != null) c.detail!,
                      if (hasScopedUl)
                        c.countsTowardUl ? 'tính vào giới hạn' : 'không tính vào giới hạn',
                    ].join(' · '),
                  ),
                  trailing: Text(
                    '${fmt(c.amount)} $u',
                    style: t.titleSmall,
                  ),
                ),
          ] else ...[
            Text('7 ngày qua', style: t.titleMedium),
            const SizedBox(height: 8),
            _SevenDayBars(
              days: state.diary.window7Days,
              nutrientId: def.id,
              targetValue: target?.value,
              unit: u,
            ),
          ],
          const SizedBox(height: 16),
          Text(groupText, style: t.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const SourcesScreen()),
              ),
              child: const Text('Nguồn số liệu ›'),
            ),
          ),
        ],
      ),
    );
  }

  String _targetLine(NutrientStatus st, Target target, String u, CautionLabels cl) {
    final pct = (st.percentOfTarget ?? 0).round();
    if (target.isEstimate) {
      return cl.caution
          ? '$pct% mức tham chiếu ${fmt(target.value)} $u (ước tính)'
          : '$pct% mức ước tính ${fmt(target.value)} $u';
    }
    return cl.percentTarget(pct, '${fmt(target.value)} $u');
  }

  static String _ulScopeDescription(NutrientDef def) {
    return switch (def.id) {
      'vitA' => 'Chỉ tính retinol (bổ sung, thực phẩm tăng cường, nguồn động vật), không tính beta-caroten.',
      'folate' => 'Chỉ tính axit folic (bổ sung, thực phẩm tăng cường), không tính folate tự nhiên.',
      _ => switch (def.ulScope) {
          UlScope.total => 'Tính mọi nguồn (thực phẩm, tăng cường, bổ sung).',
          UlScope.supplement => 'Chỉ tính bổ sung bạn ghi, không tính thức ăn.',
          UlScope.synthetic => 'Chỉ tính từ bổ sung và thực phẩm tăng cường.',
        },
    };
  }

  static String _groupDescription(GroupDef g) {
    final sexText = switch (g.sex) {
      Sex.female => 'nữ',
      Sex.male => 'nam',
      null => 'người lớn',
    };
    final ageText = g.maxAge == null ? 'từ ${g.minAge} tuổi' : '${g.minAge}–${g.maxAge} tuổi';
    return 'Mức tham chiếu cho $sexText $ageText.';
  }

  List<_NutrientContribution> _buildTodayContributions(AppState state, NutrientDef def) {
    final pack = state.pack;
    final diary = state.diary;
    final list = <_NutrientContribution>[];

    for (final d in diary.todayDoses) {
      for (final l in d.lines) {
        final amt = l.amounts[def.id] ?? 0;
        if (amt <= 0) continue;
        final countsUl = lineCountsTowardUl(
          def,
          source: l.source,
          amounts: l.amounts,
          ulAmounts: l.ulAmounts,
        );
        final formName = l.form != null && l.form != NutrientForm.unknown
            ? (pack.compoundMeta[def.id]?[l.form!]?.nameVi ?? l.form!)
            : (l.uncertain ? 'chưa rõ dạng' : null);
        final origLabel = (l.labelAmount != null && l.labelUnit != null)
            ? 'nhãn ${fmt(l.labelAmount!)} ${unitLabel(l.labelUnit!)}'
            : null;
        final parts = [
          'bổ sung',
          if (formName != null) 'dạng $formName',
          if (origLabel != null) origLabel,
        ];
        list.add(_NutrientContribution(
          title: '${d.name ?? 'Bổ sung'} · ${fmt(d.servings)} lần',
          detail: parts.join(' · '),
          amount: amt,
          countsTowardUl: countsUl,
        ));
      }
    }

    for (final f in diary.todayFoods) {
      var sum = 0.0;
      var countsUl = false;
      var anyFortified = false;
      for (final l in f.lines) {
        if (lineCountsTowardUl(
          def,
          source: l.source,
          amounts: l.amounts,
          ulAmounts: l.ulAmounts,
        )) {
          countsUl = true;
        }
        final amt = l.amounts[def.id] ?? 0;
        if (amt <= 0) continue;
        sum += amt;
        if (l.source == IntakeSource.fortified) anyFortified = true;
      }
      if (sum <= 0) continue;
      list.add(_NutrientContribution(
        title: '${f.name} · ${fmt(f.portionQty)} ${f.portionUnit}',
        detail: anyFortified ? 'thực phẩm tăng cường' : 'thực phẩm',
        amount: sum,
        countsTowardUl: countsUl,
      ));
    }

    list.sort((a, b) => b.amount.compareTo(a.amount));
    return list;
  }
}

class _NutrientContribution {
  final String title;
  final String? detail;
  final double amount;
  final bool countsTowardUl;

  const _NutrientContribution({
    required this.title,
    this.detail,
    required this.amount,
    required this.countsTowardUl,
  });
}

class _SevenDayBars extends StatelessWidget {
  final List<({DateTime day, List<IntakeItem> items})> days;
  final String nutrientId;
  final double? targetValue;
  final String unit;

  const _SevenDayBars({
    required this.days,
    required this.nutrientId,
    required this.targetValue,
    required this.unit,
  });

  @override
  Widget build(BuildContext context) {
    if (days.isEmpty) return const Text('Chưa có dữ liệu trong 7 ngày qua.');
    final cs = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    final values = [
      for (final d in days)
        (
          day: d.day,
          amount: d.items.fold<double>(0, (s, it) => s + it.amount(nutrientId)),
        ),
    ];
    final maxAmount = values.fold<double>(targetValue ?? 0, (m, v) => v.amount > m ? v.amount : m);

    final textScale = MediaQuery.textScalerOf(context).scale(1);

    return Column(
      children: [
        for (final v in values)
          Semantics(
            label: '${v.day.day}/${v.day.month}: ${fmt(v.amount)} $unit',
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: textScale >= 1.3
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('${v.day.day}/${v.day.month}', style: t.bodySmall),
                            Flexible(
                              child: Text(
                                '${fmt(v.amount)} $unit',
                                textAlign: TextAlign.right,
                                style: t.bodySmall,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        LinearProgressIndicator(
                          value: maxAmount <= 0 ? 0 : (v.amount / maxAmount).clamp(0.0, 1.0),
                          color: cs.primary,
                          backgroundColor: cs.surfaceContainerHighest,
                        ),
                      ],
                    )
                  : Row(
                      children: [
                        SizedBox(
                          width: 48,
                          child: Text('${v.day.day}/${v.day.month}', style: t.bodySmall),
                        ),
                        Expanded(
                          child: LinearProgressIndicator(
                            value: maxAmount <= 0 ? 0 : (v.amount / maxAmount).clamp(0.0, 1.0),
                            color: cs.primary,
                            backgroundColor: cs.surfaceContainerHighest,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            '${fmt(v.amount)} $unit',
                            textAlign: TextAlign.right,
                            style: t.bodySmall,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
      ],
    );
  }
}
