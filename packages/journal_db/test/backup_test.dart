import 'dart:typed_data';

import 'package:health_engine/health_engine.dart';
import 'package:journal_db/journal_db.dart';
import 'package:journal_db/src/schema.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:test/test.dart';

import 'helpers.dart';

/// Cho phép giả lập lỗi KeyUnavailable khi đọc khóa ở nhánh B.
class _FaultyKeyStore extends FakeSecureKeyStore {
  bool stuckOnRead = false;

  @override
  Future<KeyReadResult> readDbKey() async {
    if (stuckOnRead) return const KeyUnavailable();
    return super.readDbKey();
  }
}

void main() {
  group('BackupCodec (Argon2id + ChaCha20-Poly1305 trong Isolate.run)', () {
    test('mã hóa và giải mã thành công với tham số mặc định & Recovery Key', () async {
      final recoveryKey = BackupCodec.generateRecoveryKey();
      expect(recoveryKey.replaceAll('-', '').length, 24);

      final plain = Uint8List.fromList(List<int>.generate(256, (i) => i % 251));
      final encrypted = await BackupCodec.encryptSnapshot(
        plainSqliteBytes: plain,
        schemaVersion: currentSchemaVersion,
        secret: recoveryKey,
      );

      final decoded = await BackupCodec.decryptSnapshot(
        backupBytes: encrypted,
        secret: recoveryKey,
      );
      expect(decoded.schemaVersion, currentSchemaVersion);
      expect(decoded.plainSqliteBytes, plain);
    });

    test('sai mật khẩu ném BackupWrongSecretException', () async {
      final plain = Uint8List.fromList([1, 2, 3, 4, 5, 6, 7, 8]);
      final encrypted = await BackupCodec.encryptSnapshot(
        plainSqliteBytes: plain,
        schemaVersion: currentSchemaVersion,
        secret: 'mat-khau-dung-1234',
        memoryKiB: 256,
        iterations: 1,
      );

      await expectLater(
        () => BackupCodec.decryptSnapshot(
          backupBytes: encrypted,
          secret: 'mat-khau-sai-1234',
        ),
        throwsA(isA<BackupWrongSecretException>()),
      );
    });

    test('tệp bị sửa 1 byte hoặc sai định dạng ném lỗi tương ứng', () async {
      final plain = Uint8List.fromList([10, 20, 30, 40]);
      final encrypted = await BackupCodec.encryptSnapshot(
        plainSqliteBytes: plain,
        schemaVersion: currentSchemaVersion,
        secret: 'secret-1234',
        memoryKiB: 256,
        iterations: 1,
      );

      final tamperedCipher = Uint8List.fromList(encrypted);
      tamperedCipher[tamperedCipher.length - 1] ^= 0xFF;
      await expectLater(
        () => BackupCodec.decryptSnapshot(backupBytes: tamperedCipher, secret: 'secret-1234'),
        throwsA(isA<BackupWrongSecretException>()),
      );

      final badHeader = Uint8List.fromList(encrypted);
      badHeader[0] = 0;
      await expectLater(
        () => BackupCodec.decryptSnapshot(backupBytes: badHeader, secret: 'secret-1234'),
        throwsA(isA<BackupCorruptedException>()),
      );

      await expectLater(
        () => BackupCodec.decryptSnapshot(
          backupBytes: Uint8List.fromList([1, 2, 3]),
          secret: 'secret-1234',
        ),
        throwsA(isA<BackupCorruptedException>()),
      );
    });
  });

  group('DbOpener exportBackup & restoreFromBackup', () {
    test('Nhánh A (đang mở khóa): sao lưu, thêm/xóa dữ liệu, khôi phục về đúng trạng thái cũ mà không KeyAlreadyExistsException', () async {
      final dir = tempDir();
      final keys = FakeSecureKeyStore();
      final opener = testOpener(dir, keys);
      final repo1 = await createdRepo(opener);

      await repo1.saveProfile(
        const Profile(
          ageYears: 30,
          sex: Sex.female,
          heightCm: 160,
          weightKg: 52,
          activityLevel: ActivityLevel.active,
        ),
      );
      await repo1.addWater(testNow(), 350);

      final backupBytes = await opener.exportBackup(
        openRepository: repo1,
        secret: 'recovery-pass-1',
        memoryKiB: 256,
        iterations: 1,
      );

      // Tệp tạm không mã hóa phải được dọn sạch ngay sau khi sao lưu.
      expect(opener.files.backupTmp.existsSync(), isFalse);
      expect(opener.files.restoreTmp.existsSync(), isFalse);
      expect(looksLikePlainSqlite(opener.files.db), isFalse);

      // Thay đổi dữ liệu sau khi sao lưu.
      await repo1.addWater(testNow(), 500);
      expect((await repo1.waterOn(dayKey(testNow()))).length, 2);

      // Khôi phục trên máy đang mở khóa (Nhánh A).
      final res = await opener.restoreFromBackup(
        backupBytes: backupBytes,
        secret: 'recovery-pass-1',
        openRepository: repo1,
      );
      expect(res, isA<RestoreSucceeded>());
      final opened = (res as RestoreSucceeded).openOutcome;
      expect(opened, isA<Opened>());
      final repo2 = (opened as Opened).repository;
      addTearDown(() async {
        try {
          await repo2.close();
        } on Object {
          // Đã đóng.
        }
      });

      final p = await repo2.loadProfile();
      expect(p?.weightKg, 52);
      final waters = await repo2.waterOn(dayKey(testNow()));
      expect(waters.length, 1);
      expect(waters.first.ml, 350);
      expect(looksLikePlainSqlite(opener.files.db), isFalse);
      expect(opener.files.restoreTmp.existsSync(), isFalse);
    });

    test('Nhánh A với sai mật khẩu không làm mất dữ liệu hiện tại', () async {
      final dir = tempDir();
      final keys = FakeSecureKeyStore();
      final opener = testOpener(dir, keys);
      final repo = await createdRepo(opener);
      await repo.addWater(testNow(), 250);

      final backupBytes = await opener.exportBackup(
        openRepository: repo,
        secret: 'right-pass',
        memoryKiB: 256,
        iterations: 1,
      );

      final res = await opener.restoreFromBackup(
        backupBytes: backupBytes,
        secret: 'wrong-pass',
        openRepository: repo,
      );
      expect(res, isA<RestoreWrongSecret>());
      // Repo cũ vẫn mở và giữ nguyên dữ liệu.
      final waters = await repo.waterOn(dayKey(testNow()));
      expect(waters.length, 1);
      expect(waters.first.ml, 250);
    });

    test('Nhánh B: khôi phục sang máy mới (Welcome), sai schemaVersion bị từ chối, bản cũ được nâng cấp', () async {
      final srcDir = tempDir();
      final srcKeys = FakeSecureKeyStore();
      final srcOpener = testOpener(srcDir, srcKeys);
      final srcRepo = await createdRepo(srcOpener);
      await srcRepo.addWater(testNow(), 400);
      final backupBytes = await srcOpener.exportBackup(
        openRepository: srcRepo,
        secret: 'cross-device-1',
        memoryKiB: 256,
        iterations: 1,
      );

      // Tạo bản sao lưu có header schemaVersion quá mới.
      final dec = await BackupCodec.decryptSnapshot(backupBytes: backupBytes, secret: 'cross-device-1');
      final futureBackup = await BackupCodec.encryptSnapshot(
        plainSqliteBytes: dec.plainSqliteBytes,
        schemaVersion: currentSchemaVersion + 1,
        secret: 'cross-device-1',
        memoryKiB: 256,
        iterations: 1,
      );

      // Máy mới (chưa có dữ liệu).
      final dstDir = tempDir();
      final dstKeys = FakeSecureKeyStore();
      final dstOpener = testOpener(dstDir, dstKeys);

      final tooNew = await dstOpener.restoreFromBackup(
        backupBytes: futureBackup,
        secret: 'cross-device-1',
      );
      expect(tooNew, isA<RestoreNeedsUpdate>());
      expect(dstOpener.files.db.existsSync(), isFalse);
      expect(dstOpener.files.restoreTmp.existsSync(), isFalse);

      // Khôi phục bản hợp lệ.
      final ok = await dstOpener.restoreFromBackup(
        backupBytes: backupBytes,
        secret: 'cross-device-1',
      );
      expect(ok, isA<RestoreSucceeded>());
      final opened = (ok as RestoreSucceeded).openOutcome;
      expect(opened, isA<Opened>());
      final dstRepo = (opened as Opened).repository;
      addTearDown(() async {
        try {
          await dstRepo.close();
        } on Object {
          // Đã đóng.
        }
      });
      final waters = await dstRepo.waterOn(dayKey(testNow()));
      expect(waters.length, 1);
      expect(waters.first.ml, 400);
    });

    test('Nhánh B từ trạng thái KeyStuck / CannotOpen + wipeMarker dở: bản sao lưu hỏng KHÔNG được xóa wipeMarker hoặc dữ liệu đang có', () async {
      final srcDir = tempDir();
      final srcKeys = FakeSecureKeyStore();
      final srcOpener = testOpener(srcDir, srcKeys);
      final srcRepo = await createdRepo(srcOpener);
      await srcRepo.addWater(testNow(), 300);
      final goodBackup = await srcOpener.exportBackup(
        openRepository: srcRepo,
        secret: 'my-secret',
        memoryKiB: 256,
        iterations: 1,
      );

      // Tạo payload đã mã hóa đúng mật khẩu nhưng ruột không phải SQLite hợp lệ.
      final badSqliteBackup = await BackupCodec.encryptSnapshot(
        plainSqliteBytes: Uint8List.fromList(List<int>.filled(64, 7)),
        schemaVersion: currentSchemaVersion,
        secret: 'my-secret',
        memoryKiB: 256,
        iterations: 1,
      );

      final stuckDir = tempDir();
      final stuckKeys = _FaultyKeyStore()..stuckOnRead = true;
      final stuckOpener = testOpener(stuckDir, stuckKeys);
      stuckOpener.files.dir.createSync(recursive: true);
      stuckOpener.files.wipeMarker.writeAsStringSync('wiped');
      stuckOpener.files.db.writeAsBytesSync([9, 8, 7]);

      final badRes = await stuckOpener.restoreFromBackup(
        backupBytes: badSqliteBackup,
        secret: 'my-secret',
      );
      expect(badRes, isA<RestoreCorrupted>());
      // wipeMarker và tệp db hỏng phải còn nguyên vì kiểm tra bản tạm thất bại.
      expect(stuckOpener.files.wipeMarker.existsSync(), isTrue);
      expect(stuckOpener.files.db.existsSync(), isTrue);

      // Khôi phục bản hợp lệ -> wipeMarker được dọn, khóa mới được tạo, mở thành công.
      stuckKeys.stuckOnRead = false;
      final okRes = await stuckOpener.restoreFromBackup(
        backupBytes: goodBackup,
        secret: 'my-secret',
      );
      expect(okRes, isA<RestoreSucceeded>());
      final opened = (okRes as RestoreSucceeded).openOutcome;
      expect(opened, isA<Opened>());
      addTearDown(() => (opened as Opened).repository.close());
      expect(stuckOpener.files.wipeMarker.existsSync(), isFalse);
    });

    test('DbOpener.open() tự xóa backupTmp và restoreTmp nếu còn sót sau crash', () async {
      final dir = tempDir();
      final keys = FakeSecureKeyStore();
      final opener = testOpener(dir, keys);
      final repo = await createdRepo(opener);
      await repo.close();

      opener.files.backupTmp.writeAsBytesSync([1, 2, 3]);
      opener.files.restoreTmp.writeAsBytesSync([4, 5, 6]);
      expect(opener.files.backupTmp.existsSync(), isTrue);
      expect(opener.files.restoreTmp.existsSync(), isTrue);

      final openRes = await opener.open();
      expect(openRes, isA<Opened>());
      addTearDown(() => (openRes as Opened).repository.close());
      expect(opener.files.backupTmp.existsSync(), isFalse);
      expect(opener.files.restoreTmp.existsSync(), isFalse);
    });

    test('exportReadableJson hoạt động trên cả DriftJournalRepository và InMemoryJournalRepository', () async {
      final dir = tempDir();
      final keys = FakeSecureKeyStore();
      final opener = testOpener(dir, keys);
      final driftRepo = await createdRepo(opener);
      await driftRepo.addWater(testNow(), 200);
      final pid = await driftRepo.addProduct('Vitamin D3', CountUnit.capsule, 1);
      await driftRepo.saveProductIngredients(pid, const [
        IngredientDraft(
          nutrientId: 'vit_d',
          form: 'cholecalciferol',
          amountPerServing: 25,
          unit: 'mcg',
        ),
      ]);

      final driftJson = await driftRepo.exportReadableJson();
      expect(driftJson['app'], 'WholeWell');
      expect(driftJson['schemaVersion'], currentSchemaVersion);
      final tables = driftJson['tables'] as Map<String, Object?>;
      expect((tables['water_entries'] as List).length, 1);
      expect((tables['products'] as List).length, 1);
      expect((tables['ingredients'] as List).length, 1);

      final memRepo = InMemoryJournalRepository();
      addTearDown(memRepo.close);
      await memRepo.addWater(testNow(), 300);
      final memJson = await memRepo.exportReadableJson();
      expect(memJson['app'], 'WholeWell');
      expect(memJson['watersCount'], 1);
    });

    test('Nhánh B khôi phục bản schema v1 tự nâng cấp lên v3 và bảo toàn dữ liệu', () async {
      final dir = tempDir();
      final files = DbFiles(dir);
      files.dir.createSync(recursive: true);
      final plainFile = files.restoreTmp;
      final db = sqlite3.open(plainFile.path);
      try {
        for (final s in schemaV1) {
          db.execute(s);
        }
        db.execute(
          "INSERT INTO meta (id, schema_version, created_at, onboarding_step) VALUES (1, 1, 1700000000000, 'done')",
        );
        db.execute(
          "INSERT INTO consents (id, kind, content_version, granted_at) VALUES (1, 'health_data', 'v1', 1700000000000)",
        );
        db.execute('INSERT INTO settings (id) VALUES (1)');
        db.execute(
          "INSERT INTO profile (id, age_years, age_entered_on, caution, caution_answered_on, sex, height_cm, weight_kg, activity_level, updated_at) "
          "VALUES (1, 28, '2026-11-24', 0, '2026-11-24', 'male', 170, 65, 'lowActive', 1700000000000)",
        );
      } finally {
        db.close();
      }
      final v1Bytes = plainFile.readAsBytesSync();
      plainFile.deleteSync();

      final v1Backup = await BackupCodec.encryptSnapshot(
        plainSqliteBytes: v1Bytes,
        schemaVersion: 1,
        secret: 'v1-secret',
        memoryKiB: 256,
        iterations: 1,
      );

      final dstDir = tempDir();
      final realOpener = DbOpener(
        files: DbFiles(dstDir),
        keys: FakeSecureKeyStore(),
        executorFactory: sameIsolateExecutor,
        retryDelay: Duration.zero,
        now: testNow,
      );

      final res = await realOpener.restoreFromBackup(
        backupBytes: v1Backup,
        secret: 'v1-secret',
      );
      expect(res, isA<RestoreSucceeded>());
      final opened = (res as RestoreSucceeded).openOutcome;
      expect(opened, isA<Opened>());
      final repo = (opened as Opened).repository;
      addTearDown(repo.close);
      final profile = await repo.loadProfile();
      expect(profile?.ageYears, 28);
      final dayTimes = await repo.loadDayTimesSettings();
      expect(dayTimes.showTipCard, isTrue);
      expect(dayTimes.hasBreakfast, isTrue);
      expect(dayTimes.hasLunch, isTrue);
      expect(dayTimes.hasDinner, isTrue);
      expect(dayTimes.reminderShowDetails, isFalse);
    });

    test('drive consent: latestDriveConsent, grantDriveConsent, withdrawDriveConsent trên cả Drift và InMemory và bảo toàn khi khôi phục', () async {
      for (final isMem in [false, true]) {
        late final JournalRepository repo;
        if (isMem) {
          repo = InMemoryJournalRepository();
          addTearDown(repo.close);
        } else {
          final opener = testOpener(tempDir(), FakeSecureKeyStore());
          repo = await createdRepo(opener);
        }
        expect(await repo.latestDriveConsent(), isNull);
        await repo.grantDriveConsent('drive-v1');
        final c = await repo.latestDriveConsent();
        expect(c?.contentVersion, 'drive-v1');
        await repo.withdrawDriveConsent();
        expect(await repo.latestDriveConsent(), isNull);
      }

      // Khôi phục bản sao lưu mang theo trạng thái drive consent.
      final srcOpener = testOpener(tempDir(), FakeSecureKeyStore());
      final srcRepo = await createdRepo(srcOpener);
      await srcRepo.grantDriveConsent(mvpConsentVersion);
      final bytes = await srcOpener.exportBackup(
        openRepository: srcRepo,
        secret: 'drive-consent-1',
        memoryKiB: 256,
        iterations: 1,
      );
      final dstOpener = testOpener(tempDir(), FakeSecureKeyStore());
      final res = await dstOpener.restoreFromBackup(backupBytes: bytes, secret: 'drive-consent-1');
      expect(res, isA<RestoreSucceeded>());
      final dstRepo = ((res as RestoreSucceeded).openOutcome as Opened).repository;
      addTearDown(dstRepo.close);
      expect((await dstRepo.latestDriveConsent())?.contentVersion, mvpConsentVersion);
    });
  });
}
