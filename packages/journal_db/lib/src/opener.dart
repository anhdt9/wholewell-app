/// Mở, tạo, xóa CSDL (đặc tả encrypted-db, mục Luồng xử lý, Lỗi và biên).
///
/// Không bao giờ tự tạo khóa mới khi đã có tệp, không tự xóa dữ liệu khi chưa
/// chắc; lỗi do code (di chuyển, lỗi không lường trước) dẫn tới "Cần cập nhật",
/// không dẫn tới [Bắt đầu lại].
library;

import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:sqlite3/sqlite3.dart';

import 'connection.dart';
import 'db_files.dart';
import 'drift_repository.dart';
import 'journal_database.dart';
import 'key_store.dart';
import 'models.dart';
import 'repository.dart';
import 'schema.dart';

/// Kết quả mở CSDL; mỗi loại ứng với một màn trong thiết kế (dòng "Toàn app").
sealed class OpenOutcome {
  const OpenOutcome();
}

final class Opened extends OpenOutcome {
  final DriftJournalRepository repository;
  const Opened(this.repository);
}

/// Chưa có dữ liệu: về Chào mừng.
final class Welcome extends OpenOutcome {
  const Welcome();
}

/// "Mở khóa máy để xem dữ liệu." Đọc lại khi app trở lại hoặc máy mở khóa.
final class WaitingForUnlock extends OpenOutcome {
  const WaitingForUnlock();
}

/// "Chưa đọc được khóa dữ liệu trên máy này." + [Thử lại] [Khôi phục từ bản sao lưu].
final class KeyStuck extends OpenOutcome {
  const KeyStuck();
}

/// "Không mở được dữ liệu đã lưu trên máy." + [Khôi phục từ bản sao lưu] [Bắt đầu lại].
final class CannotOpen extends OpenOutcome {
  const CannotOpen();
}

/// Bản SQLite không mã hóa hoặc cipher sai: "… Hãy cài lại WholeWell từ cửa hàng ứng dụng."
final class InstallBroken extends OpenOutcome {
  const InstallBroken();
}

/// "Cần cập nhật WholeWell. Dữ liệu của bạn vẫn còn nguyên trên máy. …"
final class NeedsUpdate extends OpenOutcome {
  const NeedsUpdate();
}

/// "Máy không còn đủ dung lượng. Hãy giải phóng bộ nhớ rồi mở lại."
final class LowStorage extends OpenOutcome {
  const LowStorage();
}

/// `createNew` khi đã có tệp CSDL (không ở màn Chào mừng): mở theo luồng thường.
class DbAlreadyExistsException implements Exception {
  const DbAlreadyExistsException();
  @override
  String toString() => 'DbAlreadyExistsException';
}

/// Di chuyển lược đồ từ phiên bản n lên n + 1, chạy trong giao dịch.
typedef Migration = void Function(Database db);

/// Nội dung đồng ý và câu trả lời màn Điều kiện, ghi ở bước Đồng ý.
class ConsentInput {
  final String contentVersion;
  final int ageYears;

  /// Câu thứ hai (thuốc theo chỉ định, bệnh mạn tính): chỉ Có/Không.
  final bool caution;
  const ConsentInput({required this.contentVersion, required this.ageYears, required this.caution});
}

bool _isDiskFull(Object e) {
  if (e is SqliteException) return e.resultCode == 13;
  if (e is FileSystemException) {
    final c = e.osError?.errorCode;
    return c == 28 /* ENOSPC */ || c == 112 /* ERROR_DISK_FULL */;
  }
  return false;
}

class DbOpener {
  final DbFiles files;
  final SecureKeyStore keys;
  final ExecutorFactory executorFactory;

  /// Phiên bản lược đồ bản app này biết, và các bước di chuyển (từ n lên n + 1).
  final int schemaVersion;
  final Map<int, Migration> migrations;

  /// Số lần đọc khóa khi máy đã mở khóa trước khi hiện [KeyStuck].
  final int unlockedReadAttempts;
  final Duration retryDelay;

