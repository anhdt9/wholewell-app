/// Bản giả dùng trong bộ nhớ cho unit và widget test.
library;

import 'package:health_engine/health_engine.dart';
import 'package:journal_db/journal_db.dart';

import 'models.dart';
import 'repository.dart';

class FakeFoodLibraryRepository implements FoodLibraryRepository {
  final List<FoodDetail> _foods;

  @override
  final FoodLibraryMeta meta;

  FakeFoodLibraryRepository(
    Iterable<FoodDetail> foods, {
    this.meta = const FoodLibraryMeta(
      libraryVersion: 'fake-1',
      usdaRelease: 'test',
      fpedRelease: 'test',
      builtAt: '2026-11-25',
      packVersion: '2026.11.25-2',
      sha256: 'fake',
    ),
  }) : _foods = List.unmodifiable(foods);

  @override
  Future<List<FoodSummary>> search(String query, {int limit = 30}) async {
    final q = normalizeSearchAscii(query);
    final tokens = [for (final t in q.split(' ')) if (t.isNotEmpty) t];
    final out = <FoodSummary>[];
    for (final f in _foods) {
      final haystack = normalizeSearchAscii(
        '${f.nameVi} ${f.aliasesVi ?? ''} ${f.nameEn ?? ''}',
      );
      if (tokens.every(haystack.contains)) {
        final dp = f.defaultPortion;
        out.add(FoodSummary(
          id: f.id,
          kind: f.kind,
          nameVi: f.nameVi,
          nameEn: f.nameEn,
          isEstimate: f.isEstimate,
          addedSugarKnown: f.addedSugarKnown,
          defaultPortionId: f.defaultPortionId,
          defaultPortionLabel: dp?.labelVi,
          defaultPortionGrams: dp?.grams,
          energyKcalPer100g: f.displayAmountPer100g('energyKcal') ?? 0,
        ));
        if (out.length >= limit) break;
      }
    }
    return out;
  }

  @override
  Future<FoodDetail?> getById(String foodRef) async {
    for (final f in _foods) {
      if (f.id == foodRef) return f;
    }
    return null;
  }

  @override
  List<IntakeLine> computeLines(FoodDetail food, double grams, {required ReferencePack pack}) =>
      computeFoodIntakeLines(food, grams, pack: pack);

  @override
  Future<void> close() async {}
}
