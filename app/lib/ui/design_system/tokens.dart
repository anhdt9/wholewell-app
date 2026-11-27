/// Design tokens, bảng màu ngữ nghĩa, typography và hàm khởi tạo ThemeData sáng/tối.
library;

import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';

export 'package:lucide_icons_flutter/lucide_icons.dart';

abstract final class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;
}

abstract final class AppRadius {
  static const double control = 12;
  static const double card = 16;
  static const double sheet = 24;
  static const double pill = 999;

  // Alias giữ tương thích ngắn hạn với code cũ dùng AppRadius.md.
  static const double md = control;

  static final BorderRadius controlRadius = BorderRadius.circular(control);
  static final BorderRadius cardRadius = BorderRadius.circular(card);
  static final BorderRadius pillRadius = BorderRadius.circular(pill);
  static const BorderRadius sheetTopRadius = BorderRadius.vertical(
    top: Radius.circular(sheet),
  );
}

/// Màu sắc phân lớp & ngữ nghĩa cho toàn app WholeWell (Light / Dark).
@immutable
class WholeWellColors extends ThemeExtension<WholeWellColors> {
  const WholeWellColors({
    required this.scaffoldBackground,
    required this.cardSurface,
    required this.subtleSurface,
    required this.outlineSubtle,
    required this.foodSource,
    required this.supplementSource,
    required this.macroProtein,
    required this.macroFat,
    required this.macroCarb,
    required this.inRange,
    required this.belowTarget,
    required this.warningContainer,
    required this.onWarningContainer,
    required this.warningBorder,
  });

  final Color scaffoldBackground;
  final Color cardSurface;
  final Color subtleSurface;
  final Color outlineSubtle;
  final Color foodSource;
  final Color supplementSource;
  final Color macroProtein;
  final Color macroFat;
  final Color macroCarb;
  final Color inRange;
  final Color belowTarget;
  final Color warningContainer;
  final Color onWarningContainer;
  final Color warningBorder;

  static const light = WholeWellColors(
    scaffoldBackground: Color(0xFFF7F9F8),
    cardSurface: Color(0xFFFFFFFF),
    subtleSurface: Color(0xFFEFF3F1),
    outlineSubtle: Color(0xFFDCE3DF),
    foodSource: Color(0xFF1B6B5C),
    supplementSource: Color(0xFF3B67B0),
    macroProtein: Color(0xFF1B6B5C),
    macroFat: Color(0xFFB07B27),
    macroCarb: Color(0xFF3B67B0),
    inRange: Color(0xFF1F7A52),
    belowTarget: Color(0xFF6F7C77),
    warningContainer: Color(0xFFFFF4E0),
    onWarningContainer: Color(0xFF5E3A00),
    warningBorder: Color(0xFFE6B86A),
  );

  static const dark = WholeWellColors(
    scaffoldBackground: Color(0xFF111413),
    cardSurface: Color(0xFF1A1F1D),
    subtleSurface: Color(0xFF222825),
    outlineSubtle: Color(0xFF2D3532),
    foodSource: Color(0xFF5FD4BE),
    supplementSource: Color(0xFF8AB4F8),
    macroProtein: Color(0xFF5FD4BE),
    macroFat: Color(0xFFE3B463),
    macroCarb: Color(0xFF8AB4F8),
    inRange: Color(0xFF6CD49E),
    belowTarget: Color(0xFF8E9B96),
    warningContainer: Color(0xFF3A2B12),
    onWarningContainer: Color(0xFFFFDCA8),
    warningBorder: Color(0xFF8A6424),
  );

  @override
  WholeWellColors copyWith({
    Color? scaffoldBackground,
    Color? cardSurface,
    Color? subtleSurface,
    Color? outlineSubtle,
    Color? foodSource,
    Color? supplementSource,
    Color? macroProtein,
    Color? macroFat,
    Color? macroCarb,
    Color? inRange,
    Color? belowTarget,
    Color? warningContainer,
    Color? onWarningContainer,
    Color? warningBorder,
  }) {
    return WholeWellColors(
      scaffoldBackground: scaffoldBackground ?? this.scaffoldBackground,
      cardSurface: cardSurface ?? this.cardSurface,
      subtleSurface: subtleSurface ?? this.subtleSurface,
      outlineSubtle: outlineSubtle ?? this.outlineSubtle,
      foodSource: foodSource ?? this.foodSource,
      supplementSource: supplementSource ?? this.supplementSource,
      macroProtein: macroProtein ?? this.macroProtein,
      macroFat: macroFat ?? this.macroFat,
      macroCarb: macroCarb ?? this.macroCarb,
      inRange: inRange ?? this.inRange,
      belowTarget: belowTarget ?? this.belowTarget,
      warningContainer: warningContainer ?? this.warningContainer,
      onWarningContainer: onWarningContainer ?? this.onWarningContainer,
      warningBorder: warningBorder ?? this.warningBorder,
    );
  }

