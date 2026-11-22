// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $PeopleTable extends People with TableInfo<$PeopleTable, PersonRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PeopleTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _displayNameMeta =
      const VerificationMeta('displayName');
  @override
  late final GeneratedColumn<String> displayName = GeneratedColumn<String>(
      'display_name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _isPrimaryMeta =
      const VerificationMeta('isPrimary');
  @override
  late final GeneratedColumn<bool> isPrimary = GeneratedColumn<bool>(
      'is_primary', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_primary" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
      'created_at', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [id, displayName, isPrimary, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'people';
  @override
  VerificationContext validateIntegrity(Insertable<PersonRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('display_name')) {
      context.handle(
          _displayNameMeta,
          displayName.isAcceptableOrUnknown(
              data['display_name']!, _displayNameMeta));
    } else if (isInserting) {
      context.missing(_displayNameMeta);
    }
    if (data.containsKey('is_primary')) {
      context.handle(_isPrimaryMeta,
          isPrimary.isAcceptableOrUnknown(data['is_primary']!, _isPrimaryMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PersonRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PersonRow(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      displayName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}display_name'])!,
      isPrimary: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_primary'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $PeopleTable createAlias(String alias) {
    return $PeopleTable(attachedDatabase, alias);
  }
}

class PersonRow extends DataClass implements Insertable<PersonRow> {
  final int id;
  final String displayName;
  final bool isPrimary;
  final int createdAt;
  const PersonRow(
      {required this.id,
      required this.displayName,
      required this.isPrimary,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['display_name'] = Variable<String>(displayName);
    map['is_primary'] = Variable<bool>(isPrimary);
    map['created_at'] = Variable<int>(createdAt);
    return map;
  }

  PeopleCompanion toCompanion(bool nullToAbsent) {
    return PeopleCompanion(
      id: Value(id),
      displayName: Value(displayName),
      isPrimary: Value(isPrimary),
      createdAt: Value(createdAt),
    );
  }

  factory PersonRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PersonRow(
      id: serializer.fromJson<int>(json['id']),
      displayName: serializer.fromJson<String>(json['displayName']),
      isPrimary: serializer.fromJson<bool>(json['isPrimary']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'displayName': serializer.toJson<String>(displayName),
      'isPrimary': serializer.toJson<bool>(isPrimary),
      'createdAt': serializer.toJson<int>(createdAt),
    };
  }

  PersonRow copyWith(
          {int? id, String? displayName, bool? isPrimary, int? createdAt}) =>
      PersonRow(
        id: id ?? this.id,
        displayName: displayName ?? this.displayName,
        isPrimary: isPrimary ?? this.isPrimary,
        createdAt: createdAt ?? this.createdAt,
      );
  PersonRow copyWithCompanion(PeopleCompanion data) {
    return PersonRow(
      id: data.id.present ? data.id.value : this.id,
      displayName:
          data.displayName.present ? data.displayName.value : this.displayName,
      isPrimary: data.isPrimary.present ? data.isPrimary.value : this.isPrimary,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PersonRow(')
          ..write('id: $id, ')
          ..write('displayName: $displayName, ')
          ..write('isPrimary: $isPrimary, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, displayName, isPrimary, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PersonRow &&
          other.id == this.id &&
          other.displayName == this.displayName &&
          other.isPrimary == this.isPrimary &&
          other.createdAt == this.createdAt);
}

class PeopleCompanion extends UpdateCompanion<PersonRow> {
  final Value<int> id;
  final Value<String> displayName;
  final Value<bool> isPrimary;
  final Value<int> createdAt;
  const PeopleCompanion({
    this.id = const Value.absent(),
    this.displayName = const Value.absent(),
    this.isPrimary = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  PeopleCompanion.insert({
    this.id = const Value.absent(),
    required String displayName,
    this.isPrimary = const Value.absent(),
    required int createdAt,
  })  : displayName = Value(displayName),
        createdAt = Value(createdAt);
  static Insertable<PersonRow> custom({
    Expression<int>? id,
    Expression<String>? displayName,
    Expression<bool>? isPrimary,
    Expression<int>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (displayName != null) 'display_name': displayName,
      if (isPrimary != null) 'is_primary': isPrimary,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  PeopleCompanion copyWith(
      {Value<int>? id,
      Value<String>? displayName,
      Value<bool>? isPrimary,
      Value<int>? createdAt}) {
    return PeopleCompanion(
      id: id ?? this.id,
      displayName: displayName ?? this.displayName,
      isPrimary: isPrimary ?? this.isPrimary,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (displayName.present) {
      map['display_name'] = Variable<String>(displayName.value);
    }
    if (isPrimary.present) {
      map['is_primary'] = Variable<bool>(isPrimary.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PeopleCompanion(')
          ..write('id: $id, ')
          ..write('displayName: $displayName, ')
          ..write('isPrimary: $isPrimary, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $ProfilesTable extends Profiles
    with TableInfo<$ProfilesTable, ProfileRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ProfilesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _personIdMeta =
      const VerificationMeta('personId');
  @override
  late final GeneratedColumn<int> personId = GeneratedColumn<int>(
      'person_id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES people (id) ON DELETE CASCADE'));
  static const VerificationMeta _ageYearsMeta =
      const VerificationMeta('ageYears');
  @override
  late final GeneratedColumn<int> ageYears = GeneratedColumn<int>(
      'age_years', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  @override
  late final GeneratedColumnWithTypeConverter<Sex, String> sex =
      GeneratedColumn<String>('sex', aliasedName, false,
              type: DriftSqlType.string, requiredDuringInsert: true)
          .withConverter<Sex>($ProfilesTable.$convertersex);
  static const VerificationMeta _heightCmMeta =
      const VerificationMeta('heightCm');
  @override
  late final GeneratedColumn<double> heightCm = GeneratedColumn<double>(
      'height_cm', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _weightKgMeta =
      const VerificationMeta('weightKg');
  @override
  late final GeneratedColumn<double> weightKg = GeneratedColumn<double>(
      'weight_kg', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  @override
  late final GeneratedColumnWithTypeConverter<LifeStage, String> stage =
      GeneratedColumn<String>('stage', aliasedName, false,
              type: DriftSqlType.string, requiredDuringInsert: true)
          .withConverter<LifeStage>($ProfilesTable.$converterstage);
  static const VerificationMeta _gestationWeekMeta =
      const VerificationMeta('gestationWeek');
  @override
  late final GeneratedColumn<int> gestationWeek = GeneratedColumn<int>(
      'gestation_week', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  @override
  late final GeneratedColumnWithTypeConverter<BmiClass?, String>
      prePregnancyBmi = GeneratedColumn<String>(
              'pre_pregnancy_bmi', aliasedName, true,
              type: DriftSqlType.string, requiredDuringInsert: false)
          .withConverter<BmiClass?>($ProfilesTable.$converterprePregnancyBmin);
  static const VerificationMeta _monthsPostpartumMeta =
      const VerificationMeta('monthsPostpartum');
  @override
  late final GeneratedColumn<int> monthsPostpartum = GeneratedColumn<int>(
      'months_postpartum', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  @override
  late final GeneratedColumnWithTypeConverter<ActivityLevel, String>
      activityLevel = GeneratedColumn<String>(
              'activity_level', aliasedName, false,
              type: DriftSqlType.string, requiredDuringInsert: true)
          .withConverter<ActivityLevel>($ProfilesTable.$converteractivityLevel);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        personId,
        ageYears,
        sex,
        heightCm,
        weightKg,
        stage,
        gestationWeek,
        prePregnancyBmi,
        monthsPostpartum,
        activityLevel,
        updatedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'profiles';
  @override
  VerificationContext validateIntegrity(Insertable<ProfileRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('person_id')) {
      context.handle(_personIdMeta,
          personId.isAcceptableOrUnknown(data['person_id']!, _personIdMeta));
    }
    if (data.containsKey('age_years')) {
      context.handle(_ageYearsMeta,
          ageYears.isAcceptableOrUnknown(data['age_years']!, _ageYearsMeta));
    } else if (isInserting) {
      context.missing(_ageYearsMeta);
    }
    if (data.containsKey('height_cm')) {
      context.handle(_heightCmMeta,
          heightCm.isAcceptableOrUnknown(data['height_cm']!, _heightCmMeta));
    } else if (isInserting) {
      context.missing(_heightCmMeta);
    }
    if (data.containsKey('weight_kg')) {
      context.handle(_weightKgMeta,
          weightKg.isAcceptableOrUnknown(data['weight_kg']!, _weightKgMeta));
    } else if (isInserting) {
      context.missing(_weightKgMeta);
    }
    if (data.containsKey('gestation_week')) {
      context.handle(
          _gestationWeekMeta,
          gestationWeek.isAcceptableOrUnknown(
              data['gestation_week']!, _gestationWeekMeta));
    }
    if (data.containsKey('months_postpartum')) {
      context.handle(
          _monthsPostpartumMeta,
          monthsPostpartum.isAcceptableOrUnknown(
              data['months_postpartum']!, _monthsPostpartumMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {personId};
  @override
  ProfileRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ProfileRow(
      personId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}person_id'])!,
      ageYears: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}age_years'])!,
      sex: $ProfilesTable.$convertersex.fromSql(attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}sex'])!),
      heightCm: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}height_cm'])!,
      weightKg: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}weight_kg'])!,
      stage: $ProfilesTable.$converterstage.fromSql(attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}stage'])!),
      gestationWeek: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}gestation_week']),
      prePregnancyBmi: $ProfilesTable.$converterprePregnancyBmin.fromSql(
          attachedDatabase.typeMapping.read(DriftSqlType.string,
              data['${effectivePrefix}pre_pregnancy_bmi'])),
      monthsPostpartum: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}months_postpartum']),
      activityLevel: $ProfilesTable.$converteractivityLevel.fromSql(
          attachedDatabase.typeMapping.read(
              DriftSqlType.string, data['${effectivePrefix}activity_level'])!),
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $ProfilesTable createAlias(String alias) {
    return $ProfilesTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<Sex, String, String> $convertersex =
      const EnumNameConverter<Sex>(Sex.values);
  static JsonTypeConverter2<LifeStage, String, String> $converterstage =
      const EnumNameConverter<LifeStage>(LifeStage.values);
  static JsonTypeConverter2<BmiClass, String, String>
      $converterprePregnancyBmi =
      const EnumNameConverter<BmiClass>(BmiClass.values);
  static JsonTypeConverter2<BmiClass?, String?, String?>
      $converterprePregnancyBmin =
      JsonTypeConverter2.asNullable($converterprePregnancyBmi);
  static JsonTypeConverter2<ActivityLevel, String, String>
      $converteractivityLevel =
      const EnumNameConverter<ActivityLevel>(ActivityLevel.values);
}

class ProfileRow extends DataClass implements Insertable<ProfileRow> {
  final int personId;
  final int ageYears;
  final Sex sex;
  final double heightCm;
  final double weightKg;
  final LifeStage stage;
  final int? gestationWeek;
  final BmiClass? prePregnancyBmi;
  final int? monthsPostpartum;
  final ActivityLevel activityLevel;
  final int updatedAt;
  const ProfileRow(
      {required this.personId,
      required this.ageYears,
      required this.sex,
      required this.heightCm,
      required this.weightKg,
      required this.stage,
      this.gestationWeek,
      this.prePregnancyBmi,
      this.monthsPostpartum,
      required this.activityLevel,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['person_id'] = Variable<int>(personId);
    map['age_years'] = Variable<int>(ageYears);
    {
      map['sex'] = Variable<String>($ProfilesTable.$convertersex.toSql(sex));
    }
    map['height_cm'] = Variable<double>(heightCm);
    map['weight_kg'] = Variable<double>(weightKg);
    {
      map['stage'] =
          Variable<String>($ProfilesTable.$converterstage.toSql(stage));
    }
    if (!nullToAbsent || gestationWeek != null) {
      map['gestation_week'] = Variable<int>(gestationWeek);
    }
    if (!nullToAbsent || prePregnancyBmi != null) {
      map['pre_pregnancy_bmi'] = Variable<String>(
          $ProfilesTable.$converterprePregnancyBmin.toSql(prePregnancyBmi));
    }
    if (!nullToAbsent || monthsPostpartum != null) {
      map['months_postpartum'] = Variable<int>(monthsPostpartum);
    }
    {
      map['activity_level'] = Variable<String>(
          $ProfilesTable.$converteractivityLevel.toSql(activityLevel));
    }
    map['updated_at'] = Variable<int>(updatedAt);
    return map;
  }

  ProfilesCompanion toCompanion(bool nullToAbsent) {
    return ProfilesCompanion(
      personId: Value(personId),
      ageYears: Value(ageYears),
      sex: Value(sex),
      heightCm: Value(heightCm),
      weightKg: Value(weightKg),
      stage: Value(stage),
      gestationWeek: gestationWeek == null && nullToAbsent
          ? const Value.absent()
          : Value(gestationWeek),
      prePregnancyBmi: prePregnancyBmi == null && nullToAbsent
          ? const Value.absent()
          : Value(prePregnancyBmi),
      monthsPostpartum: monthsPostpartum == null && nullToAbsent
          ? const Value.absent()
          : Value(monthsPostpartum),
      activityLevel: Value(activityLevel),
      updatedAt: Value(updatedAt),
    );
  }

  factory ProfileRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ProfileRow(
      personId: serializer.fromJson<int>(json['personId']),
      ageYears: serializer.fromJson<int>(json['ageYears']),
      sex: $ProfilesTable.$convertersex
          .fromJson(serializer.fromJson<String>(json['sex'])),
      heightCm: serializer.fromJson<double>(json['heightCm']),
      weightKg: serializer.fromJson<double>(json['weightKg']),
      stage: $ProfilesTable.$converterstage
          .fromJson(serializer.fromJson<String>(json['stage'])),
      gestationWeek: serializer.fromJson<int?>(json['gestationWeek']),
      prePregnancyBmi: $ProfilesTable.$converterprePregnancyBmin
          .fromJson(serializer.fromJson<String?>(json['prePregnancyBmi'])),
      monthsPostpartum: serializer.fromJson<int?>(json['monthsPostpartum']),
      activityLevel: $ProfilesTable.$converteractivityLevel
          .fromJson(serializer.fromJson<String>(json['activityLevel'])),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'personId': serializer.toJson<int>(personId),
      'ageYears': serializer.toJson<int>(ageYears),
      'sex':
          serializer.toJson<String>($ProfilesTable.$convertersex.toJson(sex)),
      'heightCm': serializer.toJson<double>(heightCm),
      'weightKg': serializer.toJson<double>(weightKg),
      'stage': serializer
          .toJson<String>($ProfilesTable.$converterstage.toJson(stage)),
      'gestationWeek': serializer.toJson<int?>(gestationWeek),
      'prePregnancyBmi': serializer.toJson<String?>(
          $ProfilesTable.$converterprePregnancyBmin.toJson(prePregnancyBmi)),
      'monthsPostpartum': serializer.toJson<int?>(monthsPostpartum),
      'activityLevel': serializer.toJson<String>(
          $ProfilesTable.$converteractivityLevel.toJson(activityLevel)),
      'updatedAt': serializer.toJson<int>(updatedAt),
    };
  }

  ProfileRow copyWith(
          {int? personId,
          int? ageYears,
          Sex? sex,
          double? heightCm,
          double? weightKg,
          LifeStage? stage,
          Value<int?> gestationWeek = const Value.absent(),
          Value<BmiClass?> prePregnancyBmi = const Value.absent(),
          Value<int?> monthsPostpartum = const Value.absent(),
          ActivityLevel? activityLevel,
          int? updatedAt}) =>
      ProfileRow(
        personId: personId ?? this.personId,
        ageYears: ageYears ?? this.ageYears,
        sex: sex ?? this.sex,
        heightCm: heightCm ?? this.heightCm,
        weightKg: weightKg ?? this.weightKg,
        stage: stage ?? this.stage,
        gestationWeek:
            gestationWeek.present ? gestationWeek.value : this.gestationWeek,
        prePregnancyBmi: prePregnancyBmi.present
            ? prePregnancyBmi.value
            : this.prePregnancyBmi,
        monthsPostpartum: monthsPostpartum.present
            ? monthsPostpartum.value
            : this.monthsPostpartum,
        activityLevel: activityLevel ?? this.activityLevel,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  ProfileRow copyWithCompanion(ProfilesCompanion data) {
    return ProfileRow(
      personId: data.personId.present ? data.personId.value : this.personId,
      ageYears: data.ageYears.present ? data.ageYears.value : this.ageYears,
      sex: data.sex.present ? data.sex.value : this.sex,
      heightCm: data.heightCm.present ? data.heightCm.value : this.heightCm,
      weightKg: data.weightKg.present ? data.weightKg.value : this.weightKg,
      stage: data.stage.present ? data.stage.value : this.stage,
      gestationWeek: data.gestationWeek.present
          ? data.gestationWeek.value
          : this.gestationWeek,
      prePregnancyBmi: data.prePregnancyBmi.present
          ? data.prePregnancyBmi.value
          : this.prePregnancyBmi,
      monthsPostpartum: data.monthsPostpartum.present
          ? data.monthsPostpartum.value
          : this.monthsPostpartum,
      activityLevel: data.activityLevel.present
          ? data.activityLevel.value
          : this.activityLevel,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ProfileRow(')
          ..write('personId: $personId, ')
          ..write('ageYears: $ageYears, ')
          ..write('sex: $sex, ')
          ..write('heightCm: $heightCm, ')
          ..write('weightKg: $weightKg, ')
          ..write('stage: $stage, ')
          ..write('gestationWeek: $gestationWeek, ')
          ..write('prePregnancyBmi: $prePregnancyBmi, ')
          ..write('monthsPostpartum: $monthsPostpartum, ')
          ..write('activityLevel: $activityLevel, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      personId,
      ageYears,
      sex,
      heightCm,
      weightKg,
      stage,
      gestationWeek,
      prePregnancyBmi,
      monthsPostpartum,
      activityLevel,
      updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ProfileRow &&
          other.personId == this.personId &&
          other.ageYears == this.ageYears &&
          other.sex == this.sex &&
          other.heightCm == this.heightCm &&
          other.weightKg == this.weightKg &&
          other.stage == this.stage &&
          other.gestationWeek == this.gestationWeek &&
          other.prePregnancyBmi == this.prePregnancyBmi &&
          other.monthsPostpartum == this.monthsPostpartum &&
          other.activityLevel == this.activityLevel &&
          other.updatedAt == this.updatedAt);
}

class ProfilesCompanion extends UpdateCompanion<ProfileRow> {
  final Value<int> personId;
  final Value<int> ageYears;
  final Value<Sex> sex;
  final Value<double> heightCm;
  final Value<double> weightKg;
  final Value<LifeStage> stage;
  final Value<int?> gestationWeek;
  final Value<BmiClass?> prePregnancyBmi;
  final Value<int?> monthsPostpartum;
  final Value<ActivityLevel> activityLevel;
  final Value<int> updatedAt;
  const ProfilesCompanion({
    this.personId = const Value.absent(),
    this.ageYears = const Value.absent(),
    this.sex = const Value.absent(),
    this.heightCm = const Value.absent(),
    this.weightKg = const Value.absent(),
    this.stage = const Value.absent(),
    this.gestationWeek = const Value.absent(),
    this.prePregnancyBmi = const Value.absent(),
    this.monthsPostpartum = const Value.absent(),
    this.activityLevel = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  ProfilesCompanion.insert({
    this.personId = const Value.absent(),
    required int ageYears,
    required Sex sex,
    required double heightCm,
    required double weightKg,
    required LifeStage stage,
    this.gestationWeek = const Value.absent(),
    this.prePregnancyBmi = const Value.absent(),
    this.monthsPostpartum = const Value.absent(),
    required ActivityLevel activityLevel,
    required int updatedAt,
  })  : ageYears = Value(ageYears),
        sex = Value(sex),
        heightCm = Value(heightCm),
        weightKg = Value(weightKg),
        stage = Value(stage),
        activityLevel = Value(activityLevel),
        updatedAt = Value(updatedAt);
  static Insertable<ProfileRow> custom({
    Expression<int>? personId,
    Expression<int>? ageYears,
    Expression<String>? sex,
    Expression<double>? heightCm,
    Expression<double>? weightKg,
    Expression<String>? stage,
    Expression<int>? gestationWeek,
    Expression<String>? prePregnancyBmi,
    Expression<int>? monthsPostpartum,
    Expression<String>? activityLevel,
    Expression<int>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (personId != null) 'person_id': personId,
      if (ageYears != null) 'age_years': ageYears,
      if (sex != null) 'sex': sex,
      if (heightCm != null) 'height_cm': heightCm,
      if (weightKg != null) 'weight_kg': weightKg,
      if (stage != null) 'stage': stage,
      if (gestationWeek != null) 'gestation_week': gestationWeek,
      if (prePregnancyBmi != null) 'pre_pregnancy_bmi': prePregnancyBmi,
      if (monthsPostpartum != null) 'months_postpartum': monthsPostpartum,
      if (activityLevel != null) 'activity_level': activityLevel,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  ProfilesCompanion copyWith(
      {Value<int>? personId,
      Value<int>? ageYears,
      Value<Sex>? sex,
      Value<double>? heightCm,
      Value<double>? weightKg,
      Value<LifeStage>? stage,
      Value<int?>? gestationWeek,
      Value<BmiClass?>? prePregnancyBmi,
      Value<int?>? monthsPostpartum,
      Value<ActivityLevel>? activityLevel,
      Value<int>? updatedAt}) {
    return ProfilesCompanion(
      personId: personId ?? this.personId,
      ageYears: ageYears ?? this.ageYears,
      sex: sex ?? this.sex,
      heightCm: heightCm ?? this.heightCm,
      weightKg: weightKg ?? this.weightKg,
      stage: stage ?? this.stage,
      gestationWeek: gestationWeek ?? this.gestationWeek,
      prePregnancyBmi: prePregnancyBmi ?? this.prePregnancyBmi,
      monthsPostpartum: monthsPostpartum ?? this.monthsPostpartum,
      activityLevel: activityLevel ?? this.activityLevel,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (personId.present) {
      map['person_id'] = Variable<int>(personId.value);
    }
    if (ageYears.present) {
      map['age_years'] = Variable<int>(ageYears.value);
    }
    if (sex.present) {
      map['sex'] =
          Variable<String>($ProfilesTable.$convertersex.toSql(sex.value));
    }
    if (heightCm.present) {
      map['height_cm'] = Variable<double>(heightCm.value);
    }
    if (weightKg.present) {
      map['weight_kg'] = Variable<double>(weightKg.value);
    }
    if (stage.present) {
      map['stage'] =
          Variable<String>($ProfilesTable.$converterstage.toSql(stage.value));
    }
    if (gestationWeek.present) {
      map['gestation_week'] = Variable<int>(gestationWeek.value);
    }
    if (prePregnancyBmi.present) {
      map['pre_pregnancy_bmi'] = Variable<String>($ProfilesTable
          .$converterprePregnancyBmin
          .toSql(prePregnancyBmi.value));
    }
    if (monthsPostpartum.present) {
      map['months_postpartum'] = Variable<int>(monthsPostpartum.value);
    }
    if (activityLevel.present) {
      map['activity_level'] = Variable<String>(
          $ProfilesTable.$converteractivityLevel.toSql(activityLevel.value));
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ProfilesCompanion(')
          ..write('personId: $personId, ')
          ..write('ageYears: $ageYears, ')
          ..write('sex: $sex, ')
          ..write('heightCm: $heightCm, ')
          ..write('weightKg: $weightKg, ')
          ..write('stage: $stage, ')
          ..write('gestationWeek: $gestationWeek, ')
          ..write('prePregnancyBmi: $prePregnancyBmi, ')
          ..write('monthsPostpartum: $monthsPostpartum, ')
          ..write('activityLevel: $activityLevel, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $SettingsTable extends Settings
    with TableInfo<$SettingsTable, SettingRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SettingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
      'key', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
      'value', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [key, value];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'settings';
  @override
  VerificationContext validateIntegrity(Insertable<SettingRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
          _keyMeta, key.isAcceptableOrUnknown(data['key']!, _keyMeta));
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
          _valueMeta, value.isAcceptableOrUnknown(data['value']!, _valueMeta));
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  SettingRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SettingRow(
      key: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}key'])!,
      value: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}value'])!,
    );
  }

  @override
  $SettingsTable createAlias(String alias) {
    return $SettingsTable(attachedDatabase, alias);
  }
}

class SettingRow extends DataClass implements Insertable<SettingRow> {
  final String key;
  final String value;
  const SettingRow({required this.key, required this.value});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    return map;
  }

  SettingsCompanion toCompanion(bool nullToAbsent) {
    return SettingsCompanion(
      key: Value(key),
      value: Value(value),
    );
  }

  factory SettingRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SettingRow(
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String>(json['value']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String>(value),
    };
  }

  SettingRow copyWith({String? key, String? value}) => SettingRow(
        key: key ?? this.key,
        value: value ?? this.value,
      );
  SettingRow copyWithCompanion(SettingsCompanion data) {
    return SettingRow(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SettingRow(')
          ..write('key: $key, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, value);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SettingRow &&
          other.key == this.key &&
          other.value == this.value);
}

class SettingsCompanion extends UpdateCompanion<SettingRow> {
  final Value<String> key;
  final Value<String> value;
  final Value<int> rowid;
  const SettingsCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SettingsCompanion.insert({
    required String key,
    required String value,
    this.rowid = const Value.absent(),
  })  : key = Value(key),
        value = Value(value);
  static Insertable<SettingRow> custom({
    Expression<String>? key,
    Expression<String>? value,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SettingsCompanion copyWith(
      {Value<String>? key, Value<String>? value, Value<int>? rowid}) {
    return SettingsCompanion(
      key: key ?? this.key,
      value: value ?? this.value,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SettingsCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ProductsTable extends Products
    with TableInfo<$ProductsTable, ProductRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ProductsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _shortNameMeta =
      const VerificationMeta('shortName');
  @override
  late final GeneratedColumn<String> shortName = GeneratedColumn<String>(
      'short_name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _fullNameMeta =
      const VerificationMeta('fullName');
  @override
  late final GeneratedColumn<String> fullName = GeneratedColumn<String>(
      'full_name', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _dosageFormMeta =
      const VerificationMeta('dosageForm');
  @override
  late final GeneratedColumn<String> dosageForm = GeneratedColumn<String>(
      'dosage_form', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _unitsPerServingMeta =
      const VerificationMeta('unitsPerServing');
  @override
  late final GeneratedColumn<double> unitsPerServing = GeneratedColumn<double>(
      'units_per_serving', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _servingsPerContainerMeta =
      const VerificationMeta('servingsPerContainer');
  @override
  late final GeneratedColumn<double> servingsPerContainer =
      GeneratedColumn<double>('servings_per_container', aliasedName, true,
          type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _barcodeMeta =
      const VerificationMeta('barcode');
  @override
  late final GeneratedColumn<String> barcode = GeneratedColumn<String>(
      'barcode', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _labelPhotoPathMeta =
      const VerificationMeta('labelPhotoPath');
  @override
  late final GeneratedColumn<String> labelPhotoPath = GeneratedColumn<String>(
      'label_photo_path', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _confirmedMeta =
      const VerificationMeta('confirmed');
  @override
  late final GeneratedColumn<bool> confirmed = GeneratedColumn<bool>(
      'confirmed', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("confirmed" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
      'created_at', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        shortName,
        fullName,
        dosageForm,
        unitsPerServing,
        servingsPerContainer,
        barcode,
        labelPhotoPath,
        confirmed,
        createdAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'products';
  @override
  VerificationContext validateIntegrity(Insertable<ProductRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('short_name')) {
      context.handle(_shortNameMeta,
          shortName.isAcceptableOrUnknown(data['short_name']!, _shortNameMeta));
    } else if (isInserting) {
      context.missing(_shortNameMeta);
    }
    if (data.containsKey('full_name')) {
      context.handle(_fullNameMeta,
          fullName.isAcceptableOrUnknown(data['full_name']!, _fullNameMeta));
    }
    if (data.containsKey('dosage_form')) {
      context.handle(
          _dosageFormMeta,
          dosageForm.isAcceptableOrUnknown(
              data['dosage_form']!, _dosageFormMeta));
    } else if (isInserting) {
      context.missing(_dosageFormMeta);
    }
    if (data.containsKey('units_per_serving')) {
      context.handle(
          _unitsPerServingMeta,
          unitsPerServing.isAcceptableOrUnknown(
              data['units_per_serving']!, _unitsPerServingMeta));
    } else if (isInserting) {
      context.missing(_unitsPerServingMeta);
    }
    if (data.containsKey('servings_per_container')) {
      context.handle(
          _servingsPerContainerMeta,
          servingsPerContainer.isAcceptableOrUnknown(
              data['servings_per_container']!, _servingsPerContainerMeta));
    }
    if (data.containsKey('barcode')) {
      context.handle(_barcodeMeta,
          barcode.isAcceptableOrUnknown(data['barcode']!, _barcodeMeta));
    }
    if (data.containsKey('label_photo_path')) {
      context.handle(
          _labelPhotoPathMeta,
          labelPhotoPath.isAcceptableOrUnknown(
              data['label_photo_path']!, _labelPhotoPathMeta));
    }
    if (data.containsKey('confirmed')) {
      context.handle(_confirmedMeta,
          confirmed.isAcceptableOrUnknown(data['confirmed']!, _confirmedMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ProductRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ProductRow(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      shortName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}short_name'])!,
      fullName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}full_name']),
      dosageForm: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}dosage_form'])!,
      unitsPerServing: attachedDatabase.typeMapping.read(
          DriftSqlType.double, data['${effectivePrefix}units_per_serving'])!,
      servingsPerContainer: attachedDatabase.typeMapping.read(
          DriftSqlType.double,
          data['${effectivePrefix}servings_per_container']),
      barcode: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}barcode']),
      labelPhotoPath: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}label_photo_path']),
      confirmed: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}confirmed'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $ProductsTable createAlias(String alias) {
    return $ProductsTable(attachedDatabase, alias);
  }
}

class ProductRow extends DataClass implements Insertable<ProductRow> {
  final int id;
  final String shortName;
  final String? fullName;
  final String dosageForm;
  final double unitsPerServing;
  final double? servingsPerContainer;
  final String? barcode;
  final String? labelPhotoPath;
  final bool confirmed;
  final int createdAt;
  const ProductRow(
      {required this.id,
      required this.shortName,
      this.fullName,
      required this.dosageForm,
      required this.unitsPerServing,
      this.servingsPerContainer,
      this.barcode,
      this.labelPhotoPath,
      required this.confirmed,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['short_name'] = Variable<String>(shortName);
    if (!nullToAbsent || fullName != null) {
      map['full_name'] = Variable<String>(fullName);
    }
    map['dosage_form'] = Variable<String>(dosageForm);
    map['units_per_serving'] = Variable<double>(unitsPerServing);
    if (!nullToAbsent || servingsPerContainer != null) {
      map['servings_per_container'] = Variable<double>(servingsPerContainer);
    }
    if (!nullToAbsent || barcode != null) {
      map['barcode'] = Variable<String>(barcode);
    }
    if (!nullToAbsent || labelPhotoPath != null) {
      map['label_photo_path'] = Variable<String>(labelPhotoPath);
    }
    map['confirmed'] = Variable<bool>(confirmed);
    map['created_at'] = Variable<int>(createdAt);
    return map;
  }

  ProductsCompanion toCompanion(bool nullToAbsent) {
    return ProductsCompanion(
      id: Value(id),
      shortName: Value(shortName),
      fullName: fullName == null && nullToAbsent
          ? const Value.absent()
          : Value(fullName),
      dosageForm: Value(dosageForm),
      unitsPerServing: Value(unitsPerServing),
      servingsPerContainer: servingsPerContainer == null && nullToAbsent
          ? const Value.absent()
          : Value(servingsPerContainer),
      barcode: barcode == null && nullToAbsent
          ? const Value.absent()
          : Value(barcode),
      labelPhotoPath: labelPhotoPath == null && nullToAbsent
          ? const Value.absent()
          : Value(labelPhotoPath),
      confirmed: Value(confirmed),
      createdAt: Value(createdAt),
    );
  }

  factory ProductRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ProductRow(
      id: serializer.fromJson<int>(json['id']),
      shortName: serializer.fromJson<String>(json['shortName']),
      fullName: serializer.fromJson<String?>(json['fullName']),
      dosageForm: serializer.fromJson<String>(json['dosageForm']),
      unitsPerServing: serializer.fromJson<double>(json['unitsPerServing']),
      servingsPerContainer:
          serializer.fromJson<double?>(json['servingsPerContainer']),
      barcode: serializer.fromJson<String?>(json['barcode']),
      labelPhotoPath: serializer.fromJson<String?>(json['labelPhotoPath']),
      confirmed: serializer.fromJson<bool>(json['confirmed']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'shortName': serializer.toJson<String>(shortName),
      'fullName': serializer.toJson<String?>(fullName),
      'dosageForm': serializer.toJson<String>(dosageForm),
      'unitsPerServing': serializer.toJson<double>(unitsPerServing),
      'servingsPerContainer': serializer.toJson<double?>(servingsPerContainer),
      'barcode': serializer.toJson<String?>(barcode),
      'labelPhotoPath': serializer.toJson<String?>(labelPhotoPath),
      'confirmed': serializer.toJson<bool>(confirmed),
      'createdAt': serializer.toJson<int>(createdAt),
    };
  }

  ProductRow copyWith(
          {int? id,
          String? shortName,
          Value<String?> fullName = const Value.absent(),
          String? dosageForm,
          double? unitsPerServing,
          Value<double?> servingsPerContainer = const Value.absent(),
          Value<String?> barcode = const Value.absent(),
          Value<String?> labelPhotoPath = const Value.absent(),
          bool? confirmed,
          int? createdAt}) =>
      ProductRow(
        id: id ?? this.id,
        shortName: shortName ?? this.shortName,
        fullName: fullName.present ? fullName.value : this.fullName,
        dosageForm: dosageForm ?? this.dosageForm,
        unitsPerServing: unitsPerServing ?? this.unitsPerServing,
        servingsPerContainer: servingsPerContainer.present
            ? servingsPerContainer.value
            : this.servingsPerContainer,
        barcode: barcode.present ? barcode.value : this.barcode,
        labelPhotoPath:
            labelPhotoPath.present ? labelPhotoPath.value : this.labelPhotoPath,
        confirmed: confirmed ?? this.confirmed,
        createdAt: createdAt ?? this.createdAt,
      );
  ProductRow copyWithCompanion(ProductsCompanion data) {
    return ProductRow(
      id: data.id.present ? data.id.value : this.id,
      shortName: data.shortName.present ? data.shortName.value : this.shortName,
      fullName: data.fullName.present ? data.fullName.value : this.fullName,
      dosageForm:
          data.dosageForm.present ? data.dosageForm.value : this.dosageForm,
      unitsPerServing: data.unitsPerServing.present
          ? data.unitsPerServing.value
          : this.unitsPerServing,
      servingsPerContainer: data.servingsPerContainer.present
          ? data.servingsPerContainer.value
          : this.servingsPerContainer,
      barcode: data.barcode.present ? data.barcode.value : this.barcode,
      labelPhotoPath: data.labelPhotoPath.present
          ? data.labelPhotoPath.value
          : this.labelPhotoPath,
      confirmed: data.confirmed.present ? data.confirmed.value : this.confirmed,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ProductRow(')
          ..write('id: $id, ')
          ..write('shortName: $shortName, ')
          ..write('fullName: $fullName, ')
          ..write('dosageForm: $dosageForm, ')
          ..write('unitsPerServing: $unitsPerServing, ')
          ..write('servingsPerContainer: $servingsPerContainer, ')
          ..write('barcode: $barcode, ')
          ..write('labelPhotoPath: $labelPhotoPath, ')
          ..write('confirmed: $confirmed, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      shortName,
      fullName,
      dosageForm,
      unitsPerServing,
      servingsPerContainer,
      barcode,
      labelPhotoPath,
      confirmed,
      createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ProductRow &&
          other.id == this.id &&
          other.shortName == this.shortName &&
          other.fullName == this.fullName &&
          other.dosageForm == this.dosageForm &&
          other.unitsPerServing == this.unitsPerServing &&
          other.servingsPerContainer == this.servingsPerContainer &&
          other.barcode == this.barcode &&
          other.labelPhotoPath == this.labelPhotoPath &&
          other.confirmed == this.confirmed &&
          other.createdAt == this.createdAt);
}

class ProductsCompanion extends UpdateCompanion<ProductRow> {
  final Value<int> id;
  final Value<String> shortName;
  final Value<String?> fullName;
  final Value<String> dosageForm;
  final Value<double> unitsPerServing;
  final Value<double?> servingsPerContainer;
  final Value<String?> barcode;
  final Value<String?> labelPhotoPath;
  final Value<bool> confirmed;
  final Value<int> createdAt;
  const ProductsCompanion({
    this.id = const Value.absent(),
    this.shortName = const Value.absent(),
    this.fullName = const Value.absent(),
    this.dosageForm = const Value.absent(),
    this.unitsPerServing = const Value.absent(),
    this.servingsPerContainer = const Value.absent(),
    this.barcode = const Value.absent(),
    this.labelPhotoPath = const Value.absent(),
    this.confirmed = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  ProductsCompanion.insert({
    this.id = const Value.absent(),
    required String shortName,
    this.fullName = const Value.absent(),
    required String dosageForm,
    required double unitsPerServing,
    this.servingsPerContainer = const Value.absent(),
    this.barcode = const Value.absent(),
    this.labelPhotoPath = const Value.absent(),
    this.confirmed = const Value.absent(),
    required int createdAt,
  })  : shortName = Value(shortName),
        dosageForm = Value(dosageForm),
        unitsPerServing = Value(unitsPerServing),
        createdAt = Value(createdAt);
  static Insertable<ProductRow> custom({
    Expression<int>? id,
    Expression<String>? shortName,
    Expression<String>? fullName,
    Expression<String>? dosageForm,
    Expression<double>? unitsPerServing,
    Expression<double>? servingsPerContainer,
    Expression<String>? barcode,
    Expression<String>? labelPhotoPath,
    Expression<bool>? confirmed,
    Expression<int>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (shortName != null) 'short_name': shortName,
      if (fullName != null) 'full_name': fullName,
      if (dosageForm != null) 'dosage_form': dosageForm,
      if (unitsPerServing != null) 'units_per_serving': unitsPerServing,
      if (servingsPerContainer != null)
        'servings_per_container': servingsPerContainer,
      if (barcode != null) 'barcode': barcode,
      if (labelPhotoPath != null) 'label_photo_path': labelPhotoPath,
      if (confirmed != null) 'confirmed': confirmed,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  ProductsCompanion copyWith(
      {Value<int>? id,
      Value<String>? shortName,
      Value<String?>? fullName,
      Value<String>? dosageForm,
      Value<double>? unitsPerServing,
      Value<double?>? servingsPerContainer,
      Value<String?>? barcode,
      Value<String?>? labelPhotoPath,
      Value<bool>? confirmed,
      Value<int>? createdAt}) {
    return ProductsCompanion(
      id: id ?? this.id,
      shortName: shortName ?? this.shortName,
      fullName: fullName ?? this.fullName,
      dosageForm: dosageForm ?? this.dosageForm,
      unitsPerServing: unitsPerServing ?? this.unitsPerServing,
      servingsPerContainer: servingsPerContainer ?? this.servingsPerContainer,
      barcode: barcode ?? this.barcode,
      labelPhotoPath: labelPhotoPath ?? this.labelPhotoPath,
      confirmed: confirmed ?? this.confirmed,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (shortName.present) {
      map['short_name'] = Variable<String>(shortName.value);
    }
    if (fullName.present) {
      map['full_name'] = Variable<String>(fullName.value);
    }
    if (dosageForm.present) {
      map['dosage_form'] = Variable<String>(dosageForm.value);
    }
    if (unitsPerServing.present) {
      map['units_per_serving'] = Variable<double>(unitsPerServing.value);
    }
    if (servingsPerContainer.present) {
      map['servings_per_container'] =
          Variable<double>(servingsPerContainer.value);
    }
    if (barcode.present) {
      map['barcode'] = Variable<String>(barcode.value);
    }
    if (labelPhotoPath.present) {
      map['label_photo_path'] = Variable<String>(labelPhotoPath.value);
    }
    if (confirmed.present) {
      map['confirmed'] = Variable<bool>(confirmed.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ProductsCompanion(')
          ..write('id: $id, ')
          ..write('shortName: $shortName, ')
          ..write('fullName: $fullName, ')
          ..write('dosageForm: $dosageForm, ')
          ..write('unitsPerServing: $unitsPerServing, ')
          ..write('servingsPerContainer: $servingsPerContainer, ')
          ..write('barcode: $barcode, ')
          ..write('labelPhotoPath: $labelPhotoPath, ')
          ..write('confirmed: $confirmed, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $ProductNutrientsTable extends ProductNutrients
    with TableInfo<$ProductNutrientsTable, ProductNutrientRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ProductNutrientsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _productIdMeta =
      const VerificationMeta('productId');
  @override
  late final GeneratedColumn<int> productId = GeneratedColumn<int>(
      'product_id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES products (id) ON DELETE CASCADE'));
  static const VerificationMeta _nutrientIdMeta =
      const VerificationMeta('nutrientId');
  @override
  late final GeneratedColumn<String> nutrientId = GeneratedColumn<String>(
      'nutrient_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _chemicalFormMeta =
      const VerificationMeta('chemicalForm');
  @override
  late final GeneratedColumn<String> chemicalForm = GeneratedColumn<String>(
      'chemical_form', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _amountPerServingMeta =
      const VerificationMeta('amountPerServing');
  @override
  late final GeneratedColumn<double> amountPerServing = GeneratedColumn<double>(
      'amount_per_serving', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _unitMeta = const VerificationMeta('unit');
  @override
  late final GeneratedColumn<String> unit = GeneratedColumn<String>(
      'unit', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  @override
  late final GeneratedColumnWithTypeConverter<ProductNutrientSource, String>
      source = GeneratedColumn<String>('source', aliasedName, false,
              type: DriftSqlType.string, requiredDuringInsert: true)
          .withConverter<ProductNutrientSource>(
              $ProductNutrientsTable.$convertersource);
  @override
  List<GeneratedColumn> get $columns =>
      [productId, nutrientId, chemicalForm, amountPerServing, unit, source];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'product_nutrients';
  @override
  VerificationContext validateIntegrity(Insertable<ProductNutrientRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('product_id')) {
      context.handle(_productIdMeta,
          productId.isAcceptableOrUnknown(data['product_id']!, _productIdMeta));
    } else if (isInserting) {
      context.missing(_productIdMeta);
    }
    if (data.containsKey('nutrient_id')) {
      context.handle(
          _nutrientIdMeta,
          nutrientId.isAcceptableOrUnknown(
              data['nutrient_id']!, _nutrientIdMeta));
    } else if (isInserting) {
      context.missing(_nutrientIdMeta);
    }
    if (data.containsKey('chemical_form')) {
      context.handle(
          _chemicalFormMeta,
          chemicalForm.isAcceptableOrUnknown(
              data['chemical_form']!, _chemicalFormMeta));
    }
    if (data.containsKey('amount_per_serving')) {
      context.handle(
          _amountPerServingMeta,
          amountPerServing.isAcceptableOrUnknown(
              data['amount_per_serving']!, _amountPerServingMeta));
    } else if (isInserting) {
      context.missing(_amountPerServingMeta);
    }
    if (data.containsKey('unit')) {
      context.handle(
          _unitMeta, unit.isAcceptableOrUnknown(data['unit']!, _unitMeta));
    } else if (isInserting) {
      context.missing(_unitMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {productId, nutrientId, chemicalForm};
  @override
  ProductNutrientRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ProductNutrientRow(
      productId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}product_id'])!,
      nutrientId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}nutrient_id'])!,
      chemicalForm: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}chemical_form'])!,
      amountPerServing: attachedDatabase.typeMapping.read(
          DriftSqlType.double, data['${effectivePrefix}amount_per_serving'])!,
      unit: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}unit'])!,
      source: $ProductNutrientsTable.$convertersource.fromSql(attachedDatabase
          .typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}source'])!),
    );
  }

  @override
  $ProductNutrientsTable createAlias(String alias) {
    return $ProductNutrientsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<ProductNutrientSource, String, String>
      $convertersource = const EnumNameConverter<ProductNutrientSource>(
          ProductNutrientSource.values);
}

class ProductNutrientRow extends DataClass
    implements Insertable<ProductNutrientRow> {
  final int productId;
  final String nutrientId;

  /// Dạng chất in trên nhãn (vd. cholecalciferol, beta-carotene); '' khi không ghi.
  final String chemicalForm;
  final double amountPerServing;
  final String unit;
  final ProductNutrientSource source;
  const ProductNutrientRow(
      {required this.productId,
      required this.nutrientId,
      required this.chemicalForm,
      required this.amountPerServing,
      required this.unit,
      required this.source});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['product_id'] = Variable<int>(productId);
    map['nutrient_id'] = Variable<String>(nutrientId);
    map['chemical_form'] = Variable<String>(chemicalForm);
    map['amount_per_serving'] = Variable<double>(amountPerServing);
    map['unit'] = Variable<String>(unit);
    {
      map['source'] = Variable<String>(
          $ProductNutrientsTable.$convertersource.toSql(source));
    }
    return map;
  }

  ProductNutrientsCompanion toCompanion(bool nullToAbsent) {
    return ProductNutrientsCompanion(
      productId: Value(productId),
      nutrientId: Value(nutrientId),
      chemicalForm: Value(chemicalForm),
      amountPerServing: Value(amountPerServing),
      unit: Value(unit),
      source: Value(source),
    );
  }

  factory ProductNutrientRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ProductNutrientRow(
      productId: serializer.fromJson<int>(json['productId']),
      nutrientId: serializer.fromJson<String>(json['nutrientId']),
      chemicalForm: serializer.fromJson<String>(json['chemicalForm']),
      amountPerServing: serializer.fromJson<double>(json['amountPerServing']),
      unit: serializer.fromJson<String>(json['unit']),
      source: $ProductNutrientsTable.$convertersource
          .fromJson(serializer.fromJson<String>(json['source'])),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'productId': serializer.toJson<int>(productId),
      'nutrientId': serializer.toJson<String>(nutrientId),
      'chemicalForm': serializer.toJson<String>(chemicalForm),
      'amountPerServing': serializer.toJson<double>(amountPerServing),
      'unit': serializer.toJson<String>(unit),
      'source': serializer.toJson<String>(
          $ProductNutrientsTable.$convertersource.toJson(source)),
    };
  }

  ProductNutrientRow copyWith(
          {int? productId,
          String? nutrientId,
          String? chemicalForm,
          double? amountPerServing,
          String? unit,
          ProductNutrientSource? source}) =>
      ProductNutrientRow(
        productId: productId ?? this.productId,
        nutrientId: nutrientId ?? this.nutrientId,
        chemicalForm: chemicalForm ?? this.chemicalForm,
        amountPerServing: amountPerServing ?? this.amountPerServing,
        unit: unit ?? this.unit,
        source: source ?? this.source,
      );
  ProductNutrientRow copyWithCompanion(ProductNutrientsCompanion data) {
    return ProductNutrientRow(
      productId: data.productId.present ? data.productId.value : this.productId,
      nutrientId:
          data.nutrientId.present ? data.nutrientId.value : this.nutrientId,
      chemicalForm: data.chemicalForm.present
          ? data.chemicalForm.value
          : this.chemicalForm,
      amountPerServing: data.amountPerServing.present
          ? data.amountPerServing.value
          : this.amountPerServing,
      unit: data.unit.present ? data.unit.value : this.unit,
      source: data.source.present ? data.source.value : this.source,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ProductNutrientRow(')
          ..write('productId: $productId, ')
          ..write('nutrientId: $nutrientId, ')
          ..write('chemicalForm: $chemicalForm, ')
          ..write('amountPerServing: $amountPerServing, ')
          ..write('unit: $unit, ')
          ..write('source: $source')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      productId, nutrientId, chemicalForm, amountPerServing, unit, source);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ProductNutrientRow &&
          other.productId == this.productId &&
          other.nutrientId == this.nutrientId &&
          other.chemicalForm == this.chemicalForm &&
          other.amountPerServing == this.amountPerServing &&
          other.unit == this.unit &&
          other.source == this.source);
}

class ProductNutrientsCompanion extends UpdateCompanion<ProductNutrientRow> {
  final Value<int> productId;
  final Value<String> nutrientId;
  final Value<String> chemicalForm;
  final Value<double> amountPerServing;
  final Value<String> unit;
  final Value<ProductNutrientSource> source;
  final Value<int> rowid;
  const ProductNutrientsCompanion({
    this.productId = const Value.absent(),
    this.nutrientId = const Value.absent(),
    this.chemicalForm = const Value.absent(),
    this.amountPerServing = const Value.absent(),
    this.unit = const Value.absent(),
    this.source = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ProductNutrientsCompanion.insert({
    required int productId,
    required String nutrientId,
    this.chemicalForm = const Value.absent(),
    required double amountPerServing,
    required String unit,
    required ProductNutrientSource source,
    this.rowid = const Value.absent(),
  })  : productId = Value(productId),
        nutrientId = Value(nutrientId),
        amountPerServing = Value(amountPerServing),
        unit = Value(unit),
        source = Value(source);
  static Insertable<ProductNutrientRow> custom({
    Expression<int>? productId,
    Expression<String>? nutrientId,
    Expression<String>? chemicalForm,
    Expression<double>? amountPerServing,
    Expression<String>? unit,
    Expression<String>? source,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (productId != null) 'product_id': productId,
      if (nutrientId != null) 'nutrient_id': nutrientId,
      if (chemicalForm != null) 'chemical_form': chemicalForm,
      if (amountPerServing != null) 'amount_per_serving': amountPerServing,
      if (unit != null) 'unit': unit,
      if (source != null) 'source': source,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ProductNutrientsCompanion copyWith(
      {Value<int>? productId,
      Value<String>? nutrientId,
      Value<String>? chemicalForm,
      Value<double>? amountPerServing,
      Value<String>? unit,
      Value<ProductNutrientSource>? source,
      Value<int>? rowid}) {
    return ProductNutrientsCompanion(
      productId: productId ?? this.productId,
      nutrientId: nutrientId ?? this.nutrientId,
      chemicalForm: chemicalForm ?? this.chemicalForm,
      amountPerServing: amountPerServing ?? this.amountPerServing,
      unit: unit ?? this.unit,
      source: source ?? this.source,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (productId.present) {
      map['product_id'] = Variable<int>(productId.value);
    }
    if (nutrientId.present) {
      map['nutrient_id'] = Variable<String>(nutrientId.value);
    }
    if (chemicalForm.present) {
      map['chemical_form'] = Variable<String>(chemicalForm.value);
    }
    if (amountPerServing.present) {
      map['amount_per_serving'] = Variable<double>(amountPerServing.value);
    }
    if (unit.present) {
      map['unit'] = Variable<String>(unit.value);
    }
    if (source.present) {
      map['source'] = Variable<String>(
          $ProductNutrientsTable.$convertersource.toSql(source.value));
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ProductNutrientsCompanion(')
          ..write('productId: $productId, ')
          ..write('nutrientId: $nutrientId, ')
          ..write('chemicalForm: $chemicalForm, ')
          ..write('amountPerServing: $amountPerServing, ')
          ..write('unit: $unit, ')
          ..write('source: $source, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $InventoryBoxesTable extends InventoryBoxes
    with TableInfo<$InventoryBoxesTable, InventoryBoxRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $InventoryBoxesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _productIdMeta =
      const VerificationMeta('productId');
  @override
  late final GeneratedColumn<int> productId = GeneratedColumn<int>(
      'product_id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES products (id)'));
  static const VerificationMeta _unitsRemainingMeta =
      const VerificationMeta('unitsRemaining');
  @override
  late final GeneratedColumn<double> unitsRemaining = GeneratedColumn<double>(
      'units_remaining', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _openedOnMeta =
      const VerificationMeta('openedOn');
  @override
  late final GeneratedColumn<String> openedOn = GeneratedColumn<String>(
      'opened_on', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _expiresOnMeta =
      const VerificationMeta('expiresOn');
  @override
  late final GeneratedColumn<String> expiresOn = GeneratedColumn<String>(
      'expires_on', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _discardedMeta =
      const VerificationMeta('discarded');
  @override
  late final GeneratedColumn<bool> discarded = GeneratedColumn<bool>(
      'discarded', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("discarded" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
      'created_at', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        productId,
        unitsRemaining,
        openedOn,
        expiresOn,
        discarded,
        createdAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'inventory_boxes';
  @override
  VerificationContext validateIntegrity(Insertable<InventoryBoxRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('product_id')) {
      context.handle(_productIdMeta,
          productId.isAcceptableOrUnknown(data['product_id']!, _productIdMeta));
    } else if (isInserting) {
      context.missing(_productIdMeta);
    }
    if (data.containsKey('units_remaining')) {
      context.handle(
          _unitsRemainingMeta,
          unitsRemaining.isAcceptableOrUnknown(
              data['units_remaining']!, _unitsRemainingMeta));
    } else if (isInserting) {
      context.missing(_unitsRemainingMeta);
    }
    if (data.containsKey('opened_on')) {
      context.handle(_openedOnMeta,
          openedOn.isAcceptableOrUnknown(data['opened_on']!, _openedOnMeta));
    }
    if (data.containsKey('expires_on')) {
      context.handle(_expiresOnMeta,
          expiresOn.isAcceptableOrUnknown(data['expires_on']!, _expiresOnMeta));
    }
    if (data.containsKey('discarded')) {
      context.handle(_discardedMeta,
          discarded.isAcceptableOrUnknown(data['discarded']!, _discardedMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  InventoryBoxRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return InventoryBoxRow(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      productId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}product_id'])!,
      unitsRemaining: attachedDatabase.typeMapping.read(
          DriftSqlType.double, data['${effectivePrefix}units_remaining'])!,
      openedOn: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}opened_on']),
      expiresOn: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}expires_on']),
      discarded: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}discarded'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $InventoryBoxesTable createAlias(String alias) {
    return $InventoryBoxesTable(attachedDatabase, alias);
  }
}

class InventoryBoxRow extends DataClass implements Insertable<InventoryBoxRow> {
  final int id;
  final int productId;
  final double unitsRemaining;
  final String? openedOn;
  final String? expiresOn;
  final bool discarded;
  final int createdAt;
  const InventoryBoxRow(
      {required this.id,
      required this.productId,
      required this.unitsRemaining,
      this.openedOn,
      this.expiresOn,
      required this.discarded,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['product_id'] = Variable<int>(productId);
    map['units_remaining'] = Variable<double>(unitsRemaining);
    if (!nullToAbsent || openedOn != null) {
      map['opened_on'] = Variable<String>(openedOn);
    }
    if (!nullToAbsent || expiresOn != null) {
      map['expires_on'] = Variable<String>(expiresOn);
    }
    map['discarded'] = Variable<bool>(discarded);
    map['created_at'] = Variable<int>(createdAt);
    return map;
  }

  InventoryBoxesCompanion toCompanion(bool nullToAbsent) {
    return InventoryBoxesCompanion(
      id: Value(id),
      productId: Value(productId),
      unitsRemaining: Value(unitsRemaining),
      openedOn: openedOn == null && nullToAbsent
          ? const Value.absent()
          : Value(openedOn),
      expiresOn: expiresOn == null && nullToAbsent
          ? const Value.absent()
          : Value(expiresOn),
      discarded: Value(discarded),
      createdAt: Value(createdAt),
    );
  }

  factory InventoryBoxRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return InventoryBoxRow(
      id: serializer.fromJson<int>(json['id']),
      productId: serializer.fromJson<int>(json['productId']),
      unitsRemaining: serializer.fromJson<double>(json['unitsRemaining']),
      openedOn: serializer.fromJson<String?>(json['openedOn']),
      expiresOn: serializer.fromJson<String?>(json['expiresOn']),
      discarded: serializer.fromJson<bool>(json['discarded']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'productId': serializer.toJson<int>(productId),
      'unitsRemaining': serializer.toJson<double>(unitsRemaining),
      'openedOn': serializer.toJson<String?>(openedOn),
      'expiresOn': serializer.toJson<String?>(expiresOn),
      'discarded': serializer.toJson<bool>(discarded),
      'createdAt': serializer.toJson<int>(createdAt),
    };
  }

  InventoryBoxRow copyWith(
          {int? id,
          int? productId,
          double? unitsRemaining,
          Value<String?> openedOn = const Value.absent(),
          Value<String?> expiresOn = const Value.absent(),
          bool? discarded,
          int? createdAt}) =>
      InventoryBoxRow(
        id: id ?? this.id,
        productId: productId ?? this.productId,
        unitsRemaining: unitsRemaining ?? this.unitsRemaining,
        openedOn: openedOn.present ? openedOn.value : this.openedOn,
        expiresOn: expiresOn.present ? expiresOn.value : this.expiresOn,
        discarded: discarded ?? this.discarded,
        createdAt: createdAt ?? this.createdAt,
      );
  InventoryBoxRow copyWithCompanion(InventoryBoxesCompanion data) {
    return InventoryBoxRow(
      id: data.id.present ? data.id.value : this.id,
      productId: data.productId.present ? data.productId.value : this.productId,
      unitsRemaining: data.unitsRemaining.present
          ? data.unitsRemaining.value
          : this.unitsRemaining,
      openedOn: data.openedOn.present ? data.openedOn.value : this.openedOn,
      expiresOn: data.expiresOn.present ? data.expiresOn.value : this.expiresOn,
      discarded: data.discarded.present ? data.discarded.value : this.discarded,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('InventoryBoxRow(')
          ..write('id: $id, ')
          ..write('productId: $productId, ')
          ..write('unitsRemaining: $unitsRemaining, ')
          ..write('openedOn: $openedOn, ')
          ..write('expiresOn: $expiresOn, ')
          ..write('discarded: $discarded, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id, productId, unitsRemaining, openedOn, expiresOn, discarded, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is InventoryBoxRow &&
          other.id == this.id &&
          other.productId == this.productId &&
          other.unitsRemaining == this.unitsRemaining &&
          other.openedOn == this.openedOn &&
          other.expiresOn == this.expiresOn &&
          other.discarded == this.discarded &&
          other.createdAt == this.createdAt);
}

class InventoryBoxesCompanion extends UpdateCompanion<InventoryBoxRow> {
  final Value<int> id;
  final Value<int> productId;
  final Value<double> unitsRemaining;
  final Value<String?> openedOn;
  final Value<String?> expiresOn;
  final Value<bool> discarded;
  final Value<int> createdAt;
  const InventoryBoxesCompanion({
    this.id = const Value.absent(),
    this.productId = const Value.absent(),
    this.unitsRemaining = const Value.absent(),
    this.openedOn = const Value.absent(),
    this.expiresOn = const Value.absent(),
    this.discarded = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  InventoryBoxesCompanion.insert({
    this.id = const Value.absent(),
    required int productId,
    required double unitsRemaining,
    this.openedOn = const Value.absent(),
    this.expiresOn = const Value.absent(),
    this.discarded = const Value.absent(),
    required int createdAt,
  })  : productId = Value(productId),
        unitsRemaining = Value(unitsRemaining),
        createdAt = Value(createdAt);
  static Insertable<InventoryBoxRow> custom({
    Expression<int>? id,
    Expression<int>? productId,
    Expression<double>? unitsRemaining,
    Expression<String>? openedOn,
    Expression<String>? expiresOn,
    Expression<bool>? discarded,
    Expression<int>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (productId != null) 'product_id': productId,
      if (unitsRemaining != null) 'units_remaining': unitsRemaining,
      if (openedOn != null) 'opened_on': openedOn,
      if (expiresOn != null) 'expires_on': expiresOn,
      if (discarded != null) 'discarded': discarded,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  InventoryBoxesCompanion copyWith(
      {Value<int>? id,
      Value<int>? productId,
      Value<double>? unitsRemaining,
      Value<String?>? openedOn,
      Value<String?>? expiresOn,
      Value<bool>? discarded,
      Value<int>? createdAt}) {
    return InventoryBoxesCompanion(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      unitsRemaining: unitsRemaining ?? this.unitsRemaining,
      openedOn: openedOn ?? this.openedOn,
      expiresOn: expiresOn ?? this.expiresOn,
      discarded: discarded ?? this.discarded,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (productId.present) {
      map['product_id'] = Variable<int>(productId.value);
    }
    if (unitsRemaining.present) {
      map['units_remaining'] = Variable<double>(unitsRemaining.value);
    }
    if (openedOn.present) {
      map['opened_on'] = Variable<String>(openedOn.value);
    }
    if (expiresOn.present) {
      map['expires_on'] = Variable<String>(expiresOn.value);
    }
    if (discarded.present) {
      map['discarded'] = Variable<bool>(discarded.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('InventoryBoxesCompanion(')
          ..write('id: $id, ')
          ..write('productId: $productId, ')
          ..write('unitsRemaining: $unitsRemaining, ')
          ..write('openedOn: $openedOn, ')
          ..write('expiresOn: $expiresOn, ')
          ..write('discarded: $discarded, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $RegimensTable extends Regimens
    with TableInfo<$RegimensTable, RegimenRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RegimensTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _personIdMeta =
      const VerificationMeta('personId');
  @override
  late final GeneratedColumn<int> personId = GeneratedColumn<int>(
      'person_id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES people (id) ON DELETE CASCADE'));
  @override
  late final GeneratedColumnWithTypeConverter<RegimenKind, String> kind =
      GeneratedColumn<String>('kind', aliasedName, false,
              type: DriftSqlType.string, requiredDuringInsert: true)
          .withConverter<RegimenKind>($RegimensTable.$converterkind);
  static const VerificationMeta _productIdMeta =
      const VerificationMeta('productId');
  @override
  late final GeneratedColumn<int> productId = GeneratedColumn<int>(
      'product_id', aliasedName, true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES products (id)'));
  static const VerificationMeta _unitsPerDoseMeta =
      const VerificationMeta('unitsPerDose');
  @override
  late final GeneratedColumn<double> unitsPerDose = GeneratedColumn<double>(
      'units_per_dose', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _waterMlMeta =
      const VerificationMeta('waterMl');
  @override
  late final GeneratedColumn<double> waterMl = GeneratedColumn<double>(
      'water_ml', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _minuteOfDayMeta =
      const VerificationMeta('minuteOfDay');
  @override
  late final GeneratedColumn<int> minuteOfDay = GeneratedColumn<int>(
      'minute_of_day', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _withMealMeta =
      const VerificationMeta('withMeal');
  @override
  late final GeneratedColumn<bool> withMeal = GeneratedColumn<bool>(
      'with_meal', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("with_meal" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _weekdaysMeta =
      const VerificationMeta('weekdays');
  @override
  late final GeneratedColumn<int> weekdays = GeneratedColumn<int>(
      'weekdays', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(127));
  static const VerificationMeta _remindRepeatMeta =
      const VerificationMeta('remindRepeat');
  @override
  late final GeneratedColumn<int> remindRepeat = GeneratedColumn<int>(
      'remind_repeat', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _remindIntervalMinMeta =
      const VerificationMeta('remindIntervalMin');
  @override
  late final GeneratedColumn<int> remindIntervalMin = GeneratedColumn<int>(
      'remind_interval_min', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _activeMeta = const VerificationMeta('active');
  @override
  late final GeneratedColumn<bool> active = GeneratedColumn<bool>(
      'active', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("active" IN (0, 1))'),
      defaultValue: const Constant(true));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
      'created_at', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        personId,
        kind,
        productId,
        unitsPerDose,
        waterMl,
        minuteOfDay,
        withMeal,
        weekdays,
        remindRepeat,
        remindIntervalMin,
        active,
        createdAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'regimens';
  @override
  VerificationContext validateIntegrity(Insertable<RegimenRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('person_id')) {
      context.handle(_personIdMeta,
          personId.isAcceptableOrUnknown(data['person_id']!, _personIdMeta));
    } else if (isInserting) {
      context.missing(_personIdMeta);
    }
    if (data.containsKey('product_id')) {
      context.handle(_productIdMeta,
          productId.isAcceptableOrUnknown(data['product_id']!, _productIdMeta));
    }
    if (data.containsKey('units_per_dose')) {
      context.handle(
          _unitsPerDoseMeta,
          unitsPerDose.isAcceptableOrUnknown(
              data['units_per_dose']!, _unitsPerDoseMeta));
    }
    if (data.containsKey('water_ml')) {
      context.handle(_waterMlMeta,
          waterMl.isAcceptableOrUnknown(data['water_ml']!, _waterMlMeta));
    }
    if (data.containsKey('minute_of_day')) {
      context.handle(
          _minuteOfDayMeta,
          minuteOfDay.isAcceptableOrUnknown(
              data['minute_of_day']!, _minuteOfDayMeta));
    } else if (isInserting) {
      context.missing(_minuteOfDayMeta);
    }
    if (data.containsKey('with_meal')) {
      context.handle(_withMealMeta,
          withMeal.isAcceptableOrUnknown(data['with_meal']!, _withMealMeta));
    }
    if (data.containsKey('weekdays')) {
      context.handle(_weekdaysMeta,
          weekdays.isAcceptableOrUnknown(data['weekdays']!, _weekdaysMeta));
    }
    if (data.containsKey('remind_repeat')) {
      context.handle(
          _remindRepeatMeta,
          remindRepeat.isAcceptableOrUnknown(
              data['remind_repeat']!, _remindRepeatMeta));
    }
    if (data.containsKey('remind_interval_min')) {
      context.handle(
          _remindIntervalMinMeta,
          remindIntervalMin.isAcceptableOrUnknown(
              data['remind_interval_min']!, _remindIntervalMinMeta));
    }
    if (data.containsKey('active')) {
      context.handle(_activeMeta,
          active.isAcceptableOrUnknown(data['active']!, _activeMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  RegimenRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RegimenRow(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      personId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}person_id'])!,
      kind: $RegimensTable.$converterkind.fromSql(attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}kind'])!),
      productId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}product_id']),
      unitsPerDose: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}units_per_dose']),
      waterMl: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}water_ml']),
      minuteOfDay: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}minute_of_day'])!,
      withMeal: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}with_meal'])!,
      weekdays: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}weekdays'])!,
      remindRepeat: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}remind_repeat'])!,
      remindIntervalMin: attachedDatabase.typeMapping.read(
          DriftSqlType.int, data['${effectivePrefix}remind_interval_min'])!,
      active: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}active'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $RegimensTable createAlias(String alias) {
    return $RegimensTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<RegimenKind, String, String> $converterkind =
      const EnumNameConverter<RegimenKind>(RegimenKind.values);
}

class RegimenRow extends DataClass implements Insertable<RegimenRow> {
  final int id;
  final int personId;
  final RegimenKind kind;
  final int? productId;
  final double? unitsPerDose;
  final double? waterMl;
  final int minuteOfDay;
  final bool withMeal;

  /// Bit 0 = thứ Hai … bit 6 = Chủ nhật; 127 = mọi ngày.
  final int weekdays;
  final int remindRepeat;
  final int remindIntervalMin;
  final bool active;
  final int createdAt;
  const RegimenRow(
      {required this.id,
      required this.personId,
      required this.kind,
      this.productId,
      this.unitsPerDose,
      this.waterMl,
      required this.minuteOfDay,
      required this.withMeal,
      required this.weekdays,
      required this.remindRepeat,
      required this.remindIntervalMin,
      required this.active,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['person_id'] = Variable<int>(personId);
    {
      map['kind'] = Variable<String>($RegimensTable.$converterkind.toSql(kind));
    }
    if (!nullToAbsent || productId != null) {
      map['product_id'] = Variable<int>(productId);
    }
    if (!nullToAbsent || unitsPerDose != null) {
      map['units_per_dose'] = Variable<double>(unitsPerDose);
    }
    if (!nullToAbsent || waterMl != null) {
      map['water_ml'] = Variable<double>(waterMl);
    }
    map['minute_of_day'] = Variable<int>(minuteOfDay);
    map['with_meal'] = Variable<bool>(withMeal);
    map['weekdays'] = Variable<int>(weekdays);
    map['remind_repeat'] = Variable<int>(remindRepeat);
    map['remind_interval_min'] = Variable<int>(remindIntervalMin);
    map['active'] = Variable<bool>(active);
    map['created_at'] = Variable<int>(createdAt);
    return map;
  }

  RegimensCompanion toCompanion(bool nullToAbsent) {
    return RegimensCompanion(
      id: Value(id),
      personId: Value(personId),
      kind: Value(kind),
      productId: productId == null && nullToAbsent
          ? const Value.absent()
          : Value(productId),
      unitsPerDose: unitsPerDose == null && nullToAbsent
          ? const Value.absent()
          : Value(unitsPerDose),
      waterMl: waterMl == null && nullToAbsent
          ? const Value.absent()
          : Value(waterMl),
      minuteOfDay: Value(minuteOfDay),
      withMeal: Value(withMeal),
      weekdays: Value(weekdays),
      remindRepeat: Value(remindRepeat),
      remindIntervalMin: Value(remindIntervalMin),
      active: Value(active),
      createdAt: Value(createdAt),
    );
  }

  factory RegimenRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RegimenRow(
      id: serializer.fromJson<int>(json['id']),
      personId: serializer.fromJson<int>(json['personId']),
      kind: $RegimensTable.$converterkind
          .fromJson(serializer.fromJson<String>(json['kind'])),
      productId: serializer.fromJson<int?>(json['productId']),
      unitsPerDose: serializer.fromJson<double?>(json['unitsPerDose']),
      waterMl: serializer.fromJson<double?>(json['waterMl']),
      minuteOfDay: serializer.fromJson<int>(json['minuteOfDay']),
      withMeal: serializer.fromJson<bool>(json['withMeal']),
      weekdays: serializer.fromJson<int>(json['weekdays']),
      remindRepeat: serializer.fromJson<int>(json['remindRepeat']),
      remindIntervalMin: serializer.fromJson<int>(json['remindIntervalMin']),
      active: serializer.fromJson<bool>(json['active']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'personId': serializer.toJson<int>(personId),
      'kind':
          serializer.toJson<String>($RegimensTable.$converterkind.toJson(kind)),
      'productId': serializer.toJson<int?>(productId),
      'unitsPerDose': serializer.toJson<double?>(unitsPerDose),
      'waterMl': serializer.toJson<double?>(waterMl),
      'minuteOfDay': serializer.toJson<int>(minuteOfDay),
      'withMeal': serializer.toJson<bool>(withMeal),
      'weekdays': serializer.toJson<int>(weekdays),
      'remindRepeat': serializer.toJson<int>(remindRepeat),
      'remindIntervalMin': serializer.toJson<int>(remindIntervalMin),
      'active': serializer.toJson<bool>(active),
      'createdAt': serializer.toJson<int>(createdAt),
    };
  }

  RegimenRow copyWith(
          {int? id,
          int? personId,
          RegimenKind? kind,
          Value<int?> productId = const Value.absent(),
          Value<double?> unitsPerDose = const Value.absent(),
          Value<double?> waterMl = const Value.absent(),
          int? minuteOfDay,
          bool? withMeal,
          int? weekdays,
          int? remindRepeat,
          int? remindIntervalMin,
          bool? active,
          int? createdAt}) =>
      RegimenRow(
        id: id ?? this.id,
        personId: personId ?? this.personId,
        kind: kind ?? this.kind,
        productId: productId.present ? productId.value : this.productId,
        unitsPerDose:
            unitsPerDose.present ? unitsPerDose.value : this.unitsPerDose,
        waterMl: waterMl.present ? waterMl.value : this.waterMl,
        minuteOfDay: minuteOfDay ?? this.minuteOfDay,
        withMeal: withMeal ?? this.withMeal,
        weekdays: weekdays ?? this.weekdays,
        remindRepeat: remindRepeat ?? this.remindRepeat,
        remindIntervalMin: remindIntervalMin ?? this.remindIntervalMin,
        active: active ?? this.active,
        createdAt: createdAt ?? this.createdAt,
      );
  RegimenRow copyWithCompanion(RegimensCompanion data) {
    return RegimenRow(
      id: data.id.present ? data.id.value : this.id,
      personId: data.personId.present ? data.personId.value : this.personId,
      kind: data.kind.present ? data.kind.value : this.kind,
      productId: data.productId.present ? data.productId.value : this.productId,
      unitsPerDose: data.unitsPerDose.present
          ? data.unitsPerDose.value
          : this.unitsPerDose,
      waterMl: data.waterMl.present ? data.waterMl.value : this.waterMl,
      minuteOfDay:
          data.minuteOfDay.present ? data.minuteOfDay.value : this.minuteOfDay,
      withMeal: data.withMeal.present ? data.withMeal.value : this.withMeal,
      weekdays: data.weekdays.present ? data.weekdays.value : this.weekdays,
      remindRepeat: data.remindRepeat.present
          ? data.remindRepeat.value
          : this.remindRepeat,
      remindIntervalMin: data.remindIntervalMin.present
          ? data.remindIntervalMin.value
          : this.remindIntervalMin,
      active: data.active.present ? data.active.value : this.active,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RegimenRow(')
          ..write('id: $id, ')
          ..write('personId: $personId, ')
          ..write('kind: $kind, ')
          ..write('productId: $productId, ')
          ..write('unitsPerDose: $unitsPerDose, ')
          ..write('waterMl: $waterMl, ')
          ..write('minuteOfDay: $minuteOfDay, ')
          ..write('withMeal: $withMeal, ')
          ..write('weekdays: $weekdays, ')
          ..write('remindRepeat: $remindRepeat, ')
          ..write('remindIntervalMin: $remindIntervalMin, ')
          ..write('active: $active, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      personId,
      kind,
      productId,
      unitsPerDose,
      waterMl,
      minuteOfDay,
      withMeal,
      weekdays,
      remindRepeat,
      remindIntervalMin,
      active,
      createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RegimenRow &&
          other.id == this.id &&
          other.personId == this.personId &&
          other.kind == this.kind &&
          other.productId == this.productId &&
          other.unitsPerDose == this.unitsPerDose &&
          other.waterMl == this.waterMl &&
          other.minuteOfDay == this.minuteOfDay &&
          other.withMeal == this.withMeal &&
          other.weekdays == this.weekdays &&
          other.remindRepeat == this.remindRepeat &&
          other.remindIntervalMin == this.remindIntervalMin &&
          other.active == this.active &&
          other.createdAt == this.createdAt);
}

class RegimensCompanion extends UpdateCompanion<RegimenRow> {
  final Value<int> id;
  final Value<int> personId;
  final Value<RegimenKind> kind;
  final Value<int?> productId;
  final Value<double?> unitsPerDose;
  final Value<double?> waterMl;
  final Value<int> minuteOfDay;
  final Value<bool> withMeal;
  final Value<int> weekdays;
  final Value<int> remindRepeat;
  final Value<int> remindIntervalMin;
  final Value<bool> active;
  final Value<int> createdAt;
  const RegimensCompanion({
    this.id = const Value.absent(),
    this.personId = const Value.absent(),
    this.kind = const Value.absent(),
    this.productId = const Value.absent(),
    this.unitsPerDose = const Value.absent(),
    this.waterMl = const Value.absent(),
    this.minuteOfDay = const Value.absent(),
    this.withMeal = const Value.absent(),
    this.weekdays = const Value.absent(),
    this.remindRepeat = const Value.absent(),
    this.remindIntervalMin = const Value.absent(),
    this.active = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  RegimensCompanion.insert({
    this.id = const Value.absent(),
    required int personId,
    required RegimenKind kind,
    this.productId = const Value.absent(),
    this.unitsPerDose = const Value.absent(),
    this.waterMl = const Value.absent(),
    required int minuteOfDay,
    this.withMeal = const Value.absent(),
    this.weekdays = const Value.absent(),
    this.remindRepeat = const Value.absent(),
    this.remindIntervalMin = const Value.absent(),
    this.active = const Value.absent(),
    required int createdAt,
  })  : personId = Value(personId),
        kind = Value(kind),
        minuteOfDay = Value(minuteOfDay),
        createdAt = Value(createdAt);
  static Insertable<RegimenRow> custom({
    Expression<int>? id,
    Expression<int>? personId,
    Expression<String>? kind,
    Expression<int>? productId,
    Expression<double>? unitsPerDose,
    Expression<double>? waterMl,
    Expression<int>? minuteOfDay,
    Expression<bool>? withMeal,
    Expression<int>? weekdays,
    Expression<int>? remindRepeat,
    Expression<int>? remindIntervalMin,
    Expression<bool>? active,
    Expression<int>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (personId != null) 'person_id': personId,
      if (kind != null) 'kind': kind,
      if (productId != null) 'product_id': productId,
      if (unitsPerDose != null) 'units_per_dose': unitsPerDose,
      if (waterMl != null) 'water_ml': waterMl,
      if (minuteOfDay != null) 'minute_of_day': minuteOfDay,
      if (withMeal != null) 'with_meal': withMeal,
      if (weekdays != null) 'weekdays': weekdays,
      if (remindRepeat != null) 'remind_repeat': remindRepeat,
      if (remindIntervalMin != null) 'remind_interval_min': remindIntervalMin,
      if (active != null) 'active': active,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  RegimensCompanion copyWith(
      {Value<int>? id,
      Value<int>? personId,
      Value<RegimenKind>? kind,
      Value<int?>? productId,
      Value<double?>? unitsPerDose,
      Value<double?>? waterMl,
      Value<int>? minuteOfDay,
      Value<bool>? withMeal,
      Value<int>? weekdays,
      Value<int>? remindRepeat,
      Value<int>? remindIntervalMin,
      Value<bool>? active,
      Value<int>? createdAt}) {
    return RegimensCompanion(
      id: id ?? this.id,
      personId: personId ?? this.personId,
      kind: kind ?? this.kind,
      productId: productId ?? this.productId,
      unitsPerDose: unitsPerDose ?? this.unitsPerDose,
      waterMl: waterMl ?? this.waterMl,
      minuteOfDay: minuteOfDay ?? this.minuteOfDay,
      withMeal: withMeal ?? this.withMeal,
      weekdays: weekdays ?? this.weekdays,
      remindRepeat: remindRepeat ?? this.remindRepeat,
      remindIntervalMin: remindIntervalMin ?? this.remindIntervalMin,
      active: active ?? this.active,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (personId.present) {
      map['person_id'] = Variable<int>(personId.value);
    }
    if (kind.present) {
      map['kind'] =
          Variable<String>($RegimensTable.$converterkind.toSql(kind.value));
    }
    if (productId.present) {
      map['product_id'] = Variable<int>(productId.value);
    }
    if (unitsPerDose.present) {
      map['units_per_dose'] = Variable<double>(unitsPerDose.value);
    }
    if (waterMl.present) {
      map['water_ml'] = Variable<double>(waterMl.value);
    }
    if (minuteOfDay.present) {
      map['minute_of_day'] = Variable<int>(minuteOfDay.value);
    }
    if (withMeal.present) {
      map['with_meal'] = Variable<bool>(withMeal.value);
    }
    if (weekdays.present) {
      map['weekdays'] = Variable<int>(weekdays.value);
    }
    if (remindRepeat.present) {
      map['remind_repeat'] = Variable<int>(remindRepeat.value);
    }
    if (remindIntervalMin.present) {
      map['remind_interval_min'] = Variable<int>(remindIntervalMin.value);
    }
    if (active.present) {
      map['active'] = Variable<bool>(active.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RegimensCompanion(')
          ..write('id: $id, ')
          ..write('personId: $personId, ')
          ..write('kind: $kind, ')
          ..write('productId: $productId, ')
          ..write('unitsPerDose: $unitsPerDose, ')
          ..write('waterMl: $waterMl, ')
          ..write('minuteOfDay: $minuteOfDay, ')
          ..write('withMeal: $withMeal, ')
          ..write('weekdays: $weekdays, ')
          ..write('remindRepeat: $remindRepeat, ')
          ..write('remindIntervalMin: $remindIntervalMin, ')
          ..write('active: $active, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $DoseLogsTable extends DoseLogs
    with TableInfo<$DoseLogsTable, DoseLogRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DoseLogsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _regimenIdMeta =
      const VerificationMeta('regimenId');
  @override
  late final GeneratedColumn<int> regimenId = GeneratedColumn<int>(
      'regimen_id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES regimens (id) ON DELETE CASCADE'));
  static const VerificationMeta _dayMeta = const VerificationMeta('day');
  @override
  late final GeneratedColumn<String> day = GeneratedColumn<String>(
      'day', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _minuteOfDayMeta =
      const VerificationMeta('minuteOfDay');
  @override
  late final GeneratedColumn<int> minuteOfDay = GeneratedColumn<int>(
      'minute_of_day', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  @override
  late final GeneratedColumnWithTypeConverter<DoseStatus, String> status =
      GeneratedColumn<String>('status', aliasedName, false,
              type: DriftSqlType.string, requiredDuringInsert: true)
          .withConverter<DoseStatus>($DoseLogsTable.$converterstatus);
  static const VerificationMeta _takenAtMeta =
      const VerificationMeta('takenAt');
  @override
  late final GeneratedColumn<int> takenAt = GeneratedColumn<int>(
      'taken_at', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _boxIdMeta = const VerificationMeta('boxId');
  @override
  late final GeneratedColumn<int> boxId = GeneratedColumn<int>(
      'box_id', aliasedName, true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES inventory_boxes (id)'));
  @override
  List<GeneratedColumn> get $columns =>
      [id, regimenId, day, minuteOfDay, status, takenAt, boxId];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'dose_logs';
  @override
  VerificationContext validateIntegrity(Insertable<DoseLogRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('regimen_id')) {
      context.handle(_regimenIdMeta,
          regimenId.isAcceptableOrUnknown(data['regimen_id']!, _regimenIdMeta));
    } else if (isInserting) {
      context.missing(_regimenIdMeta);
    }
    if (data.containsKey('day')) {
      context.handle(
          _dayMeta, day.isAcceptableOrUnknown(data['day']!, _dayMeta));
    } else if (isInserting) {
      context.missing(_dayMeta);
    }
    if (data.containsKey('minute_of_day')) {
      context.handle(
          _minuteOfDayMeta,
          minuteOfDay.isAcceptableOrUnknown(
              data['minute_of_day']!, _minuteOfDayMeta));
    } else if (isInserting) {
      context.missing(_minuteOfDayMeta);
    }
    if (data.containsKey('taken_at')) {
      context.handle(_takenAtMeta,
          takenAt.isAcceptableOrUnknown(data['taken_at']!, _takenAtMeta));
    }
    if (data.containsKey('box_id')) {
      context.handle(
          _boxIdMeta, boxId.isAcceptableOrUnknown(data['box_id']!, _boxIdMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
        {regimenId, day, minuteOfDay},
      ];
  @override
  DoseLogRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DoseLogRow(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      regimenId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}regimen_id'])!,
      day: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}day'])!,
      minuteOfDay: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}minute_of_day'])!,
      status: $DoseLogsTable.$converterstatus.fromSql(attachedDatabase
          .typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}status'])!),
      takenAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}taken_at']),
      boxId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}box_id']),
    );
  }

  @override
  $DoseLogsTable createAlias(String alias) {
    return $DoseLogsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<DoseStatus, String, String> $converterstatus =
      const EnumNameConverter<DoseStatus>(DoseStatus.values);
}

class DoseLogRow extends DataClass implements Insertable<DoseLogRow> {
  final int id;
  final int regimenId;
  final String day;
  final int minuteOfDay;
  final DoseStatus status;
  final int? takenAt;
  final int? boxId;
  const DoseLogRow(
      {required this.id,
      required this.regimenId,
      required this.day,
      required this.minuteOfDay,
      required this.status,
      this.takenAt,
      this.boxId});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['regimen_id'] = Variable<int>(regimenId);
    map['day'] = Variable<String>(day);
    map['minute_of_day'] = Variable<int>(minuteOfDay);
    {
      map['status'] =
          Variable<String>($DoseLogsTable.$converterstatus.toSql(status));
    }
    if (!nullToAbsent || takenAt != null) {
      map['taken_at'] = Variable<int>(takenAt);
    }
    if (!nullToAbsent || boxId != null) {
      map['box_id'] = Variable<int>(boxId);
    }
    return map;
  }

  DoseLogsCompanion toCompanion(bool nullToAbsent) {
    return DoseLogsCompanion(
      id: Value(id),
      regimenId: Value(regimenId),
      day: Value(day),
      minuteOfDay: Value(minuteOfDay),
      status: Value(status),
      takenAt: takenAt == null && nullToAbsent
          ? const Value.absent()
          : Value(takenAt),
      boxId:
          boxId == null && nullToAbsent ? const Value.absent() : Value(boxId),
    );
  }

  factory DoseLogRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DoseLogRow(
      id: serializer.fromJson<int>(json['id']),
      regimenId: serializer.fromJson<int>(json['regimenId']),
      day: serializer.fromJson<String>(json['day']),
      minuteOfDay: serializer.fromJson<int>(json['minuteOfDay']),
      status: $DoseLogsTable.$converterstatus
          .fromJson(serializer.fromJson<String>(json['status'])),
      takenAt: serializer.fromJson<int?>(json['takenAt']),
      boxId: serializer.fromJson<int?>(json['boxId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'regimenId': serializer.toJson<int>(regimenId),
      'day': serializer.toJson<String>(day),
      'minuteOfDay': serializer.toJson<int>(minuteOfDay),
      'status': serializer
          .toJson<String>($DoseLogsTable.$converterstatus.toJson(status)),
      'takenAt': serializer.toJson<int?>(takenAt),
      'boxId': serializer.toJson<int?>(boxId),
    };
  }

  DoseLogRow copyWith(
          {int? id,
          int? regimenId,
          String? day,
          int? minuteOfDay,
          DoseStatus? status,
          Value<int?> takenAt = const Value.absent(),
          Value<int?> boxId = const Value.absent()}) =>
      DoseLogRow(
        id: id ?? this.id,
        regimenId: regimenId ?? this.regimenId,
        day: day ?? this.day,
        minuteOfDay: minuteOfDay ?? this.minuteOfDay,
        status: status ?? this.status,
        takenAt: takenAt.present ? takenAt.value : this.takenAt,
        boxId: boxId.present ? boxId.value : this.boxId,
      );
  DoseLogRow copyWithCompanion(DoseLogsCompanion data) {
    return DoseLogRow(
      id: data.id.present ? data.id.value : this.id,
      regimenId: data.regimenId.present ? data.regimenId.value : this.regimenId,
      day: data.day.present ? data.day.value : this.day,
      minuteOfDay:
          data.minuteOfDay.present ? data.minuteOfDay.value : this.minuteOfDay,
      status: data.status.present ? data.status.value : this.status,
      takenAt: data.takenAt.present ? data.takenAt.value : this.takenAt,
      boxId: data.boxId.present ? data.boxId.value : this.boxId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DoseLogRow(')
          ..write('id: $id, ')
          ..write('regimenId: $regimenId, ')
          ..write('day: $day, ')
          ..write('minuteOfDay: $minuteOfDay, ')
          ..write('status: $status, ')
          ..write('takenAt: $takenAt, ')
          ..write('boxId: $boxId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, regimenId, day, minuteOfDay, status, takenAt, boxId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DoseLogRow &&
          other.id == this.id &&
          other.regimenId == this.regimenId &&
          other.day == this.day &&
          other.minuteOfDay == this.minuteOfDay &&
          other.status == this.status &&
          other.takenAt == this.takenAt &&
          other.boxId == this.boxId);
}

class DoseLogsCompanion extends UpdateCompanion<DoseLogRow> {
  final Value<int> id;
  final Value<int> regimenId;
  final Value<String> day;
  final Value<int> minuteOfDay;
  final Value<DoseStatus> status;
  final Value<int?> takenAt;
  final Value<int?> boxId;
  const DoseLogsCompanion({
    this.id = const Value.absent(),
    this.regimenId = const Value.absent(),
    this.day = const Value.absent(),
    this.minuteOfDay = const Value.absent(),
    this.status = const Value.absent(),
    this.takenAt = const Value.absent(),
    this.boxId = const Value.absent(),
  });
  DoseLogsCompanion.insert({
    this.id = const Value.absent(),
    required int regimenId,
    required String day,
    required int minuteOfDay,
    required DoseStatus status,
    this.takenAt = const Value.absent(),
    this.boxId = const Value.absent(),
  })  : regimenId = Value(regimenId),
        day = Value(day),
        minuteOfDay = Value(minuteOfDay),
        status = Value(status);
  static Insertable<DoseLogRow> custom({
    Expression<int>? id,
    Expression<int>? regimenId,
    Expression<String>? day,
    Expression<int>? minuteOfDay,
    Expression<String>? status,
    Expression<int>? takenAt,
    Expression<int>? boxId,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (regimenId != null) 'regimen_id': regimenId,
      if (day != null) 'day': day,
      if (minuteOfDay != null) 'minute_of_day': minuteOfDay,
      if (status != null) 'status': status,
      if (takenAt != null) 'taken_at': takenAt,
      if (boxId != null) 'box_id': boxId,
    });
  }

  DoseLogsCompanion copyWith(
      {Value<int>? id,
      Value<int>? regimenId,
      Value<String>? day,
      Value<int>? minuteOfDay,
      Value<DoseStatus>? status,
      Value<int?>? takenAt,
      Value<int?>? boxId}) {
    return DoseLogsCompanion(
      id: id ?? this.id,
      regimenId: regimenId ?? this.regimenId,
      day: day ?? this.day,
      minuteOfDay: minuteOfDay ?? this.minuteOfDay,
      status: status ?? this.status,
      takenAt: takenAt ?? this.takenAt,
      boxId: boxId ?? this.boxId,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (regimenId.present) {
      map['regimen_id'] = Variable<int>(regimenId.value);
    }
    if (day.present) {
      map['day'] = Variable<String>(day.value);
    }
    if (minuteOfDay.present) {
      map['minute_of_day'] = Variable<int>(minuteOfDay.value);
    }
    if (status.present) {
      map['status'] =
          Variable<String>($DoseLogsTable.$converterstatus.toSql(status.value));
    }
    if (takenAt.present) {
      map['taken_at'] = Variable<int>(takenAt.value);
    }
    if (boxId.present) {
      map['box_id'] = Variable<int>(boxId.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DoseLogsCompanion(')
          ..write('id: $id, ')
          ..write('regimenId: $regimenId, ')
          ..write('day: $day, ')
          ..write('minuteOfDay: $minuteOfDay, ')
          ..write('status: $status, ')
          ..write('takenAt: $takenAt, ')
          ..write('boxId: $boxId')
          ..write(')'))
        .toString();
  }
}

class $IntakeEntriesTable extends IntakeEntries
    with TableInfo<$IntakeEntriesTable, IntakeEntryRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $IntakeEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _personIdMeta =
      const VerificationMeta('personId');
  @override
  late final GeneratedColumn<int> personId = GeneratedColumn<int>(
      'person_id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES people (id) ON DELETE CASCADE'));
  static const VerificationMeta _dayMeta = const VerificationMeta('day');
  @override
  late final GeneratedColumn<String> day = GeneratedColumn<String>(
      'day', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _labelMeta = const VerificationMeta('label');
  @override
  late final GeneratedColumn<String> label = GeneratedColumn<String>(
      'label', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  @override
  late final GeneratedColumnWithTypeConverter<IntakeSource, String> source =
      GeneratedColumn<String>('source', aliasedName, false,
              type: DriftSqlType.string, requiredDuringInsert: true)
          .withConverter<IntakeSource>($IntakeEntriesTable.$convertersource);
  static const VerificationMeta _mealIdMeta = const VerificationMeta('mealId');
  @override
  late final GeneratedColumn<String> mealId = GeneratedColumn<String>(
      'meal_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _productIdMeta =
      const VerificationMeta('productId');
  @override
  late final GeneratedColumn<int> productId = GeneratedColumn<int>(
      'product_id', aliasedName, true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES products (id)'));
  static const VerificationMeta _doseLogIdMeta =
      const VerificationMeta('doseLogId');
  @override
  late final GeneratedColumn<int> doseLogId = GeneratedColumn<int>(
      'dose_log_id', aliasedName, true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES dose_logs (id) ON DELETE SET NULL'));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
      'created_at', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        personId,
        day,
        label,
        source,
        mealId,
        productId,
        doseLogId,
        createdAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'intake_entries';
  @override
  VerificationContext validateIntegrity(Insertable<IntakeEntryRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('person_id')) {
      context.handle(_personIdMeta,
          personId.isAcceptableOrUnknown(data['person_id']!, _personIdMeta));
    } else if (isInserting) {
      context.missing(_personIdMeta);
    }
    if (data.containsKey('day')) {
      context.handle(
          _dayMeta, day.isAcceptableOrUnknown(data['day']!, _dayMeta));
    } else if (isInserting) {
      context.missing(_dayMeta);
    }
    if (data.containsKey('label')) {
      context.handle(
          _labelMeta, label.isAcceptableOrUnknown(data['label']!, _labelMeta));
    } else if (isInserting) {
      context.missing(_labelMeta);
    }
    if (data.containsKey('meal_id')) {
      context.handle(_mealIdMeta,
          mealId.isAcceptableOrUnknown(data['meal_id']!, _mealIdMeta));
    }
    if (data.containsKey('product_id')) {
      context.handle(_productIdMeta,
          productId.isAcceptableOrUnknown(data['product_id']!, _productIdMeta));
    }
    if (data.containsKey('dose_log_id')) {
      context.handle(
          _doseLogIdMeta,
          doseLogId.isAcceptableOrUnknown(
              data['dose_log_id']!, _doseLogIdMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  IntakeEntryRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return IntakeEntryRow(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      personId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}person_id'])!,
      day: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}day'])!,
      label: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}label'])!,
      source: $IntakeEntriesTable.$convertersource.fromSql(attachedDatabase
          .typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}source'])!),
      mealId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}meal_id']),
      productId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}product_id']),
      doseLogId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}dose_log_id']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $IntakeEntriesTable createAlias(String alias) {
    return $IntakeEntriesTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<IntakeSource, String, String> $convertersource =
      const EnumNameConverter<IntakeSource>(IntakeSource.values);
}

class IntakeEntryRow extends DataClass implements Insertable<IntakeEntryRow> {
  final int id;
  final int personId;
  final String day;
  final String label;
  final IntakeSource source;
  final String? mealId;
  final int? productId;
  final int? doseLogId;
  final int createdAt;
  const IntakeEntryRow(
      {required this.id,
      required this.personId,
      required this.day,
      required this.label,
      required this.source,
      this.mealId,
      this.productId,
      this.doseLogId,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['person_id'] = Variable<int>(personId);
    map['day'] = Variable<String>(day);
    map['label'] = Variable<String>(label);
    {
      map['source'] =
          Variable<String>($IntakeEntriesTable.$convertersource.toSql(source));
    }
    if (!nullToAbsent || mealId != null) {
      map['meal_id'] = Variable<String>(mealId);
    }
    if (!nullToAbsent || productId != null) {
      map['product_id'] = Variable<int>(productId);
    }
    if (!nullToAbsent || doseLogId != null) {
      map['dose_log_id'] = Variable<int>(doseLogId);
    }
    map['created_at'] = Variable<int>(createdAt);
    return map;
  }

  IntakeEntriesCompanion toCompanion(bool nullToAbsent) {
    return IntakeEntriesCompanion(
      id: Value(id),
      personId: Value(personId),
      day: Value(day),
      label: Value(label),
      source: Value(source),
      mealId:
          mealId == null && nullToAbsent ? const Value.absent() : Value(mealId),
      productId: productId == null && nullToAbsent
          ? const Value.absent()
          : Value(productId),
      doseLogId: doseLogId == null && nullToAbsent
          ? const Value.absent()
          : Value(doseLogId),
      createdAt: Value(createdAt),
    );
  }

  factory IntakeEntryRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return IntakeEntryRow(
      id: serializer.fromJson<int>(json['id']),
      personId: serializer.fromJson<int>(json['personId']),
      day: serializer.fromJson<String>(json['day']),
      label: serializer.fromJson<String>(json['label']),
      source: $IntakeEntriesTable.$convertersource
          .fromJson(serializer.fromJson<String>(json['source'])),
      mealId: serializer.fromJson<String?>(json['mealId']),
      productId: serializer.fromJson<int?>(json['productId']),
      doseLogId: serializer.fromJson<int?>(json['doseLogId']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'personId': serializer.toJson<int>(personId),
      'day': serializer.toJson<String>(day),
      'label': serializer.toJson<String>(label),
      'source': serializer
          .toJson<String>($IntakeEntriesTable.$convertersource.toJson(source)),
      'mealId': serializer.toJson<String?>(mealId),
      'productId': serializer.toJson<int?>(productId),
      'doseLogId': serializer.toJson<int?>(doseLogId),
      'createdAt': serializer.toJson<int>(createdAt),
    };
  }

  IntakeEntryRow copyWith(
          {int? id,
          int? personId,
          String? day,
          String? label,
          IntakeSource? source,
          Value<String?> mealId = const Value.absent(),
          Value<int?> productId = const Value.absent(),
          Value<int?> doseLogId = const Value.absent(),
          int? createdAt}) =>
      IntakeEntryRow(
        id: id ?? this.id,
        personId: personId ?? this.personId,
        day: day ?? this.day,
        label: label ?? this.label,
        source: source ?? this.source,
        mealId: mealId.present ? mealId.value : this.mealId,
        productId: productId.present ? productId.value : this.productId,
        doseLogId: doseLogId.present ? doseLogId.value : this.doseLogId,
        createdAt: createdAt ?? this.createdAt,
      );
  IntakeEntryRow copyWithCompanion(IntakeEntriesCompanion data) {
    return IntakeEntryRow(
      id: data.id.present ? data.id.value : this.id,
      personId: data.personId.present ? data.personId.value : this.personId,
      day: data.day.present ? data.day.value : this.day,
      label: data.label.present ? data.label.value : this.label,
      source: data.source.present ? data.source.value : this.source,
      mealId: data.mealId.present ? data.mealId.value : this.mealId,
      productId: data.productId.present ? data.productId.value : this.productId,
      doseLogId: data.doseLogId.present ? data.doseLogId.value : this.doseLogId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('IntakeEntryRow(')
          ..write('id: $id, ')
          ..write('personId: $personId, ')
          ..write('day: $day, ')
          ..write('label: $label, ')
          ..write('source: $source, ')
          ..write('mealId: $mealId, ')
          ..write('productId: $productId, ')
          ..write('doseLogId: $doseLogId, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, personId, day, label, source, mealId,
      productId, doseLogId, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is IntakeEntryRow &&
          other.id == this.id &&
          other.personId == this.personId &&
          other.day == this.day &&
          other.label == this.label &&
          other.source == this.source &&
          other.mealId == this.mealId &&
          other.productId == this.productId &&
          other.doseLogId == this.doseLogId &&
          other.createdAt == this.createdAt);
}

class IntakeEntriesCompanion extends UpdateCompanion<IntakeEntryRow> {
  final Value<int> id;
  final Value<int> personId;
  final Value<String> day;
  final Value<String> label;
  final Value<IntakeSource> source;
  final Value<String?> mealId;
  final Value<int?> productId;
  final Value<int?> doseLogId;
  final Value<int> createdAt;
  const IntakeEntriesCompanion({
    this.id = const Value.absent(),
    this.personId = const Value.absent(),
    this.day = const Value.absent(),
    this.label = const Value.absent(),
    this.source = const Value.absent(),
    this.mealId = const Value.absent(),
    this.productId = const Value.absent(),
    this.doseLogId = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  IntakeEntriesCompanion.insert({
    this.id = const Value.absent(),
    required int personId,
    required String day,
    required String label,
    required IntakeSource source,
    this.mealId = const Value.absent(),
    this.productId = const Value.absent(),
    this.doseLogId = const Value.absent(),
    required int createdAt,
  })  : personId = Value(personId),
        day = Value(day),
        label = Value(label),
        source = Value(source),
        createdAt = Value(createdAt);
  static Insertable<IntakeEntryRow> custom({
    Expression<int>? id,
    Expression<int>? personId,
    Expression<String>? day,
    Expression<String>? label,
    Expression<String>? source,
    Expression<String>? mealId,
    Expression<int>? productId,
    Expression<int>? doseLogId,
    Expression<int>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (personId != null) 'person_id': personId,
      if (day != null) 'day': day,
      if (label != null) 'label': label,
      if (source != null) 'source': source,
      if (mealId != null) 'meal_id': mealId,
      if (productId != null) 'product_id': productId,
      if (doseLogId != null) 'dose_log_id': doseLogId,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  IntakeEntriesCompanion copyWith(
      {Value<int>? id,
      Value<int>? personId,
      Value<String>? day,
      Value<String>? label,
      Value<IntakeSource>? source,
      Value<String?>? mealId,
      Value<int?>? productId,
      Value<int?>? doseLogId,
      Value<int>? createdAt}) {
    return IntakeEntriesCompanion(
      id: id ?? this.id,
      personId: personId ?? this.personId,
      day: day ?? this.day,
      label: label ?? this.label,
      source: source ?? this.source,
      mealId: mealId ?? this.mealId,
      productId: productId ?? this.productId,
      doseLogId: doseLogId ?? this.doseLogId,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (personId.present) {
      map['person_id'] = Variable<int>(personId.value);
    }
    if (day.present) {
      map['day'] = Variable<String>(day.value);
    }
    if (label.present) {
      map['label'] = Variable<String>(label.value);
    }
    if (source.present) {
      map['source'] = Variable<String>(
          $IntakeEntriesTable.$convertersource.toSql(source.value));
    }
    if (mealId.present) {
      map['meal_id'] = Variable<String>(mealId.value);
    }
    if (productId.present) {
      map['product_id'] = Variable<int>(productId.value);
    }
    if (doseLogId.present) {
      map['dose_log_id'] = Variable<int>(doseLogId.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('IntakeEntriesCompanion(')
          ..write('id: $id, ')
          ..write('personId: $personId, ')
          ..write('day: $day, ')
          ..write('label: $label, ')
          ..write('source: $source, ')
          ..write('mealId: $mealId, ')
          ..write('productId: $productId, ')
          ..write('doseLogId: $doseLogId, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $IntakeNutrientsTable extends IntakeNutrients
    with TableInfo<$IntakeNutrientsTable, IntakeNutrientRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $IntakeNutrientsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _entryIdMeta =
      const VerificationMeta('entryId');
  @override
  late final GeneratedColumn<int> entryId = GeneratedColumn<int>(
      'entry_id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES intake_entries (id) ON DELETE CASCADE'));
  static const VerificationMeta _nutrientIdMeta =
      const VerificationMeta('nutrientId');
  @override
  late final GeneratedColumn<String> nutrientId = GeneratedColumn<String>(
      'nutrient_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _amountMeta = const VerificationMeta('amount');
  @override
  late final GeneratedColumn<double> amount = GeneratedColumn<double>(
      'amount', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _unitMeta = const VerificationMeta('unit');
  @override
  late final GeneratedColumn<String> unit = GeneratedColumn<String>(
      'unit', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [entryId, nutrientId, amount, unit];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'intake_nutrients';
  @override
  VerificationContext validateIntegrity(Insertable<IntakeNutrientRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('entry_id')) {
      context.handle(_entryIdMeta,
          entryId.isAcceptableOrUnknown(data['entry_id']!, _entryIdMeta));
    } else if (isInserting) {
      context.missing(_entryIdMeta);
    }
    if (data.containsKey('nutrient_id')) {
      context.handle(
          _nutrientIdMeta,
          nutrientId.isAcceptableOrUnknown(
              data['nutrient_id']!, _nutrientIdMeta));
    } else if (isInserting) {
      context.missing(_nutrientIdMeta);
    }
    if (data.containsKey('amount')) {
      context.handle(_amountMeta,
          amount.isAcceptableOrUnknown(data['amount']!, _amountMeta));
    } else if (isInserting) {
      context.missing(_amountMeta);
    }
    if (data.containsKey('unit')) {
      context.handle(
          _unitMeta, unit.isAcceptableOrUnknown(data['unit']!, _unitMeta));
    } else if (isInserting) {
      context.missing(_unitMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {entryId, nutrientId};
  @override
  IntakeNutrientRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return IntakeNutrientRow(
      entryId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}entry_id'])!,
      nutrientId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}nutrient_id'])!,
      amount: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}amount'])!,
      unit: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}unit'])!,
    );
  }

  @override
  $IntakeNutrientsTable createAlias(String alias) {
    return $IntakeNutrientsTable(attachedDatabase, alias);
  }
}

class IntakeNutrientRow extends DataClass
    implements Insertable<IntakeNutrientRow> {
  final int entryId;
  final String nutrientId;
  final double amount;
  final String unit;
  const IntakeNutrientRow(
      {required this.entryId,
      required this.nutrientId,
      required this.amount,
      required this.unit});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['entry_id'] = Variable<int>(entryId);
    map['nutrient_id'] = Variable<String>(nutrientId);
    map['amount'] = Variable<double>(amount);
    map['unit'] = Variable<String>(unit);
    return map;
  }

  IntakeNutrientsCompanion toCompanion(bool nullToAbsent) {
    return IntakeNutrientsCompanion(
      entryId: Value(entryId),
      nutrientId: Value(nutrientId),
      amount: Value(amount),
      unit: Value(unit),
    );
  }

  factory IntakeNutrientRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return IntakeNutrientRow(
      entryId: serializer.fromJson<int>(json['entryId']),
      nutrientId: serializer.fromJson<String>(json['nutrientId']),
      amount: serializer.fromJson<double>(json['amount']),
      unit: serializer.fromJson<String>(json['unit']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'entryId': serializer.toJson<int>(entryId),
      'nutrientId': serializer.toJson<String>(nutrientId),
      'amount': serializer.toJson<double>(amount),
      'unit': serializer.toJson<String>(unit),
    };
  }

  IntakeNutrientRow copyWith(
          {int? entryId, String? nutrientId, double? amount, String? unit}) =>
      IntakeNutrientRow(
        entryId: entryId ?? this.entryId,
        nutrientId: nutrientId ?? this.nutrientId,
        amount: amount ?? this.amount,
        unit: unit ?? this.unit,
      );
  IntakeNutrientRow copyWithCompanion(IntakeNutrientsCompanion data) {
    return IntakeNutrientRow(
      entryId: data.entryId.present ? data.entryId.value : this.entryId,
      nutrientId:
          data.nutrientId.present ? data.nutrientId.value : this.nutrientId,
      amount: data.amount.present ? data.amount.value : this.amount,
      unit: data.unit.present ? data.unit.value : this.unit,
    );
  }

  @override
  String toString() {
    return (StringBuffer('IntakeNutrientRow(')
          ..write('entryId: $entryId, ')
          ..write('nutrientId: $nutrientId, ')
          ..write('amount: $amount, ')
          ..write('unit: $unit')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(entryId, nutrientId, amount, unit);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is IntakeNutrientRow &&
          other.entryId == this.entryId &&
          other.nutrientId == this.nutrientId &&
          other.amount == this.amount &&
          other.unit == this.unit);
}

class IntakeNutrientsCompanion extends UpdateCompanion<IntakeNutrientRow> {
  final Value<int> entryId;
  final Value<String> nutrientId;
  final Value<double> amount;
  final Value<String> unit;
  final Value<int> rowid;
  const IntakeNutrientsCompanion({
    this.entryId = const Value.absent(),
    this.nutrientId = const Value.absent(),
    this.amount = const Value.absent(),
    this.unit = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  IntakeNutrientsCompanion.insert({
    required int entryId,
    required String nutrientId,
    required double amount,
    required String unit,
    this.rowid = const Value.absent(),
  })  : entryId = Value(entryId),
        nutrientId = Value(nutrientId),
        amount = Value(amount),
        unit = Value(unit);
  static Insertable<IntakeNutrientRow> custom({
    Expression<int>? entryId,
    Expression<String>? nutrientId,
    Expression<double>? amount,
    Expression<String>? unit,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (entryId != null) 'entry_id': entryId,
      if (nutrientId != null) 'nutrient_id': nutrientId,
      if (amount != null) 'amount': amount,
      if (unit != null) 'unit': unit,
      if (rowid != null) 'rowid': rowid,
    });
  }

  IntakeNutrientsCompanion copyWith(
      {Value<int>? entryId,
      Value<String>? nutrientId,
      Value<double>? amount,
      Value<String>? unit,
      Value<int>? rowid}) {
    return IntakeNutrientsCompanion(
      entryId: entryId ?? this.entryId,
      nutrientId: nutrientId ?? this.nutrientId,
      amount: amount ?? this.amount,
      unit: unit ?? this.unit,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (entryId.present) {
      map['entry_id'] = Variable<int>(entryId.value);
    }
    if (nutrientId.present) {
      map['nutrient_id'] = Variable<String>(nutrientId.value);
    }
    if (amount.present) {
      map['amount'] = Variable<double>(amount.value);
    }
    if (unit.present) {
      map['unit'] = Variable<String>(unit.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('IntakeNutrientsCompanion(')
          ..write('entryId: $entryId, ')
          ..write('nutrientId: $nutrientId, ')
          ..write('amount: $amount, ')
          ..write('unit: $unit, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $WorkoutsTable extends Workouts
    with TableInfo<$WorkoutsTable, WorkoutRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WorkoutsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _personIdMeta =
      const VerificationMeta('personId');
  @override
  late final GeneratedColumn<int> personId = GeneratedColumn<int>(
      'person_id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES people (id) ON DELETE CASCADE'));
  static const VerificationMeta _dayMeta = const VerificationMeta('day');
  @override
  late final GeneratedColumn<String> day = GeneratedColumn<String>(
      'day', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _activityCodeMeta =
      const VerificationMeta('activityCode');
  @override
  late final GeneratedColumn<String> activityCode = GeneratedColumn<String>(
      'activity_code', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _minutesMeta =
      const VerificationMeta('minutes');
  @override
  late final GeneratedColumn<double> minutes = GeneratedColumn<double>(
      'minutes', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
      'created_at', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns =>
      [id, personId, day, activityCode, minutes, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'workouts';
  @override
  VerificationContext validateIntegrity(Insertable<WorkoutRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('person_id')) {
      context.handle(_personIdMeta,
          personId.isAcceptableOrUnknown(data['person_id']!, _personIdMeta));
    } else if (isInserting) {
      context.missing(_personIdMeta);
    }
    if (data.containsKey('day')) {
      context.handle(
          _dayMeta, day.isAcceptableOrUnknown(data['day']!, _dayMeta));
    } else if (isInserting) {
      context.missing(_dayMeta);
    }
    if (data.containsKey('activity_code')) {
      context.handle(
          _activityCodeMeta,
          activityCode.isAcceptableOrUnknown(
              data['activity_code']!, _activityCodeMeta));
    } else if (isInserting) {
      context.missing(_activityCodeMeta);
    }
    if (data.containsKey('minutes')) {
      context.handle(_minutesMeta,
          minutes.isAcceptableOrUnknown(data['minutes']!, _minutesMeta));
    } else if (isInserting) {
      context.missing(_minutesMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  WorkoutRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return WorkoutRow(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      personId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}person_id'])!,
      day: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}day'])!,
      activityCode: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}activity_code'])!,
      minutes: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}minutes'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $WorkoutsTable createAlias(String alias) {
    return $WorkoutsTable(attachedDatabase, alias);
  }
}

class WorkoutRow extends DataClass implements Insertable<WorkoutRow> {
  final int id;
  final int personId;
  final String day;
  final String activityCode;
  final double minutes;
  final int createdAt;
  const WorkoutRow(
      {required this.id,
      required this.personId,
      required this.day,
      required this.activityCode,
      required this.minutes,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['person_id'] = Variable<int>(personId);
    map['day'] = Variable<String>(day);
    map['activity_code'] = Variable<String>(activityCode);
    map['minutes'] = Variable<double>(minutes);
    map['created_at'] = Variable<int>(createdAt);
    return map;
  }

  WorkoutsCompanion toCompanion(bool nullToAbsent) {
    return WorkoutsCompanion(
      id: Value(id),
      personId: Value(personId),
      day: Value(day),
      activityCode: Value(activityCode),
      minutes: Value(minutes),
      createdAt: Value(createdAt),
    );
  }

  factory WorkoutRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return WorkoutRow(
      id: serializer.fromJson<int>(json['id']),
      personId: serializer.fromJson<int>(json['personId']),
      day: serializer.fromJson<String>(json['day']),
      activityCode: serializer.fromJson<String>(json['activityCode']),
      minutes: serializer.fromJson<double>(json['minutes']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'personId': serializer.toJson<int>(personId),
      'day': serializer.toJson<String>(day),
      'activityCode': serializer.toJson<String>(activityCode),
      'minutes': serializer.toJson<double>(minutes),
      'createdAt': serializer.toJson<int>(createdAt),
    };
  }

  WorkoutRow copyWith(
          {int? id,
          int? personId,
          String? day,
          String? activityCode,
          double? minutes,
          int? createdAt}) =>
      WorkoutRow(
        id: id ?? this.id,
        personId: personId ?? this.personId,
        day: day ?? this.day,
        activityCode: activityCode ?? this.activityCode,
        minutes: minutes ?? this.minutes,
        createdAt: createdAt ?? this.createdAt,
      );
  WorkoutRow copyWithCompanion(WorkoutsCompanion data) {
    return WorkoutRow(
      id: data.id.present ? data.id.value : this.id,
      personId: data.personId.present ? data.personId.value : this.personId,
      day: data.day.present ? data.day.value : this.day,
      activityCode: data.activityCode.present
          ? data.activityCode.value
          : this.activityCode,
      minutes: data.minutes.present ? data.minutes.value : this.minutes,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('WorkoutRow(')
          ..write('id: $id, ')
          ..write('personId: $personId, ')
          ..write('day: $day, ')
          ..write('activityCode: $activityCode, ')
          ..write('minutes: $minutes, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, personId, day, activityCode, minutes, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is WorkoutRow &&
          other.id == this.id &&
          other.personId == this.personId &&
          other.day == this.day &&
          other.activityCode == this.activityCode &&
          other.minutes == this.minutes &&
          other.createdAt == this.createdAt);
}

class WorkoutsCompanion extends UpdateCompanion<WorkoutRow> {
  final Value<int> id;
  final Value<int> personId;
  final Value<String> day;
  final Value<String> activityCode;
  final Value<double> minutes;
  final Value<int> createdAt;
  const WorkoutsCompanion({
    this.id = const Value.absent(),
    this.personId = const Value.absent(),
    this.day = const Value.absent(),
    this.activityCode = const Value.absent(),
    this.minutes = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  WorkoutsCompanion.insert({
    this.id = const Value.absent(),
    required int personId,
    required String day,
    required String activityCode,
    required double minutes,
    required int createdAt,
  })  : personId = Value(personId),
        day = Value(day),
        activityCode = Value(activityCode),
        minutes = Value(minutes),
        createdAt = Value(createdAt);
  static Insertable<WorkoutRow> custom({
    Expression<int>? id,
    Expression<int>? personId,
    Expression<String>? day,
    Expression<String>? activityCode,
    Expression<double>? minutes,
    Expression<int>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (personId != null) 'person_id': personId,
      if (day != null) 'day': day,
      if (activityCode != null) 'activity_code': activityCode,
      if (minutes != null) 'minutes': minutes,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  WorkoutsCompanion copyWith(
      {Value<int>? id,
      Value<int>? personId,
      Value<String>? day,
      Value<String>? activityCode,
      Value<double>? minutes,
      Value<int>? createdAt}) {
    return WorkoutsCompanion(
      id: id ?? this.id,
      personId: personId ?? this.personId,
      day: day ?? this.day,
      activityCode: activityCode ?? this.activityCode,
      minutes: minutes ?? this.minutes,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (personId.present) {
      map['person_id'] = Variable<int>(personId.value);
    }
    if (day.present) {
      map['day'] = Variable<String>(day.value);
    }
    if (activityCode.present) {
      map['activity_code'] = Variable<String>(activityCode.value);
    }
    if (minutes.present) {
      map['minutes'] = Variable<double>(minutes.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WorkoutsCompanion(')
          ..write('id: $id, ')
          ..write('personId: $personId, ')
          ..write('day: $day, ')
          ..write('activityCode: $activityCode, ')
          ..write('minutes: $minutes, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $WaterLogsTable extends WaterLogs
    with TableInfo<$WaterLogsTable, WaterLogRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WaterLogsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _personIdMeta =
      const VerificationMeta('personId');
  @override
  late final GeneratedColumn<int> personId = GeneratedColumn<int>(
      'person_id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES people (id) ON DELETE CASCADE'));
  static const VerificationMeta _dayMeta = const VerificationMeta('day');
  @override
  late final GeneratedColumn<String> day = GeneratedColumn<String>(
      'day', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _mlMeta = const VerificationMeta('ml');
  @override
  late final GeneratedColumn<double> ml = GeneratedColumn<double>(
      'ml', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
      'created_at', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [id, personId, day, ml, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'water_logs';
  @override
  VerificationContext validateIntegrity(Insertable<WaterLogRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('person_id')) {
      context.handle(_personIdMeta,
          personId.isAcceptableOrUnknown(data['person_id']!, _personIdMeta));
    } else if (isInserting) {
      context.missing(_personIdMeta);
    }
    if (data.containsKey('day')) {
      context.handle(
          _dayMeta, day.isAcceptableOrUnknown(data['day']!, _dayMeta));
    } else if (isInserting) {
      context.missing(_dayMeta);
    }
    if (data.containsKey('ml')) {
      context.handle(_mlMeta, ml.isAcceptableOrUnknown(data['ml']!, _mlMeta));
    } else if (isInserting) {
      context.missing(_mlMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  WaterLogRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return WaterLogRow(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      personId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}person_id'])!,
      day: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}day'])!,
      ml: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}ml'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $WaterLogsTable createAlias(String alias) {
    return $WaterLogsTable(attachedDatabase, alias);
  }
}

class WaterLogRow extends DataClass implements Insertable<WaterLogRow> {
  final int id;
  final int personId;
  final String day;
  final double ml;
  final int createdAt;
  const WaterLogRow(
      {required this.id,
      required this.personId,
      required this.day,
      required this.ml,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['person_id'] = Variable<int>(personId);
    map['day'] = Variable<String>(day);
    map['ml'] = Variable<double>(ml);
    map['created_at'] = Variable<int>(createdAt);
    return map;
  }

  WaterLogsCompanion toCompanion(bool nullToAbsent) {
    return WaterLogsCompanion(
      id: Value(id),
      personId: Value(personId),
      day: Value(day),
      ml: Value(ml),
      createdAt: Value(createdAt),
    );
  }

  factory WaterLogRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return WaterLogRow(
      id: serializer.fromJson<int>(json['id']),
      personId: serializer.fromJson<int>(json['personId']),
      day: serializer.fromJson<String>(json['day']),
      ml: serializer.fromJson<double>(json['ml']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'personId': serializer.toJson<int>(personId),
      'day': serializer.toJson<String>(day),
      'ml': serializer.toJson<double>(ml),
      'createdAt': serializer.toJson<int>(createdAt),
    };
  }

  WaterLogRow copyWith(
          {int? id, int? personId, String? day, double? ml, int? createdAt}) =>
      WaterLogRow(
        id: id ?? this.id,
        personId: personId ?? this.personId,
        day: day ?? this.day,
        ml: ml ?? this.ml,
        createdAt: createdAt ?? this.createdAt,
      );
  WaterLogRow copyWithCompanion(WaterLogsCompanion data) {
    return WaterLogRow(
      id: data.id.present ? data.id.value : this.id,
      personId: data.personId.present ? data.personId.value : this.personId,
      day: data.day.present ? data.day.value : this.day,
      ml: data.ml.present ? data.ml.value : this.ml,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('WaterLogRow(')
          ..write('id: $id, ')
          ..write('personId: $personId, ')
          ..write('day: $day, ')
          ..write('ml: $ml, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, personId, day, ml, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is WaterLogRow &&
          other.id == this.id &&
          other.personId == this.personId &&
          other.day == this.day &&
          other.ml == this.ml &&
          other.createdAt == this.createdAt);
}

class WaterLogsCompanion extends UpdateCompanion<WaterLogRow> {
  final Value<int> id;
  final Value<int> personId;
  final Value<String> day;
  final Value<double> ml;
  final Value<int> createdAt;
  const WaterLogsCompanion({
    this.id = const Value.absent(),
    this.personId = const Value.absent(),
    this.day = const Value.absent(),
    this.ml = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  WaterLogsCompanion.insert({
    this.id = const Value.absent(),
    required int personId,
    required String day,
    required double ml,
    required int createdAt,
  })  : personId = Value(personId),
        day = Value(day),
        ml = Value(ml),
        createdAt = Value(createdAt);
  static Insertable<WaterLogRow> custom({
    Expression<int>? id,
    Expression<int>? personId,
    Expression<String>? day,
    Expression<double>? ml,
    Expression<int>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (personId != null) 'person_id': personId,
      if (day != null) 'day': day,
      if (ml != null) 'ml': ml,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  WaterLogsCompanion copyWith(
      {Value<int>? id,
      Value<int>? personId,
      Value<String>? day,
      Value<double>? ml,
      Value<int>? createdAt}) {
    return WaterLogsCompanion(
      id: id ?? this.id,
      personId: personId ?? this.personId,
      day: day ?? this.day,
      ml: ml ?? this.ml,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (personId.present) {
      map['person_id'] = Variable<int>(personId.value);
    }
    if (day.present) {
      map['day'] = Variable<String>(day.value);
    }
    if (ml.present) {
      map['ml'] = Variable<double>(ml.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WaterLogsCompanion(')
          ..write('id: $id, ')
          ..write('personId: $personId, ')
          ..write('day: $day, ')
          ..write('ml: $ml, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $PeopleTable people = $PeopleTable(this);
  late final $ProfilesTable profiles = $ProfilesTable(this);
  late final $SettingsTable settings = $SettingsTable(this);
  late final $ProductsTable products = $ProductsTable(this);
  late final $ProductNutrientsTable productNutrients =
      $ProductNutrientsTable(this);
  late final $InventoryBoxesTable inventoryBoxes = $InventoryBoxesTable(this);
  late final $RegimensTable regimens = $RegimensTable(this);
  late final $DoseLogsTable doseLogs = $DoseLogsTable(this);
  late final $IntakeEntriesTable intakeEntries = $IntakeEntriesTable(this);
  late final $IntakeNutrientsTable intakeNutrients =
      $IntakeNutrientsTable(this);
  late final $WorkoutsTable workouts = $WorkoutsTable(this);
  late final $WaterLogsTable waterLogs = $WaterLogsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
        people,
        profiles,
        settings,
        products,
        productNutrients,
        inventoryBoxes,
        regimens,
        doseLogs,
        intakeEntries,
        intakeNutrients,
        workouts,
        waterLogs
      ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules(
        [
          WritePropagation(
            on: TableUpdateQuery.onTableName('people',
                limitUpdateKind: UpdateKind.delete),
            result: [
              TableUpdate('profiles', kind: UpdateKind.delete),
            ],
          ),
          WritePropagation(
            on: TableUpdateQuery.onTableName('products',
                limitUpdateKind: UpdateKind.delete),
            result: [
              TableUpdate('product_nutrients', kind: UpdateKind.delete),
            ],
          ),
          WritePropagation(
            on: TableUpdateQuery.onTableName('people',
                limitUpdateKind: UpdateKind.delete),
            result: [
              TableUpdate('regimens', kind: UpdateKind.delete),
            ],
          ),
          WritePropagation(
            on: TableUpdateQuery.onTableName('regimens',
                limitUpdateKind: UpdateKind.delete),
            result: [
              TableUpdate('dose_logs', kind: UpdateKind.delete),
            ],
          ),
          WritePropagation(
            on: TableUpdateQuery.onTableName('people',
                limitUpdateKind: UpdateKind.delete),
            result: [
              TableUpdate('intake_entries', kind: UpdateKind.delete),
            ],
          ),
          WritePropagation(
            on: TableUpdateQuery.onTableName('dose_logs',
                limitUpdateKind: UpdateKind.delete),
            result: [
              TableUpdate('intake_entries', kind: UpdateKind.update),
            ],
          ),
          WritePropagation(
            on: TableUpdateQuery.onTableName('intake_entries',
                limitUpdateKind: UpdateKind.delete),
            result: [
              TableUpdate('intake_nutrients', kind: UpdateKind.delete),
            ],
          ),
          WritePropagation(
            on: TableUpdateQuery.onTableName('people',
                limitUpdateKind: UpdateKind.delete),
            result: [
              TableUpdate('workouts', kind: UpdateKind.delete),
            ],
          ),
          WritePropagation(
            on: TableUpdateQuery.onTableName('people',
                limitUpdateKind: UpdateKind.delete),
            result: [
              TableUpdate('water_logs', kind: UpdateKind.delete),
            ],
          ),
        ],
      );
}

typedef $$PeopleTableCreateCompanionBuilder = PeopleCompanion Function({
  Value<int> id,
  required String displayName,
  Value<bool> isPrimary,
  required int createdAt,
});
typedef $$PeopleTableUpdateCompanionBuilder = PeopleCompanion Function({
  Value<int> id,
  Value<String> displayName,
  Value<bool> isPrimary,
  Value<int> createdAt,
});

final class $$PeopleTableReferences
    extends BaseReferences<_$AppDatabase, $PeopleTable, PersonRow> {
  $$PeopleTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$ProfilesTable, List<ProfileRow>>
      _profilesRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.profiles,
              aliasName: 'people__id__profiles__person_id');

  $$ProfilesTableProcessedTableManager get profilesRefs {
    final manager = $$ProfilesTableTableManager($_db, $_db.profiles)
        .filter((f) => f.personId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_profilesRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$RegimensTable, List<RegimenRow>>
      _regimensRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.regimens,
              aliasName: 'people__id__regimens__person_id');

  $$RegimensTableProcessedTableManager get regimensRefs {
    final manager = $$RegimensTableTableManager($_db, $_db.regimens)
        .filter((f) => f.personId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_regimensRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$IntakeEntriesTable, List<IntakeEntryRow>>
      _intakeEntriesRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.intakeEntries,
              aliasName: 'people__id__intake_entries__person_id');

  $$IntakeEntriesTableProcessedTableManager get intakeEntriesRefs {
    final manager = $$IntakeEntriesTableTableManager($_db, $_db.intakeEntries)
        .filter((f) => f.personId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_intakeEntriesRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$WorkoutsTable, List<WorkoutRow>>
      _workoutsRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.workouts,
              aliasName: 'people__id__workouts__person_id');

  $$WorkoutsTableProcessedTableManager get workoutsRefs {
    final manager = $$WorkoutsTableTableManager($_db, $_db.workouts)
        .filter((f) => f.personId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_workoutsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$WaterLogsTable, List<WaterLogRow>>
      _waterLogsRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.waterLogs,
              aliasName: 'people__id__water_logs__person_id');

  $$WaterLogsTableProcessedTableManager get waterLogsRefs {
    final manager = $$WaterLogsTableTableManager($_db, $_db.waterLogs)
        .filter((f) => f.personId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_waterLogsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$PeopleTableFilterComposer
    extends Composer<_$AppDatabase, $PeopleTable> {
  $$PeopleTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get displayName => $composableBuilder(
      column: $table.displayName, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isPrimary => $composableBuilder(
      column: $table.isPrimary, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  Expression<bool> profilesRefs(
      Expression<bool> Function($$ProfilesTableFilterComposer f) f) {
    final $$ProfilesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.profiles,
        getReferencedColumn: (t) => t.personId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ProfilesTableFilterComposer(
              $db: $db,
              $table: $db.profiles,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> regimensRefs(
      Expression<bool> Function($$RegimensTableFilterComposer f) f) {
    final $$RegimensTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.regimens,
        getReferencedColumn: (t) => t.personId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$RegimensTableFilterComposer(
              $db: $db,
              $table: $db.regimens,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> intakeEntriesRefs(
      Expression<bool> Function($$IntakeEntriesTableFilterComposer f) f) {
    final $$IntakeEntriesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.intakeEntries,
        getReferencedColumn: (t) => t.personId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$IntakeEntriesTableFilterComposer(
              $db: $db,
              $table: $db.intakeEntries,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> workoutsRefs(
      Expression<bool> Function($$WorkoutsTableFilterComposer f) f) {
    final $$WorkoutsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.workouts,
        getReferencedColumn: (t) => t.personId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$WorkoutsTableFilterComposer(
              $db: $db,
              $table: $db.workouts,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> waterLogsRefs(
      Expression<bool> Function($$WaterLogsTableFilterComposer f) f) {
    final $$WaterLogsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.waterLogs,
        getReferencedColumn: (t) => t.personId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$WaterLogsTableFilterComposer(
              $db: $db,
              $table: $db.waterLogs,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$PeopleTableOrderingComposer
    extends Composer<_$AppDatabase, $PeopleTable> {
  $$PeopleTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get displayName => $composableBuilder(
      column: $table.displayName, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isPrimary => $composableBuilder(
      column: $table.isPrimary, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));
}

class $$PeopleTableAnnotationComposer
    extends Composer<_$AppDatabase, $PeopleTable> {
  $$PeopleTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get displayName => $composableBuilder(
      column: $table.displayName, builder: (column) => column);

  GeneratedColumn<bool> get isPrimary =>
      $composableBuilder(column: $table.isPrimary, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  Expression<T> profilesRefs<T extends Object>(
      Expression<T> Function($$ProfilesTableAnnotationComposer a) f) {
    final $$ProfilesTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.profiles,
        getReferencedColumn: (t) => t.personId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ProfilesTableAnnotationComposer(
              $db: $db,
              $table: $db.profiles,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<T> regimensRefs<T extends Object>(
      Expression<T> Function($$RegimensTableAnnotationComposer a) f) {
    final $$RegimensTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.regimens,
        getReferencedColumn: (t) => t.personId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$RegimensTableAnnotationComposer(
              $db: $db,
              $table: $db.regimens,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<T> intakeEntriesRefs<T extends Object>(
      Expression<T> Function($$IntakeEntriesTableAnnotationComposer a) f) {
    final $$IntakeEntriesTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.intakeEntries,
        getReferencedColumn: (t) => t.personId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$IntakeEntriesTableAnnotationComposer(
              $db: $db,
              $table: $db.intakeEntries,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<T> workoutsRefs<T extends Object>(
      Expression<T> Function($$WorkoutsTableAnnotationComposer a) f) {
    final $$WorkoutsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.workouts,
        getReferencedColumn: (t) => t.personId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$WorkoutsTableAnnotationComposer(
              $db: $db,
              $table: $db.workouts,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<T> waterLogsRefs<T extends Object>(
      Expression<T> Function($$WaterLogsTableAnnotationComposer a) f) {
    final $$WaterLogsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.waterLogs,
        getReferencedColumn: (t) => t.personId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$WaterLogsTableAnnotationComposer(
              $db: $db,
              $table: $db.waterLogs,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$PeopleTableTableManager extends RootTableManager<
    _$AppDatabase,
    $PeopleTable,
    PersonRow,
    $$PeopleTableFilterComposer,
    $$PeopleTableOrderingComposer,
    $$PeopleTableAnnotationComposer,
    $$PeopleTableCreateCompanionBuilder,
    $$PeopleTableUpdateCompanionBuilder,
    (PersonRow, $$PeopleTableReferences),
    PersonRow,
    PrefetchHooks Function(
        {bool profilesRefs,
        bool regimensRefs,
        bool intakeEntriesRefs,
        bool workoutsRefs,
        bool waterLogsRefs})> {
  $$PeopleTableTableManager(_$AppDatabase db, $PeopleTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PeopleTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PeopleTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PeopleTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> displayName = const Value.absent(),
            Value<bool> isPrimary = const Value.absent(),
            Value<int> createdAt = const Value.absent(),
          }) =>
              PeopleCompanion(
            id: id,
            displayName: displayName,
            isPrimary: isPrimary,
            createdAt: createdAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String displayName,
            Value<bool> isPrimary = const Value.absent(),
            required int createdAt,
          }) =>
              PeopleCompanion.insert(
            id: id,
            displayName: displayName,
            isPrimary: isPrimary,
            createdAt: createdAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable<$PeopleTable, PersonRow>(table),
                    $$PeopleTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: (
              {profilesRefs = false,
              regimensRefs = false,
              intakeEntriesRefs = false,
              workoutsRefs = false,
              waterLogsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (profilesRefs) db.profiles,
                if (regimensRefs) db.regimens,
                if (intakeEntriesRefs) db.intakeEntries,
                if (workoutsRefs) db.workouts,
                if (waterLogsRefs) db.waterLogs
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (profilesRefs)
                    await $_getPrefetchedDataByColumns<PersonRow, $PeopleTable,
                            ProfileRow, $ProfilesTable>(
                        currentTable: table,
                        referencedTable:
                            $$PeopleTableReferences._profilesRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$PeopleTableReferences(db, table, p0).profilesRefs,
                        currentColumn: 'id',
                        referencedColumn: 'person_id',
                        typedResults: items),
                  if (regimensRefs)
                    await $_getPrefetchedDataByColumns<PersonRow, $PeopleTable,
                            RegimenRow, $RegimensTable>(
                        currentTable: table,
                        referencedTable:
                            $$PeopleTableReferences._regimensRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$PeopleTableReferences(db, table, p0).regimensRefs,
                        currentColumn: 'id',
                        referencedColumn: 'person_id',
                        typedResults: items),
                  if (intakeEntriesRefs)
                    await $_getPrefetchedDataByColumns<PersonRow, $PeopleTable,
                            IntakeEntryRow, $IntakeEntriesTable>(
                        currentTable: table,
                        referencedTable:
                            $$PeopleTableReferences._intakeEntriesRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$PeopleTableReferences(db, table, p0)
                                .intakeEntriesRefs,
                        currentColumn: 'id',
                        referencedColumn: 'person_id',
                        typedResults: items),
                  if (workoutsRefs)
                    await $_getPrefetchedDataByColumns<PersonRow, $PeopleTable,
                            WorkoutRow, $WorkoutsTable>(
                        currentTable: table,
                        referencedTable:
                            $$PeopleTableReferences._workoutsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$PeopleTableReferences(db, table, p0).workoutsRefs,
                        currentColumn: 'id',
                        referencedColumn: 'person_id',
                        typedResults: items),
                  if (waterLogsRefs)
                    await $_getPrefetchedDataByColumns<PersonRow, $PeopleTable,
                            WaterLogRow, $WaterLogsTable>(
                        currentTable: table,
                        referencedTable:
                            $$PeopleTableReferences._waterLogsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$PeopleTableReferences(db, table, p0)
                                .waterLogsRefs,
                        currentColumn: 'id',
                        referencedColumn: 'person_id',
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$PeopleTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $PeopleTable,
    PersonRow,
    $$PeopleTableFilterComposer,
    $$PeopleTableOrderingComposer,
    $$PeopleTableAnnotationComposer,
    $$PeopleTableCreateCompanionBuilder,
    $$PeopleTableUpdateCompanionBuilder,
    (PersonRow, $$PeopleTableReferences),
    PersonRow,
    PrefetchHooks Function(
        {bool profilesRefs,
        bool regimensRefs,
        bool intakeEntriesRefs,
        bool workoutsRefs,
        bool waterLogsRefs})>;
typedef $$ProfilesTableCreateCompanionBuilder = ProfilesCompanion Function({
  Value<int> personId,
  required int ageYears,
  required Sex sex,
  required double heightCm,
  required double weightKg,
  required LifeStage stage,
  Value<int?> gestationWeek,
  Value<BmiClass?> prePregnancyBmi,
  Value<int?> monthsPostpartum,
  required ActivityLevel activityLevel,
  required int updatedAt,
});
typedef $$ProfilesTableUpdateCompanionBuilder = ProfilesCompanion Function({
  Value<int> personId,
  Value<int> ageYears,
  Value<Sex> sex,
  Value<double> heightCm,
  Value<double> weightKg,
  Value<LifeStage> stage,
  Value<int?> gestationWeek,
  Value<BmiClass?> prePregnancyBmi,
  Value<int?> monthsPostpartum,
  Value<ActivityLevel> activityLevel,
  Value<int> updatedAt,
});

final class $$ProfilesTableReferences
    extends BaseReferences<_$AppDatabase, $ProfilesTable, ProfileRow> {
  $$ProfilesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $PeopleTable _personIdTable(_$AppDatabase db) =>
      db.people.createAlias('profiles__person_id__people__id');

  $$PeopleTableProcessedTableManager get personId {
    final $_column = $_itemColumn<int>('person_id')!;

    final manager = $$PeopleTableTableManager($_db, $_db.people)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_personIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$ProfilesTableFilterComposer
    extends Composer<_$AppDatabase, $ProfilesTable> {
  $$ProfilesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get ageYears => $composableBuilder(
      column: $table.ageYears, builder: (column) => ColumnFilters(column));

  ColumnWithTypeConverterFilters<Sex, Sex, String> get sex =>
      $composableBuilder(
          column: $table.sex,
          builder: (column) => ColumnWithTypeConverterFilters(column));

  ColumnFilters<double> get heightCm => $composableBuilder(
      column: $table.heightCm, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get weightKg => $composableBuilder(
      column: $table.weightKg, builder: (column) => ColumnFilters(column));

  ColumnWithTypeConverterFilters<LifeStage, LifeStage, String> get stage =>
      $composableBuilder(
          column: $table.stage,
          builder: (column) => ColumnWithTypeConverterFilters(column));

  ColumnFilters<int> get gestationWeek => $composableBuilder(
      column: $table.gestationWeek, builder: (column) => ColumnFilters(column));

  ColumnWithTypeConverterFilters<BmiClass?, BmiClass, String>
      get prePregnancyBmi => $composableBuilder(
          column: $table.prePregnancyBmi,
          builder: (column) => ColumnWithTypeConverterFilters(column));

  ColumnFilters<int> get monthsPostpartum => $composableBuilder(
      column: $table.monthsPostpartum,
      builder: (column) => ColumnFilters(column));

  ColumnWithTypeConverterFilters<ActivityLevel, ActivityLevel, String>
      get activityLevel => $composableBuilder(
          column: $table.activityLevel,
          builder: (column) => ColumnWithTypeConverterFilters(column));

  ColumnFilters<int> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  $$PeopleTableFilterComposer get personId {
    final $$PeopleTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.personId,
        referencedTable: $db.people,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$PeopleTableFilterComposer(
              $db: $db,
              $table: $db.people,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$ProfilesTableOrderingComposer
    extends Composer<_$AppDatabase, $ProfilesTable> {
  $$ProfilesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get ageYears => $composableBuilder(
      column: $table.ageYears, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get sex => $composableBuilder(
      column: $table.sex, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get heightCm => $composableBuilder(
      column: $table.heightCm, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get weightKg => $composableBuilder(
      column: $table.weightKg, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get stage => $composableBuilder(
      column: $table.stage, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get gestationWeek => $composableBuilder(
      column: $table.gestationWeek,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get prePregnancyBmi => $composableBuilder(
      column: $table.prePregnancyBmi,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get monthsPostpartum => $composableBuilder(
      column: $table.monthsPostpartum,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get activityLevel => $composableBuilder(
      column: $table.activityLevel,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  $$PeopleTableOrderingComposer get personId {
    final $$PeopleTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.personId,
        referencedTable: $db.people,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$PeopleTableOrderingComposer(
              $db: $db,
              $table: $db.people,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$ProfilesTableAnnotationComposer
    extends Composer<_$AppDatabase, $ProfilesTable> {
  $$ProfilesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get ageYears =>
      $composableBuilder(column: $table.ageYears, builder: (column) => column);

  GeneratedColumnWithTypeConverter<Sex, String> get sex =>
      $composableBuilder(column: $table.sex, builder: (column) => column);

  GeneratedColumn<double> get heightCm =>
      $composableBuilder(column: $table.heightCm, builder: (column) => column);

  GeneratedColumn<double> get weightKg =>
      $composableBuilder(column: $table.weightKg, builder: (column) => column);

  GeneratedColumnWithTypeConverter<LifeStage, String> get stage =>
      $composableBuilder(column: $table.stage, builder: (column) => column);

  GeneratedColumn<int> get gestationWeek => $composableBuilder(
      column: $table.gestationWeek, builder: (column) => column);

  GeneratedColumnWithTypeConverter<BmiClass?, String> get prePregnancyBmi =>
      $composableBuilder(
          column: $table.prePregnancyBmi, builder: (column) => column);

  GeneratedColumn<int> get monthsPostpartum => $composableBuilder(
      column: $table.monthsPostpartum, builder: (column) => column);

  GeneratedColumnWithTypeConverter<ActivityLevel, String> get activityLevel =>
      $composableBuilder(
          column: $table.activityLevel, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$PeopleTableAnnotationComposer get personId {
    final $$PeopleTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.personId,
        referencedTable: $db.people,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$PeopleTableAnnotationComposer(
              $db: $db,
              $table: $db.people,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$ProfilesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $ProfilesTable,
    ProfileRow,
    $$ProfilesTableFilterComposer,
    $$ProfilesTableOrderingComposer,
    $$ProfilesTableAnnotationComposer,
    $$ProfilesTableCreateCompanionBuilder,
    $$ProfilesTableUpdateCompanionBuilder,
    (ProfileRow, $$ProfilesTableReferences),
    ProfileRow,
    PrefetchHooks Function({bool personId})> {
  $$ProfilesTableTableManager(_$AppDatabase db, $ProfilesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ProfilesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ProfilesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ProfilesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> personId = const Value.absent(),
            Value<int> ageYears = const Value.absent(),
            Value<Sex> sex = const Value.absent(),
            Value<double> heightCm = const Value.absent(),
            Value<double> weightKg = const Value.absent(),
            Value<LifeStage> stage = const Value.absent(),
            Value<int?> gestationWeek = const Value.absent(),
            Value<BmiClass?> prePregnancyBmi = const Value.absent(),
            Value<int?> monthsPostpartum = const Value.absent(),
            Value<ActivityLevel> activityLevel = const Value.absent(),
            Value<int> updatedAt = const Value.absent(),
          }) =>
              ProfilesCompanion(
            personId: personId,
            ageYears: ageYears,
            sex: sex,
            heightCm: heightCm,
            weightKg: weightKg,
            stage: stage,
            gestationWeek: gestationWeek,
            prePregnancyBmi: prePregnancyBmi,
            monthsPostpartum: monthsPostpartum,
            activityLevel: activityLevel,
            updatedAt: updatedAt,
          ),
          createCompanionCallback: ({
            Value<int> personId = const Value.absent(),
            required int ageYears,
            required Sex sex,
            required double heightCm,
            required double weightKg,
            required LifeStage stage,
            Value<int?> gestationWeek = const Value.absent(),
            Value<BmiClass?> prePregnancyBmi = const Value.absent(),
            Value<int?> monthsPostpartum = const Value.absent(),
            required ActivityLevel activityLevel,
            required int updatedAt,
          }) =>
              ProfilesCompanion.insert(
            personId: personId,
            ageYears: ageYears,
            sex: sex,
            heightCm: heightCm,
            weightKg: weightKg,
            stage: stage,
            gestationWeek: gestationWeek,
            prePregnancyBmi: prePregnancyBmi,
            monthsPostpartum: monthsPostpartum,
            activityLevel: activityLevel,
            updatedAt: updatedAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable<$ProfilesTable, ProfileRow>(table),
                    $$ProfilesTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({personId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (personId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.personId,
                    referencedTable:
                        $$ProfilesTableReferences._personIdTable(db),
                    referencedColumn:
                        $$ProfilesTableReferences._personIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$ProfilesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $ProfilesTable,
    ProfileRow,
    $$ProfilesTableFilterComposer,
    $$ProfilesTableOrderingComposer,
    $$ProfilesTableAnnotationComposer,
    $$ProfilesTableCreateCompanionBuilder,
    $$ProfilesTableUpdateCompanionBuilder,
    (ProfileRow, $$ProfilesTableReferences),
    ProfileRow,
    PrefetchHooks Function({bool personId})>;
typedef $$SettingsTableCreateCompanionBuilder = SettingsCompanion Function({
  required String key,
  required String value,
  Value<int> rowid,
});
typedef $$SettingsTableUpdateCompanionBuilder = SettingsCompanion Function({
  Value<String> key,
  Value<String> value,
  Value<int> rowid,
});

class $$SettingsTableFilterComposer
    extends Composer<_$AppDatabase, $SettingsTable> {
  $$SettingsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
      column: $table.key, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get value => $composableBuilder(
      column: $table.value, builder: (column) => ColumnFilters(column));
}

class $$SettingsTableOrderingComposer
    extends Composer<_$AppDatabase, $SettingsTable> {
  $$SettingsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
      column: $table.key, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get value => $composableBuilder(
      column: $table.value, builder: (column) => ColumnOrderings(column));
}

class $$SettingsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SettingsTable> {
  $$SettingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);
}

class $$SettingsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $SettingsTable,
    SettingRow,
    $$SettingsTableFilterComposer,
    $$SettingsTableOrderingComposer,
    $$SettingsTableAnnotationComposer,
    $$SettingsTableCreateCompanionBuilder,
    $$SettingsTableUpdateCompanionBuilder,
    (SettingRow, BaseReferences<_$AppDatabase, $SettingsTable, SettingRow>),
    SettingRow,
    PrefetchHooks Function()> {
  $$SettingsTableTableManager(_$AppDatabase db, $SettingsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SettingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SettingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SettingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> key = const Value.absent(),
            Value<String> value = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              SettingsCompanion(
            key: key,
            value: value,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String key,
            required String value,
            Value<int> rowid = const Value.absent(),
          }) =>
              SettingsCompanion.insert(
            key: key,
            value: value,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable<$SettingsTable, SettingRow>(table),
                    BaseReferences<_$AppDatabase, $SettingsTable, SettingRow>(
                        db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$SettingsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $SettingsTable,
    SettingRow,
    $$SettingsTableFilterComposer,
    $$SettingsTableOrderingComposer,
    $$SettingsTableAnnotationComposer,
    $$SettingsTableCreateCompanionBuilder,
    $$SettingsTableUpdateCompanionBuilder,
    (SettingRow, BaseReferences<_$AppDatabase, $SettingsTable, SettingRow>),
    SettingRow,
    PrefetchHooks Function()>;
typedef $$ProductsTableCreateCompanionBuilder = ProductsCompanion Function({
  Value<int> id,
  required String shortName,
  Value<String?> fullName,
  required String dosageForm,
  required double unitsPerServing,
  Value<double?> servingsPerContainer,
  Value<String?> barcode,
  Value<String?> labelPhotoPath,
  Value<bool> confirmed,
  required int createdAt,
});
typedef $$ProductsTableUpdateCompanionBuilder = ProductsCompanion Function({
  Value<int> id,
  Value<String> shortName,
  Value<String?> fullName,
  Value<String> dosageForm,
  Value<double> unitsPerServing,
  Value<double?> servingsPerContainer,
  Value<String?> barcode,
  Value<String?> labelPhotoPath,
  Value<bool> confirmed,
  Value<int> createdAt,
});

final class $$ProductsTableReferences
    extends BaseReferences<_$AppDatabase, $ProductsTable, ProductRow> {
  $$ProductsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$ProductNutrientsTable, List<ProductNutrientRow>>
      _productNutrientsRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.productNutrients,
              aliasName: 'products__id__product_nutrients__product_id');

  $$ProductNutrientsTableProcessedTableManager get productNutrientsRefs {
    final manager =
        $$ProductNutrientsTableTableManager($_db, $_db.productNutrients)
            .filter((f) => f.productId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache =
        $_typedResult.readTableOrNull(_productNutrientsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$InventoryBoxesTable, List<InventoryBoxRow>>
      _inventoryBoxesRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.inventoryBoxes,
              aliasName: 'products__id__inventory_boxes__product_id');

  $$InventoryBoxesTableProcessedTableManager get inventoryBoxesRefs {
    final manager = $$InventoryBoxesTableTableManager($_db, $_db.inventoryBoxes)
        .filter((f) => f.productId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_inventoryBoxesRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$RegimensTable, List<RegimenRow>>
      _regimensRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.regimens,
              aliasName: 'products__id__regimens__product_id');

  $$RegimensTableProcessedTableManager get regimensRefs {
    final manager = $$RegimensTableTableManager($_db, $_db.regimens)
        .filter((f) => f.productId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_regimensRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$IntakeEntriesTable, List<IntakeEntryRow>>
      _intakeEntriesRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.intakeEntries,
              aliasName: 'products__id__intake_entries__product_id');

  $$IntakeEntriesTableProcessedTableManager get intakeEntriesRefs {
    final manager = $$IntakeEntriesTableTableManager($_db, $_db.intakeEntries)
        .filter((f) => f.productId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_intakeEntriesRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$ProductsTableFilterComposer
    extends Composer<_$AppDatabase, $ProductsTable> {
  $$ProductsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get shortName => $composableBuilder(
      column: $table.shortName, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get fullName => $composableBuilder(
      column: $table.fullName, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get dosageForm => $composableBuilder(
      column: $table.dosageForm, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get unitsPerServing => $composableBuilder(
      column: $table.unitsPerServing,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get servingsPerContainer => $composableBuilder(
      column: $table.servingsPerContainer,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get barcode => $composableBuilder(
      column: $table.barcode, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get labelPhotoPath => $composableBuilder(
      column: $table.labelPhotoPath,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get confirmed => $composableBuilder(
      column: $table.confirmed, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  Expression<bool> productNutrientsRefs(
      Expression<bool> Function($$ProductNutrientsTableFilterComposer f) f) {
    final $$ProductNutrientsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.productNutrients,
        getReferencedColumn: (t) => t.productId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ProductNutrientsTableFilterComposer(
              $db: $db,
              $table: $db.productNutrients,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> inventoryBoxesRefs(
      Expression<bool> Function($$InventoryBoxesTableFilterComposer f) f) {
    final $$InventoryBoxesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.inventoryBoxes,
        getReferencedColumn: (t) => t.productId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$InventoryBoxesTableFilterComposer(
              $db: $db,
              $table: $db.inventoryBoxes,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> regimensRefs(
      Expression<bool> Function($$RegimensTableFilterComposer f) f) {
    final $$RegimensTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.regimens,
        getReferencedColumn: (t) => t.productId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$RegimensTableFilterComposer(
              $db: $db,
              $table: $db.regimens,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> intakeEntriesRefs(
      Expression<bool> Function($$IntakeEntriesTableFilterComposer f) f) {
    final $$IntakeEntriesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.intakeEntries,
        getReferencedColumn: (t) => t.productId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$IntakeEntriesTableFilterComposer(
              $db: $db,
              $table: $db.intakeEntries,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$ProductsTableOrderingComposer
    extends Composer<_$AppDatabase, $ProductsTable> {
  $$ProductsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get shortName => $composableBuilder(
      column: $table.shortName, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get fullName => $composableBuilder(
      column: $table.fullName, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get dosageForm => $composableBuilder(
      column: $table.dosageForm, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get unitsPerServing => $composableBuilder(
      column: $table.unitsPerServing,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get servingsPerContainer => $composableBuilder(
      column: $table.servingsPerContainer,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get barcode => $composableBuilder(
      column: $table.barcode, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get labelPhotoPath => $composableBuilder(
      column: $table.labelPhotoPath,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get confirmed => $composableBuilder(
      column: $table.confirmed, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));
}

class $$ProductsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ProductsTable> {
  $$ProductsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get shortName =>
      $composableBuilder(column: $table.shortName, builder: (column) => column);

  GeneratedColumn<String> get fullName =>
      $composableBuilder(column: $table.fullName, builder: (column) => column);

  GeneratedColumn<String> get dosageForm => $composableBuilder(
      column: $table.dosageForm, builder: (column) => column);

  GeneratedColumn<double> get unitsPerServing => $composableBuilder(
      column: $table.unitsPerServing, builder: (column) => column);

  GeneratedColumn<double> get servingsPerContainer => $composableBuilder(
      column: $table.servingsPerContainer, builder: (column) => column);

  GeneratedColumn<String> get barcode =>
      $composableBuilder(column: $table.barcode, builder: (column) => column);

  GeneratedColumn<String> get labelPhotoPath => $composableBuilder(
      column: $table.labelPhotoPath, builder: (column) => column);

  GeneratedColumn<bool> get confirmed =>
      $composableBuilder(column: $table.confirmed, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  Expression<T> productNutrientsRefs<T extends Object>(
      Expression<T> Function($$ProductNutrientsTableAnnotationComposer a) f) {
    final $$ProductNutrientsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.productNutrients,
        getReferencedColumn: (t) => t.productId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ProductNutrientsTableAnnotationComposer(
              $db: $db,
              $table: $db.productNutrients,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<T> inventoryBoxesRefs<T extends Object>(
      Expression<T> Function($$InventoryBoxesTableAnnotationComposer a) f) {
    final $$InventoryBoxesTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.inventoryBoxes,
        getReferencedColumn: (t) => t.productId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$InventoryBoxesTableAnnotationComposer(
              $db: $db,
              $table: $db.inventoryBoxes,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<T> regimensRefs<T extends Object>(
      Expression<T> Function($$RegimensTableAnnotationComposer a) f) {
    final $$RegimensTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.regimens,
        getReferencedColumn: (t) => t.productId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$RegimensTableAnnotationComposer(
              $db: $db,
              $table: $db.regimens,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<T> intakeEntriesRefs<T extends Object>(
      Expression<T> Function($$IntakeEntriesTableAnnotationComposer a) f) {
    final $$IntakeEntriesTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.intakeEntries,
        getReferencedColumn: (t) => t.productId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$IntakeEntriesTableAnnotationComposer(
              $db: $db,
              $table: $db.intakeEntries,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$ProductsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $ProductsTable,
    ProductRow,
    $$ProductsTableFilterComposer,
    $$ProductsTableOrderingComposer,
    $$ProductsTableAnnotationComposer,
    $$ProductsTableCreateCompanionBuilder,
    $$ProductsTableUpdateCompanionBuilder,
    (ProductRow, $$ProductsTableReferences),
    ProductRow,
    PrefetchHooks Function(
        {bool productNutrientsRefs,
        bool inventoryBoxesRefs,
        bool regimensRefs,
        bool intakeEntriesRefs})> {
  $$ProductsTableTableManager(_$AppDatabase db, $ProductsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ProductsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ProductsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ProductsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> shortName = const Value.absent(),
            Value<String?> fullName = const Value.absent(),
            Value<String> dosageForm = const Value.absent(),
            Value<double> unitsPerServing = const Value.absent(),
            Value<double?> servingsPerContainer = const Value.absent(),
            Value<String?> barcode = const Value.absent(),
            Value<String?> labelPhotoPath = const Value.absent(),
            Value<bool> confirmed = const Value.absent(),
            Value<int> createdAt = const Value.absent(),
          }) =>
              ProductsCompanion(
            id: id,
            shortName: shortName,
            fullName: fullName,
            dosageForm: dosageForm,
            unitsPerServing: unitsPerServing,
            servingsPerContainer: servingsPerContainer,
            barcode: barcode,
            labelPhotoPath: labelPhotoPath,
            confirmed: confirmed,
            createdAt: createdAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String shortName,
            Value<String?> fullName = const Value.absent(),
            required String dosageForm,
            required double unitsPerServing,
            Value<double?> servingsPerContainer = const Value.absent(),
            Value<String?> barcode = const Value.absent(),
            Value<String?> labelPhotoPath = const Value.absent(),
            Value<bool> confirmed = const Value.absent(),
            required int createdAt,
          }) =>
              ProductsCompanion.insert(
            id: id,
            shortName: shortName,
            fullName: fullName,
            dosageForm: dosageForm,
            unitsPerServing: unitsPerServing,
            servingsPerContainer: servingsPerContainer,
            barcode: barcode,
            labelPhotoPath: labelPhotoPath,
            confirmed: confirmed,
            createdAt: createdAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable<$ProductsTable, ProductRow>(table),
                    $$ProductsTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: (
              {productNutrientsRefs = false,
              inventoryBoxesRefs = false,
              regimensRefs = false,
              intakeEntriesRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (productNutrientsRefs) db.productNutrients,
                if (inventoryBoxesRefs) db.inventoryBoxes,
                if (regimensRefs) db.regimens,
                if (intakeEntriesRefs) db.intakeEntries
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (productNutrientsRefs)
                    await $_getPrefetchedDataByColumns<
                            ProductRow,
                            $ProductsTable,
                            ProductNutrientRow,
                            $ProductNutrientsTable>(
                        currentTable: table,
                        referencedTable: $$ProductsTableReferences
                            ._productNutrientsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$ProductsTableReferences(db, table, p0)
                                .productNutrientsRefs,
                        currentColumn: 'id',
                        referencedColumn: 'product_id',
                        typedResults: items),
                  if (inventoryBoxesRefs)
                    await $_getPrefetchedDataByColumns<
                            ProductRow,
                            $ProductsTable,
                            InventoryBoxRow,
                            $InventoryBoxesTable>(
                        currentTable: table,
                        referencedTable: $$ProductsTableReferences
                            ._inventoryBoxesRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$ProductsTableReferences(db, table, p0)
                                .inventoryBoxesRefs,
                        currentColumn: 'id',
                        referencedColumn: 'product_id',
                        typedResults: items),
                  if (regimensRefs)
                    await $_getPrefetchedDataByColumns<ProductRow,
                            $ProductsTable, RegimenRow, $RegimensTable>(
                        currentTable: table,
                        referencedTable:
                            $$ProductsTableReferences._regimensRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$ProductsTableReferences(db, table, p0)
                                .regimensRefs,
                        currentColumn: 'id',
                        referencedColumn: 'product_id',
                        typedResults: items),
                  if (intakeEntriesRefs)
                    await $_getPrefetchedDataByColumns<
                            ProductRow,
                            $ProductsTable,
                            IntakeEntryRow,
                            $IntakeEntriesTable>(
                        currentTable: table,
                        referencedTable: $$ProductsTableReferences
                            ._intakeEntriesRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$ProductsTableReferences(db, table, p0)
                                .intakeEntriesRefs,
                        currentColumn: 'id',
                        referencedColumn: 'product_id',
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$ProductsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $ProductsTable,
    ProductRow,
    $$ProductsTableFilterComposer,
    $$ProductsTableOrderingComposer,
    $$ProductsTableAnnotationComposer,
    $$ProductsTableCreateCompanionBuilder,
    $$ProductsTableUpdateCompanionBuilder,
    (ProductRow, $$ProductsTableReferences),
    ProductRow,
    PrefetchHooks Function(
        {bool productNutrientsRefs,
        bool inventoryBoxesRefs,
        bool regimensRefs,
        bool intakeEntriesRefs})>;
typedef $$ProductNutrientsTableCreateCompanionBuilder
    = ProductNutrientsCompanion Function({
  required int productId,
  required String nutrientId,
  Value<String> chemicalForm,
  required double amountPerServing,
  required String unit,
  required ProductNutrientSource source,
  Value<int> rowid,
});
typedef $$ProductNutrientsTableUpdateCompanionBuilder
    = ProductNutrientsCompanion Function({
  Value<int> productId,
  Value<String> nutrientId,
  Value<String> chemicalForm,
  Value<double> amountPerServing,
  Value<String> unit,
  Value<ProductNutrientSource> source,
  Value<int> rowid,
});

final class $$ProductNutrientsTableReferences extends BaseReferences<
    _$AppDatabase, $ProductNutrientsTable, ProductNutrientRow> {
  $$ProductNutrientsTableReferences(
      super.$_db, super.$_table, super.$_typedResult);

  static $ProductsTable _productIdTable(_$AppDatabase db) =>
      db.products.createAlias('product_nutrients__product_id__products__id');

  $$ProductsTableProcessedTableManager get productId {
    final $_column = $_itemColumn<int>('product_id')!;

    final manager = $$ProductsTableTableManager($_db, $_db.products)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_productIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$ProductNutrientsTableFilterComposer
    extends Composer<_$AppDatabase, $ProductNutrientsTable> {
  $$ProductNutrientsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get nutrientId => $composableBuilder(
      column: $table.nutrientId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get chemicalForm => $composableBuilder(
      column: $table.chemicalForm, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get amountPerServing => $composableBuilder(
      column: $table.amountPerServing,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get unit => $composableBuilder(
      column: $table.unit, builder: (column) => ColumnFilters(column));

  ColumnWithTypeConverterFilters<ProductNutrientSource, ProductNutrientSource,
          String>
      get source => $composableBuilder(
          column: $table.source,
          builder: (column) => ColumnWithTypeConverterFilters(column));

  $$ProductsTableFilterComposer get productId {
    final $$ProductsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.productId,
        referencedTable: $db.products,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ProductsTableFilterComposer(
              $db: $db,
              $table: $db.products,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$ProductNutrientsTableOrderingComposer
    extends Composer<_$AppDatabase, $ProductNutrientsTable> {
  $$ProductNutrientsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get nutrientId => $composableBuilder(
      column: $table.nutrientId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get chemicalForm => $composableBuilder(
      column: $table.chemicalForm,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get amountPerServing => $composableBuilder(
      column: $table.amountPerServing,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get unit => $composableBuilder(
      column: $table.unit, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get source => $composableBuilder(
      column: $table.source, builder: (column) => ColumnOrderings(column));

  $$ProductsTableOrderingComposer get productId {
    final $$ProductsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.productId,
        referencedTable: $db.products,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ProductsTableOrderingComposer(
              $db: $db,
              $table: $db.products,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$ProductNutrientsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ProductNutrientsTable> {
  $$ProductNutrientsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get nutrientId => $composableBuilder(
      column: $table.nutrientId, builder: (column) => column);

  GeneratedColumn<String> get chemicalForm => $composableBuilder(
      column: $table.chemicalForm, builder: (column) => column);

  GeneratedColumn<double> get amountPerServing => $composableBuilder(
      column: $table.amountPerServing, builder: (column) => column);

  GeneratedColumn<String> get unit =>
      $composableBuilder(column: $table.unit, builder: (column) => column);

  GeneratedColumnWithTypeConverter<ProductNutrientSource, String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);

  $$ProductsTableAnnotationComposer get productId {
    final $$ProductsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.productId,
        referencedTable: $db.products,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ProductsTableAnnotationComposer(
              $db: $db,
              $table: $db.products,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$ProductNutrientsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $ProductNutrientsTable,
    ProductNutrientRow,
    $$ProductNutrientsTableFilterComposer,
    $$ProductNutrientsTableOrderingComposer,
    $$ProductNutrientsTableAnnotationComposer,
    $$ProductNutrientsTableCreateCompanionBuilder,
    $$ProductNutrientsTableUpdateCompanionBuilder,
    (ProductNutrientRow, $$ProductNutrientsTableReferences),
    ProductNutrientRow,
    PrefetchHooks Function({bool productId})> {
  $$ProductNutrientsTableTableManager(
      _$AppDatabase db, $ProductNutrientsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ProductNutrientsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ProductNutrientsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ProductNutrientsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> productId = const Value.absent(),
            Value<String> nutrientId = const Value.absent(),
            Value<String> chemicalForm = const Value.absent(),
            Value<double> amountPerServing = const Value.absent(),
            Value<String> unit = const Value.absent(),
            Value<ProductNutrientSource> source = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ProductNutrientsCompanion(
            productId: productId,
            nutrientId: nutrientId,
            chemicalForm: chemicalForm,
            amountPerServing: amountPerServing,
            unit: unit,
            source: source,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required int productId,
            required String nutrientId,
            Value<String> chemicalForm = const Value.absent(),
            required double amountPerServing,
            required String unit,
            required ProductNutrientSource source,
            Value<int> rowid = const Value.absent(),
          }) =>
              ProductNutrientsCompanion.insert(
            productId: productId,
            nutrientId: nutrientId,
            chemicalForm: chemicalForm,
            amountPerServing: amountPerServing,
            unit: unit,
            source: source,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable<$ProductNutrientsTable, ProductNutrientRow>(
                        table),
                    $$ProductNutrientsTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({productId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (productId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.productId,
                    referencedTable:
                        $$ProductNutrientsTableReferences._productIdTable(db),
                    referencedColumn: $$ProductNutrientsTableReferences
                        ._productIdTable(db)
                        .id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$ProductNutrientsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $ProductNutrientsTable,
    ProductNutrientRow,
    $$ProductNutrientsTableFilterComposer,
    $$ProductNutrientsTableOrderingComposer,
    $$ProductNutrientsTableAnnotationComposer,
    $$ProductNutrientsTableCreateCompanionBuilder,
    $$ProductNutrientsTableUpdateCompanionBuilder,
    (ProductNutrientRow, $$ProductNutrientsTableReferences),
    ProductNutrientRow,
    PrefetchHooks Function({bool productId})>;
typedef $$InventoryBoxesTableCreateCompanionBuilder = InventoryBoxesCompanion
    Function({
  Value<int> id,
  required int productId,
  required double unitsRemaining,
  Value<String?> openedOn,
  Value<String?> expiresOn,
  Value<bool> discarded,
  required int createdAt,
});
typedef $$InventoryBoxesTableUpdateCompanionBuilder = InventoryBoxesCompanion
    Function({
  Value<int> id,
  Value<int> productId,
  Value<double> unitsRemaining,
  Value<String?> openedOn,
  Value<String?> expiresOn,
  Value<bool> discarded,
  Value<int> createdAt,
});

final class $$InventoryBoxesTableReferences extends BaseReferences<
    _$AppDatabase, $InventoryBoxesTable, InventoryBoxRow> {
  $$InventoryBoxesTableReferences(
      super.$_db, super.$_table, super.$_typedResult);

  static $ProductsTable _productIdTable(_$AppDatabase db) =>
      db.products.createAlias('inventory_boxes__product_id__products__id');

  $$ProductsTableProcessedTableManager get productId {
    final $_column = $_itemColumn<int>('product_id')!;

    final manager = $$ProductsTableTableManager($_db, $_db.products)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_productIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static MultiTypedResultKey<$DoseLogsTable, List<DoseLogRow>>
      _doseLogsRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.doseLogs,
              aliasName: 'inventory_boxes__id__dose_logs__box_id');

  $$DoseLogsTableProcessedTableManager get doseLogsRefs {
    final manager = $$DoseLogsTableTableManager($_db, $_db.doseLogs)
        .filter((f) => f.boxId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_doseLogsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$InventoryBoxesTableFilterComposer
    extends Composer<_$AppDatabase, $InventoryBoxesTable> {
  $$InventoryBoxesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get unitsRemaining => $composableBuilder(
      column: $table.unitsRemaining,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get openedOn => $composableBuilder(
      column: $table.openedOn, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get expiresOn => $composableBuilder(
      column: $table.expiresOn, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get discarded => $composableBuilder(
      column: $table.discarded, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  $$ProductsTableFilterComposer get productId {
    final $$ProductsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.productId,
        referencedTable: $db.products,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ProductsTableFilterComposer(
              $db: $db,
              $table: $db.products,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  Expression<bool> doseLogsRefs(
      Expression<bool> Function($$DoseLogsTableFilterComposer f) f) {
    final $$DoseLogsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.doseLogs,
        getReferencedColumn: (t) => t.boxId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$DoseLogsTableFilterComposer(
              $db: $db,
              $table: $db.doseLogs,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$InventoryBoxesTableOrderingComposer
    extends Composer<_$AppDatabase, $InventoryBoxesTable> {
  $$InventoryBoxesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get unitsRemaining => $composableBuilder(
      column: $table.unitsRemaining,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get openedOn => $composableBuilder(
      column: $table.openedOn, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get expiresOn => $composableBuilder(
      column: $table.expiresOn, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get discarded => $composableBuilder(
      column: $table.discarded, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  $$ProductsTableOrderingComposer get productId {
    final $$ProductsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.productId,
        referencedTable: $db.products,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ProductsTableOrderingComposer(
              $db: $db,
              $table: $db.products,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$InventoryBoxesTableAnnotationComposer
    extends Composer<_$AppDatabase, $InventoryBoxesTable> {
  $$InventoryBoxesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<double> get unitsRemaining => $composableBuilder(
      column: $table.unitsRemaining, builder: (column) => column);

  GeneratedColumn<String> get openedOn =>
      $composableBuilder(column: $table.openedOn, builder: (column) => column);

  GeneratedColumn<String> get expiresOn =>
      $composableBuilder(column: $table.expiresOn, builder: (column) => column);

  GeneratedColumn<bool> get discarded =>
      $composableBuilder(column: $table.discarded, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$ProductsTableAnnotationComposer get productId {
    final $$ProductsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.productId,
        referencedTable: $db.products,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ProductsTableAnnotationComposer(
              $db: $db,
              $table: $db.products,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  Expression<T> doseLogsRefs<T extends Object>(
      Expression<T> Function($$DoseLogsTableAnnotationComposer a) f) {
    final $$DoseLogsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.doseLogs,
        getReferencedColumn: (t) => t.boxId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$DoseLogsTableAnnotationComposer(
              $db: $db,
              $table: $db.doseLogs,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$InventoryBoxesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $InventoryBoxesTable,
    InventoryBoxRow,
    $$InventoryBoxesTableFilterComposer,
    $$InventoryBoxesTableOrderingComposer,
    $$InventoryBoxesTableAnnotationComposer,
    $$InventoryBoxesTableCreateCompanionBuilder,
    $$InventoryBoxesTableUpdateCompanionBuilder,
    (InventoryBoxRow, $$InventoryBoxesTableReferences),
    InventoryBoxRow,
    PrefetchHooks Function({bool productId, bool doseLogsRefs})> {
  $$InventoryBoxesTableTableManager(
      _$AppDatabase db, $InventoryBoxesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$InventoryBoxesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$InventoryBoxesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$InventoryBoxesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int> productId = const Value.absent(),
            Value<double> unitsRemaining = const Value.absent(),
            Value<String?> openedOn = const Value.absent(),
            Value<String?> expiresOn = const Value.absent(),
            Value<bool> discarded = const Value.absent(),
            Value<int> createdAt = const Value.absent(),
          }) =>
              InventoryBoxesCompanion(
            id: id,
            productId: productId,
            unitsRemaining: unitsRemaining,
            openedOn: openedOn,
            expiresOn: expiresOn,
            discarded: discarded,
            createdAt: createdAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required int productId,
            required double unitsRemaining,
            Value<String?> openedOn = const Value.absent(),
            Value<String?> expiresOn = const Value.absent(),
            Value<bool> discarded = const Value.absent(),
            required int createdAt,
          }) =>
              InventoryBoxesCompanion.insert(
            id: id,
            productId: productId,
            unitsRemaining: unitsRemaining,
            openedOn: openedOn,
            expiresOn: expiresOn,
            discarded: discarded,
            createdAt: createdAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable<$InventoryBoxesTable, InventoryBoxRow>(table),
                    $$InventoryBoxesTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({productId = false, doseLogsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (doseLogsRefs) db.doseLogs],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (productId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.productId,
                    referencedTable:
                        $$InventoryBoxesTableReferences._productIdTable(db),
                    referencedColumn:
                        $$InventoryBoxesTableReferences._productIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [
                  if (doseLogsRefs)
                    await $_getPrefetchedDataByColumns<InventoryBoxRow,
                            $InventoryBoxesTable, DoseLogRow, $DoseLogsTable>(
                        currentTable: table,
                        referencedTable: $$InventoryBoxesTableReferences
                            ._doseLogsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$InventoryBoxesTableReferences(db, table, p0)
                                .doseLogsRefs,
                        currentColumn: 'id',
                        referencedColumn: 'box_id',
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$InventoryBoxesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $InventoryBoxesTable,
    InventoryBoxRow,
    $$InventoryBoxesTableFilterComposer,
    $$InventoryBoxesTableOrderingComposer,
    $$InventoryBoxesTableAnnotationComposer,
    $$InventoryBoxesTableCreateCompanionBuilder,
    $$InventoryBoxesTableUpdateCompanionBuilder,
    (InventoryBoxRow, $$InventoryBoxesTableReferences),
    InventoryBoxRow,
    PrefetchHooks Function({bool productId, bool doseLogsRefs})>;
typedef $$RegimensTableCreateCompanionBuilder = RegimensCompanion Function({
  Value<int> id,
  required int personId,
  required RegimenKind kind,
  Value<int?> productId,
  Value<double?> unitsPerDose,
  Value<double?> waterMl,
  required int minuteOfDay,
  Value<bool> withMeal,
  Value<int> weekdays,
  Value<int> remindRepeat,
  Value<int> remindIntervalMin,
  Value<bool> active,
  required int createdAt,
});
typedef $$RegimensTableUpdateCompanionBuilder = RegimensCompanion Function({
  Value<int> id,
  Value<int> personId,
  Value<RegimenKind> kind,
  Value<int?> productId,
  Value<double?> unitsPerDose,
  Value<double?> waterMl,
  Value<int> minuteOfDay,
  Value<bool> withMeal,
  Value<int> weekdays,
  Value<int> remindRepeat,
  Value<int> remindIntervalMin,
  Value<bool> active,
  Value<int> createdAt,
});

final class $$RegimensTableReferences
    extends BaseReferences<_$AppDatabase, $RegimensTable, RegimenRow> {
  $$RegimensTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $PeopleTable _personIdTable(_$AppDatabase db) =>
      db.people.createAlias('regimens__person_id__people__id');

  $$PeopleTableProcessedTableManager get personId {
    final $_column = $_itemColumn<int>('person_id')!;

    final manager = $$PeopleTableTableManager($_db, $_db.people)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_personIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static $ProductsTable _productIdTable(_$AppDatabase db) =>
      db.products.createAlias('regimens__product_id__products__id');

  $$ProductsTableProcessedTableManager? get productId {
    final $_column = $_itemColumn<int>('product_id');
    if ($_column == null) return null;
    final manager = $$ProductsTableTableManager($_db, $_db.products)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_productIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static MultiTypedResultKey<$DoseLogsTable, List<DoseLogRow>>
      _doseLogsRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.doseLogs,
              aliasName: 'regimens__id__dose_logs__regimen_id');

  $$DoseLogsTableProcessedTableManager get doseLogsRefs {
    final manager = $$DoseLogsTableTableManager($_db, $_db.doseLogs)
        .filter((f) => f.regimenId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_doseLogsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$RegimensTableFilterComposer
    extends Composer<_$AppDatabase, $RegimensTable> {
  $$RegimensTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnWithTypeConverterFilters<RegimenKind, RegimenKind, String> get kind =>
      $composableBuilder(
          column: $table.kind,
          builder: (column) => ColumnWithTypeConverterFilters(column));

  ColumnFilters<double> get unitsPerDose => $composableBuilder(
      column: $table.unitsPerDose, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get waterMl => $composableBuilder(
      column: $table.waterMl, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get minuteOfDay => $composableBuilder(
      column: $table.minuteOfDay, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get withMeal => $composableBuilder(
      column: $table.withMeal, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get weekdays => $composableBuilder(
      column: $table.weekdays, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get remindRepeat => $composableBuilder(
      column: $table.remindRepeat, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get remindIntervalMin => $composableBuilder(
      column: $table.remindIntervalMin,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get active => $composableBuilder(
      column: $table.active, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  $$PeopleTableFilterComposer get personId {
    final $$PeopleTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.personId,
        referencedTable: $db.people,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$PeopleTableFilterComposer(
              $db: $db,
              $table: $db.people,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$ProductsTableFilterComposer get productId {
    final $$ProductsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.productId,
        referencedTable: $db.products,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ProductsTableFilterComposer(
              $db: $db,
              $table: $db.products,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  Expression<bool> doseLogsRefs(
      Expression<bool> Function($$DoseLogsTableFilterComposer f) f) {
    final $$DoseLogsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.doseLogs,
        getReferencedColumn: (t) => t.regimenId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$DoseLogsTableFilterComposer(
              $db: $db,
              $table: $db.doseLogs,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$RegimensTableOrderingComposer
    extends Composer<_$AppDatabase, $RegimensTable> {
  $$RegimensTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get kind => $composableBuilder(
      column: $table.kind, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get unitsPerDose => $composableBuilder(
      column: $table.unitsPerDose,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get waterMl => $composableBuilder(
      column: $table.waterMl, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get minuteOfDay => $composableBuilder(
      column: $table.minuteOfDay, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get withMeal => $composableBuilder(
      column: $table.withMeal, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get weekdays => $composableBuilder(
      column: $table.weekdays, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get remindRepeat => $composableBuilder(
      column: $table.remindRepeat,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get remindIntervalMin => $composableBuilder(
      column: $table.remindIntervalMin,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get active => $composableBuilder(
      column: $table.active, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  $$PeopleTableOrderingComposer get personId {
    final $$PeopleTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.personId,
        referencedTable: $db.people,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$PeopleTableOrderingComposer(
              $db: $db,
              $table: $db.people,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$ProductsTableOrderingComposer get productId {
    final $$ProductsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.productId,
        referencedTable: $db.products,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ProductsTableOrderingComposer(
              $db: $db,
              $table: $db.products,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$RegimensTableAnnotationComposer
    extends Composer<_$AppDatabase, $RegimensTable> {
  $$RegimensTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumnWithTypeConverter<RegimenKind, String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<double> get unitsPerDose => $composableBuilder(
      column: $table.unitsPerDose, builder: (column) => column);

  GeneratedColumn<double> get waterMl =>
      $composableBuilder(column: $table.waterMl, builder: (column) => column);

  GeneratedColumn<int> get minuteOfDay => $composableBuilder(
      column: $table.minuteOfDay, builder: (column) => column);

  GeneratedColumn<bool> get withMeal =>
      $composableBuilder(column: $table.withMeal, builder: (column) => column);

  GeneratedColumn<int> get weekdays =>
      $composableBuilder(column: $table.weekdays, builder: (column) => column);

  GeneratedColumn<int> get remindRepeat => $composableBuilder(
      column: $table.remindRepeat, builder: (column) => column);

  GeneratedColumn<int> get remindIntervalMin => $composableBuilder(
      column: $table.remindIntervalMin, builder: (column) => column);

  GeneratedColumn<bool> get active =>
      $composableBuilder(column: $table.active, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$PeopleTableAnnotationComposer get personId {
    final $$PeopleTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.personId,
        referencedTable: $db.people,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$PeopleTableAnnotationComposer(
              $db: $db,
              $table: $db.people,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$ProductsTableAnnotationComposer get productId {
    final $$ProductsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.productId,
        referencedTable: $db.products,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ProductsTableAnnotationComposer(
              $db: $db,
              $table: $db.products,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  Expression<T> doseLogsRefs<T extends Object>(
      Expression<T> Function($$DoseLogsTableAnnotationComposer a) f) {
    final $$DoseLogsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.doseLogs,
        getReferencedColumn: (t) => t.regimenId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$DoseLogsTableAnnotationComposer(
              $db: $db,
              $table: $db.doseLogs,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$RegimensTableTableManager extends RootTableManager<
    _$AppDatabase,
    $RegimensTable,
    RegimenRow,
    $$RegimensTableFilterComposer,
    $$RegimensTableOrderingComposer,
    $$RegimensTableAnnotationComposer,
    $$RegimensTableCreateCompanionBuilder,
    $$RegimensTableUpdateCompanionBuilder,
    (RegimenRow, $$RegimensTableReferences),
    RegimenRow,
    PrefetchHooks Function(
        {bool personId, bool productId, bool doseLogsRefs})> {
  $$RegimensTableTableManager(_$AppDatabase db, $RegimensTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RegimensTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RegimensTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RegimensTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int> personId = const Value.absent(),
            Value<RegimenKind> kind = const Value.absent(),
            Value<int?> productId = const Value.absent(),
            Value<double?> unitsPerDose = const Value.absent(),
            Value<double?> waterMl = const Value.absent(),
            Value<int> minuteOfDay = const Value.absent(),
            Value<bool> withMeal = const Value.absent(),
            Value<int> weekdays = const Value.absent(),
            Value<int> remindRepeat = const Value.absent(),
            Value<int> remindIntervalMin = const Value.absent(),
            Value<bool> active = const Value.absent(),
            Value<int> createdAt = const Value.absent(),
          }) =>
              RegimensCompanion(
            id: id,
            personId: personId,
            kind: kind,
            productId: productId,
            unitsPerDose: unitsPerDose,
            waterMl: waterMl,
            minuteOfDay: minuteOfDay,
            withMeal: withMeal,
            weekdays: weekdays,
            remindRepeat: remindRepeat,
            remindIntervalMin: remindIntervalMin,
            active: active,
            createdAt: createdAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required int personId,
            required RegimenKind kind,
            Value<int?> productId = const Value.absent(),
            Value<double?> unitsPerDose = const Value.absent(),
            Value<double?> waterMl = const Value.absent(),
            required int minuteOfDay,
            Value<bool> withMeal = const Value.absent(),
            Value<int> weekdays = const Value.absent(),
            Value<int> remindRepeat = const Value.absent(),
            Value<int> remindIntervalMin = const Value.absent(),
            Value<bool> active = const Value.absent(),
            required int createdAt,
          }) =>
              RegimensCompanion.insert(
            id: id,
            personId: personId,
            kind: kind,
            productId: productId,
            unitsPerDose: unitsPerDose,
            waterMl: waterMl,
            minuteOfDay: minuteOfDay,
            withMeal: withMeal,
            weekdays: weekdays,
            remindRepeat: remindRepeat,
            remindIntervalMin: remindIntervalMin,
            active: active,
            createdAt: createdAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable<$RegimensTable, RegimenRow>(table),
                    $$RegimensTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: (
              {personId = false, productId = false, doseLogsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (doseLogsRefs) db.doseLogs],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (personId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.personId,
                    referencedTable:
                        $$RegimensTableReferences._personIdTable(db),
                    referencedColumn:
                        $$RegimensTableReferences._personIdTable(db).id,
                  ) as T;
                }
                if (productId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.productId,
                    referencedTable:
                        $$RegimensTableReferences._productIdTable(db),
                    referencedColumn:
                        $$RegimensTableReferences._productIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [
                  if (doseLogsRefs)
                    await $_getPrefetchedDataByColumns<RegimenRow,
                            $RegimensTable, DoseLogRow, $DoseLogsTable>(
                        currentTable: table,
                        referencedTable:
                            $$RegimensTableReferences._doseLogsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$RegimensTableReferences(db, table, p0)
                                .doseLogsRefs,
                        currentColumn: 'id',
                        referencedColumn: 'regimen_id',
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$RegimensTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $RegimensTable,
    RegimenRow,
    $$RegimensTableFilterComposer,
    $$RegimensTableOrderingComposer,
    $$RegimensTableAnnotationComposer,
    $$RegimensTableCreateCompanionBuilder,
    $$RegimensTableUpdateCompanionBuilder,
    (RegimenRow, $$RegimensTableReferences),
    RegimenRow,
    PrefetchHooks Function({bool personId, bool productId, bool doseLogsRefs})>;
typedef $$DoseLogsTableCreateCompanionBuilder = DoseLogsCompanion Function({
  Value<int> id,
  required int regimenId,
  required String day,
  required int minuteOfDay,
  required DoseStatus status,
  Value<int?> takenAt,
  Value<int?> boxId,
});
typedef $$DoseLogsTableUpdateCompanionBuilder = DoseLogsCompanion Function({
  Value<int> id,
  Value<int> regimenId,
  Value<String> day,
  Value<int> minuteOfDay,
  Value<DoseStatus> status,
  Value<int?> takenAt,
  Value<int?> boxId,
});

final class $$DoseLogsTableReferences
    extends BaseReferences<_$AppDatabase, $DoseLogsTable, DoseLogRow> {
  $$DoseLogsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $RegimensTable _regimenIdTable(_$AppDatabase db) =>
      db.regimens.createAlias('dose_logs__regimen_id__regimens__id');

  $$RegimensTableProcessedTableManager get regimenId {
    final $_column = $_itemColumn<int>('regimen_id')!;

    final manager = $$RegimensTableTableManager($_db, $_db.regimens)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_regimenIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static $InventoryBoxesTable _boxIdTable(_$AppDatabase db) =>
      db.inventoryBoxes.createAlias('dose_logs__box_id__inventory_boxes__id');

  $$InventoryBoxesTableProcessedTableManager? get boxId {
    final $_column = $_itemColumn<int>('box_id');
    if ($_column == null) return null;
    final manager = $$InventoryBoxesTableTableManager($_db, $_db.inventoryBoxes)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_boxIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static MultiTypedResultKey<$IntakeEntriesTable, List<IntakeEntryRow>>
      _intakeEntriesRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.intakeEntries,
              aliasName: 'dose_logs__id__intake_entries__dose_log_id');

  $$IntakeEntriesTableProcessedTableManager get intakeEntriesRefs {
    final manager = $$IntakeEntriesTableTableManager($_db, $_db.intakeEntries)
        .filter((f) => f.doseLogId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_intakeEntriesRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$DoseLogsTableFilterComposer
    extends Composer<_$AppDatabase, $DoseLogsTable> {
  $$DoseLogsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get day => $composableBuilder(
      column: $table.day, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get minuteOfDay => $composableBuilder(
      column: $table.minuteOfDay, builder: (column) => ColumnFilters(column));

  ColumnWithTypeConverterFilters<DoseStatus, DoseStatus, String> get status =>
      $composableBuilder(
          column: $table.status,
          builder: (column) => ColumnWithTypeConverterFilters(column));

  ColumnFilters<int> get takenAt => $composableBuilder(
      column: $table.takenAt, builder: (column) => ColumnFilters(column));

  $$RegimensTableFilterComposer get regimenId {
    final $$RegimensTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.regimenId,
        referencedTable: $db.regimens,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$RegimensTableFilterComposer(
              $db: $db,
              $table: $db.regimens,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$InventoryBoxesTableFilterComposer get boxId {
    final $$InventoryBoxesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.boxId,
        referencedTable: $db.inventoryBoxes,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$InventoryBoxesTableFilterComposer(
              $db: $db,
              $table: $db.inventoryBoxes,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  Expression<bool> intakeEntriesRefs(
      Expression<bool> Function($$IntakeEntriesTableFilterComposer f) f) {
    final $$IntakeEntriesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.intakeEntries,
        getReferencedColumn: (t) => t.doseLogId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$IntakeEntriesTableFilterComposer(
              $db: $db,
              $table: $db.intakeEntries,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$DoseLogsTableOrderingComposer
    extends Composer<_$AppDatabase, $DoseLogsTable> {
  $$DoseLogsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get day => $composableBuilder(
      column: $table.day, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get minuteOfDay => $composableBuilder(
      column: $table.minuteOfDay, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get takenAt => $composableBuilder(
      column: $table.takenAt, builder: (column) => ColumnOrderings(column));

  $$RegimensTableOrderingComposer get regimenId {
    final $$RegimensTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.regimenId,
        referencedTable: $db.regimens,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$RegimensTableOrderingComposer(
              $db: $db,
              $table: $db.regimens,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$InventoryBoxesTableOrderingComposer get boxId {
    final $$InventoryBoxesTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.boxId,
        referencedTable: $db.inventoryBoxes,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$InventoryBoxesTableOrderingComposer(
              $db: $db,
              $table: $db.inventoryBoxes,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$DoseLogsTableAnnotationComposer
    extends Composer<_$AppDatabase, $DoseLogsTable> {
  $$DoseLogsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get day =>
      $composableBuilder(column: $table.day, builder: (column) => column);

  GeneratedColumn<int> get minuteOfDay => $composableBuilder(
      column: $table.minuteOfDay, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DoseStatus, String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<int> get takenAt =>
      $composableBuilder(column: $table.takenAt, builder: (column) => column);

  $$RegimensTableAnnotationComposer get regimenId {
    final $$RegimensTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.regimenId,
        referencedTable: $db.regimens,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$RegimensTableAnnotationComposer(
              $db: $db,
              $table: $db.regimens,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$InventoryBoxesTableAnnotationComposer get boxId {
    final $$InventoryBoxesTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.boxId,
        referencedTable: $db.inventoryBoxes,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$InventoryBoxesTableAnnotationComposer(
              $db: $db,
              $table: $db.inventoryBoxes,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  Expression<T> intakeEntriesRefs<T extends Object>(
      Expression<T> Function($$IntakeEntriesTableAnnotationComposer a) f) {
    final $$IntakeEntriesTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.intakeEntries,
        getReferencedColumn: (t) => t.doseLogId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$IntakeEntriesTableAnnotationComposer(
              $db: $db,
              $table: $db.intakeEntries,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$DoseLogsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $DoseLogsTable,
    DoseLogRow,
    $$DoseLogsTableFilterComposer,
    $$DoseLogsTableOrderingComposer,
    $$DoseLogsTableAnnotationComposer,
    $$DoseLogsTableCreateCompanionBuilder,
    $$DoseLogsTableUpdateCompanionBuilder,
    (DoseLogRow, $$DoseLogsTableReferences),
    DoseLogRow,
    PrefetchHooks Function(
        {bool regimenId, bool boxId, bool intakeEntriesRefs})> {
  $$DoseLogsTableTableManager(_$AppDatabase db, $DoseLogsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DoseLogsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DoseLogsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DoseLogsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int> regimenId = const Value.absent(),
            Value<String> day = const Value.absent(),
            Value<int> minuteOfDay = const Value.absent(),
            Value<DoseStatus> status = const Value.absent(),
            Value<int?> takenAt = const Value.absent(),
            Value<int?> boxId = const Value.absent(),
          }) =>
              DoseLogsCompanion(
            id: id,
            regimenId: regimenId,
            day: day,
            minuteOfDay: minuteOfDay,
            status: status,
            takenAt: takenAt,
            boxId: boxId,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required int regimenId,
            required String day,
            required int minuteOfDay,
            required DoseStatus status,
            Value<int?> takenAt = const Value.absent(),
            Value<int?> boxId = const Value.absent(),
          }) =>
              DoseLogsCompanion.insert(
            id: id,
            regimenId: regimenId,
            day: day,
            minuteOfDay: minuteOfDay,
            status: status,
            takenAt: takenAt,
            boxId: boxId,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable<$DoseLogsTable, DoseLogRow>(table),
                    $$DoseLogsTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: (
              {regimenId = false, boxId = false, intakeEntriesRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (intakeEntriesRefs) db.intakeEntries
              ],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (regimenId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.regimenId,
                    referencedTable:
                        $$DoseLogsTableReferences._regimenIdTable(db),
                    referencedColumn:
                        $$DoseLogsTableReferences._regimenIdTable(db).id,
                  ) as T;
                }
                if (boxId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.boxId,
                    referencedTable: $$DoseLogsTableReferences._boxIdTable(db),
                    referencedColumn:
                        $$DoseLogsTableReferences._boxIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [
                  if (intakeEntriesRefs)
                    await $_getPrefetchedDataByColumns<
                            DoseLogRow,
                            $DoseLogsTable,
                            IntakeEntryRow,
                            $IntakeEntriesTable>(
                        currentTable: table,
                        referencedTable: $$DoseLogsTableReferences
                            ._intakeEntriesRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$DoseLogsTableReferences(db, table, p0)
                                .intakeEntriesRefs,
                        currentColumn: 'id',
                        referencedColumn: 'dose_log_id',
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$DoseLogsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $DoseLogsTable,
    DoseLogRow,
    $$DoseLogsTableFilterComposer,
    $$DoseLogsTableOrderingComposer,
    $$DoseLogsTableAnnotationComposer,
    $$DoseLogsTableCreateCompanionBuilder,
    $$DoseLogsTableUpdateCompanionBuilder,
    (DoseLogRow, $$DoseLogsTableReferences),
    DoseLogRow,
    PrefetchHooks Function(
        {bool regimenId, bool boxId, bool intakeEntriesRefs})>;
typedef $$IntakeEntriesTableCreateCompanionBuilder = IntakeEntriesCompanion
    Function({
  Value<int> id,
  required int personId,
  required String day,
  required String label,
  required IntakeSource source,
  Value<String?> mealId,
  Value<int?> productId,
  Value<int?> doseLogId,
  required int createdAt,
});
typedef $$IntakeEntriesTableUpdateCompanionBuilder = IntakeEntriesCompanion
    Function({
  Value<int> id,
  Value<int> personId,
  Value<String> day,
  Value<String> label,
  Value<IntakeSource> source,
  Value<String?> mealId,
  Value<int?> productId,
  Value<int?> doseLogId,
  Value<int> createdAt,
});

final class $$IntakeEntriesTableReferences
    extends BaseReferences<_$AppDatabase, $IntakeEntriesTable, IntakeEntryRow> {
  $$IntakeEntriesTableReferences(
      super.$_db, super.$_table, super.$_typedResult);

  static $PeopleTable _personIdTable(_$AppDatabase db) =>
      db.people.createAlias('intake_entries__person_id__people__id');

  $$PeopleTableProcessedTableManager get personId {
    final $_column = $_itemColumn<int>('person_id')!;

    final manager = $$PeopleTableTableManager($_db, $_db.people)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_personIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static $ProductsTable _productIdTable(_$AppDatabase db) =>
      db.products.createAlias('intake_entries__product_id__products__id');

  $$ProductsTableProcessedTableManager? get productId {
    final $_column = $_itemColumn<int>('product_id');
    if ($_column == null) return null;
    final manager = $$ProductsTableTableManager($_db, $_db.products)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_productIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static $DoseLogsTable _doseLogIdTable(_$AppDatabase db) =>
      db.doseLogs.createAlias('intake_entries__dose_log_id__dose_logs__id');

  $$DoseLogsTableProcessedTableManager? get doseLogId {
    final $_column = $_itemColumn<int>('dose_log_id');
    if ($_column == null) return null;
    final manager = $$DoseLogsTableTableManager($_db, $_db.doseLogs)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_doseLogIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static MultiTypedResultKey<$IntakeNutrientsTable, List<IntakeNutrientRow>>
      _intakeNutrientsRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.intakeNutrients,
              aliasName: 'intake_entries__id__intake_nutrients__entry_id');

  $$IntakeNutrientsTableProcessedTableManager get intakeNutrientsRefs {
    final manager =
        $$IntakeNutrientsTableTableManager($_db, $_db.intakeNutrients)
            .filter((f) => f.entryId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache =
        $_typedResult.readTableOrNull(_intakeNutrientsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$IntakeEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $IntakeEntriesTable> {
  $$IntakeEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get day => $composableBuilder(
      column: $table.day, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get label => $composableBuilder(
      column: $table.label, builder: (column) => ColumnFilters(column));

  ColumnWithTypeConverterFilters<IntakeSource, IntakeSource, String>
      get source => $composableBuilder(
          column: $table.source,
          builder: (column) => ColumnWithTypeConverterFilters(column));

  ColumnFilters<String> get mealId => $composableBuilder(
      column: $table.mealId, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  $$PeopleTableFilterComposer get personId {
    final $$PeopleTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.personId,
        referencedTable: $db.people,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$PeopleTableFilterComposer(
              $db: $db,
              $table: $db.people,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$ProductsTableFilterComposer get productId {
    final $$ProductsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.productId,
        referencedTable: $db.products,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ProductsTableFilterComposer(
              $db: $db,
              $table: $db.products,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$DoseLogsTableFilterComposer get doseLogId {
    final $$DoseLogsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.doseLogId,
        referencedTable: $db.doseLogs,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$DoseLogsTableFilterComposer(
              $db: $db,
              $table: $db.doseLogs,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  Expression<bool> intakeNutrientsRefs(
      Expression<bool> Function($$IntakeNutrientsTableFilterComposer f) f) {
    final $$IntakeNutrientsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.intakeNutrients,
        getReferencedColumn: (t) => t.entryId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$IntakeNutrientsTableFilterComposer(
              $db: $db,
              $table: $db.intakeNutrients,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$IntakeEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $IntakeEntriesTable> {
  $$IntakeEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get day => $composableBuilder(
      column: $table.day, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get label => $composableBuilder(
      column: $table.label, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get source => $composableBuilder(
      column: $table.source, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get mealId => $composableBuilder(
      column: $table.mealId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  $$PeopleTableOrderingComposer get personId {
    final $$PeopleTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.personId,
        referencedTable: $db.people,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$PeopleTableOrderingComposer(
              $db: $db,
              $table: $db.people,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$ProductsTableOrderingComposer get productId {
    final $$ProductsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.productId,
        referencedTable: $db.products,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ProductsTableOrderingComposer(
              $db: $db,
              $table: $db.products,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$DoseLogsTableOrderingComposer get doseLogId {
    final $$DoseLogsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.doseLogId,
        referencedTable: $db.doseLogs,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$DoseLogsTableOrderingComposer(
              $db: $db,
              $table: $db.doseLogs,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$IntakeEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $IntakeEntriesTable> {
  $$IntakeEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get day =>
      $composableBuilder(column: $table.day, builder: (column) => column);

  GeneratedColumn<String> get label =>
      $composableBuilder(column: $table.label, builder: (column) => column);

  GeneratedColumnWithTypeConverter<IntakeSource, String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);

  GeneratedColumn<String> get mealId =>
      $composableBuilder(column: $table.mealId, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$PeopleTableAnnotationComposer get personId {
    final $$PeopleTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.personId,
        referencedTable: $db.people,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$PeopleTableAnnotationComposer(
              $db: $db,
              $table: $db.people,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$ProductsTableAnnotationComposer get productId {
    final $$ProductsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.productId,
        referencedTable: $db.products,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ProductsTableAnnotationComposer(
              $db: $db,
              $table: $db.products,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$DoseLogsTableAnnotationComposer get doseLogId {
    final $$DoseLogsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.doseLogId,
        referencedTable: $db.doseLogs,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$DoseLogsTableAnnotationComposer(
              $db: $db,
              $table: $db.doseLogs,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  Expression<T> intakeNutrientsRefs<T extends Object>(
      Expression<T> Function($$IntakeNutrientsTableAnnotationComposer a) f) {
    final $$IntakeNutrientsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.intakeNutrients,
        getReferencedColumn: (t) => t.entryId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$IntakeNutrientsTableAnnotationComposer(
              $db: $db,
              $table: $db.intakeNutrients,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$IntakeEntriesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $IntakeEntriesTable,
    IntakeEntryRow,
    $$IntakeEntriesTableFilterComposer,
    $$IntakeEntriesTableOrderingComposer,
    $$IntakeEntriesTableAnnotationComposer,
    $$IntakeEntriesTableCreateCompanionBuilder,
    $$IntakeEntriesTableUpdateCompanionBuilder,
    (IntakeEntryRow, $$IntakeEntriesTableReferences),
    IntakeEntryRow,
    PrefetchHooks Function(
        {bool personId,
        bool productId,
        bool doseLogId,
        bool intakeNutrientsRefs})> {
  $$IntakeEntriesTableTableManager(_$AppDatabase db, $IntakeEntriesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$IntakeEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$IntakeEntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$IntakeEntriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int> personId = const Value.absent(),
            Value<String> day = const Value.absent(),
            Value<String> label = const Value.absent(),
            Value<IntakeSource> source = const Value.absent(),
            Value<String?> mealId = const Value.absent(),
            Value<int?> productId = const Value.absent(),
            Value<int?> doseLogId = const Value.absent(),
            Value<int> createdAt = const Value.absent(),
          }) =>
              IntakeEntriesCompanion(
            id: id,
            personId: personId,
            day: day,
            label: label,
            source: source,
            mealId: mealId,
            productId: productId,
            doseLogId: doseLogId,
            createdAt: createdAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required int personId,
            required String day,
            required String label,
            required IntakeSource source,
            Value<String?> mealId = const Value.absent(),
            Value<int?> productId = const Value.absent(),
            Value<int?> doseLogId = const Value.absent(),
            required int createdAt,
          }) =>
              IntakeEntriesCompanion.insert(
            id: id,
            personId: personId,
            day: day,
            label: label,
            source: source,
            mealId: mealId,
            productId: productId,
            doseLogId: doseLogId,
            createdAt: createdAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable<$IntakeEntriesTable, IntakeEntryRow>(table),
                    $$IntakeEntriesTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: (
              {personId = false,
              productId = false,
              doseLogId = false,
              intakeNutrientsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (intakeNutrientsRefs) db.intakeNutrients
              ],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (personId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.personId,
                    referencedTable:
                        $$IntakeEntriesTableReferences._personIdTable(db),
                    referencedColumn:
                        $$IntakeEntriesTableReferences._personIdTable(db).id,
                  ) as T;
                }
                if (productId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.productId,
                    referencedTable:
                        $$IntakeEntriesTableReferences._productIdTable(db),
                    referencedColumn:
                        $$IntakeEntriesTableReferences._productIdTable(db).id,
                  ) as T;
                }
                if (doseLogId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.doseLogId,
                    referencedTable:
                        $$IntakeEntriesTableReferences._doseLogIdTable(db),
                    referencedColumn:
                        $$IntakeEntriesTableReferences._doseLogIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [
                  if (intakeNutrientsRefs)
                    await $_getPrefetchedDataByColumns<
                            IntakeEntryRow,
                            $IntakeEntriesTable,
                            IntakeNutrientRow,
                            $IntakeNutrientsTable>(
                        currentTable: table,
                        referencedTable: $$IntakeEntriesTableReferences
                            ._intakeNutrientsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$IntakeEntriesTableReferences(db, table, p0)
                                .intakeNutrientsRefs,
                        currentColumn: 'id',
                        referencedColumn: 'entry_id',
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$IntakeEntriesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $IntakeEntriesTable,
    IntakeEntryRow,
    $$IntakeEntriesTableFilterComposer,
    $$IntakeEntriesTableOrderingComposer,
    $$IntakeEntriesTableAnnotationComposer,
    $$IntakeEntriesTableCreateCompanionBuilder,
    $$IntakeEntriesTableUpdateCompanionBuilder,
    (IntakeEntryRow, $$IntakeEntriesTableReferences),
    IntakeEntryRow,
    PrefetchHooks Function(
        {bool personId,
        bool productId,
        bool doseLogId,
        bool intakeNutrientsRefs})>;
typedef $$IntakeNutrientsTableCreateCompanionBuilder = IntakeNutrientsCompanion
    Function({
  required int entryId,
  required String nutrientId,
  required double amount,
  required String unit,
  Value<int> rowid,
});
typedef $$IntakeNutrientsTableUpdateCompanionBuilder = IntakeNutrientsCompanion
    Function({
  Value<int> entryId,
  Value<String> nutrientId,
  Value<double> amount,
  Value<String> unit,
  Value<int> rowid,
});

final class $$IntakeNutrientsTableReferences extends BaseReferences<
    _$AppDatabase, $IntakeNutrientsTable, IntakeNutrientRow> {
  $$IntakeNutrientsTableReferences(
      super.$_db, super.$_table, super.$_typedResult);

  static $IntakeEntriesTable _entryIdTable(_$AppDatabase db) => db.intakeEntries
      .createAlias('intake_nutrients__entry_id__intake_entries__id');

  $$IntakeEntriesTableProcessedTableManager get entryId {
    final $_column = $_itemColumn<int>('entry_id')!;

    final manager = $$IntakeEntriesTableTableManager($_db, $_db.intakeEntries)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_entryIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$IntakeNutrientsTableFilterComposer
    extends Composer<_$AppDatabase, $IntakeNutrientsTable> {
  $$IntakeNutrientsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get nutrientId => $composableBuilder(
      column: $table.nutrientId, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get amount => $composableBuilder(
      column: $table.amount, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get unit => $composableBuilder(
      column: $table.unit, builder: (column) => ColumnFilters(column));

  $$IntakeEntriesTableFilterComposer get entryId {
    final $$IntakeEntriesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.entryId,
        referencedTable: $db.intakeEntries,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$IntakeEntriesTableFilterComposer(
              $db: $db,
              $table: $db.intakeEntries,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$IntakeNutrientsTableOrderingComposer
    extends Composer<_$AppDatabase, $IntakeNutrientsTable> {
  $$IntakeNutrientsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get nutrientId => $composableBuilder(
      column: $table.nutrientId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get amount => $composableBuilder(
      column: $table.amount, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get unit => $composableBuilder(
      column: $table.unit, builder: (column) => ColumnOrderings(column));

  $$IntakeEntriesTableOrderingComposer get entryId {
    final $$IntakeEntriesTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.entryId,
        referencedTable: $db.intakeEntries,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$IntakeEntriesTableOrderingComposer(
              $db: $db,
              $table: $db.intakeEntries,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$IntakeNutrientsTableAnnotationComposer
    extends Composer<_$AppDatabase, $IntakeNutrientsTable> {
  $$IntakeNutrientsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get nutrientId => $composableBuilder(
      column: $table.nutrientId, builder: (column) => column);

  GeneratedColumn<double> get amount =>
      $composableBuilder(column: $table.amount, builder: (column) => column);

  GeneratedColumn<String> get unit =>
      $composableBuilder(column: $table.unit, builder: (column) => column);

  $$IntakeEntriesTableAnnotationComposer get entryId {
    final $$IntakeEntriesTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.entryId,
        referencedTable: $db.intakeEntries,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$IntakeEntriesTableAnnotationComposer(
              $db: $db,
              $table: $db.intakeEntries,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$IntakeNutrientsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $IntakeNutrientsTable,
    IntakeNutrientRow,
    $$IntakeNutrientsTableFilterComposer,
    $$IntakeNutrientsTableOrderingComposer,
    $$IntakeNutrientsTableAnnotationComposer,
    $$IntakeNutrientsTableCreateCompanionBuilder,
    $$IntakeNutrientsTableUpdateCompanionBuilder,
    (IntakeNutrientRow, $$IntakeNutrientsTableReferences),
    IntakeNutrientRow,
    PrefetchHooks Function({bool entryId})> {
  $$IntakeNutrientsTableTableManager(
      _$AppDatabase db, $IntakeNutrientsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$IntakeNutrientsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$IntakeNutrientsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$IntakeNutrientsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> entryId = const Value.absent(),
            Value<String> nutrientId = const Value.absent(),
            Value<double> amount = const Value.absent(),
            Value<String> unit = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              IntakeNutrientsCompanion(
            entryId: entryId,
            nutrientId: nutrientId,
            amount: amount,
            unit: unit,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required int entryId,
            required String nutrientId,
            required double amount,
            required String unit,
            Value<int> rowid = const Value.absent(),
          }) =>
              IntakeNutrientsCompanion.insert(
            entryId: entryId,
            nutrientId: nutrientId,
            amount: amount,
            unit: unit,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable<$IntakeNutrientsTable, IntakeNutrientRow>(
                        table),
                    $$IntakeNutrientsTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({entryId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (entryId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.entryId,
                    referencedTable:
                        $$IntakeNutrientsTableReferences._entryIdTable(db),
                    referencedColumn:
                        $$IntakeNutrientsTableReferences._entryIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$IntakeNutrientsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $IntakeNutrientsTable,
    IntakeNutrientRow,
    $$IntakeNutrientsTableFilterComposer,
    $$IntakeNutrientsTableOrderingComposer,
    $$IntakeNutrientsTableAnnotationComposer,
    $$IntakeNutrientsTableCreateCompanionBuilder,
    $$IntakeNutrientsTableUpdateCompanionBuilder,
    (IntakeNutrientRow, $$IntakeNutrientsTableReferences),
    IntakeNutrientRow,
    PrefetchHooks Function({bool entryId})>;
typedef $$WorkoutsTableCreateCompanionBuilder = WorkoutsCompanion Function({
  Value<int> id,
  required int personId,
  required String day,
  required String activityCode,
  required double minutes,
  required int createdAt,
});
typedef $$WorkoutsTableUpdateCompanionBuilder = WorkoutsCompanion Function({
  Value<int> id,
  Value<int> personId,
  Value<String> day,
  Value<String> activityCode,
  Value<double> minutes,
  Value<int> createdAt,
});

final class $$WorkoutsTableReferences
    extends BaseReferences<_$AppDatabase, $WorkoutsTable, WorkoutRow> {
  $$WorkoutsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $PeopleTable _personIdTable(_$AppDatabase db) =>
      db.people.createAlias('workouts__person_id__people__id');

  $$PeopleTableProcessedTableManager get personId {
    final $_column = $_itemColumn<int>('person_id')!;

    final manager = $$PeopleTableTableManager($_db, $_db.people)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_personIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$WorkoutsTableFilterComposer
    extends Composer<_$AppDatabase, $WorkoutsTable> {
  $$WorkoutsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get day => $composableBuilder(
      column: $table.day, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get activityCode => $composableBuilder(
      column: $table.activityCode, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get minutes => $composableBuilder(
      column: $table.minutes, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  $$PeopleTableFilterComposer get personId {
    final $$PeopleTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.personId,
        referencedTable: $db.people,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$PeopleTableFilterComposer(
              $db: $db,
              $table: $db.people,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$WorkoutsTableOrderingComposer
    extends Composer<_$AppDatabase, $WorkoutsTable> {
  $$WorkoutsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get day => $composableBuilder(
      column: $table.day, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get activityCode => $composableBuilder(
      column: $table.activityCode,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get minutes => $composableBuilder(
      column: $table.minutes, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  $$PeopleTableOrderingComposer get personId {
    final $$PeopleTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.personId,
        referencedTable: $db.people,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$PeopleTableOrderingComposer(
              $db: $db,
              $table: $db.people,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$WorkoutsTableAnnotationComposer
    extends Composer<_$AppDatabase, $WorkoutsTable> {
  $$WorkoutsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get day =>
      $composableBuilder(column: $table.day, builder: (column) => column);

  GeneratedColumn<String> get activityCode => $composableBuilder(
      column: $table.activityCode, builder: (column) => column);

  GeneratedColumn<double> get minutes =>
      $composableBuilder(column: $table.minutes, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$PeopleTableAnnotationComposer get personId {
    final $$PeopleTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.personId,
        referencedTable: $db.people,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$PeopleTableAnnotationComposer(
              $db: $db,
              $table: $db.people,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$WorkoutsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $WorkoutsTable,
    WorkoutRow,
    $$WorkoutsTableFilterComposer,
    $$WorkoutsTableOrderingComposer,
    $$WorkoutsTableAnnotationComposer,
    $$WorkoutsTableCreateCompanionBuilder,
    $$WorkoutsTableUpdateCompanionBuilder,
    (WorkoutRow, $$WorkoutsTableReferences),
    WorkoutRow,
    PrefetchHooks Function({bool personId})> {
  $$WorkoutsTableTableManager(_$AppDatabase db, $WorkoutsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$WorkoutsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$WorkoutsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$WorkoutsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int> personId = const Value.absent(),
            Value<String> day = const Value.absent(),
            Value<String> activityCode = const Value.absent(),
            Value<double> minutes = const Value.absent(),
            Value<int> createdAt = const Value.absent(),
          }) =>
              WorkoutsCompanion(
            id: id,
            personId: personId,
            day: day,
            activityCode: activityCode,
            minutes: minutes,
            createdAt: createdAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required int personId,
            required String day,
            required String activityCode,
            required double minutes,
            required int createdAt,
          }) =>
              WorkoutsCompanion.insert(
            id: id,
            personId: personId,
            day: day,
            activityCode: activityCode,
            minutes: minutes,
            createdAt: createdAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable<$WorkoutsTable, WorkoutRow>(table),
                    $$WorkoutsTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({personId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (personId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.personId,
                    referencedTable:
                        $$WorkoutsTableReferences._personIdTable(db),
                    referencedColumn:
                        $$WorkoutsTableReferences._personIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$WorkoutsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $WorkoutsTable,
    WorkoutRow,
    $$WorkoutsTableFilterComposer,
    $$WorkoutsTableOrderingComposer,
    $$WorkoutsTableAnnotationComposer,
    $$WorkoutsTableCreateCompanionBuilder,
    $$WorkoutsTableUpdateCompanionBuilder,
    (WorkoutRow, $$WorkoutsTableReferences),
    WorkoutRow,
    PrefetchHooks Function({bool personId})>;
typedef $$WaterLogsTableCreateCompanionBuilder = WaterLogsCompanion Function({
  Value<int> id,
  required int personId,
  required String day,
  required double ml,
  required int createdAt,
});
typedef $$WaterLogsTableUpdateCompanionBuilder = WaterLogsCompanion Function({
  Value<int> id,
  Value<int> personId,
  Value<String> day,
  Value<double> ml,
  Value<int> createdAt,
});

final class $$WaterLogsTableReferences
    extends BaseReferences<_$AppDatabase, $WaterLogsTable, WaterLogRow> {
  $$WaterLogsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $PeopleTable _personIdTable(_$AppDatabase db) =>
      db.people.createAlias('water_logs__person_id__people__id');

  $$PeopleTableProcessedTableManager get personId {
    final $_column = $_itemColumn<int>('person_id')!;

    final manager = $$PeopleTableTableManager($_db, $_db.people)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_personIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$WaterLogsTableFilterComposer
    extends Composer<_$AppDatabase, $WaterLogsTable> {
  $$WaterLogsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get day => $composableBuilder(
      column: $table.day, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get ml => $composableBuilder(
      column: $table.ml, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  $$PeopleTableFilterComposer get personId {
    final $$PeopleTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.personId,
        referencedTable: $db.people,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$PeopleTableFilterComposer(
              $db: $db,
              $table: $db.people,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$WaterLogsTableOrderingComposer
    extends Composer<_$AppDatabase, $WaterLogsTable> {
  $$WaterLogsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get day => $composableBuilder(
      column: $table.day, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get ml => $composableBuilder(
      column: $table.ml, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  $$PeopleTableOrderingComposer get personId {
    final $$PeopleTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.personId,
        referencedTable: $db.people,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$PeopleTableOrderingComposer(
              $db: $db,
              $table: $db.people,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$WaterLogsTableAnnotationComposer
    extends Composer<_$AppDatabase, $WaterLogsTable> {
  $$WaterLogsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get day =>
      $composableBuilder(column: $table.day, builder: (column) => column);

  GeneratedColumn<double> get ml =>
      $composableBuilder(column: $table.ml, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$PeopleTableAnnotationComposer get personId {
    final $$PeopleTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.personId,
        referencedTable: $db.people,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$PeopleTableAnnotationComposer(
              $db: $db,
              $table: $db.people,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$WaterLogsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $WaterLogsTable,
    WaterLogRow,
    $$WaterLogsTableFilterComposer,
    $$WaterLogsTableOrderingComposer,
    $$WaterLogsTableAnnotationComposer,
    $$WaterLogsTableCreateCompanionBuilder,
    $$WaterLogsTableUpdateCompanionBuilder,
    (WaterLogRow, $$WaterLogsTableReferences),
    WaterLogRow,
    PrefetchHooks Function({bool personId})> {
  $$WaterLogsTableTableManager(_$AppDatabase db, $WaterLogsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$WaterLogsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$WaterLogsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$WaterLogsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int> personId = const Value.absent(),
            Value<String> day = const Value.absent(),
            Value<double> ml = const Value.absent(),
            Value<int> createdAt = const Value.absent(),
          }) =>
              WaterLogsCompanion(
            id: id,
            personId: personId,
            day: day,
            ml: ml,
            createdAt: createdAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required int personId,
            required String day,
            required double ml,
            required int createdAt,
          }) =>
              WaterLogsCompanion.insert(
            id: id,
            personId: personId,
            day: day,
            ml: ml,
            createdAt: createdAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable<$WaterLogsTable, WaterLogRow>(table),
                    $$WaterLogsTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({personId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (personId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.personId,
                    referencedTable:
                        $$WaterLogsTableReferences._personIdTable(db),
                    referencedColumn:
                        $$WaterLogsTableReferences._personIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$WaterLogsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $WaterLogsTable,
    WaterLogRow,
    $$WaterLogsTableFilterComposer,
    $$WaterLogsTableOrderingComposer,
    $$WaterLogsTableAnnotationComposer,
    $$WaterLogsTableCreateCompanionBuilder,
    $$WaterLogsTableUpdateCompanionBuilder,
    (WaterLogRow, $$WaterLogsTableReferences),
    WaterLogRow,
    PrefetchHooks Function({bool personId})>;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$PeopleTableTableManager get people =>
      $$PeopleTableTableManager(_db, _db.people);
  $$ProfilesTableTableManager get profiles =>
      $$ProfilesTableTableManager(_db, _db.profiles);
  $$SettingsTableTableManager get settings =>
      $$SettingsTableTableManager(_db, _db.settings);
  $$ProductsTableTableManager get products =>
      $$ProductsTableTableManager(_db, _db.products);
  $$ProductNutrientsTableTableManager get productNutrients =>
      $$ProductNutrientsTableTableManager(_db, _db.productNutrients);
  $$InventoryBoxesTableTableManager get inventoryBoxes =>
      $$InventoryBoxesTableTableManager(_db, _db.inventoryBoxes);
  $$RegimensTableTableManager get regimens =>
      $$RegimensTableTableManager(_db, _db.regimens);
  $$DoseLogsTableTableManager get doseLogs =>
      $$DoseLogsTableTableManager(_db, _db.doseLogs);
  $$IntakeEntriesTableTableManager get intakeEntries =>
      $$IntakeEntriesTableTableManager(_db, _db.intakeEntries);
  $$IntakeNutrientsTableTableManager get intakeNutrients =>
      $$IntakeNutrientsTableTableManager(_db, _db.intakeNutrients);
  $$WorkoutsTableTableManager get workouts =>
      $$WorkoutsTableTableManager(_db, _db.workouts);
  $$WaterLogsTableTableManager get waterLogs =>
      $$WaterLogsTableTableManager(_db, _db.waterLogs);
}
