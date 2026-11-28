/// Mở một kết nối SQLite3MultipleCiphers đúng thứ tự (đặc tả encrypted-db, mục Mã hóa).
library;

import 'dart:io';
import 'dart:typed_data';

import 'package:meta/meta.dart';
import 'package:sqlite3/sqlite3.dart';

import 'key_store.dart';

/// Cipher chốt trong mã, không dùng mặc định của thư viện.
const dbCipher = 'chacha20';

/// drift không ghi câu SQL ra log (bản phát hành và mọi bản).
const dbLogStatements = false;

/// Câu kiểm bản SQLite có SQLite3MultipleCiphers và cipher đang dùng.
const cipherProbeSql = "SELECT sqlite3mc_config('cipher') AS c";

const _sqliteHeader = 'SQLite format 3\u0000';

/// Giai đoạn mở CSDL bị lỗi. Không chứa câu lệnh, thông báo gốc hay khóa.
enum DbOpenStage {
  /// Lỗi khi nạp khóa (`PRAGMA key`).
  key,

  /// Bản SQLite không có SQLite3MultipleCiphers, hoặc cipher khác [dbCipher].
  cipher,

  /// Khóa sai hoặc tệp hỏng.
  wrongKeyOrCorrupt,

  /// Tệp vừa tạo không được mã hóa (đầu tệp là SQLite thường hoặc quá ngắn).
  notEncrypted,
}

class DbOpenException implements Exception {
  final DbOpenStage stage;
  const DbOpenException(this.stage);
  @override
  String toString() => 'DbOpenException(stage: ${stage.name})';
}

String _hex(Uint8List key) {
  if (key.length != dbKeyLength) throw const DbOpenException(DbOpenStage.key);
  final b = StringBuffer();
  for (final x in key) {
    b.write(x.toRadixString(16).padLeft(2, '0'));
  }
  return b.toString();
}

/// Ghi đè để test: thay cách chạy `PRAGMA key` (giả lập lỗi).
@visibleForTesting
void Function(Database db, String sql)? debugKeyExecutor;

/// Ghi đè để test: thay câu kiểm cipher (giả lập bản SQLite thường).
@visibleForTesting
String? debugCipherProbeSql;

/// Đặt cipher, tham số rồi khóa; thư viện yêu cầu cipher và tham số trước khóa.
///
/// Mọi lỗi quanh `PRAGMA key` được ném lại thành [DbOpenException] không chứa câu
/// lệnh: `SqliteException` chứa câu SQL gây lỗi, tức chứa khóa.
void applyKey(Database db, Uint8List key) {
  try {
    db.execute("PRAGMA cipher = '$dbCipher'");
    db.execute('PRAGMA legacy = 0');
  } on Object {
    throw const DbOpenException(DbOpenStage.cipher);
  }
  try {
    final sql = 'PRAGMA key = "raw:${_hex(key)}"';
    (debugKeyExecutor ?? (d, s) => d.execute(s))(db, sql);
  } on Object {
    throw const DbOpenException(DbOpenStage.key);
  }
}

/// Bản SQLite có SQLite3MultipleCiphers không. Kiểm trên một kết nối trong bộ nhớ:
/// từ SQLite 3.48 mọi câu SELECT trên kết nối thật đều đọc tệp, nên khóa sai sẽ
/// bị nhầm thành thiếu thư viện.
void _verifyBuild() {
  final mem = sqlite3.openInMemory();
  try {
    final rows = mem.select(debugCipherProbeSql ?? cipherProbeSql);
    if (rows.isEmpty || rows.first.values.first == null) {
      throw const DbOpenException(DbOpenStage.cipher);
    }
  } on DbOpenException {
    rethrow;
  } on Object {
    throw const DbOpenException(DbOpenStage.cipher);
  } finally {
    mem.close();
  }
}

/// Kiểm bản mã hóa và khóa; gọi sau [applyKey], trước mọi lần ghi.
void verifyEncryption(Database db) {
  _verifyBuild();
  try {
    // PRAGMA key luôn trả "ok" kể cả khi sai khóa; đọc sqlite_master mới biết.
    db.select('SELECT count(*) FROM sqlite_master');
  } on Object {
    throw const DbOpenException(DbOpenStage.wrongKeyOrCorrupt);
  }
  try {
    final rows = db.select(debugCipherProbeSql ?? cipherProbeSql);
    if (rows.isEmpty || rows.first.values.first != dbCipher) {
      throw const DbOpenException(DbOpenStage.cipher);
    }
  } on DbOpenException {
    rethrow;
  } on Object {
    throw const DbOpenException(DbOpenStage.cipher);
  }
}

