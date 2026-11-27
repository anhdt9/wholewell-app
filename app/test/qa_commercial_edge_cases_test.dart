import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:health_engine/health_engine.dart';
import 'package:journal_db/journal_db.dart';
import 'package:material_ui/material_ui.dart';
import 'package:wholewell/state/app_scope.dart';
import 'package:wholewell/state/app_state.dart';
import 'package:wholewell/ui/add_workout_screen.dart';
import 'package:wholewell/ui/body_metrics_fields.dart';
import 'package:wholewell/ui/food_portion_screen.dart';
import 'package:wholewell/ui/label_food_screen.dart';
import 'package:wholewell/ui/supplements_screen.dart';
import 'package:wholewell/ui/today_doses_screen.dart';
import 'package:wholewell/ui/water_log_screen.dart';

class _SlowWorkoutRepo extends InMemoryJournalRepository {
  @override
  Future<int> addWorkout(DateTime startAt, WorkoutEntry w) async {
    await Future<void>.delayed(const Duration(milliseconds: 80));
    return super.addWorkout(startAt, w);
  }

  @override
  Future<DoseResult> recordDose(DoseInput d) async {
    await Future<void>.delayed(const Duration(milliseconds: 80));
    return super.recordDose(d);
  }
}

class _ThrowingBarcodeScanner implements BarcodeScanner {
  @override
  Future<String?> scanBarcode() async => throw StateError('scanner failure');

  @override
  Future<String?> scanBarcodeFromImage(String path) async => throw StateError('image decode failure');
}

class _ThrowingOcrEngine implements OcrEngine {
  @override
  Future<OcrImagePickResult> captureLabelImage() async => throw StateError('camera error');

  @override
  Future<OcrImagePickResult> pickLabelImageFromGallery() async => const OcrImagePickResult(paths: ['/fake/a.jpg']);

  @override
  Future<OcrLabelResult> recognizeLabelFromImage(String imagePath) async => throw StateError('ocr error');

  @override
  Future<OcrLabelResult> recognizeLabelFromImages(List<String> paths) async => throw StateError('ocr error');

  @override
  Future<String?> extractLabelJsonWithOnDeviceAi(List<String> ocrLines) async => null;

  @override
  Future<void> openAppSettings() async {}

  @override
  Future<void> dispose() async {}
}

class _ThrowingWorkoutAppState extends AppState {
  _ThrowingWorkoutAppState({required super.pack, required super.repo}) : super.withRepository();

  @override
  Future<void> addWorkout(WorkoutEntry w) async {
    await Future<void>.delayed(const Duration(milliseconds: 20));
    throw StateError('simulated storage failure');
  }
}

Future<AppState> _makeReadyState(
  ReferencePack pack, {
  JournalRepository? repo,
  FakeNotificationScheduler? scheduler,
}) async {
  final state = AppState.withRepository(
    pack: pack,
    repo: repo ?? InMemoryJournalRepository(),
    notificationScheduler: scheduler,
  );
  await state.start();
  await state.completeFirstConsent(ageYears: 28, caution: false);
  await state.saveOnboardingBodyProfile(const Profile(
    ageYears: 28,
    sex: Sex.male,
    heightCm: 172,
    weightKg: 68,
    activityLevel: ActivityLevel.active,
  ));
  return state;
}

Widget _wrapWithState(AppState state, Widget child) => AppScope(
      state: state,
      child: MaterialApp(home: child),
    );

