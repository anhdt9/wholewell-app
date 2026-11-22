import 'dart:io';

import 'package:drift/drift.dart';
import 'package:health_engine/health_engine.dart';
import 'package:wholewell/data/database.dart';
import 'package:wholewell/data/open_database.dart';
import 'package:wholewell/platform/secure_key_store.dart';

final testPack = ReferencePack.fromJsonString(File('assets/reference_pack.json').readAsStringSync());

/// Một tệp CSDL trong thư mục tạm riêng, kèm kho khóa giả. Dữ liệu giả lập.
class TempDb {
  final Directory dir;
  final InMemorySecureKeyStore keys = InMemorySecureKeyStore();

  TempDb() : dir = Directory.systemTemp.createTempSync('wholewell_test_') {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  }

  File get file => File('${dir.path}${Platform.pathSeparator}$dbFileName');

  Future<AppDatabase> open() => openAppDatabase(file: file, keys: keys);

  void dispose() {
    if (dir.existsSync()) dir.deleteSync(recursive: true);
  }
}
