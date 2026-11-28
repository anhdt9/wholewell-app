import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:health_engine/health_engine.dart';
import 'package:journal_db/journal_db.dart';
import 'package:material_ui/material_ui.dart';
import 'package:wholewell/state/app_state.dart';
import 'package:wholewell/ui/add_food_screen.dart';
import 'package:wholewell/ui/edit_food_screen.dart';
import 'package:wholewell/ui/edit_schedule_screen.dart';
import 'package:wholewell/ui/label_food_screen.dart';
import 'package:wholewell/ui/me_screen.dart';
import 'package:wholewell/ui/notification_settings_screen.dart';
import 'package:wholewell/ui/today_screen.dart';

import 'helpers/pump_app.dart';

Future<AppState> _makeReadyState(
  ReferencePack pack, {
  FakeNotificationScheduler? scheduler,
  InMemoryJournalRepository? repo,
}) async {
  final state = testAppState(
    pack: pack,
    repo: repo ?? InMemoryJournalRepository(),
    notificationScheduler: scheduler ?? FakeNotificationScheduler(),
  );
  await state.start();
  await state.completeFirstConsent(ageYears: 30, caution: false);
  await state.saveOnboardingBodyProfile(
    const Profile(ageYears: 30, sex: Sex.male, heightCm: 170, weightKg: 65, activityLevel: ActivityLevel.active),
  );
  return state;
}

