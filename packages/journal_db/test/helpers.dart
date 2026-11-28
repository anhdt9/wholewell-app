import 'dart:io';

import 'package:health_engine/health_engine.dart';
import 'package:journal_db/journal_db.dart';
import 'package:test/test.dart';

/// Giờ cố định cho test: 09:00 ngày 24/11/2026 (giờ máy).
DateTime testNow() => DateTime(2026, 11, 24, 9);

const testConsent = ConsentInput(contentVersion: 'test-1', ageYears: 35, caution: false);

const testPack = 'test-pack-1';

Directory tempDir() {
  final d = Directory.systemTemp.createTempSync('journal_db_');
  addTearDown(() {
    if (d.existsSync()) d.deleteSync(recursive: true);
  });
  return d;
}

DbOpener testOpener(
  Directory dir,
  SecureKeyStore keys, {
  int schemaVersion = currentSchemaVersion,
  Map<int, Migration>? migrations,
  DateTime Function() now = testNow,
}) => DbOpener(
  files: DbFiles(dir),
  keys: keys,
  executorFactory: sameIsolateExecutor,
  schemaVersion: schemaVersion,
  migrations: migrations,
  retryDelay: Duration.zero,
  now: now,
);

/// Tạo CSDL ở bước Đồng ý; đóng tự động khi test xong.
Future<DriftJournalRepository> createdRepo(DbOpener o) async {
  final r = await o.createNew(testConsent);
  expect(r, isA<Opened>());
  final repo = (r as Opened).repository;
  addTearDown(() async {
    try {
      await repo.close();
    } on Object {
      // Đã đóng trong test.
    }
  });
  return repo;
}

Future<DriftJournalRepository> reopened(DbOpener o) async {
  final r = await o.open();
  expect(r, isA<Opened>());
  final repo = (r as Opened).repository;
  addTearDown(() async {
    try {
      await repo.close();
    } on Object {
      // Đã đóng trong test.
    }
  });
  return repo;
}

IntakeLine line(String key, double v, {IntakeSource source = IntakeSource.food}) =>
    IntakeLine(nutrientId: key, source: source, amounts: {key: v});

FoodEntryInput food(
  String name,
  DateTime at,
  List<IntakeLine> lines, {
  Meal meal = Meal.breakfast,
  bool sugarKnown = true,
  double? basis,
  double qty = 1,
  String unit = 'bát',
}) => FoodEntryInput(
  at: at,
  meal: meal,
  name: name,
  portionUnit: unit,
  portionQty: qty,
  labelBasisQty: basis,
  labelBasisUnit: basis == null ? null : unit,
  addedSugarKnown: sugarKnown,
  packVersion: testPack,
  lines: lines,
);

List<String> fileNames(Directory d) =>
    [for (final e in d.listSync()) e.uri.pathSegments.where((s) => s.isNotEmpty).last]..sort();
