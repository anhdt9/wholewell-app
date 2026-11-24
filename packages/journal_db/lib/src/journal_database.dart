/// Kết nối drift tới CSDL đã mở và kiểm.
///
/// Lược đồ do [DbOpener] tạo và di chuyển (kèm bản sao trước khi di chuyển), nên
/// drift chạy với `enableMigrations: false` và không có bảng sinh mã: truy vấn viết
/// bằng SQL ([customSelect], [customStatement]).
library;

import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';

import 'connection.dart';
import 'schema.dart';

class JournalDatabase extends GeneratedDatabase {
  JournalDatabase(super.executor);

  @override
  Iterable<TableInfo<Table, Object?>> get allTables => const [];

  @override
  int get schemaVersion => currentSchemaVersion;
}

/// Cách tạo executor drift cho tệp đã kiểm. Mặc định chạy ở isolate nền.
typedef ExecutorFactory = QueryExecutor Function(File file, Uint8List key);

QueryExecutor backgroundExecutor(File file, Uint8List key) {
  final k = Uint8List.fromList(key);
  return NativeDatabase.createInBackground(
    file,
    logStatements: dbLogStatements,
    enableMigrations: false,
    setup: (db) => setUpConnection(db, k),
  );
}

/// Cùng isolate (dùng trong test).
QueryExecutor sameIsolateExecutor(File file, Uint8List key) {
  final k = Uint8List.fromList(key);
  return NativeDatabase(
    file,
    logStatements: dbLogStatements,
    enableMigrations: false,
    setup: (db) => setUpConnection(db, k),
  );
}
