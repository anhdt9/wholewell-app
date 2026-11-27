import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:health_engine/health_engine.dart';
import 'package:journal_db/journal_db.dart';
import 'package:material_ui/material_ui.dart';
import 'package:wholewell/state/app_scope.dart';
import 'package:wholewell/state/app_state.dart';
import 'package:wholewell/ui/diary_screen.dart';
import 'package:wholewell/ui/home_screen.dart';
import 'package:wholewell/ui/product_detail_screen.dart';
import 'package:wholewell/ui/profile_screen.dart';
import 'package:wholewell/ui/today_screen.dart';

Future<AppState> _readyState(
  ReferencePack pack, {
  JournalRepository? repo,
}) async {
  final state = AppState.withRepository(
    pack: pack,
    repo: repo ?? InMemoryJournalRepository(),
  );
  await state.start();
  await state.completeFirstConsent(ageYears: 30, caution: false);
  await state.saveOnboardingBodyProfile(
    const Profile(
      ageYears: 30,
      sex: Sex.female,
      heightCm: 160,
      weightKg: 55,
      activityLevel: ActivityLevel.lowActive,
    ),
  );
  return state;
}

Widget _wrap(AppState state, Widget child, {ThemeData? theme, double textScale = 1.0}) {
  return AppScope(
    state: state,
    child: MaterialApp(
      theme: theme ?? ThemeData(colorSchemeSeed: Colors.teal, useMaterial3: true),
      builder: (ctx, c) => MediaQuery(
        data: MediaQuery.of(ctx).copyWith(textScaler: TextScaler.linear(textScale)),
        child: c!,
      ),
      home: child,
    ),
  );
}

void main() {
  late ReferencePack pack;

  setUpAll(() {
    pack = ReferencePack.fromJsonString(
      File('../packages/health_engine/assets/reference_pack.json').readAsStringSync(),
    );
  });

  testWidgets('P0: tạo sản phẩm mới từ stack sâu xong bấm Back về thẳng màn gốc', (tester) async {
    final state = await _readyState(pack);
    await tester.pumpWidget(
      _wrap(
        state,
        Builder(
          builder: (ctx) => Scaffold(
            body: Center(
              child: FilledButton(
                onPressed: () {
                  Navigator.of(ctx).push(
                    MaterialPageRoute<void>(
                      builder: (ctx2) => Scaffold(
                        body: Center(
                          child: FilledButton(
                            onPressed: () {
                              Navigator.of(ctx2).push(
                                MaterialPageRoute<void>(
                                  builder: (_) => const ProductInfoScreen(initialName: 'Canxi Test'),
                                ),
                              );
                            },
                            child: const Text('Mở info'),
                          ),
                        ),
                      ),
                    ),
                  );
                },
                child: const Text('Mở quét'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Mở quét'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Mở info'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Lưu sản phẩm'));
    await tester.pumpAndSettle();

    expect(find.byType(ProductDetailScreen), findsOneWidget);
    expect(find.text('Canxi Test'), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();

    expect(find.text('Mở quét'), findsOneWidget);
    expect(find.text('Mở info'), findsNothing);
    expect(find.byType(ProductInfoScreen), findsNothing);
  });

  testWidgets('P1: chạm lại tab Hôm nay và onResume nền > 5 phút đưa ngày đang xem về hôm nay',
      (tester) async {
    final state = await _readyState(pack);
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    await state.setDay(yesterday);
    expect(state.diary.isViewingToday, isFalse);

    await tester.pumpWidget(_wrap(state, const HomeScreen()));
    await tester.pumpAndSettle();

    // Chạm lại tab Hôm nay -> tự về hôm nay.
    await tester.tap(find.text('Hôm nay').last);
    await tester.pumpAndSettle();
    expect(state.diary.isViewingToday, isTrue);

    // Chuyển lại hôm qua và giả lập ở nền 6 phút ở màn ghi (atRootScreen: false) -> giữ nguyên.
    await state.setDay(yesterday);
    final baseTime = DateTime.now();
    state.onAppBackgrounded(now: baseTime);
    await state.onAppResume(
      atRootScreen: false,
      now: baseTime.add(const Duration(minutes: 6)),
    );
    expect(state.diary.isViewingToday, isFalse);

    // Quay lại nền > 5 phút khi ở root (atRootScreen: true) -> tự về hôm nay.
    state.onAppBackgrounded(now: baseTime);
    await state.onAppResume(
      atRootScreen: true,
      now: baseTime.add(const Duration(minutes: 6)),
    );
    expect(state.diary.isViewingToday, isTrue);
  });

  testWidgets('P1: chạm để sửa buổi tập và vuốt xóa có hộp thoại xác nhận trong Nhật ký',
      (tester) async {
    final state = await _readyState(pack);
    await state.addWorkout(WorkoutEntry(activityCode: pack.activities.keys.first, minutes: 30));

    await tester.pumpWidget(_wrap(state, const Scaffold(body: DiaryScreen())));
    await tester.pumpAndSettle();

    expect(find.text('30 phút'), findsOneWidget);

    // Chạm buổi tập -> mở màn Sửa buổi tập và cập nhật phút.
    await tester.tap(find.text('30 phút'));
    await tester.pumpAndSettle();
    expect(find.text('Sửa buổi tập'), findsOneWidget);

    await tester.enterText(find.widgetWithText(TextField, 'Phút'), '45');
    await tester.pump();
    await tester.tap(find.text('Lưu'));
    await tester.pumpAndSettle();

    expect(state.todayWorkouts.single.minutes, 45);
    expect(find.text('45 phút'), findsOneWidget);

    // Vuốt xóa -> hiện hộp thoại xác nhận, Hủy giữ nguyên, Xóa mới xóa.
    await tester.drag(find.byType(Dismissible).first, const Offset(-500, 0));
    await tester.pumpAndSettle();
    expect(find.text('Xóa buổi tập?'), findsOneWidget);
    await tester.tap(find.text('Hủy'));
    await tester.pumpAndSettle();
    expect(state.todayWorkouts.length, 1);

    await tester.drag(find.byType(Dismissible).first, const Offset(-500, 0));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Xóa'));
    await tester.pumpAndSettle();
    expect(state.todayWorkouts, isEmpty);
  });

  testWidgets('P1: xóa dữ liệu ở Hồ sơ dùng hộp thoại xác nhận gõ XÓA', (tester) async {
    final state = await _readyState(pack);
    await tester.pumpWidget(_wrap(state, const ProfileScreen()));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('Xóa toàn bộ dữ liệu'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Xóa toàn bộ dữ liệu'));
    await tester.pumpAndSettle();

    expect(find.text('Gõ XÓA để xác nhận.'), findsOneWidget);
    await tester.tap(find.text('Hủy'));
    await tester.pumpAndSettle();
  });

  testWidgets('P2: TodayScreen dựng ổn định ở Dark Mode và cỡ chữ 200%', (tester) async {
    final state = await _readyState(pack);
    await state.addItem(
      const IntakeItem(
        label: 'Cơm test',
        source: IntakeSource.food,
        meal: MealSlot.lunch,
        nutrients: {'energyKcal': 500, 'protein_g': 30, 'fat_g': 15, 'carb_g': 60},
      ),
    );

    await tester.pumpWidget(
      _wrap(
        state,
        const Scaffold(body: TodayScreen()),
        theme: ThemeData(
          colorSchemeSeed: Colors.teal,
          brightness: Brightness.dark,
          useMaterial3: true,
        ),
        textScale: 2.0,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Năng lượng'), findsOneWidget);
    expect(find.text('Tỷ lệ đạm, béo, bột đường'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
