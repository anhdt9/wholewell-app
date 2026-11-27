/// Các thành phần giao diện dùng chung theo `docs/design/mvp-overview.md`.
library;

import 'package:journal_db/journal_db.dart';
import 'package:material_ui/material_ui.dart';

import '../../state/app_scope.dart';
import '../labels.dart';

/// Các nút chọn bữa theo cài đặt `Giờ trong ngày` (luôn giữ `Phụ` và [alwaysInclude]).
List<ButtonSegment<Meal>> enabledMealSegments(
  DayTimesSettings settings, {
  Meal? alwaysInclude,
}) =>
    [
      if (settings.hasBreakfast || alwaysInclude == Meal.breakfast)
        const ButtonSegment(value: Meal.breakfast, label: Text('Sáng')),
      if (settings.hasLunch || alwaysInclude == Meal.lunch)
        const ButtonSegment(value: Meal.lunch, label: Text('Trưa')),
      if (settings.hasDinner || alwaysInclude == Meal.dinner)
        const ButtonSegment(value: Meal.dinner, label: Text('Tối')),
      const ButtonSegment(value: Meal.snack, label: Text('Phụ')),
    ];

/// Hiển thị số kcal; biến mất hoàn toàn (không chiếm chỗ) khi bật "Ẩn số calo".
class CalorieText extends StatelessWidget {
  final double? kcal;
  final String prefix;
  final String suffix;
  final TextStyle? style;
  final bool? hideOverride;

  const CalorieText(
    this.kcal, {
    super.key,
    this.prefix = '',
    this.suffix = ' kcal',
    this.style,
    this.hideOverride,
  });

  @override
  Widget build(BuildContext context) {
    final hide = hideOverride ?? AppScope.maybeOf(context)?.hideCalories ?? false;
    if (hide || kcal == null) return const SizedBox.shrink();
    return Text('$prefix${kcal!.round()}$suffix', style: style);
  }
}

/// Nhãn chữ "ước tính" cho món công thức hoặc giá trị AI.
class EstimateChip extends StatelessWidget {
  final String label;
  const EstimateChip({super.key, this.label = 'ước tính'});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(color: cs.onSurfaceVariant),
      ),
    );
  }
}

/// Ghi chú an toàn / dữ liệu trung tính (không phải cờ vượt giới hạn).
class SafetyNote extends StatelessWidget {
  final String message;
  const SafetyNote({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, size: 18, color: cs.onSurfaceVariant),
          const SizedBox(width: 8),
          Expanded(
            child: Text(message, style: Theme.of(context).textTheme.bodySmall),
          ),
        ],
      ),
    );
  }
}

/// Lưu ý lịch trên Hôm nay: có nút "Đã hiểu" để thu gọn thành 1 dòng (tự mở lại khi lịch đổi).
class CollapsibleScheduleNote extends StatefulWidget {
  final List<String> messages;
  final bool collapsed;
  final VoidCallback onAcknowledge;

  const CollapsibleScheduleNote({
    super.key,
    required this.messages,
    required this.collapsed,
    required this.onAcknowledge,
  });

  @override
  State<CollapsibleScheduleNote> createState() => _CollapsibleScheduleNoteState();
}

class _CollapsibleScheduleNoteState extends State<CollapsibleScheduleNote> {
  bool _manualExpand = false;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    final showCompact = widget.collapsed && !_manualExpand;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: showCompact
          ? InkWell(
              onTap: () => setState(() => _manualExpand = true),
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 18, color: cs.onSurfaceVariant),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text('Lưu ý lịch (${widget.messages.length})', style: t.bodySmall),
                  ),
                  const Icon(Icons.chevron_right, size: 18),
                ],
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.info_outline, size: 18, color: cs.onSurfaceVariant),
                    const SizedBox(width: 8),
                    Expanded(child: Text('Lưu ý lịch', style: t.titleSmall)),
                    TextButton(
                      onPressed: () {
                        setState(() => _manualExpand = false);
                        widget.onAcknowledge();
                      },
                      child: const Text('Đã hiểu'),
                    ),
                  ],
                ),
                for (final m in widget.messages)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(m, style: t.bodySmall),
                  ),
              ],
            ),
    );
  }
}