/// Các pragma của kết nối sau khi đã kiểm mã hóa.
void applyConnectionPragmas(Database db) {
  db.execute('PRAGMA journal_mode = WAL');
  db.execute('PRAGMA foreign_keys = ON');
  // Sắp xếp, chỉ mục tạm không ghi tệp tạm ra đĩa.
  db.execute('PRAGMA temp_store = MEMORY');
}

/// Toàn bộ thứ tự mở cho một kết nối: cipher → khóa → kiểm → pragma.
void setUpConnection(Database db, Uint8List key) {
  applyKey(db, key);
  verifyEncryption(db);
  applyConnectionPragmas(db);
}

/// Sau khi tạo: đẩy dữ liệu ra tệp chính rồi kiểm tệp dài ít nhất một trang và
/// đầu tệp không phải SQLite thường.
void verifyFileEncrypted(Database db, File file) {
  db.execute('PRAGMA wal_checkpoint(TRUNCATE)');
  final pageSize = db.select('PRAGMA page_size').first.values.first! as int;
  final len = file.lengthSync();
  if (len < pageSize) throw const DbOpenException(DbOpenStage.notEncrypted);
  if (looksLikePlainSqlite(file)) throw const DbOpenException(DbOpenStage.notEncrypted);
}

/// 16 byte đầu là `SQLite format 3\0`.
bool looksLikePlainSqlite(File file) {
  final raf = file.openSync();
  try {
    final head = raf.readSync(16);
    return head.length == 16 && String.fromCharCodes(head) == _sqliteHeader;
  } finally {
    raf.closeSync();
  }
}

/// Giải mã nguyên tệp SQLite3MultipleCiphers tạm thành SQLite thuần để đóng gói sao lưu.
void decryptFileInPlace(File file, Uint8List key) {
  final db = sqlite3.open(file.path, mode: OpenMode.readWrite);
  try {
    setUpConnection(db, key);
    db.execute("PRAGMA rekey = ''");
    db.execute('PRAGMA wal_checkpoint(TRUNCATE)');
  } finally {
    db.close();
  }
}

/// Kiểm toàn vẹn tệp SQLite thuần sau giải mã sao lưu và trả về `schema_version`.
int verifyPlainBackupFile(File file) {
  final db = sqlite3.open(file.path, mode: OpenMode.readOnly);
  try {
    final ic = db.select('PRAGMA integrity_check').first.values.first;
    if (ic != 'ok') {
      throw const DbOpenException(DbOpenStage.wrongKeyOrCorrupt);
    }
    final rows = db.select('SELECT schema_version FROM meta WHERE id = 1');
    if (rows.isEmpty) {
      throw const DbOpenException(DbOpenStage.wrongKeyOrCorrupt);
    }
    db.select('SELECT count(*) FROM consents');
    return rows.first.values.first! as int;
  } finally {
    db.close();
  }
}

/// Mã hóa tệp SQLite thuần tại chỗ bằng khóa Keystore và kiểm lại bản mã hóa.
void encryptPlainFileInPlace(File file, Uint8List key) {
  final db = sqlite3.open(file.path, mode: OpenMode.readWrite);
  try {
    db.execute("PRAGMA cipher = '$dbCipher'");
    db.execute('PRAGMA legacy = 0');
    final sql = 'PRAGMA rekey = "raw:${_hex(key)}"';
    (debugKeyExecutor ?? (d, s) => d.execute(s))(db, sql);
    db.execute('PRAGMA wal_checkpoint(TRUNCATE)');
  } on DbOpenException {
    rethrow;
  } on Object {
    throw const DbOpenException(DbOpenStage.key);
  } finally {
    db.close();
  }
  final checkDb = sqlite3.open(file.path, mode: OpenMode.readWrite);
  try {
    setUpConnection(checkDb, key);
    verifyFileEncrypted(checkDb, file);
  } finally {
    checkDb.close();
  }
}
