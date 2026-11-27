/// Các biểu đồ và thanh tiến độ trực quan dùng chung trong toàn app WholeWell.
library;

import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../../state/app_scope.dart';
import '../design_system/tokens.dart';

/// Thanh tiến độ hai đoạn (Thực phẩm vs Bổ sung) vẽ bằng [CustomPainter].
class TwoSegmentProgressBar extends StatelessWidget {
  final double foodAmount;
  final double supplementAmount;
  final double targetAmount;
  final bool overLimit;
  final double height;
  final String? semanticsLabel;

  const TwoSegmentProgressBar({
    super.key,
    required this.foodAmount,
    required this.supplementAmount,
    required this.targetAmount,
    this.overLimit = false,
    this.height = 8,
    this.semanticsLabel,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final ww = context.wwColors;
    final bar = SizedBox(
      width: double.infinity,
      height: height,
      child: CustomPaint(
        painter: _TwoSegmentPainter(
          foodAmount: foodAmount.isFinite ? math.max(0, foodAmount) : 0,
          supplementAmount: supplementAmount.isFinite ? math.max(0, supplementAmount) : 0,
          targetAmount: targetAmount.isFinite ? math.max(0, targetAmount) : 0,
          overLimit: overLimit,
          trackColor: ww.subtleSurface,
          foodColor: ww.foodSource,
          supplementColor: ww.supplementSource,
          markerColor: ww.cardSurface,
          overLimitBorderColor: ww.warningBorder,
          overLimitHighlightColor: ww.warningBorder,
          outlineColor: cs.outlineVariant.withValues(alpha: 0.4),
        ),
      ),
    );
    if (semanticsLabel == null) return bar;
    return Semantics(label: semanticsLabel, child: bar);
  }
}

class _TwoSegmentPainter extends CustomPainter {
  final double foodAmount;
  final double supplementAmount;
  final double targetAmount;
  final bool overLimit;
  final Color trackColor;
  final Color foodColor;
  final Color supplementColor;
  final Color markerColor;
  final Color overLimitBorderColor;
  final Color overLimitHighlightColor;
  final Color outlineColor;

  const _TwoSegmentPainter({
    required this.foodAmount,
    required this.supplementAmount,
    required this.targetAmount,
    required this.overLimit,
    required this.trackColor,
    required this.foodColor,
    required this.supplementColor,
    required this.markerColor,
    required this.overLimitBorderColor,
    required this.overLimitHighlightColor,
    required this.outlineColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    final radius = Radius.circular(size.height / 2);
    final trackRect = Offset.zero & size;
    final trackRRect = RRect.fromRectAndRadius(trackRect, radius);

    canvas.drawRRect(trackRRect, Paint()..color = trackColor);

    final total = foodAmount + supplementAmount;
    final scaleMax = targetAmount > 0 ? math.max(targetAmount, total) : total;

    if (total > 0 && scaleMax > 0) {
      final filledW = (size.width * (total / scaleMax)).clamp(0.0, size.width);
      final hasBoth = foodAmount > 0 && supplementAmount > 0;
      final gap = (hasBoth && filledW > 4) ? 2.0 : 0.0;
      final usableW = math.max(0.0, filledW - gap);
      final foodW = usableW * (foodAmount / total);
      final suppW = usableW - foodW;

      canvas.save();
      canvas.clipRRect(trackRRect);

      if (foodW > 0) {
        canvas.drawRect(
          Rect.fromLTWH(0, 0, foodW, size.height),
          Paint()..color = foodColor,
        );
      }
      if (suppW > 0) {
        final suppLeft = foodW + gap;
        canvas.drawRect(
          Rect.fromLTWH(suppLeft, 0, suppW, size.height),
          Paint()..color = supplementColor,
        );
      }

      // Khi tổng vượt mức khuyến nghị/tham chiếu (> 0), vẽ vạch 2 px tại mốc 100%.
      if (targetAmount > 0 && total > targetAmount) {
        final targetX = (size.width * (targetAmount / scaleMax)).clamp(2.0, size.width - 2.0);
        canvas.drawRect(
          Rect.fromLTWH(targetX - 1, 0, 2, size.height),
          Paint()..color = overLimit ? overLimitHighlightColor : markerColor,
        );
      }

      canvas.restore();
    }

    if (overLimit) {
      final borderPaint = Paint()
        ..color = overLimitBorderColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;
      canvas.drawRRect(trackRRect.deflate(0.75), borderPaint);
    } else if (total == 0) {
      final subtleStroke = Paint()
        ..color = outlineColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.5;
      canvas.drawRRect(trackRRect.deflate(0.25), subtleStroke);
    }
  }

  @override
  bool shouldRepaint(covariant _TwoSegmentPainter oldDelegate) {
    return foodAmount != oldDelegate.foodAmount ||
        supplementAmount != oldDelegate.supplementAmount ||
        targetAmount != oldDelegate.targetAmount ||
        overLimit != oldDelegate.overLimit ||
        trackColor != oldDelegate.trackColor ||
        foodColor != oldDelegate.foodColor ||
        supplementColor != oldDelegate.supplementColor ||
        markerColor != oldDelegate.markerColor ||
        overLimitBorderColor != oldDelegate.overLimitBorderColor ||
        overLimitHighlightColor != oldDelegate.overLimitHighlightColor ||
        outlineColor != oldDelegate.outlineColor;
  }
}

/// Vòng cung 240 độ hiển thị năng lượng nạp so với mục tiêu giữ cân.
/// Tự ẩn hoàn toàn khi bật `Ẩn số calo`.
class EnergyArcGauge extends StatelessWidget {
  final double consumedKcal;
  final double targetKcal;
  final double size;
  final double strokeWidth;
  final bool? hideCaloriesOverride;
  final Widget? centerChild;

