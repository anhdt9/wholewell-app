/// Design tokens và hàm khởi tạo ThemeData sáng/tối dùng chung cho toàn app.
library;

import 'package:material_ui/material_ui.dart';

abstract final class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
}

abstract final class AppRadius {
  static const double md = 12;
  static final BorderRadius card = BorderRadius.circular(md);
}

/// Tạo [ThemeData] Material 3 nhất quán cho chế độ sáng và tối.
ThemeData buildWholeWellTheme(Brightness brightness) {
  return ThemeData(
    colorSchemeSeed: Colors.teal,
    brightness: brightness,
    useMaterial3: true,
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(minimumSize: const Size(64, 48)),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(minimumSize: const Size(64, 48)),
    ),
    cardTheme: CardThemeData(
      shape: RoundedRectangleBorder(borderRadius: AppRadius.card),
    ),
  );
}
