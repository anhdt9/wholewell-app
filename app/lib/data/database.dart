import 'package:drift/drift.dart';
import 'package:health_engine/health_engine.dart';

part 'database.g.dart';

// Lược đồ phiên bản 1 (docs/specs/encrypted-db.md).
// Quy ước: ngày là TEXT 'YYYY-MM-DD' theo giờ máy; thời điểm là mili giây UTC.

enum RegimenKind { supplement, water }

enum DoseStatus { taken, skipped, late }

/// Nguồn của một chất trong sản phẩm (để xác định phạm vi UL).
enum ProductNutrientSource { supplement, fortified }

@DataClassName('PersonRow')
class People extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get displayName => text()();
  BoolColumn get isPrimary => boolean().withDefault(const Constant(false))();
  IntColumn get createdAt => integer()();
}

/// Chỉ người từ 18 tuổi có hồ sơ; trẻ em chỉ có trong [People] để tính vào kho.
@DataClassName('ProfileRow')
class Profiles extends Table {
  IntColumn get personId => integer().references(People, #id, onDelete: KeyAction.cascade)();
  IntColumn get ageYears => integer()();
  TextColumn get sex => textEnum<Sex>()();
  RealColumn get heightCm => real()();
  RealColumn get weightKg => real()();
  TextColumn get stage => textEnum<LifeStage>()();
  IntColumn get gestationWeek => integer().nullable()();
  TextColumn get prePregnancyBmi => textEnum<BmiClass>().nullable()();
  IntColumn get monthsPostpartum => integer().nullable()();
  TextColumn get activityLevel => textEnum<ActivityLevel>()();
  IntColumn get updatedAt => integer()();

  @override
  Set<Column> get primaryKey => {personId};
}

@DataClassName('SettingRow')
class Settings extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column> get primaryKey => {key};
}

@DataClassName('ProductRow')
class Products extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get shortName => text()();
  TextColumn get fullName => text().nullable()();
  TextColumn get dosageForm => text()();
  RealColumn get unitsPerServing => real()();
  RealColumn get servingsPerContainer => real().nullable()();
  TextColumn get barcode => text().nullable()();
  TextColumn get labelPhotoPath => text().nullable()();
  BoolColumn get confirmed => boolean().withDefault(const Constant(false))();
  IntColumn get createdAt => integer()();
}

@DataClassName('ProductNutrientRow')
class ProductNutrients extends Table {
  IntColumn get productId => integer().references(Products, #id, onDelete: KeyAction.cascade)();
  TextColumn get nutrientId => text()();

  /// Dạng chất in trên nhãn (vd. cholecalciferol, beta-carotene); '' khi không ghi.
  TextColumn get chemicalForm => text().withDefault(const Constant(''))();
  RealColumn get amountPerServing => real()();
  TextColumn get unit => text()();
  TextColumn get source => textEnum<ProductNutrientSource>()();

  @override
  Set<Column> get primaryKey => {productId, nutrientId, chemicalForm};
}

@DataClassName('InventoryBoxRow')
class InventoryBoxes extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get productId => integer().references(Products, #id)();
  RealColumn get unitsRemaining => real()();
  TextColumn get openedOn => text().nullable()();
  TextColumn get expiresOn => text().nullable()();
  BoolColumn get discarded => boolean().withDefault(const Constant(false))();
  IntColumn get createdAt => integer()();
}

@DataClassName('RegimenRow')
class Regimens extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get personId => integer().references(People, #id, onDelete: KeyAction.cascade)();
  TextColumn get kind => textEnum<RegimenKind>()();
  IntColumn get productId => integer().nullable().references(Products, #id)();
  RealColumn get unitsPerDose => real().nullable()();
  RealColumn get waterMl => real().nullable()();
  IntColumn get minuteOfDay => integer()();
  BoolColumn get withMeal => boolean().withDefault(const Constant(false))();

  /// Bit 0 = thứ Hai … bit 6 = Chủ nhật; 127 = mọi ngày.
  IntColumn get weekdays => integer().withDefault(const Constant(127))();
  IntColumn get remindRepeat => integer().withDefault(const Constant(0))();
  IntColumn get remindIntervalMin => integer().withDefault(const Constant(0))();
  BoolColumn get active => boolean().withDefault(const Constant(true))();
  IntColumn get createdAt => integer()();

  @override
  List<String> get customConstraints => ['CHECK (minute_of_day BETWEEN 0 AND 1439)'];
}

@DataClassName('DoseLogRow')
class DoseLogs extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get regimenId => integer().references(Regimens, #id, onDelete: KeyAction.cascade)();
  TextColumn get day => text()();
  IntColumn get minuteOfDay => integer()();
  TextColumn get status => textEnum<DoseStatus>()();
  IntColumn get takenAt => integer().nullable()();
  IntColumn get boxId => integer().nullable().references(InventoryBoxes, #id)();

  @override
  List<Set<Column>> get uniqueKeys => [
        {regimenId, day, minuteOfDay},
      ];
}

@DataClassName('IntakeEntryRow')
class IntakeEntries extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get personId => integer().references(People, #id, onDelete: KeyAction.cascade)();
  TextColumn get day => text()();
  TextColumn get label => text()();
  TextColumn get source => textEnum<IntakeSource>()();
  TextColumn get mealId => text().nullable()();
  IntColumn get productId => integer().nullable().references(Products, #id)();
  IntColumn get doseLogId => integer().nullable().references(DoseLogs, #id, onDelete: KeyAction.setNull)();
  IntColumn get createdAt => integer()();
}

@DataClassName('IntakeNutrientRow')
class IntakeNutrients extends Table {
  IntColumn get entryId => integer().references(IntakeEntries, #id, onDelete: KeyAction.cascade)();
  TextColumn get nutrientId => text()();
  RealColumn get amount => real()();
  TextColumn get unit => text()();

  @override
  Set<Column> get primaryKey => {entryId, nutrientId};
}

@DataClassName('WorkoutRow')
class Workouts extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get personId => integer().references(People, #id, onDelete: KeyAction.cascade)();
  TextColumn get day => text()();
  TextColumn get activityCode => text()();
  RealColumn get minutes => real()();
  IntColumn get createdAt => integer()();
}

@DataClassName('WaterLogRow')
class WaterLogs extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get personId => integer().references(People, #id, onDelete: KeyAction.cascade)();
  TextColumn get day => text()();
  RealColumn get ml => real()();
  IntColumn get createdAt => integer()();
}

@DriftDatabase(tables: [
  People,
  Profiles,
  Settings,
  Products,
  ProductNutrients,
  InventoryBoxes,
  Regimens,
  DoseLogs,
  IntakeEntries,
  IntakeNutrients,
  Workouts,
  WaterLogs,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        beforeOpen: (details) async {
          // Đặt cả ở đây để mọi kết nối (kể cả trong test) đều bật khóa ngoại.
          await customStatement('PRAGMA foreign_keys = ON');
        },
      );
}

/// 'YYYY-MM-DD' theo giờ máy.
String dayKey(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

DateTime parseDayKey(String s) {
  final p = s.split('-');
  return DateTime(int.parse(p[0]), int.parse(p[1]), int.parse(p[2]));
}
