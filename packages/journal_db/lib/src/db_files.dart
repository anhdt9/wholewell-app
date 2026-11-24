/// Các tệp của CSDL trong thư mục dữ liệu riêng của app.
library;

import 'dart:io';

import 'package:path/path.dart' as p;

class DbFiles {
  /// Thư mục dữ liệu riêng của app (Android: filesDir; iOS: Application Support).
  final Directory dir;
  const DbFiles(this.dir);

  static const dbName = 'wholewell.db';

  File get db => File(p.join(dir.path, dbName));
  File get wal => File('${db.path}-wal');
  File get shm => File('${db.path}-shm');

  /// Tệp đang tạo ở bước Đồng ý; chỉ đổi tên thành [db] khi đã ghi xong đồng ý.
  File get creating => File(p.join(dir.path, '$dbName.creating'));

  /// Bản sao nguyên byte trước khi di chuyển từ phiên bản [fromVersion].
  File preMigrationCopy(int fromVersion) => File('${db.path}.pre-v$fromVersion');

  /// Dấu "đang xóa" (ngoài CSDL, không chứa dữ liệu sức khỏe).
  File get wipeMarker => File(p.join(dir.path, 'wholewell.wiping'));

  List<File> preMigrationCopies() {
    if (!dir.existsSync()) return const [];
    final prefix = '$dbName.pre-v';
    return [
      for (final e in dir.listSync())
        if (e is File && p.basename(e.path).startsWith(prefix)) e,
    ];
  }

  /// Mọi tệp thuộc CSDL (kể cả `-wal`, `-shm`, bản sao, tệp đang tạo).
  List<File> allDataFiles() => [
        db,
        wal,
        shm,
        creating,
        File('${creating.path}-wal'),
        File('${creating.path}-shm'),
        ...preMigrationCopies(),
      ];

  static void deleteIfExists(File f) {
    if (f.existsSync()) f.deleteSync();
  }
}