/// Thẻ "Bạn có biết" đứng yên ở cuối màn Hôm nay.
class TipCard extends StatelessWidget {
  final String text;
  final VoidCallback onViewSource;
  final VoidCallback onHide;

  const TipCard({
    super.key,
    required this.text,
    required this.onViewSource,
    required this.onHide,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Bạn có biết', style: t.titleSmall),
          const SizedBox(height: 6),
          Text(text, style: t.bodyMedium),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton(onPressed: onViewSource, child: const Text('Xem nguồn ›')),
              TextButton(onPressed: onHide, child: const Text('Ẩn')),
            ],
          ),
        ],
      ),
    );
  }
}

/// Dòng mục đã ghi (chạm mở sửa, tôn trọng Ẩn số calo và cỡ chữ 200%).
class EntryTile extends StatelessWidget {
  final IconData leadingIcon;
  final String title;
  final String subtitle;
  final String timeText;
  final double? kcal;
  final bool isEstimate;
  final VoidCallback? onTap;

  const EntryTile({
    super.key,
    required this.leadingIcon,
    required this.title,
    required this.subtitle,
    required this.timeText,
    this.kcal,
    this.isEstimate = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return ListTile(
      minTileHeight: 56,
      leading: Icon(leadingIcon),
      title: Wrap(
        spacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text(title, style: t.bodyLarge),
          if (isEstimate) const EstimateChip(),
        ],
      ),
      subtitle: Text(subtitle, style: t.bodySmall),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(timeText, style: t.bodySmall),
          if (kcal != null && kcal! > 0)
            CalorieText(kcal, suffix: ' kcal', style: t.labelSmall),
        ],
      ),
      onTap: onTap,
    );
  }
}

class EmptyState extends StatelessWidget {
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const EmptyState({super.key, required this.message, this.actionLabel, this.onAction});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, textAlign: TextAlign.center),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 12),
              FilledButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}

class ErrorState extends StatelessWidget {
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const ErrorState({super.key, required this.message, this.actionLabel, this.onAction});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.warning_amber_rounded, size: 40, color: cs.error),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 16),
              FilledButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}

/// Khung chuẩn các bước thiết lập (`1/3`..`3/3`, nâng cấp): nút chính luôn thấy khi bàn phím mở.
class StepScaffold extends StatelessWidget {
  final String? stepLabel;
  final String? title;
  final VoidCallback? onBack;
  final Widget body;
  final String primaryLabel;
  final VoidCallback? onPrimary;
  final bool busy;
  final String? secondaryLabel;
  final VoidCallback? onSecondary;

  const StepScaffold({
    super.key,
    this.stepLabel,
    this.title,
    this.onBack,
    required this.body,
    required this.primaryLabel,
    this.onPrimary,
    this.busy = false,
    this.secondaryLabel,
    this.onSecondary,
  });

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: onBack == null
            ? null
            : IconButton(
                tooltip: 'Quay lại',
                icon: const Icon(Icons.arrow_back),
                onPressed: busy ? null : onBack,
              ),
        title: title != null ? Text(title!) : null,
        actions: [
          if (stepLabel != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Center(child: Text(stepLabel!, style: t.titleSmall)),
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                child: body,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  FilledButton(
                    style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                    onPressed: busy ? null : onPrimary,
                    child: busy
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(primaryLabel),
                  ),
                  if (secondaryLabel != null) ...[
                    const SizedBox(height: 8),
                    TextButton(
                      style: TextButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                      onPressed: busy ? null : onSecondary,
                      child: Text(secondaryLabel!),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Hộp thoại xác nhận gõ `XÓA` khi rút đồng ý hoặc xóa toàn bộ dữ liệu trên máy.
Future<bool> showWipeConfirmDialog(
  BuildContext context, {
  String title = 'Xóa toàn bộ dữ liệu?',
  String message =
      'Mọi dữ liệu trên máy này sẽ bị xóa và không lấy lại được, trừ khi bạn có bản sao lưu.',
  String actionLabel = 'Xóa toàn bộ',
}) async {
  var typed = '';
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setState) {
        final cs = Theme.of(ctx).colorScheme;
        final canConfirm = typed.trim() == 'XÓA';
        return AlertDialog(
          title: Text(title),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(message),
              const SizedBox(height: 12),
              const Text('Gõ XÓA để xác nhận.'),
              const SizedBox(height: 8),
              TextField(
                autofocus: true,
                textCapitalization: TextCapitalization.characters,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'XÓA',
                ),
                onChanged: (v) => setState(() => typed = v),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Hủy'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: cs.error,
                foregroundColor: cs.onError,
              ),
              onPressed: canConfirm ? () => Navigator.of(ctx).pop(true) : null,
              child: Text(actionLabel),
            ),
          ],
        );
      },
    ),
  );
  return ok == true;
}

