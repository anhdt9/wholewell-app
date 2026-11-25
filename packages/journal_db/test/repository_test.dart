// Tiêu chí đạt "Dữ liệu" (docs/specs/encrypted-db.md).
import 'dart:io';

import 'package:health_engine/health_engine.dart';
import 'package:journal_db/journal_db.dart';
import 'package:test/test.dart';

import 'helpers.dart';

final _pack = ReferencePack.fromJsonString(File('../health_engine/assets/reference_pack.json').readAsStringSync());

const _profile = Profile(ageYears: 35, sex: Sex.female, heightCm: 160, weightKg: 55);

Future<int> _count(DriftJournalRepository r, String sql) async =>
    (await r.db.customSelect(sql).getSingle()).data.values.first as int;

void main() {
  test('tắt hẳn rồi mở lại: dữ liệu và báo cáo ngày giống hệt', () async {
    final dir = tempDir();
    final o = testOpener(dir, FakeSecureKeyStore());
    final t = testNow();
    final day = dayKey(t);
    final repo = await createdRepo(o);
    await repo.saveProfile(_profile);
    await repo.addFood(food('Phở bò', t, [line('energyKcal', 450), line('protein', 25), line('calcium', 80)]));
    await repo.recordDose(DoseInput(
      at: t.add(const Duration(minutes: 5)),
      name: 'Magie',
      kind: DoseKind.oneOff,
      servings: 1,
      packVersion: testPack,
      lines: [line('magnesium', 400, source: IntakeSource.supplement)],
    ));
    await repo.addWater(t, 250);
    await repo.addWorkout(t, const WorkoutEntry(activityCode: '17200', minutes: 30));

    Future<(List<IntakeItem>, DailyReport, List<WorkoutRecord>, List<WaterRecord>)> snapshot(
        DriftJournalRepository r) async {
      final items = intakeItemsFor(await r.foodsOn(day), await r.dosesOn(day));
      final ws = await r.workoutsOn(day);
      final report = dailyReport(_pack, (await r.loadProfile())!, items,
          workouts: [for (final w in ws) w.workout], last7Days: [items]);
      return (items, report, ws, await r.waterOn(day));
    }

    final before = await snapshot(repo);
    await repo.close();
    final after = await snapshot(await reopened(o));

    String show(IntakeItem i) =>
        '${i.label}|${i.source}|${i.meal}|${(i.nutrients.entries.map((e) => '${e.key}=${e.value}').toList()..sort()).join(',')}';
    expect(after.$1.map(show).toList(), before.$1.map(show).toList());
    expect(after.$1, hasLength(2));
    expect(after.$2.eerKcal, before.$2.eerKcal);
    expect(after.$2.ulFlags.map((f) => (f.nutrientId, f.amount)), before.$2.ulFlags.map((f) => (f.nutrientId, f.amount)));
    expect(after.$2.ulFlags.map((f) => f.nutrientId), contains('magnesium'));
    expect(after.$3.single.workout.minutes, 30);
    expect(after.$3.single.workout.day, day);
    expect(after.$4.single.ml, 250);
  });

  test('thoát sau bước Đồng ý: mở lại đúng bước đang dở, hồ sơ chưa đủ', () async {
    final dir = tempDir();
    final o = testOpener(dir, FakeSecureKeyStore());
    final repo = await createdRepo(o);
    expect(await repo.loadOnboardingStep(), OnboardingStep.bodyProfile);
    expect(await repo.loadProfile(), isNull);
    expect(await repo.loadHideCalories(), isNull);
    final consent = await repo.loadConsentProfile();
    expect(consent?.ageYears, 35);
    expect(consent?.caution, isFalse);
    await repo.saveOnboardingStep(OnboardingStep.calorieDisplay);
    await repo.close();
    final again = await reopened(o);
    expect(await again.loadOnboardingStep(), OnboardingStep.calorieDisplay);
    expect(await again.loadProfile(), isNull);
  });

  group('kho', () {
    late DriftJournalRepository repo;
    late int pid;

    setUp(() async {
      repo = await createdRepo(testOpener(tempDir(), FakeSecureKeyStore()));
      pid = await repo.addProduct('Canxi D3', CountUnit.tablet, 1);
    });

    DoseInput dose(double servings, {bool deduct = true, ExpiredBoxChoice expired = ExpiredBoxChoice.ask, int? product}) =>
        DoseInput(
          at: testNow(),
          productId: product ?? pid,
          kind: DoseKind.extra,
          servings: servings,
          packVersion: testPack,
          lines: [line('calcium', 500 * servings, source: IntakeSource.supplement)],
          deductStock: deduct,
          expiredBoxes: expired,
        );

    test('2 khẩu phần khi hộp đầu còn 1: trừ hai hộp, hoàn tác trả đúng', () async {
      final a = await repo.addBox(pid, 1, expiryMonth: '2027-01');
      final b = await repo.addBox(pid, 30, expiryMonth: '2027-06');
      final r = await repo.recordDose(dose(2)) as DoseRecorded;
      expect(r.shortfall, 0);
      final d = (await repo.dosesOn(dayKey(testNow()))).single;
      expect(d.deductions.map((x) => (x.boxId, x.amount)), unorderedEquals([(a, 1.0), (b, 1.0)]));
      expect((await repo.boxesOf(pid)).map((x) => x.remaining), [0, 29]);
      await repo.deleteDose(r.id);
      expect((await repo.boxesOf(pid)).map((x) => x.remaining), [1, 30]);
      expect(await _count(repo, 'SELECT count(*) FROM dose_box_deductions'), 0);
      expect(await _count(repo, 'SELECT count(*) FROM intake_lines'), 0);
    });

    test('lỗi giữa chừng: không có lần ghi nào, kho không đổi', () async {
      await repo.addBox(pid, 10, expiryMonth: '2027-01');
      final bad = DoseInput(
        at: testNow(),
        productId: pid,
        kind: DoseKind.scheduled,
        servings: 1,
        packVersion: testPack,
        lines: [line('calcium', 500, source: IntakeSource.supplement)],
        occurrence: const OccurrenceRef(9999, '2026-11-24'), // lịch không tồn tại: lỗi khóa ngoại
      );
      Object? err;
      try {
        await repo.recordDose(bad);
      } on Object catch (e) {
        err = e;
      }
      expect(err, isA<JournalStorageException>());
      // Giữ loại lỗi và mã lỗi để tra crash, không có câu SQL hay giá trị.
      expect(err.toString(), contains('SqliteException('));
      expect(err.toString().toUpperCase(), isNot(contains('INSERT')));
      expect(await _count(repo, 'SELECT count(*) FROM dose_entries'), 0);
      expect(await _count(repo, 'SELECT count(*) FROM intake_lines'), 0);
      expect((await repo.boxesOf(pid)).single.remaining, 10);
    });

    test('[Không trừ] hoặc kho hết: vẫn ghi và tính vào giới hạn, không có dòng trừ kho', () async {
      final kept = await repo.recordDose(dose(1, deduct: false)) as DoseRecorded;
      final empty = await repo.recordDose(dose(2)) as DoseRecorded;
      expect(empty.shortfall, 2);
      final ds = await repo.dosesOn(dayKey(testNow()));
      expect(ds.map((d) => d.id), [kept.id, empty.id]);
      expect(ds.every((d) => d.deductions.isEmpty), isTrue);
      final items = intakeItemsFor(const [], ds);
      expect(items.fold<double>(0, (s, i) => s + i.amount('calcium')), 1500);
    });

    test('chỉ còn hộp hết hạn: hỏi trước, chưa ghi gì; chọn Trừ hoặc Không trừ', () async {
      await repo.addBox(pid, 5, expiryMonth: '2026-10');
      expect(await repo.recordDose(dose(1)), isA<NeedsExpiredChoice>());
      expect(await _count(repo, 'SELECT count(*) FROM dose_entries'), 0);
      await repo.recordDose(dose(1, expired: ExpiredBoxChoice.deduct));
      expect((await repo.boxesOf(pid)).single.remaining, 4);
      await repo.recordDose(dose(1, expired: ExpiredBoxChoice.skip));
      expect((await repo.boxesOf(pid)).single.remaining, 4);
      expect(await _count(repo, 'SELECT count(*) FROM dose_entries'), 2);
    });

    test('trừ theo số đơn vị mỗi khẩu phần; số còn không âm', () async {
      final p2 = await repo.addProduct('Omega 3', CountUnit.softgel, 2);
      await repo.addBox(p2, 60);
      await repo.recordDose(dose(1, product: p2));
      expect((await repo.boxesOf(p2)).single.remaining, 58);
      await expectLater(repo.db.customStatement('UPDATE boxes SET remaining = -1'), throwsA(anything));
      expect((await repo.boxesOf(p2)).single.remaining, 58);
    });

    test('đổi thành phần sản phẩm sau khi ghi không đổi tổng của ngày đã ghi', () async {
      await repo.db.customStatement(
          "INSERT INTO ingredients (product_id, nutrient_id, amount_per_serving, unit, origin) VALUES ($pid, 'calcium', 500, 'mg', 'manual')");
      await repo.recordDose(dose(1, deduct: false));
      await repo.db.customStatement('UPDATE ingredients SET amount_per_serving = 1000');
      final items = intakeItemsFor(const [], await repo.dosesOn(dayKey(testNow())));
      expect(items.single.amount('calcium'), 500);
    });
  });

  group('lịch uống', () {
    late DriftJournalRepository repo;
    late int pid;

    setUp(() async {
      repo = await createdRepo(testOpener(tempDir(), FakeSecureKeyStore()));
      pid = await repo.addProduct('Magie', CountUnit.tablet, 1);
    });

    test('[Bỏ qua] lưu skipped; bỏ đánh dấu về Chưa đánh dấu', () async {
      final s = await repo.addSchedule(pid, 20 * 60, 1, validFrom: '2026-11-01');
      const day = '2026-11-24';
      await repo.skipOccurrence(OccurrenceRef(s, day));
      expect((await repo.occurrencesOn(day)).single.status, OccurrenceStatus.skipped);
      await repo.clearOccurrence(OccurrenceRef(s, day));
      expect(await repo.occurrencesOn(day), isEmpty);
    });

    test('đã uống theo lịch; bỏ đánh dấu xóa lần uống', () async {
      final s = await repo.addSchedule(pid, 20 * 60, 1, validFrom: '2026-11-01');
      const day = '2026-11-24';
      final r = await repo.recordDose(DoseInput(
        at: DateTime(2026, 11, 24, 20, 5),
        productId: pid,
        kind: DoseKind.scheduled,
        servings: 1,
        packVersion: testPack,
        lines: [line('magnesium', 250, source: IntakeSource.supplement)],
        occurrence: OccurrenceRef(s, day),
        deductStock: false,
      )) as DoseRecorded;
      expect((await repo.occurrencesOn(day)).single.doseEntryId, r.id);
      await repo.clearOccurrence(OccurrenceRef(s, day));
      expect(await repo.occurrencesOn(day), isEmpty);
      expect(await repo.dosesOn(day), isEmpty);
    });

    test('đổi 20:00 thành 21:00: ngày trước vẫn dùng 20:00', () async {
      final s = await repo.addSchedule(pid, 20 * 60, 1, validFrom: '2026-11-01');
      final c = await repo.updateSchedule(s, timeOfDay: 21 * 60, today: '2026-11-24');
      expect(c.effectiveFrom, '2026-11-24');
      expect((await repo.schedulesOn('2026-11-23')).single.timeOfDay, 20 * 60);
      expect((await repo.schedulesOn('2026-11-24')).single.timeOfDay, 21 * 60);
    });

    test('hôm nay đã đánh dấu lần của lịch cũ: lịch mới áp dụng từ ngày mai', () async {
      final s = await repo.addSchedule(pid, 8 * 60, 1, validFrom: '2026-11-01');
      await repo.skipOccurrence(OccurrenceRef(s, '2026-11-24'));
      final c = await repo.updateSchedule(s, timeOfDay: 9 * 60, today: '2026-11-24');
      expect(c.effectiveFrom, '2026-11-25');
      expect((await repo.schedulesOn('2026-11-24')).single.timeOfDay, 8 * 60);
      expect((await repo.schedulesOn('2026-11-25')).single.timeOfDay, 9 * 60);
    });
  });

  group('món ăn, dòng chất', () {
    late DriftJournalRepository repo;
    setUp(() async => repo = await createdRepo(testOpener(tempDir(), FakeSecureKeyStore())));

    test('món chưa rõ đường bổ sung được đếm riêng, không tính là 0 g', () async {
      final t = testNow();
      await repo.addFood(food('Cà phê sữa', t, [line('addedSugar', 18)]));
      await repo.addFood(food('Bánh quy', t, [line('energyKcal', 120)], sugarKnown: false));
      expect(await repo.unknownAddedSugarCount(dayKey(t)), 1);
    });

    test('xóa lần ghi xóa hết dòng chất; dòng sai cột lần ghi bị từ chối', () async {
      final id = await repo.addFood(food('Cơm', testNow(), [line('energyKcal', 200), line('protein', 4)]));
      expect(await _count(repo, 'SELECT count(*) FROM intake_lines WHERE food_entry_id = $id'), 2);
      await repo.deleteFood(id);
      expect(await _count(repo, 'SELECT count(*) FROM intake_lines'), 0);
      const cols = 'day, nutrient_id, source, amounts';
      const vals = "'2026-11-24', 'energyKcal', 'food', '{}'";
      await expectLater(repo.db.customStatement('INSERT INTO intake_lines ($cols) VALUES ($vals)'), throwsA(anything));
      final f = await repo.addFood(food('Cơm', testNow(), const []));
      final d = await repo.recordDose(DoseInput(
              at: testNow(), kind: DoseKind.oneOff, servings: 1, packVersion: testPack, lines: const []))
          as DoseRecorded;
      await expectLater(
          repo.db.customStatement(
              'INSERT INTO intake_lines (food_entry_id, dose_entry_id, $cols) VALUES ($f, ${d.id}, $vals)'),
          throwsA(anything));
    });

    test('đổi món sang ngày khác: dòng chất theo ngày mới, tổng hai ngày đúng', () async {
      final t = testNow();
      final id = await repo.addFood(food('Phở', t, [line('calcium', 80)]));
      await repo.addFood(food('Sữa', t, [line('calcium', 300)]));
      final yesterday = t.subtract(const Duration(days: 1));
      await repo.moveFood(id, yesterday);
      double total(List<FoodEntry> fs) => intakeItemsFor(fs, const []).fold(0, (s, i) => s + i.amount('calcium'));
      expect(total(await repo.foodsOn(dayKey(t))), 300);
      expect(total(await repo.foodsOn(dayKey(yesterday))), 80);
      expect(await _count(repo, "SELECT count(*) FROM intake_lines WHERE day = '${dayKey(yesterday)}'"), 1);
    });

    test('món theo nhãn 100 ml: đổi 180 ml thành 250 ml thì mọi lượng × 250/180', () async {
      final id = await repo.addFood(food(
        'Sữa đậu nành',
        testNow(),
        [
          IntakeLine(
              nutrientId: 'calcium', source: IntakeSource.fortified, labelAmount: 120, labelUnit: 'mg',
              amounts: const {'calcium': 216}),
        ],
        basis: 100,
        qty: 180,
        unit: 'ml',
      ));
      await repo.scaleLabelFoodPortion(id, 250);
      final f = (await repo.foodById(id))!;
      expect(f.portionQty, 250);
      expect(f.lines.single.amounts['calcium'], closeTo(216 * 250 / 180, 1e-9));
      expect(f.lines.single.labelAmount, 120);
    });

    test('món USDA: tính lại theo gói đang cài và lưu pack_version mới', () async {
      final id = await repo.addFood(food('Cơm trắng', testNow(), [line('energyKcal', 200)]));
      await expectLater(repo.scaleLabelFoodPortion(id, 2), throwsA(isA<StateError>()));
      await repo.replaceFoodLines(id, portionQty: 2, lines: [line('energyKcal', 410)], packVersion: 'pack-2');
      final f = (await repo.foodById(id))!;
      expect(f.packVersion, 'pack-2');
      expect(f.lines.single.amounts['energyKcal'], 410);
    });

    test('Ghi một lần có tên thì đọc lại được tên đó', () async {
      await repo.recordDose(DoseInput(
          at: testNow(), name: 'Viên kẽm', kind: DoseKind.oneOff, servings: 1, packVersion: testPack,
          lines: [line('zinc', 15, source: IntakeSource.supplement)]));
      expect((await repo.dosesOn(dayKey(testNow()))).single.name, 'Viên kẽm');
    });

    test('ghi và kiểm tra giới hạn từ dòng có lượng tính giới hạn riêng (ulAmounts)', () async {
      const ul = IntakeLine(
          nutrientId: 'vitE',
          source: IntakeSource.supplement,
          form: NutrientForm.synthetic2r,
          uncertain: false,
          amounts: {'vitE': 540},
          ulAmounts: {'vitE': 1090.91});
      final res = await repo.recordDose(DoseInput(
          at: testNow(), kind: DoseKind.oneOff, servings: 1, packVersion: testPack, lines: const [ul]));
      expect(res, isA<DoseRecorded>());
      final items = intakeItemsFor(const [], await repo.dosesOn(dayKey(testNow())));
      final flags = checkUlDay(_pack, _profile, items);
      expect(flags.single.nutrientId, 'vitE');
      expect(flags.single.amount, closeTo(1090.91, 1e-6));
    });
  });

  test('bảng profile chỉ có các cột đã định, không có tên bệnh, tên thuốc', () async {
    final repo = await createdRepo(testOpener(tempDir(), FakeSecureKeyStore()));
    final cols = [for (final r in await repo.db.customSelect('PRAGMA table_info(profile)').get()) r.data['name']];
    expect(cols.toSet(), {
      'id', 'age_years', 'age_entered_on', 'caution', 'caution_answered_on', 'sex', 'height_cm',
      'weight_kg', 'activity_level', 'updated_at',
    });
  });
}