  /// Tệp ngoài CSDL cần xóa khi xóa toàn bộ (vd. cài đặt giao diện).
  final List<File> extraFilesToWipe;
  final DateTime Function() now;

  DbOpener({
    required this.files,
    required this.keys,
    this.executorFactory = backgroundExecutor,
    this.schemaVersion = currentSchemaVersion,
    this.migrations = const {},
    this.unlockedReadAttempts = 3,
    this.retryDelay = const Duration(milliseconds: 500),
    this.extraFilesToWipe = const [],
    DateTime Function()? now,
  }) : now = now ?? DateTime.now;

  /// Mở app (luồng 2). Chỉ gọi khi giao diện đã hiện; mã chạy nền không gọi.
  Future<OpenOutcome> open() async {
    try {
      return await _open();
    } on Object {
      // Lỗi không lường trước là lỗi của app: giữ nguyên dữ liệu.
      return const NeedsUpdate();
    }
  }

  Future<OpenOutcome> _open() async {
    if (files.wipeMarker.existsSync()) {
      // Xóa khóa lỗi thì dấu còn lại, lần sau thử xóa khóa lần nữa; tệp đã xóa
      // nên dữ liệu đã mất, vẫn về Chào mừng.
      await _finishWipe();
      return const Welcome();
    }
    _deleteCreatingFiles();
    final restored = _restorePreMigrationCopy();
    if (restored != null) return restored;

    final key = await _readKey();
    if (key is OpenOutcome) return key;
    final hasFile = files.db.existsSync();
    switch (key as KeyReadResult) {
      case KeyPresent(key: final k):
        if (!hasFile) {
          // Khóa còn sót (vd. app chết giữa bước Đồng ý): không tạo CSDL mới.
          await keys.deleteDbKey();
          return const Welcome();
        }
        return _openExisting(k);
      case KeyAbsent():
        return hasFile ? const CannotOpen() : const Welcome();
      case KeyLost():
        if (hasFile) return const CannotOpen();
        await keys.deleteDbKey();
        return const Welcome();
      case KeyUnavailable():
        throw StateError('không tới được');
    }
  }

  /// [KeyReadResult] hoặc [OpenOutcome] khi khóa chưa đọc được.
  Future<Object> _readKey() async {
    var r = await keys.readDbKey();
    if (r is! KeyUnavailable) return r;
    if (!await keys.isDeviceUnlocked()) return const WaitingForUnlock();
    for (var i = 1; i < unlockedReadAttempts; i++) {
      await Future<void>.delayed(retryDelay);
      r = await keys.readDbKey();
      if (r is! KeyUnavailable) return r;
    }
    return await keys.isDeviceUnlocked() ? const KeyStuck() : const WaitingForUnlock();
  }

  Future<OpenOutcome> _openExisting(Uint8List key) async {
    int version;
    Database? db;
    try {
      db = sqlite3.open(files.db.path, mode: OpenMode.readWrite);
      applyKey(db, key);
      verifyEncryption(db);
      final rows = db.select('SELECT schema_version FROM meta WHERE id = 1');
      if (rows.isEmpty) return const CannotOpen();
      version = rows.first.values.first as int;
      if (version > schemaVersion) return const NeedsUpdate();
      if (version < schemaVersion) {
        db.execute('PRAGMA journal_mode = WAL');
        db.execute('PRAGMA wal_checkpoint(TRUNCATE)');
      }
    } on DbOpenException catch (e) {
      return e.stage == DbOpenStage.cipher ? const InstallBroken() : const CannotOpen();
    } on SqliteException {
      return const CannotOpen();
    } finally {
      db?.close();
    }
    if (version < schemaVersion) {
      final o = _migrate(key, version);
      if (o != null) return o;
    }
    final jdb = JournalDatabase(executorFactory(files.db, key));
    try {
      await jdb.customSelect('SELECT 1').get();
    } on Object {
      await jdb.close();
      return const CannotOpen();
    }
    return Opened(DriftJournalRepository(jdb, now: now));
  }