  const EnergyArcGauge({
    super.key,
    required this.consumedKcal,
    required this.targetKcal,
    this.size = 148,
    this.strokeWidth = 10,
    this.hideCaloriesOverride,
    this.centerChild,
  });

  @override
  Widget build(BuildContext context) {
    final hide = hideCaloriesOverride ?? AppScope.maybeOf(context)?.hideCalories ?? false;
    if (hide) return const SizedBox.shrink();

    final cs = Theme.of(context).colorScheme;
    final ww = context.wwColors;
    final t = Theme.of(context).textTheme;

    final safeConsumed = consumedKcal.isFinite ? math.max(0.0, consumedKcal) : 0.0;
    final safeTarget = targetKcal.isFinite ? math.max(0.0, targetKcal) : 0.0;
    final rawRatio = safeTarget <= 0 ? 0.0 : (safeConsumed / safeTarget).clamp(0.0, 1.0);

    final innerContent = centerChild ??
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${safeConsumed.round()}',
              style: tabularNumberStyle(
                t.headlineMedium?.copyWith(
                  fontSize: 28,
                  fontWeight: FontWeight.w600,
                  height: 1.1,
                  color: cs.onSurface,
                ),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              safeTarget > 0 ? '/ ${safeTarget.round()} kcal' : 'kcal',
              style: tabularNumberStyle(
                t.bodySmall?.copyWith(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: cs.onSurfaceVariant,
                ),
              ),
            ),
          ],
        );