  @override
  WholeWellColors lerp(covariant ThemeExtension<WholeWellColors>? other, double t) {
    if (other is! WholeWellColors) return this;
    return WholeWellColors(
      scaffoldBackground: Color.lerp(scaffoldBackground, other.scaffoldBackground, t)!,
      cardSurface: Color.lerp(cardSurface, other.cardSurface, t)!,
      subtleSurface: Color.lerp(subtleSurface, other.subtleSurface, t)!,
      outlineSubtle: Color.lerp(outlineSubtle, other.outlineSubtle, t)!,
      foodSource: Color.lerp(foodSource, other.foodSource, t)!,
      supplementSource: Color.lerp(supplementSource, other.supplementSource, t)!,
      macroProtein: Color.lerp(macroProtein, other.macroProtein, t)!,
      macroFat: Color.lerp(macroFat, other.macroFat, t)!,
      macroCarb: Color.lerp(macroCarb, other.macroCarb, t)!,
      inRange: Color.lerp(inRange, other.inRange, t)!,
      belowTarget: Color.lerp(belowTarget, other.belowTarget, t)!,
      warningContainer: Color.lerp(warningContainer, other.warningContainer, t)!,
      onWarningContainer: Color.lerp(onWarningContainer, other.onWarningContainer, t)!,
      warningBorder: Color.lerp(warningBorder, other.warningBorder, t)!,
    );
  }
}

extension WholeWellThemeContext on BuildContext {
  WholeWellColors get wwColors =>
      Theme.of(this).extension<WholeWellColors>() ??
      (Theme.of(this).brightness == Brightness.dark
          ? WholeWellColors.dark
          : WholeWellColors.light);
}

/// Kiểu chữ số thẳng hàng cho kcal, mg, µg, %, giờ, cân nặng.
TextStyle tabularNumberStyle(TextStyle? base) {
  return (base ?? const TextStyle()).copyWith(
    fontFeatures: const [FontFeature.tabularFigures()],
  );
}

/// Tạo [ThemeData] Material 3 nhất quán cho chế độ sáng và tối.
ThemeData buildWholeWellTheme(Brightness brightness) {
  final isDark = brightness == Brightness.dark;
  final ww = isDark ? WholeWellColors.dark : WholeWellColors.light;
  final seed = isDark ? const Color(0xFF5FD4BE) : const Color(0xFF1B6B5C);

  final baseScheme = ColorScheme.fromSeed(
    seedColor: seed,
    brightness: brightness,
  );
  final colorScheme = baseScheme.copyWith(
    surface: ww.cardSurface,
    surfaceContainerLowest: ww.cardSurface,
    surfaceContainerLow: ww.scaffoldBackground,
    surfaceContainer: ww.subtleSurface,
    outlineVariant: ww.outlineSubtle,
  );

  final baseTheme = ThemeData(
    colorScheme: colorScheme,
    brightness: brightness,
    useMaterial3: true,
    fontFamily: 'BeVietnamPro',
  );

  return baseTheme.copyWith(
    scaffoldBackgroundColor: ww.scaffoldBackground,
    appBarTheme: AppBarTheme(
      backgroundColor: ww.scaffoldBackground,
      surfaceTintColor: Colors.transparent,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: baseTheme.textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.w600,
        color: colorScheme.onSurface,
      ),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: ww.cardSurface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.cardRadius,
        side: BorderSide(color: ww.outlineSubtle),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(64, 48),
        shape: RoundedRectangleBorder(borderRadius: AppRadius.controlRadius),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(64, 48),
        side: BorderSide(color: ww.outlineSubtle),
        shape: RoundedRectangleBorder(borderRadius: AppRadius.controlRadius),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: isDark ? ww.subtleSurface : ww.cardSurface,
      border: OutlineInputBorder(
        borderRadius: AppRadius.controlRadius,
        borderSide: BorderSide(color: ww.outlineSubtle),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: AppRadius.controlRadius,
        borderSide: BorderSide(color: ww.outlineSubtle),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: AppRadius.controlRadius,
        borderSide: BorderSide(color: colorScheme.primary, width: 1.5),
      ),
    ),
    chipTheme: baseTheme.chipTheme.copyWith(
      shape: const StadiumBorder(),
      side: BorderSide(color: ww.outlineSubtle),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: ww.cardSurface,
      surfaceTintColor: Colors.transparent,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.sheetTopRadius),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: ww.cardSurface,
      surfaceTintColor: Colors.transparent,
      indicatorColor: colorScheme.primaryContainer,
      elevation: 0,
    ),
    dividerTheme: DividerThemeData(
      color: ww.outlineSubtle,
      thickness: 1,
      space: 1,
    ),
    snackBarTheme: const SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
    ),
    iconTheme: IconThemeData(
      color: colorScheme.onSurfaceVariant,
      size: 20,
    ),
    extensions: [ww],
  );
}

/// Tên biểu tượng chung tham chiếu từ Lucide (đảm bảo bundle offline).
typedef AppIcons = LucideIcons;
