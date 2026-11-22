import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

// CSDL và khóa không được vào sao lưu tự động của Android (docs/specs/encrypted-db.md).
void main() {
  const domains = ['root', 'file', 'database', 'sharedpref', 'external'];

  test('AndroidManifest tắt sao lưu tự động', () {
    final m = File('android/app/src/main/AndroidManifest.xml').readAsStringSync();
    expect(m, contains('android:allowBackup="false"'));
    expect(m, contains('android:fullBackupContent="false"'));
    expect(m, contains('android:dataExtractionRules="@xml/data_extraction_rules"'));
  });

  test('data_extraction_rules loại trừ mọi miền cho cả sao lưu đám mây và chuyển thiết bị', () {
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
}
