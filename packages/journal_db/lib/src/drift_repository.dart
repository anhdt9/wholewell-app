/// Nhật ký trên CSDL mã hóa (thay `InMemoryJournalRepository`).
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:health_engine/health_engine.dart';
import 'package:sqlite3/sqlite3.dart' show SqliteException;

import 'intake.dart';
import 'journal_database.dart';
import 'models.dart';
import 'repository.dart';
import 'schema.dart';

/// SQLITE_FULL.
const _sqliteFull = 13;

/// Lỗi từ isolate nền được bọc lại; nhận ra qua mã lỗi trong chuỗi mô tả.
bool _isFull(Object e) => e is SqliteException
    ? e.resultCode == _sqliteFull
    : RegExp('SqliteException\\($_sqliteFull\\)').hasMatch(e.toString());

/// Loại lỗi và mã lỗi, không có câu SQL hay giá trị.
String _kind(Object e) {
  if (e is SqliteException) return 'SqliteException(${e.extendedResultCode})';
  final m = RegExp(r'SqliteException\((\d+)\)').firstMatch(e.toString());
  return m == null
      ? e.runtimeType.toString()
      : 'SqliteException(${m.group(1)})';
}

String _doseKindDb(DoseKind k) => switch (k) {
  DoseKind.scheduled => 'scheduled',
  DoseKind.extra => 'extra',
  DoseKind.oneOff => 'one_off',
};

DoseKind _doseKind(String s) => switch (s) {
  'scheduled' => DoseKind.scheduled,
  'extra' => DoseKind.extra,
  _ => DoseKind.oneOff,
};

String _stepDb(OnboardingStep s) => switch (s) {
  OnboardingStep.bodyProfile => 'body_profile',
  OnboardingStep.calorieDisplay => 'calorie_display',
  OnboardingStep.done => 'done',
};

OnboardingStep _step(String s) => switch (s) {
  'calorie_display' => OnboardingStep.calorieDisplay,
  'done' => OnboardingStep.done,
  _ => OnboardingStep.bodyProfile,
};

double _d(Object? v) => (v as num).toDouble();
double? _dn(Object? v) => v == null ? null : (v as num).toDouble();

Map<String, double> _decode(Object? json) => {
  for (final e in (jsonDecode(json as String) as Map<String, dynamic>).entries)
    e.key: (e.value as num).toDouble(),
};

class DriftJournalRepository implements JournalRepository {
  final JournalDatabase db;
  final DateTime Function() _now;
  final _changes = StreamController<void>.broadcast();
  Future<void>? _pendingWrite;

  DriftJournalRepository(this.db, {DateTime Function()? now})
    : _now = now ?? DateTime.now;

  @override
  Stream<void> get changes => _changes.stream;

  void _changed() {
    if (!_changes.isClosed) _changes.add(null);
  }

  Future<T> _serializeWrite<T>(Future<T> Function() action) async {
    while (_pendingWrite != null) {
      await _pendingWrite;
    }
    final completer = Completer<void>();
    _pendingWrite = completer.future;
    try {
      return await action();
    } finally {
      if (identical(_pendingWrite, completer.future)) {
        _pendingWrite = null;
      }
      if (!completer.isCompleted) completer.complete();
    }
  }

  /// Lỗi lưu trữ không được mang câu SQL hay giá trị ra ngoài (báo cáo crash).
  Future<T> _guard<T>(Future<T> Function() body, {bool write = false}) async {
    Future<T> run() async {
      try {
        final r = await body();
        if (write) _changed();
        return r;
      } on Error {
        rethrow;
      } on StorageFullException {
        rethrow;
      } on Object catch (e) {
        if (_isFull(e)) throw const StorageFullException();
        throw JournalStorageException(_kind(e));
      }
    }

    return write ? _serializeWrite(run) : run();
  }

  static List<Variable<Object>> _vars(List<Object?> args) => [
    for (final a in args)
      switch (a) {
        null => const Variable<String>(null),
        bool() => Variable<int>(a ? 1 : 0),
        int() => Variable<int>(a),
        double() => Variable<double>(a),
        String() => Variable<String>(a),
        _ => throw ArgumentError.value(a),
      },
  ];

  Future<int> _insert(String sql, List<Object?> args) =>
      db.customInsert(sql, variables: _vars(args));

  Future<int> _update(String sql, List<Object?> args) =>
      db.customUpdate(sql, variables: _vars(args));

  Future<List<Map<String, Object?>>> _select(
    String sql, [
    List<Object?> args = const [],
  ]) async => [
    for (final r in await db.customSelect(sql, variables: _vars(args)).get())
      r.data,
  ];

  (int, int, String) _when(DateTime t) {
    final l = t.toLocal();
    return (
      t.toUtc().millisecondsSinceEpoch,
      l.timeZoneOffset.inMinutes,
      dayKey(l),
    );
  }

  static DateTime _at(Object? ms) =>
      DateTime.fromMillisecondsSinceEpoch(ms as int, isUtc: true).toLocal();

  int get _nowMs => _now().toUtc().millisecondsSinceEpoch;

  // ---------------------------------------------------------------- hồ sơ, cài đặt

  @override
  Future<Profile?> loadProfile() => _guard(() async {
    final rows = await _select('SELECT * FROM profile WHERE id = 1');
    if (rows.isEmpty) {
      return null;
    }
    final r = rows.first;
    if (r['sex'] == null || r['height_cm'] == null || r['weight_kg'] == null) {
      return null;
    }
    final level = r['activity_level'] as String?;
    return Profile(
      ageYears: r['age_years'] as int,
      sex: Sex.values.byName(r['sex'] as String),
      heightCm: _d(r['height_cm']),
      weightKg: _d(r['weight_kg']),
      activityLevel: level == null
          ? ActivityLevel.inactive
          : ActivityLevel.values.byName(level),
    );
  });

  @override
  Future<HealthConsentStatus?> latestHealthConsent() => _guard(() async {
    final rows = await _select(
      "SELECT content_version, granted_at FROM consents "
      "WHERE kind = 'health_data' AND withdrawn_at IS NULL "
      "ORDER BY granted_at DESC, id DESC LIMIT 1",
    );
    if (rows.isEmpty) {
      return null;
    }
    final r = rows.first;
    return HealthConsentStatus(
      r['content_version'] as String,
      _at(r['granted_at']),
    );
  });

  /// Tuổi, ngày nhập và câu thuốc, bệnh đã lưu ở bước Đồng ý.
  @override
  Future<ConsentProfileState?> loadConsentProfile() => _guard(() async {
    final rows = await _select(
      'SELECT age_years, age_entered_on, caution, caution_answered_on FROM profile WHERE id = 1',
    );
    if (rows.isEmpty) {
      return null;
    }
    final r = rows.first;
    return (
      ageYears: r['age_years'] as int,
      ageEnteredOn: r['age_entered_on'] as String,
      caution: r['caution'] == 1,
      cautionAnsweredOn: r['caution_answered_on'] as String,
    );
  });

  @override
  Future<void> upgradeHealthConsent({
    required String contentVersion,
    required int ageYears,
    required bool caution,
  }) => _guard(
    write: true,
    () => db.transaction(() async {
      final nowMs = _nowMs;
      final today = dayKey(_now());
      await _update(
        "UPDATE consents SET withdrawn_at = ? WHERE kind = 'health_data' AND withdrawn_at IS NULL",
        [nowMs],
      );
      await _insert(
        "INSERT INTO consents (kind, content_version, granted_at) VALUES ('health_data', ?, ?)",
        [contentVersion, nowMs],
      );
      final n = await _update(
        'UPDATE profile SET '
        'age_entered_on = CASE WHEN age_years = ? THEN age_entered_on ELSE ? END, '
        'age_years = ?, caution = ?, caution_answered_on = ?, updated_at = ? '
        'WHERE id = 1',
        [ageYears, today, ageYears, caution, today, nowMs],
      );
      if (n != 1) throw StateError('Chưa có hồ sơ để nâng cấp đồng ý');
    }),
  );