  /// Sao tệp nguyên byte (giữ mã hóa) rồi di chuyển trong một giao dịch.
  OpenOutcome? _migrate(Uint8List key, int from) {
    final copy = files.preMigrationCopy(from);
    try {
      files.db.copySync(copy.path);
    } on FileSystemException catch (e) {
      DbFiles.deleteIfExists(copy);
      return _isDiskFull(e) ? const LowStorage() : const NeedsUpdate();
    }
    final db = sqlite3.open(files.db.path, mode: OpenMode.readWrite);
    try {
      setUpConnection(db, key);
      db.execute('BEGIN IMMEDIATE');
      try {
        for (var v = from; v < schemaVersion; v++) {
          final m = migrations[v];
          if (m == null) throw StateError('Thiếu bước di chuyển từ v$v');
          m(db);
        }
        db.execute('UPDATE meta SET schema_version = ? WHERE id = 1', [schemaVersion]);
        db.execute('COMMIT');
      } on Object {
        try {
          db.execute('ROLLBACK');
        } on Object {
          // Giao dịch đã tự hoàn tác.
        }
        rethrow;
      }
      final ic = db.select('PRAGMA integrity_check').first.values.first;
      if (ic != 'ok') throw StateError('integrity_check');
      db.execute('PRAGMA wal_checkpoint(TRUNCATE)');
    } on Object catch (e) {
      return _isDiskFull(e) ? const LowStorage() : const NeedsUpdate();
    } finally {
      db.close();
    }
    DbFiles.deleteIfExists(copy);
    return null;
  }

  /// Còn bản `.pre-v{n}` (lần di chuyển trước lỗi hoặc bị ngắt, chưa có lần ghi
  /// nào sau đó): bỏ tệp hiện tại cùng `-wal`, `-shm`, khôi phục bản sao.
  OpenOutcome? _restorePreMigrationCopy() {
    final copies = files.preMigrationCopies()
      ..sort((a, b) => _copyVersion(a).compareTo(_copyVersion(b)));
    if (copies.isEmpty) return null;
    try {
      for (final f in [files.db, files.wal, files.shm]) {
        DbFiles.deleteIfExists(f);
      }
      copies.first.renameSync(files.db.path);
      for (final c in copies.skip(1)) {
        DbFiles.deleteIfExists(c);
      }
    } on FileSystemException catch (e) {
      return _isDiskFull(e) ? const LowStorage() : const NeedsUpdate();
    }
    return null;
  }

  static int _copyVersion(File f) => int.tryParse(f.path.split('.pre-v').last) ?? 0;

  void _deleteCreatingFiles() {
    for (final f in [files.creating, File('${files.creating.path}-wal'), File('${files.creating.path}-shm')]) {
      DbFiles.deleteIfExists(f);
    }
  }