void main() {
  late ReferencePack pack;

  setUpAll(() {
    pack = ReferencePack.fromJsonString(File('assets/reference_pack.json').readAsStringSync());
  });

  group('QA thương mại hóa: Kiểm tra biên, NaN/Infinity, double-tap & bảo mật', () {
    test('BodyMeasureValidation từ chối NaN, Infinity, 0, âm và ngoài biên 1..300', () {
      for (final bad in ['', '   ', '0', '-10', 'NaN', 'Infinity', '-Infinity', '301', 'abc']) {
        expect(BodyMeasureValidation.validateHeight(bad).isValid, isFalse, reason: 'height "$bad"');
        expect(BodyMeasureValidation.validateWeight(bad).isValid, isFalse, reason: 'weight "$bad"');
      }
      expect(BodyMeasureValidation.validateHeight('172,5').isValid, isTrue);
      expect(BodyMeasureValidation.validateWeight('68.5').isValid, isTrue);
    });

    testWidgets('WaterLogScreen chặn NaN, Infinity, <= 0 và > 5000 ml', (tester) async {
      final state = await _makeReadyState(pack);
      addTearDown(state.dispose);

      await tester.pumpWidget(_wrapWithState(state, const WaterLogScreen()));
      await tester.pumpAndSettle();

      // Chuyển sang nhập số tùy chỉnh bằng cách gõ vào ô text.
      final field = find.byType(TextField);
      for (final bad in ['NaN', 'Infinity', '0', '-50', '5001']) {
        await tester.enterText(field, bad);
        await tester.pump();
        await tester.tap(find.text('Lưu'));
        await tester.pump();
        expect(find.text('Nhập lượng nước từ 1 đến 5.000 ml.'), findsOneWidget, reason: 'bad="$bad"');
        expect(state.todayWaters, isEmpty);
      }
    });

    testWidgets('AddWorkoutScreen chống double-tap Lưu và chặn NaN/Infinity/0', (tester) async {
      final slowRepo = _SlowWorkoutRepo();
      final state = await _makeReadyState(pack, repo: slowRepo);
      addTearDown(state.dispose);

      await tester.pumpWidget(_wrapWithState(state, const AddWorkoutScreen()));
      await tester.pumpAndSettle();

      // Chọn hoạt động đầu tiên.
      await tester.tap(find.byType(RadioListTile<String>).first);
      await tester.pumpAndSettle();

      final minutesField = find.widgetWithText(TextField, 'Phút');
      for (final bad in ['NaN', 'Infinity', '0', '-15']) {
        await tester.enterText(minutesField, bad);
        await tester.pump();
        final saveBtn = tester.widget<TextButton>(find.widgetWithText(TextButton, 'Lưu'));
        expect(saveBtn.onPressed, isNull, reason: 'minutes="$bad" phải khóa nút Lưu');
      }

      // Nhập hợp lệ rồi tap Lưu liên tiếp 2 lần khi DB đang ghi chậm.
      await tester.enterText(minutesField, '45');
      await tester.pump();
      await tester.tap(find.text('Lưu'));
      await tester.pump();
      await tester.tap(find.text('Lưu'), warnIfMissed: false);
      await tester.pumpAndSettle();

      expect(state.todayWorkouts.length, 1);
      expect(state.todayWorkouts.single.minutes, 45);
    });

    testWidgets('AddWorkoutScreen nhả _saving trong finally nếu addWorkout ném ngoại lệ',
        (tester) async {
      final state = _ThrowingWorkoutAppState(pack: pack, repo: InMemoryJournalRepository());
      await state.start();
      await state.completeFirstConsent(ageYears: 28, caution: false);
      await state.saveOnboardingBodyProfile(const Profile(
        ageYears: 28,
        sex: Sex.male,
        heightCm: 172,
        weightKg: 68,
        activityLevel: ActivityLevel.active,
      ));
      addTearDown(state.dispose);

      await tester.pumpWidget(_wrapWithState(state, const AddWorkoutScreen()));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(RadioListTile<String>).first);
      await tester.pumpAndSettle();

      Object? caught;
      await runZonedGuarded(() async {
        await tester.tap(find.text('Lưu'));
        await tester.pump();
        // Khi đang chờ addWorkout, nút Lưu tạm thời khóa.
        expect(tester.widget<TextButton>(find.widgetWithText(TextButton, 'Lưu')).onPressed, isNull);
        await tester.pump(const Duration(milliseconds: 50));
      }, (e, _) => caught = e);
      expect(caught, isA<StateError>());
      await tester.pump();

      // Nhờ try/finally, màn vẫn ở lại và nút Lưu được mở khóa lại.
      expect(tester.widget<TextButton>(find.widgetWithText(TextButton, 'Lưu')).onPressed, isNotNull);
    });

    testWidgets('FoodPortionScreen xóa trống hoặc nhập 0/NaN sẽ khóa nút Lưu thay vì lưu số cũ',
        (tester) async {
      final state = await _makeReadyState(pack);
      addTearDown(state.dispose);

      final custom = CustomFood(
        id: 1,
        name: 'Sữa tươi',
        portionUnit: 'ml',
        labelBasisQty: 100,
        labelBasisUnit: 'ml',
        createdAt: DateTime(2026, 11, 27),
        archived: false,
        lines: const [
          CustomFoodLine(
            nutrientId: 'energyKcal',
            labelAmount: 60,
            labelUnit: 'kcal',
            source: IntakeSource.food,
          ),
        ],
      );

      await tester.pumpWidget(_wrapWithState(
        state,
        FoodPortionScreen.custom(
          custom: custom,
          initialMeal: Meal.breakfast,
          initialAt: DateTime(2026, 11, 27, 7, 0),
        ),
      ));
      await tester.pumpAndSettle();

      final qtyField = find.byType(TextField);
      for (final bad in ['', '0', '-5', 'NaN', 'Infinity']) {
        await tester.enterText(qtyField, bad);
        await tester.pump();
        final btn = tester.widget<FilledButton>(find.widgetWithText(FilledButton, 'Lưu'));
        expect(btn.onPressed, isNull, reason: 'qty="$bad" phải vô hiệu hóa Lưu');
      }
      expect(state.diary.todayFoods, isEmpty);
    });

    testWidgets('LabelFoodScreen từ chối NaN/Infinity/số âm trên các trường số', (tester) async {
      final state = await _makeReadyState(pack);
      addTearDown(state.dispose);

      await tester.pumpWidget(_wrapWithState(
        state,
        const LabelFoodScreen(initialMeal: Meal.snack, initialName: 'Bánh thử'),
      ));
      await tester.pumpAndSettle();

      final kcalField = find.widgetWithText(TextFormField, 'Năng lượng (kcal)');
      await tester.enterText(kcalField, 'NaN');
      await tester.pump();
      await tester.tap(find.text('Lưu'));
      await tester.pump();
      expect(find.text('Nhập số ≥ 0'), findsOneWidget);
      expect(state.diary.todayFoods, isEmpty);

      await tester.enterText(kcalField, 'Infinity');
      await tester.pump();
      await tester.tap(find.text('Lưu'));
      await tester.pump();
      expect(find.text('Nhập số ≥ 0'), findsOneWidget);
      expect(state.diary.todayFoods, isEmpty);
    });

    test('Gói dữ liệu + schedule slot bảo mật: payload nhắc giờ không mang tên chất hay sản phẩm', () async {
      final scheduler = FakeNotificationScheduler();
      final state = await _makeReadyState(pack, scheduler: scheduler);
      addTearDown(state.dispose);

      final pid = await state.diary.createProductWithIngredientsAndBox(
        name: 'Biochemical Secret Vitamin C 1000',
        countUnit: CountUnit.tablet,
        unitsPerServing: 1,
        ingredients: const [
          IngredientDraft(
            nutrientId: 'vitC',
            form: 'unknown',
            amountPerServing: 1000,
            unit: 'mg',
            labelAmount: 1000,
            labelUnit: 'mg',
            origin: IngredientOrigin.manual,
            confirmed: true,
          ),
        ],
        initialBoxRemaining: 30,
      );
      expect(pid, isNotNull);
      await state.diary.addSchedule(pid!, 7 * 60, 1.0, validFrom: dayKey(DateTime.now()));
      await state.enableNotifications(consentVersion: 'notif-1');

      expect(scheduler.syncedSlots, hasLength(1));
      final payload = scheduler.syncedSlots.single.toMap().toString();
      expect(payload, isNot(contains('Secret')));
      expect(payload, isNot(contains('Vitamin')));
      expect(payload, isNot(contains('1000')));
    });

    testWidgets('TodayDosesScreen chống double-tap Đã uống khi DB ghi chậm', (tester) async {
      final slowRepo = _SlowWorkoutRepo();
      final state = await _makeReadyState(pack, repo: slowRepo);
      addTearDown(state.dispose);

      final now = DateTime(2026, 11, 27, 8, 30);
      final pid = await state.diary.createProductWithIngredientsAndBox(
        name: 'Vitamin D3',
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
        initialBoxRemaining: 30,
      );
      await state.diary.addSchedule(pid!, 8 * 60, 1, validFrom: dayKey(now));

      await tester.pumpWidget(_wrapWithState(state, TodayDosesScreen(nowOverride: now)));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Đã uống'));
      await tester.pump();
      await tester.tap(find.text('Đã uống'), warnIfMissed: false);
      await tester.pumpAndSettle();

      final doses = await slowRepo.dosesBetween(dayKey(now), dayKey(now));
      expect(doses, hasLength(1));
    });

    testWidgets('ScanProductScreen nhả _busy khi quét ảnh/OCR ném ngoại lệ', (tester) async {
      final state = AppState.withRepository(
        pack: pack,
        repo: InMemoryJournalRepository(),
        ocrEngine: _ThrowingOcrEngine(),
        barcodeScanner: _ThrowingBarcodeScanner(),
      );
      await state.start();
      await state.completeFirstConsent(ageYears: 28, caution: false);
      await state.saveOnboardingBodyProfile(const Profile(
        ageYears: 28,
        sex: Sex.male,
        heightCm: 172,
        weightKg: 68,
        activityLevel: ActivityLevel.active,
      ));
      addTearDown(state.dispose);

      await tester.pumpWidget(_wrapWithState(state, const ScanProductScreen()));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Chụp ảnh nhãn (tên, thành phần)'));
      await tester.pumpAndSettle();

      // Sau lỗi, thông báo lỗi hiển thị và nút không bị khóa kẹt.
      expect(find.text('Chưa chọn hoặc chụp được ảnh. Thử lại.'), findsOneWidget);
      final cameraBtn = tester.widget<ButtonStyleButton>(
        find.ancestor(
          of: find.text('Chụp ảnh nhãn (tên, thành phần)'),
          matching: find.bySubtype<ButtonStyleButton>(),
        ),
      );
      expect(cameraBtn.onPressed, isNotNull);

      // Thử chọn ảnh từ thư viện -> barcode scanner ném lỗi vẫn phục hồi trạng thái _busy.
      await tester.tap(find.text('Chọn ảnh từ thư viện'));
      await tester.pumpAndSettle();
      expect(find.text('Chưa chọn hoặc chụp được ảnh. Thử lại.'), findsOneWidget);
      final galleryBtn = tester.widget<ButtonStyleButton>(
        find.ancestor(
          of: find.text('Chọn ảnh từ thư viện'),
          matching: find.bySubtype<ButtonStyleButton>(),
        ),
      );
      expect(galleryBtn.onPressed, isNotNull);
    });
  });
}
