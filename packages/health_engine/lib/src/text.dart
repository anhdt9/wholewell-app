/// Chuẩn hóa chuỗi tiếng Việt (có dấu → không dấu, chữ thường) phục vụ tìm kiếm.
library;

const _vietMap = <String, String>{
  'à': 'a', 'á': 'a', 'ả': 'a', 'ã': 'a', 'ạ': 'a',
  'ă': 'a', 'ằ': 'a', 'ắ': 'a', 'ẳ': 'a', 'ẵ': 'a', 'ặ': 'a',
  'â': 'a', 'ầ': 'a', 'ấ': 'a', 'ẩ': 'a', 'ẫ': 'a', 'ậ': 'a',
  'đ': 'd',
  'è': 'e', 'é': 'e', 'ẻ': 'e', 'ẽ': 'e', 'ẹ': 'e',
  'ê': 'e', 'ề': 'e', 'ế': 'e', 'ể': 'e', 'ễ': 'e', 'ệ': 'e',
  'ì': 'i', 'í': 'i', 'ỉ': 'i', 'ĩ': 'i', 'ị': 'i',
  'ò': 'o', 'ó': 'o', 'ỏ': 'o', 'õ': 'o', 'ọ': 'o',
  'ô': 'o', 'ồ': 'o', 'ố': 'o', 'ổ': 'o', 'ỗ': 'o', 'ộ': 'o',
  'ơ': 'o', 'ờ': 'o', 'ớ': 'o', 'ở': 'o', 'ỡ': 'o', 'ợ': 'o',
  'ù': 'u', 'ú': 'u', 'ủ': 'u', 'ũ': 'u', 'ụ': 'u',
  'ư': 'u', 'ừ': 'u', 'ứ': 'u', 'ử': 'u', 'ữ': 'u', 'ự': 'u',
  'ỳ': 'y', 'ý': 'y', 'ỷ': 'y', 'ỹ': 'y', 'ỵ': 'y',
};

/// Bỏ dấu tiếng Việt, đổi `đ`/`Đ` thành `d`, chuyển chữ thường và gom khoảng trắng.
String normalizeSearchAscii(String input) {
  final lower = input.toLowerCase();
  final sb = StringBuffer();
  var prevSpace = true;
  for (final rune in lower.runes) {
    // Bỏ dấu kết hợp Unicode NFD nếu có.
    if (rune >= 0x0300 && rune <= 0x036F) continue;
    final ch = String.fromCharCode(rune);
    final mapped = _vietMap[ch] ?? ch;
    final isAlnum = (mapped.codeUnitAt(0) >= 0x61 && mapped.codeUnitAt(0) <= 0x7A) ||
        (mapped.codeUnitAt(0) >= 0x30 && mapped.codeUnitAt(0) <= 0x39);
    if (isAlnum) {
      sb.write(mapped);
      prevSpace = false;
    } else if (!prevSpace) {
      sb.write(' ');
      prevSpace = true;
    }
  }
  return sb.toString().trim();
}