  /// Lưu giới tính, chiều cao, cân nặng, mức vận động, tuổi. Giai đoạn mang thai,
  /// cho con bú không lưu (MVP; giai đoạn 2 thêm bằng di chuyển lược đồ).
  @override
  Future<void> saveProfile(Profile p) => _guard(write: true, () async {
    final n = await _update(
      'UPDATE profile SET '
      'age_entered_on = CASE WHEN age_years = ? THEN age_entered_on ELSE ? END, '
      'age_years = ?, sex = ?, height_cm = ?, weight_kg = ?, activity_level = ?, updated_at = ? '
      'WHERE id = 1',
      [
        p.ageYears,
        dayKey(_now()),
        p.ageYears,
        p.sex.name,
        p.heightCm,
        p.weightKg,
        p.activityLevel.name,
        _nowMs,
      ],
    );
    if (n != 1) throw StateError('Chưa có hồ sơ: hồ sơ được tạo ở bước Đồng ý');
  });

  @override
  Future<void> saveProfileWithCaution(
    Profile p, {
    required bool caution,
  }) => _guard(
    write: true,
    () => db.transaction(() async {
      final today = dayKey(_now());
      final n = await _update(
        'UPDATE profile SET '
        'age_entered_on = CASE WHEN age_years = ? THEN age_entered_on ELSE ? END, '
        'age_years = ?, caution = ?, caution_answered_on = ?, '
        'sex = ?, height_cm = ?, weight_kg = ?, activity_level = ?, updated_at = ? '
        'WHERE id = 1',
        [
          p.ageYears,
          today,
          p.ageYears,
          caution,
          today,
          p.sex.name,
          p.heightCm,
          p.weightKg,
          p.activityLevel.name,
          _nowMs,
        ],
      );
      if (n != 1) {
        throw StateError('Chưa có hồ sơ: hồ sơ được tạo ở bước Đồng ý');
      }
    }),
  );

  @override
  Future<int?> bumpAgeIfDue(DateTime now) => _guard(
    write: true,
    () => db.transaction(() async {
      final rows = await _select(
        'SELECT age_years, age_entered_on FROM profile WHERE id = 1',
      );
      if (rows.isEmpty) {
      return null;
    }
      final r = rows.first;
      final bump = computeAgeBump(
        r['age_years'] as int,
        r['age_entered_on'] as String,
        now,
      );
      if (bump == null) return null;
      await _update(
        'UPDATE profile SET age_years = ?, age_entered_on = ?, updated_at = ? WHERE id = 1',
        [bump.newAgeYears, bump.newEnteredOn, _nowMs],
      );
      await _insert(
        'INSERT INTO ui_state (key, value) VALUES (?, ?) '
        'ON CONFLICT (key) DO UPDATE SET value = excluded.value',
        [ageBumpedNoticeKey, '${bump.newAgeYears}'],
      );
      return bump.newAgeYears;
    }),
  );

  @override
  Future<bool?> loadHideCalories() => _guard(() async {
    final v = (await _select(
      'SELECT hide_calories FROM settings WHERE id = 1',
    )).first['hide_calories'];
    return v == null ? null : v == 1;
  });

  @override
  Future<void> saveHideCalories(bool v) => _guard(
    write: true,
    () => _update('UPDATE settings SET hide_calories = ? WHERE id = 1', [v]),
  );

  @override
  Future<DayTimesSettings> loadDayTimesSettings() => _guard(() async {
    final r = (await _select(
      'SELECT wake, breakfast, lunch, dinner, sleep, day_times_confirmed, show_tip_card, '
      'has_breakfast, has_lunch, has_dinner, reminder_show_details '
      'FROM settings WHERE id = 1',
    )).first;
    return DayTimesSettings(
      wake: r['wake'] as int,
      breakfast: r['breakfast'] as int,
      lunch: r['lunch'] as int,
      dinner: r['dinner'] as int,
      sleep: r['sleep'] as int,
      dayTimesConfirmed: r['day_times_confirmed'] == 1,
      showTipCard: r['show_tip_card'] == 1,
      hasBreakfast: r['has_breakfast'] == 1,
      hasLunch: r['has_lunch'] == 1,
      hasDinner: r['has_dinner'] == 1,
      reminderShowDetails: r['reminder_show_details'] == 1,
    );
  });

  @override
  Future<void> saveDayTimesSettings(DayTimesSettings s) => _guard(
    write: true,
    () => _update(
      'UPDATE settings SET wake = ?, breakfast = ?, lunch = ?, dinner = ?, sleep = ?, '
      'day_times_confirmed = ?, show_tip_card = ?, has_breakfast = ?, has_lunch = ?, '
      'has_dinner = ?, reminder_show_details = ? WHERE id = 1',
      [
        s.wake,
        s.breakfast,
        s.lunch,
        s.dinner,
        s.sleep,
        s.dayTimesConfirmed,
        s.showTipCard,
        s.hasBreakfast,
        s.hasLunch,
        s.hasDinner,
        s.reminderShowDetails,
      ],
    ),
  );

  @override
  Future<void> saveShowTipCard(bool show) => _guard(
    write: true,
    () => _update('UPDATE settings SET show_tip_card = ? WHERE id = 1', [show]),
  );

  Future<HealthConsentStatus?> _latestConsent(String kind) => _guard(() async {
    final rows = await _select(
      'SELECT content_version, granted_at FROM consents '
      'WHERE kind = ? AND withdrawn_at IS NULL '
      'ORDER BY granted_at DESC, id DESC LIMIT 1',
      [kind],
    );
    if (rows.isEmpty) {
      return null;
    }
    final r = rows.first;
    return HealthConsentStatus(
      r['content_version'] as String,
      _at(r['granted_at']),
    );
  });

  Future<void> _grantConsent(String kind, String contentVersion) => _guard(
    write: true,
    () => db.transaction(() async {
      final nowMs = _nowMs;
      await _update(
        'UPDATE consents SET withdrawn_at = ? WHERE kind = ? AND withdrawn_at IS NULL',
        [nowMs, kind],
      );
      await _insert(
        'INSERT INTO consents (kind, content_version, granted_at) VALUES (?, ?, ?)',
        [kind, contentVersion, nowMs],
      );
    }),
  );

  Future<void> _withdrawConsent(String kind) => _guard(
    write: true,
    () => _update(
      'UPDATE consents SET withdrawn_at = ? WHERE kind = ? AND withdrawn_at IS NULL',
      [_nowMs, kind],
    ),
  );

  @override
  Future<HealthConsentStatus?> latestNotificationConsent() => _latestConsent('notifications');

  @override
  Future<void> grantNotificationConsent(String contentVersion) =>
      _grantConsent('notifications', contentVersion);

  @override
  Future<void> withdrawNotificationConsent() => _withdrawConsent('notifications');

  @override
  Future<HealthConsentStatus?> latestDriveConsent() => _latestConsent('drive');

  @override
  Future<void> grantDriveConsent(String contentVersion) => _grantConsent('drive', contentVersion);

  @override
  Future<void> withdrawDriveConsent() => _withdrawConsent('drive');

  @override
  Future<OnboardingStep> loadOnboardingStep() => _guard(
    () async => _step(
      (await _select(
            'SELECT onboarding_step FROM meta WHERE id = 1',
          )).first['onboarding_step']
          as String,
    ),
  );

