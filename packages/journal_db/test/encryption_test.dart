// Tiêu chí đạt "Khóa và mã hóa" (docs/specs/encrypted-db.md).
import 'dart:io';
import 'dart:typed_data';

import 'package:journal_db/journal_db.dart';
import 'package:journal_db/src/connection.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:test/test.dart';

import 'helpers.dart';

String _hex(Uint8List k) => [for (final b in k) b.toRadixString(16).padLeft(2, '0')].join();

void main() {
  tearDown(() {
    debugCipherProbeSql = null;
    debugKeyExecutor = null;
  });

  test('trước khi đồng ý: không có tệp CSDL, chưa có khóa', () async {
    final dir = tempDir();
    final keys = FakeSecureKeyStore();
    final o = testOpener(dir, keys);
    expect(await o.open(), isA<Welcome>());
    expect(await o.open(), isA<Welcome>());
    expect(fileNames(dir), isEmpty);
    expect(keys.key, isNull);
    expect(keys.creates, 0);
  });

  test('tệp được mã hóa: đầu tệp không phải SQLite thường, không đọc được khi thiếu khóa', () async {
    final dir = tempDir();
    final o = testOpener(dir, FakeSecureKeyStore());
    final repo = await createdRepo(o);
    await repo.close();
    final f = DbFiles(dir).db;
    expect(looksLikePlainSqlite(f), isFalse);
    expect(f.lengthSync(), greaterThanOrEqualTo(4096));
    final plain = sqlite3.open(f.path, mode: OpenMode.readOnly);
    addTearDown(plain.close);
    expect(() => plain.select('SELECT count(*) FROM sqlite_master'), throwsA(isA<SqliteException>()));
  });

  test('kiểm đầu tệp sau checkpoint bắt được tệp SQLite thường', () {
    final dir = tempDir();
    final f = File('${dir.path}/plain.db');
    final db = sqlite3.open(f.path);
    addTearDown(db.close);
    db.execute('PRAGMA journal_mode = WAL');
    db.execute('CREATE TABLE t (x)');
    expect(
      () => verifyFileEncrypted(db, f),
      throwsA(isA<DbOpenException>().having((e) => e.stage, 'stage', DbOpenStage.notEncrypted)),
    );
  });

  test('bản SQLite không có SQLite3MultipleCiphers: từ chối, không để lại tệp hay khóa', () async {
    final dir = tempDir();
    final keys = FakeSecureKeyStore();
    debugCipherProbeSql = "SELECT no_such_function('cipher')";
    expect(await testOpener(dir, keys).createNew(testConsent), isA<InstallBroken>());
    expect(fileNames(dir), isEmpty);
    expect(keys.key, isNull);
  });

  test('cipher khác chacha20: từ chối mở, tệp không đổi', () async {
    final dir = tempDir();
    final keys = FakeSecureKeyStore();
    final o = testOpener(dir, keys);
    await (await createdRepo(o)).close();
    final before = DbFiles(dir).db.readAsBytesSync();
    debugCipherProbeSql = "SELECT 'aes256cbc'";
    expect(await o.open(), isA<InstallBroken>());
    expect(DbFiles(dir).db.readAsBytesSync(), before);
  });

  test('khóa sai: lỗi, không tạo dữ liệu mới, không ghi đè tệp', () async {
    final dir = tempDir();
    final keys = FakeSecureKeyStore();
    final o = testOpener(dir, keys);
    await (await createdRepo(o)).close();
    final before = DbFiles(dir).db.readAsBytesSync();
    keys.key = generateDbKey();
    expect(await o.open(), isA<CannotOpen>());
    expect(DbFiles(dir).db.readAsBytesSync(), before);
    expect(keys.creates, 1);
  });

  test('máy đang khóa: chờ, không tạo, không xóa; mở khóa thì mở bình thường', () async {
    final dir = tempDir();
    final keys = FakeSecureKeyStore();
    final o = testOpener(dir, keys);
    final repo = await createdRepo(o);
    await repo.saveHideCalories(true);
    await repo.close();
    keys
      ..unavailableReads = -1
      ..unlocked = false;
    expect(await o.open(), isA<WaitingForUnlock>());
    expect(keys.creates, 1);
    expect(keys.deletes, 0);
    expect(DbFiles(dir).db.existsSync(), isTrue);
    keys
      ..unavailableReads = 0
      ..unlocked = true;
    final again = await reopened(o);
    expect(await again.loadHideCalories(), isTrue);
  });

  test('lỗi khóa kéo dài khi máy đã mở khóa: sau 3 lần thử hiện Thử lại, không Bắt đầu lại', () async {
    final dir = tempDir();
    final keys = FakeSecureKeyStore();
    final o = testOpener(dir, keys);
    await (await createdRepo(o)).close();
    keys.unavailableReads = -1;
    final readsBefore = keys.reads;
    expect(await o.open(), isA<KeyStuck>());
    expect(keys.reads - readsBefore, 3);
    expect(keys.deletes, 0);
    expect(DbFiles(dir).db.existsSync(), isTrue);
  });

  test('mất khóa vĩnh viễn khi có tệp: không mở được, không tự tạo khóa mới', () async {
    final dir = tempDir();
    final keys = FakeSecureKeyStore();
    final o = testOpener(dir, keys);
    await (await createdRepo(o)).close();
    keys.lost = true;
    expect(await o.open(), isA<CannotOpen>());
    expect(keys.creates, 1);
    expect(DbFiles(dir).db.existsSync(), isTrue);
  });

  test('createDbKey khi đã có khóa thì lỗi, khóa cũ giữ nguyên', () async {
    final keys = FakeSecureKeyStore();
    final k = await keys.createDbKey();
    await expectLater(keys.createDbKey(), throwsA(isA<KeyAlreadyExistsException>()));
    expect(keys.key, k);
  });

  test('lỗi khi nạp khóa không làm lộ khóa hay câu lệnh', () {
    final db = sqlite3.openInMemory();
    addTearDown(db.close);
    final key = generateDbKey();
    debugKeyExecutor = (d, sql) => throw SqliteException(
      extendedResultCode: 1,
      message: 'lỗi giả',
      causingStatement: sql,
      parametersToStatement: [sql],
    );
    Object? caught;
    try {
      applyKey(db, key);
    } on Object catch (e) {
      caught = e;
    }
    expect(caught, isA<DbOpenException>());
    final text = caught.toString();
    expect(text.contains(_hex(key)), isFalse);
    expect(text.toUpperCase().contains('PRAGMA'), isFalse);
    expect((caught as DbOpenException).stage, DbOpenStage.key);
  });

  test('pragma sau khi mở: WAL, khóa ngoại bật, bảng tạm trong bộ nhớ', () async {
    final repo = await createdRepo(testOpener(tempDir(), FakeSecureKeyStore()));
    Future<Object?> pragma(String p) async => (await repo.db.customSelect('PRAGMA $p').getSingle()).data.values.first;
    expect(await pragma('journal_mode'), 'wal');
    expect(await pragma('foreign_keys'), 1);
    expect(await pragma('temp_store'), 2);
  });

  test('drift không ghi câu SQL ra log', () {
    expect(dbLogStatements, isFalse);
  });
}
