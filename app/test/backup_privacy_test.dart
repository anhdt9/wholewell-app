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
      final tables = exported['tables'] as Map<String, Object?>;
      expect((tables['water_entries'] as List).length, 1);

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
}
