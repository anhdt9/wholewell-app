/// Hạ tầng golden test (docs/refactor-plan.md, mục 3.6).
///
/// - Tệp golden gắn `@Tags(['golden'])` và gọi [goldenTest]; ảnh mẫu nằm trong `test/goldens/`.
/// - Chỉ chạy trên Linux (CI), vì cách vẽ chữ khác nhau giữa các hệ điều hành; Windows, macOS bỏ qua.
/// - Ảnh mẫu sinh trên CI: chạy workflow CI bằng tay (workflow_dispatch) với `update_goldens`,
///   tải artifact `goldens` về `app/test/goldens/` rồi commit.
/// - Nạp font BeVietnamPro của app ở đây, không ở `flutter_test_config.dart`: nạp cho mọi test làm
///   đổi kích thước chữ so với font Ahem mặc định, và 4 test bố cục hiện có hỏng (ghi ở status.md).
library;

import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

bool _fontsLoaded = false;

/// Nạp font của app một lần cho isolate của tệp test.
Future<void> loadAppFonts() async {
  if (_fontsLoaded) return;
  final loader = FontLoader('BeVietnamPro');
  for (final weight in ['Regular', 'Medium', 'SemiBold', 'Bold']) {
    final bytes = File('assets/fonts/BeVietnamPro-$weight.ttf').readAsBytesSync();
    loader.addFont(Future.value(ByteData.sublistView(bytes)));
  }
  await loader.load();
  _fontsLoaded = true;
}

/// `testWidgets` cho golden: bỏ qua ngoài Linux, nạp font của app trước khi chạy.
void goldenTest(String description, WidgetTesterCallback callback) {
  testWidgets(description, (tester) async {
    await loadAppFonts();
    await callback(tester);
  }, skip: !Platform.isLinux);
}
