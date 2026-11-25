/// Lưu trữ nhật ký, bất đồng bộ (đặc tả encrypted-db, mục Interface).
library;

import 'dart:async';

import 'package:health_engine/health_engine.dart';

import 'intake.dart';
import 'models.dart';

/// Phần lưu trữ mà trạng thái app dùng. Kho, lịch uống chỉ có ở bản CSDL
/// ([DriftJournalRepository]); bản bộ nhớ dùng để test giao diện.
abstract interface class JournalRepository {
  /// Phát sau mỗi lần ghi.
  Stream<void> get changes;

  Future<HealthConsentStatus?> latestHealthConsent();
  Future<ConsentProfileState?> loadConsentProfile();
  Future<void> upgradeHealthConsent({
    required String contentVersion,
    required int ageYears,
    required bool caution,
  });

  /// null khi chưa xong Hồ sơ cơ thể (giới tính, chiều cao, cân nặng còn trống).
  Future<Profile?> loadProfile();
  Future<void> saveProfile(Profile p);
  Future<void> saveProfileWithCaution(Profile p, {required bool caution});
  Future<int?> bumpAgeIfDue(DateTime now);

  /// null: chưa chọn (màn Hiển thị calo không chọn sẵn).
  Future<bool?> loadHideCalories();
  Future<void> saveHideCalories(bool v);

  Future<OnboardingStep> loadOnboardingStep();
  Future<void> saveOnboardingStep(OnboardingStep s);

  Future<String?> getUiState(String key);
  Future<void> setUiState(String key, String value);
  Future<void> deleteUiState(String key);
  Future<int?> loadAgeBumpedNotice();
  Future<void> clearAgeBumpedNotice();

  Future<int> addWater(DateTime at, double ml);
  Future<void> updateWater(int id, {required DateTime at, required double ml});
  Future<void> deleteWater(int id);
  Future<List<WaterRecord>> waterOn(String day);
  Future<List<WaterRecord>> waterBetween(String fromDay, String toDay);
  Future<double?> lastWaterMl();

  Future<int> addFood(FoodEntryInput e);
  Future<void> deleteFood(int id);
  Future<FoodEntry?> foodById(int id);
  Future<void> moveFood(int id, DateTime at);
  Future<void> updateFoodMeta(int id, {required DateTime at, required Meal meal});
  Future<void> scaleLabelFoodPortion(int id, double newQty, {DateTime? at, Meal? meal});
  Future<void> replaceFoodLines(
    int id, {
    required double portionQty,
    String? portionUnit,
    DateTime? at,
    Meal? meal,
    required List<IntakeLine> lines,
    required String packVersion,
  });
  Future<List<FoodEntry>> foodsOn(String day);
  Future<List<FoodEntry>> foodsBetween(String fromDay, String toDay);
  Future<List<FoodEntry>> recentFoods({int limit = 20});

  Future<int> saveCustomFood(CustomFoodInput input);
  Future<List<CustomFood>> searchCustomFoods(String query, {int limit = 30});
  Future<void> archiveCustomFood(int id);

  Future<int> addProduct(
    String name,
    CountUnit unit,
    double unitsPerServing, {
    String? barcode,
  });
  Future<Product> productById(int id);
  Future<Product?> productByBarcode(String barcode);
  Future<List<ProductSummary>> listProducts({bool includeArchived = false});
  Future<ProductDetail> productDetail(int productId);
  Future<void> updateProduct(
    int id, {
    required String name,
    required CountUnit countUnit,
    required double unitsPerServing,
    String? barcode,
  });
  Future<void> archiveProduct(int id);
  Future<void> saveProductIngredients(int productId, List<IngredientDraft> items);

  Future<int> addBox(int productId, double remaining, {String? expiryMonth});
  Future<List<StockBox>> boxesOf(int productId);
  Future<void> updateBox(int boxId, {required double remaining, String? expiryMonth});
  Future<void> deleteBox(int boxId);

