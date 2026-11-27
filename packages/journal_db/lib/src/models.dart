/// Kiểu dữ liệu đọc, ghi của nhật ký.
library;

import 'dart:math' show min;

import 'package:health_engine/health_engine.dart';

/// Phiên bản đồng ý chính thức của MVP (khác `'khung-tam-0'` của khung tạm).
const mvpConsentVersion = 'mvp-1';

/// Khóa `ui_state` lưu tuổi mới khi hệ thống vừa tự cộng thêm 12 tháng.
const ageBumpedNoticeKey = 'age_bumped_notice';

/// Trạng thái đồng ý `health_data` đang hiệu lực (`withdrawn_at IS NULL`).
class HealthConsentStatus {
  final String contentVersion;
  final DateTime grantedAt;
  const HealthConsentStatus(this.contentVersion, this.grantedAt);
}

/// Tuổi, ngày nhập tuổi và câu trả lời chế độ thận trọng trong bảng `profile`.
typedef ConsentProfileState = ({
  int ageYears,
  String ageEnteredOn,
  bool caution,
  String cautionAnsweredOn,
});

/// Kết quả tính tự tăng tuổi theo chu kỳ 12 tháng dương lịch kể từ `age_entered_on`.
({int newAgeYears, String newEnteredOn})? computeAgeBump(
    int currentAge, String enteredOn, DateTime now) {
  final parts = enteredOn.split('-');
  if (parts.length != 3) return null;
  final baseYear = int.tryParse(parts[0]);
  final baseMonth = int.tryParse(parts[1]);
  final baseDay = int.tryParse(parts[2]);
  if (baseYear == null || baseMonth == null || baseDay == null) return null;

  final localNow = now.toLocal();
  final today = DateTime(localNow.year, localNow.month, localNow.day);

  DateTime anniversary(int addYears) {
    final ty = baseYear + addYears;
    final maxDay = DateTime(ty, baseMonth + 1, 0).day;
    return DateTime(ty, baseMonth, min(baseDay, maxDay));
  }

  var cycles = 0;
  while (currentAge + cycles < 120 && !anniversary(cycles + 1).isAfter(today)) {
    cycles++;
  }
  if (cycles == 0) return null;
  final nextAnchor = anniversary(cycles);
  return (newAgeYears: currentAge + cycles, newEnteredOn: dayKey(nextAnchor));
}

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

enum IngredientOrigin { manual, barcode, ocr }

class Product {
  final int id;
  final String name;
  final CountUnit countUnit;
  final double unitsPerServing;
  final String? barcode;
  final bool archived;
  const Product(
    this.id,
    this.name,
    this.countUnit,
    this.unitsPerServing, {
    this.barcode,
    this.archived = false,
  });
}

class IngredientDraft {
  final String? nutrientId;
  final String? freeName;
  final String form;
  final double? amountPerServing;
  final String? unit;
  final double? labelAmount;
  final String? labelUnit;
  final bool isCompound;
  final IngredientOrigin origin;
  final bool confirmed;

  const IngredientDraft({
    this.nutrientId,
    this.freeName,
    this.form = 'unknown',
    this.amountPerServing,
    this.unit,
    this.labelAmount,
    this.labelUnit,
    this.isCompound = false,
    this.origin = IngredientOrigin.manual,
    this.confirmed = false,
  });
}

class ProductIngredient {
  final int id;
  final int productId;
  final String? nutrientId;
  final String? freeName;
  final String form;
  final double? amountPerServing;
  final String? unit;
  final double? labelAmount;
  final String? labelUnit;
  final bool isCompound;
  final IngredientOrigin origin;
  final bool confirmed;

  const ProductIngredient({
    required this.id,
    required this.productId,
    required this.nutrientId,
    required this.freeName,
    required this.form,
    required this.amountPerServing,
    required this.unit,
    required this.labelAmount,
    required this.labelUnit,
    required this.isCompound,
    required this.origin,
    required this.confirmed,
  });
}

class ProductDetail {
  final Product product;
  final List<ProductIngredient> ingredients;
  final List<StockBox> boxes;

  const ProductDetail({
    required this.product,
    required this.ingredients,
    required this.boxes,
  });
}

class ProductSummary {
  final Product product;
  final double validRemaining;
  final double expiredRemaining;
  final String? nearestExpiryMonth;
  final int? estimatedDaysLeft;
  final bool isLowStock;

  const ProductSummary({
    required this.product,
    required this.validRemaining,
    required this.expiredRemaining,
    required this.nearestExpiryMonth,
    required this.estimatedDaysLeft,
    required this.isLowStock,
  });
}

class UpdateDoseInput {
  final int doseId;
  final String? name;
  final double servings;
  final DateTime at;
  final String packVersion;
  final List<IntakeLine> lines;
  final ExpiredBoxChoice expiredBoxes;

  const UpdateDoseInput({
    required this.doseId,
    this.name,
    required this.servings,
    required this.at,
    required this.packVersion,
    required this.lines,
    this.expiredBoxes = ExpiredBoxChoice.ask,
  });
}

