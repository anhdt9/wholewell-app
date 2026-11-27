/// Các thành phần giao diện dùng chung theo `docs/design/mvp-overview.md`.
library;

import 'package:journal_db/journal_db.dart';
import 'package:material_ui/material_ui.dart';

import '../../state/app_scope.dart';
import '../design_system/tokens.dart';
import '../labels.dart';

export '../design_system/tokens.dart';
export 'data_viz.dart';

/// Khung thẻ viền chuẩn (dùng chung thay vì copy-paste `BoxDecoration` bo góc 12).
class SurfaceCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final Color? color;
  final Color? borderColor;

  const SurfaceCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.md),
    this.margin,
    this.color,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final ww = context.wwColors;
    return Container(
      width: double.infinity,
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: color ?? ww.cardSurface,
        borderRadius: AppRadius.cardRadius,
        border: Border.all(color: borderColor ?? cs.outlineVariant),
      ),
      child: child,
    );
  }
}

/// Hàng 2 đầu tự động chuyển sang xếp dọc khi cỡ chữ hệ thống >= 1.3x.
class ResponsiveStatRow extends StatelessWidget {
  final Widget leading;
  final Widget trailing;
  final double gap;

  const ResponsiveStatRow({
    super.key,
    required this.leading,
    required this.trailing,
    this.gap = AppSpacing.sm,
  });

  @override
  Widget build(BuildContext context) {
    final textScale = MediaQuery.textScalerOf(context).scale(1);
    if (textScale >= 1.3) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          leading,
          SizedBox(height: gap / 2),
          trailing,
        ],
      );
    }
    return Row(
      children: [
        Expanded(child: leading),
        SizedBox(width: gap),
        trailing,
      ],
    );
  }
}

/// Hiển thị thông báo SnackBar nhất quán trên toàn app.
abstract final class AppFeedback {
  static void showSnack(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 4),
    SnackBarAction? action,
  }) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          duration: duration,
          content: Text(message),
          action: action,
        ),
      );
  }
}

/// Hộp thoại xác nhận hành động 2 nút chuẩn (`Hủy` / [confirmLabel]).
Future<bool> showConfirmDialog(
  BuildContext context, {
  String? title,
  String? message,
  String cancelLabel = 'Hủy',
  required String confirmLabel,
  bool destructive = false,
}) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: title == null ? null : Text(title),
      content: message == null ? null : Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: Text(cancelLabel),
        ),
        FilledButton(
          style: destructive
              ? FilledButton.styleFrom(
                  backgroundColor: Theme.of(ctx).colorScheme.error,
                  foregroundColor: Theme.of(ctx).colorScheme.onError,
                )
              : null,
          onPressed: () => Navigator.of(ctx).pop(true),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  return ok == true;
}

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
    return Text('$prefix${kcal!.round()}$suffix', style: tabularNumberStyle(style));
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
        borderRadius: AppRadius.pillRadius,
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
    return SurfaceCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(LucideIcons.info, size: 18, color: cs.onSurfaceVariant),
          const SizedBox(width: AppSpacing.sm),
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

    return SurfaceCard(
      child: showCompact
          ? InkWell(
              onTap: () => setState(() => _manualExpand = true),
              child: Row(
                children: [
                  Icon(LucideIcons.info, size: 18, color: cs.onSurfaceVariant),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text('Lưu ý lịch (${widget.messages.length})', style: t.bodySmall),
                  ),
                  const Icon(LucideIcons.chevronRight, size: 18),
                ],
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(LucideIcons.info, size: 18, color: cs.onSurfaceVariant),
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
    final t = Theme.of(context).textTheme;
    return SurfaceCard(
      padding: const EdgeInsets.all(14),
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
    final textScale = MediaQuery.textScalerOf(context).scale(1);
    final hasKcal = kcal != null && kcal! > 0;
    final metaChildren = [
      Text(timeText, style: tabularNumberStyle(t.bodySmall)),
      if (hasKcal) CalorieText(kcal, suffix: ' kcal', style: tabularNumberStyle(t.labelSmall)),
    ];

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
      subtitle: textScale >= 1.3
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(subtitle, style: t.bodySmall),
                const SizedBox(height: AppSpacing.xs),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.xs,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: metaChildren,
                ),
              ],
            )
          : Text(subtitle, style: t.bodySmall),
      trailing: textScale >= 1.3
          ? null
          : Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: metaChildren,
            ),
      onTap: onTap,
    );
  }
}

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String? title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const EmptyState({
    super.key,
    this.icon = LucideIcons.inbox,
    this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 44,
              color: cs.onSurfaceVariant.withValues(alpha: 0.72),
            ),
            const SizedBox(height: AppSpacing.md),
            if (title != null) ...[
              Text(title!, style: t.titleMedium, textAlign: TextAlign.center),
              const SizedBox(height: AppSpacing.xs),
            ],
            Text(
              message,
              style: t.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: AppSpacing.lg),
              FilledButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}

