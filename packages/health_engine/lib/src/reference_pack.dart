/// Đọc gói dữ liệu tham chiếu (assets/reference_pack.json).
library;

import 'dart:convert';

import 'models.dart';

enum TargetKind { rda, ai, none }

enum UlScope { total, supplement, synthetic }

enum EerType { none, adult, pregnant, lactating }

class SourceRef {
  final String id;
  final String label;
  final String title;
  final String url;
  final String? retrieved;
  const SourceRef(this.id, this.label, this.title, this.url, [this.retrieved]);
}

class GroupDef {
  final String id;
  final Sex? sex;
  final LifeStage stage;
  final int minAge;
  final int? maxAge;
  final String amdrKey;
  final double? proteinPerKg;
  final EerType eerType;

  const GroupDef({
    required this.id,
    required this.sex,
    required this.stage,
    required this.minAge,
    required this.maxAge,
    required this.amdrKey,
    required this.proteinPerKg,
    required this.eerType,
  });

  factory GroupDef.fromJson(Map<String, dynamic> j) => GroupDef(
        id: j['id'] as String,
        sex: switch (j['sex'] as String?) {
          'male' => Sex.male,
          'female' => Sex.female,
          _ => null,
        },
        stage: switch (j['stage'] as String) {
          'pregnant' => LifeStage.pregnant,
          'lactating' => LifeStage.lactating,
          _ => LifeStage.none,
        },
        minAge: (j['minAge'] as num).toInt(),
        maxAge: (j['maxAge'] as num?)?.toInt(),
        amdrKey: j['amdrKey'] as String,
        proteinPerKg: (j['proteinPerKg'] as num?)?.toDouble(),
        eerType: switch (j['eerType'] as String) {
          'adult' => EerType.adult,
          'pregnant' => EerType.pregnant,
          'lactating' => EerType.lactating,
          _ => EerType.none,
        },
      );
}

class NutrientDef {
  final String id;
  final String nameVi;
  final String unit;
  final String group;
  final TargetKind kind;
  final Map<String, double> target;
  final Map<String, double> ul;
  final UlScope ulScope;

  /// Khi khác null, UL so với lượng của khóa này (vd. vitA → retinol).
  final String? ulKey;
  final String source;

  const NutrientDef({
    required this.id,
    required this.nameVi,
    required this.unit,
    required this.group,
    required this.kind,
    required this.target,
    required this.ul,
    required this.ulScope,
    required this.ulKey,
    required this.source,
  });
}

class EerCoef {
  final double a, age, height, weight, gestWeek;
  const EerCoef(this.a, this.age, this.height, this.weight, [this.gestWeek = 0]);

  factory EerCoef.fromJson(Map<String, dynamic> j) => EerCoef(
        _d(j['a']),
        _d(j['age']),
        _d(j['height']),
        _d(j['weight']),
        j['gestWeek'] == null ? 0 : _d(j['gestWeek']),
      );
}

class Activity {
  final String code;
  final double met;
  final String nameVi;
  final bool muscleStrengthening;
  const Activity(this.code, this.met, this.nameVi, this.muscleStrengthening);
}

class Range {
  final double min, max;
  const Range(this.min, this.max);
  bool contains(double v) => v >= min && v <= max;
}

class VitaminEEsterDef {
  final double tocopherolRatio;
  final bool isNatural;
  const VitaminEEsterDef({required this.tocopherolRatio, required this.isNatural});
}

class ReferencePack {
  final String version;
  final int minProfileAge;
  final List<GroupDef> groups;
  final Map<String, SourceRef> sources;
  final Map<String, NutrientDef> nutrients;

  final Map<String, Map<String, EerCoef>> eerAdult;
  final Map<String, EerCoef> eerPregnancy;
  final int firstTrimesterMaxWeek;
  final Map<String, double> pregnancyDeposition;
  final ({double milk, double mobilization}) lactation0to6;
  final ({double milk, double mobilization}) lactation7to12;

  final Map<String, Map<String, Range>> amdr;
  final double addedSugarMaxGramsPerMeal;
  final Map<String, double> energyPerGram;

  final Map<String, Activity> activities;
  final double moderateMinMet, vigorousMinMet;
  final Range weeklyModerateMin, weeklyVigorousMin;
  final int strengthDaysPerWeek;
  final Map<String, double> palSuggestionThresholds;

  final Map<String, double> unitConversions;
  final double? foodBetaCaroteneIuToUgRae;
  final Map<String, VitaminEEsterDef> vitaminEEsters;
  final Map<String, Map<String, double>> compounds;

  ReferencePack._({
    required this.version,
    required this.minProfileAge,
    required this.groups,
    required this.sources,
    required this.nutrients,
    required this.eerAdult,
    required this.eerPregnancy,
    required this.firstTrimesterMaxWeek,
    required this.pregnancyDeposition,
    required this.lactation0to6,
    required this.lactation7to12,
    required this.amdr,
    required this.addedSugarMaxGramsPerMeal,
    required this.energyPerGram,
    required this.activities,
    required this.moderateMinMet,
    required this.vigorousMinMet,
    required this.weeklyModerateMin,
    required this.weeklyVigorousMin,
    required this.strengthDaysPerWeek,
    required this.palSuggestionThresholds,
    required this.unitConversions,
    required this.foodBetaCaroteneIuToUgRae,
    required this.vitaminEEsters,
    required this.compounds,
  });

  factory ReferencePack.fromJsonString(String s) =>
      ReferencePack.fromJson(jsonDecode(s) as Map<String, dynamic>);

