/// Bản giả lập [DsldLibraryRepository] phục vụ test giao diện và unit test.
library;

import 'models.dart';
import 'repository.dart';

class FakeDsldLibraryRepository implements DsldLibraryRepository {
  @override
  final DsldLibraryMeta meta;
  final List<DsldProductDetail> _products;

  FakeDsldLibraryRepository({DsldLibraryMeta? meta, List<DsldProductDetail> products = const []})
    : meta =
          meta ??
          DsldLibraryMeta(
            libraryVersion: 'test',
            dsldRelease: 'test',
            builtAt: '2026-11-26',
            productCount: products.length,
            factCount: products.fold(0, (s, p) => s + p.facts.length),
            sha256: 'fake',
          ),
      _products = products;

  static Set<String> barcodeVariants(String raw) {
    final digits = raw.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return const {};
    final variants = <String>{digits};
    if (digits.length == 12) {
      variants.add('0$digits');
    } else if (digits.length == 13 && digits.startsWith('0')) {
      variants.add(digits.substring(1));
    }
    return variants;
  }

  @override
  Future<List<DsldProductDetail>> findByBarcode(String barcode) async {
    final variants = barcodeVariants(barcode);
    if (variants.isEmpty) return const [];
    return [
      for (final p in _products)
        if (variants.contains(p.barcode.replaceAll(RegExp(r'\D'), ''))) p,
    ];
  }

  @override
  Future<List<DsldProductSummary>> searchByName(String query, {int limit = 30}) async {
    if (limit <= 0) return const [];
    final q = query.trim().toLowerCase();
    if (q.length < 2) return const [];
    final tokens = q.split(RegExp(r'\s+')).where((t) => t.isNotEmpty).toList();
    final out = <DsldProductSummary>[];
    for (final p in _products) {
      final hay = '${p.productName} ${p.brandName}'.toLowerCase();
      if (tokens.every(hay.contains)) {
        out.add(
          DsldProductSummary(
            dsldId: p.dsldId,
            barcode: p.barcode,
            productName: p.productName,
            brandName: p.brandName,
            servingSize: p.servingSize,
            supplementForm: p.supplementForm,
          ),
        );
        if (out.length >= limit) break;
      }
    }
    return out;
  }

  @override
  Future<DsldProductDetail?> getDetail(int dsldId) async {
    for (final p in _products) {
      if (p.dsldId == dsldId) return p;
    }
    return null;
  }

  @override
  void close() {}
}
