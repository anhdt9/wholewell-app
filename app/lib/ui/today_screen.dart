import 'package:health_engine/health_engine.dart';
import 'package:journal_db/journal_db.dart';
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
    final hasFood = state.todayItems.isNotEmpty;
    final cl = CautionLabels(caution: state.caution);
    final bumpedAge = state.ageBumpedNotice;
    final isToday = diary.isViewingToday;

    final scheduleFlags = isToday ? diary.scheduledUlFlags() : const <UlFlag>[];
    final combinedFlags = <UlFlag>[...r.ulFlags, ...scheduleFlags];
    final activeNotices = isToday
        ? [for (final n in diary.scheduleNotices()) if (n.severity == 'notice') n]
        : const <ScheduleNotice>[];
    final noticeSig = diary.scheduleNoticeSignature(activeNotices);
    final tipRule = diary.todayTipRule(hasUlWarnings: combinedFlags.isNotEmpty);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
      children: [
        if (combinedFlags.isNotEmpty) ...[
          _UlBanner(flags: combinedFlags, pack: pack),
          const SizedBox(height: 12),
        ],
        if (state.caution) ...[
          const SafetyNote(message: cautionBannerMessage),
          const SizedBox(height: 12),
        ],
        if (state.drivePendingDeleteActive) ...[
          const PendingDriveDeleteCard(),
          const SizedBox(height: 12),
        ],
        if (activeNotices.isNotEmpty) ...[
          CollapsibleScheduleNote(
            messages: [for (final n in activeNotices) n.messageVi],
            collapsed: noticeSig == diary.dismissedScheduleNoticeSig,
            onAcknowledge: () => diary.dismissScheduleNotices(noticeSig),
          ),
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
            onDismiss: state.diary.dismissAgeBumpedNotice,
          ),
          const SizedBox(height: 12),
        ],
        if (isToday && diary.todaySchedules.isNotEmpty) ...[
          _NextDoseCard(diary: diary),
          const SizedBox(height: 12),
        ],
        if (isToday &&
            !hasFood &&
            diary.todayDoses.isEmpty &&
            state.todayWaters.isEmpty &&
            state.todayWorkouts.isEmpty) ...[
          _EmptyTodayHintCard(
            onLogFood: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const AddFoodScreen()),
            ),
            onAddSupplement: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const ScanProductScreen()),
            ),
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
        Wrap(
          spacing: 8,
          runSpacing: 8,
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
        const SizedBox(height: 8),
        const _TwoSegmentLegend(),
        const SizedBox(height: 4),
        Builder(builder: (context) {
          final alertIds = {for (final f in combinedFlags) f.nutrientId};
          final visible = [
            for (final n in r.nutrients)
              if (pack.nutrients[n.nutrientId]!.group != 'macro' &&
                  (n.target != null || alertIds.contains(n.nutrientId)))
                if (switch (_nutrientFilter) {
                  _NutrientFilter.all => true,
                  _NutrientFilter.withSupplement => n.supplementAmount > 0,
                  _NutrientFilter.underTarget =>
                    n.target != null && n.totalAmount < n.target!.value,
                })
                  n,
          ];
          if (visible.isEmpty) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text('Không có vi chất nào thuộc mục lọc này.'),
            );
          }
          return Column(
            children: [
              for (final n in visible)
                _NutrientRow(
                  status: n,
                  def: pack.nutrients[n.nutrientId]!,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => NutrientDetailScreen(nutrientId: n.nutrientId),
                    ),
                  ),
                ),
            ],
          );
        }),
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
        if (tipRule != null) ...[
          TipCard(
            text: tipRule.tipVi,
            onViewSource: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => SourcesScreen(highlightRuleId: tipRule.id)),
            ),
            onHide: diary.hideTipCardForToday,
          ),
          const SizedBox(height: 16),
        ],
        Text(
          'Số liệu chỉ để tham khảo, không thay cho chẩn đoán hay tư vấn của bác sĩ. '
          'Nguồn: NASEM (qua NIH ODS), Dietary Guidelines 2025–2030, 2024 Adult Compendium.',
          style: t.bodySmall,
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
        await markScheduledDoseTaken(
          context,
          schedule: s,
          scheduleDay: todayStr,
          at: now,
        );
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

    if (pending.isEmpty) {
      return Card(
        child: ListTile(
          title: const Text('Lần uống hôm nay'),
          subtitle: const Text('Đã hoàn tất các lần uống theo lịch hôm nay.'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => const TodayDosesScreen()),
          ),
        ),
      );
    }

    final firstTime = pending.first.timeOfDay;
    final slotItems = [for (final s in pending) if (s.timeOfDay == firstTime) s];
    final first = slotItems.first;
    final phase = classifySchedulePhase(
      schedule: first,
      scheduleDay: todayStr,
      now: now,
    );
    final names = [
      for (final s in slotItems) prodMap[s.productId]?.name ?? 'Sản phẩm #${s.productId}',
    ].join(', ');

    return SurfaceCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Lần uống ${formatMinutesHhMm(firstTime)}',
                  style: t.titleSmall,
                ),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(builder: (_) => const TodayDosesScreen()),
                ),
                child: const Text('Xem ›'),
              ),
            ],
          ),
          Text(names, style: t.bodyMedium),
          const SizedBox(height: 8),
          if (phase == ScheduleWindowPhase.inWindow)
            FilledButton.tonal(
              onPressed: _busy ? null : () => _markSlotTaken(slotItems, todayStr, now),
              child: Text(slotItems.length > 1 ? 'Đã uống cả ${slotItems.length}' : 'Đã uống'),
            )
          else
            OutlinedButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const TodayDosesScreen()),
              ),
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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

