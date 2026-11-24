// Tiêu chí đạt "Xóa, di chuyển" (docs/specs/encrypted-db.md).
import 'package:journal_db/journal_db.dart';
import 'package:test/test.dart';

import 'helpers.dart';

void main() {
  test('rút đồng ý, xóa toàn bộ: không còn tệp nào, không còn khóa, về Chào mừng', () async {
    final dir = tempDir();
    final keys = FakeSecureKeyStore();
    final o = testOpener(dir, keys);
    final repo = await createdRepo(o);
    await repo.saveHideCalories(true);
    // Bản sao còn sót của một lần di chuyển cũng phải bị xóa.
    DbFiles(dir).preMigrationCopy(1).writeAsStringSync('x');
    await o.wipeAll(openRepository: repo);
    expect(fileNames(dir), isEmpty);
    expect(keys.key, isNull);
    expect(await o.open(), isA<Welcome>());
  });

  test('app chết sau khi xóa khóa, trước khi xóa tệp: lần mở sau làm tiếp, về Chào mừng', () async {
    final dir = tempDir();
    final keys = FakeSecureKeyStore();
    final o = testOpener(dir, keys);
    await (await createdRepo(o)).close();
    DbFiles(dir).wipeMarker.writeAsStringSync('1');
    await keys.deleteDbKey();
    expect(await o.open(), isA<Welcome>());
    expect(fileNames(dir), isEmpty);
  });

  test('có khóa, không có tệp: xóa khóa, về Chào mừng, không tạo CSDL nào', () async {
    final dir = tempDir();
    final keys = FakeSecureKeyStore(key: generateDbKey());
    expect(await testOpener(dir, keys).open(), isA<Welcome>());
    expect(keys.key, isNull);
    expect(fileNames(dir), isEmpty);
  });

  test('app chết giữa bước Đồng ý (tệp đang tạo còn sót): về Chào mừng', () async {
    final dir = tempDir();
    final keys = FakeSecureKeyStore(key: generateDbKey());
    DbFiles(dir).creating.writeAsStringSync('dở');
    expect(await testOpener(dir, keys).open(), isA<Welcome>());
    expect(fileNames(dir), isEmpty);
    expect(keys.key, isNull);
  });

  test('[Bắt đầu lại] khi không mở được: xóa hết, tạo lại được', () async {
    final dir = tempDir();
    final keys = FakeSecureKeyStore();
    final o = testOpener(dir, keys);
    await (await createdRepo(o)).close();
    keys.key = null;
    expect(await o.open(), isA<CannotOpen>());
    await o.startOver();
    expect(fileNames(dir), isEmpty);
    expect(await o.open(), isA<Welcome>());
    await createdRepo(o);
  });

  test('di chuyển lỗi: giữ tệp và bản .pre-v1, Cần cập nhật; bản sửa lỗi di chuyển lại được', () async {
    final dir = tempDir();
    final keys = FakeSecureKeyStore();
    final v1 = testOpener(dir, keys);
    final repo = await createdRepo(v1);
    await repo.saveHideCalories(true);
    await repo.close();

    final broken = testOpener(dir, keys, schemaVersion: 2, migrations: {
      1: (db) {
        db.execute('CREATE TABLE extra (x)');
        throw StateError('lỗi giả của bản app');
      },
    });
    expect(await broken.open(), isA<NeedsUpdate>());
    expect(DbFiles(dir).db.existsSync(), isTrue);
    expect(DbFiles(dir).preMigrationCopy(1).existsSync(), isTrue);
    expect(await broken.open(), isA<NeedsUpdate>());

    final fixed = testOpener(dir, keys, schemaVersion: 2, migrations: {
      1: (db) => db.execute('CREATE TABLE extra (x)'),
    });
    final r = await reopened(fixed);
    expect(await r.loadHideCalories(), isTrue);
    final v = await r.db.customSelect('SELECT schema_version FROM meta').getSingle();
    expect(v.data['schema_version'], 2);
    await r.db.customSelect('SELECT count(*) FROM extra').get();
    expect(DbFiles(dir).preMigrationCopy(1).existsSync(), isFalse);
  });

  test('lược đồ mới hơn bản app (cài bản cũ hơn): Cần cập nhật, tệp không đổi', () async {
    final dir = tempDir();
    final keys = FakeSecureKeyStore();
    final o = testOpener(dir, keys);
    final repo = await createdRepo(o);
    await repo.db.customStatement('UPDATE meta SET schema_version = 5');
    await repo.close();
    final before = DbFiles(dir).db.readAsBytesSync();
    expect(await o.open(), isA<NeedsUpdate>());
    expect(DbFiles(dir).db.readAsBytesSync(), before);
    expect(keys.deletes, 0);
  });

  test('khung test di chuyển: mở v1 với bản app v1 không di chuyển gì', () async {
    final dir = tempDir();
    final o = testOpener(dir, FakeSecureKeyStore());
    await (await createdRepo(o)).close();
    final r = await reopened(o);
    final v = await r.db.customSelect('SELECT schema_version FROM meta').getSingle();
    expect(v.data['schema_version'], currentSchemaVersion);
    expect(DbFiles(dir).preMigrationCopies(), isEmpty);
  });
}
