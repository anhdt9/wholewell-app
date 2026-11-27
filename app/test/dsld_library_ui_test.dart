import 'dart:io';

import 'package:dsld_library/dsld_library.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:health_engine/health_engine.dart';
import 'package:journal_db/journal_db.dart';
import 'package:material_ui/material_ui.dart';
import 'package:wholewell/main.dart';
import 'package:wholewell/state/app_state.dart';

Future<AppState> _makeReadyState({
  required ReferencePack pack,
  DsldLibraryRepository? dsld,
  String? scanBarcodeResult,
  String? scanBarcodeFromImageResult,
  OcrEngine? ocrEngine,
}) async {
  final repo = InMemoryJournalRepository();
  final state = AppState.withRepository(
    pack: pack,
    repo: repo,
    dsldLibrary: dsld,
    ocrEngine: ocrEngine,
    barcodeScanner: FakeBarcodeScanner(
      nextBarcode: scanBarcodeResult,
      nextBarcodeFromImage: scanBarcodeFromImageResult,
    ),
  );
  await state.start();
  await state.completeFirstConsent(ageYears: 30, caution: false);
  await state.saveOnboardingBodyProfile(const Profile(
    ageYears: 30,
    sex: Sex.male,
    heightCm: 170,
    weightKg: 65,
    activityLevel: ActivityLevel.active,
  ));
  return state;
}

DsldLibraryRepository _fakeDsld() => FakeDsldLibraryRepository(
      products: const [
        DsldProductDetail(
          dsldId: 268234,
          barcode: '023249012344',
          productName: 'Vitamin D3 + K2',
          brandName: 'Sports Research',
          servingSize: '1 Liquid Veggie Softgel',
          supplementForm: 'Softgel',
          netContents: '60 Softgels',
          suggestedUse: 'Take 1 veggie softgel daily with food.',
          otherIngredients: 'Coconut oil, tapioca starch, vegetable glycerin.',
          facts: [
            DsldFact(
              ingredient: 'Vitamin D3 (cholecalciferol)',
              category: 'vitamin',
              amount: '125',
              unit: 'mcg',
              dvPercent: '625',
              dvGroup: 'Adults',
            ),
          ],
        ),
        DsldProductDetail(
          dsldId: 318254,
          barcode: '023249010111',
          productName: 'Tart Cherry Fruit Complex 800 mg',
          brandName: 'Sports Research',
          servingSize: '1 Softgel(s)',
          supplementForm: 'Softgel',
          netContents: '60 Softgels',
          suggestedUse: 'Take 1 softgel daily.',
          otherIngredients: 'Rice bran oil, gelatin.',
          facts: [
            DsldFact(
              ingredient: 'Vitamin C',
              category: 'vitamin',
              amount: '60',
              unit: 'mg',
              dvPercent: '67',
              dvGroup: 'Adults',
            ),
          ],
        ),
        DsldProductDetail(
          dsldId: 326285,
          barcode: '023249010111',
          productName: 'Tart Cherry Fruit Complex',
          brandName: 'Sports Research',
          servingSize: '1 Softgel(s)',
          supplementForm: 'Softgel',
          netContents: '60 Softgels',
          suggestedUse: 'Take 1 softgel daily.',
          otherIngredients: 'Rice bran oil.',
          facts: [
            DsldFact(
              ingredient: 'Vitamin C',
              category: 'vitamin',
              amount: '60',
              unit: 'mg',
              dvPercent: '67',
              dvGroup: 'Adults',
            ),
          ],
        ),
      ],
    );

void main() {
  final pack = ReferencePack.fromJsonString(File('assets/reference_pack.json').readAsStringSync());

  testWidgets('Quét mã vạch khớp DSLD điền sẵn, Xác nhận tất cả, lưu và hiện tá dược', (tester) async {
    final state = await _makeReadyState(
      pack: pack,
      dsld: _fakeDsld(),
      scanBarcodeResult: '0 23249 01234 4',
    );
    await tester.pumpWidget(WholeWellApp(state: state));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Bổ sung'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Thêm sản phẩm'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Quét mã vạch'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Điền sẵn từ thư viện nhãn Mỹ (NIH DSLD)'), findsOneWidget);
    expect(find.text('Xác nhận tất cả (1)'), findsOneWidget);

    await tester.tap(find.text('Xác nhận tất cả (1)'));
    await tester.pumpAndSettle();

    // Sang màn Thông tin sản phẩm đã điền sẵn tên & mã vạch.
    expect(find.text('Thông tin sản phẩm'), findsOneWidget);
    await tester.tap(find.text('Lưu sản phẩm'));
    await tester.pumpAndSettle();

    // Sang Chi tiết sản phẩm: có mục Cách dùng trên nhãn & Thành phần khác (theo nhãn).
    expect(find.text('Cách dùng trên nhãn'), findsOneWidget);
    expect(find.text('Thành phần khác (theo nhãn)'), findsOneWidget);
  });

  testWidgets('Quét mã vạch có nhiều bản ghi DSLD mở sheet Chọn phiên bản nhãn', (tester) async {
    final state = await _makeReadyState(
      pack: pack,
      dsld: _fakeDsld(),
      scanBarcodeResult: '023249010111',
    );
    await tester.pumpWidget(WholeWellApp(state: state));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Bổ sung'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Thêm sản phẩm'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Quét mã vạch'));
    await tester.pumpAndSettle();

    expect(find.text('Chọn phiên bản nhãn'), findsOneWidget);
    await tester.tap(find.text('Tart Cherry Fruit Complex 800 mg'));
    await tester.pumpAndSettle();

    expect(find.text('Xác nhận tất cả (1)'), findsOneWidget);
  });

  testWidgets('Tìm theo tên sản phẩm trong thư viện DSLD và không khớp mã vạch', (tester) async {
    final state = await _makeReadyState(
      pack: pack,
      dsld: _fakeDsld(),
      scanBarcodeResult: '023249094012',
    );
    await tester.pumpWidget(WholeWellApp(state: state));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Bổ sung'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Thêm sản phẩm'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Quét mã vạch'));
    await tester.pumpAndSettle();

    expect(find.text('Chưa thấy trong thư viện nhãn. Hãy chụp bảng thành phần hoặc nhập tay.'), findsOneWidget);

    await tester.tap(find.text('Tìm theo tên sản phẩm'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Vitamin D3');
    await tester.pumpAndSettle();

    expect(find.text('Vitamin D3 + K2'), findsOneWidget);
    await tester.tap(find.text('Vitamin D3 + K2'));
    await tester.pumpAndSettle();

    expect(find.text('Xác nhận tất cả (1)'), findsOneWidget);
  });

  testWidgets('Chọn ảnh từ thư viện tự dò mã vạch trên ảnh và khớp DSLD', (tester) async {
    final ocr = FakeOcrEngine(nextGalleryResult: const OcrImagePickResult(paths: ['/tmp/bottle.jpg']));
    final state = await _makeReadyState(
      pack: pack,
      dsld: _fakeDsld(),
      ocrEngine: ocr,
      scanBarcodeFromImageResult: '0 23249 01234 4',
    );
    await tester.pumpWidget(WholeWellApp(state: state));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Bổ sung'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Thêm sản phẩm'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Chọn ảnh từ thư viện'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Điền sẵn từ thư viện nhãn Mỹ (NIH DSLD)'), findsOneWidget);
    expect(find.text('Xác nhận tất cả (1)'), findsOneWidget);
  });
}
