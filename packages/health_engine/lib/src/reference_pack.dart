/// Đọc gói dữ liệu tham chiếu (assets/reference_pack.json).
library;

import 'dart:convert';

enum TargetKind { rda, ai, none }

enum UlScope { total, supplement, synthetic }

class SourceRef {
  final String id;
  final String label;
  final String title;
  final String url;
  const SourceRef(this.id, this.label, this.title, this.url);
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
  const Activity(this.code, this.met, this.nameVi);
}

class Range {
  final double min, max;
  const Range(this.min, this.max);
  bool contains(double v) => v >= min && v <= max;
}

class ReferencePack {
  final String version;
  final List<String> groups;
  final Map<String, SourceRef> sources;
  final Map<String, NutrientDef> nutrients;
  final double proteinPerKgAdult;

  /// EER: [sex][level] cho người 19+.
  final Map<String, Map<String, EerCoef>> eerAdult;
  final Map<String, EerCoef> eerPregnancy;
  final int eerMinAge;
  final int firstTrimesterMaxWeek;
  final Map<String, double> pregnancyDeposition;
  final ({double milk, double mobilization}) lactation0to6;
  final ({double milk, double mobilization}) lactation7to12;

  final Map<String, Range> amdrAdult;
  final Map<String, Range> amdrTeen;
  final double addedSugarMaxPercent;
  final double addedSugarMaxGramsPerMeal;
  final Map<String, double> energyPerGram;

  final Map<String, Activity> activities;
  final double moderateMinMet, vigorousMinMet;
  final Map<String, double> palSuggestionThresholds;
  final Map<String, double> unitConversions;

  ReferencePack._({
    required this.version,
    required this.groups,
    required this.sources,
    required this.nutrients,
    required this.proteinPerKgAdult,
    required this.eerAdult,
    required this.eerPregnancy,
    required this.eerMinAge,
    required this.firstTrimesterMaxWeek,
    required this.pregnancyDeposition,
    required this.lactation0to6,
    required this.lactation7to12,
    required this.amdrAdult,
    required this.amdrTeen,
    required this.addedSugarMaxPercent,
    required this.addedSugarMaxGramsPerMeal,
    required this.energyPerGram,
    required this.activities,
    required this.moderateMinMet,
    required this.vigorousMinMet,
    required this.palSuggestionThresholds,
    required this.unitConversions,
  });

  factory ReferencePack.fromJsonString(String s) =>
      ReferencePack.fromJson(jsonDecode(s) as Map<String, dynamic>);

  factory ReferencePack.fromJson(Map<String, dynamic> j) {
    if (j['schema'] != 1) {
      throw const FormatException('reference_pack: schema không hỗ trợ');
    }
    final sources = <String, SourceRef>{
      for (final s in (j['sources'] as List).cast<Map<String, dynamic>>())
        s['id'] as String: SourceRef(s['id'] as String, s['label'] as String,
            s['title'] as String, s['url'] as String),
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

    Map<String, Range> ranges(Map<String, dynamic> m) => {
          for (final e in m.entries)
            e.key: Range(_d((e.value as List)[0]), _d((e.value as List)[1])),
        };
    final amdr = j['amdr'] as Map<String, dynamic>;
    final sugar = j['addedSugar'] as Map<String, dynamic>;
    final pag = j['pag'] as Map<String, dynamic>;
    final pal = j['palSuggestion'] as Map<String, dynamic>;
    final epg = j['energyPerGram'] as Map<String, dynamic>;

    return ReferencePack._(
      version: j['version'] as String,
      groups: (j['groups'] as List).cast<String>(),
      sources: sources,
      nutrients: nutrients,
      proteinPerKgAdult: _d((j['proteinPerKg'] as Map<String, dynamic>)['adult19']),
      eerAdult: adult,
      eerPregnancy: preg,
      eerMinAge: (eer['minAge'] as num).toInt(),
      firstTrimesterMaxWeek: (eer['pregnancyFirstTrimesterMaxWeek'] as num).toInt(),
      pregnancyDeposition: _numMap(eer['pregnancyDeposition']),
      lactation0to6: lac('0_6'),
      lactation7to12: lac('7_12'),
      amdrAdult: ranges(amdr['adult19'] as Map<String, dynamic>),
      amdrTeen: ranges(amdr['age4_18'] as Map<String, dynamic>),
      addedSugarMaxPercent: _d(sugar['maxPercentEnergyPerDay']),
      addedSugarMaxGramsPerMeal: _d(sugar['maxGramsPerMeal']),
      energyPerGram: {
        for (final e in epg.entries)
          if (e.value is num) e.key: _d(e.value),
      },
      activities: {
        for (final a in (j['activities'] as List).cast<Map<String, dynamic>>())
          a['code'] as String:
              Activity(a['code'] as String, _d(a['met']), a['nameVi'] as String),
      },
      moderateMinMet: _d(pag['moderateMinMet']),
      vigorousMinMet: _d(pag['vigorousMinMet']),
      palSuggestionThresholds: _numMap(pal['moderateEquivalentMinPerDay']),
      unitConversions: {
        for (final e in (j['unitConversions'] as Map<String, dynamic>).entries)
          if (e.value is num) e.key: _d(e.value),
      },
    );
  }
}

double _d(Object? v) => (v as num).toDouble();

Map<String, double> _numMap(Object? m) => {
      for (final e in (m as Map<String, dynamic>).entries) e.key: _d(e.value),
    };