class _EmptyTodayHintCard extends StatelessWidget {
  final VoidCallback onLogFood;
  final VoidCallback onAddSupplement;
  const _EmptyTodayHintCard({
    required this.onLogFood,
    required this.onAddSupplement,
  });

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Chưa có mục nào hôm nay', style: t.titleMedium),
            const SizedBox(height: 4),
            Text(
              'Ghi bữa ăn đầu tiên hoặc thêm sản phẩm bổ sung để xem tổng kết trong ngày.',
              style: t.bodySmall,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton.tonalIcon(
                  onPressed: onLogFood,
                  icon: const Icon(Icons.restaurant),
                  label: const Text('Ghi món ăn'),
                ),
                OutlinedButton.icon(
                  onPressed: onAddSupplement,
                  icon: const Icon(Icons.medication_outlined),
                  label: const Text('Thêm bổ sung'),
                ),
              ],
            ),
          ],
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
    final textScale = MediaQuery.textScalerOf(context).scale(1);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LayoutBuilder(builder: (context, constraints) {
              final stackStats = textScale >= 1.3 || constraints.maxWidth < 340;
              final stats = [
                _Stat(label: 'Calo nạp', value: '${r.energyInKcal.round()} kcal'),
                _Stat(label: labels.calorieGoalLabel, value: eer == null ? '—' : '$eer kcal'),
                _Stat(label: 'Tiêu hao khi tập', value: '${r.energyOutWorkoutKcal.round()} kcal'),
              ];
              if (stackStats) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (var i = 0; i < stats.length; i++) ...[
                      if (i > 0) const SizedBox(height: 8),
                      stats[i],
                    ],
                  ],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [for (final s in stats) Expanded(child: s)],
              );
            }),
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
  final String label;
  final String value;
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
    final cs = Theme.of(context).colorScheme;
    final color = s.status == RangeStatus.within ? cs.primary : cs.secondary;
    final note = switch (s.status) {
      RangeStatus.within => 'trong khoảng',
      RangeStatus.below => 'thấp hơn khoảng',
      RangeStatus.above => 'cao hơn khoảng',
    };
    final detail = '${s.percentEnergy.round()}% · ${s.amdr.min.round()}–${s.amdr.max.round()}% · $note';
    final progress = (s.percentEnergy / 100).clamp(0, 1).toDouble();
    final textScale = MediaQuery.textScalerOf(context).scale(1);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: LayoutBuilder(builder: (context, constraints) {
        final narrowOrLargeText = textScale >= 1.3 || constraints.maxWidth < 360;
        if (narrowOrLargeText) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 2,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(macroLabel(s.macro), style: Theme.of(context).textTheme.bodyMedium),
                  Text(detail, style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
              const SizedBox(height: 4),
              LinearProgressIndicator(value: progress, color: color),
            ],
          );
        }
        return Row(children: [
          SizedBox(width: 80, child: Text(macroLabel(s.macro))),
          Expanded(child: LinearProgressIndicator(value: progress, color: color)),
          const SizedBox(width: 8),
          Flexible(
            flex: 2,
            child: Text(detail, style: Theme.of(context).textTheme.bodySmall),
          ),
        ]);
      }),
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

class _TwoSegmentLegend extends StatelessWidget {
  const _TwoSegmentLegend();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    return Wrap(
      spacing: 16,
      runSpacing: 4,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 12, height: 6, color: cs.primary),
            const SizedBox(width: 6),
            Text('Thực phẩm', style: t.bodySmall),
          ],
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 12, height: 6, color: cs.tertiary),
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
  final VoidCallback onTap;

  const _NutrientRow({
    required this.status,
    required this.def,
    required this.onTap,
  });

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

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ResponsiveStatRow(
              leading: Text(name, style: t.bodyMedium),
              trailing: Text(valueText, style: t.bodySmall),
            ),
            const SizedBox(height: 6),
            TwoSegmentProgressBar(
              foodAmount: foodAndFort,
              supplementAmount: status.supplementAmount,
              targetAmount: target?.value ?? (status.ul ?? status.totalAmount),
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
