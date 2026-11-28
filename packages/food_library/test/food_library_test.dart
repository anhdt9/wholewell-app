import 'dart:io';

import 'package:food_library/food_library.dart';
import 'package:health_engine/health_engine.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:test/test.dart';

final _pack = ReferencePack.fromJsonString(File('../health_engine/assets/reference_pack.json').readAsStringSync());

class _TempStore implements FoodLibraryAssetStore {
  final String path;
  _TempStore(this.path);
  @override
  Future<String> prepareDatabaseFile({required String libraryVersion, required String expectedSha256}) async => path;
}

String _createSampleLibraryDb(Directory dir) {
  final path = '${dir.path}/sample_food_library.db';
  final db = sqlite3.open(path);
  db.execute('''
    CREATE TABLE meta (
      library_version TEXT NOT NULL,
      usda_release TEXT NOT NULL,
      fped_release TEXT NOT NULL,
      built_at TEXT NOT NULL,
      pack_version TEXT NOT NULL
    );
    CREATE TABLE foods (
      id TEXT PRIMARY KEY,
      kind TEXT NOT NULL,
      name_vi TEXT NOT NULL,
      name_en TEXT,
      aliases_vi TEXT,
      search_ascii TEXT NOT NULL,
      is_estimate INTEGER NOT NULL,
      added_sugar_known INTEGER NOT NULL,
      niacin_fortified_unseparated INTEGER NOT NULL,
      folate_unseparated INTEGER NOT NULL,
      default_portion_id TEXT
    );
    CREATE TABLE food_portions (
      id TEXT PRIMARY KEY,
      food_id TEXT NOT NULL,
      label_vi TEXT NOT NULL,
      grams REAL NOT NULL
    );
    CREATE TABLE food_nutrients_per_100g (
      food_id TEXT NOT NULL,
      nutrient_id TEXT NOT NULL,
      source TEXT NOT NULL,
      form TEXT,
      amount REAL NOT NULL,
      ul_amount REAL,
      unit TEXT NOT NULL
    );
    CREATE VIRTUAL TABLE foods_fts USING fts5(
      name_vi,
      aliases_vi,
      search_ascii,
      name_en,
      content='foods',
      content_rowid='rowid'
    );
  ''');

  db.execute("INSERT INTO meta VALUES ('2026.11.25-1', 'FDC 2026-10', 'FPED 2021-2023', '2026-11-25', '2026.11.25-2')");

  // 1. Công thức Phở bò (estimate)
  db.execute(
    "INSERT INTO foods VALUES ('recipe:pho-bo', 'recipe', 'Phở bò', 'Beef noodle soup', 'pho bo tai nam', "
    "'pho bo tai nam beef noodle soup', 1, 1, 0, 0, 'p_pho_bat')",
  );
  db.execute("INSERT INTO food_portions VALUES ('p_pho_bat', 'recipe:pho-bo', '1 bát vừa', 450)");
  db.execute(
    "INSERT INTO food_nutrients_per_100g VALUES ('recipe:pho-bo', 'energyKcal', 'food', NULL, 100, NULL, 'kcal')",
  );
  db.execute("INSERT INTO food_nutrients_per_100g VALUES ('recipe:pho-bo', 'addedSugar', 'food', NULL, 0, NULL, 'g')");
  db.execute(
    "INSERT INTO food_nutrients_per_100g VALUES ('recipe:pho-bo', 'totalSugar', 'food', NULL, 1.5, NULL, 'g')",
  );

  // 2. Ngũ cốc tăng cường (folicAcid + vitE ul_amount * 2)
  db.execute(
    "INSERT INTO foods VALUES ('usda:173904', 'usda_sr', 'Ngũ cốc ăn sáng tăng cường', 'Breakfast cereal fortified', "
    "'ngu coc an sang', 'ngu coc an sang tang cuong breakfast cereal fortified', 0, 1, 1, 0, 'p_cereal_chen')",
  );
  db.execute("INSERT INTO food_portions VALUES ('p_cereal_chen', 'usda:173904', '1 chén', 30)");
  db.execute(
    "INSERT INTO food_nutrients_per_100g VALUES ('usda:173904', 'folicAcid', 'fortified', 'folic_acid', 200, NULL, 'ug')",
  );
  db.execute(
    "INSERT INTO food_nutrients_per_100g VALUES ('usda:173904', 'folate', 'food', 'natural_folate', 40, NULL, 'ug_DFE')",
  );
  db.execute(
    "INSERT INTO food_nutrients_per_100g VALUES ('usda:173904', 'vitE', 'fortified', 'synthetic_2r', 15, 30, 'mg')",
  );
  db.execute("INSERT INTO food_nutrients_per_100g VALUES ('usda:173904', 'vitE', 'food', NULL, 2, NULL, 'mg')");

  // 3. Món có footnote RRR-alpha-tocopherol + folate unseparated
  db.execute(
    "INSERT INTO foods VALUES ('usda:999001', 'usda_sr', 'Sữa hạt RRR vitamin E', 'Soy milk RRR vit E', NULL, "
    "'sua hat rrr vitamin e soy milk rrr vit e', 0, 0, 0, 1, NULL)",
  );
  db.execute(
    "INSERT INTO food_nutrients_per_100g VALUES ('usda:999001', 'vitE', 'fortified', 'natural_2r', 10, NULL, 'mg')",
  );
  db.execute("INSERT INTO food_nutrients_per_100g VALUES ('usda:999001', 'folate', 'food', NULL, 50, NULL, 'ug_DFE')");

  db.execute("INSERT INTO foods_fts(foods_fts) VALUES ('rebuild')");
  db.close();
  return path;
}