  @override
  Future<void> saveOnboardingStep(OnboardingStep s) => _guard(
    write: true,
    () => _update('UPDATE meta SET onboarding_step = ? WHERE id = 1', [
      _stepDb(s),
    ]),
  );

  @override
  Future<String?> getUiState(String key) => _guard(() async {
    final rows = await _select('SELECT value FROM ui_state WHERE key = ?', [
      key,
    ]);
    return rows.isEmpty ? null : rows.first['value'] as String;
  });

  @override
  Future<void> setUiState(String key, String value) => _guard(
    write: true,
    () => _insert(
      'INSERT INTO ui_state (key, value) VALUES (?, ?) '
      'ON CONFLICT (key) DO UPDATE SET value = excluded.value',
      [key, value],
    ),
  );

  @override
  Future<void> deleteUiState(String key) => _guard(
    write: true,
    () => _update('DELETE FROM ui_state WHERE key = ?', [key]),
  );

  @override
  Future<int?> loadAgeBumpedNotice() async =>
      int.tryParse(await getUiState(ageBumpedNoticeKey) ?? '');

  @override
  Future<void> clearAgeBumpedNotice() => deleteUiState(ageBumpedNoticeKey);

  // ---------------------------------------------------------------- dòng chất

  Future<void> _insertLines(
    List<IntakeLine> lines, {
    int? foodId,
    int? doseId,
    required String day,
  }) async {
    for (final l in lines) {
      await _insert(
        'INSERT INTO intake_lines (food_entry_id, dose_entry_id, day, nutrient_id, free_name, source, '
        'form, uncertain, label_amount, label_unit, amounts, ul_amounts) '
        'VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
        [
          foodId,
          doseId,
          day,
          l.nutrientId,
          l.freeName,
          l.source.name,
          l.form,
          l.uncertain,
          l.labelAmount,
          l.labelUnit,
          jsonEncode(l.amounts),
          l.ulAmounts == null ? null : jsonEncode(l.ulAmounts),
        ],
      );
    }
  }

  static IntakeLine _line(Map<String, Object?> r) => IntakeLine(
    nutrientId: r['nutrient_id'] as String?,
    freeName: r['free_name'] as String?,
    source: IntakeSource.values.byName(r['source'] as String),
    form: r['form'] as String?,
    uncertain: r['uncertain'] == 1,
    labelAmount: _dn(r['label_amount']),
    labelUnit: r['label_unit'] as String?,
    amounts: _decode(r['amounts']),
    ulAmounts: r['ul_amounts'] == null ? null : _decode(r['ul_amounts']),
  );

  Future<Map<int, List<IntakeLine>>> _linesBetween(
    String fromDay,
    String toDay,
    String column,
  ) async {
    final out = <int, List<IntakeLine>>{};
    final rows = await _select(
      'SELECT * FROM intake_lines WHERE day >= ? AND day <= ? AND $column IS NOT NULL ORDER BY id',
      [fromDay, toDay],
    );
    for (final r in rows) {
      (out[r[column] as int] ??= []).add(_line(r));
    }
    return out;
  }

  Future<Map<int, List<IntakeLine>>> _linesForIds(
    String column,
    List<int> ids,
  ) async {
    if (ids.isEmpty) return const {};
    final marks = List.filled(ids.length, '?').join(',');
    final out = <int, List<IntakeLine>>{};
    final rows = await _select(
      'SELECT * FROM intake_lines WHERE $column IN ($marks) ORDER BY id',
      ids,
    );
    for (final r in rows) {
      (out[r[column] as int] ??= []).add(_line(r));
    }
    return out;
  }

  // ---------------------------------------------------------------- món ăn

  @override
  Future<int> addFood(FoodEntryInput e) async {
    checkLinesWritable(e.lines);
    return _guard(
      write: true,
      () => db.transaction(() async {
        final (ms, tz, day) = _when(e.at);
        final id = await _insert(
          'INSERT INTO food_entries (at, tz_offset, day, meal, name, food_ref, portion_unit, '
          'portion_qty, label_basis_qty, label_basis_unit, added_sugar_known, pack_version) '
          'VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
          [
            ms,
            tz,
            day,
            e.meal.name,
            e.name,
            e.foodRef,
            e.portionUnit,
            e.portionQty,
            e.labelBasisQty,
            e.labelBasisUnit,
            e.addedSugarKnown,
            e.packVersion,
          ],
        );
        await _insertLines(e.lines, foodId: id, day: day);
        return id;
      }),
    );
  }

  @override
  Future<void> deleteFood(int id) => _guard(
    write: true,
    () => _update('DELETE FROM food_entries WHERE id = ?', [id]),
  );

  @override
  Future<List<FoodEntry>> foodsOn(String day) => foodsBetween(day, day);

  @override
  Future<List<FoodEntry>> foodsBetween(
    String fromDay,
    String toDay,
  ) => _guard(() async {
    final lines = await _linesBetween(fromDay, toDay, 'food_entry_id');
    return [
      for (final r in await _select(
        'SELECT * FROM food_entries WHERE day >= ? AND day <= ? ORDER BY day, at, id',
        [fromDay, toDay],
      ))
        _food(r, lines[r['id'] as int] ?? const []),
    ];
  });

  @override
  Future<List<FoodEntry>> recentFoods({int limit = 20}) => _guard(() async {
    final rows = await _select(
      'SELECT * FROM food_entries ORDER BY at DESC, id DESC LIMIT ?',
      [limit * 8],
    );
    final picked = <Map<String, Object?>>[];
    final seen = <String>{};
    for (final r in rows) {
      final ref = r['food_ref'] as String?;
      final name = r['name'] as String;
      final key = ref ?? 'label:${name.trim().toLowerCase()}';
      if (seen.add(key)) {
        picked.add(r);
        if (picked.length >= limit) break;
      }
    }
    final lines = await _linesForIds('food_entry_id', [
      for (final r in picked) r['id'] as int,
    ]);
    return [
      for (final r in picked) _food(r, lines[r['id'] as int] ?? const []),
    ];
  });

  @override
  Future<FoodEntry?> foodById(int id) => _guard(() async {
    final rows = await _select('SELECT * FROM food_entries WHERE id = ?', [id]);
    if (rows.isEmpty) {
      return null;
    }
    final ls = await _select(
      'SELECT * FROM intake_lines WHERE food_entry_id = ? ORDER BY id',
      [id],
    );
    return _food(rows.first, [for (final l in ls) _line(l)]);
  });

  static FoodEntry _food(Map<String, Object?> r, List<IntakeLine> lines) =>
      FoodEntry(
        id: r['id'] as int,
        at: _at(r['at']),
        day: r['day'] as String,
        meal: Meal.values.byName(r['meal'] as String),
        name: r['name'] as String,
        foodRef: r['food_ref'] as String?,
        portionUnit: r['portion_unit'] as String,
        portionQty: _d(r['portion_qty']),
        labelBasisQty: _dn(r['label_basis_qty']),
        labelBasisUnit: r['label_basis_unit'] as String?,
        addedSugarKnown: r['added_sugar_known'] == 1,
        packVersion: r['pack_version'] as String,
        lines: List.unmodifiable(lines),
      );

  /// Đổi giờ, ngày của món; các dòng chất đổi `day` cùng giao dịch.
  @override
  Future<void> moveFood(int id, DateTime at) => _guard(
    write: true,
    () => db.transaction(() async {
      final (ms, tz, day) = _when(at);
      await _update(
        'UPDATE food_entries SET at = ?, tz_offset = ?, day = ? WHERE id = ?',
        [ms, tz, day, id],
      );
      await _update('UPDATE intake_lines SET day = ? WHERE food_entry_id = ?', [
        day,
        id,
      ]);
    }),
  );