  /// Bước "Đồng ý và tiếp tục" (luồng 1). Gọi từ màn Chào mừng: chưa có tệp CSDL.
  ///
  /// Tạo ở tệp tạm, chỉ đổi tên thành `wholewell.db` khi đã ghi xong đồng ý; app
  /// chết giữa chừng thì lần mở sau thấy khóa còn sót, xóa khóa và về Chào mừng.
  Future<OpenOutcome> createNew(ConsentInput consent) async {
    files.dir.createSync(recursive: true);
    // Xóa nốt lần xóa trước (nếu còn dở) trước khi xét tệp CSDL.
    if (files.wipeMarker.existsSync() && !await _finishWipe()) return const KeyStuck();
    if (files.db.existsSync()) throw const DbAlreadyExistsException();
    _deleteCreatingFiles();
    Uint8List key;
    try {
      try {
        key = await keys.createDbKey();
      } on KeyAlreadyExistsException {
        // Khóa còn sót khi chưa có tệp nào: không còn dữ liệu nào dùng khóa này.
        await keys.deleteDbKey();
        key = await keys.createDbKey();
      }
    } on Object {
      // Kho khóa lỗi: chưa ghi gì xuống đĩa; "Chưa đọc được khóa…" + [Thử lại].
      return const KeyStuck();
    }
    final t = now();
    final today = dayKey(t);
    final ms = t.toUtc().millisecondsSinceEpoch;
    final db = sqlite3.open(files.creating.path);
    OpenOutcome? failed;
    try {
      setUpConnection(db, key);
      db.execute('BEGIN');
      for (final s in schemaV1) {
        db.execute(s);
      }
      db.execute("INSERT INTO meta (id, schema_version, created_at, onboarding_step) VALUES (1, ?, ?, 'body_profile')",
          [currentSchemaVersion, ms]);
      db.execute('INSERT INTO settings (id) VALUES (1)');
      db.execute('COMMIT');
      // Chưa có dữ liệu người dùng: kiểm tệp thật sự được mã hóa trước khi ghi.
      verifyFileEncrypted(db, files.creating);
      db.execute('BEGIN');
      db.execute(
          "INSERT INTO consents (kind, content_version, granted_at) VALUES ('health_data', ?, ?)",
          [consent.contentVersion, ms]);
      db.execute(
          'INSERT INTO profile (id, age_years, age_entered_on, caution, caution_answered_on, updated_at) '
          'VALUES (1, ?, ?, ?, ?, ?)',
          [consent.ageYears, today, consent.caution ? 1 : 0, today, ms]);
      db.execute('COMMIT');
      db.execute('PRAGMA wal_checkpoint(TRUNCATE)');
    } on DbOpenException catch (e) {
      failed = switch (e.stage) {
        DbOpenStage.cipher || DbOpenStage.notEncrypted => const InstallBroken(),
        _ => const CannotOpen(),
      };
    } on Object catch (e) {
      failed = _isDiskFull(e) ? const LowStorage() : const NeedsUpdate();
    } finally {
      db.close();
    }
    if (failed != null) {
      _deleteCreatingFiles();
      try {
        await keys.deleteDbKey();
      } on Object {
        // Khóa còn sót không có tệp: lần mở sau xóa lại.
      }
      return failed;
    }
    files.creating.renameSync(files.db.path);
    return open();
  }

  /// Rút đồng ý, xóa toàn bộ (luồng 4). Xóa khóa trước để dữ liệu không đọc được
  /// ngay, rồi mới xóa tệp; có dấu "đang xóa" để làm tiếp nếu app chết giữa chừng.
  Future<void> wipeAll({JournalRepository? openRepository}) async {
    files.dir.createSync(recursive: true);
    files.wipeMarker.writeAsStringSync('1', flush: true);
    if (openRepository != null) {
      try {
        await openRepository.close();
      } on Object {
        // Đóng lỗi vẫn xóa tiếp.
      }
    }
    await _finishWipe();
  }

  /// [Bắt đầu lại] sau khi gõ XÓA (màn "Không mở được"). Đóng nhật ký đang mở
  /// (nếu có) trước khi xóa tệp.
  Future<void> startOver({JournalRepository? openRepository}) => wipeAll(openRepository: openRepository);

  /// Xóa khóa rồi xóa tệp. Xóa khóa lỗi vẫn xóa tiếp các tệp (không còn tệp thì
  /// dữ liệu cũng không còn) và giữ dấu "đang xóa" để lần sau thử xóa khóa lại.
  /// Trả về true khi đã xóa xong cả khóa lẫn tệp và đã bỏ dấu.
  Future<bool> _finishWipe() async {
    var done = true;
    try {
      await keys.deleteDbKey();
    } on Object {
      done = false;
    }
    for (final f in [...files.allDataFiles(), ...extraFilesToWipe]) {
      try {
        DbFiles.deleteIfExists(f);
      } on FileSystemException {
        done = false;
      }
    }
    if (done) DbFiles.deleteIfExists(files.wipeMarker);
    return done;
  }
}
