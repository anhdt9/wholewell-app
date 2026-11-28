/// Màn Hôm nay: cảnh báo giới hạn an toàn, nhắc lịch, năng lượng & đa lượng, đường, nước và vi chất.
library;

import 'dart:async';

import 'package:flutter/services.dart' show HapticFeedback;
import 'package:health_engine/health_engine.dart';
import 'package:journal_db/models.dart';
import 'package:material_ui/material_ui.dart';

import '../state/app_scope.dart';
import '../state/diary_controller.dart';
import 'add_food_screen.dart';
import 'common/common_widgets.dart';
import 'day_times_screen.dart';
import 'drive_backup_screens.dart';
import 'labels.dart';
import 'nutrient_detail_screen.dart';
import 'profile_screen.dart';
import 'schedule_dose_helper.dart';
import 'sources_screen.dart';
import 'supplements_screen.dart';
import 'today_doses_screen.dart';
import 'water_log_screen.dart';

enum _NutrientFilter { all, withSupplement, underTarget }

/// Tổng kết ngày: cảnh báo UL, dòng thận trọng, nhắc tuổi, calo, đường, vi chất, nước.
class TodayScreen extends StatefulWidget {
  const TodayScreen({super.key});

  @override
  State<TodayScreen> createState() => _TodayScreenState();
}

class _TodayScreenState extends State<TodayScreen> {
  _NutrientFilter _nutrientFilter = _NutrientFilter.all;

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final r = state.report();
    if (r == null) return const SizedBox.shrink();
    final pack = state.pack;
    final diary = state.diary;
    final t = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    final ww = context.wwColors;
    final hasFood = state.todayItems.isNotEmpty;
    final cl = CautionLabels(caution: state.caution);
    final bumpedAge = state.ageBumpedNotice;
    final isToday = diary.isViewingToday;

    final scheduleFlags = isToday ? diary.scheduledUlFlags() : const <UlFlag>[];
    final combinedFlags = <UlFlag>[...r.ulFlags, ...scheduleFlags];
    final activeNotices = isToday
        ? [
            for (final n in diary.scheduleNotices())
              if (n.severity == 'notice') n,
          ]
        : const <ScheduleNotice>[];
    final noticeSig = diary.scheduleNoticeSignature(activeNotices);
    final tipRule = diary.todayTipRule(hasUlWarnings: combinedFlags.isNotEmpty);

