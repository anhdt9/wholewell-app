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
import 'package:wholewell/ui/diary_screen.dart';
import 'package:wholewell/ui/food_portion_screen.dart';
import 'package:wholewell/ui/me_screen.dart';
import 'package:wholewell/ui/onboarding_flow.dart';
import 'package:wholewell/ui/supplements_screen.dart';
import 'package:wholewell/ui/today_doses_screen.dart';

Future<AppState> _makeReadyState(ReferencePack pack, {bool hideCalories = false}) async {
  final repo = InMemoryJournalRepository();
  final state = AppState.withRepository(pack: pack, repo: repo);
  await state.start();
  await state.completeFirstConsent(ageYears: 30, caution: false);
  await state.saveOnboardingBodyProfile(
    const Profile(ageYears: 30, sex: Sex.female, heightCm: 160, weightKg: 55, activityLevel: ActivityLevel.active),
  );
  await state.setHideCalories(hideCalories);
  return state;
}

Widget _wrapWithAppTheme(AppState state, Widget child, {Brightness brightness = Brightness.light}) {
  return AppScope(
    state: state,
    child: MaterialApp(theme: buildWholeWellTheme(brightness), home: child),
  );
}

void main() {
  final pack = ReferencePack.fromJsonString(File('assets/reference_pack.json').readAsStringSync());

  testWidgets('FoodPortionScreen ghim thẻ tóm tắt, đổi số với AnimatedSwitcher và ẩn kcal khi bật Ẩn số calo', (
    tester,
  ) async {
    final state = await _makeReadyState(pack, hideCalories: false);
    addTearDown(state.dispose);

    const food = FoodDetail(
      id: 'rice_1',
      kind: FoodKind.usdaFoundation,
      nameVi: 'Cơm trắng',
      nameEn: 'White rice',
      isEstimate: false,
      addedSugarKnown: true,
      niacinFortifiedUnseparated: false,
      folateUnseparated: false,
      defaultPortionId: 'bowl',
      portions: [FoodPortion(id: 'bowl', labelVi: '1 bát vừa', grams: 150)],
      nutrientsPer100g: [
        FoodNutrientPer100g(nutrientId: 'energyKcal', source: IntakeSource.food, amount: 130, unit: 'kcal'),
        FoodNutrientPer100g(nutrientId: 'protein_g', source: IntakeSource.food, amount: 2.7, unit: 'g'),
        FoodNutrientPer100g(nutrientId: 'fat_g', source: IntakeSource.food, amount: 0.3, unit: 'g'),
        FoodNutrientPer100g(nutrientId: 'carb_g', source: IntakeSource.food, amount: 28, unit: 'g'),
      ],
    );

    await tester.pumpWidget(
      _wrapWithAppTheme(
        state,
        FoodPortionScreen.library(food: food, initialMeal: Meal.lunch, initialAt: DateTime(2026, 11, 27, 12, 0)),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.descendant(of: find.byType(SurfaceCard), matching: find.byType(AnimatedSwitcher)), findsOneWidget);
    expect(find.textContaining('kcal'), findsOneWidget);

    await state.setHideCalories(true);
    await tester.pumpAndSettle();
    expect(find.textContaining('kcal'), findsNothing);
    expect(find.textContaining('Đạm '), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('LogSheet 4 ô và DiaryScreen nhóm món ăn theo bữa trong Card', (tester) async {
    final state = await _makeReadyState(pack);
    addTearDown(state.dispose);

    await state.addItem(
      const IntakeItem(
        label: 'Bánh mì',
        source: IntakeSource.food,
        meal: MealSlot.breakfast,
        nutrients: {'energyKcal': 250, 'protein_g': 8, 'fat_g': 6, 'carb_g': 40},
      ),
    );
    await state.addItem(
      const IntakeItem(
        label: 'Cơm gà',
        source: IntakeSource.food,
        meal: MealSlot.lunch,
        nutrients: {'energyKcal': 520, 'protein_g': 30, 'fat_g': 16, 'carb_g': 60},
      ),
    );

    await tester.pumpWidget(
      _wrapWithAppTheme(
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
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Bữa sáng'), findsOneWidget);
    expect(find.text('Bữa trưa'), findsOneWidget);
    expect(find.text('Bánh mì'), findsOneWidget);
    expect(find.text('Cơm gà'), findsOneWidget);

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    expect(find.text('Món ăn'), findsAtLeastNWidgets(1));
    expect(find.text('Bổ sung'), findsAtLeastNWidgets(1));
    expect(find.text('Nước'), findsAtLeastNWidgets(1));
    expect(find.text('Buổi tập'), findsAtLeastNWidgets(1));
  });

  testWidgets('SupplementsScreen hiện LoadingSkeletonBox khi đang tải, sau đó hiện thanh kho & pill trạng thái', (
    tester,
  ) async {
    final state = await _makeReadyState(pack);
    addTearDown(state.dispose);

    final pid = await state.diary.createProductWithIngredientsAndBox(
      name: 'Kẽm 15 mg',
      countUnit: CountUnit.tablet,
      unitsPerServing: 1,
      ingredients: const [
        IngredientDraft(
          nutrientId: 'zinc',
          form: NutrientForm.unknown,
          amountPerServing: 15,
          unit: 'mg',
          labelAmount: 15,
          labelUnit: 'mg',
          origin: IngredientOrigin.manual,
          confirmed: true,
        ),
      ],
      initialBoxRemaining: 5,
      initialBoxExpiryMonth: '2027-06',
    );
    await state.diary.addSchedule(pid!, 480, 1, validFrom: dayKey(state.day));

    await tester.pumpWidget(
      _wrapWithAppTheme(state, const Scaffold(body: SupplementsScreen()), brightness: Brightness.dark),
    );
    // Dùng pump(Duration) thay vì pumpAndSettle khi LoadingSkeletonBox đang chạy animation lặp.
    expect(find.byType(LoadingSkeletonBox), findsWidgets);
    await tester.pump(const Duration(milliseconds: 120));
    await tester.pumpAndSettle();

    expect(find.byType(LoadingSkeletonBox), findsNothing);
    expect(find.text('Kẽm 15 mg'), findsOneWidget);
    expect(find.text('Sắp hết'), findsOneWidget);
    expect(find.text('HSD 06/2027'), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('TodayDosesScreen timeline dọc và MeScreen 4 nhóm thẻ', (tester) async {
    final state = await _makeReadyState(pack);
    addTearDown(state.dispose);

    final pid = await state.diary.createProductWithIngredientsAndBox(
      name: 'Vitamin C 500',
      countUnit: CountUnit.tablet,
      unitsPerServing: 1,
      ingredients: const [],
      initialBoxRemaining: 30,
    );
    await state.diary.addSchedule(pid!, 480, 1, validFrom: dayKey(state.day));
    final now = DateTime(state.day.year, state.day.month, state.day.day, 8, 5);

    await tester.pumpWidget(_wrapWithAppTheme(state, TodayDosesScreen(nowOverride: now)));
    await tester.pumpAndSettle();

    expect(find.text('08:00'), findsOneWidget);
    expect(find.text('Đã uống'), findsOneWidget);

    await tester.pumpWidget(_wrapWithAppTheme(state, const Scaffold(body: MeScreen())));
    await tester.pumpAndSettle();

    expect(find.text('Hồ sơ & Lịch sinh hoạt'), findsOneWidget);
    expect(find.text('Nhắc giờ & Hiển thị'), findsOneWidget);
    expect(find.text('Sao lưu'), findsOneWidget);
    expect(find.text('Quyền riêng tư & Nguồn'), findsOneWidget);
    expect(find.byType(Card), findsNWidgets(4));
  });

  testWidgets('OnboardingFlow Chào mừng có huy hiệu và bước 1/3 có thanh tiến độ 3 đoạn', (tester) async {
    final repo = InMemoryJournalRepository();
    final state = AppState.withRepository(pack: pack, repo: repo);
    await state.start();
    addTearDown(state.dispose);

    await tester.pumpWidget(_wrapWithAppTheme(state, const OnboardingFlow()));
    await tester.pumpAndSettle();

    expect(find.byType(CustomPaint), findsWidgets);
    expect(find.byType(SurfaceCard), findsOneWidget);

    await tester.tap(find.text('Bắt đầu'));
    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel('Bước 1 trên 3'), findsOneWidget);
  });

  testWidgets('TodayDosesScreen ở màn 360dp và cỡ chữ 200% xếp dọc nút trong overdue/inWindow/early không tràn', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final state = await _makeReadyState(pack);
    addTearDown(state.dispose);

    final pid = await state.diary.createProductWithIngredientsAndBox(
      name: 'Phức hợp Vitamin B Tổng Hợp Cao Cấp',
      countUnit: CountUnit.tablet,
      unitsPerServing: 1,
      ingredients: const [],
      initialBoxRemaining: 30,
    );
    final today = dayKey(state.day);
    // 06:00 overdue, 12:00 inWindow, 20:00 early khi now = 12:15
    await state.diary.addSchedule(pid!, 360, 1, validFrom: today);
    await state.diary.addSchedule(pid, 720, 1, validFrom: today);
    await state.diary.addSchedule(pid, 1200, 1, validFrom: today);
    final now = DateTime(state.day.year, state.day.month, state.day.day, 12, 15);

    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(size: Size(360, 800), textScaler: TextScaler.linear(2.0)),
        child: _wrapWithAppTheme(state, TodayDosesScreen(nowOverride: now)),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Đánh dấu'), findsOneWidget);
    expect(find.text('Đã uống'), findsOneWidget);

    final firstTitleY = tester.getTopLeft(find.textContaining('Phức hợp Vitamin B').first).dy;
    final markBtnY = tester.getTopLeft(find.text('Đánh dấu')).dy;
    expect(markBtnY, greaterThan(firstTitleY));

    await tester.scrollUntilVisible(find.text('Uống sớm?'), 200);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('Uống sớm?'), findsOneWidget);
    expect(find.text('Bỏ qua'), findsWidgets);
  });
}
