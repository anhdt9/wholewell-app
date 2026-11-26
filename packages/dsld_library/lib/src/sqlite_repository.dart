/// Đọc thư viện NIH DSLD từ tệp SQLite chỉ đọc có FTS5 và kiểm toàn vẹn SHA-256.
library;

import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:sqlite3/sqlite3.dart';

import 'fake_repository.dart';
import 'models.dart';
import 'repository.dart';

/// Tính SHA-256 hex chữ thường của một tệp trên ổ đĩa.
Future<String> computeDsldFileSha256(String path) async {
  final f = File(path);
  if (!await f.exists()) {
    throw DsldLibraryIntegrityException('Không tìm thấy tệp thư viện nhãn tại $path');
  }
  final digest = await sha256.bind(f.openRead()).first;
  return digest.toString();
}

/// Xây truy vấn MATCH an toàn cho FTS5 từ chuỗi tìm kiếm.
String? buildSafeDsldFts5Query(String raw) {
  final cleaned = raw.toLowerCase().replaceAll(RegExp(r'[^a-z0-9\s]'), ' ').trim();
  if (cleaned.isEmpty) return null;
  final tokens = [
    for (final t in cleaned.split(RegExp(r'\s+')))
      if (t.isNotEmpty) '"$t"*',
  ];
  if (tokens.isEmpty) return null;
  return tokens.join(' ');
}

class SqliteDsldLibraryRepository implements DsldLibraryRepository {
  final Database _db;
  @override
  final DsldLibraryMeta meta;

  SqliteDsldLibraryRepository._(this._db, this.meta);

  /// Chuẩn bị tệp qua [store], kiểm SHA-256 trên tệp cục bộ rồi mở chỉ đọc.
  static Future<SqliteDsldLibraryRepository> open({
    required DsldLibraryAssetStore store,
    required String libraryVersion,
    required String expectedSha256,
  }) async {
    final path = await store.prepareDatabaseFile(
      libraryVersion: libraryVersion,
      expectedSha256: expectedSha256,
    );
    return openVerifiedPath(path: path, expectedSha256: expectedSha256);
  }

  /// Mở trực tiếp đường dẫn tệp sau khi xác minh SHA-256.
  static Future<SqliteDsldLibraryRepository> openVerifiedPath({
    required String path,
    required String expectedSha256,
  }) async {
    final actual = await computeDsldFileSha256(path);
    if (actual.toLowerCase() != expectedSha256.toLowerCase()) {
      throw DsldLibraryIntegrityException(
        'Sai SHA-256 thư viện nhãn (kỳ vọng $expectedSha256, thực tế $actual)',
      );
    }
    late final Database db;
    try {
      db = sqlite3.open(path, mode: OpenMode.readOnly);
      final rows = db.select('SELECT * FROM meta LIMIT 1');
      if (rows.isEmpty) {
        throw const DsldLibraryIntegrityException('Thiếu bảng meta trong thư viện nhãn');
      }
      final m = rows.first;
      final meta = DsldLibraryMeta(
        libraryVersion: m['library_version'] as String,
        dsldRelease: m['dsld_release'] as String,
        builtAt: m['built_at'] as String,
        productCount: m['product_count'] as int,
        factCount: m['fact_count'] as int,
        sha256: actual,
      );
      return SqliteDsldLibraryRepository._(db, meta);
    } on DsldLibraryIntegrityException {
      rethrow;
    } on Object catch (e) {
      throw DsldLibraryIntegrityException('Không mở được thư viện nhãn: $e');
    }
  }

  @override
  Future<List<DsldProductDetail>> findByBarcode(String barcode) async {
    final variants = FakeDsldLibraryRepository.barcodeVariants(barcode).toList();
    if (variants.isEmpty) return const [];
    final placeholders = List.filled(variants.length, '?').join(',');
    final rows = _db.select(
      '''
      SELECT dsld_id, barcode, product_name, brand_name, serving_size,
             supplement_form, net_contents, suggested_use, other_ingredients
      FROM products
      WHERE barcode IN ($placeholders)
      ORDER BY dsld_id DESC
      ''',
      variants,
    );
    return [for (final r in rows) _detailFromRow(r)];
  }

  @override
  Future<List<DsldProductSummary>> searchByName(String query, {int limit = 30}) async {
    if (limit <= 0 || query.trim().length < 2) return const [];
    final matchQuery = buildSafeDsldFts5Query(query);
    if (matchQuery == null) return const [];
    final rows = _db.select(
      '''
      SELECT p.dsld_id, p.barcode, p.product_name, p.brand_name,
             p.serving_size, p.supplement_form
      FROM products_fts
      JOIN products p ON p.dsld_id = products_fts.rowid
      WHERE products_fts MATCH ?
      ORDER BY bm25(products_fts), p.dsld_id DESC
      LIMIT ?
      ''',
      [matchQuery, limit],
    );
    return [
      for (final r in rows)
        DsldProductSummary(
          dsldId: r['dsld_id'] as int,
          barcode: r['barcode'] as String,
          productName: r['product_name'] as String,
          brandName: r['brand_name'] as String,
          servingSize: r['serving_size'] as String,
          supplementForm: r['supplement_form'] as String,
        ),
    ];
  }

  @override
  Future<DsldProductDetail?> getDetail(int dsldId) async {
    final rows = _db.select(
      '''
      SELECT dsld_id, barcode, product_name, brand_name, serving_size,
             supplement_form, net_contents, suggested_use, other_ingredients
      FROM products
      WHERE dsld_id = ?
      LIMIT 1
      ''',
      [dsldId],
    );
    if (rows.isEmpty) return null;
    return _detailFromRow(rows.first);
  }

  DsldProductDetail _detailFromRow(Row r) {
    final dsldId = r['dsld_id'] as int;
    final factRows = _db.select(
      '''
      SELECT ingredient, category, amount, unit, dv_percent, dv_group
      FROM facts
      WHERE dsld_id = ?
      ORDER BY id ASC
      ''',
      [dsldId],
    );
    return DsldProductDetail(
      dsldId: dsldId,
      barcode: r['barcode'] as String,
      productName: r['product_name'] as String,
      brandName: r['brand_name'] as String,
      servingSize: r['serving_size'] as String,
      supplementForm: r['supplement_form'] as String,
      netContents: r['net_contents'] as String,
      suggestedUse: r['suggested_use'] as String,
      otherIngredients: r['other_ingredients'] as String,
      facts: [
        for (final f in factRows)
          DsldFact(
            ingredient: f['ingredient'] as String,
            category: f['category'] as String,
            amount: f['amount'] as String,
            unit: f['unit'] as String,
            dvPercent: f['dv_percent'] as String,
            dvGroup: f['dv_group'] as String,
          ),
      ],
    );
  }

  @override
  void close() => _db.close();
}
