import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:wholewell/ui/common/common_widgets.dart';

Widget _wrap(Widget child, {Brightness brightness = Brightness.light}) {
  return MaterialApp(
    theme: buildWholeWellTheme(brightness),
    home: Scaffold(body: Center(child: child)),
  );
}

void main() {
  group('PR 2 Shared Widgets', () {
    testWidgets('TwoSegmentProgressBar hiển thị Semantics, vượt mốc và overLimit ở Light & Dark', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TwoSegmentProgressBar(
                  foodAmount: 40,
                  supplementAmount: 20,
                  targetAmount: 100,
                  semanticsLabel: 'Vitamin C, 60 trên 100 mg',
                ),
                SizedBox(height: 12),
                TwoSegmentProgressBar(
                  foodAmount: 80,
                  supplementAmount: 60,
                  targetAmount: 100,
                  overLimit: true,
                  semanticsLabel: 'Magie, vượt giới hạn',
                ),
                SizedBox(height: 12),
                TwoSegmentProgressBar(
                  foodAmount: 0,
                  supplementAmount: 0,
                  targetAmount: 0,
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.bySemanticsLabel('Vitamin C, 60 trên 100 mg'), findsOneWidget);
      expect(find.bySemanticsLabel('Magie, vượt giới hạn'), findsOneWidget);
      expect(find.byType(CustomPaint), findsWidgets);

      await tester.pumpWidget(
        _wrap(
          const Padding(
            padding: EdgeInsets.all(16),
            child: TwoSegmentProgressBar(
              foodAmount: 50,
              supplementAmount: 50,
              targetAmount: 80,
              overLimit: true,
            ),
          ),
          brightness: Brightness.dark,
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(TwoSegmentProgressBar), findsOneWidget);
    });

    testWidgets('EnergyArcGauge hiển thị số tabular, tôn trọng hideCaloriesOverride', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const EnergyArcGauge(
            consumedKcal: 1150,
            targetKcal: 2000,
            hideCaloriesOverride: false,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('1150'), findsOneWidget);
      expect(find.text('/ 2000 kcal'), findsOneWidget);

      await tester.pumpWidget(
        _wrap(
          const EnergyArcGauge(
            consumedKcal: 1150,
            targetKcal: 2000,
            hideCaloriesOverride: true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('1150'), findsNothing);
      expect(find.text('/ 2000 kcal'), findsNothing);
    });

    testWidgets('TargetRangeBar xử lý dưới / trong / trên khoảng và Semantics', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TargetRangeBar(percent: 8, minPercent: 10, maxPercent: 35),
                SizedBox(height: 8),
                TargetRangeBar(
                  percent: 25,
                  minPercent: 10,
                  maxPercent: 35,
                  semanticsLabel: 'Đạm 25%',
                ),
                SizedBox(height: 8),
                TargetRangeBar(percent: 72, minPercent: 45, maxPercent: 65),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.bySemanticsLabel('Đạm 25%'), findsOneWidget);
      expect(find.bySemanticsLabel('8%, khoảng khuyến nghị 10 đến 35%'), findsOneWidget);
    });

    testWidgets('EmptyState và ErrorState hiển thị tiêu đề, mô tả và nút hành động', (tester) async {
      var retried = false;
      await tester.pumpWidget(
        _wrap(
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const EmptyState(
                title: 'Chưa có dữ liệu',
                message: 'Thêm món đầu tiên để bắt đầu.',
              ),
              ErrorState(
                title: 'Không đọc được',
                message: 'Kiểm tra lại kết nối hoặc thử lại.',
                onAction: () => retried = true,
              ),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Chưa có dữ liệu'), findsOneWidget);
      expect(find.text('Thêm món đầu tiên để bắt đầu.'), findsOneWidget);
      expect(find.text('Không đọc được'), findsOneWidget);
      await tester.tap(find.widgetWithText(FilledButton, 'Thử lại'));
      await tester.pumpAndSettle();
      expect(retried, isTrue);
    });

    testWidgets('showAppModalSheet mở sheet bo góc 24 px và trả về kết quả', (tester) async {
      String? picked;
      await tester.pumpWidget(
        MaterialApp(
          theme: buildWholeWellTheme(Brightness.light),
          home: Scaffold(
            body: Builder(
              builder: (ctx) => Center(
                child: FilledButton(
                  onPressed: () async {
                    picked = await showAppModalSheet<String>(
                      context: ctx,
                      builder: (sheetCtx) => Padding(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('Nội dung sheet'),
                            const SizedBox(height: AppSpacing.md),
                            FilledButton(
                              onPressed: () => Navigator.of(sheetCtx).pop('ok'),
                              child: const Text('Chọn'),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                  child: const Text('Mở sheet'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Mở sheet'));
      await tester.pumpAndSettle();
      expect(find.text('Nội dung sheet'), findsOneWidget);

      await tester.tap(find.text('Chọn'));
      await tester.pumpAndSettle();
      expect(picked, 'ok');
    });

    testWidgets('LoadingSkeletonBox render kích thước chuẩn và chạy animation an toàn', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const Padding(
            padding: EdgeInsets.all(16),
            child: LoadingSkeletonBox(width: 200, height: 24),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 280));
      final box = tester.renderObject<RenderBox>(find.byType(LoadingSkeletonBox));
      expect(box.size.width, 200);
      expect(box.size.height, 24);
    });
  });
}
