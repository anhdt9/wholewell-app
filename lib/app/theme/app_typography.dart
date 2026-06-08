import 'package:flutter/material.dart';

class AppTypography {
  static TextTheme get textTheme => Typography.material2021().black.copyWith(
        headlineSmall: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
        titleLarge: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
        bodyLarge: const TextStyle(fontSize: 16, height: 1.4),
        bodyMedium: const TextStyle(fontSize: 14, height: 1.4),
      );
}
