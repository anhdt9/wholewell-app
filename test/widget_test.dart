// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wholewell/app/app.dart';

void main() {
  testWidgets('WholeWell app loads without errors', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    // Note: A full integration test would require proper database initialization.
    // This is a basic smoke test to verify the app widget loads.
    await tester.pumpWidget(
      const ProviderScope(
        child: WholeWellApp(),
      ),
    );

    // Verify the app loaded without crashing.
    expect(find.byType(WholeWellApp), findsOneWidget);
  });
}
