import 'dart:io';
import 'package:drift/native.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

class DatabaseConnection {
  static Future<NativeDatabase> createConnection() async {
    final appDir = await getApplicationDocumentsDirectory();
    final file = File(path.join(appDir.path, 'wholewell.db'));
    return NativeDatabase(file);
  }
}