    return ListView(
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, 96),
      children: [
        if (combinedFlags.isNotEmpty) ...[
          _UlBanner(flags: combinedFlags, pack: pack),
          const SizedBox(height: AppSpacing.md),
        ],
        if (state.caution) ...[const SafetyNote(message: cautionBannerMessage), const SizedBox(height: AppSpacing.md)],
        if (state.drivePendingDeleteActive) ...[const PendingDriveDeleteCard(), const SizedBox(height: AppSpacing.md)],
        if (activeNotices.isNotEmpty) ...[
          CollapsibleScheduleNote(
            messages: [for (final n in activeNotices) n.messageVi],
            collapsed: noticeSig == diary.dismissedScheduleNoticeSig,
            onAcknowledge: () => diary.dismissScheduleNotices(noticeSig),
          ),
          const SizedBox(height: AppSpacing.md),
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
            onDismiss: state.diary.dismissAgeBumpedNotice,
          ),
          const SizedBox(height: AppSpacing.md),
        ],
        if (isToday && diary.todaySchedules.isNotEmpty) ...[
          _NextDoseCard(diary: diary),
          const SizedBox(height: AppSpacing.md),
        ],
        if (isToday &&
            !hasFood &&
            diary.todayDoses.isEmpty &&
            state.todayWaters.isEmpty &&
            state.todayWorkouts.isEmpty) ...[
          _EmptyTodayHintCard(
            onLogFood: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const AddFoodScreen())),
            onAddSupplement: () =>
                Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const ScanProductScreen())),
          ),
          const SizedBox(height: AppSpacing.md),
        ],
        _EnergyAndMacroCard(report: r, labels: cl, hideCalories: state.hideCalories, hasFood: hasFood),
        const SizedBox(height: AppSpacing.md),
        _SugarCard(sugar: r.sugar, maxMeal: pack.addedSugarMaxGramsPerMeal),
        const SizedBox(height: AppSpacing.md),
        _WaterCard(
          totalMl: state.diary.todayWaterTotalMl,
          hasEntries: state.todayWaters.isNotEmpty,
          quickMl: state.lastWaterMl,
          onOpenLog: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const WaterLogScreen())),
          onQuickAdd: () async {
            final ml = state.lastWaterMl;
            final id = await state.diary.quickAddWater();
            if (id != null && context.mounted) {
              unawaited(HapticFeedback.selectionClick());
              showUndoWaterSnack(context, ml: ml, onUndo: () => state.diary.deleteWater(id));
            }
          },
        ),
        const SizedBox(height: AppSpacing.xl),
        Text('Vitamin và khoáng chất', style: t.titleMedium),
        const SizedBox(height: AppSpacing.xs),
        Text(cl.nutrientsSubtitle, style: t.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
        const SizedBox(height: AppSpacing.md),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.xs,
          children: [
            ChoiceChip(
              label: const Text('Tất cả'),
              selected: _nutrientFilter == _NutrientFilter.all,
              materialTapTargetSize: MaterialTapTargetSize.padded,
              onSelected: (_) => setState(() => _nutrientFilter = _NutrientFilter.all),
            ),
            ChoiceChip(
              label: const Text('Có bổ sung'),
              selected: _nutrientFilter == _NutrientFilter.withSupplement,
              materialTapTargetSize: MaterialTapTargetSize.padded,
              onSelected: (_) => setState(() => _nutrientFilter = _NutrientFilter.withSupplement),
            ),
            ChoiceChip(
              label: Text(cl.underTargetFilter),
              selected: _nutrientFilter == _NutrientFilter.underTarget,
              materialTapTargetSize: MaterialTapTargetSize.padded,
              onSelected: (_) => setState(() => _nutrientFilter = _NutrientFilter.underTarget),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        const _TwoSegmentLegend(),
        const SizedBox(height: AppSpacing.sm),
        Builder(
          builder: (context) {
            final alertIds = {for (final f in combinedFlags) f.nutrientId};
            final visible = [
              for (final n in r.nutrients)
                if (pack.nutrients[n.nutrientId]!.group != 'macro' &&
                    (n.target != null || alertIds.contains(n.nutrientId)))
                  if (switch (_nutrientFilter) {
                    _NutrientFilter.all => true,
                    _NutrientFilter.withSupplement => n.supplementAmount > 0,
                    _NutrientFilter.underTarget => n.target != null && n.totalAmount < n.target!.value,
                  })
                    n,
            ];
            if (visible.isEmpty) {
              return const SurfaceCard(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
                  child: Text('Không có vi chất nào thuộc mục lọc này.'),
                ),
              );
            }
            return SurfaceCard(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.xs),
              child: Column(
                children: [
                  for (var i = 0; i < visible.length; i++) ...[
                    if (i > 0) Divider(height: 1, color: ww.outlineSubtle.withValues(alpha: 0.6)),
                    _NutrientRow(
                      status: visible[i],
                      def: pack.nutrients[visible[i].nutrientId]!,
                      overLimit: alertIds.contains(visible[i].nutrientId),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => NutrientDetailScreen(nutrientId: visible[i].nutrientId),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
        ),
        const SizedBox(height: AppSpacing.lg),
        if (tipRule != null) ...[
          TipCard(
            text: tipRule.tipVi,
            onViewSource: () =>
                Navigator.of(context)
                    .push(MaterialPageRoute<void>(builder: (_) => SourcesScreen(highlightRuleId: tipRule.id))),
            onHide: diary.hideTipCardForToday,
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
        Text(
          'Số liệu chỉ để tham khảo, không thay cho chẩn đoán hay tư vấn của bác sĩ. '
          'Nguồn: NASEM (qua NIH ODS), Dietary Guidelines 2025–2030, 2024 Adult Compendium.',
          style: t.bodySmall?.copyWith(color: cs.onSurfaceVariant),
        ),
      ],
    );
  }
}

class _NextDoseCard extends StatefulWidget {
  final DiaryController diary;
  const _NextDoseCard({required this.diary});

  @override
  State<_NextDoseCard> createState() => _NextDoseCardState();
}

class _NextDoseCardState extends State<_NextDoseCard> {
  bool _busy = false;

  Future<void> _markSlotTaken(List<Schedule> slotItems, String todayStr, DateTime now) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      for (final s in slotItems) {
        if (!mounted) break;
        await markScheduledDoseTaken(context, schedule: s, scheduleDay: todayStr, at: now);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final diary = widget.diary;
    final now = DateTime.now();
    final todayStr = dayKey(diary.day);
    final occMap = {for (final o in diary.todayOccurrences) o.scheduleId: o};
    final prodMap = {for (final s in diary.allProducts) s.product.id: s.product};
    final pending = [
      for (final s in diary.todaySchedules)
        if (!occMap.containsKey(s.id)) s,
    ];
    final t = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    final ww = context.wwColors;

    if (pending.isEmpty) {
      return Card(
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        child: ListTile(
          leading: CircleAvatar(
            radius: 18,
            backgroundColor: ww.subtleSurface,
            child: Icon(LucideIcons.circleCheck, size: 18, color: ww.inRange),
          ),
          title: const Text('Lần uống hôm nay'),
          subtitle: const Text('Đã hoàn tất các lần uống theo lịch hôm nay.'),
          trailing: Icon(LucideIcons.chevronRight, color: cs.onSurfaceVariant),
          onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const TodayDosesScreen())),
        ),
      );
    }

    final firstTime = pending.first.timeOfDay;
    final slotItems = [
      for (final s in pending)
        if (s.timeOfDay == firstTime) s,
    ];
    final first = slotItems.first;
    final phase = classifySchedulePhase(schedule: first, scheduleDay: todayStr, now: now);
    final names = [for (final s in slotItems) prodMap[s.productId]?.name ?? 'Sản phẩm #${s.productId}'].join(', ');

    return SurfaceCard(
      color: cs.primaryContainer.withValues(alpha: 0.32),
      borderColor: cs.primary.withValues(alpha: 0.28),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.xs,
            crossAxisAlignment: WrapCrossAlignment.center,
            alignment: WrapAlignment.spaceBetween,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: ww.cardSurface,
                    child: Icon(LucideIcons.pill, size: 16, color: cs.primary),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text('Lần uống ${formatMinutesHhMm(firstTime)}', style: tabularNumberStyle(t.titleSmall)),
                ],
              ),
              TextButton(
                onPressed: () =>
                    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const TodayDosesScreen())),
                child: const Text('Xem tất cả ›'),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(names, style: t.bodyMedium),
          const SizedBox(height: AppSpacing.md),
          if (phase == ScheduleWindowPhase.inWindow)
            FilledButton.tonalIcon(
              onPressed: _busy ? null : () => _markSlotTaken(slotItems, todayStr, now),
              icon: const Icon(LucideIcons.checkCheck, size: 18),
              label: Text(slotItems.length > 1 ? 'Đã uống cả ${slotItems.length}' : 'Đã uống'),
            )
          else
            OutlinedButton(
              onPressed: () =>
                  Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const TodayDosesScreen())),
              child: Text(phase == ScheduleWindowPhase.early ? 'Uống sớm?' : 'Đánh dấu'),
            ),
        ],
      ),
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
    return SurfaceCard(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      child: Wrap(
        spacing: AppSpacing.sm,
        runSpacing: AppSpacing.xs,
        crossAxisAlignment: WrapCrossAlignment.center,
        alignment: WrapAlignment.spaceBetween,
        children: [
          Text('Tuổi trong hồ sơ đã được cập nhật thành $age.'),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextButton(onPressed: onEdit, child: const Text('Sửa')),
              IconButton(tooltip: 'Đóng', icon: const Icon(LucideIcons.x, size: 18), onPressed: onDismiss),
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
    final cs = Theme.of(context).colorScheme;
    final ww = context.wwColors;
    final textScale = MediaQuery.textScalerOf(context).scale(1);

    final info = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircleAvatar(
          radius: 20,
          backgroundColor: ww.subtleSurface,
          child: Icon(LucideIcons.droplet, size: 20, color: cs.primary),
        ),
        const SizedBox(width: AppSpacing.md),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Nước uống', style: t.titleSmall),
              const SizedBox(height: 2),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: Text(
                  hasEntries ? 'Đã uống ${fmtWaterMl(totalMl)} ml' : 'Chưa ghi nước hôm nay',
                  key: ValueKey('${hasEntries}_${totalMl.round()}'),
                  style: tabularNumberStyle(
                    t.bodyMedium?.copyWith(color: hasEntries ? cs.onSurface : cs.onSurfaceVariant),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );

    final quickButton = OutlinedButton(
      style: OutlinedButton.styleFrom(minimumSize: const Size(48, 48), shape: const StadiumBorder()),
      onPressed: onQuickAdd,
      child: Text('+${fmtWaterMl(quickMl)} ml', style: tabularNumberStyle(null)),
    );

    return SurfaceCard(
      padding: EdgeInsets.zero,
      child: ClipRRect(
        borderRadius: AppRadius.cardRadius,
        child: InkWell(
          onTap: onOpenLog,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: textScale >= 1.3
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      info,
                      const SizedBox(height: AppSpacing.md),
                      Align(alignment: Alignment.centerRight, child: quickButton),
                    ],
                  )
                : Row(
                    children: [
                      Expanded(child: info),
                      const SizedBox(width: AppSpacing.md),
                      quickButton,
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

class _EmptyTodayHintCard extends StatelessWidget {
  final VoidCallback onLogFood;
  final VoidCallback onAddSupplement;
  const _EmptyTodayHintCard({required this.onLogFood, required this.onAddSupplement});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    return SurfaceCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Chưa có mục nào hôm nay', style: t.titleMedium),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Ghi bữa ăn đầu tiên hoặc thêm sản phẩm bổ sung để xem tổng kết trong ngày.',
            style: t.bodySmall?.copyWith(color: cs.onSurfaceVariant),
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              FilledButton.tonalIcon(
                onPressed: onLogFood,
                icon: Icon(LucideIcons.utensils, size: 18, color: cs.onSecondaryContainer),
                label: const Text('Ghi món ăn'),
              ),
              OutlinedButton.icon(
                onPressed: onAddSupplement,
                icon: Icon(LucideIcons.pill, size: 18, color: cs.primary),
                label: const Text('Thêm bổ sung'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EnergyAndMacroCard extends StatelessWidget {
  final DailyReport report;
  final CautionLabels labels;
  final bool hideCalories;
  final bool hasFood;

  const _EnergyAndMacroCard({
    required this.report,
    required this.labels,
    required this.hideCalories,
    required this.hasFood,
  });

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    final ww = context.wwColors;
    final r = report;
    final eer = r.eerKcal;
    final textScale = MediaQuery.textScalerOf(context).scale(1);

    return SurfaceCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!hideCalories) ...[
            Text('Năng lượng', style: t.titleMedium),
            const SizedBox(height: AppSpacing.md),
            LayoutBuilder(
              builder: (context, constraints) {
                final stackGauge = textScale >= 1.3 || constraints.maxWidth < 320;
                final gauge = EnergyArcGauge(
                  consumedKcal: r.energyInKcal,
                  targetKcal: (eer ?? 0).toDouble(),
                  size: 128,
                  hideCaloriesOverride: false,
                );
                final details = Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _StatLine(label: labels.calorieGoalLabel, value: eer == null ? '—' : '$eer kcal'),
                    const SizedBox(height: AppSpacing.sm),
                    _StatLine(label: 'Tiêu hao khi tập', value: '${r.energyOutWorkoutKcal.round()} kcal'),
                    if (eer != null) ...[
                      const SizedBox(height: AppSpacing.sm),
                      Text(labels.calorieGoalExplainer, style: t.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
                    ],
                    if (r.eerNotComputed != null) ...[
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        reasonLabel(r.eerNotComputed!, caution: labels.caution),
                        style: t.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                      ),
                    ],
                  ],
                );

                if (stackGauge) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(child: gauge),
                      const SizedBox(height: AppSpacing.md),
                      details,
                    ],
                  );
                }
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    gauge,
                    const SizedBox(width: AppSpacing.lg),
                    Expanded(child: details),
                  ],
                );
              },
            ),
            const Divider(height: AppSpacing.xl),
          ],
          Text('Tỷ lệ đạm, béo, bột đường', style: t.titleMedium),
          const SizedBox(height: AppSpacing.xs),
          Text(labels.macroShareSubtitle, style: t.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
          const SizedBox(height: AppSpacing.md),
          if (!hasFood)
            Text('Chưa ghi bữa ăn nào hôm nay.', style: t.bodyMedium?.copyWith(color: cs.onSurfaceVariant))
          else ...[
            if (hideCalories) ...[
              LayoutBuilder(
                builder: (context, constraints) {
                  final stackCols = textScale >= 1.3 || constraints.maxWidth < 300;
                  final pills = [
                    for (final m in r.macros)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                        decoration: BoxDecoration(color: ww.subtleSurface, borderRadius: AppRadius.controlRadius),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(macroLabel(m.macro), style: t.labelMedium?.copyWith(color: cs.onSurfaceVariant)),
                            const SizedBox(height: 2),
                            Text(
                              '${m.percentEnergy.round()}%',
                              style: tabularNumberStyle(t.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                            ),
                          ],
                        ),
                      ),
                  ];
                  if (stackCols) {
                    return Wrap(spacing: AppSpacing.sm, runSpacing: AppSpacing.sm, children: pills);
                  }
                  return Row(
                    children: [
                      for (var i = 0; i < pills.length; i++) ...[
                        if (i > 0) const SizedBox(width: AppSpacing.sm),
                        Expanded(child: pills[i]),
                      ],
                    ],
                  );
                },
              ),
              const SizedBox(height: AppSpacing.md),
            ],
            for (final m in r.macros) _MacroRow(share: m),
          ],
        ],
      ),
    );
  }
}

