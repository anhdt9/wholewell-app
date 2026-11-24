/// Kiểu dữ liệu đọc, ghi của nhật ký.
library;

import 'package:health_engine/health_engine.dart';

enum OnboardingStep { bodyProfile, calorieDisplay, done }

enum Meal { breakfast, lunch, dinner, snack }

enum DoseKind { scheduled, extra, oneOff }

/// Mã đơn vị đếm của sản phẩm; chữ "viên", "gói" chỉ để hiện.
enum CountUnit { tablet, capsule, softgel, sachet, drop, ml, g }

enum OccurrenceStatus { taken, skipped }

/// Khi chỉ còn hộp đã hết hạn: hỏi, trừ, hay không trừ.
enum ExpiredBoxChoice { ask, deduct, skip }

/// YYYY-MM-DD theo giờ địa phương của [t].
String dayKey(DateTime t) {
  final l = t.toLocal();
  return '${l.year.toString().padLeft(4, '0')}-${_pad2(l.month)}-${_pad2(l.day)}';
}

/// YYYY-MM theo giờ địa phương của [t].
String monthKey(DateTime t) {
  final l = t.toLocal();
  return '${l.year.toString().padLeft(4, '0')}-${_pad2(l.month)}';
}

String _pad2(int v) => v.toString().padLeft(2, '0');

/// Ngày kế tiếp của một [dayKey].
String nextDay(String day) {
  final p = day.split('-').map(int.parse).toList();
  return dayKey(DateTime(p[0], p[1], p[2] + 1));
}

/// Một dòng chất của một lần ghi (đặc tả encrypted-db, mục Lượng đã ghi).
class IntakeLine {
  final String? nutrientId;
  final String? freeName;
  final IntakeSource source;
  final String? form;
  final bool uncertain;
  final double? labelAmount;
  final String? labelUnit;

  /// Lượng theo khóa của engine, đã đổi đơn vị và nhân số khẩu phần.
  final Map<String, double> amounts;

  /// Lượng tính giới hạn khi khác [amounts]; chỉ dùng được khi engine hỗ trợ (việc 2).
  final Map<String, double>? ulAmounts;

  const IntakeLine({
    this.nutrientId,
    this.freeName,
    required this.source,
    this.form,
    this.uncertain = false,
    this.labelAmount,
    this.labelUnit,
    required this.amounts,
    this.ulAmounts,
  });

  IntakeLine scaled(double f) => IntakeLine(
        nutrientId: nutrientId,
        freeName: freeName,
        source: source,
        form: form,
        uncertain: uncertain,
        labelAmount: labelAmount,
        labelUnit: labelUnit,
        amounts: {for (final e in amounts.entries) e.key: e.value * f},
        ulAmounts: ulAmounts == null ? null : {for (final e in ulAmounts!.entries) e.key: e.value * f},
      );
}

class FoodEntryInput {
  final DateTime at;
  final Meal meal;
  final String name;

  /// `usda:<id>`, `recipe:<id>`, `custom:<id>`; trống khi nhập theo nhãn không lưu.
  final String? foodRef;
  final String portionUnit;
  final double portionQty;

  /// Số trên nhãn tính cho bao nhiêu (chỉ món theo nhãn), vd. 100 ml.
  final double? labelBasisQty;
  final String? labelBasisUnit;

  /// false: "chưa rõ đường bổ sung", khác 0 g.
  final bool addedSugarKnown;
  final String packVersion;
  final List<IntakeLine> lines;

  const FoodEntryInput({
    required this.at,
    required this.meal,
    required this.name,
    this.foodRef,
    required this.portionUnit,
    required this.portionQty,
    this.labelBasisQty,
    this.labelBasisUnit,
    required this.addedSugarKnown,
    required this.packVersion,
    required this.lines,
  });
}

class FoodEntry {
  final int id;
  final DateTime at;
  final String day;
  final Meal meal;
  final String name;
  final String? foodRef;
  final String portionUnit;
  final double portionQty;
  final double? labelBasisQty;
  final String? labelBasisUnit;
  final bool addedSugarKnown;
  final String packVersion;
  final List<IntakeLine> lines;