/// Tổng hợp tồn kho và ngày dự kiến còn dùng được cho một sản phẩm.
ProductSummary summarizeProduct({
  required Product product,
  required List<StockBox> boxes,
  required List<Schedule> activeSchedules,
  required List<DoseEntry> recentDoses14Days,
  required DateTime now,
}) {
  final m = '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}';
  var validRem = 0.0;
  var expiredRem = 0.0;
  String? nearest;
  for (final b in boxes) {
    final exp = b.expiryMonth;
    final isExpired = exp != null && exp.compareTo(m) < 0;
    if (isExpired) {
      expiredRem += b.remaining;
    } else {
      validRem += b.remaining;
      if (b.remaining > 0 && exp != null) {
        if (nearest == null || exp.compareTo(nearest) < 0) {
          nearest = exp;
        }
      }
    }
  }
  var dailyUnits = 0.0;
  if (activeSchedules.isNotEmpty) {
    for (final s in activeSchedules) {
      dailyUnits += s.servings * product.unitsPerServing;
    }
  } else if (recentDoses14Days.isNotEmpty) {
    var sum = 0.0;
    for (final d in recentDoses14Days) {
      sum += d.servings * product.unitsPerServing;
    }
    dailyUnits = sum / 14.0;
  }
  final int? daysLeft =
      validRem > 0 && dailyUnits > 0 ? (validRem / dailyUnits).floor() : null;
  return ProductSummary(
    product: product,
    validRemaining: validRem,
    expiredRemaining: expiredRem,
    nearestExpiryMonth: nearest,
    estimatedDaysLeft: daysLeft,
    isLowStock: daysLeft != null && daysLeft <= 7,
  );
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

/// Thay đổi lịch: dòng mới và ngày bắt đầu có hiệu lực.
class ScheduleChange {
  final int newScheduleId;
  final String effectiveFrom;
  const ScheduleChange(this.newScheduleId, this.effectiveFrom);
}

/// Cài đặt giờ trong ngày, bật/tắt bữa chính, thẻ "Bạn có biết" và hiển thị tên SP trên thông báo.
class DayTimesSettings {
  final int wake;
  final int breakfast;
  final int lunch;
  final int dinner;
  final int sleep;
  final bool dayTimesConfirmed;
  final bool showTipCard;
  final bool hasBreakfast;
  final bool hasLunch;
  final bool hasDinner;
  final bool reminderShowDetails;

  const DayTimesSettings({
    this.wake = 360,
    this.breakfast = 420,
    this.lunch = 720,
    this.dinner = 1140,
    this.sleep = 1350,
    this.dayTimesConfirmed = false,
    this.showTipCard = true,
    this.hasBreakfast = true,
    this.hasLunch = true,
    this.hasDinner = true,
    this.reminderShowDetails = false,
  });

  DayTimesSettings copyWith({
    int? wake,
    int? breakfast,
    int? lunch,
    int? dinner,
    int? sleep,
    bool? dayTimesConfirmed,
    bool? showTipCard,
    bool? hasBreakfast,
    bool? hasLunch,
    bool? hasDinner,
    bool? reminderShowDetails,
  }) =>
      DayTimesSettings(
        wake: wake ?? this.wake,
        breakfast: breakfast ?? this.breakfast,
        lunch: lunch ?? this.lunch,
        dinner: dinner ?? this.dinner,
        sleep: sleep ?? this.sleep,
        dayTimesConfirmed: dayTimesConfirmed ?? this.dayTimesConfirmed,
        showTipCard: showTipCard ?? this.showTipCard,
        hasBreakfast: hasBreakfast ?? this.hasBreakfast,
        hasLunch: hasLunch ?? this.hasLunch,
        hasDinner: hasDinner ?? this.hasDinner,
        reminderShowDetails: reminderShowDetails ?? this.reminderShowDetails,
      );
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

class CustomFoodLine {
  final String nutrientId;
  final String? form;
  final double labelAmount;
  final String labelUnit;
  final IntakeSource source;

  const CustomFoodLine({
    required this.nutrientId,
    this.form,
    required this.labelAmount,
    required this.labelUnit,
    required this.source,
  });
}

class CustomFoodInput {
  final String name;
  final String portionUnit;
  final double labelBasisQty;
  final String labelBasisUnit;
  final List<CustomFoodLine> lines;

  const CustomFoodInput({
    required this.name,
    required this.portionUnit,
    required this.labelBasisQty,
    required this.labelBasisUnit,
    required this.lines,
  });
}

class CustomFood {
  final int id;
  final String name;
  final String portionUnit;
  final double labelBasisQty;
  final String labelBasisUnit;
  final DateTime createdAt;
  final bool archived;
  final List<CustomFoodLine> lines;

  const CustomFood({
    required this.id,
    required this.name,
    required this.portionUnit,
    required this.labelBasisQty,
    required this.labelBasisUnit,
    required this.createdAt,
    required this.archived,
    required this.lines,
  });

  /// Quy ước schemaV1: có dòng `addedSugar` (dù `0`) => đã biết đường bổ sung.
  bool get addedSugarKnown => lines.any((l) => l.nutrientId == 'addedSugar');
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
