import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/products_table.dart';
import '../tables/product_ingredients_table.dart';

part 'product_dao.g.dart';

class ProductWithIngredients {
  final Product product;
  final List<ProductIngredient> ingredients;

  ProductWithIngredients({required this.product, required this.ingredients});
}

@DriftAccessor(tables: [Products, ProductIngredients])
class ProductDao extends DatabaseAccessor<AppDatabase> with _$ProductDaoMixin {
  ProductDao(AppDatabase db) : super(db);

  Stream<List<Product>> watchAllProducts() {
    return select(products).watch();
  }

  Stream<List<ProductWithIngredients>> watchProductsWithIngredients() {
    return select(products).watch().asyncMap((productsList) async {
      final result = <ProductWithIngredients>[];
      for (final product in productsList) {
        final ingredients = await (select(productIngredients)..where((tbl) => tbl.productId.equals(product.id))).get();
        result.add(ProductWithIngredients(product: product, ingredients: ingredients));
      }
      return result;
    });
  }

  Stream<ProductWithIngredients?> watchProductWithIngredients(int id) {
    final query = select(products)..where((tbl) => tbl.id.equals(id));
    return query.watchSingleOrNull().asyncMap((product) async {
      if (product == null) return null;
      final ingredientQuery = (select(productIngredients)..where((tbl) => tbl.productId.equals(id))).watch();
      final ingredients = await ingredientQuery.first;
      return ProductWithIngredients(product: product, ingredients: ingredients);
    });
  }

  Future<ProductWithIngredients?> getProductWithIngredients(int id) async {
    final product = await (select(products)..where((tbl) => tbl.id.equals(id))).getSingleOrNull();
    if (product == null) return null;
    final ingredients = await (select(productIngredients)..where((tbl) => tbl.productId.equals(id))).get();
    return ProductWithIngredients(product: product, ingredients: ingredients);
  }

  Future<int> insertProduct(ProductsCompanion entry) => into(products).insert(entry);

  Future<int> insertIngredient(ProductIngredientsCompanion entry) => into(productIngredients).insert(entry);

  Future<void> updateProductEntry(Product product) => update(products).replace(product);

  Future<void> updateIngredientEntry(ProductIngredient ingredient) => update(productIngredients).replace(ingredient);

  Future<void> deleteProductById(int id) async {
    await (delete(productIngredients)..where((tbl) => tbl.productId.equals(id))).go();
    await (delete(products)..where((tbl) => tbl.id.equals(id))).go();
  }

  Future<void> deleteIngredientById(int id) async {
    await (delete(productIngredients)..where((tbl) => tbl.id.equals(id))).go();
  }

  Future<void> createProductWithIngredients(ProductsCompanion entry, List<ProductIngredientsCompanion> ingredients) async {
    await transaction(() async {
      final productId = await into(products).insert(entry);
      for (final ingredient in ingredients) {
        await into(productIngredients).insert(ingredient.copyWith(productId: Value(productId)));
      }
    });
  }

  Future<void> updateProductWithIngredients(Product product, List<ProductIngredient> ingredients) async {
    await transaction(() async {
      await update(products).replace(product);
      final existing = await (select(productIngredients)..where((tbl) => tbl.productId.equals(product.id))).get();
      final existingIds = existing.map((it) => it.id).toSet();
      final updatedIds = ingredients.map((it) => it.id).toSet();
      for (final ingredient in ingredients) {
        await update(productIngredients).replace(ingredient);
            }
      final deleteIds = existingIds.difference(updatedIds);
      if (deleteIds.isNotEmpty) {
        await (delete(productIngredients)..where((tbl) => tbl.id.isIn(deleteIds.toList()))).go();
      }
    });
  }
}