  @override
  Future<void> updateFoodMeta(
    int id, {
    required DateTime at,
    required Meal meal,
  }) => _guard(
    write: true,
    () => db.transaction(() async {
      final (ms, tz, day) = _when(at);
      await _update(
        'UPDATE food_entries SET at = ?, tz_offset = ?, day = ?, meal = ? WHERE id = ?',
        [ms, tz, day, meal.name, id],
      );
      await _update('UPDATE intake_lines SET day = ? WHERE food_entry_id = ?', [
        day,
        id,
      ]);
    }),
  );

  /// Đổi khẩu phần (và tùy chọn giờ/ngày/bữa) của món nhập theo nhãn trong một giao dịch.
  @override
  Future<void> scaleLabelFoodPortion(
    int id,
    double newQty, {
    DateTime? at,
    Meal? meal,
  }) async {
    if (newQty <= 0) throw ArgumentError.value(newQty, 'newQty');
    return _guard(
      write: true,
      () => db.transaction(() async {
        final f = await foodById(id);
        if (f == null) throw StateError('Không có món $id');
        if (f.labelBasisQty == null) {
          throw StateError(
            'Món không theo nhãn: tính lại theo gói dữ liệu (replaceFoodLines)',
          );
        }
        final factor = newQty / f.portionQty;
        final nextAt = at ?? f.at;
        final (ms, tz, day) = _when(nextAt);
        await _update(
          'UPDATE food_entries SET portion_qty = ?, at = ?, tz_offset = ?, day = ?, meal = ? WHERE id = ?',
          [newQty, ms, tz, day, (meal ?? f.meal).name, id],
        );
        await _update('DELETE FROM intake_lines WHERE food_entry_id = ?', [id]);
        await _insertLines(
          [for (final l in f.lines) l.scaled(factor)],
          foodId: id,
          day: day,
        );
      }),
    );
  }

  /// Thay khẩu phần (và tùy chọn đơn vị/giờ/ngày/bữa) và các dòng đã tính lại trong một giao dịch.
  @override
  Future<void> replaceFoodLines(
    int id, {
    required double portionQty,
    String? portionUnit,
    DateTime? at,
    Meal? meal,
    required List<IntakeLine> lines,
    required String packVersion,
  }) async {
    if (portionQty <= 0) throw ArgumentError.value(portionQty, 'portionQty');
    checkLinesWritable(lines);
    return _guard(
      write: true,
      () => db.transaction(() async {
        final rows = await _select(
          'SELECT at, tz_offset, day, meal, portion_unit FROM food_entries WHERE id = ?',
          [id],
        );
        if (rows.isEmpty) throw StateError('Không có món $id');
        final cur = rows.first;
        final String day;
        final int ms;
        final int tz;
        if (at != null) {
          (ms, tz, day) = _when(at);
        } else {
          ms = cur['at'] as int;
          tz = cur['tz_offset'] as int;
          day = cur['day'] as String;
        }
        final nextMeal = meal?.name ?? (cur['meal'] as String);
        final nextUnit = portionUnit ?? (cur['portion_unit'] as String);
        await _update(
          'UPDATE food_entries SET portion_qty = ?, portion_unit = ?, at = ?, tz_offset = ?, day = ?, meal = ?, pack_version = ? WHERE id = ?',
          [portionQty, nextUnit, ms, tz, day, nextMeal, packVersion, id],
        );
        await _update('DELETE FROM intake_lines WHERE food_entry_id = ?', [id]);
        await _insertLines(lines, foodId: id, day: day);
      }),
    );
  }

  @override
  Future<int> saveCustomFood(CustomFoodInput input) => _guard(
    write: true,
    () => db.transaction(() async {
      final id = await _insert(
        'INSERT INTO custom_foods (name, portion_unit, label_basis_qty, label_basis_unit, created_at) '
        'VALUES (?, ?, ?, ?, ?)',
        [
          input.name,
          input.portionUnit,
          input.labelBasisQty,
          input.labelBasisUnit,
          _nowMs,
        ],
      );
      for (final l in input.lines) {
        if (l.source == IntakeSource.supplement) {
          throw ArgumentError('custom_food_lines chỉ nhận food hoặc fortified');
        }
        await _insert(
          'INSERT INTO custom_food_lines (custom_food_id, nutrient_id, form, label_amount, label_unit, source) '
          'VALUES (?, ?, ?, ?, ?, ?)',
          [id, l.nutrientId, l.form, l.labelAmount, l.labelUnit, l.source.name],
        );
      }
      return id;
    }),
  );

  @override
  Future<List<CustomFood>> searchCustomFoods(
    String query, {
    int limit = 30,
  }) => _guard(() async {
    final q = normalizeSearchAscii(query);
    final rows = await _select(
      'SELECT * FROM custom_foods WHERE archived = 0 ORDER BY created_at DESC, id DESC',
    );
    final matched = <Map<String, Object?>>[];
    for (final r in rows) {
      final name = r['name'] as String;
      if (q.isEmpty || normalizeSearchAscii(name).contains(q)) {
        matched.add(r);
        if (matched.length >= limit) break;
      }
    }
    if (matched.isEmpty) return const [];
    final ids = [for (final r in matched) r['id'] as int];
    final marks = List.filled(ids.length, '?').join(',');
    final lineRows = await _select(
      'SELECT * FROM custom_food_lines WHERE custom_food_id IN ($marks) ORDER BY rowid',
      ids,
    );
    final byId = <int, List<CustomFoodLine>>{};
    for (final lr in lineRows) {
      (byId[lr['custom_food_id'] as int] ??= []).add(
        CustomFoodLine(
          nutrientId: lr['nutrient_id'] as String,
          form: lr['form'] as String?,
          labelAmount: _d(lr['label_amount']),
          labelUnit: lr['label_unit'] as String,
          source: IntakeSource.values.byName(lr['source'] as String),
        ),
      );
    }
    return [
      for (final r in matched)
        CustomFood(
          id: r['id'] as int,
          name: r['name'] as String,
          portionUnit: r['portion_unit'] as String,
          labelBasisQty: _d(r['label_basis_qty']),
          labelBasisUnit: r['label_basis_unit'] as String,
          createdAt: _at(r['created_at']),
          archived: r['archived'] == 1,
          lines: List.unmodifiable(
            byId[r['id'] as int] ?? const <CustomFoodLine>[],
          ),
        ),
    ];
  });

  @override
  Future<void> archiveCustomFood(int id) => _guard(
    write: true,
    () => _update('UPDATE custom_foods SET archived = 1 WHERE id = ?', [id]),
  );

  /// Số món "chưa rõ đường bổ sung" trong ngày.
  Future<int> unknownAddedSugarCount(String day) => _guard(
    () async =>
        (await _select(
              'SELECT count(*) AS n FROM food_entries WHERE day = ? AND added_sugar_known = 0',
              [day],
            )).first['n']
            as int,
  );

  // ---------------------------------------------------------------- sản phẩm, kho, lịch

  @override
  Future<int> addProduct(
    String name,
    CountUnit unit,
    double unitsPerServing, {
    String? barcode,
  }) => _guard(
    write: true,
    () => _insert(
      'INSERT INTO products (name, count_unit, units_per_serving, barcode, created_at) VALUES (?, ?, ?, ?, ?)',
      [name, unit.name, unitsPerServing, barcode, _nowMs],
    ),
  );

