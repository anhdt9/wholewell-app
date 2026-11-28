/// Đọc thư viện món từ tệp SQLite chỉ đọc có FTS5 và kiểm toàn vẹn SHA-256.
library;

import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:health_engine/health_engine.dart';
import 'package:journal_db/journal_db.dart';
import 'package:sqlite3/sqlite3.dart';

import 'models.dart';
import 'repository.dart';

/// Tính SHA-256 hex chữ thường của một tệp trên ổ đĩa.
Future<String> computeFileSha256(String path) async {
  final f = File(path);
  if (!await f.exists()) {
    throw FoodLibraryIntegrityException('Không tìm thấy tệp thư viện tại $path');
  }
  final digest = await sha256.bind(f.openRead()).first;
  return digest.toString();
}

/// Xây truy vấn MATCH an toàn cho FTS5 từ chuỗi tìm kiếm bất kỳ.
/// Trả null nếu chuỗi không có token chữ-số nào.
String? buildSafeFts5MatchQuery(String raw) {
  final ascii = normalizeSearchAscii(raw);
  if (ascii.isEmpty) return null;
  final tokens = [
    for (final t in ascii.split(' '))
      if (t.isNotEmpty) t,
  ];
  if (tokens.isEmpty) return null;
  // Bọc ngoặc kép từng token + `*` prefix để tránh mọi ký tự cú pháp FTS5 (", *, -, (, ), :).
  return [for (final t in tokens) '"$t"*'].join(' ');
}

FoodKind _kindOf(String s) => switch (s) {
  'usda_foundation' => FoodKind.usdaFoundation,
  'usda_sr' => FoodKind.usdaSr,
  'usda_fndds' => FoodKind.usdaFndds,
  'recipe' => FoodKind.recipe,
  _ => throw FoodLibraryIntegrityException('Loại món không hợp lệ: $s'),
};

IntakeSource _foodSourceOf(String s) => switch (s) {
  'food' => IntakeSource.food,
  'fortified' => IntakeSource.fortified,
  _ => throw FoodLibraryIntegrityException('Nguồn món không hợp lệ: $s'),
};

class SqliteFoodLibraryRepository implements FoodLibraryRepository {
  final Database _db;
  @override
  final FoodLibraryMeta meta;

  SqliteFoodLibraryRepository._(this._db, this.meta);

  /// Chuẩn bị tệp qua [store], kiểm SHA-256 trên tệp cục bộ rồi mở chỉ đọc.
  static Future<SqliteFoodLibraryRepository> open({
    required FoodLibraryAssetStore store,
    required String libraryVersion,
    required String expectedSha256,
  }) async {
    final path = await store.prepareDatabaseFile(libraryVersion: libraryVersion, expectedSha256: expectedSha256);
    return openVerifiedPath(path: path, expectedSha256: expectedSha256);
  }

  /// Mở trực tiếp đường dẫn tệp sau khi xác minh SHA-256 (dùng cho test và [open]).
  static Future<SqliteFoodLibraryRepository> openVerifiedPath({
    required String path,
    required String expectedSha256,
  }) async {
    final actual = await computeFileSha256(path);
    if (actual.toLowerCase() != expectedSha256.toLowerCase()) {
      throw FoodLibraryIntegrityException('Sai SHA-256 thư viện món (kỳ vọng $expectedSha256, thực tế $actual)');
    }
    late final Database db;
    try {
      db = sqlite3.open(path, mode: OpenMode.readOnly);
      final rows = db.select('SELECT * FROM meta LIMIT 1');
      if (rows.isEmpty) {
        throw const FoodLibraryIntegrityException('Thiếu bảng meta trong thư viện món');
      }
      final m = rows.first;
      final meta = FoodLibraryMeta(
        libraryVersion: m['library_version'] as String,
        usdaRelease: m['usda_release'] as String,
        fpedRelease: m['fped_release'] as String,
        builtAt: m['built_at'] as String,
        packVersion: m['pack_version'] as String,
        sha256: actual,
      );
      return SqliteFoodLibraryRepository._(db, meta);
    } on FoodLibraryIntegrityException {
      rethrow;
    } on Object catch (e) {
      throw FoodLibraryIntegrityException('Không mở được thư viện món: $e');
    }
  }

