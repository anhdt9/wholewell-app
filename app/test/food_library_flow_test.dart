import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:food_library/food_library.dart';
import 'package:health_engine/health_engine.dart';
import 'package:journal_db/journal_db.dart';
import 'package:wholewell/state/app_scope.dart';
import 'package:wholewell/state/app_state.dart';
import 'package:wholewell/ui/add_food_screen.dart';
import 'package:wholewell/ui/food_portion_screen.dart';
import 'package:wholewell/ui/label_food_screen.dart';

void main() {
  final pack = ReferencePack.fromJsonString(File('assets/reference_pack.json').readAsStringSync());
  const profile = Profile(ageYears: 35, sex: Sex.female, heightCm: 160, weightKg: 55);

  group('LabelFoodBuilder và custom_foods', () {
    test('đường bổ sung bỏ trống -> false; nhập 0 -> true và giữ được qua custom_foods', () async {
      final repo = InMemoryJournalRepository();
      final state = AppState.withRepository(pack: pack, repo: repo);
      await state.start();
      await state.saveProfile(profile);

      final blankFb = await state.diary.recordLabelFood(
        LabelFoodDraft(
          name: 'Sữa chua',
          meal: Meal.snack,
          at: DateTime(2026, 11, 23, 15, 0),
          labelBasisQty: 100,
          labelBasisUnit: 'ml',
          usedQty: 180,
          energyKcal: 100,
          addedSugarG: null,
        ),
        saveForReuse: true,
      );
      expect(blankFb.failed, isFalse);

      final zeroFb = await state.diary.recordLabelFood(
        LabelFoodDraft(
          name: 'Sữa hạt không đường',
          meal: Meal.breakfast,
          at: DateTime(2026, 11, 23, 7, 30),
          labelBasisQty: 100,
          labelBasisUnit: 'ml',
          usedQty: 200,
          energyKcal: 45,
          addedSugarG: 0,
        ),
        saveForReuse: true,
      );
      expect(zeroFb.failed, isFalse);

      final foods = await repo.foodsOn('2026-11-23');
      expect(foods.firstWhere((f) => f.name == 'Sữa chua').addedSugarKnown, isFalse);
      expect(foods.firstWhere((f) => f.name == 'Sữa hạt không đường').addedSugarKnown, isTrue);

      final customs = await repo.searchCustomFoods('sua');
      expect(customs.firstWhere((c) => c.name == 'Sữa chua').addedSugarKnown, isFalse);
      expect(customs.firstWhere((c) => c.name == 'Sữa hạt không đường').addedSugarKnown, isTrue);

      // Dùng lại món custom với 0 g đường bổ sung -> vẫn addedSugarKnown = true
      final zeroCustom = customs.firstWhere((c) => c.name == 'Sữa hạt không đường');
      await state.diary.recordCustomFood(
        zeroCustom,
        usedQty: 150,
        meal: Meal.dinner,
        at: DateTime(2026, 11, 23, 19, 0),
      );
      final foods2 = await repo.foodsOn('2026-11-23');
      expect(foods2.last.addedSugarKnown, isTrue);
      expect(foods2.last.lines.firstWhere((l) => l.nutrientId == 'addedSugar').amounts['addedSugar'], 0);
    });

    test('folate + folic_acid tự gán fortified; vitA/vitE theo dạng ảnh hưởng phép tính', () {
      final built = LabelFoodBuilder.build(
        LabelFoodDraft(
          name: 'Ngũ cốc tăng cường',
          meal: Meal.breakfast,
          at: DateTime(2026, 11, 23, 7, 0),
          labelBasisQty: 100,
          labelBasisUnit: 'g',
          usedQty: 100,
          micros: const [
            LabelMicroEntry(
              nutrientId: 'folate',
              labelAmount: 200,
              unit: LabelUnit.ug,
              form: NutrientForm.folicAcid,
              folateMode: LabelFolateMode.folateGeneral,
            ),
            LabelMicroEntry(
              nutrientId: 'vitA',
              labelAmount: 600,
              unit: LabelUnit.ug,
              form: NutrientForm.betaCarotene,
            ),
            LabelMicroEntry(
              nutrientId: 'vitE',
              labelAmount: 15,
              unit: LabelUnit.mg,
              form: NutrientForm.natural2r,
            ),
          ],
        ),
        pack: pack,
        profile: profile,
      );

      final lines = built.entryInput.lines;
      final folateLine = lines.firstWhere((l) => l.nutrientId == 'folate');
      expect(folateLine.source, IntakeSource.fortified);
      expect(folateLine.amounts['folicAcid'], 200);
      expect(folateLine.amounts['folate'], closeTo(340, 1e-9));

      final vitALine = lines.firstWhere((l) => l.nutrientId == 'vitA');
      expect(vitALine.amounts['retinol'], isNull); // beta-carotene không vào retinol UL

      final vitELine = lines.firstWhere((l) => l.nutrientId == 'vitE');
      expect(vitELine.source, IntakeSource.fortified);
      expect(vitELine.ulAmounts, isNull); // natural 2R tính 1x
    });

    test('kiểm hợp lý đơn vị nhắc khi > 100% UL hoặc > 10x RDA', () {
      final built = LabelFoodBuilder.build(
        LabelFoodDraft(
          name: 'Nước tăng lực',
          meal: Meal.snack,
          at: DateTime(2026, 11, 23, 15, 0),
          labelBasisQty: 100,
          labelBasisUnit: 'ml',
          usedQty: 100,
          micros: const [
            LabelMicroEntry(nutrientId: 'vitD', labelAmount: 400, unit: LabelUnit.ug),
            LabelMicroEntry(nutrientId: 'vitB12', labelAmount: 100, unit: LabelUnit.ug),
          ],
        ),
        pack: pack,
        profile: profile,
      );
      expect(built.warnings.map((w) => w.nutrientId), containsAll(['vitD', 'vitB12']));
    });
  });

  group('DiaryController: thư viện, sửa khẩu phần và fallback', () {
    const sampleFood = FoodDetail(
      id: 'recipe:pho-bo',
      kind: FoodKind.recipe,
      nameVi: 'Phở bò',
      nameEn: 'Pho bo',
      isEstimate: true,
      addedSugarKnown: true,
      niacinFortifiedUnseparated: false,
      folateUnseparated: false,
      defaultPortionId: 'p1',
      portions: [FoodPortion(id: 'p1', labelVi: 'Bát vừa', grams: 500)],
      nutrientsPer100g: [
        FoodNutrientPer100g(nutrientId: 'energyKcal', source: IntakeSource.food, amount: 90, unit: 'kcal'),
        FoodNutrientPer100g(nutrientId: 'protein', source: IntakeSource.food, amount: 5, unit: 'g'),
        FoodNutrientPer100g(nutrientId: 'addedSugar', source: IntakeSource.food, amount: 0, unit: 'g'),
      ],
    );

    test('sửa khẩu phần món thư viện gọi replaceFoodLines; thiếu món trong DB mới vẫn nhân tỷ lệ an toàn', () async {
      final repo = InMemoryJournalRepository();
      final lib = FakeFoodLibraryRepository([sampleFood]);
      final state = AppState.withRepository(pack: pack, repo: repo, foodLibrary: lib);
      await state.start();
      await state.saveProfile(profile);

      final fb = await state.diary.recordLibraryFood(
        food: sampleFood,
        portionUnit: 'Bát vừa',
        portionQty: 1,
        grams: 500,
        meal: Meal.breakfast,
        at: DateTime(2026, 11, 23, 7, 30),
      );
      final entry = (await repo.foodById(fb.savedFoodId!))!;
      expect(entry.lines.firstWhere((l) => l.nutrientId == 'energyKcal').amounts['energyKcal'], 450);

      // Sửa lên 1.5 bát vừa
      await state.diary.updateLoggedFood(
        entry,
        newQty: 1.5,
        newPortionUnit: 'Bát vừa',
        newGramsIfLibrary: 750,
        newMeal: Meal.lunch,
        newAt: DateTime(2026, 11, 23, 12, 0),
      );
      final edited = (await repo.foodById(entry.id))!;
      expect(edited.meal, Meal.lunch);
      expect(edited.portionQty, 1.5);
      expect(edited.lines.firstWhere((l) => l.nutrientId == 'energyKcal').amounts['energyKcal'], 675);

      // Giả lập thư viện mới không còn món -> vẫn nhân tỷ lệ an toàn
      state.diary.setFoodLibrary(repository: FakeFoodLibraryRepository(const []));
      await state.diary.updateLoggedFood(
        edited,
        newQty: 3.0,
        newPortionUnit: 'Bát vừa',
        newMeal: Meal.lunch,
        newAt: edited.at,
      );
      final fallback = (await repo.foodById(entry.id))!;
      expect(fallback.lines.firstWhere((l) => l.nutrientId == 'energyKcal').amounts['energyKcal'], 1350);
    });
  });

  group('Widget flow Ghi món & Ẩn số calo', () {
    testWidgets('Ghi món ẩn kcal khi bật hideCalories và hiện màn chặn khi thư viện hỏng', (tester) async {
      final repo = InMemoryJournalRepository();
      final lib = FakeFoodLibraryRepository([
        const FoodDetail(
          id: 'recipe:pho-bo',
          kind: FoodKind.recipe,
          nameVi: 'Phở bò',
          nameEn: 'Pho bo',
          isEstimate: true,
          addedSugarKnown: true,
          niacinFortifiedUnseparated: false,
          folateUnseparated: false,
          defaultPortionId: 'p1',
          portions: [FoodPortion(id: 'p1', labelVi: 'Bát vừa', grams: 500)],
          nutrientsPer100g: [
            FoodNutrientPer100g(nutrientId: 'energyKcal', source: IntakeSource.food, amount: 90, unit: 'kcal'),
            FoodNutrientPer100g(nutrientId: 'addedSugar', source: IntakeSource.food, amount: 0, unit: 'g'),
          ],
        ),
      ]);
      final state = AppState.withRepository(pack: pack, repo: repo, foodLibrary: lib);
      await state.start();
      await state.saveProfile(profile);
      await state.setHideCalories(true);

      await tester.pumpWidget(
        AppScope(
          state: state,
          child: const MaterialApp(home: AddFoodScreen()),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'pho bo');
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pumpAndSettle();

      expect(find.text('Phở bò'), findsOneWidget);
      expect(find.text('ước tính'), findsOneWidget);
      expect(find.textContaining('450'), findsNothing);

      // Mở Chọn khẩu phần, ẩn kcal vẫn được tôn trọng
      await tester.tap(find.text('Phở bò'));
      await tester.pumpAndSettle();
      expect(find.byType(FoodPortionScreen), findsOneWidget);
      expect(find.textContaining('kcal'), findsNothing);

      // Quay lại và thử trạng thái thư viện hỏng
      await tester.pageBack();
      await tester.pumpAndSettle();
      state.diary.setFoodLibrary(repository: null, broken: true);
      await tester.pumpAndSettle();
      expect(
        find.text('Không đọc được thư viện món ăn. Hãy cài lại WholeWell từ cửa hàng ứng dụng.'),
        findsOneWidget,
      );
      await tester.tap(find.text('Nhập theo nhãn'));
      await tester.pumpAndSettle();
      expect(find.byType(LabelFoodScreen), findsOneWidget);
    });
  });

  test('mở tệp assets/food_library.db thật, kiểm SHA-256 manifest và truy vấn pho bo', () async {
    final manifest = jsonDecode(File('assets/food_library_manifest.json').readAsStringSync()) as Map<String, dynamic>;
    final lib = await SqliteFoodLibraryRepository.openVerifiedPath(
      path: 'assets/food_library.db',
      expectedSha256: manifest['sha256'] as String,
    );
    addTearDown(lib.close);

    expect(lib.meta.packVersion, pack.version);
    final hits = await lib.search('pho bo');
    expect(hits.any((h) => h.id == 'recipe:pho-bo'), isTrue);
    final detail = (await lib.getById('recipe:pho-bo'))!;
    expect(detail.isEstimate, isTrue);
    expect(detail.addedSugarKnown, isTrue);
    final lines = lib.computeLines(detail, detail.defaultPortion!.grams, pack: pack);
    expect(lines.any((l) => l.nutrientId == 'energyKcal' && (l.amounts['energyKcal'] ?? 0) > 200), isTrue);
  });

  test('updateLoggedFood đổi ngày kiểm tra đúng cờ UL và đường bổ sung của ngày đích', () async {
    final repo = InMemoryJournalRepository();
    final state = AppState.withRepository(pack: pack, repo: repo);
    await state.start();
    await state.saveProfile(profile);

    // Đang xem 23/11: tạo sẵn 1 món ngọt ngày 23/11 (20g đường) và 1 món Vitamin A cao (3200 ug retinol) định chuyển sang 22/11
    await state.setDay(DateTime(2026, 11, 23));
    await state.diary.recordLabelFood(
      LabelFoodDraft(
        name: 'Bánh ngọt 23/11',
        meal: Meal.lunch,
        at: DateTime(2026, 11, 23, 12, 0),
        labelBasisQty: 100,
        labelBasisUnit: 'g',
        usedQty: 100,
        addedSugarG: 20,
      ),
      saveForReuse: false,
    );
    final moveFb = await state.diary.recordLabelFood(
      LabelFoodDraft(
        name: 'Gan đậm đặc',
        meal: Meal.breakfast,
        at: DateTime(2026, 11, 23, 7, 30),
        labelBasisQty: 100,
        labelBasisUnit: 'g',
        usedQty: 100,
        addedSugarG: 0,
        micros: const [
          LabelMicroEntry(
            nutrientId: 'vitA',
            labelAmount: 3200,
            unit: LabelUnit.ug,
            form: NutrientForm.retinol,
          ),
        ],
      ),
      saveForReuse: false,
    );
    final entry = (await repo.foodById(moveFb.savedFoodId!))!;

    // Dời món từ 23/11 -> 22/11 (ngày 22/11 chưa có đường quá 10g, nhưng vừa nhận 3200 ug retinol > UL 3000)
    final editFb = await state.diary.updateLoggedFood(
      entry,
      newQty: 100,
      newMeal: Meal.breakfast,
      newAt: DateTime(2026, 11, 22, 8, 0),
    );
    expect(editFb.newUlFlags.any((f) => f.nutrientId == 'retinol' && f.kind == UlFlagKind.daily), isTrue);
    expect(editFb.mealsOverSugar, isEmpty); // không lẫn đường bữa trưa 20g của ngày 23/11!
  });

  testWidgets('LabelFoodScreen đổi Vitamin E mg->IU, Folate mode không crash và tô đỏ inline vitA', (tester) async {
    final repo = InMemoryJournalRepository();
    final state = AppState.withRepository(pack: pack, repo: repo);
    await state.start();
    await state.saveProfile(profile);

    await tester.pumpWidget(
      AppScope(
        state: state,
        child: const MaterialApp(home: LabelFoodScreen(initialMeal: Meal.breakfast)),
      ),
    );
    await tester.pumpAndSettle();

    final mainScroll = find.byType(Scrollable).first;

    Future<void> scrollToAndTap(Finder target) async {
      await tester.scrollUntilVisible(target, 150, scrollable: mainScroll);
      await tester.pumpAndSettle();
      await tester.drag(mainScroll, const Offset(0, -100));
      await tester.pumpAndSettle();
      await tester.tap(target);
      await tester.pumpAndSettle();
    }

    // Tên món
    await tester.enterText(find.widgetWithText(TextFormField, 'Tên món'), 'Thử nhãn');

    // Thêm Vitamin E
    await scrollToAndTap(find.text('Thêm vi chất trên nhãn'));
    await tester.enterText(find.widgetWithText(TextField, 'Tìm vitamin, khoáng chất...'), 'vitamin e');
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('Vitamin E').last);
    await tester.pumpAndSettle();

    // Chọn Tổng hợp (dl-alpha, theo khối lượng) rồi đổi đơn vị sang IU -> không crash AssertionError
    await scrollToAndTap(find.text('Nhãn không ghi rõ').last);
    await tester.tap(find.text('Tổng hợp (dl-alpha, theo khối lượng)').last);
    await tester.pumpAndSettle();

    await scrollToAndTap(find.text('mg').last);
    await tester.tap(find.text('IU').last);
    await tester.pumpAndSettle();
    expect(find.text('Tổng hợp (dl-alpha)'), findsOneWidget);

    // Thêm Folate và đổi mode
    await scrollToAndTap(find.text('Thêm vi chất trên nhãn'));
    await tester.enterText(find.widgetWithText(TextField, 'Tìm vitamin, khoáng chất...'), 'folate');
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('Folate').last);
    await tester.pumpAndSettle();

    await scrollToAndTap(find.text('Folate').last);
    await tester.tap(find.text('Axit folic').last);
    await tester.pumpAndSettle();

    // Thêm Vitamin A và nhập 5000 ug -> tô đỏ inline khi kiểm tra lại đơn vị
    await scrollToAndTap(find.text('Thêm vi chất trên nhãn'));
    await tester.enterText(find.widgetWithText(TextField, 'Tìm vitamin, khoáng chất...'), 'vitamin a');
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('Vitamin A').last);
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(find.textContaining('Vitamin A').last, 150, scrollable: mainScroll);
    await tester.drag(mainScroll, const Offset(0, -100));
    await tester.pumpAndSettle();
    final vitAAmountField = find.widgetWithText(TextFormField, 'Lượng trên nhãn').last;
    await tester.enterText(vitAAmountField, '5000');
    await tester.tap(find.widgetWithText(FilledButton, 'Lưu'));
    await tester.pumpAndSettle();

    expect(find.text('Kiểm tra lại đơn vị'), findsOneWidget);
    await tester.tap(find.text('Kiểm tra lại'));
    await tester.pumpAndSettle();
    expect(find.text('Kiểm tra lại mg và µg'), findsOneWidget);
  });
}