  const FoodEntry({
    required this.id,
    required this.at,
    required this.day,
    required this.meal,
    required this.name,
    required this.foodRef,
    required this.portionUnit,
    required this.portionQty,
    required this.labelBasisQty,
    required this.labelBasisUnit,
    required this.addedSugarKnown,
    required this.packVersion,
    required this.lines,
  });
}

/// Lần theo lịch mà lần uống gắn vào.
class OccurrenceRef {
  final int scheduleId;
  final String day;
  const OccurrenceRef(this.scheduleId, this.day);
}

class DoseInput {
  final DateTime at;
  final int? productId;

  /// Ô "Tên (không bắt buộc)" của Ghi một lần.
  final String? name;
  final DoseKind kind;
  final double servings;
  final String packVersion;
  final List<IntakeLine> lines;
  final OccurrenceRef? occurrence;

  /// false: [Không trừ] (lần uống vẫn được ghi và tính vào giới hạn).
  final bool deductStock;
  final ExpiredBoxChoice expiredBoxes;

  const DoseInput({
    required this.at,
    this.productId,
    this.name,
    required this.kind,
    required this.servings,
    required this.packVersion,
    required this.lines,
    this.occurrence,
    this.deductStock = true,
    this.expiredBoxes = ExpiredBoxChoice.ask,
  });
}

class BoxDeduction {
  final int boxId;
  final double amount;
  const BoxDeduction(this.boxId, this.amount);
}

class DoseEntry {
  final int id;
  final DateTime at;
  final String day;
  final int? productId;
  final String? name;
  final DoseKind kind;
  final double servings;
  final String packVersion;
  final List<IntakeLine> lines;
  final List<BoxDeduction> deductions;

  const DoseEntry({
    required this.id,
    required this.at,
    required this.day,
    required this.productId,
    required this.name,
    required this.kind,
    required this.servings,
    required this.packVersion,
    required this.lines,
    required this.deductions,
  });
}

sealed class DoseResult {
  const DoseResult();
}

final class DoseRecorded extends DoseResult {
  final int id;

  /// Phần không trừ được vì kho hết (theo đơn vị đếm). > 0: "Kho đã hết · Thêm hộp".
  final double shortfall;
  const DoseRecorded(this.id, this.shortfall);
}

/// Chỉ còn hộp đã hết hạn: hỏi "Trừ vào hộp đã hết hạn?". Chưa ghi gì.
final class NeedsExpiredChoice extends DoseResult {
  const NeedsExpiredChoice();
}

class Product {
  final int id;
  final String name;
  final CountUnit countUnit;
  final double unitsPerServing;
  const Product(this.id, this.name, this.countUnit, this.unitsPerServing);
}

class StockBox {
  final int id;
  final int productId;
  final double remaining;
  final String? expiryMonth;
  const StockBox(this.id, this.productId, this.remaining, this.expiryMonth);
}

class Schedule {
  final int id;
  final int productId;
  final int timeOfDay;
  final double servings;
  final String validFrom;
  final String? validTo;
  const Schedule(this.id, this.productId, this.timeOfDay, this.servings, this.validFrom, this.validTo);
}

class Occurrence {
  final int scheduleId;
  final String day;
  final OccurrenceStatus status;
  final int? doseEntryId;
  const Occurrence(this.scheduleId, this.day, this.status, this.doseEntryId);
}

class WorkoutRecord {
  final int id;
  final DateTime startAt;
  final String day;
  final WorkoutEntry workout;
  const WorkoutRecord(this.id, this.startAt, this.day, this.workout);
}

class WaterRecord {
  final int id;
  final DateTime at;
  final double ml;
  const WaterRecord(this.id, this.at, this.ml);
}

/// Hết dung lượng: "Chưa lưu được. Thử lại". Giao dịch đã hoàn tác.
class StorageFullException implements Exception {
  const StorageFullException();
  @override
  String toString() => 'StorageFullException';
}

/// Lỗi lưu trữ khác. Chỉ giữ loại lỗi và mã lỗi SQLite (vd. `SqliteException(787)`)
/// để tra crash; không chứa câu SQL hay giá trị.
class JournalStorageException implements Exception {
  final String kind;
  const JournalStorageException([this.kind = '']);
  @override
  String toString() => 'JournalStorageException($kind)';
}