  Product _productFromRow(Map<String, Object?> r) => Product(
    r['id'] as int,
    r['name'] as String,
    CountUnit.values.byName(r['count_unit'] as String),
    _d(r['units_per_serving']),
    barcode: r['barcode'] as String?,
    archived: (r['archived'] as int? ?? 0) != 0,
  );

  Future<Product> _product(int id) async {
    final rows = await _select('SELECT * FROM products WHERE id = ?', [id]);
    if (rows.isEmpty) throw StateError('Không có sản phẩm $id');
    return _productFromRow(rows.first);
  }

  @override
  Future<Product> productById(int id) => _guard(() => _product(id));

  @override
  Future<Product?> productByBarcode(String barcode) => _guard(() async {
    final rows = await _select(
      'SELECT * FROM products WHERE barcode = ? AND archived = 0 ORDER BY id DESC LIMIT 1',
      [barcode],
    );
    return rows.isEmpty ? null : _productFromRow(rows.first);
  });

  @override
  Future<List<ProductSummary>> listProducts({bool includeArchived = false}) =>
      _guard(() async {
        final t = _now();
        final today = dayKey(t);
        final from = dayKey(t.subtract(const Duration(days: 13)));
        final prods = await _select(
          includeArchived
              ? 'SELECT * FROM products ORDER BY id DESC'
              : 'SELECT * FROM products WHERE archived = 0 ORDER BY id DESC',
        );
        final activeScheds = await schedulesOn(today);
        final recentDoses = await dosesBetween(from, today);
        final out = <ProductSummary>[];
        for (final r in prods) {
          final p = _productFromRow(r);
          final boxes = await boxesOf(p.id);
          out.add(
            summarizeProduct(
              product: p,
              boxes: boxes,
              activeSchedules: [
                for (final s in activeScheds)
                  if (s.productId == p.id) s,
              ],
              recentDoses14Days: [
                for (final d in recentDoses)
                  if (d.productId == p.id) d,
              ],
              now: t,
            ),
          );
        }
        return out;
      });

  @override
  Future<ProductDetail> productDetail(int productId) => _guard(() async {
    final p = await _product(productId);
    final ingRows = await _select(
      'SELECT * FROM ingredients WHERE product_id = ? ORDER BY id',
      [productId],
    );
    final ings = [
      for (final r in ingRows)
        ProductIngredient(
          id: r['id'] as int,
          productId: r['product_id'] as int,
          nutrientId: r['nutrient_id'] as String?,
          freeName: r['free_name'] as String?,
          form: r['form'] as String,
          amountPerServing: r['amount_per_serving'] == null
              ? null
              : _d(r['amount_per_serving']),
          unit: r['unit'] as String?,
          labelAmount: r['label_amount'] == null ? null : _d(r['label_amount']),
          labelUnit: r['label_unit'] as String?,
          isCompound: (r['is_compound'] as int? ?? 0) != 0,
          origin: IngredientOrigin.values.byName(r['origin'] as String),
          confirmed: (r['confirmed'] as int? ?? 0) != 0,
        ),
    ];
    final boxes = await boxesOf(productId);
    return ProductDetail(product: p, ingredients: ings, boxes: boxes);
  });

  @override
  Future<void> updateProduct(
    int id, {
    required String name,
    required CountUnit countUnit,
    required double unitsPerServing,
    String? barcode,
  }) => _guard(
    write: true,
    () => _update(
      'UPDATE products SET name = ?, count_unit = ?, units_per_serving = ?, barcode = ? WHERE id = ?',
      [name, countUnit.name, unitsPerServing, barcode, id],
    ),
  );

  @override
  Future<void> archiveProduct(int id) => _guard(
    write: true,
    () => db.transaction(() async {
      final today = dayKey(_now());
      await _update('UPDATE products SET archived = 1 WHERE id = ?', [id]);
      await _update(
        'UPDATE schedules SET valid_to = ? WHERE product_id = ? AND (valid_to IS NULL OR valid_to > ?)',
        [today, id, today],
      );
    }),
  );

  @override
  Future<void> saveProductIngredients(
    int productId,
    List<IngredientDraft> items,
  ) => _guard(
    write: true,
    () => db.transaction(() async {
      await _product(productId);
      await _update('DELETE FROM ingredients WHERE product_id = ?', [
        productId,
      ]);
      for (final item in items) {
        await _insert(
          'INSERT INTO ingredients '
          '(product_id, nutrient_id, free_name, form, amount_per_serving, unit, label_amount, label_unit, is_compound, origin, confirmed) '
          'VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
          [
            productId,
            item.nutrientId,
            item.freeName,
            item.form,
            item.amountPerServing,
            item.unit,
            item.labelAmount,
            item.labelUnit,
            item.isCompound ? 1 : 0,
            item.origin.name,
            item.confirmed ? 1 : 0,
          ],
        );
      }
    }),
  );

  /// [remaining] theo đơn vị đếm của sản phẩm; [expiryMonth] dạng YYYY-MM.
  @override
  Future<int> addBox(
    int productId,
    double remaining, {
    String? expiryMonth,
  }) => _guard(
    write: true,
    () => _insert(
      'INSERT INTO boxes (product_id, remaining, expiry_month, added_at) VALUES (?, ?, ?, ?)',
      [productId, remaining, expiryMonth, _nowMs],
    ),
  );

  @override
  Future<List<StockBox>> boxesOf(int productId) => _guard(
    () async => [
      for (final r in await _select(
        'SELECT * FROM boxes WHERE product_id = ? ORDER BY id',
        [productId],
      ))
        StockBox(
          r['id'] as int,
          r['product_id'] as int,
          _d(r['remaining']),
          r['expiry_month'] as String?,
        ),
    ],
  );

  @override
  Future<void> updateBox(
    int boxId, {
    required double remaining,
    String? expiryMonth,
  }) {
    if (remaining < 0) throw ArgumentError.value(remaining, 'remaining');
    return _guard(
      write: true,
      () => _update(
        'UPDATE boxes SET remaining = ?, expiry_month = ? WHERE id = ?',
        [remaining, expiryMonth, boxId],
      ),
    );
  }

  @override
  Future<void> deleteBox(int boxId) => _guard(
    write: true,
    () => db.transaction(() async {
      await _update('DELETE FROM dose_box_deductions WHERE box_id = ?', [
        boxId,
      ]);
      await _update('DELETE FROM boxes WHERE id = ?', [boxId]);
    }),
  );

  @override
  Future<int> addSchedule(
    int productId,
    int timeOfDay,
    double servings, {
    required String validFrom,
  }) => _guard(
    write: true,
    () => _insert(
      'INSERT INTO schedules (product_id, time_of_day, servings, valid_from) VALUES (?, ?, ?, ?)',
      [productId, timeOfDay, servings, validFrom],
    ),
  );

  /// Sửa lịch: đóng dòng cũ, mở dòng mới. Có hiệu lực từ [today] nếu hôm nay chưa
  /// đánh dấu lần nào của lịch cũ; nếu đã đánh dấu thì từ ngày mai.
  @override
  Future<ScheduleChange> updateSchedule(
    int id, {
    int? timeOfDay,
    double? servings,
    required String today,
  }) => _guard(
    write: true,
    () => db.transaction(() async {
      final rows = await _select('SELECT * FROM schedules WHERE id = ?', [id]);
      if (rows.isEmpty) throw StateError('Không có lịch $id');
      final old = rows.first;
      if (old['valid_to'] != null) throw StateError('Lịch $id đã đóng');
      final marked = (await _select(
        'SELECT 1 FROM dose_occurrences WHERE schedule_id = ? AND day = ?',
        [id, today],
      )).isNotEmpty;
      var from = marked ? nextDay(today) : today;
      final oldFrom = old['valid_from'] as String;
      if (from.compareTo(oldFrom) < 0) from = oldFrom;
      await _update('UPDATE schedules SET valid_to = ? WHERE id = ?', [
        from,
        id,
      ]);
      final newId = await _insert(
        'INSERT INTO schedules (product_id, time_of_day, servings, valid_from) VALUES (?, ?, ?, ?)',
        [
          old['product_id'],
          timeOfDay ?? old['time_of_day'],
          servings ?? _d(old['servings']),
          from,
        ],
      );
      return ScheduleChange(newId, from);
    }),
  );

