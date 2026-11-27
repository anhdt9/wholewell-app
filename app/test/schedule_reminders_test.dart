import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:health_engine/health_engine.dart';
import 'package:journal_db/journal_db.dart';
import 'package:material_ui/material_ui.dart';
import 'package:wholewell/main.dart';
import 'package:wholewell/state/app_state.dart';

Future<AppState> _makeReadyState({
  required ReferencePack pack,
  FakeNotificationScheduler? scheduler,
}) async {
  final repo = InMemoryJournalRepository();
  final state = AppState.withRepository(
    pack: pack,
    repo: repo,
    notificationScheduler: scheduler,
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

void main() {
  final pack = ReferencePack.fromJsonString(File('assets/reference_pack.json').readAsStringSync());

  testWidgets('Đặt lịch lần đầu -> Giờ trong ngày -> Bảng cảnh báo lịch -> Đồng ý Nhắc giờ -> Xóa lịch',
      (tester) async {
    final scheduler = FakeNotificationScheduler();
    final state = await _makeReadyState(pack: pack, scheduler: scheduler);

    await state.diary.createProductWithIngredientsAndBox(
      name: 'Magie Cao',
      countUnit: CountUnit.tablet,
      unitsPerServing: 1,
      ingredients: const [
        IngredientDraft(
          nutrientId: 'magnesium',
          form: 'unknown',
          amountPerServing: 400,
          unit: 'mg',
          labelAmount: 400,
          labelUnit: 'mg',
          origin: IngredientOrigin.manual,
          confirmed: true,
        ),
      ],
      initialBoxRemaining: 30,
    );

    await tester.pumpWidget(WholeWellApp(state: state));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Bổ sung'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Magie Cao'));
    await tester.pumpAndSettle();

    expect(find.text('Chưa có lịch uống'), findsOneWidget);
    await tester.tap(find.text('Đặt lịch'));
    await tester.pumpAndSettle();

    // Lần đầu: qua Giờ trong ngày trước.
    expect(find.text('Giờ trong ngày'), findsOneWidget);
    await tester.tap(find.text('Xác nhận và tiếp tục'));
    await tester.pumpAndSettle();

    // Sang Đặt lịch -> Lưu lịch -> vượt UL 350 mg -> Bảng cảnh báo lịch.
    expect(find.text('Đặt lịch: Magie Cao'), findsOneWidget);
    await tester.tap(find.text('Lưu lịch'));
    await tester.pumpAndSettle();

    expect(find.text('⚠ Lịch này vượt giới hạn an toàn'), findsOneWidget);
    await tester.tap(find.text('Vẫn lưu'));
    await tester.pumpAndSettle();

    // Lần đầu: màn đồng ý Nhắc giờ (checkbox chưa đánh sẵn).
    expect(find.text('Nhắc giờ'), findsOneWidget);
    await tester.tap(find.text('Tôi đồng ý bật thông báo nhắc giờ trên máy này'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Bật nhắc giờ'));
    await tester.pumpAndSettle();

    expect(scheduler.syncedSlots, hasLength(1));
    expect(state.diary.todaySchedules, hasLength(1));

    // Sửa lịch vừa tạo -> Xóa lịch này.
    final schedTile = find.textContaining('Lịch: mỗi ngày');
    expect(schedTile, findsOneWidget);
    await tester.tap(schedTile);
    await tester.pumpAndSettle();

    expect(find.text('Xóa lịch này'), findsOneWidget);
    await tester.tap(find.text('Xóa lịch này'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Xóa lịch'));
    await tester.pumpAndSettle();

    expect(state.diary.todaySchedules, isEmpty);
  });

  testWidgets('Hôm nay hiện SafetyNote lưu ý lịch thu gọn được, TipCard Bạn có biết & công tắc Tôi -> Hiển thị',
      (tester) async {
    final state = await _makeReadyState(pack: pack);
    // Xác nhận sẵn Giờ trong ngày và bật đồng ý thông báo.
    await state.diary.saveDayTimesSettings(const DayTimesSettings(dayTimesConfirmed: true));
    await state.diary.grantNotificationConsent('notif-1');

    // Sản phẩm 1: Canxi carbonat 600 mg lúc 07:00 (cùng bữa sáng -> chỉ dính quy tắc 1: >500mg).
    // Sản phẩm 2: Vitamin D 25 µg -> đủ chất cho TipCard quy tắc 5 ("Chất béo trong bữa...").
    final caId = await state.diary.createProductWithIngredientsAndBox(
      name: 'Canxi Carbonat 600',
      countUnit: CountUnit.tablet,
      unitsPerServing: 1,
      ingredients: const [
        IngredientDraft(
          nutrientId: 'calcium',
          form: 'calcium_carbonate',
          amountPerServing: 600,
          unit: 'mg',
          labelAmount: 1500,
          labelUnit: 'mg',
          isCompound: true,
          origin: IngredientOrigin.manual,
          confirmed: true,
        ),
      ],
      initialBoxRemaining: 20,
    );
    await state.diary.createProductWithIngredientsAndBox(
      name: 'Vitamin D3',
      countUnit: CountUnit.softgel,
      unitsPerServing: 1,
      ingredients: const [
        IngredientDraft(
          nutrientId: 'vitD',
          form: 'unknown',
          amountPerServing: 25,
          unit: 'ug',
          labelAmount: 1000,
          labelUnit: 'iu',
          origin: IngredientOrigin.manual,
          confirmed: true,
        ),
      ],
      initialBoxRemaining: 20,
    );
    await state.diary.addSchedule(caId!, 420, 1, validFrom: dayKey(state.day));

    await tester.pumpWidget(WholeWellApp(state: state));
    await tester.pumpAndSettle();

    // Lưu ý lịch quy tắc 1 hiện trên Hôm nay và thu gọn với "Đã hiểu".
    expect(find.text('Canxi hấp thu tốt nhất khi mỗi lần không quá 500 mg.'), findsOneWidget);
    await tester.tap(find.text('Đã hiểu'));
    await tester.pumpAndSettle();
    expect(find.text('Lưu ý lịch (1)'), findsOneWidget);

    // TipCard "Bạn có biết" hiện vì không có cảnh báo vượt UL.
    await tester.scrollUntilVisible(find.text('Bạn có biết'), 300);
    expect(find.text('Bạn có biết'), findsOneWidget);

    // Bấm Xem nguồn › -> mở màn Nguồn số liệu.
    await tester.ensureVisible(find.text('Xem nguồn ›'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Xem nguồn ›'));
    await tester.pumpAndSettle();
    expect(find.text('Nguồn số liệu'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();

    // Sang Tôi -> Hiển thị tắt thẻ Bạn có biết.
    await tester.tap(find.text('Tôi'));
    await tester.pumpAndSettle();
    expect(find.text('Giờ trong ngày'), findsOneWidget);
    expect(find.text('Nhắc giờ'), findsOneWidget);
    await tester.tap(find.text('Hiển thị'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Hiện thẻ "Bạn có biết"'));
    await tester.pumpAndSettle();
    await tester.pageBack();
    await tester.pumpAndSettle();

    await tester.tap(find.text('Hôm nay'));
    await tester.pumpAndSettle();
    expect(find.text('Bạn có biết'), findsNothing);
  });

  testWidgets('Cold start từ nút Đã uống trên thông báo -> Sheet xác nhận -> Hỏi hộp hết hạn -> Báo UL',
      (tester) async {
    final repo = InMemoryJournalRepository();
    final scheduler = FakeNotificationScheduler(
      pendingAction: const NotificationAction(
        kind: NotificationActionKind.markTaken,
        timeOfDayMinutes: 480,
        scheduleIds: [4],
      ),
    );
    final state = AppState.withRepository(
      pack: pack,
      repo: repo,
      notificationScheduler: scheduler,
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

    // Sản phẩm chỉ còn hộp ĐÃ HẾT HẠN và vượt UL Magie (400 mg > 350 mg).
    final createdPid = await repo.addProduct('Magie Hết Hạn', CountUnit.tablet, 1);
    expect(createdPid, isPositive);
    await repo.saveProductIngredients(createdPid, const [
      IngredientDraft(
        nutrientId: 'magnesium',
        form: 'unknown',
        amountPerServing: 400,
        unit: 'mg',
        labelAmount: 400,
        labelUnit: 'mg',
        origin: IngredientOrigin.manual,
        confirmed: true,
      ),
    ]);
    await repo.addBox(createdPid, 10, expiryMonth: '2020-01');
    final sid = await repo.addSchedule(createdPid, 480, 1, validFrom: '2026-11-01');
    scheduler.pendingAction = NotificationAction(
      kind: NotificationActionKind.markTaken,
      timeOfDayMinutes: 480,
      scheduleIds: [sid],
    );
    await state.diary.reload();

    await tester.pumpWidget(WholeWellApp(state: state));
    await tester.pumpAndSettle();

    // Sheet Xác nhận lần nhắc tự mở ngay khi vào app (cold start).
    expect(find.text('Đến giờ uống · 08:00'), findsOneWidget);
    await tester.tap(find.text('Ghi đã chọn (1)'));
    await tester.pumpAndSettle();

    // Hỏi Trừ vào hộp đã hết hạn?
    expect(find.text('Trừ vào hộp đã hết hạn?'), findsOneWidget);
    await tester.tap(find.text('Không trừ'));
    await tester.pumpAndSettle();

    // Ghi thành công, vượt UL -> hiện Bảng cảnh báo + gọi showUlAlertNotice + cancelWindow.
    expect(find.textContaining('Magie vượt giới hạn an toàn'), findsAtLeastNWidgets(1));
    expect(scheduler.ulAlertCount, 1);
    expect(scheduler.canceledWindows, [480]);
  });

  testWidgets('startOver, archiveProduct xóa/đồng bộ lịch nhắc và xem ngày hôm qua vẫn ghi đúng hôm nay',
      (tester) async {
    final scheduler = FakeNotificationScheduler();
    final state = await _makeReadyState(pack: pack, scheduler: scheduler);
    await state.diary.grantNotificationConsent('notif-1');
    await state.diary.saveDayTimesSettings(const DayTimesSettings(dayTimesConfirmed: true));

    final pid = await state.diary.createProductWithIngredientsAndBox(
      name: 'Kẽm 15',
      countUnit: CountUnit.tablet,
      unitsPerServing: 1,
      ingredients: const [
        IngredientDraft(
          nutrientId: 'zinc',
          form: 'unknown',
          amountPerServing: 15,
          unit: 'mg',
          labelAmount: 15,
          labelUnit: 'mg',
          origin: IngredientOrigin.manual,
          confirmed: true,
        ),
      ],
      initialBoxRemaining: 10,
    );
    await state.diary.addSchedule(pid!, 480, 1, validFrom: dayKey(DateTime.now()));
    await state.syncNotifications();
    expect(scheduler.syncedSlots, hasLength(1));

    // Lỗi 3: chuyển ngày đang xem về hôm qua, mở Bổ sung -> Lần uống hôm nay vẫn thấy lịch của hôm nay.
    await state.setDay(DateTime.now().subtract(const Duration(days: 1)));
    expect(state.diary.actualTodaySchedules, hasLength(1));

    await tester.pumpWidget(WholeWellApp(state: state));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Bổ sung'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Lần uống hôm nay'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Kẽm 15'), findsOneWidget);

    // Lỗi 2: lưu trữ sản phẩm đồng bộ lại scheduler -> syncedSlots rỗng.
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Kẽm 15'));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Lưu trữ sản phẩm'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Lưu trữ'));
    await tester.pumpAndSettle();
    expect(scheduler.syncedSlots, isEmpty);

    // Lỗi 1: thêm lại lịch và gọi startOver() / withdrawConsentAndReset() -> xóa hết lịch nhắc Android.
    final pid2 = await state.diary.createProductWithIngredientsAndBox(
      name: 'Vitamin C',
      countUnit: CountUnit.tablet,
      unitsPerServing: 1,
      ingredients: const [],
    );
    await state.diary.addSchedule(pid2!, 720, 1, validFrom: dayKey(DateTime.now()));
    await state.syncNotifications();
    expect(scheduler.syncedSlots, hasLength(1));

    await state.withdrawConsentAndReset();
    expect(scheduler.syncedSlots, isEmpty);
  });
}
