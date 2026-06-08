import 'package:drift/drift.dart';

class Products extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 255)();
  TextColumn get brand => text().withLength(min: 0, max: 255).nullable()();
  RealColumn get price => real().nullable()();
  TextColumn get currency => text().withLength(min: 1, max: 16).withDefault(const Constant('VND'))();
  IntColumn get totalQuantity => integer().withDefault(const Constant(0))();
  RealColumn get servingSize => real().withDefault(const Constant(0.0))();
  TextColumn get servingType => text().withLength(min: 0, max: 64).nullable()();
  TextColumn get imagePath => text().nullable()();
  TextColumn get note => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}