  /// Kết thúc lịch (không xóa dòng cũ để giữ lịch sử). Có hiệu lực từ [today]
  /// nếu hôm nay chưa đánh dấu; ngược lại từ ngày mai.
  @override
  Future<void> endSchedule(int id, {required String today}) => _guard(
    write: true,
    () => db.transaction(() async {
      final rows = await _select('SELECT * FROM schedules WHERE id = ?', [id]);
      if (rows.isEmpty) throw StateError('Không có lịch $id');
      final old = rows.first;
      if (old['valid_to'] != null) return;
      final marked = (await _select(
        'SELECT 1 FROM dose_occurrences WHERE schedule_id = ? AND day = ?',
        [id, today],
      )).isNotEmpty;
      var to = marked ? nextDay(today) : today;
      final oldFrom = old['valid_from'] as String;
      if (to.compareTo(oldFrom) < 0) to = oldFrom;
      await _update('UPDATE schedules SET valid_to = ? WHERE id = ?', [to, id]);
    }),
  );

  /// Các dòng lịch có hiệu lực trong [day] (khoảng [valid_from, valid_to)).
  @override
  Future<List<Schedule>> schedulesOn(String day) => _guard(
    () async => [
      for (final r in await _select(
        'SELECT * FROM schedules WHERE valid_from <= ? AND (valid_to IS NULL OR valid_to > ?) '
        'ORDER BY time_of_day, id',
        [day, day],
      ))
        Schedule(
          r['id'] as int,
          r['product_id'] as int,
          r['time_of_day'] as int,
          _d(r['servings']),
          r['valid_from'] as String,
          r['valid_to'] as String?,
        ),
    ],
  );

  @override
  Future<List<Occurrence>> occurrencesOn(String day) => _guard(
    () async => [
      for (final r in await _select(
        'SELECT * FROM dose_occurrences WHERE day = ?',
        [day],
      ))
        Occurrence(
          r['schedule_id'] as int,
          r['day'] as String,
          OccurrenceStatus.values.byName(r['status'] as String),
          r['dose_entry_id'] as int?,
        ),
    ],
  );

  /// [Bỏ qua] một lần theo lịch.
  @override
  Future<void> skipOccurrence(OccurrenceRef o) => _guard(
    write: true,
    () => db.transaction(() async {
      final rows = await _select(
        'SELECT status FROM dose_occurrences WHERE schedule_id = ? AND day = ?',
        [o.scheduleId, o.day],
      );
      if (rows.isNotEmpty && rows.first['status'] == 'taken') {
        throw StateError('Lần này đã đánh dấu đã uống');
      }
      await _insert(
        'INSERT INTO dose_occurrences (schedule_id, day, status, dose_entry_id, updated_at) '
        "VALUES (?, ?, 'skipped', NULL, ?) "
        'ON CONFLICT (schedule_id, day) DO UPDATE SET updated_at = excluded.updated_at',
        [o.scheduleId, o.day, _nowMs],
      );
    }),
  );

  /// Bỏ đánh dấu, về "Chưa đánh dấu". Lần đã uống thì xóa lần uống và trả kho.
  @override
  Future<void> clearOccurrence(OccurrenceRef o) => _guard(
    write: true,
    () => db.transaction(() async {
      final rows = await _select(
        'SELECT dose_entry_id FROM dose_occurrences WHERE schedule_id = ? AND day = ?',
        [o.scheduleId, o.day],
      );
      if (rows.isEmpty) return;
      final doseId = rows.first['dose_entry_id'] as int?;
      if (doseId != null) {
        await _deleteDoseTx(doseId);
      } else {
        await _update(
          'DELETE FROM dose_occurrences WHERE schedule_id = ? AND day = ?',
          [o.scheduleId, o.day],
        );
      }
    }),
  );

  @override
  Future<void> relinkDoseOccurrence(
    int doseId,
    OccurrenceRef? newOccurrence,
  ) => _guard(
    write: true,
    () => db.transaction(() async {
      await _update('DELETE FROM dose_occurrences WHERE dose_entry_id = ?', [
        doseId,
      ]);
      if (newOccurrence != null) {
        final rows = await _select(
          'SELECT status FROM dose_occurrences WHERE schedule_id = ? AND day = ?',
          [newOccurrence.scheduleId, newOccurrence.day],
        );
        if (rows.isNotEmpty && rows.first['status'] == 'taken') {
          throw StateError('Lần này đã đánh dấu đã uống');
        }
        await _insert(
          'INSERT INTO dose_occurrences (schedule_id, day, status, dose_entry_id, updated_at) '
          "VALUES (?, ?, 'taken', ?, ?) "
          "ON CONFLICT (schedule_id, day) DO UPDATE SET status = 'taken', "
          'dose_entry_id = excluded.dose_entry_id, updated_at = excluded.updated_at',
          [newOccurrence.scheduleId, newOccurrence.day, doseId, _nowMs],
        );
      }
    }),
  );

  // ---------------------------------------------------------------- lần uống

  /// Ghi lần uống. Luôn ghi và luôn tính vào giới hạn; kho chỉ ảnh hưởng việc trừ.
  /// Trừ hộp còn hạn hết hạn sớm nhất trước; chỉ còn hộp hết hạn thì theo
  /// [DoseInput.expiredBoxes]; số còn không bao giờ âm.
  @override
  Future<DoseResult> recordDose(DoseInput d) async {
    checkLinesWritable(d.lines);
    if (d.servings <= 0) throw ArgumentError.value(d.servings, 'servings');
    return _guard(
      write: true,
      () => db.transaction<DoseResult>(() async {
        final (ms, tz, day) = _when(d.at);
        final deductions = <BoxDeduction>[];
        var shortfall = 0.0;
        if (d.productId != null && d.deductStock) {
          final product = await _product(d.productId!);
          var need = d.servings * product.unitsPerServing;
          final boxes = await _select(
            'SELECT id, remaining, expiry_month FROM boxes WHERE product_id = ? AND remaining > 0 '
            'ORDER BY expiry_month IS NULL, expiry_month, added_at, id',
            [d.productId],
          );
          final month = monthKey(d.at);
          bool expired(Map<String, Object?> b) {
            final m = b['expiry_month'] as String?;
            return m != null && m.compareTo(month) < 0;
          }

          final valid = [
            for (final b in boxes)
              if (!expired(b)) b,
          ];
          final old = [
            for (final b in boxes)
              if (expired(b)) b,
          ];
          final List<Map<String, Object?>> use;
          if (valid.isNotEmpty) {
            use = valid;
          } else if (old.isNotEmpty) {
            switch (d.expiredBoxes) {
              case ExpiredBoxChoice.ask:
                return const NeedsExpiredChoice();
              case ExpiredBoxChoice.deduct:
                use = old;
              case ExpiredBoxChoice.skip:
                use = const [];
            }
          } else {
            use = const [];
          }
          for (final b in use) {
            if (need <= 0) break;
            final rem = _d(b['remaining']);
            final take = rem < need ? rem : need;
            await _update(
              'UPDATE boxes SET remaining = remaining - ? WHERE id = ?',
              [take, b['id']],
            );
            deductions.add(BoxDeduction(b['id'] as int, take));
            need -= take;
          }
          shortfall = need > 1e-9 ? need : 0;
        }
        final id = await _insert(
          'INSERT INTO dose_entries (at, tz_offset, day, product_id, name, kind, servings, pack_version) '
          'VALUES (?, ?, ?, ?, ?, ?, ?, ?)',
          [
            ms,
            tz,
            day,
            d.productId,
            d.name,
            _doseKindDb(d.kind),
            d.servings,
            d.packVersion,
          ],
        );
        await _insertLines(d.lines, doseId: id, day: day);
        for (final x in deductions) {
          await _insert(
            'INSERT INTO dose_box_deductions (dose_entry_id, box_id, amount) VALUES (?, ?, ?)',
            [id, x.boxId, x.amount],
          );
        }
        final o = d.occurrence;
        if (o != null) {
          final rows = await _select(
            'SELECT status FROM dose_occurrences WHERE schedule_id = ? AND day = ?',
            [o.scheduleId, o.day],
          );
          if (rows.isNotEmpty && rows.first['status'] == 'taken') {
            throw StateError('Lần này đã đánh dấu đã uống');
          }
          await _insert(
            'INSERT INTO dose_occurrences (schedule_id, day, status, dose_entry_id, updated_at) '
            "VALUES (?, ?, 'taken', ?, ?) "
            "ON CONFLICT (schedule_id, day) DO UPDATE SET status = 'taken', "
            'dose_entry_id = excluded.dose_entry_id, updated_at = excluded.updated_at',
            [o.scheduleId, o.day, id, _nowMs],
          );
        }
        return DoseRecorded(id, shortfall);
      }),
    );
  }

