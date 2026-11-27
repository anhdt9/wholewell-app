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

  test('di chuyển lỗi: giữ tệp và bản .pre-v2, Cần cập nhật; bản sửa lỗi di chuyển lại được', () async {
    final dir = tempDir();
    final keys = FakeSecureKeyStore();
    final vCur = testOpener(dir, keys);
    final repo = await createdRepo(vCur);
    await repo.saveHideCalories(true);
    await repo.close();

    final nextVer = currentSchemaVersion + 1;
    final broken = testOpener(dir, keys, schemaVersion: nextVer, migrations: {
      currentSchemaVersion: (db) {
        db.execute('CREATE TABLE extra (x)');
        throw StateError('lỗi giả của bản app');
      },
    });
    expect(await broken.open(), isA<NeedsUpdate>());
    expect(DbFiles(dir).db.existsSync(), isTrue);
    expect(DbFiles(dir).preMigrationCopy(currentSchemaVersion).existsSync(), isTrue);
    expect(await broken.open(), isA<NeedsUpdate>());

    final fixed = testOpener(dir, keys, schemaVersion: nextVer, migrations: {
      currentSchemaVersion: (db) => db.execute('CREATE TABLE extra (x)'),
    });
    final r = await reopened(fixed);
    expect(await r.loadHideCalories(), isTrue);
    final v = await r.db.customSelect('SELECT schema_version FROM meta').getSingle();
    expect(v.data['schema_version'], nextVer);
    await r.db.customSelect('SELECT count(*) FROM extra').get();
    expect(DbFiles(dir).preMigrationCopy(currentSchemaVersion).existsSync(), isFalse);
  });

  test('di chuyển v1 -> v3 thêm barcode cho products và cài đặt bữa/thông báo cho settings', () async {
    final dir = tempDir();
    final keys = FakeSecureKeyStore();
    final o = testOpener(dir, keys);
    final repo = await createdRepo(o);
    // Giả lập tệp CSDL đang ở v1 chưa có cột của v2 & v3.
    await repo.db.customStatement('DROP INDEX IF EXISTS idx_products_barcode');
    await repo.db.customStatement('ALTER TABLE products DROP COLUMN barcode');
    await repo.db.customStatement('ALTER TABLE settings DROP COLUMN has_breakfast');
    await repo.db.customStatement('ALTER TABLE settings DROP COLUMN has_lunch');
    await repo.db.customStatement('ALTER TABLE settings DROP COLUMN has_dinner');
    await repo.db.customStatement('ALTER TABLE settings DROP COLUMN reminder_show_details');
    await repo.db.customStatement('UPDATE meta SET schema_version = 1');
    await repo.close();

    final migrated = await reopened(o);
    final v = await migrated.db.customSelect('SELECT schema_version FROM meta').getSingle();
    expect(v.data['schema_version'], currentSchemaVersion);
    final pid = await migrated.addProduct('Canxi D3', CountUnit.tablet, 1, barcode: '8935001');
    final found = await migrated.productByBarcode('8935001');
    expect(found?.id, pid);
    expect(found?.barcode, '8935001');
    final s = await migrated.loadDayTimesSettings();
    expect(s.hasBreakfast, isTrue);
    expect(s.hasLunch, isTrue);
    expect(s.hasDinner, isTrue);
    expect(s.reminderShowDetails, isFalse);
  });

  test('di chuyển v2 -> v3 thêm cột bật/tắt bữa và hiển thị tên thông báo cho settings', () async {
    final dir = tempDir();
    final keys = FakeSecureKeyStore();
    final o = testOpener(dir, keys);
    final repo = await createdRepo(o);
    await repo.db.customStatement('ALTER TABLE settings DROP COLUMN has_breakfast');
    await repo.db.customStatement('ALTER TABLE settings DROP COLUMN has_lunch');
    await repo.db.customStatement('ALTER TABLE settings DROP COLUMN has_dinner');
    await repo.db.customStatement('ALTER TABLE settings DROP COLUMN reminder_show_details');
    await repo.db.customStatement('UPDATE meta SET schema_version = 2');
    await repo.close();

    final migrated = await reopened(o);
    final v = await migrated.db.customSelect('SELECT schema_version FROM meta').getSingle();
    expect(v.data['schema_version'], currentSchemaVersion);
    final s = await migrated.loadDayTimesSettings();
    expect(s.hasBreakfast, isTrue);
    expect(s.hasLunch, isTrue);
    expect(s.hasDinner, isTrue);
    expect(s.reminderShowDetails, isFalse);
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

  test('xóa khóa lỗi: vẫn xóa tệp, giữ dấu, về Chào mừng; lần sau xóa lại khóa', () async {
    final dir = tempDir();
    final keys = FakeSecureKeyStore();
    final o = testOpener(dir, keys);
    final repo = await createdRepo(o);
    keys.failingDeletes = 1;
    await o.wipeAll(openRepository: repo);
    expect(fileNames(dir), ['wholewell.wiping']);
    expect(keys.key, isNotNull);
    expect(await o.open(), isA<Welcome>());
    expect(keys.key, isNull);
    expect(fileNames(dir), isEmpty);
  });

  test('xóa khóa vẫn lỗi khi bấm Đồng ý: không ghi gì, báo lỗi khóa', () async {
    final dir = tempDir();
    final keys = FakeSecureKeyStore();
    final o = testOpener(dir, keys);
    await o.wipeAll(openRepository: await createdRepo(o));
    keys
      ..key = generateDbKey()
      ..failingDeletes = 1;
    DbFiles(dir).wipeMarker.writeAsStringSync('1');
    expect(await o.createNew(testConsent), isA<KeyStuck>());
    expect(DbFiles(dir).db.existsSync(), isFalse);
    final r = await o.createNew(testConsent);
    expect(r, isA<Opened>());
    expect(DbFiles(dir).wipeMarker.existsSync(), isFalse);
    await (r as Opened).repository.close();
  });

  test('Đồng ý khi lần xóa trước còn dở (còn tệp CSDL và dấu): xóa nốt rồi tạo mới', () async {
    final dir = tempDir();
    final keys = FakeSecureKeyStore();
    final o = testOpener(dir, keys);
    await (await createdRepo(o)).close();
    DbFiles(dir).wipeMarker.writeAsStringSync('1');
    final r = await o.createNew(testConsent);
    expect(r, isA<Opened>());
    expect(DbFiles(dir).wipeMarker.existsSync(), isFalse);
    await (r as Opened).repository.close();
  });

  test('createNew khi đã có CSDL: báo lỗi riêng, không đụng tệp', () async {
    final dir = tempDir();
    final o = testOpener(dir, FakeSecureKeyStore());
    await (await createdRepo(o)).close();
    final before = DbFiles(dir).db.readAsBytesSync();
    await expectLater(o.createNew(testConsent), throwsA(isA<DbAlreadyExistsException>()));
    expect(DbFiles(dir).db.readAsBytesSync(), before);
  });
}