void main() {
  final pack = ReferencePack.fromJsonString(File('assets/reference_pack.json').readAsStringSync());

  group('#26 Tắt từng bữa chính hoặc cả 3 bữa', () {
    test('defaultMealFor bỏ qua bữa đã tắt và trả Meal.snack khi tắt cả 3', () {
      const noBreakfast = DayTimesSettings(hasBreakfast: false, hasLunch: true, hasDinner: true);
      expect(DiaryController.defaultMealFor(DateTime(2026, 11, 27, 7, 15), noBreakfast), Meal.snack);
      expect(DiaryController.defaultMealFor(DateTime(2026, 11, 27, 12, 15), noBreakfast), Meal.lunch);

      const noMeals = DayTimesSettings(hasBreakfast: false, hasLunch: false, hasDinner: false);
      expect(DiaryController.defaultMealFor(DateTime(2026, 11, 27, 7, 15), noMeals), Meal.snack);
      expect(DiaryController.defaultMealFor(DateTime(2026, 11, 27, 12, 15), noMeals), Meal.snack);
      expect(DiaryController.defaultMealFor(DateTime(2026, 11, 27, 19, 15), noMeals), Meal.snack);
    });

    testWidgets('DayTimesScreen bật/tắt bữa, giữ giờ cũ khi bật lại, tắt cả 3 hiện "Chỉ bữa phụ" trên MeScreen', (
      tester,
    ) async {
      final state = await _makeReadyState(pack);
      addTearDown(state.dispose);

      await pumpApp(tester, state, const Scaffold(body: MeScreen()));
      await tester.tap(find.text('Giờ trong ngày'));
      await tester.pumpAndSettle();

      // Đổi giờ bữa sáng hoặc giữ 07:00, rồi tắt cả 3 bữa.
      expect(find.text('07:00'), findsOneWidget);
      final switches = find.byType(Switch);
      expect(switches, findsNWidgets(3));

      await tester.tap(switches.at(0));
      await tester.pumpAndSettle();
      expect(find.text('07:00'), findsNothing);

      // Bật lại bữa sáng -> giờ cũ 07:00 vẫn được giữ.
      await tester.tap(switches.at(0));
      await tester.pumpAndSettle();
      expect(find.text('07:00'), findsOneWidget);

      // Tắt cả 3 bữa -> hiện note và lưu.
      await tester.tap(switches.at(0));
      await tester.tap(switches.at(1));
      await tester.tap(switches.at(2));
      await tester.pumpAndSettle();
      expect(find.text('Đã tắt hết bữa chính — món mới mặc định vào Phụ.'), findsOneWidget);

      await tester.tap(find.text('Lưu'));
      await tester.pumpAndSettle();

      expect(state.dayTimesSettings.hasBreakfast, isFalse);
      expect(state.dayTimesSettings.hasLunch, isFalse);
      expect(state.dayTimesSettings.hasDinner, isFalse);
      expect(state.dayTimesSettings.breakfast, 420);
      expect(find.byType(MeScreen), findsOneWidget);
      expect(find.text('Chỉ bữa phụ'), findsOneWidget);
    });

    testWidgets('AddFoodScreen, LabelFoodScreen, EditScheduleScreen ẩn bữa tắt; EditFoodScreen giữ được món cũ', (
      tester,
    ) async {
      final repo = InMemoryJournalRepository();
      final state = await _makeReadyState(pack, repo: repo);
      addTearDown(state.dispose);

      await state.diary.saveDayTimesSettings(
        const DayTimesSettings(hasBreakfast: false, hasLunch: true, hasDinner: false, dayTimesConfirmed: true),
      );

      // AddFoodScreen chỉ còn Trưa và Phụ.
      await pumpApp(tester, state, const AddFoodScreen());
      expect(find.text('Sáng'), findsNothing);
      expect(find.text('Trưa'), findsOneWidget);
      expect(find.text('Tối'), findsNothing);
      expect(find.text('Phụ'), findsOneWidget);

      // LabelFoodScreen mở với initialMeal=Meal.snack cũng chỉ hiện Trưa và Phụ.
      await pumpApp(tester, state, const LabelFoodScreen(initialMeal: Meal.snack));
      expect(find.text('Sáng'), findsNothing);
      expect(find.text('Trưa'), findsOneWidget);
      expect(find.text('Tối'), findsNothing);
      expect(find.text('Phụ'), findsOneWidget);

      // EditScheduleScreen chỉ còn chip Trưa 12:00 và take_with_meal nhắc nếu đặt vào 07:00.
      final prodId = await state.diary.createProductWithIngredientsAndBox(
        name: 'Vitamin D3 1000 IU',
        countUnit: CountUnit.tablet,
        unitsPerServing: 1,
        ingredients: const [
          IngredientDraft(
            nutrientId: 'vitD',
            form: 'unknown',
            amountPerServing: 25,
            unit: 'ug',
            labelAmount: 1000,
            labelUnit: 'IU',
            origin: IngredientOrigin.manual,
            confirmed: true,
          ),
        ],
      );
      final prod = state.diary.allProducts.singleWhere((p) => p.product.id == prodId).product;
      await pumpApp(tester, state, EditScheduleScreen(product: prod));
      expect(find.widgetWithText(ActionChip, 'Sáng 07:00'), findsNothing);
      expect(find.widgetWithText(ActionChip, 'Trưa 12:00'), findsOneWidget);
      expect(find.widgetWithText(ActionChip, 'Tối 19:00'), findsNothing);

      // Món cũ từng ghi ở Bữa sáng trước khi tắt vẫn mở & sửa được ở EditFoodScreen.
      final entryId = await repo.addFood(
        FoodEntryInput(
          at: DateTime.now(),
          meal: Meal.breakfast,
          name: 'Phở sáng cũ',
          portionUnit: 'bát',
          portionQty: 1,
          addedSugarKnown: true,
          packVersion: pack.version,
          lines: const [
            IntakeLine(nutrientId: 'energyKcal', source: IntakeSource.food, amounts: {'energyKcal': 400}),
          ],
        ),
      );
      await state.diary.reload();
      final oldEntry = state.diary.todayFoods.singleWhere((e) => e.id == entryId);
      await pumpApp(tester, state, EditFoodScreen(entry: oldEntry));
      expect(find.text('Sáng'), findsOneWidget);
      expect(find.text('Trưa'), findsOneWidget);
      expect(find.text('Tối'), findsNothing);
      expect(find.text('Phụ'), findsOneWidget);
    });
  });

  group('#27 Bỏ bước 4/4 Hiển thị calo trong onboarding', () {
    testWidgets('CSDL cũ đang dở bước calorie_display (đã có profile) tự hoàn tất và vào Hôm nay', (tester) async {
      final dir = Directory.systemTemp.createTempSync('ww_legacy_cal_');
      addTearDown(() {
        if (dir.existsSync()) dir.deleteSync(recursive: true);
      });
      final opener = DbOpener(
        files: DbFiles(dir),
        keys: FakeSecureKeyStore(),
        executorFactory: sameIsolateExecutor,
        retryDelay: Duration.zero,
      );
      final res = await opener.createNew(
        const ConsentInput(contentVersion: mvpConsentVersion, ageYears: 29, caution: false),
      );
      final repo = (res as Opened).repository;
      await repo.saveProfile(
        const Profile(ageYears: 29, sex: Sex.female, heightCm: 162, weightKg: 54, activityLevel: ActivityLevel.active),
      );
      await repo.saveOnboardingStep(OnboardingStep.calorieDisplay);
      await repo.close();

      final state = AppState(pack: pack, opener: opener);
      await tester.runAsync(state.start);
      addTearDown(() async {
        await state.session.repo?.close();
        state.dispose();
      });

      await pumpWholeWellApp(tester, state);
      await tester.pumpAndSettle();

      expect(find.byType(TodayScreen), findsOneWidget);
      expect(state.hideCalories, isFalse);
      expect(find.text('Năng lượng'), findsOneWidget);
      expect(await tester.runAsync(() => state.session.repo!.loadOnboardingStep()), OnboardingStep.done);
    });
  });

  group('#28 Tùy chọn Hiện tên sản phẩm trên thông báo (mặc định tắt)', () {
    testWidgets('Mặc định không gửi detailText; bật công tắc đồng bộ tên SP, tắt lập tức xóa sạch', (tester) async {
      final scheduler = FakeNotificationScheduler();
      final state = await _makeReadyState(pack, scheduler: scheduler);
      addTearDown(state.dispose);

      await state.diary.grantNotificationConsent('notif-1');
      await state.diary.saveDayTimesSettings(const DayTimesSettings(dayTimesConfirmed: true));

      final p1 = await state.diary.createProductWithIngredientsAndBox(
        name: 'Vitamin C 500 mg',
        countUnit: CountUnit.tablet,
        unitsPerServing: 1,
        ingredients: const [
          IngredientDraft(
            nutrientId: 'vitC',
            form: 'unknown',
            amountPerServing: 500,
            unit: 'mg',
            labelAmount: 500,
            labelUnit: 'mg',
            origin: IngredientOrigin.manual,
            confirmed: true,
          ),
        ],
      );
      await state.diary.addSchedule(p1!, 480, 1, validFrom: dayKey(DateTime.now()));
      await state.syncNotifications();

      expect(scheduler.syncedSlots, hasLength(1));
      expect(scheduler.syncedSlots.single.detailText, isNull);
      expect(scheduler.syncedSlots.single.toMap().containsKey('detailText'), isFalse);

      await pumpApp(tester, state, const NotificationSettingsScreen());

      final detailTile = find.widgetWithText(SwitchListTile, 'Hiện tên sản phẩm trên thông báo');
      expect(detailTile, findsOneWidget);
      expect(tester.widget<SwitchListTile>(detailTile).value, isFalse);

      // Bật hiện tên sản phẩm -> hiện cảnh báo màn hình khóa & đồng bộ detailText chỉ gồm tên sản phẩm.
      await tester.tap(detailTile);
      await tester.pumpAndSettle();

      expect(state.dayTimesSettings.reminderShowDetails, isTrue);
      expect(find.textContaining('Tên sản phẩm bổ sung sẽ hiển thị trên thông báo'), findsOneWidget);
      expect(scheduler.syncedSlots.single.detailText, 'Vitamin C 500 mg');
      expect(scheduler.syncedSlots.single.toMap()['detailText'], 'Vitamin C 500 mg');

      // Tắt lại -> xóa ngay tên sản phẩm khỏi syncedSlots.
      await tester.tap(detailTile);
      await tester.pumpAndSettle();

      expect(state.dayTimesSettings.reminderShowDetails, isFalse);
      expect(scheduler.syncedSlots.single.detailText, isNull);
      expect(scheduler.syncedSlots.single.toMap().containsKey('detailText'), isFalse);
    });
  });
}
