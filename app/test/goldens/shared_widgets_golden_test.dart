// Golden mẫu cho hạ tầng golden (PR 0c). PR 3b thêm golden cho design_system (sáng/tối, 200%).
@Tags(['golden'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:wholewell/ui/common/common_widgets.dart';

import '../helpers/golden.dart';

Widget _frame(Widget child, Brightness brightness) => MaterialApp(
  debugShowCheckedModeBanner: false,
  theme: buildWholeWellTheme(brightness),
  home: Scaffold(
    body: Center(
      child: RepaintBoundary(key: const ValueKey('golden'), child: child),
    ),
  ),
);

void main() {
  for (final brightness in Brightness.values) {
    goldenTest('EnergyArcGauge ${brightness.name}', (tester) async {
      tester.view.physicalSize = const Size(400, 400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        _frame(const EnergyArcGauge(consumedKcal: 1150, targetKcal: 2000, hideCaloriesOverride: false), brightness),
      );
      await tester.pumpAndSettle();
      await expectLater(
        find.byKey(const ValueKey('golden')),
        matchesGoldenFile('energy_arc_gauge_${brightness.name}.png'),
      );
    });
  }
}
