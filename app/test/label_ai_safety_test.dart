// Test cho PR 1: an toàn khi AI đọc nhãn (đặc tả label-scan-inventory, Bổ sung 1, mục B1.7).
import 'dart:convert';
import 'dart:io';

import 'package:dsld_library/dsld_library.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:health_engine/health_engine.dart';
import 'package:journal_db/journal_db.dart';
import 'package:material_ui/material_ui.dart';
import 'package:wholewell/state/app_scope.dart';
import 'package:wholewell/state/app_state.dart';
import 'package:wholewell/state/dsld_ingredient_mapper.dart';
import 'package:wholewell/ui/common/common_widgets.dart';
import 'package:wholewell/ui/confirm_ingredients_screen.dart';
import 'package:wholewell/ui/food_portion_screen.dart';

final _packJson = File('assets/reference_pack.json').readAsStringSync();
final _pack = ReferencePack.fromJsonString(_packJson);

Future<AppState> _readyState() async {
  final repo = InMemoryJournalRepository();
  await repo.saveProfileWithCaution(
    const Profile(
      ageYears: 30,
      sex: Sex.male,
      heightCm: 170,
      weightKg: 65,
      activityLevel: ActivityLevel.inactive,
    ),
    caution: false,
  );
  await repo.saveHideCalories(false);
  await repo.saveOnboardingStep(OnboardingStep.done);
  final state = AppState.withRepository(pack: _pack, repo: repo);
  await state.start();
  return state;
}

Widget _wrap(AppState state, Widget child) => AppScope(
      state: state,
      child: MaterialApp(
        theme: buildWholeWellTheme(Brightness.light),
        home: child,
      ),
    );

void _phoneViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(1080, 2600);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
}

ParsedLabelPackage _ai(List<Map<String, Object?>> ingredients) =>
    SupplementLabelParser.parseAiJson(jsonEncode({'ingredients': ingredients}), const [])!;

ParsedLabelPackage _cross(List<Map<String, Object?>> ai, List<String> ocr) =>
    SupplementLabelParser.crossCheckAi(_ai(ai), SupplementLabelParser.parsePackage(ocr), ocr);

DsldProductDetail _dsld(List<DsldFact> facts) => DsldProductDetail(
      dsldId: 1,
      barcode: '012345678905',
      productName: 'Test Multi',
      brandName: 'Brand',
      servingSize: '1 Tablet(s)',
      supplementForm: 'Tablet',
      netContents: '60 Tablet(s)',
      suggestedUse: '',
      otherIngredients: '',
      facts: facts,
    );

DsldFact _fact(String ingredient, String amount, String unit, {String category = 'vitamin'}) =>
    DsldFact(
      ingredient: ingredient,
      category: category,
      amount: amount,
      unit: unit,
      dvPercent: '',
      dvGroup: '',
    );