  Future<DoseResult> recordDose(DoseInput d);
  Future<DoseResult> updateDose(UpdateDoseInput input);
  Future<void> moveDose(int id, DateTime at);
  Future<void> deleteDose(int id);
  Future<List<DoseEntry>> dosesOn(String day);
  Future<List<DoseEntry>> dosesBetween(String fromDay, String toDay);

  Future<int> addWorkout(DateTime startAt, WorkoutEntry w);
  Future<void> deleteWorkout(int id);
  Future<List<WorkoutRecord>> workoutsOn(String day);
  Future<List<WorkoutRecord>> workoutsBetween(String fromDay, String toDay);

  Future<void> close();
}

/// Bản bộ nhớ (test giao diện). Không có kho: lần uống không trừ hộp nào.
class InMemoryJournalRepository implements JournalRepository {
  final _changes = StreamController<void>.broadcast();
  HealthConsentStatus? _consent;
  int _ageYears;
  String _ageEnteredOn;
  bool _caution;
  String _cautionAnsweredOn;
  Profile? _profile;
  bool? _hide;
  OnboardingStep _step = OnboardingStep.bodyProfile;
  final _uiState = <String, String>{};
  final _foods = <FoodEntry>[];
  final _customFoods = <CustomFood>[];
  final _products = <Product>[];
  final _ingredients = <ProductIngredient>[];
  final _boxes = <StockBox>[];
  final _doses = <DoseEntry>[];
  final _workouts = <WorkoutRecord>[];
  final _waters = <WaterRecord>[];
  int _nextId = 1;

  /// Mặc định khởi tạo sẵn đồng ý [mvpConsentVersion] để tương thích các test giao diện/state cũ.
  InMemoryJournalRepository({
    String? initialConsentVersion = mvpConsentVersion,
    bool initialCaution = false,
    int initialAgeYears = 30,
    String? initialAgeEnteredOn,
    String? initialCautionAnsweredOn,
  })  : _consent = initialConsentVersion == null
            ? null
            : HealthConsentStatus(initialConsentVersion, DateTime.now()),
        _ageYears = initialAgeYears,
        _ageEnteredOn = initialAgeEnteredOn ?? dayKey(DateTime.now()),
        _caution = initialCaution,
        _cautionAnsweredOn = initialCautionAnsweredOn ?? dayKey(DateTime.now());

  void _changed() => _changes.add(null);

  @override
  Stream<void> get changes => _changes.stream;

  @override
  Future<HealthConsentStatus?> latestHealthConsent() async => _consent;

  @override
  Future<ConsentProfileState?> loadConsentProfile() async => (
        ageYears: _ageYears,
        ageEnteredOn: _ageEnteredOn,
        caution: _caution,
        cautionAnsweredOn: _cautionAnsweredOn,
      );

  @override
  Future<void> upgradeHealthConsent({
    required String contentVersion,
    required int ageYears,
    required bool caution,
  }) async {
    final today = dayKey(DateTime.now());
    _consent = HealthConsentStatus(contentVersion, DateTime.now());
    if (_ageYears != ageYears) {
      _ageYears = ageYears;
      _ageEnteredOn = today;
    }
    _caution = caution;
    _cautionAnsweredOn = today;
    if (_profile != null) {
      final p = _profile!;
      _profile = Profile(
        ageYears: ageYears,
        sex: p.sex,
        heightCm: p.heightCm,
        weightKg: p.weightKg,
        stage: p.stage,
        gestationWeek: p.gestationWeek,
        prePregnancyBmi: p.prePregnancyBmi,
        monthsPostpartum: p.monthsPostpartum,
        activityLevel: p.activityLevel,
      );
    }
    _changed();
  }

  @override
  Future<Profile?> loadProfile() async => _profile;
  @override
  Future<void> saveProfile(Profile p) async {
    if (_ageYears != p.ageYears) {
      _ageYears = p.ageYears;
      _ageEnteredOn = dayKey(DateTime.now());
    }
    _profile = p;
    _changed();
  }

