import 'package:health_engine/health_engine.dart';

/// Đơn vị của các khóa năng lượng không có trong danh sách chất của gói.
const energyKeyUnits = {'energyKcal': 'kcal', 'fat': 'g', 'addedSugar': 'g'};

/// Đơn vị chuẩn của mọi khóa mà [IntakeItem.nutrients] được phép dùng.
Map<String, String> unitTable(ReferencePack pack) => {
      for (final n in pack.nutrients.values) n.id: n.unit,
      ...energyKeyUnits,
    };

/// Đơn vị lưu trong CSDL khác đơn vị hiện tại của gói: không trả số sai.
class UnitMismatch implements Exception {
  final String nutrientId;
  final String stored;
  final String expected;
  const UnitMismatch(this.nutrientId, this.stored, this.expected);
  @override
  String toString() => 'UnitMismatch($nutrientId: lưu "$stored", gói dùng "$expected")';
}

/// Khóa chất không có trong gói dữ liệu.
class UnknownNutrient implements Exception {
  final String nutrientId;
  const UnknownNutrient(this.nutrientId);
  @override
  String toString() => 'UnknownNutrient($nutrientId)';
}
