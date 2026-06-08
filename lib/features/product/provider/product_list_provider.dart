import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repository/product_repository.dart';
import '../../../data/local/daos/product_dao.dart';

final productListWithDetailsProvider = StreamProvider.autoDispose<List<ProductWithIngredients>>((ref) {
  final repository = ref.watch(productRepositoryProvider);
  return repository.watchProductsWithIngredients();
});
