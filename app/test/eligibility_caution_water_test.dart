import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:health_engine/health_engine.dart';
import 'package:journal_db/journal_db.dart';
import 'package:material_ui/material_ui.dart';
import 'package:wholewell/main.dart';
import 'package:wholewell/state/app_state.dart';
import 'package:wholewell/ui/diary_screen.dart';
import 'package:wholewell/ui/labels.dart';
import 'package:wholewell/ui/profile_screen.dart';
import 'package:wholewell/ui/today_screen.dart';
import 'package:wholewell/ui/water_log_screen.dart';

void main() {
  final pack = ReferencePack.fromJsonString(File('assets/reference_pack.json').readAsStringSync());

  Directory makeTempDir() {
    final dir = Directory.systemTemp.createTempSync('wholewell_v4_');
    addTearDown(() {
      if (dir.existsSync()) dir.deleteSync(recursive: true);
    });
    return dir;
  }

  DbOpener makeOpener(Directory dir, FakeSecureKeyStore keys) => DbOpener(
        files: DbFiles(dir),
        keys: keys,
        executorFactory: sameIsolateExecutor,
        retryDelay: Duration.zero,
      );

  group('việc 4: điều kiện, đồng ý, khởi tạo CSDL và tiếp tục bước dở', () {
    testWidgets('không tạo CSDL/khóa trước khi đồng ý; <18/mang thai vào Chưa dùng được; nối lại 3/4, 4/4',
        (tester) async {
      final dir = makeTempDir();
      final keys = FakeSecureKeyStore();
      final opener = makeOpener(dir, keys);
      final state = AppState(pack: pack, opener: opener);
      await tester.runAsync(state.start);
      addTearDown(() async {
        await state.session.repo?.close();
        state.dispose();
      });

      await tester.pumpWidget(WholeWellApp(state: state));
      await tester.pumpAndSettle();

      // Chào mừng: không có nút Khôi phục từ bản sao lưu.
      expect(find.text('WholeWell'), findsOneWidget);
      expect(find.text('Khôi phục từ bản sao lưu'), findsNothing);
      await tester.tap(find.text('Bắt đầu'));
      await tester.pumpAndSettle();

      // Điều kiện 1/4: tuổi 17 -> Chưa dùng được, không tạo tệp/khóa.
      await tester.enterText(find.byType(TextField), '17');
      await tester.tap(find.text('Không').first);
      await tester.tap(find.text('Không').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Tiếp tục'));
      await tester.pumpAndSettle();

      expect(find.textContaining('từ 18 tuổi'), findsOneWidget);
      expect(dir.listSync(), isEmpty);
      expect(keys.key, isNull);

      // Quay lại giữ nguyên câu trả lời cũ; sửa tuổi thành 35 để sang Đồng ý.
      await tester.tap(find.text('Quay lại'));
      await tester.pumpAndSettle();
      expect(find.text('17'), findsOneWidget);
      await tester.enterText(find.byType(TextField), '35');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Tiếp tục'));
      await tester.pumpAndSettle();

      // Màn Đồng ý 2/4: bấm Không đồng ý -> vẫn chưa có CSDL.
      expect(find.text('2/4'), findsOneWidget);
      expect(find.textContaining('xóa ở tab Tôi'), findsOneWidget);
      await tester.tap(find.text('Không đồng ý'));
      await tester.pumpAndSettle();
      expect(find.textContaining('App cần đồng ý này để tính toán'), findsOneWidget);
      await tester.tap(find.text('Quay lại'));
      await tester.pumpAndSettle();
      expect(dir.listSync(), isEmpty);
      expect(keys.key, isNull);

      // Đánh dấu đồng ý -> tạo CSDL với mvp-1 và sang 3/4.
      await tester.tap(find.byType(CheckboxListTile));
      await tester.pumpAndSettle();
      await tester.runAsync(() async {
        await tester.tap(find.text('Đồng ý và tiếp tục'));
        await Future<void>.delayed(const Duration(milliseconds: 20));
      });
      await tester.pumpAndSettle();

      expect(find.text('3/4'), findsOneWidget);
      expect(keys.key, isNotNull);
      expect(dir.listSync(), isNotEmpty);
      expect((await state.session.repo!.latestHealthConsent())?.contentVersion, mvpConsentVersion);

      // Thoát ở 3/4 rồi mở lại: vào thẳng 3/4.
      await tester.runAsync(() => state.session.repo!.close());
      final state2 = AppState(pack: pack, opener: opener);
      await tester.runAsync(state2.start);
      addTearDown(() async {
        await state2.session.repo?.close();
        state2.dispose();
      });
      await tester.pumpWidget(WholeWellApp(state: state2));
      await tester.pumpAndSettle();
      expect(find.text('3/4'), findsOneWidget);

      // Nhập sai chiều cao (= 0) -> chặn; nhập 110 -> nhắc nhẹ nhưng vẫn qua 4/4.
      await tester.tap(find.text('Nữ'));
      await tester.enterText(find.widgetWithText(TextField, 'Chiều cao'), '0');
      await tester.enterText(find.widgetWithText(TextField, 'Cân nặng'), '55');
      await tester.pumpAndSettle();
      expect(find.text('Nhập chiều cao hợp lệ (1–300 cm).'), findsOneWidget);

      await tester.enterText(find.widgetWithText(TextField, 'Chiều cao'), '110');
      await tester.pumpAndSettle();
      expect(find.text('Kiểm tra lại chiều cao.'), findsOneWidget);
      await tester.tap(find.byType(DropdownButtonFormField<ActivityLevel>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Vận động nhẹ').last);
      await tester.pumpAndSettle();
      await tester.runAsync(() async {
        await tester.tap(find.text('Tiếp tục'));
        await Future<void>.delayed(const Duration(milliseconds: 20));
      });
      await tester.pumpAndSettle();

      expect(find.text('4/4'), findsOneWidget);

      // Thoát ở 4/4 rồi mở lại: vào thẳng 4/4, không chọn sẵn, chọn Ẩn số calo -> Hôm nay.
      await tester.runAsync(() => state2.session.repo!.close());
      final state3 = AppState(pack: pack, opener: opener);
      await tester.runAsync(state3.start);
      addTearDown(() async {
        await state3.session.repo?.close();
        state3.dispose();
      });
      await tester.pumpWidget(WholeWellApp(state: state3));
      await tester.pumpAndSettle();
      expect(find.text('4/4'), findsOneWidget);

      await tester.tap(find.text('Ẩn số calo'));
      await tester.pumpAndSettle();
      await tester.runAsync(() async {
        await tester.tap(find.text('Xong'));
        await Future<void>.delayed(const Duration(milliseconds: 20));
      });
      await tester.pumpAndSettle();

      expect(find.byType(TodayScreen), findsOneWidget);
      expect(state3.hideCalories, isTrue);
      expect(find.text('Năng lượng'), findsNothing);

      // Mở Tôi -> Hiển thị -> tắt Ẩn số calo.
      await tester.tap(find.text('Tôi'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Hiển thị'));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(SwitchListTile));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Hôm nay'));
      await tester.pumpAndSettle();
      expect(find.text('Năng lượng'), findsOneWidget);
    });
  });

  group('việc 4: nâng cấp khung-tam-0', () {
    Future<DbOpener> seedKhungTam(Directory dir, FakeSecureKeyStore keys) async {
      final opener = makeOpener(dir, keys);
      final res = await opener.createNew(
        const ConsentInput(contentVersion: khungTamConsentVersion, ageYears: 35, caution: false),
      );
      final repo = (res as Opened).repository;
      await repo.saveProfile(const Profile(ageYears: 35, sex: Sex.female, heightCm: 160, weightKg: 55));
      await repo.saveHideCalories(false);
      await repo.saveOnboardingStep(OnboardingStep.done);
      await repo.addFood(FoodEntryInput(
        at: DateTime.now(),
        meal: Meal.lunch,
        name: 'Phở bò cũ',
        portionUnit: 'bát',
        portionQty: 1,
        addedSugarKnown: true,
        packVersion: pack.version,
        lines: const [IntakeLine(nutrientId: 'energyKcal', source: IntakeSource.food, amounts: {'energyKcal': 420})],
      ));
      await repo.close();
      return opener;
    }

    testWidgets('khung-tam-0 hỏi lại Điều kiện + Đồng ý, giữ món cũ và bật chế độ thận trọng',
        (tester) async {
      final dir = makeTempDir();
      final keys = FakeSecureKeyStore();
      final opener = await tester.runAsync(() => seedKhungTam(dir, keys));
      final state = AppState(pack: pack, opener: opener!);
      await tester.runAsync(state.start);
      addTearDown(() async {
        await state.session.repo?.close();
        state.dispose();
      });

      await tester.pumpWidget(WholeWellApp(state: state));
      await tester.pumpAndSettle();

      expect(find.text('Xác nhận điều kiện'), findsOneWidget);
      expect(find.text('35'), findsOneWidget);
      // Chọn Không mang thai, Có bệnh mạn tính -> Đồng ý.
      await tester.tap(find.text('Không').first);
      await tester.tap(find.text('Có').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Tiếp tục'));
      await tester.pumpAndSettle();

      expect(find.text('Xác nhận đồng ý'), findsOneWidget);
      await tester.tap(find.byType(CheckboxListTile));
      await tester.pumpAndSettle();
      await tester.runAsync(() async {
        await tester.tap(find.text('Đồng ý và tiếp tục'));
        await Future<void>.delayed(const Duration(milliseconds: 20));
      });
      await tester.pumpAndSettle();

      expect(find.byType(TodayScreen), findsOneWidget);
      expect(state.caution, isTrue);
      expect(find.text(cautionBannerMessage), findsOneWidget);
      expect(find.text('Mức calo tham chiếu'), findsOneWidget);
      expect(find.textContaining('Mức calo tham chiếu là mức giữ cân'), findsOneWidget);
      expect(state.diary.todayFoods.map((f) => f.name), ['Phở bò cũ']);
    });

    testWidgets('khung-tam-0 chọn đang mang thai -> Chưa dùng được có nút Xóa toàn bộ dữ liệu',
        (tester) async {
      final dir = makeTempDir();
      final keys = FakeSecureKeyStore();
      final opener = await tester.runAsync(() => seedKhungTam(dir, keys));
      final state = AppState(pack: pack, opener: opener!);
      await tester.runAsync(state.start);
      addTearDown(() async {
        await state.session.repo?.close();
        state.dispose();
      });

      await tester.pumpWidget(WholeWellApp(state: state));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Có').first);
      await tester.tap(find.text('Không').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Tiếp tục'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Xóa toàn bộ dữ liệu'));
      await tester.pumpAndSettle();
      await tester.enterText(find.widgetWithText(TextField, 'XÓA'), 'XÓA');
      await tester.pumpAndSettle();
      await tester.runAsync(() async {
        await tester.tap(find.text('Xóa toàn bộ'));
        await Future<void>.delayed(const Duration(milliseconds: 20));
      });
      await tester.pumpAndSettle();

      expect(find.text('WholeWell'), findsOneWidget);
      expect(dir.listSync(), isEmpty);
      expect(keys.key, isNull);
    });
  });

  group('việc 4: thận trọng, tự tăng tuổi và nước', () {
    testWidgets('CautionLabels đổi đầy đủ chuỗi (kể cả người 18 tuổi) và tắt/bật ở Hồ sơ',
        (tester) async {
      final repo = InMemoryJournalRepository(initialCaution: true, initialAgeYears: 18);
      await repo.saveProfile(const Profile(ageYears: 18, sex: Sex.female, heightCm: 160, weightKg: 52));
      await repo.saveHideCalories(false);
      await repo.saveOnboardingStep(OnboardingStep.done);

      final state = AppState.withRepository(pack: pack, repo: repo);
      await state.start();
      addTearDown(state.dispose);

      await tester.pumpWidget(WholeWellApp(state: state));
      await tester.pumpAndSettle();

      expect(find.text(cautionBannerMessage), findsOneWidget);
      expect(find.text('Chưa có mức calo tham chiếu cho người 18 tuổi.'), findsOneWidget);

      // Mở Tôi -> Hồ sơ -> tắt câu thận trọng -> Lưu -> Hôm nay cập nhật ngay.
      await tester.tap(find.text('Tôi'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Hồ sơ'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Không'));
      await tester.tap(find.text('Không'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Lưu'));
      await tester.tap(find.text('Lưu'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Hôm nay'));
      await tester.pumpAndSettle();

      expect(find.text(cautionBannerMessage), findsNothing);
      expect(find.text('Chưa có mục tiêu calo cho người 18 tuổi.'), findsOneWidget);
    });

    testWidgets('tự tăng tuổi chạy khi start(), không chạy khi reload(), xóa nhắc khi bấm Sửa/Lưu',
        (tester) async {
      final oldAnchor = dayKey(DateTime.now().subtract(const Duration(days: 380)));
      final repo = InMemoryJournalRepository(initialAgeYears: 35, initialAgeEnteredOn: oldAnchor);
      await repo.saveProfile(const Profile(ageYears: 35, sex: Sex.male, heightCm: 170, weightKg: 65));
      await repo.saveHideCalories(false);
      await repo.saveOnboardingStep(OnboardingStep.done);

      final state = AppState.withRepository(pack: pack, repo: repo);
      // reload() không tự tăng tuổi; chỉ start() / onAppResume() khi ready mới chạy.
      state.diary.attachRepository(repo);
      await state.diary.reload();
      expect(state.ageBumpedNotice, isNull);
      expect(state.profile?.ageYears, 35);

      await state.start();
      addTearDown(state.dispose);

      await tester.pumpWidget(WholeWellApp(state: state));
      await tester.pumpAndSettle();

      expect(find.text('Tuổi trong hồ sơ đã được cập nhật thành 36.'), findsOneWidget);
      await tester.tap(find.text('Sửa'));
      await tester.pumpAndSettle();
      expect(find.byType(ProfileScreen), findsOneWidget);
      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();
      expect(find.text('Tuổi trong hồ sơ đã được cập nhật thành 36.'), findsNothing);
    });

    testWidgets('nước: 1 chạm trên Hôm nay, Undo, Ghi nước, lọc/sửa/xóa ở Nhật ký', (tester) async {
      final repo = InMemoryJournalRepository();
      await repo.saveProfile(const Profile(ageYears: 30, sex: Sex.male, heightCm: 170, weightKg: 65));
      await repo.saveHideCalories(false);
      await repo.saveOnboardingStep(OnboardingStep.done);

      final state = AppState.withRepository(pack: pack, repo: repo);
      await state.start();
      addTearDown(state.dispose);

      await tester.pumpWidget(WholeWellApp(state: state));
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(find.text('Chưa ghi nước hôm nay'), 300);
      await tester.pumpAndSettle();
      expect(find.text('Chưa ghi nước hôm nay'), findsOneWidget);
      await tester.ensureVisible(find.text('+250 ml'));
      await tester.tap(find.text('+250 ml'));
      await tester.pumpAndSettle();

      expect(find.text('Đã uống 250 ml'), findsOneWidget);
      expect(find.text('Đã ghi 250 ml nước'), findsOneWidget);

      // Hoàn tác
      await tester.tap(find.text('Hoàn tác'));
      await tester.pumpAndSettle();
      expect(find.text('Chưa ghi nước hôm nay'), findsOneWidget);

      // Mở Bảng Ghi -> Nước -> kiểm lỗi 6000 ml -> chọn 500 ml -> Lưu.
      await tester.tap(find.text('Ghi'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Nước').last);
      await tester.pumpAndSettle();
      expect(find.byType(WaterLogScreen), findsOneWidget);

      await tester.enterText(find.widgetWithText(TextField, 'Số khác'), '6000');
      await tester.tap(find.text('Lưu'));
      await tester.pumpAndSettle();
      expect(find.text('Nhập lượng nước từ 1 đến 5.000 ml.'), findsOneWidget);

      await tester.tap(find.text('500 ml'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Lưu'));
      await tester.pumpAndSettle();

      expect(find.text('Đã uống 500 ml'), findsOneWidget);
      expect(find.text('+500 ml'), findsOneWidget);

      // Chuyển sang ngày hôm qua rồi bấm +500 ml: ghi vào hôm qua lúc 12:00.
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      await state.setDay(yesterday);
      await tester.pumpAndSettle();
      await tester.tap(find.text('+500 ml'));
      await tester.pumpAndSettle();
      final yWaters = await repo.waterOn(dayKey(yesterday));
      expect(yWaters.single.at.hour, 12);
      expect(yWaters.single.ml, 500);

      // Sang tab Nhật ký -> lọc Nước -> chạm sửa thành 350 ml -> xóa.
      await tester.tap(find.text('Nhật ký'));
      await tester.pumpAndSettle();
      await tester.tap(find.descendant(of: find.byType(DiaryScreen), matching: find.text('Nước')).first);
      await tester.pumpAndSettle();
      expect(find.text('Nước  500 ml (1 lần)'), findsOneWidget);

      await tester.tap(find.text('500 ml').last);
      await tester.pumpAndSettle();
      await tester.enterText(find.widgetWithText(TextField, 'Số khác'), '350');
      await tester.tap(find.text('Lưu'));
      await tester.pumpAndSettle();
      expect(find.text('Nước  350 ml (1 lần)'), findsOneWidget);

      await tester.tap(find.text('350 ml').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Xóa khỏi nhật ký'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Xóa'));
      await tester.pumpAndSettle();
      expect(find.text('Chưa ghi nước trong ngày này.'), findsOneWidget);
    });
  });
}
