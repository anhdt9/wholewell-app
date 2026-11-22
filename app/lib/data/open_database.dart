import 'dart:io';
import 'dart:isolate';
import 'dart:math';

import 'package:drift/native.dart';
import 'package:sqlite3/sqlite3.dart';

import '../platform/secure_key_store.dart';
import 'database.dart';

/// Tên khóa CSDL trong [SecureKeyStore].
const dbKeyName = 'wholewell.db.key.v1';

/// Tên tệp CSDL trong thư mục dữ liệu riêng của app.
const dbFileName = 'wholewell.db';

enum DatabaseOpenFailure {
  /// Bản SQLite không có mã hóa (`PRAGMA cipher` rỗng).
  cipherUnavailable,

  /// Kho khóa của hệ điều hành ném lỗi.
  keyStoreUnavailable,

  /// Có tệp CSDL nhưng không còn khóa.
  keyMissing,

  /// Khóa không mở được tệp, hoặc tệp hỏng.
  wrongKeyOrCorrupt,
}

class DatabaseOpenError implements Exception {
  final DatabaseOpenFailure reason;
  const DatabaseOpenError(this.reason);
  @override
  String toString() => 'DatabaseOpenError($reason)';
}

final _hex64 = RegExp(r'^[0-9a-f]{64}$');

/// 32 byte ngẫu nhiên an toàn, dạng hex (64 ký tự).
String generateDbKey([Random? random]) {
  final r = random ?? Random.secure();
  return [for (var i = 0; i < 32; i++) r.nextInt(256).toRadixString(16).padLeft(2, '0')].join();
}

/// Mở (hoặc tạo) CSDL mã hóa ở [file]. Không bao giờ tự xóa dữ liệu.
///
/// Ném [DatabaseOpenError] khi không mở được; giao diện quyết định làm gì tiếp.
Future<AppDatabase> openAppDatabase({
  required File file,
  required SecureKeyStore keys,
  Random? random,
}) async {
  String? key;
  try {
    key = await keys.read(dbKeyName);
  } catch (_) {
    throw const DatabaseOpenError(DatabaseOpenFailure.keyStoreUnavailable);
  }

  if (key == null) {
    if (file.existsSync() && file.lengthSync() > 0) {
      throw const DatabaseOpenError(DatabaseOpenFailure.keyMissing);
    }
    key = generateDbKey(random);
    try {
      await keys.write(dbKeyName, key);
    } catch (_) {
      throw const DatabaseOpenError(DatabaseOpenFailure.keyStoreUnavailable);
    }
  }
  if (!_hex64.hasMatch(key)) {
    throw const DatabaseOpenError(DatabaseOpenFailure.wrongKeyOrCorrupt);
  }

  final path = file.path;
  final k = key;
  final failure = await Isolate.run(() => preflightDatabase(path, k));
  if (failure != null) throw DatabaseOpenError(failure);

  return AppDatabase(NativeDatabase.createInBackground(
    file,
    setup: (db) => applyKey(db, k),
  ));
}

/// Kiểm trước khi giao cho drift: có mã hóa, khóa mở được tệp. Trả null khi ổn.
DatabaseOpenFailure? preflightDatabase(String path, String hexKey) {
  final db = sqlite3.open(path);
  try {
    if (!hasCipher(db)) return DatabaseOpenFailure.cipherUnavailable;
    applyKey(db, hexKey);
    db.select('SELECT count(*) FROM sqlite_master');
    return null;
  } on SqliteException {
    return DatabaseOpenFailure.wrongKeyOrCorrupt;
  } finally {
    db.close();
  }
}

/// SQLite3MultipleCiphers trả tên thuật toán; SQLite gốc bỏ qua pragma lạ và trả rỗng.
bool hasCipher(Database db) {
  final rows = db.select('PRAGMA cipher;');
  return rows.isNotEmpty && (rows.first.values.first?.toString() ?? '').isNotEmpty;
}

/// Đặt khóa cho một kết nối. Ném [StateError] nếu bản SQLite không có mã hóa,
/// kể cả ở bản phát hành (không chỉ `assert`).
void applyKey(Database db, String hexKey) {
  if (!_hex64.hasMatch(hexKey)) throw ArgumentError('khóa không hợp lệ');
  if (!hasCipher(db)) throw StateError('SQLite không có mã hóa');
  db.execute("PRAGMA hexkey = '$hexKey';");
  db.execute('PRAGMA foreign_keys = ON;');
}