  @override
  Future<void> saveProfileWithCaution(Profile p, {required bool caution}) async {
    final today = dayKey(DateTime.now());
    if (_ageYears != p.ageYears) {
      _ageYears = p.ageYears;
      _ageEnteredOn = today;
    }
    _caution = caution;
    _cautionAnsweredOn = today;
    _profile = p;
    _changed();
  }

  @override
  Future<int?> bumpAgeIfDue(DateTime now) async {
    final bump = computeAgeBump(_ageYears, _ageEnteredOn, now);
    if (bump == null) return null;
    _ageYears = bump.newAgeYears;
    _ageEnteredOn = bump.newEnteredOn;
    if (_profile != null) {
      final p = _profile!;
      _profile = Profile(
        ageYears: bump.newAgeYears,
        sex: p.sex,
        heightCm: p.heightCm,
        weightKg: p.weightKg,
        stage: p.stage,
        gestationWeek: p.gestationWeek,
        prePregnancyBmi: p.prePregnancyBmi,
        monthsPostpartum: p.monthsPostpartum,
        activityLevel: p.activityLevel,
      );
    }
    _uiState[ageBumpedNoticeKey] = '${bump.newAgeYears}';
    _changed();
    return bump.newAgeYears;
  }

  @override
  Future<bool?> loadHideCalories() async => _hide;
  @override
  Future<void> saveHideCalories(bool v) async {
    _hide = v;
    _changed();
  }

  @override
  Future<OnboardingStep> loadOnboardingStep() async => _step;
  @override
  Future<void> saveOnboardingStep(OnboardingStep s) async {
    _step = s;
    _changed();
  }

  @override
  Future<String?> getUiState(String key) async => _uiState[key];
  @override
  Future<void> setUiState(String key, String value) async {
    _uiState[key] = value;
    _changed();
  }

  @override
  Future<void> deleteUiState(String key) async {
    _uiState.remove(key);
    _changed();
  }

  @override
  Future<int?> loadAgeBumpedNotice() async => int.tryParse(_uiState[ageBumpedNoticeKey] ?? '');
  @override
  Future<void> clearAgeBumpedNotice() => deleteUiState(ageBumpedNoticeKey);

  @override
  Future<int> addWater(DateTime at, double ml) async {
    final id = _nextId++;
    _waters.add(WaterRecord(id, at, ml));
    _changed();
    return id;
  }

  @override
  Future<void> updateWater(int id, {required DateTime at, required double ml}) async {
    final idx = _waters.indexWhere((w) => w.id == id);
    if (idx >= 0) _waters[idx] = WaterRecord(id, at, ml);
    _changed();
  }

  @override
  Future<void> deleteWater(int id) async {
    _waters.removeWhere((w) => w.id == id);
    _changed();
  }

  @override
  Future<List<WaterRecord>> waterOn(String day) async => [
        for (final w in _waters)
          if (dayKey(w.at) == day) w,
      ]..sort((a, b) {
          final c = a.at.compareTo(b.at);
          return c != 0 ? c : a.id.compareTo(b.id);
        });

  @override
  Future<List<WaterRecord>> waterBetween(String fromDay, String toDay) async => [
        for (final w in _waters)
          if (dayKey(w.at).compareTo(fromDay) >= 0 && dayKey(w.at).compareTo(toDay) <= 0) w,
      ]..sort((a, b) {
          final d = dayKey(a.at).compareTo(dayKey(b.at));
          if (d != 0) return d;
          final c = a.at.compareTo(b.at);
          return c != 0 ? c : a.id.compareTo(b.id);
        });

  @override
  Future<double?> lastWaterMl() async {
    if (_waters.isEmpty) return null;
    final sorted = [..._waters]..sort((a, b) {
        final c = b.at.compareTo(a.at);
        return c != 0 ? c : b.id.compareTo(a.id);
      });
    return sorted.first.ml;
  }

