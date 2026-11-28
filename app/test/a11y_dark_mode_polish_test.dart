import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:food_library/food_library.dart';
import 'package:health_engine/health_engine.dart';
import 'package:journal_db/journal_db.dart';
import 'package:material_ui/material_ui.dart';
import 'package:wholewell/state/app_scope.dart';
import 'package:wholewell/state/app_state.dart';
import 'package:wholewell/ui/common/common_widgets.dart';
import 'package:wholewell/ui/common/log_sheet.dart';
import 'package:wholewell/ui/confirm_ingredients_screen.dart';
import 'package:wholewell/ui/diary_screen.dart';
import 'package:wholewell/ui/food_portion_screen.dart';
import 'package:wholewell/ui/home_screen.dart';
import 'package:wholewell/ui/me_screen.dart';
import 'package:wholewell/ui/nutrient_detail_screen.dart';
import 'package:wholewell/ui/onboarding_flow.dart';
import 'package:wholewell/ui/supplements_screen.dart';

Future<AppState> _makeState(ReferencePack pack, {bool caution = false, bool hideCalories = false}) async {
  final repo = InMemoryJournalRepository();
  final state = AppState.withRepository(pack: pack, repo: repo);
  await state.start();
  await state.completeFirstConsent(ageYears: 30, caution: caution);
  const profile = Profile(
    ageYears: 30,
    sex: Sex.female,
    heightCm: 160,
    weightKg: 55,
    activityLevel: ActivityLevel.active,
  );
  await state.saveOnboardingBodyProfile(profile);
  if (caution) {
    await state.saveProfileFromSettings(profile, caution: true);
  }
  await state.setHideCalories(hideCalories);
  return state;
}

Widget _wrapA11y(
  AppState state,
  Widget child, {
  Brightness brightness = Brightness.light,
  Size size = const Size(360, 800),
  double textScale = 2.0,
}) {
  return MediaQuery(
    data: MediaQueryData(size: size, textScaler: TextScaler.linear(textScale)),
    child: AppScope(
      state: state,
      child: MaterialApp(
        theme: buildWholeWellTheme(Brightness.light),
        darkTheme: buildWholeWellTheme(Brightness.dark),
        themeMode: brightness == Brightness.dark ? ThemeMode.dark : ThemeMode.light,
        home: child,
      ),
    ),
  );
}

void _usePhoneViewport(WidgetTester tester, {Size size = const Size(360, 800)}) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}

