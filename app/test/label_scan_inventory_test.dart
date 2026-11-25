import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:health_engine/health_engine.dart';
import 'package:journal_db/journal_db.dart';
import 'package:material_ui/material_ui.dart';
import 'package:wholewell/main.dart';
import 'package:wholewell/state/app_state.dart';
import 'package:wholewell/ui/labels.dart';

void main() {
  final pack = ReferencePack.fromJsonString(File('assets/reference_pack.json').readAsStringSync());

  group('SupplementLabelParser', () {
    test('phân tích đúng các dòng tiếng Anh/tiếng Việt, hợp chất và chất ngoài gói', () {
      final parsed = SupplementLabelParser.parseLines(const [
        'Supplement Facts',
        'Vitamin D3 (cholecalciferol) 1000 IU',
        'Calcium (as calcium carbonate) 1250 mg',
        'Iron (ferrous fumarate) 100 mg',
        'Coenzyme Q10 30 mg',
      ]);
      expect(parsed, hasLength(4));
      expect(parsed[0].nutrientId, 'vitD');
      expect(parsed[0].amount, 1000);
      expect(parsed[0].unit, LabelUnit.iu);

      expect(parsed[1].nutrientId, 'calcium');
      expect(parsed[1].form, 'calcium_carbonate');
      expect(parsed[1].compoundKind, CompoundKind.compound);
      expect(parsed[1].amount, 1250);

      expect(parsed[2].nutrientId, 'iron');
      expect(parsed[2].form, 'ferrous_fumarate');
      expect(parsed[2].amount, 100);

      expect(parsed[3].nutrientId, isNull);
      expect(parsed[3].freeName, 'Coenzyme Q10');
      expect(parsed[3].amount, 30);
    });

    test('parsePackage ghép dòng 2 cột, hỗ trợ 1,250 và gợi ý tên/số viên từ ảnh mặt trước', () {
      final pkg = SupplementLabelParser.parsePackage(const [
        'Nature Made D3 + Calcium',
        '60 Tablets',
        'Supplement Facts',
        'Vitamin D3',
        '1000 IU',
        'Calcium (as calcium carbonate) 1,250 mg',
      ]);
      expect(pkg.suggestedProductName, 'Nature Made D3 + Calcium');
      expect(pkg.suggestedBoxRemaining, 60);
      expect(pkg.suggestedCountUnit, CountUnit.tablet);
      expect(pkg.ingredients, hasLength(2));
      expect(pkg.ingredients[0].nutrientId, 'vitD');
      expect(pkg.ingredients[0].amount, 1000);
      expect(pkg.ingredients[1].nutrientId, 'calcium');
      expect(pkg.ingredients[1].amount, 1250);
      expect(pkg.ingredients[1].form, 'calcium_carbonate');
    });

    test('parsePackage xử lý đúng text OCR thật từ nhãn SCanPrev Zinc Bis Glycinate 25', () {
      final pkg = SupplementLabelParser.parsePackage(const [
        'SCanPrev',
        'Zinc',
        'Bis Glycinate e 25',
        '25mg of Pure Elementa inc perCopulo',
        'P PROESSENIA',
        '7B19240 VEGETARE CAPSUES VO',
        'MATURAL HEALIH PRODUCTS',
      ]);
      expect(pkg.suggestedProductName, 'SCanPrev');
      expect(pkg.ingredients, hasLength(1));
      expect(pkg.ingredients.single.nutrientId, 'zinc');
      expect(pkg.ingredients.single.amount, 25);
      expect(pkg.ingredients.single.unit, LabelUnit.mg);
      expect(pkg.ingredients.single.compoundKind, CompoundKind.elemental);
    });

    test('parsePackage fuzzy matching sửa lỗi OCR sai ký tự chất, dạng và đơn vị', () {
      final pkg = SupplementLabelParser.parsePackage(const [
        'Serving Size: 2 Capsules',
        'Caleium carbonat 1250 mq',
        'Cholecalciferol 1000 1U',
        'Zine 500 meg',
      ]);
      expect(pkg.suggestedUnitsPerServing, 2);
      expect(pkg.ingredients, hasLength(3));
      expect(pkg.ingredients[0].nutrientId, 'calcium');
      expect(pkg.ingredients[0].form, 'calcium_carbonate');
      expect(pkg.ingredients[0].unit, LabelUnit.mg);
      expect(pkg.ingredients[1].nutrientId, 'vitD');
      expect(pkg.ingredients[1].unit, LabelUnit.iu);
      expect(pkg.ingredients[2].nutrientId, 'zinc');
      expect(pkg.ingredients[2].unit, LabelUnit.ug);

      final viPkg = SupplementLabelParser.parsePackage(const [
        'Khẩu phần: 2 viên',
        'Mỗi lần uống 1 gói',
        'Vitamin C 500 mg',
        'Folate (as Folic Acid) 667 mcg DFE',
      ]);
      expect(viPkg.suggestedUnitsPerServing, 2);
      expect(viPkg.suggestedBoxRemaining, isNull);
      expect(viPkg.ingredients[1].nutrientId, 'folate');
      expect(viPkg.ingredients[1].unit, LabelUnit.ugDfe);
      expect(unitLabel(LabelUnit.ugDfe.name), 'µg DFE');
      expect(unitLabel(LabelUnit.ugRae.name), 'µg RAE');
      expect(unitLabel(LabelUnit.mgNe.name), 'mg NE');
      expect(unitLabel(LabelUnit.iu.name), 'IU');
      expect(unitLabel(LabelUnit.ug.name), 'µg');
    });

    test('parseAiJson đọc JSON từ Gemini Nano và trả null khi JSON lỗi', () {
      expect(SupplementLabelParser.parseAiJson('not-json', const []), isNull);
      final pkg = SupplementLabelParser.parseAiJson(
        '{"productName":"Sports Research B-Complex","boxCount":120,"servings":2,"unit":"capsule",'
        '"ingredients":[{"name":"Folate","amount":667,"unit":"ug_dfe","form":"L-5-Methylfolate","elemental":false},'
        '{"name":"Vitamin B12","amount":500,"unit":"ug","form":"Methylcobalamin","elemental":false}]}',
        const ['raw'],
      );
      expect(pkg, isNotNull);
      expect(pkg!.suggestedProductName, 'Sports Research B-Complex');
      expect(pkg.suggestedBoxRemaining, 120);
      expect(pkg.suggestedUnitsPerServing, 2);
      expect(pkg.suggestedCountUnit, CountUnit.capsule);
      expect(pkg.ingredients, hasLength(2));
      expect(pkg.ingredients[0].nutrientId, 'folate');
      expect(pkg.ingredients[0].unit, LabelUnit.ugDfe);
      expect(pkg.ingredients[1].nutrientId, 'vitB12');
      expect(pkg.ingredients[1].unit, LabelUnit.ug);
    });

    test('parseExpiryMmYyyy kiểm hợp lệ tháng 01..12 và chuyển sang YYYY-MM', () {
      expect(parseExpiryMmYyyy('').ok, isTrue);
      expect(parseExpiryMmYyyy('').yyyyMm, isNull);
      expect(parseExpiryMmYyyy('08/2027'), (ok: true, yyyyMm: '2027-08'));
      expect(parseExpiryMmYyyy('13/2027').ok, isFalse);
      expect(parseExpiryMmYyyy('00/2027').ok, isFalse);
      expect(parseExpiryMmYyyy('2027-08').ok, isFalse);
    });
  });

  group('Luồng Việc 5: 4 tab, OCR giả lập, mã vạch, kho và cảnh báo', () {
    Future<AppState> makeReadyState({
      required FakeOcrEngine ocr,
      required FakeBarcodeScanner scanner,
    }) async {
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
      final state = AppState.withRepository(
        pack: pack,
        repo: repo,
        ocrEngine: ocr,
        barcodeScanner: scanner,
      );
      await state.start();
      return state;
    }

    testWidgets('quét mã vạch, từ chối camera -> thư viện OCR, cảnh báo mg/µg, xác nhận từng dòng, lưu và quét lại',
        (tester) async {
      final ocr = FakeOcrEngine(
        nextCaptureResult: const OcrImagePickResult(permissionDenied: true),
        nextGalleryResult: const OcrImagePickResult(paths: ['/fake/label.jpg']),
        nextOcrResult: const OcrLabelResult(lines: [
          'Vitamin D3 25 mg',
          'Calcium carbonate 1250 mg',
        ]),
      );
      final scanner = FakeBarcodeScanner(nextBarcode: '8935001122');
      final state = await makeReadyState(ocr: ocr, scanner: scanner);

      await tester.pumpWidget(WholeWellApp(state: state));
      await tester.pumpAndSettle();

      // Mở tab Bổ sung (tab 3/4).
      await tester.tap(find.text('Bổ sung'));
      await tester.pumpAndSettle();
      expect(find.text('Chưa có sản phẩm bổ sung nào.'), findsOneWidget);

      await tester.tap(find.text('Thêm sản phẩm'));
      await tester.pumpAndSettle();

      // Quét mã vạch chưa có trong máy.
      await tester.tap(find.text('Quét mã vạch'));
      await tester.pumpAndSettle();
      expect(find.textContaining('8935001122'), findsOneWidget);

      // Chụp ảnh bị từ chối quyền camera -> thông báo chuyển sang chọn ảnh thư viện + nút Mở cài đặt.
      await tester.tap(find.text('Chụp ảnh nhãn (tên, thành phần)'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Chưa có quyền máy ảnh'), findsOneWidget);
      expect(find.text('Mở cài đặt'), findsOneWidget);

      // Chọn ảnh từ thư viện -> bấm Đọc thông tin từ 1 ảnh -> mở Xác nhận thành phần.
      await tester.tap(find.text('Chọn ảnh từ thư viện'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Đọc thông tin từ 1 ảnh'));
      await tester.pumpAndSettle();
      expect(find.text('Xác nhận thành phần'), findsOneWidget);
      // Vitamin D3 25 mg phải hiện cảnh báo nghi nhầm đơn vị!
      expect(find.textContaining('kiểm lại đơn vị mg/µg'), findsOneWidget);

      // Nút Tiếp tục chưa bật vì chưa xác nhận dòng nào.
      final continueBtn = find.widgetWithText(FilledButton, 'Tiếp tục (0/2 đã xác nhận)');
      expect(tester.widget<FilledButton>(continueBtn).onPressed, isNull);

      // Sửa Vitamin D3 thành 25 µg rồi xác nhận cả 2 dòng.
      await tester.tap(find.text('Sửa').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('mg').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('µg').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Xác nhận dòng này'));
      await tester.pumpAndSettle();
      expect(find.textContaining('kiểm lại đơn vị mg/µg'), findsNothing);

      // Đánh dấu xác nhận dòng Canxi còn lại.
      await tester.tap(find.byType(Checkbox).last);
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Tiếp tục (2/2 đã xác nhận)'));
      await tester.pumpAndSettle();

      // Nhập tên sản phẩm và hạn dùng sai rồi sửa thành đúng.
      await tester.enterText(find.widgetWithText(TextField, 'Tên sản phẩm *'), 'Canxi D3 Test');
      await tester.enterText(find.widgetWithText(TextField, 'Số còn lại'), '30');
      await tester.enterText(find.widgetWithText(TextField, 'Hạn dùng'), '13/2027');
      await tester.tap(find.text('Lưu sản phẩm'));
      await tester.pumpAndSettle();
      expect(
        find.text('Nhập hạn dùng theo tháng/năm (MM/YYYY), tháng từ 01 đến 12.'),
        findsOneWidget,
      );

      await tester.enterText(find.widgetWithText(TextField, 'Hạn dùng'), '08/2027');
      await tester.tap(find.text('Lưu sản phẩm'));
      await tester.pumpAndSettle();

      // Đã sang Chi tiết sản phẩm: Canxi carbonat 1.250 mg -> nguyên tố 500 mg.
      expect(find.text('Canxi D3 Test'), findsOneWidget);
      expect(find.text('500 mg'), findsOneWidget);
      expect(find.textContaining('Còn 30 viên'), findsOneWidget);

      // Quay về Bổ sung -> bấm Thêm sản phẩm -> quét lại đúng mã vạch -> mở thẳng Chi tiết sản phẩm.
      await tester.pageBack();
      await tester.pumpAndSettle();
      await tester.tap(find.text('Thêm sản phẩm'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Quét mã vạch'));
      await tester.pumpAndSettle();
      expect(find.text('Canxi D3 Test'), findsOneWidget);
    });

    testWidgets('hộp hết hạn hỏi Trừ/Không trừ, vừa shortfall vừa vượt UL chỉ hiện 1 bảng cảnh báo',
        (tester) async {
      final ocr = FakeOcrEngine();
      final scanner = FakeBarcodeScanner();
      final state = await makeReadyState(ocr: ocr, scanner: scanner);

      final pid = await state.diary.createProductWithIngredientsAndBox(
        name: 'Magie Cao',
        countUnit: CountUnit.tablet,
        unitsPerServing: 1,
        ingredients: const [
          IngredientDraft(
            nutrientId: 'magnesium',
            form: NutrientForm.unknown,
            amountPerServing: 400,
            unit: 'mg',
            labelAmount: 400,
            labelUnit: 'mg',
            origin: IngredientOrigin.manual,
            confirmed: true,
          ),
        ],
        initialBoxRemaining: 1,
        initialBoxExpiryMonth: '2025-01', // Đã hết hạn
      );
      expect(pid, isNotNull);

      await tester.pumpWidget(WholeWellApp(state: state));
      await tester.pumpAndSettle();

      // 3 chạm từ nút nổi Ghi: Ghi -> Bổ sung -> chọn sản phẩm -> Lưu.
      await tester.tap(find.text('Ghi'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Bổ sung').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Magie Cao'));
      await tester.pumpAndSettle();

      // Đổi sang 2 khẩu phần (hộp hết hạn chỉ còn 1 -> vừa NeedsExpiredChoice vừa shortfall = 1) và vượt UL 400*2 = 800 > 350.
      await tester.enterText(find.byType(TextField).first, '2');
      await tester.tap(find.text('Lưu').last);
      await tester.pumpAndSettle();

      // Hiện hộp thoại hỏi trừ hộp hết hạn.
      expect(find.text('Trừ vào hộp đã hết hạn?'), findsOneWidget);
      await tester.tap(find.text('Trừ'));
      await tester.pumpAndSettle();

      // Chỉ 1 phản hồi chính: Bảng cảnh báo vượt UL kèm dòng "Kho đã hết · Thêm hộp" bên trong.
      expect(find.textContaining('Magie vượt giới hạn an toàn'), findsAtLeastNWidgets(1));
      expect(find.text('Kho đã hết · Thêm hộp'), findsOneWidget);
      expect(find.byType(SnackBar), findsNothing);

      // Đóng bảng cảnh báo -> sang Nhật ký phải hiện đúng tên sản phẩm "Magie Cao" (không bị "Bổ sung").
      await tester.tap(find.text('Đã hiểu'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Nhật ký'));
      await tester.pumpAndSettle();
      expect(find.text('Magie Cao'), findsOneWidget);
    });

    testWidgets('sửa lần uống Ghi một lần giữ tên mới và khôi phục dạng Vitamin A/E', (tester) async {
      final state = await makeReadyState(ocr: FakeOcrEngine(), scanner: FakeBarcodeScanner());
      await state.diary.recordSupplementDose(
        name: 'Viên cũ',
        servings: 1,
        at: DateTime(2026, 11, 25, 9, 0),
        lines: const [
          IntakeLine(
            nutrientId: 'vitE',
            source: IntakeSource.supplement,
            form: NutrientForm.synthetic2r,
            labelAmount: 100,
            labelUnit: 'iu',
            amounts: {'vitE': 45},
            ulAmounts: {'vitE': 90.9},
          ),
          IntakeLine(
            nutrientId: 'vitA',
            source: IntakeSource.supplement,
            form: NutrientForm.betaCarotene,
            labelAmount: 1000,
            labelUnit: 'iu',
            amounts: {'vitA': 300},
          ),
        ],
        summaryLabel: 'Viên cũ',
      );

      await tester.pumpWidget(WholeWellApp(state: state));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Nhật ký'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Viên cũ'));
      await tester.pumpAndSettle();

      // Khôi phục đúng dạng Vitamin E tổng hợp và Vitamin A beta-caroten (Switch == false).
      expect(find.text('Dạng tổng hợp (dl-alpha)'), findsOneWidget);
      final vitASwitch = tester.widget<SwitchListTile>(find.byType(SwitchListTile));
      expect(vitASwitch.value, isFalse);

      // Đổi tên mới -> Lưu -> Nhật ký hiện tên mới.
      await tester.enterText(find.widgetWithText(TextField, 'Tên sản phẩm (tùy chọn)'), 'Viên mới');
      await tester.tap(find.text('Lưu').last);
      await tester.pumpAndSettle();
      expect(find.text('Viên mới'), findsOneWidget);
    });

    testWidgets('OCR đọc nhầm đơn vị (Folate 400 mg) không crash đỏ và cho phép sửa sang µg',
        (tester) async {
      final ocr = FakeOcrEngine(
        nextGalleryResult: const OcrImagePickResult(paths: ['/fake/bcomplex.jpg']),
        nextOcrResult: const OcrLabelResult(lines: [
          'Sports Research B-Complex',
          'Folate 400 mg',
          'Vitamin B12 500 mcg',
        ]),
      );
      final state = await makeReadyState(ocr: ocr, scanner: FakeBarcodeScanner());

      await tester.pumpWidget(WholeWellApp(state: state));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Bổ sung'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Thêm sản phẩm'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Chọn ảnh từ thư viện'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Đọc thông tin từ 1 ảnh'));
      await tester.pumpAndSettle();

      // Không crash đỏ, hiện cảnh báo đơn vị chưa phù hợp cho Folate 400 mg.
      expect(find.text('Xác nhận thành phần'), findsOneWidget);
      expect(find.textContaining('chưa phù hợp với chất này'), findsOneWidget);

      // Sửa Folate: sheet tự lọc sang đơn vị hợp lệ (µg DFE / µg), chọn µg -> cảnh báo biến mất.
      await tester.tap(find.text('Sửa').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('µg DFE').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('µg').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Xác nhận dòng này'));
      await tester.pumpAndSettle();
      expect(find.textContaining('chưa phù hợp với chất này'), findsNothing);
    });
  });
}