  @override
  Future<List<FoodSummary>> search(String query, {int limit = 30}) async {
    if (limit <= 0) return const [];
    final ResultSet rows;
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      rows = _db.select(
        '''
        SELECT f.id, f.kind, f.name_vi, f.name_en, f.is_estimate, f.added_sugar_known,
               f.default_portion_id,
               p.label_vi AS portion_label, p.grams AS portion_grams,
               COALESCE((SELECT SUM(n.amount) FROM food_nutrients_per_100g n
                         WHERE n.food_id = f.id AND n.nutrient_id = 'energyKcal'), 0.0) AS kcal
        FROM foods f
        LEFT JOIN food_portions p ON p.id = f.default_portion_id
        ORDER BY (f.kind = 'recipe') DESC, f.name_vi
        LIMIT ?
        ''',
        [limit],
      );
    } else {
      final ftsQuery = buildSafeFts5MatchQuery(trimmed);
      if (ftsQuery == null) return const [];
      rows = _db.select(
        '''
        SELECT f.id, f.kind, f.name_vi, f.name_en, f.is_estimate, f.added_sugar_known,
               f.default_portion_id,
               p.label_vi AS portion_label, p.grams AS portion_grams,
               COALESCE((SELECT SUM(n.amount) FROM food_nutrients_per_100g n
                         WHERE n.food_id = f.id AND n.nutrient_id = 'energyKcal'), 0.0) AS kcal
        FROM foods_fts
        JOIN foods f ON f.rowid = foods_fts.rowid
        LEFT JOIN food_portions p ON p.id = f.default_portion_id
        WHERE foods_fts MATCH ?
        ORDER BY (f.kind = 'recipe') DESC, bm25(foods_fts, 10.0, 5.0, 8.0, 3.0), length(f.name_vi)
        LIMIT ?
        ''',
        [ftsQuery, limit],
      );
    }
    return [
      for (final r in rows)
        FoodSummary(
          id: r['id'] as String,
          kind: _kindOf(r['kind'] as String),
          nameVi: r['name_vi'] as String,
          nameEn: r['name_en'] as String?,
          isEstimate: (r['is_estimate'] as int) == 1,
          addedSugarKnown: (r['added_sugar_known'] as int) == 1,
          defaultPortionId: r['default_portion_id'] as String?,
          defaultPortionLabel: r['portion_label'] as String?,
          defaultPortionGrams: (r['portion_grams'] as num?)?.toDouble(),
          energyKcalPer100g: (r['kcal'] as num).toDouble(),
        ),
    ];
  }

  @override
  Future<FoodDetail?> getById(String foodRef) async {
    final rows = _db.select('SELECT * FROM foods WHERE id = ? LIMIT 1', [foodRef]);
    if (rows.isEmpty) return null;
    final r = rows.first;
    final portions = [
      for (final p in _db.select('SELECT id, label_vi, grams FROM food_portions WHERE food_id = ? ORDER BY rowid', [
        foodRef,
      ]))
        FoodPortion(id: p['id'] as String, labelVi: p['label_vi'] as String, grams: (p['grams'] as num).toDouble()),
    ];
    final nutrients = [
      for (final n in _db.select(
        'SELECT nutrient_id, source, form, amount, ul_amount, unit '
        'FROM food_nutrients_per_100g WHERE food_id = ? ORDER BY rowid',
        [foodRef],
      ))
        FoodNutrientPer100g(
          nutrientId: n['nutrient_id'] as String,
          source: _foodSourceOf(n['source'] as String),
          form: n['form'] as String?,
          amount: (n['amount'] as num).toDouble(),
          ulAmount: (n['ul_amount'] as num?)?.toDouble(),
          unit: n['unit'] as String,
        ),
    ];
    return FoodDetail(
      id: r['id'] as String,
      kind: _kindOf(r['kind'] as String),
      nameVi: r['name_vi'] as String,
      nameEn: r['name_en'] as String?,
      aliasesVi: r['aliases_vi'] as String?,
      isEstimate: (r['is_estimate'] as int) == 1,
      addedSugarKnown: (r['added_sugar_known'] as int) == 1,
      niacinFortifiedUnseparated: (r['niacin_fortified_unseparated'] as int) == 1,
      folateUnseparated: (r['folate_unseparated'] as int) == 1,
      defaultPortionId: r['default_portion_id'] as String?,
      portions: List.unmodifiable(portions),
      nutrientsPer100g: List.unmodifiable(nutrients),
    );
  }

  @override
  List<IntakeLine> computeLines(FoodDetail food, double grams, {required ReferencePack pack}) =>
      computeFoodIntakeLines(food, grams, pack: pack);

  @override
  Future<void> close() async => _db.close();
}
