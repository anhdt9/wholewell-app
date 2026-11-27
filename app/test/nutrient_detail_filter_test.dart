import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:health_engine/health_engine.dart';
import 'package:journal_db/journal_db.dart';
import 'package:material_ui/material_ui.dart';
import 'package:wholewell/state/app_scope.dart';
import 'package:wholewell/state/app_state.dart';
import 'package:wholewell/ui/today_screen.dart';

Future<AppState> _makeReadyState(
  ReferencePack pack, {
  bool caution = false,
}) async {
  final repo = InMemoryJournalRepository(initialCaution: caution, initialAgeYears: 35);
  await repo.saveProfile(
    const Profile(
      ageYears: 35,
      sex: Sex.female,
      heightCm: 160,
      weightKg: 55,
      activityLevel: ActivityLevel.lowActive,
    ),
  );
  await repo.saveHideCalories(false);
  await repo.saveOnboardingStep(OnboardingStep.done);
  final state = AppState.withRepository(pack: pack, repo: repo);
  await state.start();
  return state;
}

Widget _wrap(AppState state, Widget child, {double textScale = 1.0}) {
  return AppScope(
    state: state,
    child: MaterialApp(
      theme: ThemeData(colorSchemeSeed: Colors.teal, useMaterial3: true),
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

  testWidgets('Hôm nay lọc vi chất theo Có bổ sung & Dưới mức khuyến nghị/tham chiếu',
      (tester) async {
    final state = await _makeReadyState(pack);
    await state.recordDose(
      'Viên Magie',
      const [
        IntakeLine(
          nutrientId: 'magnesium',
          source: IntakeSource.supplement,
          form: 'magnesium_citrate',
          amounts: {'magnesium': 150},
        ),
      ],
    );
    await state.addItem(
      const IntakeItem(
        label: 'Phở bò',
        source: IntakeSource.food,
        meal: MealSlot.breakfast,
        nutrients: {'energyKcal': 450, 'magnesium': 30, 'vitC': 200},
      ),
    );

    await tester.pumpWidget(_wrap(state, const Scaffold(body: TodayScreen())));
    await tester.pumpAndSettle();

    // Lọc "Có bổ sung": hiện Magie, ẩn Vitamin C (không có bổ sung).
    await tester.dragUntilVisible(
      find.text('Có bổ sung'),
      find.byType(ListView).first,
      const Offset(0, -300),
    );
    await tester.ensureVisible(find.text('Có bổ sung'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Có bổ sung'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Magie'), findsWidgets);
    expect(find.text('Vitamin C'), findsNothing);

    // Lọc "Dưới mức khuyến nghị": Vitamin C đã vượt 100% (200/75) nên không còn trong danh sách.
    await tester.ensureVisible(find.text('Dưới mức khuyến nghị'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Dưới mức khuyến nghị'));
    await tester.pumpAndSettle();
    expect(find.text('Vitamin C'), findsNothing);
    expect(find.textContaining('Magie'), findsWidgets);
  });

  testWidgets('Chạm Magie mở Chi tiết chất đủ 2 tổng, phạm vi UL riêng, đóng góp & 7 ngày',
      (tester) async {
    final state = await _makeReadyState(pack, caution: true);
    await state.recordDose(
      'Magie Citrat',
      const [
        IntakeLine(
          nutrientId: 'magnesium',
          source: IntakeSource.supplement,
          form: 'magnesium_citrate',
          amounts: {'magnesium': 150},
        ),
      ],
    );
    await state.addItem(
      const IntakeItem(
        label: 'Cơm trắng',
        source: IntakeSource.food,
        meal: MealSlot.lunch,
        nutrients: {'energyKcal': 200, 'magnesium': 30},
      ),
    );

    await tester.pumpWidget(_wrap(state, const Scaffold(body: TodayScreen())));
    await tester.pumpAndSettle();

    // Chế độ thận trọng: bộ lọc dùng "Dưới mức tham chiếu".
    await tester.dragUntilVisible(
      find.text('Dưới mức tham chiếu'),
      find.byType(ListView).first,
      const Offset(0, -300),
    );
    await tester.ensureVisible(find.text('Dưới mức tham chiếu'));
    await tester.pumpAndSettle();
    expect(find.text('Dưới mức tham chiếu'), findsOneWidget);

    await tester.dragUntilVisible(
      find.text('Magie'),
      find.byType(ListView).first,
      const Offset(0, -300),
    );
    await tester.ensureVisible(find.text('Magie').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Magie').last);
    await tester.pumpAndSettle();

    // Đã sang NutrientDetailScreen với đủ 2 tổng và phạm vi UL riêng của Magie.
    expect(find.text('Tổng mọi nguồn: 180 mg'), findsOneWidget);
    expect(find.text('Tính vào giới hạn an toàn'), findsOneWidget);
    expect(find.text('150 / 350 mg'), findsOneWidget);
    expect(find.text('Chỉ tính bổ sung bạn ghi, không tính thức ăn.'), findsOneWidget);
    expect(find.text('App không tính thuốc, trừ khi bạn ghi.'), findsOneWidget);

    // Đóng góp hôm nay phân biệt rõ tính / không tính vào giới hạn.
    await tester.dragUntilVisible(
      find.textContaining('Cơm trắng'),
      find.byType(ListView).first,
      const Offset(0, -200),
    );
    expect(find.textContaining('Magie Citrat'), findsOneWidget);
    expect(find.textContaining('Cơm trắng'), findsOneWidget);
    expect(find.textContaining('tính vào giới hạn'), findsWidgets);
    expect(find.textContaining('không tính vào giới hạn'), findsWidgets);

    // Chuyển sang 7 ngày.
    await tester.dragUntilVisible(
      find.text('7 ngày'),
      find.byType(ListView).first,
      const Offset(0, 200),
    );
    await tester.ensureVisible(find.text('7 ngày'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('7 ngày'));
    await tester.pumpAndSettle();
    await tester.dragUntilVisible(
      find.text('7 ngày qua'),
      find.byType(ListView).first,
      const Offset(0, -300),
    );
    expect(find.text('7 ngày qua'), findsOneWidget);

    // Mở Nguồn số liệu.
    await tester.dragUntilVisible(
      find.text('Nguồn số liệu ›'),
      find.byType(ListView).first,
      const Offset(0, -300),
    );
    await tester.ensureVisible(find.text('Nguồn số liệu ›'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Nguồn số liệu ›'));
    await tester.pumpAndSettle();
    expect(find.text('Nguồn số liệu'), findsOneWidget);
  });

  testWidgets('Sắt hiển thị lưu ý vitamin C và chịu được cỡ chữ 200%', (tester) async {
    final state = await _makeReadyState(pack);
    await tester.pumpWidget(_wrap(state, const Scaffold(body: TodayScreen()), textScale: 2.0));
    await tester.pumpAndSettle();

    await tester.dragUntilVisible(
      find.text('Sắt'),
      find.byType(ListView).first,
      const Offset(0, -300),
    );
    await tester.ensureVisible(find.text('Sắt'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sắt'));
    await tester.pumpAndSettle();

    await tester.dragUntilVisible(
      find.textContaining('Vitamin C hỗ trợ hấp thu sắt không heme'),
      find.byType(ListView).first,
      const Offset(0, -300),
    );
    expect(find.textContaining('Vitamin C hỗ trợ hấp thu sắt không heme'), findsOneWidget);
    await tester.dragUntilVisible(
      find.text('7 ngày'),
      find.byType(ListView).first,
      const Offset(0, 300),
    );
    await tester.ensureVisible(find.text('7 ngày'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('7 ngày'));
    await tester.pumpAndSettle();
    await tester.dragUntilVisible(
      find.text('7 ngày qua'),
      find.byType(ListView).first,
      const Offset(0, -300),
    );
    expect(find.text('7 ngày qua'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Vitamin A với amounts[retinol] (ulAmounts null) vẫn gắn đúng tính vào giới hạn',
      (tester) async {
    final state = await _makeReadyState(pack);
    await state.addItem(
      const IntakeItem(
        label: 'Gan gà',
        source: IntakeSource.food,
        meal: MealSlot.lunch,
        nutrients: {'vitA': 500, 'retinol': 500},
      ),
    );

    await tester.pumpWidget(_wrap(state, const Scaffold(body: TodayScreen())));
    await tester.pumpAndSettle();

    await tester.dragUntilVisible(
      find.text('Vitamin A'),
      find.byType(ListView).first,
      const Offset(0, -300),
    );
    await tester.ensureVisible(find.text('Vitamin A'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Vitamin A'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Gan gà'), findsOneWidget);
    expect(find.textContaining('tính vào giới hạn'), findsWidgets);
    expect(find.textContaining('không tính vào giới hạn'), findsNothing);
  });
}