class _StatLine extends StatelessWidget {
  final String label;
  final String value;
  const _StatLine({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: t.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: Text(value, key: ValueKey(value), style: tabularNumberStyle(t.titleMedium)),
        ),
      ],
    );
  }
}

class _MacroRow extends StatelessWidget {
  final MacroShare share;
  const _MacroRow({required this.share});

  @override
  Widget build(BuildContext context) {
    final s = share;
    final ww = context.wwColors;
    final cs = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    final macroColor = switch (s.macro) {
      'protein' => ww.macroProtein,
      'fat' => ww.macroFat,
      'carbohydrate' => ww.macroCarb,
      _ => cs.primary,
    };
    final note = switch (s.status) {
      RangeStatus.within => 'trong khoảng',
      RangeStatus.below => 'thấp hơn khoảng',
      RangeStatus.above => 'cao hơn khoảng',
    };
    final pctText = '${s.percentEnergy.round()}%';
    final rangeNote = '${s.amdr.min.round()}–${s.amdr.max.round()}% · $note';
    final textScale = MediaQuery.textScalerOf(context).scale(1);

    final bar = TargetRangeBar(
      percent: s.percentEnergy,
      minPercent: s.amdr.min,
      maxPercent: s.amdr.max,
      activeColor: macroColor,
      semanticsLabel:
          '${macroLabel(s.macro)} $pctText, khoảng khuyến nghị ${s.amdr.min.round()} đến ${s.amdr.max.round()}%, $note',
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final narrowOrLargeText = textScale >= 1.3 || constraints.maxWidth < 340;
          if (narrowOrLargeText) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: 2,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text('${macroLabel(s.macro)} $pctText', style: tabularNumberStyle(t.bodyMedium)),
                    Text(rangeNote, style: tabularNumberStyle(t.bodySmall?.copyWith(color: cs.onSurfaceVariant))),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                bar,
              ],
            );
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(macroLabel(s.macro), style: t.bodyMedium),
                  const SizedBox(width: AppSpacing.sm),
                  Text(pctText, style: tabularNumberStyle(t.bodyMedium?.copyWith(fontWeight: FontWeight.w600))),
                  const Spacer(),
                  Flexible(
                    child: Text(
                      rangeNote,
                      textAlign: TextAlign.right,
                      style: tabularNumberStyle(t.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              bar,
            ],
          );
        },
      ),
    );
  }
}

