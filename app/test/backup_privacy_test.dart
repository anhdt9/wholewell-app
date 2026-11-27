import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:health_engine/health_engine.dart';
import 'package:journal_db/journal_db.dart';
import 'package:material_ui/material_ui.dart';
import 'package:wholewell/main.dart';
import 'package:wholewell/state/app_state.dart';
import 'package:wholewell/ui/data_status_screen.dart';
import 'package:wholewell/ui/drive_backup_screens.dart';
import 'package:wholewell/ui/today_screen.dart';

Future<void> _drainUntil(WidgetTester tester, bool Function() ready) async {
  for (var i = 0; i < 200; i++) {
    await tester.pump();
    if (ready()) break;
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
  }
  await tester.pumpAndSettle();
}

void main() {
  late ReferencePack pack;

  setUpAll(() {
    final packFile = File('assets/reference_pack.json');
    pack = ReferencePack.fromJsonString(packFile.readAsStringSync());
  });

  DbOpener makeOpener(Directory dir, FakeSecureKeyStore keys) => DbOpener(
        files: DbFiles(dir),
        keys: keys,
        executorFactory: sameIsolateExecutor,
        retryDelay: Duration.zero,
      );

  Future<Directory> makeTempDir(String prefix) async {
    final dir = Directory.systemTemp.createTempSync(prefix);
    addTearDown(() {
      if (dir.existsSync()) dir.deleteSync(recursive: true);
    });
    return dir;
  }

  Future<AppState> seedReadyApp({
    required Directory dir,
    required FakeSecureKeyStore keys,
    required FakeBackupFileProvider fileProvider,
    FakeNotificationScheduler? notif,
    double waterMl = 350,
    bool autoDispose = true,
  }) async {
    final opener = makeOpener(dir, keys);
    final res = await opener.createNew(
      const ConsentInput(contentVersion: mvpConsentVersion, ageYears: 29, caution: false),
    );
    expect(res, isA<Opened>());
    final repo = (res as Opened).repository;
    await repo.saveProfile(
      const Profile(
        ageYears: 29,
        sex: Sex.female,
        heightCm: 160,
        weightKg: 54,
        activityLevel: ActivityLevel.active,
      ),
    );
    await repo.saveHideCalories(false);
    await repo.saveOnboardingStep(OnboardingStep.done);
    await repo.addWater(DateTime.now(), waterMl);
    await repo.close();

    final state = AppState(
      pack: pack,
      opener: makeOpener(dir, keys),
      backupFileProvider: fileProvider,
      notificationScheduler: notif ?? FakeNotificationScheduler(),
    );
    await state.start();
    if (autoDispose) {
      addTearDown(() async {
        await state.session.repo?.close();
        state.dispose();
      });
    }
    return state;
  }

  group('Sao lưu tệp mã hóa, khôi phục và Quyền riêng tư', () {
    testWidgets('Tôi -> Sao lưu và khôi phục: mã 24 ký tự & tự đặt mật khẩu lưu tệp .wwbackup', (tester) async {
      final dir = await makeTempDir('ww_backup_ui_');
      final keys = FakeSecureKeyStore();
      final files = FakeBackupFileProvider();
      final state = await tester.runAsync(
        () => seedReadyApp(dir: dir, keys: keys, fileProvider: files),
      );

      await tester.pumpWidget(WholeWellApp(state: state!));
      await tester.pumpAndSettle();

      // Vào tab Tôi -> thấy Chưa sao lưu qua tệp.
      await tester.tap(find.text('Tôi'));
      await tester.pumpAndSettle();
      expect(find.text('Sao lưu và khôi phục'), findsOneWidget);
      expect(find.text('Chưa sao lưu qua tệp'), findsOneWidget);
      expect(find.text('Quyền riêng tư'), findsOneWidget);

      await tester.tap(find.text('Sao lưu và khôi phục'));
      await tester.pumpAndSettle();
      expect(find.text('Tạo tệp sao lưu'), findsOneWidget);
      expect(find.text('Google Drive (tùy chọn)'), findsOneWidget);

      // Mở Tạo tệp sao lưu (chế độ mặc định Mã khôi phục 24 ký tự).
      await tester.tap(find.text('Tạo tệp sao lưu'));
      await tester.pumpAndSettle();

      // Nút lưu tắt khi chưa tick xác nhận đã lưu mã.
      final saveBtn = find.widgetWithText(FilledButton, 'Chọn nơi lưu tệp');
      expect(tester.widget<FilledButton>(saveBtn).onPressed, isNull);

      await tester.tap(find.text('Tôi đã lưu mã này ở nơi an toàn.'));
      await tester.pumpAndSettle();
      expect(tester.widget<FilledButton>(saveBtn).onPressed, isNotNull);

      await tester.tap(saveBtn);
      await tester.pump();
      await _drainUntil(tester, () => files.savedFiles.isNotEmpty);

      expect(files.savedFiles.length, 1);
      expect(files.savedFiles.first.suggestedName, endsWith('.wwbackup'));
      expect(state.lastFileBackupAt, isNotNull);

      // Chuyển sang Tự đặt mật khẩu -> kiểm tra validation < 8 ký tự và không khớp.
      await tester.tap(find.text('Tạo tệp sao lưu'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Tự đặt mật khẩu'));
      await tester.pumpAndSettle();

      final pwFields = find.byType(TextField);
      await tester.enterText(pwFields.at(0), '12345');
      await tester.enterText(pwFields.at(1), '12345');
      await tester.pumpAndSettle();
      expect(find.text('Mật khẩu tối thiểu 8 ký tự.'), findsOneWidget);

      await tester.enterText(pwFields.at(0), 'matkhau123');
      await tester.enterText(pwFields.at(1), 'matkhau456');
      await tester.pumpAndSettle();
      expect(find.text('Mật khẩu nhập lại chưa khớp.'), findsOneWidget);

      await tester.enterText(pwFields.at(1), 'matkhau123');
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Chọn nơi lưu tệp'));
      await tester.pump();
      await _drainUntil(tester, () => files.savedFiles.length >= 2);

      expect(files.savedFiles.length, 2);
      expect(state.lastFileBackupAt, isNotNull);
    });

    testWidgets('Khôi phục từ Chào mừng: sai mã báo lỗi giữ Welcome, đúng mã vào thẳng Hôm nay và sync thông báo',
        (tester) async {
      // Tạo bản sao lưu từ máy nguồn (có bật nhắc giờ và sản phẩm có lịch).
      final srcDir = await makeTempDir('ww_src_');
      final srcKeys = FakeSecureKeyStore();
      final srcFiles = FakeBackupFileProvider();
      final srcState = await tester.runAsync(
        () => seedReadyApp(
          dir: srcDir,
          keys: srcKeys,
          fileProvider: srcFiles,
          waterMl: 450,
          autoDispose: false,
        ),
      );
      await tester.runAsync(() async {
        final r = srcState!.session.repo!;
        await r.grantNotificationConsent(mvpConsentVersion);
        final pid = await r.addProduct('Vitamin C', CountUnit.tablet, 1);
        await r.addSchedule(pid, 8 * 60, 1, validFrom: dayKey(DateTime.now()));
        await srcState.reload();
        await srcState.createEncryptedBackupFile(
          secret: 'mat-khau-bi-mat',
          memoryKiB: 256,
          iterations: 1,
        );
        await srcState.session.repo?.close();
        srcState.dispose();
      });
      final backupBytes = srcFiles.savedFiles.single.bytes;

      // Máy mới (Welcome).
      final dstDir = await makeTempDir('ww_dst_');
      final dstKeys = FakeSecureKeyStore();
      final dstFiles = FakeBackupFileProvider()
        ..nextPickFile = PickedBackupFile(name: 'wholewell.wwbackup', bytes: backupBytes);
      final dstNotif = FakeNotificationScheduler(granted: true);
      final dstState = AppState(
        pack: pack,
        opener: makeOpener(dstDir, dstKeys),
        backupFileProvider: dstFiles,
        notificationScheduler: dstNotif,
      );
      await tester.runAsync(dstState.start);
      addTearDown(() async {
        await dstState.session.repo?.close();
        dstState.dispose();
      });

      await tester.pumpWidget(WholeWellApp(state: dstState));
      await tester.pumpAndSettle();

      expect(find.text('Khôi phục từ bản sao lưu'), findsOneWidget);
      await tester.tap(find.text('Khôi phục từ bản sao lưu'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Từ tệp trên máy (.wwbackup)'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Chọn tệp sao lưu'));
      await tester.pumpAndSettle();
      expect(find.text('Tệp: wholewell.wwbackup'), findsOneWidget);

      // Thử mật khẩu sai.
      await tester.enterText(find.byType(TextField), 'sai-mat-khau');
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Khôi phục'));
      await _drainUntil(
        tester,
        () => find.text('Mã khôi phục không đúng hoặc tệp đã bị hỏng.').evaluate().isNotEmpty,
      );

      expect(find.text('Mã khôi phục không đúng hoặc tệp đã bị hỏng.'), findsOneWidget);
      expect(dstState.status, DataStatus.welcome);

      // Nhập mật khẩu đúng -> vào thẳng Hôm nay & đồng bộ lại lịch nhắc.
      await tester.enterText(find.byType(TextField), 'mat-khau-bi-mat');
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Khôi phục'));
      await tester.pump();
      await _drainUntil(tester, () => dstState.status == DataStatus.ready);

      expect(dstState.status, DataStatus.ready);
      expect(dstState.stage, SessionStage.ready);
      expect(dstState.todayWaters.single.ml, 450);
      expect(dstNotif.syncedSlots.length, 1);
      expect(find.byType(TodayScreen), findsOneWidget);
    });

    testWidgets('Khôi phục từ màn lỗi DataStatus.cannotOpen hoạt động', (tester) async {
      final srcDir = await makeTempDir('ww_src_err_');
      final srcFiles = FakeBackupFileProvider();
      final srcState = await tester.runAsync(
        () => seedReadyApp(
          dir: srcDir,
          keys: FakeSecureKeyStore(),
          fileProvider: srcFiles,
          waterMl: 500,
          autoDispose: false,
        ),
      );
      await tester.runAsync(() async {
        await srcState!.createEncryptedBackupFile(
          secret: 'recover-err-99',
          memoryKiB: 256,
          iterations: 1,
        );
        await srcState.session.repo?.close();
        srcState.dispose();
      });

      // Máy có file db nhưng không có khóa -> CannotOpen.
      final errDir = await makeTempDir('ww_cannot_open_');
      File('${errDir.path}/wholewell.db').writeAsBytesSync([1, 2, 3, 4]);
      final errFiles = FakeBackupFileProvider()
        ..nextPickFile = PickedBackupFile(
          name: 'err.wwbackup',
          bytes: srcFiles.savedFiles.single.bytes,
        );
      final errState = AppState(
        pack: pack,
        opener: makeOpener(errDir, FakeSecureKeyStore()),
        backupFileProvider: errFiles,
      );
      await tester.runAsync(errState.start);
      addTearDown(() async {
        await errState.session.repo?.close();
        errState.dispose();
      });

      await tester.pumpWidget(WholeWellApp(state: errState));
      await tester.pumpAndSettle();

      expect(find.byType(DataStatusScreen), findsOneWidget);
      await tester.tap(find.text('Khôi phục từ bản sao lưu'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Từ tệp trên máy (.wwbackup)'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Chọn tệp sao lưu'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'recover-err-99');
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Khôi phục'));
      await tester.pump();
      await _drainUntil(tester, () => errState.status == DataStatus.ready);

      expect(errState.status, DataStatus.ready);
      expect(errState.todayWaters.single.ml, 500);
    });

    testWidgets('Khôi phục bản schema mới hơn báo cần cập nhật và giữ dữ liệu cũ', (tester) async {
      final dir = await makeTempDir('ww_newer_');
      final keys = FakeSecureKeyStore();
      final files = FakeBackupFileProvider();
      final state = await tester.runAsync(
        () => seedReadyApp(dir: dir, keys: keys, fileProvider: files, waterMl: 200),
      );
      final futureBackup = await tester.runAsync(() => BackupCodec.encryptSnapshot(
            plainSqliteBytes: Uint8List.fromList([1, 2, 3, 4]),
            schemaVersion: currentSchemaVersion + 2,
            secret: 'future-pass',
            memoryKiB: 256,
            iterations: 1,
          ));
      files.nextPickFile = PickedBackupFile(name: 'future.wwbackup', bytes: futureBackup!);

      await tester.pumpWidget(WholeWellApp(state: state!));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Tôi'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Sao lưu và khôi phục'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Khôi phục từ tệp'));
      await tester.pumpAndSettle();
      expect(find.text('Khôi phục sẽ thay dữ liệu hiện tại trên máy này.'), findsOneWidget);

      await tester.tap(find.text('Chọn tệp sao lưu'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'future-pass');
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Khôi phục'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Khôi phục').last);
      await _drainUntil(
        tester,
        () => find
            .text(
              'Tệp sao lưu được tạo bởi phiên bản WholeWell mới hơn. Hãy cập nhật app trước khi khôi phục.',
            )
            .evaluate()
            .isNotEmpty,
      );

      expect(
        find.text(
          'Tệp sao lưu được tạo bởi phiên bản WholeWell mới hơn. Hãy cập nhật app trước khi khôi phục.',
        ),
        findsOneWidget,
      );
      expect(state.todayWaters.single.ml, 200);
    });

    testWidgets('Quyền riêng tư: xuất JSON (cảnh báo không mã hóa), rút đồng ý và xóa toàn bộ dữ liệu',
        (tester) async {
      final dir = await makeTempDir('ww_privacy_');
      final keys = FakeSecureKeyStore();
      final files = FakeBackupFileProvider();
      final notif = FakeNotificationScheduler(granted: true);
      final state = await tester.runAsync(
        () => seedReadyApp(dir: dir, keys: keys, fileProvider: files, notif: notif, waterMl: 300),
      );

      await tester.pumpWidget(WholeWellApp(state: state!));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Tôi'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Quyền riêng tư'));
      await tester.pumpAndSettle();

      expect(find.text('Xử lý dữ liệu sức khỏe'), findsOneWidget);
      expect(find.text('Google Drive: chưa bật'), findsOneWidget);

      // Xuất dữ liệu -> cảnh báo không mã hóa -> lưu .json đọc được.
      await tester.tap(find.text('Xuất dữ liệu'));
      await tester.pumpAndSettle();
      expect(find.text('Tệp này không được mã hóa. Ai có tệp đều đọc được.'), findsOneWidget);
      await tester.tap(find.text('Tiếp tục xuất'));
      await tester.pump();
      await _drainUntil(tester, () => files.savedFiles.isNotEmpty);

      expect(files.savedFiles.length, 1);
      expect(files.savedFiles.single.suggestedName, endsWith('.json'));
      final exported = jsonDecode(utf8.decode(files.savedFiles.single.bytes)) as Map<String, Object?>;
      expect(exported['app'], 'WholeWell');
      final tables = exported['tables'] as Map<String, Object?>?;
      expect(tables, isNotNull);
      expect((tables!['water_entries'] as List?)?.length, 1);

      // Rút đồng ý -> xác nhận -> xóa CSDL, hủy thông báo, về màn Chào mừng.
      await tester.tap(find.widgetWithText(OutlinedButton, 'Rút đồng ý'));
      await tester.pumpAndSettle();
      expect(
        find.text(
          'Rút đồng ý sẽ xóa mọi dữ liệu trên máy này. Nếu có bản sao lưu, bạn có thể khôi phục sau.',
        ),
        findsOneWidget,
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Rút đồng ý'));
      await tester.pump();
      await _drainUntil(tester, () => state.status == DataStatus.welcome);

      expect(state.status, DataStatus.welcome);
      expect(keys.key, isNull);
      expect(find.text('Bắt đầu'), findsOneWidget);
    });
  });

  group('Phần 7b: Sao lưu Google Drive (appDataFolder)', () {
    testWidgets('Kết nối Drive (đồng ý riêng), tải tối đa 3 bản và ngắt kết nối', (tester) async {
      final dir = await makeTempDir('ww_drive_up_');
      final keys = FakeSecureKeyStore();
      final files = FakeBackupFileProvider();
      final googleAuth = FakeGoogleAuth();
      final driveProvider = FakeBackupProvider();
      final pendingStore = FileDrivePendingDeleteStore(
        File('${dir.path}/drive_pending_delete.json'),
      );

      final opener = makeOpener(dir, keys);
      final seeded = await tester.runAsync(() async {
        final res = await opener.createNew(
          const ConsentInput(contentVersion: mvpConsentVersion, ageYears: 27, caution: false),
        );
        final repo = (res as Opened).repository;
        await repo.saveProfile(
          const Profile(
            ageYears: 27,
            sex: Sex.male,
            heightCm: 172,
            weightKg: 66,
            activityLevel: ActivityLevel.active,
          ),
        );
        await repo.saveHideCalories(false);
        await repo.saveOnboardingStep(OnboardingStep.done);
        await repo.addWater(DateTime.now(), 400);
        await repo.close();
        final s = AppState(
          pack: pack,
          opener: makeOpener(dir, keys),
          backupFileProvider: files,
          googleAuth: googleAuth,
          driveBackupProvider: driveProvider,
          drivePendingDeleteStore: pendingStore,
        );
        await s.start();
        return s;
      });
      final state = seeded!;
      addTearDown(() async {
        await state.session.repo?.close();
        state.dispose();
      });

      await tester.pumpWidget(WholeWellApp(state: state));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Tôi'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Sao lưu và khôi phục'));
      await tester.pumpAndSettle();

      // Chưa bật Drive -> thấy Kết nối Google Drive.
      await tester.tap(find.text('Kết nối Google Drive'));
      await tester.pumpAndSettle();

      // Màn đồng ý riêng: ô không đánh sẵn.
      final cb = find.byType(CheckboxListTile);
      expect(tester.widget<CheckboxListTile>(cb).value, isFalse);
      final nextBtn = find.widgetWithText(FilledButton, 'Tiếp tục với Google');
      expect(tester.widget<FilledButton>(nextBtn).onPressed, isNull);

      await tester.tap(cb);
      await tester.pumpAndSettle();
      await tester.tap(nextBtn);
      await tester.pumpAndSettle();

      // Đã vào màn Sao lưu lên Google Drive.
      expect(find.textContaining('test@example.com'), findsOneWidget);
      await tester.tap(find.text('Tự đặt mật khẩu'));
      await tester.pumpAndSettle();
      final pwFields = find.byType(TextField);
      await tester.enterText(pwFields.at(0), 'drive-secret-1');
      await tester.enterText(pwFields.at(1), 'drive-secret-1');
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Tải bản sao lưu lên'));
      await _drainUntil(tester, () => state.lastDriveBackupAt != null);

      expect(state.driveEnabled, isTrue);
      expect(state.lastDriveBackupAt, isNotNull);
      expect((await driveProvider.listBackups()).length, 1);

      // Tải thêm 3 lần nữa -> tối đa chỉ giữ 3 bản gần nhất trên Drive.
      await tester.runAsync(() async {
        for (var i = 0; i < 3; i++) {
          await state.createDriveBackup(
            secret: 'drive-secret-$i',
            memoryKiB: 256,
            iterations: 1,
          );
        }
      });
      expect((await driveProvider.listBackups()).length, 3);

      // Ngắt kết nối Google Drive (giữ bản trên Drive).
      await tester.tap(find.text('Ngắt kết nối Google Drive'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Ngắt kết nối'));
      await tester.pumpAndSettle();
      expect(state.driveEnabled, isFalse);
      expect((await driveProvider.listBackups()).length, 3);
    });

    testWidgets('Khôi phục từ Google Drive ở Chào mừng: không hỏi màn đồng ý, mang theo drive consent',
        (tester) async {
      // Tạo bản sao lưu có sẵn consents.kind = 'drive' đưa lên FakeBackupProvider.
      final srcDir = await makeTempDir('ww_drive_src_');
      final srcKeys = FakeSecureKeyStore();
      final srcOpener = makeOpener(srcDir, srcKeys);
      final driveProvider = FakeBackupProvider();
      await tester.runAsync(() async {
        final r = (await srcOpener.createNew(
          const ConsentInput(contentVersion: mvpConsentVersion, ageYears: 31, caution: false),
        )) as Opened;
        await r.repository.saveProfile(
          const Profile(
            ageYears: 31,
            sex: Sex.female,
            heightCm: 158,
            weightKg: 50,
            activityLevel: ActivityLevel.inactive,
          ),
        );
        await r.repository.saveHideCalories(false);
        await r.repository.saveOnboardingStep(OnboardingStep.done);
        await r.repository.grantDriveConsent(mvpConsentVersion);
        await r.repository.addWater(DateTime.now(), 600);
        final bytes = await srcOpener.exportBackup(
          openRepository: r.repository,
          secret: 'cloud-restore-1',
          memoryKiB: 256,
          iterations: 1,
        );
        driveProvider.seedBackup(bytes: bytes);
        await r.repository.close();
      });

      final dstDir = await makeTempDir('ww_drive_dst_');
      final dstAuth = FakeGoogleAuth();
      final dstState = AppState(
        pack: pack,
        opener: makeOpener(dstDir, FakeSecureKeyStore()),
        googleAuth: dstAuth,
        driveBackupProvider: driveProvider,
      );
      await tester.runAsync(dstState.start);
      addTearDown(() async {
        await dstState.session.repo?.close();
        dstState.dispose();
      });

      await tester.pumpWidget(WholeWellApp(state: dstState));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Khôi phục từ bản sao lưu'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Từ Google Drive'));
      await tester.pumpAndSettle();

      // Không hỏi màn đồng ý bật Drive; yêu cầu đăng nhập để chọn bản.
      expect(find.text('Tôi hiểu và đồng ý bật sao lưu qua Google Drive.'), findsNothing);
      await tester.tap(find.text('Đăng nhập Google'));
      await tester.pumpAndSettle();
      expect(find.text('Chọn bản sao lưu'), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'cloud-restore-1');
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Khôi phục'));
      await _drainUntil(tester, () => dstState.status == DataStatus.ready);

      expect(dstState.status, DataStatus.ready);
      expect(dstState.todayWaters.single.ml, 600);
      expect(dstState.driveEnabled, isTrue);
      expect(find.byType(TodayScreen), findsOneWidget);
    });

    testWidgets('Rút đồng ý & Xóa toàn bộ khi bật Drive: mất mạng giữ pending_delete ngoài CSDL rồi tự xóa khi có mạng / hết phiên',
        (tester) async {
      final dir = await makeTempDir('ww_drive_del_');
      final keys = FakeSecureKeyStore();
      final pendingFile = File('${dir.path}/drive_pending_delete.json');
      final pendingStore = FileDrivePendingDeleteStore(pendingFile);
      final googleAuth = FakeGoogleAuth(
        initialUser: const GoogleAuthAccount(id: 'u1', email: 'user@gmail.com'),
      );
      final driveProvider = FakeBackupProvider()
        ..seedBackup(bytes: Uint8List.fromList([1, 2, 3]))
        ..errorOnDelete = const SocketException('offline');

      final state = await tester.runAsync(() async {
        final opener = makeOpener(dir, keys);
        final res = (await opener.createNew(
          const ConsentInput(contentVersion: mvpConsentVersion, ageYears: 28, caution: false),
        )) as Opened;
        await res.repository.saveProfile(
          const Profile(
            ageYears: 28,
            sex: Sex.male,
            heightCm: 170,
            weightKg: 65,
            activityLevel: ActivityLevel.active,
          ),
        );
        await res.repository.saveHideCalories(false);
        await res.repository.saveOnboardingStep(OnboardingStep.done);
        await res.repository.grantDriveConsent(mvpConsentVersion);
        await res.repository.close();

        final s = AppState(
          pack: pack,
          opener: makeOpener(dir, keys),
          googleAuth: googleAuth,
          driveBackupProvider: driveProvider,
          drivePendingDeleteStore: pendingStore,
        );
        await s.start();
        return s;
      });
      final appState = state!;
      addTearDown(() async {
        await appState.session.repo?.close();
        appState.dispose();
      });

      await tester.pumpWidget(WholeWellApp(state: appState));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Tôi'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Quyền riêng tư'));
      await tester.pumpAndSettle();

      // Kiểm tra hộp thoại Xóa toàn bộ: ô Xóa cả bản Drive KHÔNG đánh sẵn.
      await tester.tap(find.widgetWithText(OutlinedButton, 'Xóa toàn bộ dữ liệu'));
      await tester.pumpAndSettle();
      expect(tester.widget<CheckboxListTile>(find.byType(CheckboxListTile)).value, isFalse);
      await tester.tap(find.text('Hủy'));
      await tester.pumpAndSettle();

      // Kiểm tra hộp thoại Rút đồng ý: ô Xóa cả bản Drive ĐÁNH SẴN.
      await tester.tap(find.widgetWithText(OutlinedButton, 'Rút đồng ý'));
      await tester.pumpAndSettle();
      expect(tester.widget<CheckboxListTile>(find.byType(CheckboxListTile)).value, isTrue);
      expect(find.text('Tệp sao lưu bạn đã xuất ra ngoài thì app không xóa được.'), findsOneWidget);

      await tester.tap(find.widgetWithText(FilledButton, 'Rút đồng ý'));
      await _drainUntil(tester, () => appState.status == DataStatus.welcome);

      // Dữ liệu trên máy xóa ngay dù mất mạng, nhưng drive_pending_delete.json vẫn còn ngoài CSDL.
      expect(appState.status, DataStatus.welcome);
      expect(keys.key, isNull);
      expect(pendingFile.existsSync(), isTrue);
      expect(appState.drivePendingDeleteActive, isTrue);
      expect(find.byType(PendingDriveDeleteCard), findsOneWidget);

      // Mô phỏng hết phiên / thu hồi quyền ngoài Google Account -> hiện Đăng nhập để xóa.
      driveProvider.errorOnDelete = null;
      googleAuth.silentRevoked = true;
      await tester.runAsync(appState.onAppResume);
      await tester.pumpAndSettle();
      expect(appState.drivePendingDeleteNeedsReauth, isTrue);
      expect(find.text('Chưa xóa được bản trên Google Drive do hết phiên đăng nhập.'), findsOneWidget);

      // Bấm Đăng nhập để xóa -> xóa sạch trên Drive, xóa cờ và thu hồi quyền.
      await tester.tap(find.text('Đăng nhập để xóa'));
      await _drainUntil(tester, () => !appState.drivePendingDeleteActive);
      expect(pendingFile.existsSync(), isFalse);
      expect(await driveProvider.listBackups(), isEmpty);
      expect(googleAuth.disconnectCalls, 1);
    });

    testWidgets('createDriveBackup: currentUser != null nhưng authHeaders == null vẫn gọi lại signInGoogleDrive()',
        (tester) async {
      final dir = await makeTempDir('ww_drive_hdr_');
      final keys = FakeSecureKeyStore();
      final googleAuth = FakeGoogleAuth(
        initialUser: const GoogleAuthAccount(id: 'u1', email: 'user@gmail.com'),
      )..fakeHeaders = null;
      final driveProvider = FakeBackupProvider();
      final state = await tester.runAsync(() async {
        final opener = makeOpener(dir, keys);
        final res = (await opener.createNew(
          const ConsentInput(contentVersion: mvpConsentVersion, ageYears: 26, caution: false),
        )) as Opened;
        await res.repository.saveProfile(
          const Profile(
            ageYears: 26,
            sex: Sex.female,
            heightCm: 160,
            weightKg: 52,
            activityLevel: ActivityLevel.active,
          ),
        );
        await res.repository.saveHideCalories(false);
        await res.repository.saveOnboardingStep(OnboardingStep.done);
        await res.repository.close();
        final s = AppState(
          pack: pack,
          opener: makeOpener(dir, keys),
          googleAuth: googleAuth,
          driveBackupProvider: driveProvider,
        );
        await s.start();
        return s;
      });
      final appState = state!;
      addTearDown(() async {
        await appState.session.repo?.close();
        appState.dispose();
      });

      final beforeCalls = googleAuth.signInCalls;
      await tester.runAsync(() async {
        await appState.createDriveBackup(
          secret: 'reauth-secret-1',
          memoryKiB: 256,
          iterations: 1,
        );
      });
      expect(googleAuth.signInCalls, beforeCalls + 1);
      expect((await driveProvider.listBackups()).length, 1);
    });

    testWidgets('restoreFromGoogleDrive không gọi lại signInSilently; onAppResume không lặp vô hạn khi needsReauth',
        (tester) async {
      final srcDir = await makeTempDir('ww_drive_norepeat_src_');
      final keys = FakeSecureKeyStore();
      final srcOpener = makeOpener(srcDir, keys);
      final bytes = await tester.runAsync(() async {
        final srcRes = await srcOpener.createNew(
          const ConsentInput(contentVersion: mvpConsentVersion, ageYears: 29, caution: false),
        );
        final srcRepo = (srcRes as Opened).repository;
        await srcRepo.saveProfile(const Profile(
          ageYears: 29,
          sex: Sex.female,
          heightCm: 160,
          weightKg: 54,
          activityLevel: ActivityLevel.active,
        ));
        await srcRepo.saveOnboardingStep(OnboardingStep.done);
        await srcRepo.grantDriveConsent(mvpConsentVersion);
        final exported = await srcOpener.exportBackup(
          openRepository: srcRepo,
          secret: 'no-loop-secret',
          memoryKiB: 256,
          iterations: 1,
          parallelism: 1,
        );
        await srcRepo.close();
        return exported;
      });
      final backupBytes = bytes!;

      final dstDir = await makeTempDir('ww_drive_norepeat_dst_');
      final googleAuth = FakeGoogleAuth(
        initialUser: const GoogleAuthAccount(id: 'u1', email: 'test@example.com'),
      );
      final driveProvider = FakeBackupProvider()..seedBackup(bytes: backupBytes);
      final pendingStore = FileDrivePendingDeleteStore(
        File('${dstDir.path}/drive_pending_delete.json'),
      );
      final dstState = await tester.runAsync(() async {
        final s = AppState(
          pack: pack,
          opener: makeOpener(dstDir, FakeSecureKeyStore()),
          googleAuth: googleAuth,
          driveBackupProvider: driveProvider,
          drivePendingDeleteStore: pendingStore,
        );
        await s.start();
        return s;
      });
      final state = dstState!;
      addTearDown(() async {
        await state.session.repo?.close();
        state.dispose();
      });

      final backups = await driveProvider.listBackups();
      final outcome = await tester.runAsync(
        () => state.restoreFromGoogleDrive(backupId: backups.single.id, secret: 'no-loop-secret'),
      );
      expect(outcome, isA<RestoreSucceeded>());
      expect(googleAuth.signInSilentlyCalls, 0);

      // Khi cần reauth (pending delete + signInSilently trả null), onAppResume thứ 2 không lặp lại signInSilently.
      await tester.runAsync(pendingStore.markPendingDelete);
      googleAuth.silentRevoked = true;
      await tester.runAsync(state.onAppResume);
      expect(googleAuth.signInSilentlyCalls, 1);
      expect(state.drivePendingDeleteNeedsReauth, isTrue);

      await tester.runAsync(state.onAppResume);
      expect(googleAuth.signInSilentlyCalls, 1);
    });

    testWidgets('start() không bật CredentialManager (signInSilentlyCalls == 0) khi pending == false',
        (tester) async {
      final dir = await makeTempDir('ww_drive_cold_no_prompt_');
      final keys = FakeSecureKeyStore();
      final googleAuth = FakeGoogleAuth();
      final firstOpener = makeOpener(dir, keys);
      await tester.runAsync(() async {
        final res = await firstOpener.createNew(
          const ConsentInput(contentVersion: mvpConsentVersion, ageYears: 28, caution: false),
        );
        final repo = (res as Opened).repository;
        await repo.saveProfile(const Profile(
          ageYears: 28,
          sex: Sex.male,
          heightCm: 172,
          weightKg: 68,
          activityLevel: ActivityLevel.active,
        ));
        await repo.saveHideCalories(false);
        await repo.saveOnboardingStep(OnboardingStep.done);
        await repo.grantDriveConsent(mvpConsentVersion);
        await repo.close();
      });

      final state = await tester.runAsync(() async {
        final s = AppState(
          pack: pack,
          opener: makeOpener(dir, keys),
          googleAuth: googleAuth,
          driveBackupProvider: FakeBackupProvider(),
          drivePendingDeleteStore: FileDrivePendingDeleteStore(
            File('${dir.path}/drive_pending_delete.json'),
          ),
        );
        await s.start();
        return s;
      });
      final appState = state!;
      addTearDown(() async {
        await appState.session.repo?.close();
        appState.dispose();
      });

      expect(appState.status, DataStatus.ready);
      expect(appState.stage, SessionStage.ready);
      expect(appState.driveEnabled, isTrue);
      expect(googleAuth.signInSilentlyCalls, 0);
    });
  });
}
