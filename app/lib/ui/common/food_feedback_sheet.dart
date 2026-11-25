/// Phản hồi hợp nhất sau khi ghi hoặc sửa món: Bảng cảnh báo hoặc UndoSnack (chỉ một phản hồi).
library;

import 'package:material_ui/material_ui.dart';
import 'package:health_engine/health_engine.dart';

import '../../state/diary_controller.dart';
import '../labels.dart';

String _ulScopeText(UlScope s) => switch (s) {
      UlScope.total => 'Tính mọi nguồn',
      UlScope.supplement => 'Chỉ tính bổ sung bạn ghi, không tính thức ăn',
      UlScope.synthetic => 'Tính từ thực phẩm bổ sung và thực phẩm tăng cường',
    };

Future<void> presentFoodFeedback(
  BuildContext context, {
  required FoodLogFeedback feedback,
  required ReferencePack pack,
  VoidCallback? onEdit,
  VoidCallback? onUndo,
}) async {
  final messenger = ScaffoldMessenger.maybeOf(context);
  if (feedback.failed) {
    messenger?.hideCurrentSnackBar();
    messenger?.showSnackBar(SnackBar(content: Text(feedback.summaryText)));
    return;
  }

  // Theo mvp-overview.md: có cờ vượt mới thì mở Bảng cảnh báo (không hiện thông báo nhỏ).
  if (feedback.newUlFlags.isNotEmpty) {
    messenger?.hideCurrentSnackBar();
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) {
        final cs = Theme.of(ctx).colorScheme;
        final t = Theme.of(ctx).textTheme;
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(child: Text(feedback.summaryText, style: t.bodyMedium)),
                  if (onEdit != null)
                    TextButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        onEdit();
                      },
                      child: const Text('Sửa'),
                    ),
                ],
              ),
              for (final s in feedback.mealsOverSugar)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    'Bữa ${mealLabel(s.meal)} có ${fmt(s.grams)} g đường bổ sung, quá giới hạn ${fmt(pack.addedSugarMaxGramsPerMeal)} g mỗi bữa.',
                    style: t.bodySmall,
                  ),
                ),
              const SizedBox(height: 8),
              for (final f in feedback.newUlFlags) ...[
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: cs.errorContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '⚠ ${pack.nutrients[f.nutrientId]?.nameVi ?? f.nutrientId} vượt giới hạn an toàn'
                        '${f.isSevenDayAverage ? ' (trung bình ${f.dayCount} ngày)' : ''}',
                        style: t.titleSmall?.copyWith(color: cs.onErrorContainer, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Đã ghi: ${fmt(f.amount)} ${unitLabel(pack.nutrients[f.nutrientId]?.unit ?? '')} · '
                        'Giới hạn: ${fmt(f.ul)} · Vượt: ${fmt(f.excess)} (${f.percentOver.round()}%)',
                        style: t.bodyMedium?.copyWith(color: cs.onErrorContainer),
                      ),
                      const SizedBox(height: 4),
                      Text(_ulScopeText(f.scope), style: t.bodySmall?.copyWith(color: cs.onErrorContainer)),
                      const SizedBox(height: 4),
                      Text('Hỏi bác sĩ hoặc dược sĩ nếu cần.', style: t.bodySmall?.copyWith(color: cs.onErrorContainer)),
                    ],
                  ),
                ),
              ],
              Row(
                children: [
                  Expanded(
                    child: FilledButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Đã hiểu'),
                    ),
                  ),
                ],
              ),
              if (onUndo != null)
                Center(
                  child: TextButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      onUndo();
                    },
                    child: const Text('Hoàn tác lần ghi'),
                  ),
                ),
            ],
          ),
        );
      },
    );
    return;
  }

  // Không có cờ mới: tối đa 3 dòng gộp trong UndoSnack (7 giây).
  final lines = <String>[
    ...feedback.stillOverUlLines,
    for (final s in feedback.mealsOverSugar)
      'Bữa ${mealLabel(s.meal)} có ${fmt(s.grams)} g đường bổ sung, quá giới hạn ${fmt(pack.addedSugarMaxGramsPerMeal)} g mỗi bữa.',
    feedback.summaryText,
  ];
  final shown = lines.take(3).join('\n');

  messenger?.hideCurrentSnackBar();
  messenger?.showSnackBar(
    SnackBar(
      duration: const Duration(seconds: 7),
      content: Text(shown),
      action: onUndo != null
          ? SnackBarAction(label: 'Hoàn tác', onPressed: onUndo)
          : (onEdit != null ? SnackBarAction(label: 'Sửa', onPressed: onEdit) : null),
    ),
  );
}