void main() {
  test('mở SQLite chỉ đọc có kiểm SHA-256, tìm không dấu FTS5 và thoát ký tự đặc biệt', () async {
    final dir = Directory.systemTemp.createTempSync('wholewell_fl_');
    addTearDown(() => dir.deleteSync(recursive: true));
    final path = _createSampleLibraryDb(dir);
    final hash = await computeFileSha256(path);

    await expectLater(
      SqliteFoodLibraryRepository.open(
        store: _TempStore(path),
        libraryVersion: '2026.11.25-1',
        expectedSha256: '0' * 64,
      ),
      throwsA(isA<FoodLibraryIntegrityException>()),
    );

    final repo = await SqliteFoodLibraryRepository.open(
      store: _TempStore(path),
      libraryVersion: '2026.11.25-1',
      expectedSha256: hash,
    );
    addTearDown(repo.close);

    expect(repo.meta.packVersion, '2026.11.25-2');

    // Tìm tiếng Việt không dấu
    final pho = await repo.search('pho bo');
    expect(pho.single.id, 'recipe:pho-bo');
    expect(pho.single.isEstimate, isTrue);
    expect(pho.single.defaultPortionGrams, 450);

    // Ký tự đặc biệt FTS5 không văng lỗi
    expect(await repo.search('"*()-:'), isEmpty);
    final specialQuery = await repo.search('pho "bo" (tai) -nam*');
    expect(specialQuery.single.id, 'recipe:pho-bo');
  });

  test('computeLines giữ totalSugar ngoài engine, tách folicAcid và ulAmounts của vitE', () async {
    final dir = Directory.systemTemp.createTempSync('wholewell_fl_');
    addTearDown(() => dir.deleteSync(recursive: true));
    final path = _createSampleLibraryDb(dir);
    final hash = await computeFileSha256(path);
    final repo = await SqliteFoodLibraryRepository.openVerifiedPath(path: path, expectedSha256: hash);
    addTearDown(repo.close);

    // Món có totalSugar chỉ để hiển thị
    final pho = (await repo.getById('recipe:pho-bo'))!;
    expect(pho.displayAmountPer100g('totalSugar'), 1.5);
    final phoLines = repo.computeLines(pho, 200, pack: _pack);
    expect(phoLines.any((l) => l.nutrientId == 'totalSugar'), isFalse);
    expect(phoLines.firstWhere((l) => l.nutrientId == 'energyKcal').amounts['energyKcal'], 200);

    // Cereal 50 g: folicAcid = 100 ug -> folate = 170, natural folate = 20; vitE fort = 7.5 (ul 15), food = 1
    final cereal = (await repo.getById('usda:173904'))!;
    expect(cereal.niacinFortifiedUnseparated, isTrue);
    final cLines = repo.computeLines(cereal, 50, pack: _pack);
    final faLine = cLines.firstWhere((l) => l.nutrientId == 'folicAcid');
    expect(faLine.amounts['folicAcid'], closeTo(100, 1e-9));
    expect(faLine.amounts['folate'], closeTo(170, 1e-9));

    final veFort = cLines.firstWhere((l) => l.nutrientId == 'vitE' && l.source == IntakeSource.fortified);
    expect(veFort.amounts['vitE'], closeTo(7.5, 1e-9));
    expect(veFort.ulAmounts?['vitE'], closeTo(15.0, 1e-9));

    // Ngoại lệ RRR vitE: ulAmounts == null -> tính 1x theo amounts
    final rrr = (await repo.getById('usda:999001'))!;
    expect(rrr.folateUnseparated, isTrue);
    final rrrLines = repo.computeLines(rrr, 100, pack: _pack);
    final rrrVe = rrrLines.firstWhere((l) => l.nutrientId == 'vitE');
    expect(rrrVe.amounts['vitE'], 10);
    expect(rrrVe.ulAmounts, isNull);
  });
}
