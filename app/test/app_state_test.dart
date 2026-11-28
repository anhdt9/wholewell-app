import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:health_engine/health_engine.dart';
import 'package:journal_db/journal_db.dart';
import 'package:wholewell/state/app_state.dart';

/// Đọc ngày [slowDay] chậm (giả lập đọc ngày cũ xong sau ngày mới).
class _SlowRepo extends InMemoryJournalRepository {
  String? slowDay;
  @override
  Future<List<FoodEntry>> foodsBetween(String fromDay, String toDay) async {
    if (slowDay != null && slowDay!.compareTo(fromDay) >= 0 && slowDay!.compareTo(toDay) <= 0) {
      await Future<void>.delayed(const Duration(milliseconds: 50));
    }
    return super.foodsBetween(fromDay, toDay);
  }
}

/// Lần đọc tiếp theo lỗi.
class _FailingRepo extends InMemoryJournalRepository {
  bool failNext = false;
  @override
  Future<List<FoodEntry>> foodsBetween(String fromDay, String toDay) async {
    if (failNext) {
      failNext = false;
      throw const JournalStorageException('SqliteException(5)');
    }
    return super.foodsBetween(fromDay, toDay);
  }
}

void main() {
  final pack = ReferencePack.fromJsonString(File('assets/reference_pack.json').readAsStringSync());
  const profile = Profile(ageYears: 30, sex: Sex.male, heightCm: 170, weightKg: 65);

  test('báo cáo ngày qua AppState, cờ UL trung bình ngày có ghi và vận động tăng cơ', () async {
    final s = AppState.withRepository(pack: pack, repo: InMemoryJournalRepository());
    await s.start();
    expect(s.report(), isNull);
    await s.saveProfile(profile);
    await s.addItem(
      const IntakeItem(label: 'Viên magie', source: IntakeSource.supplement, nutrients: {'magnesium': 500}),
    );
    await s.addWorkout(const WorkoutEntry(activityCode: '17200', minutes: 30));
    await s.addWorkout(const WorkoutEntry(activityCode: '02054', minutes: 20));
    final r = s.report()!;
    expect(r.eerKcal, 2450);
    expect(r.loggedDaysCount, 1);
    expect(r.ulFlags.where((f) => f.nutrientId == 'magnesium').map((f) => f.kind).toSet(), {
      UlFlagKind.daily,
      UlFlagKind.sevenDayAverage,
    });
    expect(r.energyOutWorkoutKcal, closeTo((4.8 * 30 + 3.5 * 20) * 65 / 60, 1e-9));
    expect(r.activity7Days.strengthDays, 1);
  });

  test('recordDose qua UnitConverter tính đúng UL vitamin E tổng hợp', () async {
    final s = AppState.withRepository(pack: pack, repo: InMemoryJournalRepository());
    await s.start();
    await s.saveProfile(profile);
    final conv = UnitConverter(pack).convertIntakeLine(
      const IntakeLineInput(
        nutrientId: 'vitE',
        source: IntakeSource.supplement,
        form: NutrientForm.synthetic2r,
        amount: 1200,
        unit: LabelUnit.iu,
      ),
    );
    await s.recordDose('VitE 1200 IU', [
      IntakeLine(
        nutrientId: 'vitE',
        source: IntakeSource.supplement,
        form: NutrientForm.synthetic2r,
        labelAmount: 1200,
        labelUnit: 'iu',
        amounts: conv.amounts,
        ulAmounts: conv.ulAmounts,
      ),
    ]);
    final r = s.report()!;
    expect(r.ulFlags.any((f) => f.nutrientId == 'vitE'), isTrue);
  });

  test('ẩn số calo, nhật ký được lưu qua nhật ký và đọc lại khi mở lại', () async {
    final repo = InMemoryJournalRepository();
    final a = AppState.withRepository(pack: pack, repo: repo);
    await a.start();
    await a.saveProfile(profile);
    await a.setHideCalories(true);
    await a.addItem(
      const IntakeItem(
        label: 'Cơm',
        source: IntakeSource.food,
        meal: MealSlot.lunch,
        nutrients: {'energyKcal': 200, 'protein': 4},
      ),
    );
    final b = AppState.withRepository(pack: pack, repo: repo);
    await b.start();
    expect(b.hideCalories, isTrue);
    expect(b.profile?.weightKg, 65);
    expect(b.todayItems.single.meal, MealSlot.lunch);
    expect(b.todayItems.single.nutrients, {'energyKcal': 200.0, 'protein': 4.0});
  });

  test('xóa mục theo vị trí trong danh sách', () async {
    final s = AppState.withRepository(pack: pack, repo: InMemoryJournalRepository());
    await s.start();
    await s.addItem(
      const IntakeItem(label: 'A', source: IntakeSource.food, meal: MealSlot.breakfast, nutrients: {'protein': 1}),
    );
    await s.addItem(const IntakeItem(label: 'B', source: IntakeSource.supplement, nutrients: {'zinc': 5}));
    expect(s.todayItems.map((i) => i.label), ['A', 'B']);
    await s.removeItem(1);
    expect(s.todayItems.map((i) => i.label), ['A']);
  });

  test('mở CSDL: chưa có dữ liệu thì về lần đầu; máy đang khóa thì chờ', () async {
    final dir = Directory.systemTemp.createTempSync('wholewell_app_');
    addTearDown(() => dir.deleteSync(recursive: true));
    final keys = FakeSecureKeyStore();
    final opener = DbOpener(files: DbFiles(dir), keys: keys, retryDelay: Duration.zero);
    final s = AppState(pack: pack, opener: opener);
    await s.start();
    expect(s.status, DataStatus.welcome);
    keys
      ..unavailableReads = -1
      ..unlocked = false;
    await s.start();
    expect(s.status, DataStatus.waitingForUnlock);
    expect(dir.listSync(), isEmpty);
  });

  test('đổi ngày nhanh: số liệu luôn của ngày đang xem', () async {
    final repo = _SlowRepo();
    final s = AppState.withRepository(pack: pack, repo: repo);
    await s.start();
    final today = s.day;
    await s.addItem(
      const IntakeItem(
        label: 'Hôm nay',
        source: IntakeSource.food,
        meal: MealSlot.breakfast,
        nutrients: {'protein': 1},
      ),
    );
    final yesterday = today.subtract(const Duration(days: 1));
    repo.slowDay = dayKey(yesterday);
    final a = s.setDay(yesterday);
    final b = s.setDay(today);
    await Future.wait([a, b]);
    expect(s.day, today);
    expect(s.todayItems.map((i) => i.label), ['Hôm nay']);
  });

  test('đọc lỗi sau khi đã mở: vẫn ở app, báo lỗi đọc, Thử lại được', () async {
    final repo = _FailingRepo();
    final s = AppState.withRepository(pack: pack, repo: repo);
    await s.start();
    repo.failNext = true;
    await s.setDay(s.day);
    expect(s.status, DataStatus.ready);
    expect(s.readFailed, isTrue);
    await s.reload();
    expect(s.readFailed, isFalse);
  });

  test('gọi start chồng nhau chỉ mở CSDL một lần', () async {
    final dir = Directory.systemTemp.createTempSync('wholewell_app_');
    addTearDown(() => dir.deleteSync(recursive: true));
    final keys = FakeSecureKeyStore();
    final s = AppState(
      pack: pack,
      opener: DbOpener(files: DbFiles(dir), keys: keys, retryDelay: Duration.zero),
    );
    await Future.wait([s.start(), s.start()]);
    expect(keys.reads, 1);
    expect(s.status, DataStatus.welcome);
  });

  test('nền tảng chưa hỗ trợ: không mở, không ghi gì', () async {
    final s = AppState.unsupportedPlatform(pack: pack);
    await s.start();
    await s.saveProfile(profile);
    expect(s.status, DataStatus.unsupportedPlatform);
    expect(s.profile, isNull);
  });

  test('memoize report() & periodReport7Days(), và hideTipCardForToday không gọi reload()', () async {
    var foodBetweenCalls = 0;
    final repo = _CountingRepo(() => foodBetweenCalls++);
    final s = AppState.withRepository(pack: pack, repo: repo);
    await s.start();
    await s.saveProfile(profile);
    final r1 = s.report();
    final r2 = s.report();
    final p1 = s.periodReport7Days();
    final p2 = s.periodReport7Days();
    expect(identical(r1, r2), isTrue);
    expect(identical(p1, p2), isTrue);

    final callsBefore = foodBetweenCalls;
    await s.diary.hideTipCardForToday();
    await s.diary.dismissScheduleNotices('sig1');
    expect(foodBetweenCalls, callsBefore);
    expect(s.diary.tipHiddenToday, isTrue);
    expect(s.diary.dismissedScheduleNoticeSig, 'sig1');

    // Ghi dữ liệu mới -> invalidate cache.
    await s.addItem(const IntakeItem(label: 'Phở', source: IntakeSource.food, nutrients: {'energyKcal': 400}));
    final r3 = s.report();
    expect(identical(r1, r3), isFalse);
  });

  test('lineCountsTowardUl đồng bộ với amountForUl cho vitA (retinol) và magnesium', () {
    final vitA = pack.nutrients['vitA']!;
    final mag = pack.nutrients['magnesium']!;

    expect(lineCountsTowardUl(vitA, source: IntakeSource.food, amounts: const {'vitA': 500, 'retinol': 500}), isTrue);
    expect(lineCountsTowardUl(vitA, source: IntakeSource.food, amounts: const {'vitA': 500}), isFalse);
    expect(lineCountsTowardUl(mag, source: IntakeSource.food, amounts: const {'magnesium': 200}), isFalse);
    expect(lineCountsTowardUl(mag, source: IntakeSource.supplement, amounts: const {'magnesium': 200}), isTrue);
  });
}

class _CountingRepo extends InMemoryJournalRepository {
  final void Function() onFoodsBetween;
  _CountingRepo(this.onFoodsBetween);

  @override
  Future<List<FoodEntry>> foodsBetween(String fromDay, String toDay) {
    onFoodsBetween();
    return super.foodsBetween(fromDay, toDay);
  }
}