  @override
  Future<int> addFood(FoodEntryInput e) async {
    checkLinesWritable(e.lines);
    final id = _nextId++;
    _foods.add(FoodEntry(
      id: id,
      at: e.at,
      day: dayKey(e.at),
      meal: e.meal,
      name: e.name,
      foodRef: e.foodRef,
      portionUnit: e.portionUnit,
      portionQty: e.portionQty,
      labelBasisQty: e.labelBasisQty,
      labelBasisUnit: e.labelBasisUnit,
      addedSugarKnown: e.addedSugarKnown,
      packVersion: e.packVersion,
      lines: List.unmodifiable(e.lines),
    ));
    _changed();
    return id;
  }

  @override
  Future<void> deleteFood(int id) async {
    _foods.removeWhere((f) => f.id == id);
    _changed();
  }

  @override
  Future<FoodEntry?> foodById(int id) async {
    for (final f in _foods) {
      if (f.id == id) return f;
    }
    return null;
  }

  @override
  Future<void> moveFood(int id, DateTime at) async {
    final idx = _foods.indexWhere((f) => f.id == id);
    if (idx < 0) return;
    final f = _foods[idx];
    _foods[idx] = FoodEntry(
      id: f.id,
      at: at,
      day: dayKey(at),
      meal: f.meal,
      name: f.name,
      foodRef: f.foodRef,
      portionUnit: f.portionUnit,
      portionQty: f.portionQty,
      labelBasisQty: f.labelBasisQty,
      labelBasisUnit: f.labelBasisUnit,
      addedSugarKnown: f.addedSugarKnown,
      packVersion: f.packVersion,
      lines: f.lines,
    );
    _changed();
  }

  @override
  Future<void> updateFoodMeta(int id, {required DateTime at, required Meal meal}) async {
    final idx = _foods.indexWhere((f) => f.id == id);
    if (idx < 0) return;
    final f = _foods[idx];
    _foods[idx] = FoodEntry(
      id: f.id,
      at: at,
      day: dayKey(at),
      meal: meal,
      name: f.name,
      foodRef: f.foodRef,
      portionUnit: f.portionUnit,
      portionQty: f.portionQty,
      labelBasisQty: f.labelBasisQty,
      labelBasisUnit: f.labelBasisUnit,
      addedSugarKnown: f.addedSugarKnown,
      packVersion: f.packVersion,
      lines: f.lines,
    );
    _changed();
  }

