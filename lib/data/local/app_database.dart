import 'package:drift/drift.dart';
import 'tables/products_table.dart';
import 'tables/product_ingredients_table.dart';
import 'daos/product_dao.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [Products, ProductIngredients], daos: [ProductDao])
class AppDatabase extends _$AppDatabase {
  AppDatabase(QueryExecutor e) : super(e);

  @override
  late final ProductDao productDao = ProductDao(this);

  @override
  int get schemaVersion => 1;
}
