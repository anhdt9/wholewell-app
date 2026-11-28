// Thư viện `package:journal_db/models.dart` chỉ chứa model (docs/refactor-plan.md, mục 3.3):
// không kéo theo CSDL, repository hay sao lưu.
import 'dart:io';

import 'package:test/test.dart';

void main() {
  test('models.dart chỉ export src/models.dart', () {
    final lib = File('lib/models.dart').readAsStringSync();
    final directives = RegExp(
      r'''^\s*(import|export)\s+['"]([^'"]+)['"]''',
      multiLine: true,
    ).allMatches(lib).map((m) => '${m[1]} ${m[2]}').toList();
    expect(directives, ['export src/models.dart']);
  });

  test('src/models.dart chỉ phụ thuộc dart:* và health_engine', () {
    final src = File('lib/src/models.dart').readAsStringSync();
    final imports = RegExp(
      r'''^\s*(?:import|export)\s+['"]([^'"]+)['"]''',
      multiLine: true,
    ).allMatches(src).map((m) => m[1]!).toList();
    for (final uri in imports) {
      expect(
        uri.startsWith('dart:') || uri.startsWith('package:health_engine/'),
        isTrue,
        reason: 'models.dart không được import $uri',
      );
    }
  });
}