    return Semantics(
      label: safeTarget > 0
          ? 'Năng lượng ${safeConsumed.round()} trên ${safeTarget.round()} kilocalo'
          : 'Năng lượng ${safeConsumed.round()} kilocalo',
      child: SizedBox(
        width: size,
        height: size,
        child: TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0, end: rawRatio),
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
          builder: (context, animatedRatio, child) {
            return CustomPaint(
              painter: _EnergyArcPainter(
                progress: animatedRatio,
                strokeWidth: strokeWidth,
                trackColor: ww.subtleSurface,
                activeColor: cs.primary,
              ),
              child: child,
            );
          },
          child: Padding(
            padding: EdgeInsets.all(strokeWidth + AppSpacing.md),
            child: Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: innerContent,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _EnergyArcPainter extends CustomPainter {
  final double progress;
  final double strokeWidth;
  final Color trackColor;
  final Color activeColor;

  const _EnergyArcPainter({
    required this.progress,
    required this.strokeWidth,
    required this.trackColor,
    required this.activeColor,
  });

  // 150 độ (góc dưới trái) quét theo chiều kim đồng hồ 240 độ tới 30 độ (góc dưới phải).
  static const double _startAngle = 5 * math.pi / 6;
  static const double _sweepTotal = 4 * math.pi / 3;

  @override
  void paint(Canvas canvas, Size size) {
    final side = math.min(size.width, size.height);
    if (side <= strokeWidth) return;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = (side - strokeWidth) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(rect, _startAngle, _sweepTotal, false, trackPaint);

    final clamped = progress.clamp(0.0, 1.0);
    if (clamped > 0) {
      final activePaint = Paint()
        ..color = activeColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(rect, _startAngle, _sweepTotal * clamped, false, activePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _EnergyArcPainter oldDelegate) {
    return progress != oldDelegate.progress ||
        strokeWidth != oldDelegate.strokeWidth ||
        trackColor != oldDelegate.trackColor ||
        activeColor != oldDelegate.activeColor;
  }
}

/// Thanh hiển thị tỷ lệ % đa lượng kèm vùng khoảng khuyến nghị (`minPercent`–`maxPercent`)
/// và chấm đánh dấu vị trí hiện tại.
class TargetRangeBar extends StatelessWidget {
  final double percent;
  final double minPercent;
  final double maxPercent;
  final Color? activeColor;
  final double height;
  final String? semanticsLabel;

  const TargetRangeBar({
    super.key,
    required this.percent,
    required this.minPercent,
    required this.maxPercent,
    this.activeColor,
    this.height = 16,
    this.semanticsLabel,
  });

  @override
  Widget build(BuildContext context) {
    final ww = context.wwColors;
    final safePct = percent.isFinite ? percent.clamp(0.0, 100.0) : 0.0;
    final safeMin = minPercent.isFinite ? minPercent.clamp(0.0, 100.0) : 0.0;
    final safeMax = maxPercent.isFinite ? math.max(safeMin, maxPercent.clamp(0.0, 100.0)) : safeMin;
    final inRange = safePct >= safeMin && safePct <= safeMax;

    final baseAccent = activeColor ?? ww.inRange;
    final dotColor = inRange
        ? baseAccent
        : (safePct > safeMax ? ww.warningBorder : ww.belowTarget);

    final bar = SizedBox(
      width: double.infinity,
      height: height,
      child: CustomPaint(
        painter: _TargetRangePainter(
          percent: safePct,
          minPercent: safeMin,
          maxPercent: safeMax,
          trackColor: ww.subtleSurface,
          bandColor: baseAccent.withValues(alpha: 0.24),
          bandTickColor: baseAccent.withValues(alpha: 0.7),
          dotColor: dotColor,
          dotHaloColor: ww.cardSurface,
        ),
      ),
    );

    final label = semanticsLabel ??
        '${safePct.round()}%, khoảng khuyến nghị ${safeMin.round()} đến ${safeMax.round()}%';
    return Semantics(label: label, child: bar);
  }
}

class _TargetRangePainter extends CustomPainter {
  final double percent;
  final double minPercent;
  final double maxPercent;
  final Color trackColor;
  final Color bandColor;
  final Color bandTickColor;
  final Color dotColor;
  final Color dotHaloColor;

  const _TargetRangePainter({
    required this.percent,
    required this.minPercent,
    required this.maxPercent,
    required this.trackColor,
    required this.bandColor,
    required this.bandTickColor,
    required this.dotColor,
    required this.dotHaloColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    const trackHeight = 6.0;
    final cy = size.height / 2;
    final trackTop = cy - trackHeight / 2;
    final trackRect = Rect.fromLTWH(0, trackTop, size.width, trackHeight);
    final trackRRect = RRect.fromRectAndRadius(trackRect, const Radius.circular(trackHeight / 2));

    canvas.drawRRect(trackRRect, Paint()..color = trackColor);

    final dotRadius = math.min(5.0, size.height / 2 - 1);
    final usableWidth = math.max(1.0, size.width - dotRadius * 2);

    double xFor(double pct) => dotRadius + usableWidth * (pct.clamp(0.0, 100.0) / 100.0);

    final minX = xFor(minPercent);
    final maxX = xFor(maxPercent);

    if (maxX > minX) {
      final bandRect = Rect.fromLTRB(minX, trackTop - 1, maxX, trackTop + trackHeight + 1);
      canvas.drawRRect(
        RRect.fromRectAndRadius(bandRect, const Radius.circular(3)),
        Paint()..color = bandColor,
      );
      final tickPaint = Paint()
        ..color = bandTickColor
        ..strokeWidth = 1.5;
      canvas.drawLine(
        Offset(minX, trackTop - 2),
        Offset(minX, trackTop + trackHeight + 2),
        tickPaint,
      );
      canvas.drawLine(
        Offset(maxX, trackTop - 2),
        Offset(maxX, trackTop + trackHeight + 2),
        tickPaint,
      );
    }

    final dotX = xFor(percent);
    canvas.drawCircle(
      Offset(dotX, cy),
      dotRadius + 1.5,
      Paint()..color = dotHaloColor,
    );
    canvas.drawCircle(
      Offset(dotX, cy),
      dotRadius,
      Paint()..color = dotColor,
    );
  }

  @override
  bool shouldRepaint(covariant _TargetRangePainter oldDelegate) {
    return percent != oldDelegate.percent ||
        minPercent != oldDelegate.minPercent ||
        maxPercent != oldDelegate.maxPercent ||
        trackColor != oldDelegate.trackColor ||
        bandColor != oldDelegate.bandColor ||
        bandTickColor != oldDelegate.bandTickColor ||
        dotColor != oldDelegate.dotColor ||
        dotHaloColor != oldDelegate.dotHaloColor;
  }
}
