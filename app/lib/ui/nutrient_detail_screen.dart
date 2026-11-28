/// Màn Chi tiết chất: 2 tổng (mức khuyến nghị vs giới hạn an toàn), đóng góp hôm nay & biểu đồ 7 ngày qua.
library;

import 'dart:math' as math;

import 'package:health_engine/health_engine.dart';
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
        body: const EmptyState(message: 'Chưa có dữ liệu cho chất này.'),
      );
    }

    final statusToday = daily.nutrients.where((n) => n.nutrientId == def.id).firstOrNull;
    final statusPeriod = period?.nutrients.where((n) => n.nutrientId == def.id).firstOrNull;
    final activeStatus = _sevenDayMode ? (statusPeriod ?? statusToday) : statusToday;
    if (activeStatus == null) {
      return Scaffold(
        appBar: AppBar(title: Text(def.nameVi)),
        body: const EmptyState(message: 'Chưa có dữ liệu cho chất này.'),
      );
    }

    final cl = CautionLabels(caution: state.caution);
    final t = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    final ww = context.wwColors;
    final u = unitLabel(def.unit);
    final target = activeStatus.target;
    final foodAndFortified = activeStatus.foodAmount + activeStatus.fortifiedAmount;
    final hasScopedUl = def.ulScope != UlScope.total || def.ulKey != null;
    final ulExceeded = activeStatus.ul != null && activeStatus.ulAmount > activeStatus.ul!;

    final contribs = _buildTodayContributions(state, def);
    final group = driGroupDefFor(pack, profile);
    final groupText = _groupDescription(group);

    return Scaffold(
      appBar: AppBar(title: Text(def.nameVi)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.xxl),
        children: [
          if (state.caution) ...[
            const SafetyNote(message: cautionBannerMessage),
            const SizedBox(height: AppSpacing.md),
          ],
          SizedBox(
            width: double.infinity,
            child: SegmentedButton<bool>(
              showSelectedIcon: false,
              segments: const [
                ButtonSegment<bool>(value: false, label: Text('Hôm nay')),
                ButtonSegment<bool>(value: true, label: Text('7 ngày')),
              ],
              selected: {_sevenDayMode},
              onSelectionChanged: (sel) => setState(() => _sevenDayMode = sel.first),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          SurfaceCard(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _sevenDayMode
                      ? 'Trung bình ${period?.loggedDaysCount ?? 0} ngày có ghi: ${fmt(activeStatus.totalAmount)} $u/ngày'
                      : 'Tổng mọi nguồn: ${fmt(activeStatus.totalAmount)} $u',
                  style: tabularNumberStyle(t.titleMedium),
                ),
                if (target != null) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    _targetLine(activeStatus, target, u, cl),
                    style: tabularNumberStyle(t.bodyMedium),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TwoSegmentProgressBar(
                    foodAmount: foodAndFortified,
                    supplementAmount: activeStatus.supplementAmount,
                    targetAmount: target.value,
                    overLimit: ulExceeded,
                    semanticsLabel:
                        '${def.nameVi}, ${fmt(activeStatus.totalAmount)} trên ${fmt(target.value)} $u',
                  ),
                  if (target.isEstimate) ...[
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Chưa đủ dữ liệu để đặt mức khuyến nghị chính thức; đây là mức ước tính.',
                      style: t.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                    ),
                  ],
                ],
                const SizedBox(height: AppSpacing.md),
                Wrap(
                  spacing: AppSpacing.lg,
                  runSpacing: AppSpacing.xs,
                  children: [
                    _SourceDotLabel(
                      color: ww.foodSource,
                      text: 'Thực phẩm ${fmt(foodAndFortified)} $u',
                    ),
                    _SourceDotLabel(
                      color: ww.supplementSource,
                      text: 'Bổ sung ${fmt(activeStatus.supplementAmount)} $u',
                    ),
                  ],
                ),
                const Divider(height: AppSpacing.xl),
                Text('Tính vào giới hạn an toàn', style: t.titleSmall),
                const SizedBox(height: AppSpacing.xs),
                if (activeStatus.ul != null) ...[
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.xs,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        '${fmt(activeStatus.ulAmount)} / ${fmt(activeStatus.ul!)} $u',
                        style: tabularNumberStyle(
                          t.titleMedium?.copyWith(
                            color: ulExceeded ? ww.onWarningContainer : cs.onSurface,
                          ),
                        ),
                      ),
                      if (ulExceeded)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: ww.warningContainer,
                            borderRadius: AppRadius.pillRadius,
                            border: Border.all(color: ww.warningBorder),
                          ),
                          child: Text(
                            'Vượt giới hạn an toàn',
                            style: t.labelSmall?.copyWith(
                              color: ww.onWarningContainer,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(_ulScopeDescription(def), style: t.bodySmall),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'App không tính thuốc, trừ khi bạn ghi.',
                    style: t.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                  ),
                ] else
                  Text(
                    'Chưa có giới hạn an toàn được đặt cho chất này.',
                    style: t.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                  ),
              ],
            ),
          ),
          if (def.id == 'iron') ...[
            const SizedBox(height: AppSpacing.md),
            const SafetyNote(
              message: 'Vitamin C hỗ trợ hấp thu sắt không heme (sắt từ nguồn thực vật).',
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          if (!_sevenDayMode) ...[
            Text('Đóng góp hôm nay', style: t.titleMedium),
            const SizedBox(height: AppSpacing.sm),
            if (contribs.isEmpty)
              SurfaceCard(
                child: Text(
                  'Chưa có mục nào đóng góp ${def.nameVi} trong ngày này.',
                  style: t.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
                ),
              )
            else
              SurfaceCard(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.xs,
                ),
                child: Column(
                  children: [
                    for (var i = 0; i < contribs.length; i++) ...[
                      if (i > 0)
                        Divider(
                          height: 1,
                          color: ww.outlineSubtle.withValues(alpha: 0.5),
                        ),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(contribs[i].title),
                        subtitle: Text(
                          [
                            if (contribs[i].detail != null) contribs[i].detail!,
                            if (hasScopedUl)
                              contribs[i].countsTowardUl
                                  ? 'tính vào giới hạn'
                                  : 'không tính vào giới hạn',
                          ].join(' · '),
                        ),
                        trailing: Text(
                          '${fmt(contribs[i].amount)} $u',
                          style: tabularNumberStyle(t.titleSmall),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
          ] else ...[
            Text('7 ngày qua', style: t.titleMedium),
            const SizedBox(height: AppSpacing.sm),
            _SevenDayChartCard(
              days: state.diary.window7Days,
              nutrientId: def.id,
              targetValue: target?.value,
              targetLabel: cl.caution ? 'Mức tham chiếu' : 'Mức khuyến nghị',
              ulValue: activeStatus.ul,
              unit: u,
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          Text(groupText, style: t.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
          const SizedBox(height: AppSpacing.xs),
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
          ?origLabel,
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

class _SourceDotLabel extends StatelessWidget {
  final Color color;
  final String text;
  const _SourceDotLabel({required this.color, required this.text});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Flexible(child: Text(text, style: tabularNumberStyle(t.bodySmall))),
      ],
    );
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

class _SevenDayChartCard extends StatelessWidget {
  final List<({DateTime day, List<IntakeItem> items})> days;
  final String nutrientId;
  final double? targetValue;
  final String targetLabel;
  final double? ulValue;
  final String unit;

  const _SevenDayChartCard({
    required this.days,
    required this.nutrientId,
    required this.targetValue,
    required this.targetLabel,
    required this.ulValue,
    required this.unit,
  });

  @override
  Widget build(BuildContext context) {
    if (days.isEmpty) {
      return const SurfaceCard(child: Text('Chưa có dữ liệu trong 7 ngày qua.'));
    }

    final cs = Theme.of(context).colorScheme;
    final ww = context.wwColors;
    final t = Theme.of(context).textTheme;

    final values = [
      for (final d in days)
        (
          day: d.day,
          amount: d.items.fold<double>(0, (s, it) => s + it.amount(nutrientId)),
        ),
    ];
    final maxData = values.fold<double>(0, (m, v) => v.amount > m ? v.amount : m);
    final showUlLine = ulValue != null && ulValue! > 0 && maxData >= 0.7 * ulValue!;
    final rawPeak = [
      maxData,
      if (targetValue != null && targetValue! > 0) targetValue!,
      if (showUlLine) ulValue!,
    ].fold<double>(0, math.max);
    final scaleMax = rawPeak <= 0 ? 1.0 : rawPeak * 1.15;

    return SurfaceCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 156,
            child: CustomPaint(
              painter: _SevenDayColumnsPainter(
                amounts: [for (final v in values) v.amount],
                scaleMax: scaleMax,
                targetValue: targetValue,
                ulValue: showUlLine ? ulValue : null,
                pastBarColor: cs.primary.withValues(alpha: 0.40),
                latestBarColor: cs.primary,
                trackColor: ww.subtleSurface,
                targetLineColor: cs.onSurfaceVariant.withValues(alpha: 0.65),
                ulLineColor: ww.warningBorder,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              for (var i = 0; i < values.length; i++)
                Expanded(
                  child: Semantics(
                    label: '${values[i].day.day}/${values[i].day.month}: ${fmt(values[i].amount)} $unit',
                    child: Column(
                      children: [
                        Text(
                          '${values[i].day.day}/${values[i].day.month}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: tabularNumberStyle(
                            t.labelSmall?.copyWith(
                              fontWeight: i == values.length - 1 ? FontWeight.w600 : FontWeight.w400,
                              color: i == values.length - 1 ? cs.onSurface : cs.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          if ((targetValue != null && targetValue! > 0) || showUlLine) ...[
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: AppSpacing.lg,
              runSpacing: AppSpacing.xs,
              children: [
                if (targetValue != null && targetValue! > 0)
                  _DashedLegendItem(
                    color: cs.onSurfaceVariant.withValues(alpha: 0.7),
                    text: '$targetLabel (${fmt(targetValue!)} $unit)',
                  ),
                if (showUlLine)
                  _DashedLegendItem(
                    color: ww.warningBorder,
                    text: 'Giới hạn an toàn (${fmt(ulValue!)} $unit)',
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _DashedLegendItem extends StatelessWidget {
  final Color color;
  final String text;
  const _DashedLegendItem({required this.color, required this.text});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 14, height: 2, color: color),
        const SizedBox(width: 6),
        Flexible(child: Text(text, style: tabularNumberStyle(t.bodySmall))),
      ],
    );
  }
}

class _SevenDayColumnsPainter extends CustomPainter {
  final List<double> amounts;
  final double scaleMax;
  final double? targetValue;
  final double? ulValue;
  final Color pastBarColor;
  final Color latestBarColor;
  final Color trackColor;
  final Color targetLineColor;
  final Color ulLineColor;

  const _SevenDayColumnsPainter({
    required this.amounts,
    required this.scaleMax,
    required this.targetValue,
    required this.ulValue,
    required this.pastBarColor,
    required this.latestBarColor,
    required this.trackColor,
    required this.targetLineColor,
    required this.ulLineColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (amounts.isEmpty || size.width <= 0 || size.height <= 0) return;

    final baselineY = size.height;
    final slotW = size.width / amounts.length;
    final barW = math.min(26.0, slotW * 0.54);

    for (var i = 0; i < amounts.length; i++) {
      final centerX = slotW * i + slotW / 2;
      final left = centerX - barW / 2;
      final ratio = scaleMax <= 0 ? 0.0 : (amounts[i] / scaleMax).clamp(0.0, 1.0);
      final barH = ratio > 0 ? math.max(4.0, size.height * ratio) : 2.0;
      final top = baselineY - barH;
      final rect = Rect.fromLTWH(left, top, barW, barH);
      final rrect = RRect.fromRectAndCorners(
        rect,
        topLeft: const Radius.circular(6),
        topRight: const Radius.circular(6),
      );
      final isLatest = i == amounts.length - 1;
      final color = ratio == 0
          ? trackColor
          : (isLatest ? latestBarColor : pastBarColor);
      canvas.drawRRect(rrect, Paint()..color = color);
    }

    if (targetValue != null && targetValue! > 0 && scaleMax > 0) {
      final y = (baselineY - size.height * (targetValue! / scaleMax)).clamp(1.0, baselineY - 1.0);
      _drawDashedLine(canvas, size.width, y, targetLineColor);
    }

    if (ulValue != null && ulValue! > 0 && scaleMax > 0) {
      final y = (baselineY - size.height * (ulValue! / scaleMax)).clamp(1.0, baselineY - 1.0);
      _drawDashedLine(canvas, size.width, y, ulLineColor);
    }
  }

  void _drawDashedLine(Canvas canvas, double width, double y, Color color) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5;
    const dash = 5.0;
    const gap = 4.0;
    var x = 0.0;
    while (x < width) {
      final endX = math.min(width, x + dash);
      canvas.drawLine(Offset(x, y), Offset(endX, y), paint);
      x += dash + gap;
    }
  }

  @override
  bool shouldRepaint(covariant _SevenDayColumnsPainter oldDelegate) {
    if (amounts.length != oldDelegate.amounts.length) return true;
    for (var i = 0; i < amounts.length; i++) {
      if (amounts[i] != oldDelegate.amounts[i]) return true;
    }
    return scaleMax != oldDelegate.scaleMax ||
        targetValue != oldDelegate.targetValue ||
        ulValue != oldDelegate.ulValue ||
        pastBarColor != oldDelegate.pastBarColor ||
        latestBarColor != oldDelegate.latestBarColor ||
        trackColor != oldDelegate.trackColor ||
        targetLineColor != oldDelegate.targetLineColor ||
        ulLineColor != oldDelegate.ulLineColor;
  }
}
