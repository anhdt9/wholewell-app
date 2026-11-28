// Test kiểm toán luật phụ thuộc (docs/refactor-plan.md, mục 3.3 và 3.6).
//
// Mỗi danh sách vi phạm **chỉ được giảm**: thêm vi phạm mới thì test hỏng; sửa xong một tệp mà
// chưa xóa nó khỏi danh sách thì test cũng hỏng, để danh sách luôn đúng với code.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'helpers/a11y_exceptions.dart';

/// Tệp UI còn cần thứ ngoài model của `journal_db` (sao lưu, mã hóa tệp). Chuyển ở GĐ6.
const _uiFullJournalDbAllowed = {'lib/ui/backup_restore_screen.dart', 'lib/ui/drive_backup_screens.dart'};

/// Tệp UI còn gọi thẳng plugin nền tảng. `mobile_scanner` chuyển sang `BarcodeService` ở PR 4b.
const _uiPlatformAllowed = {'lib/ui/supplements_screen.dart'};

/// Trần của `maxA11yExceptions` lúc lập danh sách (29/11/2026). Chỉ được giảm.
const _a11yCeiling = 4;

final _journalDbFull = RegExp(
  r'''^\s*(import|export)\s+['"]package:journal_db/journal_db\.dart['"]''',
  multiLine: true,
);
final _platformImport = RegExp(
  r'''^\s*import\s+['"]package:(mobile_scanner|google_mlkit_[a-z_]+|image_picker)/''',
  multiLine: true,
);
final _channel = RegExp(r'\b(MethodChannel|EventChannel|BasicMessageChannel)\b');

Iterable<File> _dartFiles(String dir) =>
    Directory(dir).listSync(recursive: true).whereType<File>().where((f) => f.path.endsWith('.dart'));

String _rel(File f) => f.path.replaceAll(r'\', '/').replaceFirst(RegExp(r'^\./'), '');

Set<String> _violations(String dir, bool Function(String source) violates) => {
  for (final f in _dartFiles(dir))
    if (violates(f.readAsStringSync())) _rel(f),
};

void _expectOnlyShrinks(Set<String> actual, Set<String> allowed, String rule) {
  final added = actual.difference(allowed);
  final fixed = allowed.difference(actual);
  expect(added, isEmpty, reason: 'Vi phạm mới ($rule): $added');
  expect(fixed, isEmpty, reason: 'Đã hết vi phạm ($rule), xóa khỏi danh sách: $fixed');
}

void main() {
  test('UI chỉ import package:journal_db/models.dart, trừ danh sách vi phạm', () {
    _expectOnlyShrinks(
      _violations('lib/ui', _journalDbFull.hasMatch),
      _uiFullJournalDbAllowed,
      'UI import journal_db.dart',
    );
  });

  test('UI không gọi thẳng plugin nền tảng hay channel, trừ danh sách vi phạm', () {
    _expectOnlyShrinks(
      _violations('lib/ui', (s) => _platformImport.hasMatch(s) || _channel.hasMatch(s)),
      _uiPlatformAllowed,
      'UI gọi plugin nền tảng',
    );
  });

  test('không re-export journal_db.dart để lách luật', () {
    final reexports = {
      for (final dir in ['lib', '../packages/food_library/lib', '../packages/dsld_library/lib'])
        for (final f in _dartFiles(dir))
          if (RegExp(r'''^\s*export\s+['"]package:journal_db/''', multiLine: true).hasMatch(f.readAsStringSync()))
            _rel(f),
    };
    expect(reexports, isEmpty);
  });

  test('chỉ test/helpers/pump_app.dart dựng AppScope và gọi AppState.withRepository', () {
    final offenders = {
      for (final f in _dartFiles('test'))
        if (!_rel(f).endsWith('test/helpers/pump_app.dart') && !_rel(f).endsWith('test/architecture_rules_test.dart'))
          if (RegExp(r'\bAppScope\(|AppState\.withRepository\(').hasMatch(f.readAsStringSync())) _rel(f),
    };
    expect(offenders, isEmpty, reason: 'Dùng testAppState / pumpApp / wrapApp trong test/helpers/pump_app.dart');
  });

  test('danh sách ngoại lệ trợ năng chỉ được giảm', () {
    final total = a11yExceptions.values.fold<int>(0, (n, s) => n + s.length);
    expect(total, maxA11yExceptions, reason: 'maxA11yExceptions phải bằng số cặp (màn, hướng dẫn) đang miễn');
    expect(maxA11yExceptions, lessThanOrEqualTo(_a11yCeiling));
    for (final entry in a11yExceptions.entries) {
      expect(entry.value, isNotEmpty, reason: 'Xóa dòng rỗng ${entry.key}');
    }
  });
}
