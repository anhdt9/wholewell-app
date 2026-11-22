import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:health_engine/health_engine.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:wholewell/data/database.dart';
import 'package:wholewell/data/drift_journal_repository.dart';
import 'package:wholewell/data/open_database.dart';
import 'package:wholewell/data/units.dart';

import 'helpers.dart';

// Tiêu chí đạt trong docs/specs/encrypted-db.md.
void main() {
  late TempDb t;
  setUp(() => t = TempDb());
  tearDown(() => t.dispose());

  final day = DateTime(2026, 3, 10);
  const label = 'Pho bo thu nghiem 7f3a';

  Future<void> writeSample() async {
    final db = await t.open();
    final repo = DriftJournalRepository(db, testPack);
    await repo.addItem(day, const IntakeItem(
      label: label,
      source: IntakeSource.food,
      nutrients: {'vitD': 2.5, 'energyKcal': 450},
    ));
    await db.close();
  }

  test('bản SQLite dùng trong test có mã hóa (PRAGMA cipher khác rỗng)', () {
    final db = sqlite3.openInMemory();
    addTearDown(db.close);
    expect(hasCipher(db), isTrue, reason: 'hook sqlite3mc chưa có hiệu lực');
  });

  test('tệp CSDL không phải SQLite thường và không lộ nội dung', () async {
    await writeSample();
    final bytes = t.file.readAsBytesSync();
    expect(bytes.length, greaterThan(16));
    expect(ascii.decode(bytes.sublist(0, 15), allowInvalid: true), isNot('SQLite format 3'));
    final raw = latin1.decode(bytes);
    expect(raw.contains(label), isFalse);
    expect(raw.contains('intake_entries'), isFalse);
    expect(raw.contains('CREATE TABLE'), isFalse);
  });

  test('khóa sinh một lần, 64 ký tự hex, lần mở sau dùng lại', () async {
    await (await t.open()).close();
    final k1 = t.keys.values[dbKeyName];
    expect(k1, matches(RegExp(r'^[0-9a-f]{64}$')));
    await writeSample();
    expect(t.keys.values[dbKeyName], k1);

    // Mở lại đọc được dữ liệu đã ghi bằng khóa đó.
    final db = await t.open();
    final items = await DriftJournalRepository(db, testPack).itemsBetween(day, day);
    expect(items.single.value.label, label);
    await db.close();
  });

  test('khóa khác → wrongKeyOrCorrupt, tệp còn nguyên', () async {
    await writeSample();
    final before = t.file.readAsBytesSync();
    t.keys.values[dbKeyName] = generateDbKey();
    await expectLater(
      t.open(),
      throwsA(isA<DatabaseOpenError>().having((e) => e.reason, 'reason', DatabaseOpenFailure.wrongKeyOrCorrupt)),
    );
    expect(t.file.readAsBytesSync(), before);
  });

  test('có tệp mà không có khóa → keyMissing, tệp còn nguyên, không sinh khóa mới', () async {
    await writeSample();
    final before = t.file.readAsBytesSync();
    t.keys.values.clear();
    await expectLater(
      t.open(),
      throwsA(isA<DatabaseOpenError>().having((e) => e.reason, 'reason', DatabaseOpenFailure.keyMissing)),
    );
    expect(t.file.readAsBytesSync(), before);
    expect(t.keys.values, isEmpty);
  });

  test('kho khóa lỗi → keyStoreUnavailable', () async {
    t.keys.failing = true;
    await expectLater(
      t.open(),
      throwsA(isA<DatabaseOpenError>().having((e) => e.reason, 'reason', DatabaseOpenFailure.keyStoreUnavailable)),
    );
  });

  test('đủ 12 bảng của lược đồ phiên bản 1, khóa ngoại bật', () async {
    final db = await t.open();
    addTearDown(db.close);
    final names = (await db.customSelect("SELECT name FROM sqlite_master WHERE type = 'table'").get())
        .map((r) => r.read<String>('name'))
        .toSet();
    expect(names, containsAll(<String>[
      'people', 'profiles', 'settings', 'products', 'product_nutrients', 'inventory_boxes',
      'regimens', 'dose_logs', 'intake_entries', 'intake_nutrients', 'workouts', 'water_logs',
    ]));
    final fk = await db.customSelect('PRAGMA foreign_keys').getSingle();
    expect(fk.data.values.first, 1);
    expect(db.schemaVersion, 1);
  });

  test('xóa món thì các dòng chất của nó cũng mất', () async {
    final db = await t.open();
    addTearDown(db.close);
    final repo = DriftJournalRepository(db, testPack);
    final id = await repo.addItem(day, const IntakeItem(
      label: 'Viên tổng hợp',
      source: IntakeSource.supplement,
      nutrients: {'vitC': 500, 'zinc': 11, 'magnesium': 100},
    ));
    Future<int> count() async =>
        (await db.customSelect('SELECT count(*) AS c FROM intake_nutrients').getSingle()).read<int>('c');
    expect(await count(), 3);
    await repo.removeItem(id);
    expect(await count(), 0);
  });

  test('lưu kèm đơn vị của gói; đơn vị trong CSDL khác gói → UnitMismatch', () async {
    final db = await t.open();
    addTearDown(db.close);
    final repo = DriftJournalRepository(db, testPack);
    await repo.addItem(day, const IntakeItem(
      label: 'Viên vitamin D',
      source: IntakeSource.supplement,
      nutrients: {'vitD': 25, 'energyKcal': 0},
    ));
    final stored = await db.customSelect("SELECT unit FROM intake_nutrients WHERE nutrient_id = 'vitD'").getSingle();
    expect(stored.read<String>('unit'), testPack.nutrients['vitD']!.unit);
    final kcal = await db.customSelect("SELECT unit FROM intake_nutrients WHERE nutrient_id = 'energyKcal'").getSingle();
    expect(kcal.read<String>('unit'), 'kcal');

    await db.customStatement("UPDATE intake_nutrients SET unit = 'mg' WHERE nutrient_id = 'vitD'");
    await expectLater(repo.itemsBetween(day, day), throwsA(isA<UnitMismatch>()));
  });

  test('khóa chất lạ → UnknownNutrient, không ghi gì', () async {
    final db = await t.open();
    addTearDown(db.close);
    final repo = DriftJournalRepository(db, testPack);
    await expectLater(
      repo.addItem(day, const IntakeItem(label: 'x', source: IntakeSource.food, nutrients: {'vitamin_z': 1})),
      throwsA(isA<UnknownNutrient>()),
    );
    final n = await db.customSelect('SELECT count(*) AS c FROM intake_entries').getSingle();
    expect(n.read<int>('c'), 0);
  });

  test('30 ngày × 20 món × 15 chất: đọc 7 ngày đủ nhanh', () async {
    final db = await t.open();
    addTearDown(db.close);
    final repo = DriftJournalRepository(db, testPack);
    final ids = testPack.nutrients.keys.take(15).toList();
    final start = DateTime(2026, 1, 1);
    await db.transaction(() async {
      for (var d = 0; d < 30; d++) {
        for (var i = 0; i < 20; i++) {
          await repo.addItem(
            DateTime(start.year, start.month, start.day + d),
            IntakeItem(label: 'Món $i', source: IntakeSource.food, nutrients: {for (final k in ids) k: i + 0.5}),
          );
        }
      }
    });
    final sw = Stopwatch()..start();
    final items = await repo.itemsBetween(DateTime(2026, 1, 24), DateTime(2026, 1, 30));
    sw.stop();
    expect(items, hasLength(7 * 20));
    expect(items.first.value.nutrients, hasLength(15));
    // ignore: avoid_print
    print('đọc 7 ngày: ${sw.elapsedMilliseconds} ms (mục tiêu dưới 200 ms trên máy phát triển)');
    expect(sw.elapsed, lessThan(const Duration(seconds: 2)));
  }, timeout: const Timeout(Duration(minutes: 2)));

  test('ngày lưu dạng YYYY-MM-DD theo giờ máy', () {
    expect(dayKey(DateTime(2026, 3, 5, 23, 59)), '2026-03-05');
    expect(parseDayKey('2026-03-05'), DateTime(2026, 3, 5));
  });
}