  @override
  Future<void> scaleLabelFoodPortion(int id, double newQty, {DateTime? at, Meal? meal}) async {
    if (newQty <= 0) throw ArgumentError.value(newQty, 'newQty');
    final idx = _foods.indexWhere((f) => f.id == id);
    if (idx < 0) throw StateError('Không có món $id');
    final f = _foods[idx];
    if (f.labelBasisQty == null) {
      throw StateError('Món không theo nhãn: tính lại theo gói dữ liệu (replaceFoodLines)');
    }
    final factor = newQty / f.portionQty;
    final nextAt = at ?? f.at;
    _foods[idx] = FoodEntry(
      id: f.id,
      at: nextAt,
      day: dayKey(nextAt),
      meal: meal ?? f.meal,
      name: f.name,
      foodRef: f.foodRef,
      portionUnit: f.portionUnit,
      portionQty: newQty,
      labelBasisQty: f.labelBasisQty,
      labelBasisUnit: f.labelBasisUnit,
      addedSugarKnown: f.addedSugarKnown,
      packVersion: f.packVersion,
      lines: List.unmodifiable([for (final l in f.lines) l.scaled(factor)]),
    );
    _changed();
  }

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
    final idx = _foods.indexWhere((f) => f.id == id);
    if (idx < 0) throw StateError('Không có món $id');
    final f = _foods[idx];
    final nextAt = at ?? f.at;
    _foods[idx] = FoodEntry(
      id: f.id,
      at: nextAt,
      day: dayKey(nextAt),
      meal: meal ?? f.meal,
      name: f.name,
      foodRef: f.foodRef,
      portionUnit: portionUnit ?? f.portionUnit,
      portionQty: portionQty,
      labelBasisQty: f.labelBasisQty,
      labelBasisUnit: f.labelBasisUnit,
      addedSugarKnown: f.addedSugarKnown,
      packVersion: packVersion,
      lines: List.unmodifiable(lines),
    );
    _changed();
  }

  @override
  Future<List<FoodEntry>> foodsOn(String day) async =>
      [for (final f in _foods) if (f.day == day) f]..sort((a, b) => a.at.compareTo(b.at));

  @override
  Future<List<FoodEntry>> foodsBetween(String fromDay, String toDay) async => [
        for (final f in _foods)
          if (f.day.compareTo(fromDay) >= 0 && f.day.compareTo(toDay) <= 0) f
      ]..sort((a, b) {
          final c = a.day.compareTo(b.day);
          return c != 0 ? c : a.at.compareTo(b.at);
        });

  @override
  Future<List<FoodEntry>> recentFoods({int limit = 20}) async {
    final sorted = [..._foods]..sort((a, b) {
        final c = b.at.compareTo(a.at);
        return c != 0 ? c : b.id.compareTo(a.id);
      });
    final seen = <String>{};
    final out = <FoodEntry>[];
    for (final f in sorted) {
      final key = f.foodRef ?? 'label:${f.name.trim().toLowerCase()}';
      if (seen.add(key)) {
        out.add(f);
        if (out.length >= limit) break;
      }
    }
    return out;
  }

  @override
  Future<int> saveCustomFood(CustomFoodInput input) async {
    final id = _nextId++;
    _customFoods.add(CustomFood(
      id: id,
      name: input.name,
      portionUnit: input.portionUnit,
      labelBasisQty: input.labelBasisQty,
      labelBasisUnit: input.labelBasisUnit,
      createdAt: DateTime.now(),
      archived: false,
      lines: List.unmodifiable(input.lines),
    ));
    _changed();
    return id;
  }

  @override
  Future<List<CustomFood>> searchCustomFoods(String query, {int limit = 30}) async {
    final q = normalizeSearchAscii(query);
    final active = [for (final c in _customFoods) if (!c.archived) c]
      ..sort((a, b) => b.id.compareTo(a.id));
    final out = <CustomFood>[];
    for (final c in active) {
      if (q.isEmpty || normalizeSearchAscii(c.name).contains(q)) {
        out.add(c);
        if (out.length >= limit) break;
      }
    }
    return out;
  }

  @override
  Future<void> archiveCustomFood(int id) async {
    final idx = _customFoods.indexWhere((c) => c.id == id);
    if (idx < 0) return;
    final c = _customFoods[idx];
    _customFoods[idx] = CustomFood(
      id: c.id,
      name: c.name,
      portionUnit: c.portionUnit,
      labelBasisQty: c.labelBasisQty,
      labelBasisUnit: c.labelBasisUnit,
      createdAt: c.createdAt,
      archived: true,
      lines: c.lines,
    );
    _changed();
  }

  @override
  Future<int> addProduct(
    String name,
    CountUnit unit,
    double unitsPerServing, {
    String? barcode,
  }) async {
    final id = _nextId++;
    _products.add(Product(id, name, unit, unitsPerServing, barcode: barcode));
    _changed();
    return id;
  }

  @override
  Future<Product> productById(int id) async =>
      _products.firstWhere((p) => p.id == id, orElse: () => throw StateError('Không có sản phẩm $id'));

  @override
  Future<Product?> productByBarcode(String barcode) async {
    for (final p in _products) {
      if (!p.archived && p.barcode == barcode) return p;
    }
    return null;
  }

  @override
  Future<List<ProductSummary>> listProducts({bool includeArchived = false}) async {
    final now = DateTime.now();
    final today = dayKey(now);
    final from = dayKey(now.subtract(const Duration(days: 13)));
    final out = <ProductSummary>[];
    for (final p in _products) {
      if (!includeArchived && p.archived) continue;
      final boxes = [for (final b in _boxes) if (b.productId == p.id) b];
      final recent = [
        for (final d in _doses)
          if (d.productId == p.id && d.day.compareTo(from) >= 0 && d.day.compareTo(today) <= 0) d,
      ];
      out.add(summarizeProduct(
        product: p,
        boxes: boxes,
        activeSchedules: const [],
        recentDoses14Days: recent,
        now: now,
      ));
    }
    return out;
  }

  @override
  Future<ProductDetail> productDetail(int productId) async {
    final p = await productById(productId);
    final ing = [for (final i in _ingredients) if (i.productId == productId) i];
    final boxes = await boxesOf(productId);
    return ProductDetail(product: p, ingredients: ing, boxes: boxes);
  }

  @override
  Future<void> updateProduct(
    int id, {
    required String name,
    required CountUnit countUnit,
    required double unitsPerServing,
    String? barcode,
  }) async {
    final idx = _products.indexWhere((p) => p.id == id);
    if (idx < 0) throw StateError('Không có sản phẩm $id');
    final old = _products[idx];
    _products[idx] = Product(
      id,
      name,
      countUnit,
      unitsPerServing,
      barcode: barcode,
      archived: old.archived,
    );
    _changed();
  }

  @override
  Future<void> archiveProduct(int id) async {
    final idx = _products.indexWhere((p) => p.id == id);
    if (idx < 0) throw StateError('Không có sản phẩm $id');
    final old = _products[idx];
    _products[idx] = Product(
      old.id,
      old.name,
      old.countUnit,
      old.unitsPerServing,
      barcode: old.barcode,
      archived: true,
    );
    _changed();
  }

  @override
  Future<void> saveProductIngredients(int productId, List<IngredientDraft> items) async {
    await productById(productId);
    _ingredients.removeWhere((i) => i.productId == productId);
    for (final item in items) {
      _ingredients.add(ProductIngredient(
        id: _nextId++,
        productId: productId,
        nutrientId: item.nutrientId,
        freeName: item.freeName,
        form: item.form,
        amountPerServing: item.amountPerServing,
        unit: item.unit,
        labelAmount: item.labelAmount,
        labelUnit: item.labelUnit,
        isCompound: item.isCompound,
        origin: item.origin,
        confirmed: item.confirmed,
      ));
    }
    _changed();
  }

  @override
  Future<int> addBox(int productId, double remaining, {String? expiryMonth}) async {
    final id = _nextId++;
    _boxes.add(StockBox(id, productId, remaining, expiryMonth));
    _changed();
    return id;
  }

  @override
  Future<List<StockBox>> boxesOf(int productId) async =>
      [for (final b in _boxes) if (b.productId == productId) b];

  @override
  Future<void> updateBox(int boxId, {required double remaining, String? expiryMonth}) async {
    if (remaining < 0) throw ArgumentError.value(remaining, 'remaining');
    final idx = _boxes.indexWhere((b) => b.id == boxId);
    if (idx < 0) throw StateError('Không có hộp $boxId');
    final old = _boxes[idx];
    _boxes[idx] = StockBox(old.id, old.productId, remaining, expiryMonth);
    _changed();
  }

  @override
  Future<void> deleteBox(int boxId) async {
    _boxes.removeWhere((b) => b.id == boxId);
    _changed();
  }

  ({List<BoxDeduction> deductions, double shortfall})? _planDeduction(
    int productId,
    double servings,
    DateTime at,
    ExpiredBoxChoice expiredChoice,
  ) {
    final prod = _products.firstWhere(
      (p) => p.id == productId,
      orElse: () => throw StateError('Không có sản phẩm $productId'),
    );
    var need = servings * prod.unitsPerServing;
    final month = monthKey(at);
    final candidates = [for (final b in _boxes) if (b.productId == productId && b.remaining > 0) b]
      ..sort((a, b) {
        if (a.expiryMonth == null && b.expiryMonth == null) return a.id.compareTo(b.id);
        if (a.expiryMonth == null) return 1;
        if (b.expiryMonth == null) return -1;
        final c = a.expiryMonth!.compareTo(b.expiryMonth!);
        return c != 0 ? c : a.id.compareTo(b.id);
      });
    bool isExpired(StockBox b) => b.expiryMonth != null && b.expiryMonth!.compareTo(month) < 0;
    final valid = [for (final b in candidates) if (!isExpired(b)) b];
    final old = [for (final b in candidates) if (isExpired(b)) b];
    final List<StockBox> use;
    if (valid.isNotEmpty) {
      use = valid;
    } else if (old.isNotEmpty) {
      switch (expiredChoice) {
        case ExpiredBoxChoice.ask:
          return null;
        case ExpiredBoxChoice.deduct:
          use = old;
        case ExpiredBoxChoice.skip:
          use = const [];
      }
    } else {
      use = const [];
    }
    final deductions = <BoxDeduction>[];
    for (final b in use) {
      if (need <= 0) break;
      final take = b.remaining < need ? b.remaining : need;
      final idx = _boxes.indexWhere((x) => x.id == b.id);
      _boxes[idx] = StockBox(b.id, b.productId, b.remaining - take, b.expiryMonth);
      deductions.add(BoxDeduction(b.id, take));
      need -= take;
    }
    return (deductions: deductions, shortfall: need > 1e-9 ? need : 0.0);
  }

  void _restoreDeductions(List<BoxDeduction> deductions) {
    for (final d in deductions) {
      final idx = _boxes.indexWhere((b) => b.id == d.boxId);
      if (idx >= 0) {
        final b = _boxes[idx];
        _boxes[idx] = StockBox(b.id, b.productId, b.remaining + d.amount, b.expiryMonth);
      }
    }
  }

  @override
  Future<DoseResult> recordDose(DoseInput d) async {
    checkLinesWritable(d.lines);
    if (d.servings <= 0) throw ArgumentError.value(d.servings, 'servings');
    var deductions = const <BoxDeduction>[];
    var shortfall = 0.0;
    if (d.productId != null && d.deductStock) {
      final res = _planDeduction(d.productId!, d.servings, d.at, d.expiredBoxes);
      if (res == null) return const NeedsExpiredChoice();
      deductions = res.deductions;
      shortfall = res.shortfall;
    }
    final id = _nextId++;
    _doses.add(DoseEntry(
      id: id,
      at: d.at,
      day: dayKey(d.at),
      productId: d.productId,
      name: d.name,
      kind: d.kind,
      servings: d.servings,
      packVersion: d.packVersion,
      lines: List.unmodifiable(d.lines),
      deductions: List.unmodifiable(deductions),
    ));
    _changed();
    return DoseRecorded(id, shortfall);
  }

  @override
  Future<DoseResult> updateDose(UpdateDoseInput input) async {
    checkLinesWritable(input.lines);
    if (input.servings <= 0) throw ArgumentError.value(input.servings, 'servings');
    final idx = _doses.indexWhere((d) => d.id == input.doseId);
    if (idx < 0) throw StateError('Không có lần uống ${input.doseId}');
    final old = _doses[idx];
    // Tạm hoàn kho trong bộ nhớ để kiểm tra; nếu NeedsExpiredChoice thì khôi phục nguyên trạng.
    _restoreDeductions(old.deductions);
    var newDeductions = const <BoxDeduction>[];
    var shortfall = 0.0;
    if (old.productId != null && old.deductions.isNotEmpty) {
      final res = _planDeduction(old.productId!, input.servings, input.at, input.expiredBoxes);
      if (res == null) {
        // Hoàn tác lại trạng thái kho cũ (trừ lại như cũ) vì chưa sửa.
        for (final d in old.deductions) {
          final bi = _boxes.indexWhere((b) => b.id == d.boxId);
          if (bi >= 0) {
            final b = _boxes[bi];
            _boxes[bi] = StockBox(b.id, b.productId, b.remaining - d.amount, b.expiryMonth);
          }
        }
        return const NeedsExpiredChoice();
      }
      newDeductions = res.deductions;
      shortfall = res.shortfall;
    } else if (old.productId != null) {
      final res = _planDeduction(old.productId!, input.servings, input.at, input.expiredBoxes);
      if (res == null) {
        return const NeedsExpiredChoice();
      }
      newDeductions = res.deductions;
      shortfall = res.shortfall;
    }
    _doses[idx] = DoseEntry(
      id: old.id,
      at: input.at,
      day: dayKey(input.at),
      productId: old.productId,
      name: old.name,
      kind: old.kind,
      servings: input.servings,
      packVersion: input.packVersion,
      lines: List.unmodifiable(input.lines),
      deductions: List.unmodifiable(newDeductions),
    );
    _changed();
    return DoseRecorded(old.id, shortfall);
  }

  @override
  Future<void> moveDose(int id, DateTime at) async {
    final idx = _doses.indexWhere((d) => d.id == id);
    if (idx < 0) return;
    final old = _doses[idx];
    _doses[idx] = DoseEntry(
      id: old.id,
      at: at,
      day: dayKey(at),
      productId: old.productId,
      name: old.name,
      kind: old.kind,
      servings: old.servings,
      packVersion: old.packVersion,
      lines: old.lines,
      deductions: old.deductions,
    );
    _changed();
  }

  @override
  Future<void> deleteDose(int id) async {
    final idx = _doses.indexWhere((d) => d.id == id);
    if (idx >= 0) {
      _restoreDeductions(_doses[idx].deductions);
      _doses.removeAt(idx);
      _changed();
    }
  }

  @override
  Future<List<DoseEntry>> dosesOn(String day) async =>
      [for (final d in _doses) if (d.day == day) d]..sort((a, b) => a.at.compareTo(b.at));

  @override
  Future<List<DoseEntry>> dosesBetween(String fromDay, String toDay) async => [
        for (final d in _doses)
          if (d.day.compareTo(fromDay) >= 0 && d.day.compareTo(toDay) <= 0) d
      ]..sort((a, b) {
          final c = a.day.compareTo(b.day);
          return c != 0 ? c : a.at.compareTo(b.at);
        });

  @override
  Future<int> addWorkout(DateTime startAt, WorkoutEntry w) async {
    final id = _nextId++;
    final d = dayKey(startAt);
    _workouts.add(WorkoutRecord(
      id,
      startAt,
      d,
      WorkoutEntry(activityCode: w.activityCode, minutes: w.minutes, day: d),
    ));
    _changed();
    return id;
  }

  @override
  Future<void> deleteWorkout(int id) async {
    _workouts.removeWhere((w) => w.id == id);
    _changed();
  }

  @override
  Future<List<WorkoutRecord>> workoutsOn(String day) async =>
      [for (final w in _workouts) if (w.day == day) w]..sort((a, b) => a.startAt.compareTo(b.startAt));

  @override
  Future<List<WorkoutRecord>> workoutsBetween(String fromDay, String toDay) async => [
        for (final w in _workouts)
          if (w.day.compareTo(fromDay) >= 0 && w.day.compareTo(toDay) <= 0) w
      ]..sort((a, b) {
          final c = a.day.compareTo(b.day);
          return c != 0 ? c : a.startAt.compareTo(b.startAt);
        });

  @override
  Future<void> close() async => _changes.close();
}