class _SugarCard extends StatelessWidget {
  final SugarCheck sugar;
  final double maxMeal;
  const _SugarCard({required this.sugar, required this.maxMeal});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    final ww = context.wwColors;
    final hasOverMeal = sugar.mealsOverLimit.isNotEmpty;

    return SurfaceCard(
      color: hasOverMeal ? ww.warningContainer : null,
      borderColor: hasOverMeal ? ww.warningBorder : null,
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ResponsiveStatRow(
            leading: Text(
              'Đường bổ sung',
              style: t.titleSmall?.copyWith(color: hasOverMeal ? ww.onWarningContainer : cs.onSurface),
            ),
            trailing: Text(
              '${fmt(sugar.addedSugarG)} g · ~${sugar.percentEnergy.round()}%',
              style: tabularNumberStyle(
                t.titleSmall?.copyWith(color: hasOverMeal ? ww.onWarningContainer : cs.onSurface),
              ),
            ),
          ),
          for (final a in sugar.mealsOverLimit) ...[
            const SizedBox(height: AppSpacing.xs),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Icon(LucideIcons.triangleAlert, size: 16, color: ww.onWarningContainer),
                ),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(
                    'Bữa ${mealLabel(a.meal)}: ${fmt(a.grams)} g, vượt ${fmt(maxMeal)} g mỗi bữa.',
                    style: tabularNumberStyle(t.bodySmall?.copyWith(color: ww.onWarningContainer)),
                  ),
                ),
              ],
            ),
          ],
          if (sugar.unknownSugarFoods.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Chưa tính đường bổ sung của ${sugar.unknownSugarFoods.length} món (nhãn không ghi riêng).',
              style: t.bodySmall?.copyWith(color: hasOverMeal ? ww.onWarningContainer : cs.onSurfaceVariant),
            ),
          ],
        ],
      ),
    );
  }
}