  Future<void> _deleteDoseTx(int id) async {
    for (final r in await _select(
      'SELECT box_id, amount FROM dose_box_deductions WHERE dose_entry_id = ?',
      [id],
    )) {
      await _update('UPDATE boxes SET remaining = remaining + ? WHERE id = ?', [
        _d(r['amount']),
        r['box_id'],
      ]);
    }
    // Dòng chất, dòng trừ kho, trạng thái lần theo lịch xóa theo khóa ngoại.
    await _update('DELETE FROM dose_entries WHERE id = ?', [id]);
  }

  /// Xóa, Hoàn tác: trả kho đúng các hộp đã trừ, bỏ đánh dấu lần theo lịch.
  @override
  Future<void> deleteDose(int id) =>
      _guard(write: true, () => db.transaction(() => _deleteDoseTx(id)));

  /// Đổi giờ, ngày của lần uống; các dòng chất đổi `day` cùng giao dịch.
  @override
  Future<void> moveDose(int id, DateTime at) => _guard(
    write: true,
    () => db.transaction(() async {
      final (ms, tz, day) = _when(at);
      await _update(
        'UPDATE dose_entries SET at = ?, tz_offset = ?, day = ? WHERE id = ?',
        [ms, tz, day, id],
      );
      await _update('UPDATE intake_lines SET day = ? WHERE dose_entry_id = ?', [
        day,
        id,
      ]);
    }),
  );

  @override
  Future<DoseResult> updateDose(UpdateDoseInput input) async {
    checkLinesWritable(input.lines);
    if (input.servings <= 0) {
      throw ArgumentError.value(input.servings, 'servings');
    }
    return _guard(
      write: true,
      () => db.transaction<DoseResult>(() async {
        final rows = await _select('SELECT * FROM dose_entries WHERE id = ?', [
          input.doseId,
        ]);
        if (rows.isEmpty) throw StateError('Không có lần uống ${input.doseId}');
        final old = rows.first;
        final productId = old['product_id'] as int?;
        final oldDeductions = await _select(
          'SELECT box_id, amount FROM dose_box_deductions WHERE dose_entry_id = ?',
          [input.doseId],
        );

        final month = monthKey(input.at);
        bool expired(Map<String, Object?> b) {
          final m = b['expiry_month'] as String?;
          return m != null && m.compareTo(month) < 0;
        }

        if (productId != null && input.expiredBoxes == ExpiredBoxChoice.ask) {
          final restoredByBox = <int, double>{
            for (final r in oldDeductions) r['box_id'] as int: _d(r['amount']),
          };
          final allBoxes = await _select(
            'SELECT id, remaining, expiry_month FROM boxes WHERE product_id = ?',
            [productId],
          );
          final effective = [
            for (final b in allBoxes)
              if (_d(b['remaining']) + (restoredByBox[b['id'] as int] ?? 0) > 0)
                b,
          ];
          final hasValid = effective.any((b) => !expired(b));
          final hasOld = effective.any(expired);
          if (!hasValid && hasOld) {
            return const NeedsExpiredChoice();
          }
        }

        for (final r in oldDeductions) {
          await _update(
            'UPDATE boxes SET remaining = remaining + ? WHERE id = ?',
            [_d(r['amount']), r['box_id']],
          );
        }
        await _update(
          'DELETE FROM dose_box_deductions WHERE dose_entry_id = ?',
          [input.doseId],
        );

        var shortfall = 0.0;
        if (productId != null) {
          final product = await _product(productId);
          var need = input.servings * product.unitsPerServing;
          final boxes = await _select(
            'SELECT id, remaining, expiry_month FROM boxes WHERE product_id = ? AND remaining > 0 '
            'ORDER BY expiry_month IS NULL, expiry_month, added_at, id',
            [productId],
          );
          final valid = [
            for (final b in boxes)
              if (!expired(b)) b,
          ];
          final oldBoxes = [
            for (final b in boxes)
              if (expired(b)) b,
          ];
          final List<Map<String, Object?>> use;
          if (valid.isNotEmpty) {
            use = valid;
          } else if (oldBoxes.isNotEmpty) {
            use = input.expiredBoxes == ExpiredBoxChoice.deduct
                ? oldBoxes
                : const [];
          } else {
            use = const [];
          }
          for (final b in use) {
            if (need <= 0) break;
            final rem = _d(b['remaining']);
            final take = rem < need ? rem : need;
            await _update(
              'UPDATE boxes SET remaining = remaining - ? WHERE id = ?',
              [take, b['id']],
            );
            await _insert(
              'INSERT INTO dose_box_deductions (dose_entry_id, box_id, amount) VALUES (?, ?, ?)',
              [input.doseId, b['id'], take],
            );
            need -= take;
          }
          shortfall = need > 1e-9 ? need : 0.0;
        }

        final (ms, tz, day) = _when(input.at);
        await _update(
          'UPDATE dose_entries SET at = ?, tz_offset = ?, day = ?, name = COALESCE(?, name), servings = ?, pack_version = ? WHERE id = ?',
          [
            ms,
            tz,
            day,
            input.name,
            input.servings,
            input.packVersion,
            input.doseId,
          ],
        );
        await _update('DELETE FROM intake_lines WHERE dose_entry_id = ?', [
          input.doseId,
        ]);
        await _insertLines(input.lines, doseId: input.doseId, day: day);
        return DoseRecorded(input.doseId, shortfall);
      }),
    );
  }

  @override
  Future<List<DoseEntry>> dosesOn(String day) => dosesBetween(day, day);

