/// Các thành phần giao diện dùng chung theo `docs/design/mvp-overview.md`.
library;

import 'package:material_ui/material_ui.dart';

import '../../state/app_scope.dart';
import '../labels.dart';

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