class _TwoSegmentLegend extends StatelessWidget {
  const _TwoSegmentLegend();

  @override
  Widget build(BuildContext context) {
    final ww = context.wwColors;
    final t = Theme.of(context).textTheme;
    return Wrap(
      spacing: AppSpacing.lg,
      runSpacing: AppSpacing.xs,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: ww.foodSource, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
            Text('Thực phẩm', style: t.bodySmall),
          ],
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: ww.supplementSource, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
            Text('Bổ sung', style: t.bodySmall),
          ],
        ),
      ],
    );
  }
}

class _NutrientRow extends StatelessWidget {
  final NutrientStatus status;
  final NutrientDef def;
  final bool overLimit;
  final VoidCallback onTap;

  const _NutrientRow({required this.status, required this.def, required this.overLimit, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final target = status.target;
    final pct = status.percentOfTarget ?? 0;
    final u = unitLabel(def.unit);
    final name = def.nameVi + (target?.isEstimate == true ? ' (ước tính)' : '');
    final valueText = target != null
        ? '${fmt(status.totalAmount)}/${fmt(target.value)} $u · ${pct.round()}%'
        : '${fmt(status.totalAmount)} $u';
    final foodAndFort = status.foodAmount + status.fortifiedAmount;
    final t = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    final ww = context.wwColors;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ResponsiveStatRow(
              leading: Text(name, style: t.bodyMedium),
              trailing: Text(
                valueText,
                style: tabularNumberStyle(
                  t.bodySmall?.copyWith(
                    color: overLimit ? ww.onWarningContainer : cs.onSurfaceVariant,
                    fontWeight: overLimit ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 6),
            TwoSegmentProgressBar(
              foodAmount: foodAndFort,
              supplementAmount: status.supplementAmount,
              targetAmount: target?.value ?? (status.ul ?? status.totalAmount),
              overLimit: overLimit,
              semanticsLabel: '$name, $valueText',
            ),
          ],
        ),
      ),
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
    final ww = context.wwColors;
    final t = Theme.of(context).textTheme;
    return SurfaceCard(
      color: ww.warningContainer,
      borderColor: ww.warningBorder,
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(LucideIcons.triangleAlert, size: 20, color: ww.onWarningContainer),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  'Vượt giới hạn an toàn',
                  style: t.titleSmall?.copyWith(fontWeight: FontWeight.w600, color: ww.onWarningContainer),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          for (final f in flags) ...[
            Text(
              '${pack.nutrients[f.nutrientId]!.nameVi}: ${fmt(f.amount)} / ${fmt(f.ul)} '
              '${unitLabel(pack.nutrients[f.nutrientId]!.unit)}'
              '${f.isSevenDayAverage ? ' (trung bình ${f.dayCount} ngày)' : ''}, ${_scope(f.scope)}'
              ' · Vượt ${fmt(f.excess)} (${f.percentOver.round()}%).',
              style: tabularNumberStyle(t.bodyMedium?.copyWith(color: ww.onWarningContainer)),
            ),
            const SizedBox(height: 2),
          ],
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Xem lại liều bổ sung; hỏi bác sĩ hoặc dược sĩ nếu đang dùng theo đơn.',
            style: t.bodySmall?.copyWith(color: ww.onWarningContainer),
          ),
        ],
      ),
    );
  }
}
