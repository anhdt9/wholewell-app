import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/local/app_database.dart';
import '../../../data/local/daos/product_dao.dart';
import '../../../core/providers/database_provider.dart';

final productRepositoryProvider = Provider<ProductRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return ProductRepository(db.productDao);
});

class ProductRepository {
  final ProductDao dao;
  ProductRepository(this.dao);

  Stream<List<Product>> watchProducts() => dao.watchAllProducts();

  Stream<List<ProductWithIngredients>> watchProductsWithIngredients() => dao.watchProductsWithIngredients();

  Stream<ProductWithIngredients?> watchProduct(int id) => dao.watchProductWithIngredients(id);

  Future<ProductWithIngredients?> fetchProduct(int id) => dao.getProductWithIngredients(id);

  Future<void> saveProductWithIngredients(ProductsCompanion product, List<ProductIngredientsCompanion> ingredients) => dao.createProductWithIngredients(product, ingredients);

  Future<void> updateProductWithIngredients(Product product, List<ProductIngredient> ingredients) => dao.updateProductWithIngredients(product, ingredients);

  Future<void> deleteProduct(int id) => dao.deleteProductById(id);

  Future<void> deleteIngredient(int id) => dao.deleteIngredientById(id);
}
