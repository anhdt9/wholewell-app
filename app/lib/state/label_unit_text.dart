/// Đọc chữ đơn vị trên nhãn (JSON của AI trên máy, NIH DSLD) theo một danh sách cố định.
///
/// Không đoán: chữ không có trong danh sách trả `null`, người dùng chọn đơn vị theo nhãn
/// (đặc tả `label-scan-inventory`, Bổ sung 1, mục B1.5).
library;

import 'package:health_engine/health_engine.dart';

abstract final class LabelUnitText {
  static const _known = <String, LabelUnit>{
    'mg': LabelUnit.mg,
    'milligram': LabelUnit.mg,
    'milligrams': LabelUnit.mg,
    'ug': LabelUnit.ug,
    'mcg': LabelUnit.ug,
    'µg': LabelUnit.ug, // U+00B5 (ký tự micro)
    'μg': LabelUnit.ug, // U+03BC (chữ mu Hy Lạp)
    'microgram': LabelUnit.ug,
    'micrograms': LabelUnit.ug,
    'g': LabelUnit.g,
    'gram': LabelUnit.g,
    'grams': LabelUnit.g,
    'gram(s)': LabelUnit.g,
    'iu': LabelUnit.iu,
    'international unit': LabelUnit.iu,
    'international units': LabelUnit.iu,
    'ug dfe': LabelUnit.ugDfe,
    'mcg dfe': LabelUnit.ugDfe,
    'µg dfe': LabelUnit.ugDfe,
    'μg dfe': LabelUnit.ugDfe,
    'ug rae': LabelUnit.ugRae,
    'mcg rae': LabelUnit.ugRae,
    'µg rae': LabelUnit.ugRae,
    'μg rae': LabelUnit.ugRae,
    'mg ne': LabelUnit.mgNe,
  };

  /// Trả `null` khi chữ trống hoặc không có trong danh sách.
  static LabelUnit? parse(String? raw) {
    if (raw == null) return null;
    final key = raw.toLowerCase().replaceAll(RegExp(r'^[\s_]+|[\s_]+$'), '').replaceAll(RegExp(r'[\s_]+'), ' ');
    if (key.isEmpty) return null;
    return _known[key];
  }
}