void main() {
  group('LabelUnitText.parse', () {
    test('chỉ nhận chữ trong danh sách cố định', () {
      const cases = <String, LabelUnit>{
        'mg': LabelUnit.mg,
        'MG': LabelUnit.mg,
        ' milligrams ': LabelUnit.mg,
        'mcg': LabelUnit.ug,
        'µg': LabelUnit.ug,
        'μg': LabelUnit.ug,
        'Micrograms': LabelUnit.ug,
        'ug': LabelUnit.ug,
        'g': LabelUnit.g,
        'Gram(s)': LabelUnit.g,
        'IU': LabelUnit.iu,
        'International Units': LabelUnit.iu,
        'mcg DFE': LabelUnit.ugDfe,
        'ug_dfe': LabelUnit.ugDfe,
        'μg  DFE': LabelUnit.ugDfe,
        'mcg RAE': LabelUnit.ugRae,
        'ug_rae': LabelUnit.ugRae,
        'mg NE': LabelUnit.mgNe,
        'mg_ne': LabelUnit.mgNe,
      };
      cases.forEach((raw, unit) => expect(LabelUnitText.parse(raw), unit, reason: raw));
    });

    test('chữ lạ, trống hay đơn vị engine không đổi được thì null, không bao giờ mặc định mg', () {
      for (final raw in [null, '', '  ', 'UI', 'gm', 'ng', '%', 'mg DFE', 'mg RAE', 'mg/day', 'RE', 'mg alpha-TE']) {
        expect(LabelUnitText.parse(raw), isNull, reason: '$raw');
      }
    });
  });

  group('parseAiJson', () {
    test('thiếu đơn vị hoặc đơn vị lạ thì để trống', () {
      final pkg = _ai([
        {'name': 'Vitamin C', 'amount': 1},
        {'name': 'Zinc', 'amount': 15, 'unit': 'milligram/day'},
        {'name': 'Vitamin D3', 'amount': 25, 'unit': 'μg'},
        {'name': 'Vitamin B12', 'amount': 500, 'unit': 'mcg'},
      ]);
      expect(pkg.fromOnDeviceAi, isTrue);
      expect(pkg.ingredients.map((l) => l.unit), [null, null, LabelUnit.ug, LabelUnit.ug]);
    });
  });

  group('Bộ đọc chữ OCR', () {
    test('đọc đơn vị viết liền và chữ mu Hy Lạp', () {
      final lines = SupplementLabelParser.parseLines(const [
        'Folate 667 mcgDFE',
        'Vitamin D 25 μg',
        'Niacin 16 mgNE',
      ]);
      expect(lines.map((l) => l.unit), [LabelUnit.ugDfe, LabelUnit.ug, LabelUnit.mgNe]);
    });
  });

  group('Lượng trên bảng Supplement Facts là lượng nguyên tố (B1.8)', () {
    test('xếp loại theo cách ghi trên nhãn', () {
      final cases = <(String, String, String, CompoundKind)>[
        ('calcium', 'Calcium (as calcium carbonate) 500 mg', NutrientForm.unknown, CompoundKind.elemental),
        ('calcium', 'Calcium from calcium citrate 300 mg', NutrientForm.unknown, CompoundKind.elemental),
        ('iron', 'Iron (as ferrous gluconate) 27 mg', NutrientForm.unknown, CompoundKind.elemental),
        ('calcium', 'Calcium carbonate 1250 mg', 'calcium_carbonate', CompoundKind.compound),
        ('calcium', 'Canxi carbonat 1250mg', 'calcium_carbonate', CompoundKind.compound),
        ('iron', 'Ferrous fumarate 300 mg', 'ferrous_fumarate', CompoundKind.compound),
        ('iron', 'Iron (ferrous fumarate) 100 mg', NutrientForm.unknown, CompoundKind.unknown),
        ('calcium', 'Canxi (canxi carbonat) 500mg', NutrientForm.unknown, CompoundKind.unknown),
        ('calcium', 'Calcium 500 mg', NutrientForm.unknown, CompoundKind.elemental),
      ];
      for (final (nid, text, form, kind) in cases) {
        expect(SupplementLabelParser.classifyMineral(nid, text), (form, kind), reason: text);
      }
    });

    test('nhãn "(as …)" tính đủ lượng vào giới hạn', () {
      final line = SupplementLabelParser.parseLines(const ['Iron (as ferrous gluconate) 27 mg']).single;
      final ing = EditableIngredient.fromParsed(line);
      final converted = SupplementIngredientHelper.convertLine(
        _pack,
        nutrientId: ing.nutrientId,
        form: ing.form,
        amount: ing.labelAmount!,
        unit: ing.labelUnit!,
        isCompound: ing.isCompound,
      );
      expect(converted.amounts['iron'], 27);
    });

    test('chữ đánh dấu trong bộ đọc chữ trùng dữ liệu có nguồn trong gói', () {
      final raw = jsonDecode(_packJson) as Map<String, dynamic>;
      final sfe = raw['supplementFactsElemental'] as Map<String, dynamic>;
      expect(sfe['markers'], SupplementLabelParser.elementalSourceMarkers);
      expect(sfe['source'], 'fda_21cfr_101_36');
    });
  });

  group('crossCheckAi', () {
    test('số và đơn vị có trên ảnh thì khớp, với 1,000 / 1.000 / 1000 và 2,5', () {
      for (final d in ['1,000', '1.000', '1000']) {
        final pkg = _cross(
          [
            {'name': 'Vitamin D3', 'amount': 1000, 'unit': 'iu'},
            {'name': 'Vitamin B6', 'amount': 2.5, 'unit': 'mg'},
          ],
          ['Vitamin D3 $d IU', 'Vitamin B6 2,5 mg'],
        );
        expect(pkg.ingredients.map((l) => l.needsCheck), [false, false], reason: d);
        expect(pkg.fromOnDeviceAi, isTrue);
      }
    });

    test('lệch số, lệch đơn vị hay đơn vị trống thì cần kiểm', () {
      final pkg = _cross(
        [
          {'name': 'Vitamin C', 'amount': 50, 'unit': 'mg'},
          {'name': 'Folate', 'amount': 667, 'unit': 'ug'},
          {'name': 'Zinc', 'amount': 15},
        ],
        ['Vitamin C 500 mg', 'Folate 667 mcg DFE', 'Zinc 15 mg'],
      );
      final ai = pkg.ingredients.take(3).toList();
      expect(ai.map((l) => l.needsCheck), [true, true, true]);
    });

    test('AI đổi số của hai chất cho nhau thì cả hai dòng cần kiểm', () {
      final pkg = _cross(
        [
          {'name': 'Vitamin B2', 'amount': 5, 'unit': 'mg'},
          {'name': 'Vitamin B6', 'amount': 10, 'unit': 'mg'},
        ],
        ['Vitamin B2 10 mg', 'Vitamin B6 5 mg'],
      );
      expect(pkg.ingredients, hasLength(2));
      expect(pkg.ingredients.every((l) => l.needsCheck), isTrue);
    });

    test('chất AI bỏ sót mà bộ đọc chữ thấy được thêm vào', () {
      final pkg = _cross(
        [
          {'name': 'Vitamin C', 'amount': 500, 'unit': 'mg'},
        ],
        ['Vitamin A 900 mcg', 'Vitamin C 500 mg'],
      );
      expect(pkg.ingredients.map((l) => l.nutrientId), ['vitC', 'vitA']);
      expect(pkg.ingredients.every((l) => !l.needsCheck), isTrue);
    });

    test('nhãn ghi một chất hai đơn vị chỉ ra một dòng, và dòng đó khớp', () {
      final pkg = _cross(
        [
          {'name': 'Vitamin D3', 'amount': 1000, 'unit': 'iu'},
        ],
        ['Vitamin D3 25 mcg (1,000 IU)'],
      );
      expect(pkg.ingredients, hasLength(1));
      expect(pkg.ingredients.single.nutrientId, 'vitD');
      expect(pkg.ingredients.single.needsCheck, isFalse);
    });

    test('dòng canxi khớp ảnh được xếp lại theo chữ trên ảnh; không khớp thì chưa rõ dạng', () {
      final matched = _cross(
        [
          {'name': 'Calcium', 'amount': 500, 'unit': 'mg', 'form': 'calcium carbonate', 'elemental': false},
        ],
        ['Calcium (as calcium carbonate) 500 mg'],
      );
      expect(matched.ingredients.single.compoundKind, CompoundKind.elemental);

      final unmatched = _cross(
        [
          {'name': 'Calcium', 'amount': 600, 'unit': 'mg', 'form': 'calcium carbonate', 'elemental': false},
        ],
        ['Calcium (as calcium carbonate) 500 mg'],
      );
      final ai = unmatched.ingredients.first;
      expect(ai.needsCheck, isTrue);
      expect(ai.compoundKind, CompoundKind.unknown);
    });
  });

  group('DSLD', () {
    test('đơn vị lạ để trống, % không làm lượng', () {
      final mapped = DsldIngredientMapper.mapProduct(
        _dsld([
          _fact('Vitamin B12', '500', 'mcg'),
          _fact('Folate', '1.7', 'mg DFE'),
          _fact('Vitamin D3', '5000', 'UI'),
          _fact('Vitamin C', '25', '%'),
          _fact('Thiamine', '30', 'gm'),
        ]),
        _pack,
      );
      final byId = {for (final l in mapped.ingredients) l.nutrientId: l};
      expect(byId['vitB12']!.labelUnit, LabelUnit.ug);
      expect(byId['folate']!.labelUnit, isNull);
      expect(byId['vitD']!.labelUnit, isNull);
      // Không dòng nào lấy phần trăm giá trị hằng ngày làm lượng, hay đoán đơn vị cho `gm`.
      expect(mapped.ingredients.where((l) => l.labelAmount == 25 && l.labelUnit != null), isEmpty);
      expect(mapped.ingredients.where((l) => l.labelAmount == 30 && l.labelUnit != null), isEmpty);
    });

    testWidgets('sản phẩm có dòng chưa rõ đơn vị thì không hiện Xác nhận tất cả', (tester) async {
      _phoneViewport(tester);
      final state = await _readyState();
      final mapped = DsldIngredientMapper.mapProduct(
        _dsld([_fact('Vitamin B12', '500', 'mcg'), _fact('Folate', '1.7', 'mg DFE')]),
        _pack,
      );
      await tester.pumpWidget(
        _wrap(
          state,
          ConfirmIngredientsScreen(
            initialLines: mapped.ingredients,
            fromDsld: true,
            onConfirmed: (ctx, drafts) async {},
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('Xác nhận tất cả'), findsNothing);
      expect(find.textContaining('Còn 1 dòng cần kiểm'), findsOneWidget);
    });
  });

  group('EditableIngredient', () {
    test('không đoán đơn vị khi tạo, đọc kết quả hay đọc dữ liệu đã lưu', () {
      expect(EditableIngredient().labelUnit, isNull);
      expect(
        EditableIngredient.fromParsed(const ParsedIngredientLine(rawLine: 'x', nutrientId: 'vitC', amount: 5))
            .labelUnit,
        isNull,
      );
      const saved = ProductIngredient(
        id: 1,
        productId: 1,
        nutrientId: 'vitD',
        freeName: null,
        form: NutrientForm.unknown,
        amountPerServing: 25,
        unit: 'ug',
        labelAmount: 25,
        labelUnit: 'micro',
        isCompound: false,
        origin: IngredientOrigin.ocr,
        confirmed: true,
      );
      final e = EditableIngredient.fromSaved(saved);
      expect(e.labelUnit, isNull);
      expect(e.confirmed, isFalse);
    });
  });

  group('Đơn vị chuẩn trong gói', () {
    test('mọi chất (trừ đa lượng) có đơn vị nhãn tương ứng; chữ lạ ra null', () {
      for (final d in _pack.nutrients.values.where((d) => d.group != 'macro')) {
        expect(SupplementIngredientHelper.labelUnitForPackUnit(d.unit), isNotNull, reason: d.id);
      }
      expect(SupplementIngredientHelper.labelUnitForPackUnit('L'), isNull);
      expect(SupplementIngredientHelper.labelUnitForPackUnit('xyz'), isNull);
    });
  });

  group('Món đã lưu', () {
    final corrupt = CustomFood(
      id: 1,
      name: 'Bánh yến mạch',
      portionUnit: 'gói',
      labelBasisQty: 1,
      labelBasisUnit: 'gói',
      createdAt: DateTime(2026, 11, 28),
      archived: false,
      lines: const [
        CustomFoodLine(nutrientId: 'vitC', labelAmount: 60, labelUnit: 'milli', source: IntakeSource.food),
      ],
    );

    test('mọi đơn vị lưu ra đọc lại được; chữ lạ thì báo lỗi, không đoán mg', () {
      for (final u in LabelUnit.values) {
        expect(LabelFoodBuilder.unitFromWire(LabelFoodBuilder.unitWireName(u)), u);
      }
      expect(LabelFoodBuilder.unitFromWire('milli'), isNull);
      expect(
        () => LabelFoodBuilder.entryFromCustomFood(
          corrupt,
          usedQty: 1,
          meal: Meal.breakfast,
          at: DateTime(2026, 11, 28, 8),
          pack: _pack,
        ),
        throwsFormatException,
      );
    });

    testWidgets('màn Chọn khẩu phần hiện lỗi thay vì màn đỏ, nút Lưu khóa', (tester) async {
      _phoneViewport(tester);
      final state = await _readyState();
      await tester.pumpWidget(
        _wrap(
          state,
          FoodPortionScreen.custom(
            custom: corrupt,
            initialMeal: Meal.breakfast,
            initialAt: DateTime(2026, 11, 28, 8),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.textContaining('Không đọc được số liệu của món đã lưu này'), findsOneWidget);
      expect(tester.widget<FilledButton>(find.widgetWithText(FilledButton, 'Lưu')).onPressed, isNull);
    });
  });

  group('Màn Xác nhận thành phần', () {
    List<EditableIngredient> lines() => [
          EditableIngredient(nutrientId: 'folate', labelAmount: 667, origin: IngredientOrigin.ocr),
          EditableIngredient(nutrientId: 'magnesium', labelUnit: LabelUnit.mg, origin: IngredientOrigin.ocr),
          EditableIngredient(
            nutrientId: 'vitC',
            labelAmount: 50,
            labelUnit: LabelUnit.mg,
            origin: IngredientOrigin.ocr,
            needsCheck: true,
          ),
          EditableIngredient(nutrientId: 'vitD', labelAmount: 25, labelUnit: LabelUnit.ug, origin: IngredientOrigin.ocr),
        ];

    Future<void> pumpConfirm(WidgetTester tester, List<EditableIngredient> initial) async {
      _phoneViewport(tester);
      final state = await _readyState();
      await tester.pumpWidget(
        _wrap(
          state,
          ConfirmIngredientsScreen(
            initialLines: initial,
            showAiNote: true,
            onConfirmed: (ctx, drafts) async {},
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('dòng cần kiểm bị khóa ô đánh dấu và hiện đúng lời nhắc', (tester) async {
      await pumpConfirm(tester, lines());

      expect(find.text('Gợi ý do AI trên máy tách từ chữ trên ảnh. Hãy so từng số với nhãn.'), findsOneWidget);
      expect(find.textContaining('Còn 3 dòng cần kiểm. Bấm Sửa ở từng dòng.'), findsOneWidget);
      expect(find.text('667 · Chưa rõ đơn vị'), findsOneWidget);
      expect(find.textContaining('Chưa đọc được đơn vị. Bấm Sửa và chọn đơn vị theo nhãn.'), findsOneWidget);
      expect(find.textContaining('Chưa có lượng. Bấm Sửa và nhập theo nhãn.'), findsOneWidget);
      expect(find.textContaining('Chưa thấy số này trong chữ đọc từ ảnh. Bấm Sửa để so với nhãn.'), findsOneWidget);
      expect(find.textContaining('Chọn tất cả'), findsNothing);

      final boxes = tester.widgetList<Checkbox>(find.byType(Checkbox)).toList();
      expect(boxes.map((b) => b.onChanged == null), [true, true, true, false]);
      final next = find.widgetWithText(FilledButton, 'Tiếp tục (0/4 đã xác nhận)');
      expect(tester.widget<FilledButton>(next).onPressed, isNull);
    });

    testWidgets('bảng sửa dòng không đóng khi chưa chọn đơn vị; chọn xong thì dòng được xác nhận', (tester) async {
      await pumpConfirm(tester, lines());

      await tester.tap(find.text('Sửa').first);
      await tester.pumpAndSettle();
      expect(find.text('Chọn'), findsWidgets);
      await tester.tap(find.text('Xác nhận dòng này'));
      await tester.pumpAndSettle();
      expect(find.text('Chọn đơn vị theo nhãn.'), findsOneWidget);
      expect(find.text('Sửa dòng thành phần'), findsOneWidget);

      await tester.tap(find.text('Chọn').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('µg DFE').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Xác nhận dòng này'));
      await tester.pumpAndSettle();
      expect(find.text('Sửa dòng thành phần'), findsNothing);
      expect(find.textContaining('Còn 2 dòng cần kiểm'), findsOneWidget);
      expect(tester.widgetList<Checkbox>(find.byType(Checkbox)).first.value, isTrue);
    });

    testWidgets('dòng AI chưa khớp: bảng sửa hiện lời nhắc, xác nhận qua bảng thì hết cần kiểm', (tester) async {
      await pumpConfirm(tester, lines());

      await tester.tap(find.text('Sửa').at(2));
      await tester.pumpAndSettle();
      expect(find.textContaining('So số và đơn vị với nhãn rồi bấm Xác nhận dòng này.'), findsOneWidget);
      await tester.tap(find.text('Xác nhận dòng này'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Chưa thấy số này trong chữ đọc từ ảnh'), findsNothing);
      expect(find.textContaining('Còn 2 dòng cần kiểm'), findsOneWidget);
    });

    testWidgets('lượng trống thì bảng sửa báo lỗi dưới ô lượng', (tester) async {
      await pumpConfirm(tester, lines());

      await tester.tap(find.text('Sửa').at(1));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Xác nhận dòng này'));
      await tester.pumpAndSettle();
      expect(find.text('Nhập lượng lớn hơn 0.'), findsOneWidget);
      expect(find.text('Sửa dòng thành phần'), findsOneWidget);
    });

    testWidgets('dòng mới có đơn vị trống', (tester) async {
      await pumpConfirm(tester, const []);
      await tester.tap(find.text('Thêm dòng thành phần'));
      await tester.pumpAndSettle();
      expect(find.text('Chọn'), findsWidgets);
    });
  });

  group('Kiểm toán', () {
    test('app/lib không còn chỗ mặc định đơn vị mg', () {
      final banned = [
        RegExp(r'_\s*=>\s*LabelUnit\.mg\b'),
        RegExp(r'\?\?\s*LabelUnit\.mg\b'),
        RegExp(r"\?\?\s*'mg'"),
      ];
      final hits = <String>[];
      for (final f in Directory('lib').listSync(recursive: true).whereType<File>()) {
        if (!f.path.endsWith('.dart')) continue;
        final lines = f.readAsLinesSync();
        for (var i = 0; i < lines.length; i++) {
          if (banned.any((r) => r.hasMatch(lines[i]))) hits.add('${f.path}:${i + 1}');
        }
      }
      expect(hits, isEmpty);
    });
  });
}
