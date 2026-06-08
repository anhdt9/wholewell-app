import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repository/product_repository.dart';
import '../../../data/local/daos/product_dao.dart';

final productDetailProvider = StreamProvider.autoDispose.family<ProductWithIngredients?, int>((ref, id) {
  final repository = ref.watch(productRepositoryProvider);
  return repository.watchProduct(id);
});

final productDetailFutureProvider = FutureProvider.autoDispose.family<ProductWithIngredients?, int>((ref, id) {
  final repository = ref.watch(productRepositoryProvider);
  return repository.fetchProduct(id);
});