class ErrorState extends StatelessWidget {
  final String? title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const ErrorState({
    super.key,
    this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(LucideIcons.triangleAlert, size: 44, color: cs.error),
            const SizedBox(height: AppSpacing.md),
            if (title != null) ...[
              Text(title!, style: t.titleMedium, textAlign: TextAlign.center),
              const SizedBox(height: AppSpacing.xs),
            ],
            Text(
              message,
              style: t.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            if (onAction != null) ...[
              const SizedBox(height: AppSpacing.lg),
              FilledButton(onPressed: onAction, child: Text(actionLabel ?? 'Thử lại')),
            ],
          ],
        ),
      ),
    );
  }
}

/// Mở Bottom Sheet chuẩn với `SafeArea`, bo trên 24 px, drag handle và tự đệm bàn phím.
Future<T?> showAppModalSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool isScrollControlled = true,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: isScrollControlled,
    useSafeArea: true,
    showDragHandle: true,
    shape: const RoundedRectangleBorder(borderRadius: AppRadius.sheetTopRadius),
    builder: (ctx) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(ctx).bottom),
      child: SafeArea(
        top: false,
        child: builder(ctx),
      ),
    ),
  );
}

/// Khung xám nhấp nháy nhẹ dùng khi chờ tải danh sách chậm (DSLD / Google Drive).
class LoadingSkeletonBox extends StatefulWidget {
  final double? width;
  final double height;
  final BorderRadiusGeometry borderRadius;

  const LoadingSkeletonBox({
    super.key,
    this.width,
    required this.height,
    this.borderRadius = AppRadius.controlRadius,
  });

  @override
  State<LoadingSkeletonBox> createState() => _LoadingSkeletonBoxState();
}

class _LoadingSkeletonBoxState extends State<LoadingSkeletonBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  bool _animating = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final disableAnimations = MediaQuery.disableAnimationsOf(context);
    if (disableAnimations && _animating) {
      _controller.stop();
      _animating = false;
    } else if (!disableAnimations && !_animating) {
      _animating = true;
      _controller.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ww = context.wwColors;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final color = Color.lerp(ww.subtleSurface, ww.outlineSubtle, _controller.value)!;
        return Container(
          width: widget.width ?? double.infinity,
          height: widget.height,
          decoration: BoxDecoration(
            color: color,
            borderRadius: widget.borderRadius,
          ),
        );
      },
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

  static ({int current, int total})? _parseStepProgress(String? label) {
    if (label == null) return null;
    final m = RegExp(r'^(\d+)\s*/\s*(\d+)$').firstMatch(label.trim());
    if (m == null) return null;
    final cur = int.tryParse(m.group(1)!);
    final tot = int.tryParse(m.group(2)!);
    if (cur == null || tot == null || tot <= 1 || cur < 1 || cur > tot) return null;
    return (current: cur, total: tot);
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final progress = _parseStepProgress(stepLabel);
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: onBack == null
            ? null
            : IconButton(
                tooltip: 'Quay lại',
                icon: const Icon(LucideIcons.arrowLeft),
                onPressed: busy ? null : onBack,
              ),
        title: title != null ? Text(title!) : null,
        actions: [
          if (stepLabel != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Center(
                child: Text(stepLabel!, style: tabularNumberStyle(t.titleSmall)),
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            if (progress != null)
              _StepProgressBar(current: progress.current, total: progress.total),
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

/// Thanh tiến độ nhiều đoạn mảnh cho các bước thiết lập (`1/3`, `2/3`, `3/3`).
class _StepProgressBar extends StatelessWidget {
  final int current;
  final int total;
  const _StepProgressBar({required this.current, required this.total});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final ww = context.wwColors;
    return Semantics(
      label: 'Bước $current trên $total',
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
        child: Row(
          children: [
            for (var i = 1; i <= total; i++) ...[
              if (i > 1) const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  height: 4,
                  decoration: BoxDecoration(
                    color: i <= current ? cs.primary : ww.subtleSurface,
                    borderRadius: AppRadius.pillRadius,
                  ),
                ),
              ),
            ],
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
}) =>
    AppFeedback.showSnack(
      context,
      'Đã ghi ${fmtWaterMl(ml)} ml nước',
      duration: const Duration(seconds: 7),
      action: SnackBarAction(label: 'Hoàn tác', onPressed: onUndo),
    );

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
