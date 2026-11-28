/// Interface kho tra cứu thư viện món và tính dòng chất theo gói chuẩn.
library;

import 'package:health_engine/health_engine.dart';
import 'package:journal_db/journal_db.dart';

import 'models.dart';

/// Lớp trừu tượng để cung cấp đường dẫn tệp `food_library.db` cục bộ (tách khỏi Flutter asset).
abstract interface class FoodLibraryAssetStore {
  /// Giải nén/chuẩn bị tệp cục bộ theo [libraryVersion], kiểm [expectedSha256],
  /// xóa bản cũ nếu cần và trả về đường dẫn tệp sẵn sàng mở chỉ đọc.
  Future<String> prepareDatabaseFile({required String libraryVersion, required String expectedSha256});
}

abstract interface class FoodLibraryRepository {
  FoodLibraryMeta get meta;
  Future<List<FoodSummary>> search(String query, {int limit = 30});
  Future<FoodDetail?> getById(String foodRef);
  List<IntakeLine> computeLines(FoodDetail food, double grams, {required ReferencePack pack});
  Future<void> close();
}

/// Quy đổi chung từ `food_nutrients_per_100g` sang `List<IntakeLine>` cho cả bản SQLite và bản giả.
List<IntakeLine> computeFoodIntakeLines(FoodDetail food, double grams, {required ReferencePack pack}) {
  if (grams <= 0) throw ArgumentError.value(grams, 'grams', 'Khối lượng phải > 0');
  final scale = grams / 100.0;
  final dfeFactor = pack.unitConversions['folicAcid_ug_to_ug_DFE'] ?? 1.7;
  final out = <IntakeLine>[];
  for (final n in food.nutrientsPer100g) {
    // `totalSugar` chỉ dùng để hiển thị thông tin món, không đưa vào tính toán của engine.
    if (n.nutrientId == 'totalSugar') continue;
    final val = n.amount * scale;
    final ulVal = n.ulAmount == null ? null : n.ulAmount! * scale;
    final Map<String, double> amounts;
    if (n.nutrientId == 'folicAcid') {
      amounts = {'folicAcid': val, 'folate': val * dfeFactor};
    } else {
      amounts = {n.nutrientId: val};
    }
    out.add(
      IntakeLine(
        nutrientId: n.nutrientId,
        source: n.source,
        form: n.form,
        labelAmount: val,
        labelUnit: n.unit,
        amounts: amounts,
        ulAmounts: ulVal == null ? null : {n.nutrientId: ulVal},
      ),
    );
  }
  return List.unmodifiable(out);
}
