/// Mô hình dữ liệu cho thư viện món ăn.
library;

import 'package:health_engine/health_engine.dart';

enum FoodKind { usdaFoundation, usdaSr, usdaFndds, recipe }

class FoodLibraryMeta {
  final String libraryVersion;
  final String usdaRelease;
  final String fpedRelease;
  final String builtAt;
  final String packVersion;
  final String sha256;

  const FoodLibraryMeta({
    required this.libraryVersion,
    required this.usdaRelease,
    required this.fpedRelease,
    required this.builtAt,
    required this.packVersion,
    required this.sha256,
  });
}

class FoodPortion {
  final String id;
  final String labelVi;
  final double grams;

  const FoodPortion({
    required this.id,
    required this.labelVi,
    required this.grams,
  });
}

class FoodNutrientPer100g {
  final String nutrientId;
  final IntakeSource source;
  final String? form;
  final double amount;
  final double? ulAmount;
  final String unit;

  const FoodNutrientPer100g({
    required this.nutrientId,
    required this.source,
    this.form,
    required this.amount,
    this.ulAmount,
    required this.unit,
  });
}

class FoodSummary {
  final String id;
  final FoodKind kind;
  final String nameVi;
  final String? nameEn;
  final bool isEstimate;
  final bool addedSugarKnown;
  final String? defaultPortionId;
  final String? defaultPortionLabel;
  final double? defaultPortionGrams;
  final double energyKcalPer100g;

  const FoodSummary({
    required this.id,
    required this.kind,
    required this.nameVi,
    this.nameEn,
    required this.isEstimate,
    required this.addedSugarKnown,
    this.defaultPortionId,
    this.defaultPortionLabel,
    this.defaultPortionGrams,
    required this.energyKcalPer100g,
  });
}

class FoodDetail {
  final String id;
  final FoodKind kind;
  final String nameVi;
  final String? nameEn;
  final String? aliasesVi;
  final bool isEstimate;
  final bool addedSugarKnown;
  final bool niacinFortifiedUnseparated;
  final bool folateUnseparated;
  final String? defaultPortionId;
  final List<FoodPortion> portions;
  final List<FoodNutrientPer100g> nutrientsPer100g;

  const FoodDetail({
    required this.id,
    required this.kind,
    required this.nameVi,
    this.nameEn,
    this.aliasesVi,
    required this.isEstimate,
    required this.addedSugarKnown,
    required this.niacinFortifiedUnseparated,
    required this.folateUnseparated,
    this.defaultPortionId,
    required this.portions,
    required this.nutrientsPer100g,
  });

  FoodPortion? get defaultPortion {
    if (portions.isEmpty) return null;
    if (defaultPortionId == null) return portions.first;
    for (final p in portions) {
      if (p.id == defaultPortionId) return p;
    }
    return portions.first;
  }

  /// Giá trị / 100 g theo khóa hiển thị (kể cả `totalSugar` không đưa vào engine).
  double? displayAmountPer100g(String nutrientId) {
    var sum = 0.0;
    var found = false;
    for (final n in nutrientsPer100g) {
      if (n.nutrientId == nutrientId) {
        sum += n.amount;
        found = true;
      }
    }
    return found ? sum : null;
  }

  /// Quy đổi [qty] theo [unitLabel] sang gram; trả `null` nếu [unitLabel] không còn trong danh sách.
  double? gramsForPortion(String unitLabel, double qty) {
    final norm = unitLabel.trim().toLowerCase();
    if (norm == 'gram' || norm == 'g') return qty;
    for (final p in portions) {
      if (p.labelVi == unitLabel) return qty * p.grams;
    }
    return null;
  }
}

/// Tệp thư viện món thiếu, không giải nén được, hoặc sai mã băm SHA-256.
class FoodLibraryIntegrityException implements Exception {
  final String message;
  const FoodLibraryIntegrityException(this.message);
  @override
  String toString() => 'FoodLibraryIntegrityException: $message';
}