  @override
  Future<List<DoseEntry>> dosesBetween(
    String fromDay,
    String toDay,
  ) => _guard(() async {
    final lines = await _linesBetween(fromDay, toDay, 'dose_entry_id');
    final deductions = <int, List<BoxDeduction>>{};
    for (final r in await _select(
      'SELECT x.dose_entry_id, x.box_id, x.amount FROM dose_box_deductions x '
      'JOIN dose_entries d ON d.id = x.dose_entry_id WHERE d.day >= ? AND d.day <= ?',
      [fromDay, toDay],
    )) {
      (deductions[r['dose_entry_id'] as int] ??= []).add(
        BoxDeduction(r['box_id'] as int, _d(r['amount'])),
      );
    }
    return [
      for (final r in await _select(
        'SELECT * FROM dose_entries WHERE day >= ? AND day <= ? ORDER BY day, at, id',
        [fromDay, toDay],
      ))
        DoseEntry(
          id: r['id'] as int,
          at: _at(r['at']),
          day: r['day'] as String,
          productId: r['product_id'] as int?,
          name: r['name'] as String?,
          kind: _doseKind(r['kind'] as String),
          servings: _d(r['servings']),
          packVersion: r['pack_version'] as String,
          lines: List.unmodifiable(
            lines[r['id'] as int] ?? const <IntakeLine>[],
          ),
          deductions: List.unmodifiable(
            deductions[r['id'] as int] ?? const <BoxDeduction>[],
          ),
        ),
    ];
  });

  // ---------------------------------------------------------------- nước, buổi tập

  @override
  Future<int> addWater(DateTime at, double ml) {
    final (ms, tz, day) = _when(at);
    return _guard(
      write: true,
      () => _insert(
        'INSERT INTO water_entries (at, tz_offset, day, ml) VALUES (?, ?, ?, ?)',
        [ms, tz, day, ml],
      ),
    );
  }

  @override
  Future<void> updateWater(int id, {required DateTime at, required double ml}) {
    final (ms, tz, day) = _when(at);
    return _guard(
      write: true,
      () => _update(
        'UPDATE water_entries SET at = ?, tz_offset = ?, day = ?, ml = ? WHERE id = ?',
        [ms, tz, day, ml, id],
      ),
    );
  }

  @override
  Future<void> deleteWater(int id) => _guard(
    write: true,
    () => _update('DELETE FROM water_entries WHERE id = ?', [id]),
  );

  @override
  Future<List<WaterRecord>> waterOn(String day) => waterBetween(day, day);

  @override
  Future<List<WaterRecord>> waterBetween(
    String fromDay,
    String toDay,
  ) => _guard(
    () async => [
      for (final r in await _select(
        'SELECT * FROM water_entries WHERE day >= ? AND day <= ? ORDER BY day, at, id',
        [fromDay, toDay],
      ))
        WaterRecord(r['id'] as int, _at(r['at']), _d(r['ml'])),
    ],
  );

  @override
  Future<double?> lastWaterMl() => _guard(() async {
    final rows = await _select(
      'SELECT ml FROM water_entries ORDER BY at DESC, id DESC LIMIT 1',
    );
    return rows.isEmpty ? null : _d(rows.first['ml']);
  });

  @override
  Future<int> addWorkout(DateTime startAt, WorkoutEntry w) {
    final (ms, tz, day) = _when(startAt);
    return _guard(
      write: true,
      () => _insert(
        'INSERT INTO workout_entries (start_at, tz_offset, day, activity_code, minutes) VALUES (?, ?, ?, ?, ?)',
        [ms, tz, day, w.activityCode, w.minutes],
      ),
    );
  }

  @override
  Future<void> updateWorkout(int id, DateTime startAt, WorkoutEntry w) {
    final (ms, tz, day) = _when(startAt);
    return _guard(
      write: true,
      () => _update(
        'UPDATE workout_entries SET start_at = ?, tz_offset = ?, day = ?, activity_code = ?, minutes = ? WHERE id = ?',
        [ms, tz, day, w.activityCode, w.minutes, id],
      ),
    );
  }

  @override
  Future<void> deleteWorkout(int id) => _guard(
    write: true,
    () => _update('DELETE FROM workout_entries WHERE id = ?', [id]),
  );

  @override
  Future<List<WorkoutRecord>> workoutsOn(String day) =>
      workoutsBetween(day, day);

  @override
  Future<List<WorkoutRecord>> workoutsBetween(
    String fromDay,
    String toDay,
  ) => _guard(
    () async => [
      for (final r in await _select(
        'SELECT * FROM workout_entries WHERE day >= ? AND day <= ? ORDER BY day, start_at, id',
        [fromDay, toDay],
      ))
        WorkoutRecord(
          r['id'] as int,
          _at(r['start_at']),
          r['day'] as String,
          WorkoutEntry(
            activityCode: r['activity_code'] as String,
            minutes: _d(r['minutes']),
            day: r['day'] as String,
          ),
        ),
    ],
  );

  /// Chờ ghi hiện tại xong, dồn WAL (`TRUNCATE`) và sao chép tệp CSDL sang [dest].
  Future<void> copyTruncatedDbTo(File dest) => _serializeWrite(() async {
    try {
      await db.customSelect('PRAGMA wal_checkpoint(TRUNCATE)').get();
      final dbs = await db.customSelect('PRAGMA database_list').get();
      String? mainPath;
      for (final r in dbs) {
        if (r.data['name'] == 'main') {
          mainPath = r.data['file'] as String?;
          break;
        }
      }
      if (mainPath == null || mainPath.isEmpty) {
        throw const JournalStorageException('NoMainDatabaseFile');
      }
      dest.parent.createSync(recursive: true);
      File(mainPath).copySync(dest.path);
    } on Error {
      rethrow;
    } on Object catch (e) {
      if (e is JournalStorageException) rethrow;
      if (_isFull(e)) throw const StorageFullException();
      throw JournalStorageException(_kind(e));
    }
  });

  @override
  Future<Map<String, Object?>> exportReadableJson() => _guard(() async {
    const tables = <String, String>{
      'meta': 'SELECT * FROM meta',
      'consents': 'SELECT * FROM consents ORDER BY id',
      'profile': 'SELECT * FROM profile ORDER BY id',
      'settings': 'SELECT * FROM settings ORDER BY id',
      'products': 'SELECT * FROM products ORDER BY id',
      'ingredients': 'SELECT * FROM ingredients ORDER BY id',
      'boxes': 'SELECT * FROM boxes ORDER BY id',
      'schedules': 'SELECT * FROM schedules ORDER BY id',
      'dose_entries': 'SELECT * FROM dose_entries ORDER BY id',
      'dose_occurrences':
          'SELECT * FROM dose_occurrences ORDER BY schedule_id, day',
      'dose_box_deductions':
          'SELECT * FROM dose_box_deductions ORDER BY dose_entry_id, box_id',
      'food_entries': 'SELECT * FROM food_entries ORDER BY id',
      'custom_foods': 'SELECT * FROM custom_foods ORDER BY id',
      'custom_food_lines':
          'SELECT * FROM custom_food_lines ORDER BY custom_food_id, nutrient_id',
      'intake_lines': 'SELECT * FROM intake_lines ORDER BY id',
      'water_entries': 'SELECT * FROM water_entries ORDER BY id',
      'workout_entries': 'SELECT * FROM workout_entries ORDER BY id',
      'ui_state': 'SELECT * FROM ui_state ORDER BY key',
    };
    final data = <String, Object?>{};
    for (final entry in tables.entries) {
      data[entry.key] = await _select(entry.value);
    }
    return <String, Object?>{
      'app': 'WholeWell',
      'schemaVersion': currentSchemaVersion,
      'exportedAt': _now().toUtc().toIso8601String(),
      'tables': data,
    };
  });

  @override
  Future<void> close() async {
    await _changes.close();
    await db.close();
  }
}
