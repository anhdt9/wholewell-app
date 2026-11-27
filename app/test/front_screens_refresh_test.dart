import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:health_engine/health_engine.dart';
import 'package:journal_db/journal_db.dart';
import 'package:material_ui/material_ui.dart';
import 'package:wholewell/main.dart';
import 'package:wholewell/state/app_scope.dart';
import 'package:wholewell/state/app_state.dart';
import 'package:wholewell/ui/common/common_widgets.dart';
import 'package:wholewell/ui/nutrient_detail_screen.dart';

Future<AppState> _makeState(ReferencePack pack, {bool hideCalories = false}) async {
  final repo = InMemoryJournalRepository();
  final state = AppState.withRepository(pack: pack, repo: repo);
  await state.start();
  await state.completeFirstConsent(ageYears: 30, caution: false);
  await state.saveOnboardingBodyProfile(const Profile(
    ageYears: 30,
    sex: Sex.female,
    heightCm: 160,
    weightKg: 55,
    activityLevel: ActivityLevel.active,
  ));
  await state.setHideCalories(hideCalories);
  return state;
}

void main() {
  final pack = ReferencePack.fromJsonString(
    File('assets/reference_pack.json').readAsStringSync(),
  );

  testWidgets('HomeScreen DaySwitcher pill chuyển ngày trước/sau và không tràn ở cỡ chữ 200%', (tester) async {
    final state = await _makeState(pack);
    addTearDown(state.dispose);

    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(textScaler: TextScaler.linear(2.0)),
        child: WholeWellApp(state: state),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('Hôm nay,'), findsOneWidget);
    await tester.tap(find.byTooltip('Ngày trước'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Hôm qua,'), findsOneWidget);

    await tester.tap(find.byTooltip('Ngày sau'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Hôm nay,'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('TodayScreen dùng EnergyArcGauge + TargetRangeBar và ẩn calo chuyển 3 cột macro', (tester) async {
    final state = await _makeState(pack, hideCalories: false);
    addTearDown(state.dispose);

    await state.addItem(
      const IntakeItem(
        label: 'Phở bò',
        source: IntakeSource.food,
        meal: MealSlot.lunch,
        nutrients: {'energyKcal': 450, 'protein_g': 25, 'fat_g': 12, 'carb_g': 55},
      ),
    );

    await tester.pumpWidget(WholeWellApp(state: state));
    await tester.pumpAndSettle();

    expect(find.byType(EnergyArcGauge), findsOneWidget);
    expect(find.byType(TargetRangeBar), findsNWidgets(3));

    await state.setHideCalories(true);
    await tester.pumpAndSettle();

    expect(find.byType(EnergyArcGauge), findsNothing);
    expect(find.text('Năng lượng'), findsNothing);
    expect(find.byType(TargetRangeBar), findsNWidgets(3));
  });

  testWidgets('NutrientDetailScreen biểu đồ 7 ngày hiện đường Giới hạn an toàn khi đạt >= 70% UL', (tester) async {
    final state = await _makeState(pack);
    addTearDown(state.dispose);

    // UL magie bổ sung = 350 mg; 260 mg > 70% UL (245 mg).
    await state.recordDose(
      'Magie 260',
      const [
        IntakeLine(
          nutrientId: 'magnesium',
          source: IntakeSource.supplement,
          form: 'magnesium_citrate',
          amounts: {'magnesium': 260},
        ),
      ],
    );

    await tester.pumpWidget(
      AppScope(
        state: state,
        child: MaterialApp(
          theme: buildWholeWellTheme(Brightness.dark),
          home: const NutrientDetailScreen(nutrientId: 'magnesium'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('7 ngày'));
    await tester.pumpAndSettle();

    expect(find.text('7 ngày qua'), findsOneWidget);
    expect(find.textContaining('Mức khuyến nghị ('), findsOneWidget);
    expect(find.textContaining('Giới hạn an toàn (350 mg)'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