void main() {
  final pack = ReferencePack.fromJsonString(File('assets/reference_pack.json').readAsStringSync());

  group('PR 5 A11y 200% & Dark Mode', () {
    testWidgets('HomeScreen DaySwitcher >= 40x44 và TodayScreen trống không tràn ở 360dp 200% Light & Dark', (
      tester,
    ) async {
      _usePhoneViewport(tester);
      final state = await _makeState(pack);
      addTearDown(state.dispose);

      for (final brightness in [Brightness.light, Brightness.dark]) {
        await tester.pumpWidget(_wrapA11y(state, const HomeScreen(), brightness: brightness));
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        final prevSize = tester.getSize(find.byTooltip('Ngày trước'));
        final nextSize = tester.getSize(find.byTooltip('Ngày sau'));
        expect(prevSize.width, greaterThanOrEqualTo(40));
        expect(prevSize.height, greaterThanOrEqualTo(44));
        expect(nextSize.width, greaterThanOrEqualTo(40));
        expect(nextSize.height, greaterThanOrEqualTo(44));
      }
    });

    testWidgets('TodayScreen đủ dữ liệu (UL, thận trọng, đường > 10g, lịch, nước, ẩn calo) không tràn ở Dark 200%', (
      tester,
    ) async {
      _usePhoneViewport(tester);
      final state = await _makeState(pack, caution: true, hideCalories: false);
      addTearDown(state.dispose);

      await state.addItem(
        IntakeItem(
          label: 'Trà sữa trân châu đường đen',
          source: IntakeSource.food,
          meal: MealSlot.lunch,
          at: DateTime(state.day.year, state.day.month, state.day.day, 12, 30),
          nutrients: const {
            'energyKcal': 480,
            'protein_g': 6,
            'fat_g': 16,
            'carb_g': 78,
            'addedSugar_g': 24,
            'iron': 1.2,
          },
        ),
      );
      await state.recordDose('Magie Citrate liều cao', const [
        IntakeLine(
          nutrientId: 'magnesium',
          source: IntakeSource.supplement,
          form: 'magnesium_citrate',
          amounts: {'magnesium': 400},
        ),
      ]);
      await state.diary.addWater(state.day, 250);
      final pid = await state.diary.createProductWithIngredientsAndBox(
        name: 'Vitamin D3 1000 IU',
        countUnit: CountUnit.softgel,
        unitsPerServing: 1,
        ingredients: const [],
        initialBoxRemaining: 10,
      );
      final nowMinutes = DateTime.now().hour * 60 + DateTime.now().minute;
      await state.diary.addSchedule(pid!, nowMinutes, 1, validFrom: dayKey(state.day));

      await tester.pumpWidget(_wrapA11y(state, const HomeScreen(), brightness: Brightness.dark));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Vượt giới hạn an toàn'), findsOneWidget);

      await state.setHideCalories(true);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.byType(EnergyArcGauge), findsNothing);
    });

    testWidgets('NutrientDetailScreen (Hôm nay & 7 ngày) ở 360dp 200% Dark Mode với nhãn đầy đủ không tràn', (
      tester,
    ) async {
      _usePhoneViewport(tester);
      final state = await _makeState(pack, caution: true);
      addTearDown(state.dispose);

      await state.recordDose('Magie bổ sung', const [
        IntakeLine(
          nutrientId: 'magnesium',
          source: IntakeSource.supplement,
          form: 'magnesium_citrate',
          amounts: {'magnesium': 280},
        ),
      ]);

      await tester.pumpWidget(
        _wrapA11y(state, const NutrientDetailScreen(nutrientId: 'magnesium'), brightness: Brightness.dark),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      await tester.ensureVisible(find.text('7 ngày'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('7 ngày'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.dragUntilVisible(find.text('7 ngày qua'), find.byType(ListView), const Offset(0, -300));
      await tester.pumpAndSettle();
      expect(find.text('7 ngày qua'), findsOneWidget);
      await tester.dragUntilVisible(
        find.textContaining('Mức tham chiếu ('),
        find.byType(ListView),
        const Offset(0, -300),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.textContaining('Mức tham chiếu ('), findsOneWidget);
      expect(find.textContaining('Giới hạn an toàn (350 mg)'), findsOneWidget);
    });

    testWidgets('FoodPortionScreen ở màn thấp 360x640 và 200% Dark Mode cuộn toàn trang không tràn', (tester) async {
      const smallPhone = Size(360, 640);
      _usePhoneViewport(tester, size: smallPhone);
      final state = await _makeState(pack);
      addTearDown(state.dispose);

      const food = FoodDetail(
        id: 'pho_1',
        kind: FoodKind.usdaFoundation,
        nameVi: 'Phở bò tái chín',
        nameEn: 'Beef pho',
        isEstimate: false,
        addedSugarKnown: true,
        niacinFortifiedUnseparated: false,
        folateUnseparated: false,
        defaultPortionId: 'bowl',
        portions: [FoodPortion(id: 'bowl', labelVi: '1 tô vừa', grams: 500)],
        nutrientsPer100g: [
          FoodNutrientPer100g(nutrientId: 'energyKcal', source: IntakeSource.food, amount: 90, unit: 'kcal'),
          FoodNutrientPer100g(nutrientId: 'protein_g', source: IntakeSource.food, amount: 6, unit: 'g'),
          FoodNutrientPer100g(nutrientId: 'fat_g', source: IntakeSource.food, amount: 2.5, unit: 'g'),
          FoodNutrientPer100g(nutrientId: 'carb_g', source: IntakeSource.food, amount: 11, unit: 'g'),
        ],
      );

      await tester.pumpWidget(
        _wrapA11y(
          state,
          FoodPortionScreen.library(food: food, initialMeal: Meal.breakfast, initialAt: DateTime(2026, 11, 27, 7, 30)),
          brightness: Brightness.dark,
          size: smallPhone,
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      await tester.scrollUntilVisible(find.text('Lưu'), 200);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets('DiaryScreen, LogSheet, SupplementsScreen & ConfirmIngredientsScreen không tràn ở 360dp 200% Dark', (
      tester,
    ) async {
      _usePhoneViewport(tester);
      final state = await _makeState(pack);
      addTearDown(state.dispose);

      await state.addItem(
        const IntakeItem(
          label: 'Cơm tấm sườn bì chả',
          source: IntakeSource.food,
          meal: MealSlot.lunch,
          nutrients: {'energyKcal': 620, 'protein_g': 28, 'fat_g': 20, 'carb_g': 82},
        ),
      );
      await state.diary.addWater(state.day, 300);

      final pid = await state.diary.createProductWithIngredientsAndBox(
        name: 'Viên uống Phức hợp Sắt & Axit Folic',
        countUnit: CountUnit.tablet,
        unitsPerServing: 1,
        ingredients: const [],
        initialBoxRemaining: 4,
        initialBoxExpiryMonth: '2027-08',
      );
      expect(pid, isNotNull);

      // DiaryScreen + LogSheet
      await tester.pumpWidget(
        _wrapA11y(
          state,
          Scaffold(
            body: const DiaryScreen(),
            floatingActionButton: Builder(
              builder: (ctx) => FloatingActionButton(
                onPressed: () => unawaited(showLogSheet(ctx)),
                child: const Icon(LucideIcons.plus),
              ),
            ),
          ),
          brightness: Brightness.dark,
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();

      // SupplementsScreen (kiểm tra tên sản phẩm xếp dọc trên số còn lại ở 200%)
      await tester.pumpWidget(_wrapA11y(state, const Scaffold(body: SupplementsScreen()), brightness: Brightness.dark));
      await tester.pump(const Duration(milliseconds: 120));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      final nameY = tester.getTopLeft(find.text('Viên uống Phức hợp Sắt & Axit Folic')).dy;
      final stockY = tester.getTopLeft(find.text('Còn 4 viên')).dy;
      expect(stockY, greaterThan(nameY));

      // ConfirmIngredientsScreen + Edit sheet
      await tester.pumpWidget(
        _wrapA11y(
          state,
          ConfirmIngredientsScreen(
            initialLines: [
              EditableIngredient(
                nutrientId: 'iron',
                form: 'ferrous_fumarate',
                labelAmount: 30,
                labelUnit: LabelUnit.mg,
                isCompound: true,
                confirmed: true,
              ),
            ],
            onConfirmed: (ctx, drafts) async {},
          ),
          brightness: Brightness.dark,
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      await tester.tap(find.text('Sắt'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets('OnboardingFlow và MeScreen không tràn ở 360dp 200% Light & Dark', (tester) async {
      _usePhoneViewport(tester);
      final onboardingState = AppState.withRepository(pack: pack, repo: InMemoryJournalRepository());
      await onboardingState.start();
      addTearDown(onboardingState.dispose);

      await tester.pumpWidget(_wrapA11y(onboardingState, const OnboardingFlow(), brightness: Brightness.dark));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      await tester.scrollUntilVisible(find.text('Bắt đầu'), 200);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Bắt đầu'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      final readyState = await _makeState(pack);
      addTearDown(readyState.dispose);
      await tester.pumpWidget(_wrapA11y(readyState, const Scaffold(body: MeScreen()), brightness: Brightness.dark));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      await tester.scrollUntilVisible(find.text('Nguồn số liệu'), 200);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });
}
