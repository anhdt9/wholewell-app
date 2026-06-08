import 'package:drift/drift.dart';
import 'products_table.dart';

class ProductIngredients extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get productId => integer().references(Products, #id).nullable()();
  TextColumn get nutrientKey => text().withLength(min: 1, max: 128)();
  TextColumn get nutrientName => text().withLength(min: 1, max: 255)();
  TextColumn get variantKey => text().withLength(min: 0, max: 128).nullable()();
  TextColumn get variantName => text().withLength(min: 0, max: 255).nullable()();
  RealColumn get compoundAmount => real().nullable()();
  TextColumn get compoundUnit => text().withLength(min: 0, max: 32).nullable()();
  RealColumn get elementalAmount => real().nullable()();
  TextColumn get elementalUnit => text().withLength(min: 0, max: 32).nullable()();
  TextColumn get amountAccuracyStatus => text().withLength(min: 1, max: 64)();
  TextColumn get sourceText => text().nullable()();
  IntColumn get confidence => integer().withDefault(const Constant(0))();
  TextColumn get note => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}
