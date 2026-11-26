import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:health_engine/health_engine.dart';
import 'package:journal_db/journal_db.dart';
import 'package:material_ui/material_ui.dart';
import 'package:wholewell/main.dart';
import 'package:wholewell/state/app_state.dart';
import 'package:wholewell/ui/privacy_policy_screen.dart';

Future<void> _waitPolicyLoaded(WidgetTester tester) async {
  for (var i = 0; i < 40; i++) {
    await tester.pump();
    if (find.byType(CircularProgressIndicator).evaluate().isEmpty) break;
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
  }
  expect(find.byType(CircularProgressIndicator), findsNothing);
  await tester.pumpAndSettle();
}

void main() {
  group('Cổng 2: Kiểm toán quyền riêng tư, cấu hình Android & Chính sách quyền riêng tư', () {
    test('assets/privacy_policy.md khớp hoàn toàn với docs/privacy-policy.md và đủ thông tin liên hệ', () {
      final assetPolicy = File('assets/privacy_policy.md').readAsStringSync();
      final docsPolicy = File('../docs/privacy-policy.md').readAsStringSync();
      expect(assetPolicy, docsPolicy);
      expect(assetPolicy, contains('Đặng Thế Anh'));
      expect(assetPolicy, contains('wholewell.apps@gmail.com'));
      expect(assetPolicy, contains('drive.appdata'));
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

    test('AndroidManifest.xml và ReminderLogic.kt tuân thủ bảo mật quyền riêng tư', () {
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

      final reminderLogic =
          File('android/app/src/main/kotlin/vn/wholewell/app/ReminderLogic.kt').readAsStringSync();
      expect(reminderLogic, contains('Đến giờ uống'));
      expect(reminderLogic.toLowerCase(), isNot(contains('productname')));
      expect(reminderLogic.toLowerCase(), isNot(contains('nutrient')));
    });

    testWidgets('Màn Đồng ý (2/4) dùng đúng chữ "Tôi → Quyền riêng tư" và mở được Chính sách quyền riêng tư offline',
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

      // Kiểm tra chữ mới & mở Chính sách quyền riêng tư offline.
      expect(find.textContaining('xóa ở Tôi → Quyền riêng tư'), findsOneWidget);
      await tester.tap(find.text('Chính sách quyền riêng tư'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));
      expect(find.byType(PrivacyPolicyScreen), findsOneWidget);
      await _waitPolicyLoaded(tester);
      expect(find.textContaining('wholewell.apps@gmail.com'), findsOneWidget);
    });

    testWidgets('Tôi -> Quyền riêng tư -> Chính sách quyền riêng tư mở đọc toàn văn offline',
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
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));
      expect(find.byType(PrivacyPolicyScreen), findsOneWidget);
      await _waitPolicyLoaded(tester);

      expect(find.byType(PrivacyPolicyScreen), findsOneWidget);
      expect(find.textContaining('Đặng Thế Anh'), findsWidgets);
    });
  });
}