  factory ReferencePack.fromJson(Map<String, dynamic> j) {
    if (j['schema'] != 2) {
      throw const FormatException('reference_pack: schema không hỗ trợ');
    }
    final sources = <String, SourceRef>{
      for (final s in (j['sources'] as List).cast<Map<String, dynamic>>())
        s['id'] as String: SourceRef(
          s['id'] as String,
          s['label'] as String,
          s['title'] as String,
          s['url'] as String,
          s['retrieved'] as String?,
        ),
    };
    final nutrients = <String, NutrientDef>{};
    for (final n in (j['nutrients'] as List).cast<Map<String, dynamic>>()) {
      final def = NutrientDef(
        id: n['id'] as String,
        nameVi: n['nameVi'] as String,
        unit: n['unit'] as String,
        group: n['group'] as String,
        kind: switch (n['kind'] as String) {
          'RDA' => TargetKind.rda,
          'AI' => TargetKind.ai,
          _ => TargetKind.none,
        },
        target: _numMap(n['target']),
        ul: _numMap(n['ul']),
        ulScope: switch (n['ulScope'] as String) {
          'supplement' => UlScope.supplement,
          'synthetic' => UlScope.synthetic,
          _ => UlScope.total,
        },
        ulKey: n['ulKey'] as String?,
        source: n['source'] as String,
      );
      nutrients[def.id] = def;
    }

    final eer = j['eer'] as Map<String, dynamic>;
    final adult = <String, Map<String, EerCoef>>{};
    (eer['adult'] as Map<String, dynamic>).forEach((sex, levels) {
      adult[sex] = {
        for (final e in (levels as Map<String, dynamic>).entries)
          e.key: EerCoef.fromJson(e.value as Map<String, dynamic>),
      };
    });
    final preg = {
      for (final e in (eer['pregnancy'] as Map<String, dynamic>).entries)
        e.key: EerCoef.fromJson(e.value as Map<String, dynamic>),
    };
    final lact = eer['lactation'] as Map<String, dynamic>;
    ({double milk, double mobilization}) lac(String k) {
      final m = lact[k] as Map<String, dynamic>;
      return (milk: _d(m['milk']), mobilization: _d(m['mobilization']));
    }

    Range rangeOf(List<dynamic> l) => Range(_d(l[0]), _d(l[1]));
    Map<String, Range> ranges(Map<String, dynamic> m) => {
          for (final e in m.entries) e.key: rangeOf(e.value as List),
        };
    final amdrRaw = j['amdr'] as Map<String, dynamic>;
    final amdr = <String, Map<String, Range>>{
      for (final e in amdrRaw.entries)
        if (e.value is Map<String, dynamic>) e.key: ranges(e.value as Map<String, dynamic>),
    };
    final sugar = j['addedSugar'] as Map<String, dynamic>;
    final pag = j['pag'] as Map<String, dynamic>;
    final pal = j['palSuggestion'] as Map<String, dynamic>;
    final epg = j['energyPerGram'] as Map<String, dynamic>;
    final uc = j['unitConversions'] as Map<String, dynamic>;

    final estersRaw = (uc['vitaminEEsters'] as Map<String, dynamic>?) ?? const {};
    final esters = <String, VitaminEEsterDef>{
      for (final e in estersRaw.entries)
        e.key: VitaminEEsterDef(
          tocopherolRatio: _d((e.value as Map<String, dynamic>)['tocopherolRatio']),
          isNatural: (e.value as Map<String, dynamic>)['origin'] == 'natural',
        ),
    };
    final compRaw = (uc['compounds'] as Map<String, dynamic>?) ?? const {};
    final compounds = <String, Map<String, double>>{
      for (final e in compRaw.entries) e.key: _numMap(e.value),
    };

    return ReferencePack._(
      version: j['version'] as String,
      minProfileAge: (j['minProfileAge'] as num).toInt(),
      groups: [
        for (final g in (j['groups'] as List).cast<Map<String, dynamic>>())
          GroupDef.fromJson(g),
      ],
      sources: sources,
      nutrients: nutrients,
      eerAdult: adult,
      eerPregnancy: preg,
      firstTrimesterMaxWeek: (eer['pregnancyFirstTrimesterMaxWeek'] as num).toInt(),
      pregnancyDeposition: _numMap(eer['pregnancyDeposition']),
      lactation0to6: lac('0_6'),
      lactation7to12: lac('7_12'),
      amdr: amdr,
      addedSugarMaxGramsPerMeal: _d(sugar['maxGramsPerMeal']),
      energyPerGram: {
        for (final e in epg.entries)
          if (e.value is num) e.key: _d(e.value),
      },
      activities: {
        for (final a in (j['activities'] as List).cast<Map<String, dynamic>>())
          a['code'] as String: Activity(
            a['code'] as String,
            _d(a['met']),
            a['nameVi'] as String,
            a['muscleStrengthening'] as bool,
          ),
      },
      moderateMinMet: _d(pag['moderateMinMet']),
      vigorousMinMet: _d(pag['vigorousMinMet']),
      weeklyModerateMin: rangeOf(pag['weeklyModerateMin'] as List),
      weeklyVigorousMin: rangeOf(pag['weeklyVigorousMin'] as List),
      strengthDaysPerWeek: (pag['strengthDaysPerWeek'] as num).toInt(),
      palSuggestionThresholds: _numMap(pal['moderateEquivalentMinPerDay']),
      unitConversions: {
        for (final e in uc.entries)
          if (e.value is num) e.key: _d(e.value),
      },
      foodBetaCaroteneIuToUgRae:
          (uc['vitA_food_betacarotene_IU_to_ug_RAE'] as num?)?.toDouble(),
      vitaminEEsters: esters,
      compounds: compounds,
    );
  }
}

double _d(Object? v) => (v as num).toDouble();

Map<String, double> _numMap(Object? m) => {
      for (final e in (m as Map<String, dynamic>).entries) e.key: _d(e.value),
    };