/// Thông báo ngắn 7 giây sau khi ghi nước, kèm nút Hoàn tác.
void showUndoWaterSnack(
  BuildContext context, {
  required double ml,
  required Future<void> Function() onUndo,
}) {
  final messenger = ScaffoldMessenger.maybeOf(context);
  if (messenger == null) return;
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      duration: const Duration(seconds: 7),
      content: Text('Đã ghi ${fmtWaterMl(ml)} ml nước'),
      action: SnackBarAction(label: 'Hoàn tác', onPressed: onUndo),
    ));
}

/// Format giờ phút theo 24 giờ (`07:30`).
String fmtTime24(DateTime t) =>
    '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

/// Nhãn ngày ngắn gọn ("Hôm nay", "Hôm qua", "23/11").
String fmtShortDay(DateTime d, {DateTime? now}) {
  final n = now ?? DateTime.now();
  final today = DateTime(n.year, n.month, n.day);
  final target = DateTime(d.year, d.month, d.day);
  final diff = today.difference(target).inDays;
  if (diff == 0) return 'hôm nay, ${d.day}/${d.month}';
  if (diff == 1) return 'hôm qua, ${d.day}/${d.month}';
  return '${d.day}/${d.month}';
}

String fmtUnitShort(String u) => unitLabel(u);

/// Thanh tiến độ hai đoạn (thực phẩm vs bổ sung) theo `mvp-overview.md` (`LabeledProgress`).
class TwoSegmentProgressBar extends StatelessWidget {
  final double foodAmount;
  final double supplementAmount;
  final double targetAmount;
  final String? semanticsLabel;

  const TwoSegmentProgressBar({
    super.key,
    required this.foodAmount,
    required this.supplementAmount,
    required this.targetAmount,
    this.semanticsLabel,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final total = foodAmount + supplementAmount;
    final denom = targetAmount > 0 ? (total > targetAmount ? total : targetAmount) : total;
    final foodRatio = denom <= 0 ? 0.0 : (foodAmount / denom).clamp(0.0, 1.0);
    final suppRatio = denom <= 0 ? 0.0 : (supplementAmount / denom).clamp(0.0, 1.0 - foodRatio);
    final fillRatio = targetAmount <= 0
        ? (total > 0 ? 1.0 : 0.0)
        : (total / targetAmount).clamp(0.0, 1.0);

    final bar = ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: Container(
        height: 6,
        color: cs.surfaceContainerHighest,
        child: LayoutBuilder(builder: (context, constraints) {
          final w = constraints.maxWidth;
          final filledW = w * fillRatio;
          final sumRatio = foodRatio + suppRatio;
          final foodW = sumRatio <= 0 ? 0.0 : filledW * (foodRatio / sumRatio);
          final suppW = (filledW - foodW).clamp(0.0, filledW);
          return Row(
            children: [
              if (foodW > 0) Container(width: foodW, height: 6, color: cs.primary),
              if (suppW > 0) Container(width: suppW, height: 6, color: cs.tertiary),
            ],
          );
        }),
      ),
    );

    if (semanticsLabel == null) return bar;
    return Semantics(label: semanticsLabel, child: bar);
  }
}
