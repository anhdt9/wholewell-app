/// Helper duy nhất để dựng app và màn hình trong test (docs/refactor-plan.md, mục 3.6).
///
/// Mọi test tạo trạng thái app bằng [testAppState] và dựng màn bằng [pumpApp] / [wrapApp] /
/// [pumpWholeWellApp]; không test nào tự dựng `AppScope` hay gọi `AppState.withRepository`.
/// Khi đổi kiến trúc (provider, go_router, ViewModel) chỉ sửa tệp này.
library;

import 'dart:io';

import 'package:dsld_library/dsld_library.dart';
import 'package:food_library/food_library.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:health_engine/health_engine.dart';
import 'package:journal_db/journal_db.dart';
import 'package:material_ui/material_ui.dart';
import 'package:wholewell/main.dart';
import 'package:wholewell/state/app_scope.dart';
import 'package:wholewell/state/app_state.dart';
import 'package:wholewell/ui/common/common_widgets.dart';

import 'a11y_exceptions.dart';

ReferencePack? _defaultPack;

/// Gói dữ liệu đi kèm app (`assets/reference_pack.json`), đọc một lần.
ReferencePack get testPack =>
    _defaultPack ??= ReferencePack.fromJsonString(File('assets/reference_pack.json').readAsStringSync());

/// Trạng thái app dùng nhật ký có sẵn (mặc định bản bộ nhớ) và bản giả cho mọi phần nền tảng.
AppState testAppState({
  ReferencePack? pack,
  JournalRepository? repo,
  FoodLibraryRepository? foodLibrary,
  DsldLibraryRepository? dsldLibrary,
  OcrEngine? ocrEngine,
  BarcodeScanner? barcodeScanner,
  NotificationScheduler? notificationScheduler,
  BackupFileProvider? backupFileProvider,
  GoogleAuth? googleAuth,
  BackupProvider? driveBackupProvider,
  DrivePendingDeleteStore? drivePendingDeleteStore,
}) => AppState.withRepository(
  pack: pack ?? testPack,
  repo: repo ?? InMemoryJournalRepository(),
  foodLibrary: foodLibrary,
  dsldLibrary: dsldLibrary,
  ocrEngine: ocrEngine,
  barcodeScanner: barcodeScanner,
  notificationScheduler: notificationScheduler,
  backupFileProvider: backupFileProvider,
  googleAuth: googleAuth,
  driveBackupProvider: driveBackupProvider,
  drivePendingDeleteStore: drivePendingDeleteStore,
);

/// Bọc [home] trong app với theme WholeWell (sáng hoặc tối) và cỡ chữ [textScale].
Widget wrapApp(AppState state, Widget home, {Brightness brightness = Brightness.light, double textScale = 1.0}) {
  return AppScope(
    state: state,
    child: MaterialApp(
      theme: buildWholeWellTheme(Brightness.light),
      darkTheme: buildWholeWellTheme(Brightness.dark),
      themeMode: brightness == Brightness.dark ? ThemeMode.dark : ThemeMode.light,
      builder: (ctx, child) => MediaQuery(
        data: MediaQuery.of(ctx).copyWith(textScaler: TextScaler.linear(textScale)),
        child: child!,
      ),
      home: home,
    ),
  );
}

/// Dựng [home] bằng [wrapApp]. Với [settle] (mặc định) chờ hết hoạt ảnh rồi kiểm trợ năng
/// ([expectA11yGuidelines]) cho màn đang hiện.
Future<void> pumpApp(
  WidgetTester tester,
  AppState state,
  Widget home, {
  Brightness brightness = Brightness.light,
  double textScale = 1.0,
  bool settle = true,
}) async {
  await tester.pumpWidget(wrapApp(state, home, brightness: brightness, textScale: textScale));
  if (!settle) return;
  await tester.pumpAndSettle();
  await expectA11yGuidelines(tester);
}

/// Dựng cả app như khi chạy thật (màn gốc do trạng thái phiên quyết định).
Future<void> pumpWholeWellApp(WidgetTester tester, AppState state, {double? textScale}) => tester.pumpWidget(
  textScale == null
      ? WholeWellApp(state: state)
      : MediaQuery(
          data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
          child: WholeWellApp(state: state),
        ),
);

/// Khung điện thoại [size] (dp) với mật độ điểm ảnh 1; tự trả lại sau test.
void usePhoneViewport(WidgetTester tester, {Size size = const Size(360, 800)}) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}

/// Tên màn đang hiện: widget đầu tiên (theo thứ tự duyệt cây) có tên kết thúc bằng `Screen` hoặc `Flow`.
String currentScreenName(WidgetTester tester) {
  final screens = find.byWidgetPredicate((w) {
    final name = w.runtimeType.toString();
    return name.endsWith('Screen') || name.endsWith('Flow');
  });
  final elements = screens.evaluate();
  return elements.isEmpty ? '?' : elements.first.widget.runtimeType.toString();
}

/// Kiểm 3 hướng dẫn trợ năng của Flutter cho màn đang hiện, trừ những hướng dẫn màn đó còn
/// nằm trong [a11yExceptions] (danh sách chỉ được giảm).
///
/// Đặt biến môi trường `A11Y_DISCOVER=<tệp>` thì chỉ ghi các cặp chưa đạt vào tệp đó, không làm test
/// hỏng (dùng khi lập lại danh sách).
Future<void> expectA11yGuidelines(WidgetTester tester) async {
  final screen = currentScreenName(tester);
  final skipped = a11yExceptions[screen] ?? const <A11yGuideline>{};
  final discoverFile = Platform.environment['A11Y_DISCOVER'];
  final handle = tester.ensureSemantics();
  try {
    final failures = <String>[];
    for (final g in A11yGuideline.values) {
      if (skipped.contains(g)) continue;
      final result = await g.guideline.evaluate(tester);
      if (result.passed) continue;
      if (discoverFile != null) {
        File(discoverFile).writeAsStringSync('$screen ${g.name}\n', mode: FileMode.append);
      } else {
        failures.add('${g.name}: ${result.reason}');
      }
    }
    if (failures.isNotEmpty) fail('Màn $screen chưa đạt trợ năng:\n${failures.join('\n')}');
  } finally {
    handle.dispose();
  }
}
