import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

// Cấu hình Android và phụ thuộc của CSDL mã hóa (docs/specs/encrypted-db.md, Tiêu chí đạt).
void main() {
  const domains = ['root', 'file', 'database', 'sharedpref', 'external'];

  test('AndroidManifest tắt sao lưu tự động, dùng quy tắc loại khỏi sao lưu và chuyển máy', () {
    final m = File('android/app/src/main/AndroidManifest.xml').readAsStringSync();
    expect(m, contains('android:allowBackup="false"'));
    expect(m, contains('android:fullBackupContent="false"'));
    expect(m, contains('android:dataExtractionRules="@xml/data_extraction_rules"'));
  });

  test('data_extraction_rules loại mọi miền cho cả sao lưu đám mây và chuyển máy', () {
    final x = File('android/app/src/main/res/xml/data_extraction_rules.xml').readAsStringSync();
    for (final section in ['cloud-backup', 'device-transfer']) {
      final body = RegExp('<$section>(.*?)</$section>', dotAll: true).firstMatch(x)?.group(1);
      expect(body, isNotNull, reason: 'thiếu <$section>');
      for (final d in domains) {
        expect(body, contains('<exclude domain="$d" />'), reason: '$section thiếu $d');
      }
      expect(body, isNot(contains('<include')));
    }
  });

  test('minSdk = 28 (setUnlockedDeviceRequired)', () {
    final g = File('android/app/build.gradle.kts').readAsStringSync();
    expect(RegExp(r'^\s*minSdk = 28\s*$', multiLine: true).hasMatch(g), isTrue);
  });

  test('khóa Android dùng setUnlockedDeviceRequired, không dùng flutter_secure_storage', () {
    final kt = File('android/app/src/main/kotlin/vn/wholewell/app/DbKeyStore.kt').readAsStringSync();
    expect(kt, contains('setUnlockedDeviceRequired(true)'));
    expect(kt, isNot(contains('Log.')));
    final pubspec = File('pubspec.yaml').readAsStringSync();
    expect(pubspec, isNot(contains('flutter_secure_storage')));
    expect(pubspec, isNot(contains('sqlite3_flutter_libs')));
    expect(RegExp(r'sqlite3:\s*\n\s*source: sqlite3mc').hasMatch(pubspec), isTrue);
  });
}
