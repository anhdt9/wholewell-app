import 'dart:io';

import 'package:dsld_library/dsld_library.dart';
import 'package:path/path.dart' as p;
import 'package:sqlite3/sqlite3.dart';
import 'package:test/test.dart';

Future<String> _createSampleDb(String dir) async {
  final dbPath = p.join(dir, 'sample_dsld.db');
  final db = sqlite3.open(dbPath);
  db.execute('''
    CREATE TABLE meta (
      library_version TEXT NOT NULL,
      dsld_release TEXT NOT NULL,
      built_at TEXT NOT NULL,
      product_count INTEGER NOT NULL,
      fact_count INTEGER NOT NULL
    );
  ''');
  db.execute(
    "INSERT INTO meta VALUES ('2026.01.16-test', 'test', '2026-11-26', 2, 2);",
  );
  db.execute('''
    CREATE TABLE products (
      dsld_id INTEGER PRIMARY KEY,
      barcode TEXT NOT NULL,
      product_name TEXT NOT NULL,
      brand_name TEXT NOT NULL,
      serving_size TEXT NOT NULL,
      supplement_form TEXT NOT NULL,
      net_contents TEXT NOT NULL,
      suggested_use TEXT NOT NULL,
      other_ingredients TEXT NOT NULL DEFAULT ''
    );
  ''');
  db.execute('''
    INSERT INTO products VALUES
      (268234, '023249012344', 'Vitamin D3 + K2', 'Sports Research', '1 Liquid Veggie Softgel', 'Softgel', '60 Softgels', 'Take 1 softgel daily', 'Coconut oil, tapioca starch'),
      (100001, '0074312706400', 'B-2 100 mg', 'Nature''s Bounty', '1 Tablet', 'Tablet', '100 Tablets', 'Take 1 tablet daily', 'Vegetable cellulose');
  ''');
  db.execute('''
    CREATE TABLE facts (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      dsld_id INTEGER NOT NULL,
      ingredient TEXT NOT NULL,
      category TEXT NOT NULL,
      amount TEXT NOT NULL,
      unit TEXT NOT NULL,
      dv_percent TEXT NOT NULL,
      dv_group TEXT NOT NULL
    );
  ''');
  db.execute('''
    INSERT INTO facts (dsld_id, ingredient, category, amount, unit, dv_percent, dv_group) VALUES
      (268234, 'Vitamin D', 'vitamin', '125', 'mcg', '625', 'Adults'),
      (100001, 'Riboflavin', 'vitamin', '100', 'mg', '7692', 'Adults');
  ''');
  db.execute('CREATE INDEX idx_products_barcode ON products(barcode);');
  db.execute('CREATE INDEX idx_facts_dsld_id ON facts(dsld_id);');
  db.execute(
    "CREATE VIRTUAL TABLE products_fts USING fts5(product_name, brand_name, content='products', content_rowid='dsld_id');",
  );
  db.execute("INSERT INTO products_fts(products_fts) VALUES('rebuild');");
  db.close();
  return dbPath;
}

void main() {
  test('SqliteDsldLibraryRepository verifies sha256, barcode variants, FTS5 and getDetail', () async {
    final tmp = await Directory.systemTemp.createTemp('dsld_lib_test_');
    addTearDown(() => tmp.delete(recursive: true));

    final dbPath = await _createSampleDb(tmp.path);
    final sha = await computeDsldFileSha256(dbPath);

    await expectLater(
      () => SqliteDsldLibraryRepository.openVerifiedPath(
        path: dbPath,
        expectedSha256: '0' * 64,
      ),
      throwsA(isA<DsldLibraryIntegrityException>()),
    );

    final repo = await SqliteDsldLibraryRepository.openVerifiedPath(
      path: dbPath,
      expectedSha256: sha,
    );
    addTearDown(repo.close);

    expect(repo.meta.productCount, 2);
    expect(repo.meta.factCount, 2);

    // 12-digit UPC-A and 13-digit EAN-13 with leading 0 both match.
    final by12 = await repo.findByBarcode('0 23249 01234 4');
    expect(by12, hasLength(1));
    expect(by12.first.productName, 'Vitamin D3 + K2');
    expect(by12.first.otherIngredients, 'Coconut oil, tapioca starch');
    expect(by12.first.facts.single.ingredient, 'Vitamin D');

    final by13 = await repo.findByBarcode('0023249012344');
    expect(by13, hasLength(1));
    expect(by13.first.dsldId, 268234);

    // 13-digit in DB matched by 12-digit scan without leading 0.
    final by12For13 = await repo.findByBarcode('074312706400');
    expect(by12For13, hasLength(1));
    expect(by12For13.first.dsldId, 100001);

    // FTS5 search by brand & product name, safe with special chars.
    final fts = await repo.searchByName('Sports Research "D3"*');
    expect(fts, hasLength(1));
    expect(fts.first.dsldId, 268234);

    final detail = await repo.getDetail(100001);
    expect(detail, isNotNull);
    expect(detail!.facts.single.amount, '100');
  });

  test('FakeDsldLibraryRepository supports barcode variants and search', () async {
    final repo = FakeDsldLibraryRepository(
      products: const [
        DsldProductDetail(
          dsldId: 1,
          barcode: '023249012344',
          productName: 'Vitamin D3 + K2',
          brandName: 'Sports Research',
          servingSize: '1 Softgel',
          supplementForm: 'Softgel',
          netContents: '60 Softgels',
          suggestedUse: '1 daily',
          otherIngredients: 'Coconut oil',
          facts: [
            DsldFact(
              ingredient: 'Vitamin D',
              category: 'vitamin',
              amount: '125',
              unit: 'mcg',
              dvPercent: '625',
              dvGroup: 'Adults',
            ),
          ],
        ),
      ],
    );

    expect(await repo.findByBarcode('0023249012344'), hasLength(1));
    expect(await repo.searchByName('sports d3'), hasLength(1));
    expect(await repo.getDetail(1), isNotNull);
  });
}
