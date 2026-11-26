import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:health_engine/health_engine.dart';
import 'package:journal_db/journal_db.dart';
import 'package:material_ui/material_ui.dart';
import 'package:wholewell/main.dart';
import 'package:wholewell/state/app_state.dart';
import 'package:wholewell/ui/confirm_ingredients_screen.dart';
import 'package:wholewell/ui/privacy_policy_screen.dart';
import 'package:wholewell/ui/privacy_policy_text.dart';

void main() {
  group('Cổng 2: Kiểm toán quyền riêng tư, cấu hình Android, Kotlin & Chính sách quyền riêng tư', () {
    test('kPrivacyPolicyMarkdown khớp hoàn toàn với docs/privacy-policy.md và đủ thông tin liên hệ', () {
      final docsPolicy = File('../docs/privacy-policy.md').readAsStringSync().replaceAll('\r\n', '\n');
      expect(kPrivacyPolicyMarkdown, docsPolicy);
      expect(kPrivacyPolicyMarkdown, contains('Đặng Thế Anh'));
      expect(kPrivacyPolicyMarkdown, contains('wholewell.apps@gmail.com'));
      expect(kPrivacyPolicyMarkdown, contains('drive.appdata'));
    });

    test('pubspec.yaml không chứa SDK quảng cáo, phân tích hành vi hay báo lỗi bên thứ ba', () {
      final pubspec = File('pubspec.yaml').readAsStringSync().toLowerCase();
      for (final forbidden in [
        'google_mobile_ads',
        'admob',
        'firebase_analytics',
        'firebase_crashlytics',
        'sentry',
        'appsflyer',
        'mixpanel',
        'amplitude',
      ]) {
        expect(pubspec.contains(forbidden), isFalse, reason: 'Không được nhúng $forbidden trong MVP');
      }
    });

    test('AndroidManifest.xml và toàn bộ mã nguồn Kotlin không rò dữ liệu sức khỏe hay xin quyền ngoài phạm vi', () {
      final manifest = File('android/app/src/main/AndroidManifest.xml').readAsStringSync();
      expect(manifest, contains('android:allowBackup="false"'));
      expect(manifest, contains('android:fullBackupContent="false"'));
      for (final forbiddenPerm in [
        'READ_EXTERNAL_STORAGE',
        'WRITE_EXTERNAL_STORAGE',
        'ACCESS_FINE_LOCATION',
        'ACCESS_COARSE_LOCATION',
        'READ_PHONE_STATE',
        'READ_CONTACTS',
      ]) {
        expect(manifest.contains(forbiddenPerm), isFalse, reason: 'Không xin quyền $forbiddenPerm');
      }

      final kotlinFiles = Directory('android/app/src/main/kotlin')
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.kt'))
          .toList()
        ..sort((a, b) => a.path.compareTo(b.path));
      final basenames = kotlinFiles.map((f) => f.uri.pathSegments.last).toSet();
      expect(
        basenames,
        containsAll([
          'MainActivity.kt',
          'LabelGenAiExtractor.kt',
          'ReminderLogic.kt',
          'ReminderReceiver.kt',
          'ReminderScheduler.kt',
          'BackupFileChannel.kt',
          'DbKeyRules.kt',
          'DbKeyStore.kt',
        ]),
      );

      final logLinePattern = RegExp(r'\b(?:Log\.[vdiew]|println|print)\s*\((.*)\)');
      final sensitiveLogTokens = RegExp(r'\b(ocrText|productName|nutrient|dose|plain|key|wrapped)\b');

      for (final file in kotlinFiles) {
        final content = file.readAsStringSync();
        // Bỏ comment // và /* ... */ khi kiểm tra từ khóa API/quyền (giữ nguyên cho kiểm tra log).
        final codeOnly = content
            .replaceAll(RegExp(r'/\*[\s\S]*?\*/'), '')
            .replaceAll(RegExp(r'//.*$', multiLine: true), '')
            .toLowerCase();
        for (final forbidden in [
          'http://',
          'https://',
          'okhttp',
          'retrofit',
          'firebase',
          'crashlytics',
          'admob',
          'google_mobile_ads',
          'healthconnect',
          'read_external_storage',
          'write_external_storage',
          'access_fine_location',
          'read_contacts',
          'read_phone_state',
        ]) {
          expect(
            codeOnly.contains(forbidden),
            isFalse,
            reason: '${file.path} không được chứa $forbidden',
          );
        }

        for (final match in logLinePattern.allMatches(content)) {
          final logArgs = match.group(1) ?? '';
          expect(
            sensitiveLogTokens.hasMatch(logArgs),
            isFalse,
            reason: '${file.path} không được log dữ liệu nhạy cảm: $logArgs',
          );
        }
      }

      final reminderLogic =
          File('android/app/src/main/kotlin/vn/wholewell/app/ReminderLogic.kt').readAsStringSync();
      expect(reminderLogic, contains('Đến giờ uống'));
      expect(reminderLogic.toLowerCase(), isNot(contains('productname')));
      expect(reminderLogic.toLowerCase(), isNot(contains('nutrient')));

      final dbKeyStore =
          File('android/app/src/main/kotlin/vn/wholewell/app/DbKeyStore.kt').readAsStringSync();
      expect(dbKeyStore, contains('setUnlockedDeviceRequired(true)'));
      expect(dbKeyStore, contains('noBackupFilesDir'));
    });

    testWidgets('Màn Đồng ý (2/4) dùng đúng chữ "Tôi → Quyền riêng tư" và mở tức thì Chính sách quyền riêng tư offline',
        (tester) async {
      final pack = ReferencePack.fromJsonString(File('assets/reference_pack.json').readAsStringSync());
      final dir = Directory.systemTemp.createTempSync('ww_gate2_consent_');
      addTearDown(() {
        if (dir.existsSync()) dir.deleteSync(recursive: true);
      });
      final opener = DbOpener(
        files: DbFiles(dir),
        keys: FakeSecureKeyStore(),
        executorFactory: sameIsolateExecutor,
        retryDelay: Duration.zero,
      );
      final state = AppState(pack: pack, opener: opener);
      await tester.runAsync(state.start);
      addTearDown(() async {
        await state.session.repo?.close();
        state.dispose();
      });

      await tester.pumpWidget(WholeWellApp(state: state));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Bắt đầu'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), '25');
      await tester.tap(find.text('Không').first);
      await tester.tap(find.text('Không').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Tiếp tục'));
      await tester.pumpAndSettle();

      expect(find.textContaining('xóa ở Tôi → Quyền riêng tư'), findsOneWidget);
      await tester.tap(find.text('Chính sách quyền riêng tư'));
      await tester.pumpAndSettle();

      expect(find.byType(PrivacyPolicyScreen), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.textContaining('wholewell.apps@gmail.com'), findsOneWidget);
    });

    testWidgets('Tôi -> Quyền riêng tư -> Chính sách quyền riêng tư mở tức thì đọc toàn văn offline',
        (tester) async {
      final pack = ReferencePack.fromJsonString(File('assets/reference_pack.json').readAsStringSync());
      final repo = InMemoryJournalRepository();
      await repo.saveProfile(const Profile(
        ageYears: 30,
        sex: Sex.female,
        heightCm: 160,
        weightKg: 54,
        activityLevel: ActivityLevel.active,
      ));
      await repo.saveHideCalories(false);
      final state = AppState.withRepository(pack: pack, repo: repo);
      await tester.runAsync(state.reload);
      addTearDown(() async {
        await repo.close();
        state.dispose();
      });

      await tester.pumpWidget(WholeWellApp(state: state));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Tôi'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Quyền riêng tư'));
      await tester.pumpAndSettle();

      final policyBtn = find.text('Chính sách quyền riêng tư');
      await tester.ensureVisible(policyBtn);
      await tester.pumpAndSettle();
      await tester.tap(policyBtn);
      await tester.pumpAndSettle();

      expect(find.byType(PrivacyPolicyScreen), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.textContaining('Đặng Thế Anh'), findsWidgets);
    });

    testWidgets('Mọi dòng OCR chưa confirmed không bao giờ được lưu vào ingredients hay dose_entries',
        (tester) async {
      final pack = ReferencePack.fromJsonString(File('assets/reference_pack.json').readAsStringSync());
      final parsed = SupplementLabelParser.parsePackage(const [
        'Vitamin C 500 mg',
        'Zinc Gluconate 50 mg',
      ]);
      expect(parsed.ingredients, hasLength(2));
      for (final line in parsed.ingredients) {
        expect(EditableIngredient.fromParsed(line, pack).confirmed, isFalse);
      }

      final repo = InMemoryJournalRepository();
      await repo.saveProfileWithCaution(
        const Profile(
          ageYears: 30,
          sex: Sex.male,
          heightCm: 170,
          weightKg: 65,
          activityLevel: ActivityLevel.inactive,
        ),
        caution: false,
      );
      await repo.saveHideCalories(false);
      await repo.saveOnboardingStep(OnboardingStep.done);

      final ocr = FakeOcrEngine(
        nextGalleryResult: const OcrImagePickResult(paths: ['/fake/label.jpg']),
        nextOcrResult: const OcrLabelResult(lines: [
          'Vitamin C 500 mg',
          'Zinc Gluconate 50 mg',
        ]),
      );
      final state = AppState.withRepository(
        pack: pack,
        repo: repo,
        ocrEngine: ocr,
        barcodeScanner: FakeBarcodeScanner(),
      );
      await tester.runAsync(state.start);
      addTearDown(() async {
        await repo.close();
        state.dispose();
      });

      await tester.pumpWidget(WholeWellApp(state: state));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Bổ sung'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Thêm sản phẩm'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Chọn ảnh từ thư viện'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Đọc thông tin từ 1 ảnh'));
      await tester.pumpAndSettle();

      expect(find.byType(ConfirmIngredientsScreen), findsOneWidget);
      expect(find.text('Tiếp tục (0/2 đã xác nhận)'), findsOneWidget);
      FilledButton continueBtn() => tester.widget<FilledButton>(
            find.ancestor(of: find.textContaining('Tiếp tục ('), matching: find.byType(FilledButton)),
          );
      expect(continueBtn().onPressed, isNull);

      // Xác nhận mới 1/2 dòng -> nút Tiếp tục vẫn khóa.
      await tester.tap(find.byType(Checkbox).first);
      await tester.pumpAndSettle();
      expect(find.text('Tiếp tục (1/2 đã xác nhận)'), findsOneWidget);
      expect(continueBtn().onPressed, isNull);

      // Quay lại mà không xác nhận đủ -> 0 sản phẩm, 0 thành phần, 0 dose_entries trong CSDL.
      await tester.pageBack();
      await tester.pumpAndSettle();

      final savedProducts = await tester.runAsync(() => repo.listProducts(includeArchived: true));
      final savedDoses = await tester.runAsync(
        () => repo.dosesBetween('2020-01-01', '2030-12-31'),
      );
      expect(savedProducts, isEmpty);
      expect(savedDoses, isEmpty);
    });
  });
}
