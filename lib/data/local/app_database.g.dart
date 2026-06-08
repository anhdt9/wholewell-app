// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $ProductsTable extends Products with TableInfo<$ProductsTable, Product> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ProductsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 255,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _brandMeta = const VerificationMeta('brand');
  @override
  late final GeneratedColumn<String> brand = GeneratedColumn<String>(
    'brand',
    aliasedName,
    true,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 0,
      maxTextLength: 255,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _priceMeta = const VerificationMeta('price');
  @override
  late final GeneratedColumn<double> price = GeneratedColumn<double>(
    'price',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _currencyMeta = const VerificationMeta(
    'currency',
  );
  @override
  late final GeneratedColumn<String> currency = GeneratedColumn<String>(
    'currency',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 16,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('VND'),
  );
  static const VerificationMeta _totalQuantityMeta = const VerificationMeta(
    'totalQuantity',
  );
  @override
  late final GeneratedColumn<int> totalQuantity = GeneratedColumn<int>(
    'total_quantity',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _servingSizeMeta = const VerificationMeta(
    'servingSize',
  );
  @override
  late final GeneratedColumn<double> servingSize = GeneratedColumn<double>(
    'serving_size',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0.0),
  );
  static const VerificationMeta _servingTypeMeta = const VerificationMeta(
    'servingType',
  );
  @override
  late final GeneratedColumn<String> servingType = GeneratedColumn<String>(
    'serving_type',
    aliasedName,
    true,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 0,
      maxTextLength: 64,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _imagePathMeta = const VerificationMeta(
    'imagePath',
  );
  @override
  late final GeneratedColumn<String> imagePath = GeneratedColumn<String>(
    'image_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    brand,
    price,
    currency,
    totalQuantity,
    servingSize,
    servingType,
    imagePath,
    note,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'products';
  @override
  VerificationContext validateIntegrity(
    Insertable<Product> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('brand')) {
      context.handle(
        _brandMeta,
        brand.isAcceptableOrUnknown(data['brand']!, _brandMeta),
      );
    }
    if (data.containsKey('price')) {
      context.handle(
        _priceMeta,
        price.isAcceptableOrUnknown(data['price']!, _priceMeta),
      );
    }
    if (data.containsKey('currency')) {
      context.handle(
        _currencyMeta,
        currency.isAcceptableOrUnknown(data['currency']!, _currencyMeta),
      );
    }
    if (data.containsKey('total_quantity')) {
      context.handle(
        _totalQuantityMeta,
        totalQuantity.isAcceptableOrUnknown(
          data['total_quantity']!,
          _totalQuantityMeta,
        ),
      );
    }
    if (data.containsKey('serving_size')) {
      context.handle(
        _servingSizeMeta,
        servingSize.isAcceptableOrUnknown(
          data['serving_size']!,
          _servingSizeMeta,
        ),
      );
    }
    if (data.containsKey('serving_type')) {
      context.handle(
        _servingTypeMeta,
        servingType.isAcceptableOrUnknown(
          data['serving_type']!,
          _servingTypeMeta,
        ),
      );
    }
    if (data.containsKey('image_path')) {
      context.handle(
        _imagePathMeta,
        imagePath.isAcceptableOrUnknown(data['image_path']!, _imagePathMeta),
      );
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Product map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Product(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      brand: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}brand'],
      ),
      price: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}price'],
      ),
      currency: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}currency'],
      )!,
      totalQuantity: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}total_quantity'],
      )!,
      servingSize: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}serving_size'],
      )!,
      servingType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}serving_type'],
      ),
      imagePath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}image_path'],
      ),
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $ProductsTable createAlias(String alias) {
    return $ProductsTable(attachedDatabase, alias);
  }
}

class Product extends DataClass implements Insertable<Product> {
  final int id;
  final String name;
  final String? brand;
  final double? price;
  final String currency;
  final int totalQuantity;
  final double servingSize;
  final String? servingType;
  final String? imagePath;
  final String? note;
  final DateTime createdAt;
  final DateTime updatedAt;
  const Product({
    required this.id,
    required this.name,
    this.brand,
    this.price,
    required this.currency,
    required this.totalQuantity,
    required this.servingSize,
    this.servingType,
    this.imagePath,
    this.note,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || brand != null) {
      map['brand'] = Variable<String>(brand);
    }
    if (!nullToAbsent || price != null) {
      map['price'] = Variable<double>(price);
    }
    map['currency'] = Variable<String>(currency);
    map['total_quantity'] = Variable<int>(totalQuantity);
    map['serving_size'] = Variable<double>(servingSize);
    if (!nullToAbsent || servingType != null) {
      map['serving_type'] = Variable<String>(servingType);
    }
    if (!nullToAbsent || imagePath != null) {
      map['image_path'] = Variable<String>(imagePath);
    }
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  ProductsCompanion toCompanion(bool nullToAbsent) {
    return ProductsCompanion(
      id: Value(id),
      name: Value(name),
      brand: brand == null && nullToAbsent
          ? const Value.absent()
          : Value(brand),
      price: price == null && nullToAbsent
          ? const Value.absent()
          : Value(price),
      currency: Value(currency),
      totalQuantity: Value(totalQuantity),
      servingSize: Value(servingSize),
      servingType: servingType == null && nullToAbsent
          ? const Value.absent()
          : Value(servingType),
      imagePath: imagePath == null && nullToAbsent
          ? const Value.absent()
          : Value(imagePath),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory Product.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Product(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      brand: serializer.fromJson<String?>(json['brand']),
      price: serializer.fromJson<double?>(json['price']),
      currency: serializer.fromJson<String>(json['currency']),
      totalQuantity: serializer.fromJson<int>(json['totalQuantity']),
      servingSize: serializer.fromJson<double>(json['servingSize']),
      servingType: serializer.fromJson<String?>(json['servingType']),
      imagePath: serializer.fromJson<String?>(json['imagePath']),
      note: serializer.fromJson<String?>(json['note']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'brand': serializer.toJson<String?>(brand),
      'price': serializer.toJson<double?>(price),
      'currency': serializer.toJson<String>(currency),
      'totalQuantity': serializer.toJson<int>(totalQuantity),
      'servingSize': serializer.toJson<double>(servingSize),
      'servingType': serializer.toJson<String?>(servingType),
      'imagePath': serializer.toJson<String?>(imagePath),
      'note': serializer.toJson<String?>(note),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  Product copyWith({
    int? id,
    String? name,
    Value<String?> brand = const Value.absent(),
    Value<double?> price = const Value.absent(),
    String? currency,
    int? totalQuantity,
    double? servingSize,
    Value<String?> servingType = const Value.absent(),
    Value<String?> imagePath = const Value.absent(),
    Value<String?> note = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => Product(
    id: id ?? this.id,
    name: name ?? this.name,
    brand: brand.present ? brand.value : this.brand,
    price: price.present ? price.value : this.price,
    currency: currency ?? this.currency,
    totalQuantity: totalQuantity ?? this.totalQuantity,
    servingSize: servingSize ?? this.servingSize,
    servingType: servingType.present ? servingType.value : this.servingType,
    imagePath: imagePath.present ? imagePath.value : this.imagePath,
    note: note.present ? note.value : this.note,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  Product copyWithCompanion(ProductsCompanion data) {
    return Product(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      brand: data.brand.present ? data.brand.value : this.brand,
      price: data.price.present ? data.price.value : this.price,
      currency: data.currency.present ? data.currency.value : this.currency,
      totalQuantity: data.totalQuantity.present
          ? data.totalQuantity.value
          : this.totalQuantity,
      servingSize: data.servingSize.present
          ? data.servingSize.value
          : this.servingSize,
      servingType: data.servingType.present
          ? data.servingType.value
          : this.servingType,
      imagePath: data.imagePath.present ? data.imagePath.value : this.imagePath,
      note: data.note.present ? data.note.value : this.note,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Product(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('brand: $brand, ')
          ..write('price: $price, ')
          ..write('currency: $currency, ')
          ..write('totalQuantity: $totalQuantity, ')
          ..write('servingSize: $servingSize, ')
          ..write('servingType: $servingType, ')
          ..write('imagePath: $imagePath, ')
          ..write('note: $note, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    brand,
    price,
    currency,
    totalQuantity,
    servingSize,
    servingType,
    imagePath,
    note,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Product &&
          other.id == this.id &&
          other.name == this.name &&
          other.brand == this.brand &&
          other.price == this.price &&
          other.currency == this.currency &&
          other.totalQuantity == this.totalQuantity &&
          other.servingSize == this.servingSize &&
          other.servingType == this.servingType &&
          other.imagePath == this.imagePath &&
          other.note == this.note &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class ProductsCompanion extends UpdateCompanion<Product> {
  final Value<int> id;
  final Value<String> name;
  final Value<String?> brand;
  final Value<double?> price;
  final Value<String> currency;
  final Value<int> totalQuantity;
  final Value<double> servingSize;
  final Value<String?> servingType;
  final Value<String?> imagePath;
  final Value<String?> note;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  const ProductsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.brand = const Value.absent(),
    this.price = const Value.absent(),
    this.currency = const Value.absent(),
    this.totalQuantity = const Value.absent(),
    this.servingSize = const Value.absent(),
    this.servingType = const Value.absent(),
    this.imagePath = const Value.absent(),
    this.note = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  ProductsCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    this.brand = const Value.absent(),
    this.price = const Value.absent(),
    this.currency = const Value.absent(),
    this.totalQuantity = const Value.absent(),
    this.servingSize = const Value.absent(),
    this.servingType = const Value.absent(),
    this.imagePath = const Value.absent(),
    this.note = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  }) : name = Value(name);
  static Insertable<Product> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<String>? brand,
    Expression<double>? price,
    Expression<String>? currency,
    Expression<int>? totalQuantity,
    Expression<double>? servingSize,
    Expression<String>? servingType,
    Expression<String>? imagePath,
    Expression<String>? note,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (brand != null) 'brand': brand,
      if (price != null) 'price': price,
      if (currency != null) 'currency': currency,
      if (totalQuantity != null) 'total_quantity': totalQuantity,
      if (servingSize != null) 'serving_size': servingSize,
      if (servingType != null) 'serving_type': servingType,
      if (imagePath != null) 'image_path': imagePath,
      if (note != null) 'note': note,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  ProductsCompanion copyWith({
    Value<int>? id,
    Value<String>? name,
    Value<String?>? brand,
    Value<double?>? price,
    Value<String>? currency,
    Value<int>? totalQuantity,
    Value<double>? servingSize,
    Value<String?>? servingType,
    Value<String?>? imagePath,
    Value<String?>? note,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
  }) {
    return ProductsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      brand: brand ?? this.brand,
      price: price ?? this.price,
      currency: currency ?? this.currency,
      totalQuantity: totalQuantity ?? this.totalQuantity,
      servingSize: servingSize ?? this.servingSize,
      servingType: servingType ?? this.servingType,
      imagePath: imagePath ?? this.imagePath,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (brand.present) {
      map['brand'] = Variable<String>(brand.value);
    }
    if (price.present) {
      map['price'] = Variable<double>(price.value);
    }
    if (currency.present) {
      map['currency'] = Variable<String>(currency.value);
    }
    if (totalQuantity.present) {
      map['total_quantity'] = Variable<int>(totalQuantity.value);
    }
    if (servingSize.present) {
      map['serving_size'] = Variable<double>(servingSize.value);
    }
    if (servingType.present) {
      map['serving_type'] = Variable<String>(servingType.value);
    }
    if (imagePath.present) {
      map['image_path'] = Variable<String>(imagePath.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ProductsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('brand: $brand, ')
          ..write('price: $price, ')
          ..write('currency: $currency, ')
          ..write('totalQuantity: $totalQuantity, ')
          ..write('servingSize: $servingSize, ')
          ..write('servingType: $servingType, ')
          ..write('imagePath: $imagePath, ')
          ..write('note: $note, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $ProductIngredientsTable extends ProductIngredients
    with TableInfo<$ProductIngredientsTable, ProductIngredient> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ProductIngredientsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _productIdMeta = const VerificationMeta(
    'productId',
  );
  @override
  late final GeneratedColumn<int> productId = GeneratedColumn<int>(
    'product_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES products (id)',
    ),
  );
  static const VerificationMeta _nutrientKeyMeta = const VerificationMeta(
    'nutrientKey',
  );
  @override
  late final GeneratedColumn<String> nutrientKey = GeneratedColumn<String>(
    'nutrient_key',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 128,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nutrientNameMeta = const VerificationMeta(
    'nutrientName',
  );
  @override
  late final GeneratedColumn<String> nutrientName = GeneratedColumn<String>(
    'nutrient_name',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 255,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _variantKeyMeta = const VerificationMeta(
    'variantKey',
  );
  @override
  late final GeneratedColumn<String> variantKey = GeneratedColumn<String>(
    'variant_key',
    aliasedName,
    true,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 0,
      maxTextLength: 128,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _variantNameMeta = const VerificationMeta(
    'variantName',
  );
  @override
  late final GeneratedColumn<String> variantName = GeneratedColumn<String>(
    'variant_name',
    aliasedName,
    true,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 0,
      maxTextLength: 255,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _compoundAmountMeta = const VerificationMeta(
    'compoundAmount',
  );
  @override
  late final GeneratedColumn<double> compoundAmount = GeneratedColumn<double>(
    'compound_amount',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _compoundUnitMeta = const VerificationMeta(
    'compoundUnit',
  );
  @override
  late final GeneratedColumn<String> compoundUnit = GeneratedColumn<String>(
    'compound_unit',
    aliasedName,
    true,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 0,
      maxTextLength: 32,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _elementalAmountMeta = const VerificationMeta(
    'elementalAmount',
  );
  @override
  late final GeneratedColumn<double> elementalAmount = GeneratedColumn<double>(
    'elemental_amount',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _elementalUnitMeta = const VerificationMeta(
    'elementalUnit',
  );
  @override
  late final GeneratedColumn<String> elementalUnit = GeneratedColumn<String>(
    'elemental_unit',
    aliasedName,
    true,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 0,
      maxTextLength: 32,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _amountAccuracyStatusMeta =
      const VerificationMeta('amountAccuracyStatus');
  @override
  late final GeneratedColumn<String> amountAccuracyStatus =
      GeneratedColumn<String>(
        'amount_accuracy_status',
        aliasedName,
        false,
        additionalChecks: GeneratedColumn.checkTextLength(
          minTextLength: 1,
          maxTextLength: 64,
        ),
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _sourceTextMeta = const VerificationMeta(
    'sourceText',
  );
  @override
  late final GeneratedColumn<String> sourceText = GeneratedColumn<String>(
    'source_text',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _confidenceMeta = const VerificationMeta(
    'confidence',
  );
  @override
  late final GeneratedColumn<int> confidence = GeneratedColumn<int>(
    'confidence',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    productId,
    nutrientKey,
    nutrientName,
    variantKey,
    variantName,
    compoundAmount,
    compoundUnit,
    elementalAmount,
    elementalUnit,
    amountAccuracyStatus,
    sourceText,
    confidence,
    note,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'product_ingredients';
  @override
  VerificationContext validateIntegrity(
    Insertable<ProductIngredient> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('product_id')) {
      context.handle(
        _productIdMeta,
        productId.isAcceptableOrUnknown(data['product_id']!, _productIdMeta),
      );
    }
    if (data.containsKey('nutrient_key')) {
      context.handle(
        _nutrientKeyMeta,
        nutrientKey.isAcceptableOrUnknown(
          data['nutrient_key']!,
          _nutrientKeyMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_nutrientKeyMeta);
    }
    if (data.containsKey('nutrient_name')) {
      context.handle(
        _nutrientNameMeta,
        nutrientName.isAcceptableOrUnknown(
          data['nutrient_name']!,
          _nutrientNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_nutrientNameMeta);
    }
    if (data.containsKey('variant_key')) {
      context.handle(
        _variantKeyMeta,
        variantKey.isAcceptableOrUnknown(data['variant_key']!, _variantKeyMeta),
      );
    }
    if (data.containsKey('variant_name')) {
      context.handle(
        _variantNameMeta,
        variantName.isAcceptableOrUnknown(
          data['variant_name']!,
          _variantNameMeta,
        ),
      );
    }
    if (data.containsKey('compound_amount')) {
      context.handle(
        _compoundAmountMeta,
        compoundAmount.isAcceptableOrUnknown(
          data['compound_amount']!,
          _compoundAmountMeta,
        ),
      );
    }
    if (data.containsKey('compound_unit')) {
      context.handle(
        _compoundUnitMeta,
        compoundUnit.isAcceptableOrUnknown(
          data['compound_unit']!,
          _compoundUnitMeta,
        ),
      );
    }
    if (data.containsKey('elemental_amount')) {
      context.handle(
        _elementalAmountMeta,
        elementalAmount.isAcceptableOrUnknown(
          data['elemental_amount']!,
          _elementalAmountMeta,
        ),
      );
    }
    if (data.containsKey('elemental_unit')) {
      context.handle(
        _elementalUnitMeta,
        elementalUnit.isAcceptableOrUnknown(
          data['elemental_unit']!,
          _elementalUnitMeta,
        ),
      );
    }
    if (data.containsKey('amount_accuracy_status')) {
      context.handle(
        _amountAccuracyStatusMeta,
        amountAccuracyStatus.isAcceptableOrUnknown(
          data['amount_accuracy_status']!,
          _amountAccuracyStatusMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_amountAccuracyStatusMeta);
    }
    if (data.containsKey('source_text')) {
      context.handle(
        _sourceTextMeta,
        sourceText.isAcceptableOrUnknown(data['source_text']!, _sourceTextMeta),
      );
    }
    if (data.containsKey('confidence')) {
      context.handle(
        _confidenceMeta,
        confidence.isAcceptableOrUnknown(data['confidence']!, _confidenceMeta),
      );
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ProductIngredient map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ProductIngredient(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      productId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}product_id'],
      ),
      nutrientKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}nutrient_key'],
      )!,
      nutrientName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}nutrient_name'],
      )!,
      variantKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}variant_key'],
      ),
      variantName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}variant_name'],
      ),
      compoundAmount: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}compound_amount'],
      ),
      compoundUnit: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}compound_unit'],
      ),
      elementalAmount: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}elemental_amount'],
      ),
      elementalUnit: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}elemental_unit'],
      ),
      amountAccuracyStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}amount_accuracy_status'],
      )!,
      sourceText: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_text'],
      ),
      confidence: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}confidence'],
      )!,
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $ProductIngredientsTable createAlias(String alias) {
    return $ProductIngredientsTable(attachedDatabase, alias);
  }
}

class ProductIngredient extends DataClass
    implements Insertable<ProductIngredient> {
  final int id;
  final int? productId;
  final String nutrientKey;
  final String nutrientName;
  final String? variantKey;
  final String? variantName;
  final double? compoundAmount;
  final String? compoundUnit;
  final double? elementalAmount;
  final String? elementalUnit;
  final String amountAccuracyStatus;
  final String? sourceText;
  final int confidence;
  final String? note;
  final DateTime createdAt;
  final DateTime updatedAt;
  const ProductIngredient({
    required this.id,
    this.productId,
    required this.nutrientKey,
    required this.nutrientName,
    this.variantKey,
    this.variantName,
    this.compoundAmount,
    this.compoundUnit,
    this.elementalAmount,
    this.elementalUnit,
    required this.amountAccuracyStatus,
    this.sourceText,
    required this.confidence,
    this.note,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    if (!nullToAbsent || productId != null) {
      map['product_id'] = Variable<int>(productId);
    }
    map['nutrient_key'] = Variable<String>(nutrientKey);
    map['nutrient_name'] = Variable<String>(nutrientName);
    if (!nullToAbsent || variantKey != null) {
      map['variant_key'] = Variable<String>(variantKey);
    }
    if (!nullToAbsent || variantName != null) {
      map['variant_name'] = Variable<String>(variantName);
    }
    if (!nullToAbsent || compoundAmount != null) {
      map['compound_amount'] = Variable<double>(compoundAmount);
    }
    if (!nullToAbsent || compoundUnit != null) {
      map['compound_unit'] = Variable<String>(compoundUnit);
    }
    if (!nullToAbsent || elementalAmount != null) {
      map['elemental_amount'] = Variable<double>(elementalAmount);
    }
    if (!nullToAbsent || elementalUnit != null) {
      map['elemental_unit'] = Variable<String>(elementalUnit);
    }
    map['amount_accuracy_status'] = Variable<String>(amountAccuracyStatus);
    if (!nullToAbsent || sourceText != null) {
      map['source_text'] = Variable<String>(sourceText);
    }
    map['confidence'] = Variable<int>(confidence);
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  ProductIngredientsCompanion toCompanion(bool nullToAbsent) {
    return ProductIngredientsCompanion(
      id: Value(id),
      productId: productId == null && nullToAbsent
          ? const Value.absent()
          : Value(productId),
      nutrientKey: Value(nutrientKey),
      nutrientName: Value(nutrientName),
      variantKey: variantKey == null && nullToAbsent
          ? const Value.absent()
          : Value(variantKey),
      variantName: variantName == null && nullToAbsent
          ? const Value.absent()
          : Value(variantName),
      compoundAmount: compoundAmount == null && nullToAbsent
          ? const Value.absent()
          : Value(compoundAmount),
      compoundUnit: compoundUnit == null && nullToAbsent
          ? const Value.absent()
          : Value(compoundUnit),
      elementalAmount: elementalAmount == null && nullToAbsent
          ? const Value.absent()
          : Value(elementalAmount),
      elementalUnit: elementalUnit == null && nullToAbsent
          ? const Value.absent()
          : Value(elementalUnit),
      amountAccuracyStatus: Value(amountAccuracyStatus),
      sourceText: sourceText == null && nullToAbsent
          ? const Value.absent()
          : Value(sourceText),
      confidence: Value(confidence),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory ProductIngredient.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ProductIngredient(
      id: serializer.fromJson<int>(json['id']),
      productId: serializer.fromJson<int?>(json['productId']),
      nutrientKey: serializer.fromJson<String>(json['nutrientKey']),
      nutrientName: serializer.fromJson<String>(json['nutrientName']),
      variantKey: serializer.fromJson<String?>(json['variantKey']),
      variantName: serializer.fromJson<String?>(json['variantName']),
      compoundAmount: serializer.fromJson<double?>(json['compoundAmount']),
      compoundUnit: serializer.fromJson<String?>(json['compoundUnit']),
      elementalAmount: serializer.fromJson<double?>(json['elementalAmount']),
      elementalUnit: serializer.fromJson<String?>(json['elementalUnit']),
      amountAccuracyStatus: serializer.fromJson<String>(
        json['amountAccuracyStatus'],
      ),
      sourceText: serializer.fromJson<String?>(json['sourceText']),
      confidence: serializer.fromJson<int>(json['confidence']),
      note: serializer.fromJson<String?>(json['note']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'productId': serializer.toJson<int?>(productId),
      'nutrientKey': serializer.toJson<String>(nutrientKey),
      'nutrientName': serializer.toJson<String>(nutrientName),
      'variantKey': serializer.toJson<String?>(variantKey),
      'variantName': serializer.toJson<String?>(variantName),
      'compoundAmount': serializer.toJson<double?>(compoundAmount),
      'compoundUnit': serializer.toJson<String?>(compoundUnit),
      'elementalAmount': serializer.toJson<double?>(elementalAmount),
      'elementalUnit': serializer.toJson<String?>(elementalUnit),
      'amountAccuracyStatus': serializer.toJson<String>(amountAccuracyStatus),
      'sourceText': serializer.toJson<String?>(sourceText),
      'confidence': serializer.toJson<int>(confidence),
      'note': serializer.toJson<String?>(note),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  ProductIngredient copyWith({
    int? id,
    Value<int?> productId = const Value.absent(),
    String? nutrientKey,
    String? nutrientName,
    Value<String?> variantKey = const Value.absent(),
    Value<String?> variantName = const Value.absent(),
    Value<double?> compoundAmount = const Value.absent(),
    Value<String?> compoundUnit = const Value.absent(),
    Value<double?> elementalAmount = const Value.absent(),
    Value<String?> elementalUnit = const Value.absent(),
    String? amountAccuracyStatus,
    Value<String?> sourceText = const Value.absent(),
    int? confidence,
    Value<String?> note = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => ProductIngredient(
    id: id ?? this.id,
    productId: productId.present ? productId.value : this.productId,
    nutrientKey: nutrientKey ?? this.nutrientKey,
    nutrientName: nutrientName ?? this.nutrientName,
    variantKey: variantKey.present ? variantKey.value : this.variantKey,
    variantName: variantName.present ? variantName.value : this.variantName,
    compoundAmount: compoundAmount.present
        ? compoundAmount.value
        : this.compoundAmount,
    compoundUnit: compoundUnit.present ? compoundUnit.value : this.compoundUnit,
    elementalAmount: elementalAmount.present
        ? elementalAmount.value
        : this.elementalAmount,
    elementalUnit: elementalUnit.present
        ? elementalUnit.value
        : this.elementalUnit,
    amountAccuracyStatus: amountAccuracyStatus ?? this.amountAccuracyStatus,
    sourceText: sourceText.present ? sourceText.value : this.sourceText,
    confidence: confidence ?? this.confidence,
    note: note.present ? note.value : this.note,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  ProductIngredient copyWithCompanion(ProductIngredientsCompanion data) {
    return ProductIngredient(
      id: data.id.present ? data.id.value : this.id,
      productId: data.productId.present ? data.productId.value : this.productId,
      nutrientKey: data.nutrientKey.present
          ? data.nutrientKey.value
          : this.nutrientKey,
      nutrientName: data.nutrientName.present
          ? data.nutrientName.value
          : this.nutrientName,
      variantKey: data.variantKey.present
          ? data.variantKey.value
          : this.variantKey,
      variantName: data.variantName.present
          ? data.variantName.value
          : this.variantName,
      compoundAmount: data.compoundAmount.present
          ? data.compoundAmount.value
          : this.compoundAmount,
      compoundUnit: data.compoundUnit.present
          ? data.compoundUnit.value
          : this.compoundUnit,
      elementalAmount: data.elementalAmount.present
          ? data.elementalAmount.value
          : this.elementalAmount,
      elementalUnit: data.elementalUnit.present
          ? data.elementalUnit.value
          : this.elementalUnit,
      amountAccuracyStatus: data.amountAccuracyStatus.present
          ? data.amountAccuracyStatus.value
          : this.amountAccuracyStatus,
      sourceText: data.sourceText.present
          ? data.sourceText.value
          : this.sourceText,
      confidence: data.confidence.present
          ? data.confidence.value
          : this.confidence,
      note: data.note.present ? data.note.value : this.note,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ProductIngredient(')
          ..write('id: $id, ')
          ..write('productId: $productId, ')
          ..write('nutrientKey: $nutrientKey, ')
          ..write('nutrientName: $nutrientName, ')
          ..write('variantKey: $variantKey, ')
          ..write('variantName: $variantName, ')
          ..write('compoundAmount: $compoundAmount, ')
          ..write('compoundUnit: $compoundUnit, ')
          ..write('elementalAmount: $elementalAmount, ')
          ..write('elementalUnit: $elementalUnit, ')
          ..write('amountAccuracyStatus: $amountAccuracyStatus, ')
          ..write('sourceText: $sourceText, ')
          ..write('confidence: $confidence, ')
          ..write('note: $note, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    productId,
    nutrientKey,
    nutrientName,
    variantKey,
    variantName,
    compoundAmount,
    compoundUnit,
    elementalAmount,
    elementalUnit,
    amountAccuracyStatus,
    sourceText,
    confidence,
    note,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ProductIngredient &&
          other.id == this.id &&
          other.productId == this.productId &&
          other.nutrientKey == this.nutrientKey &&
          other.nutrientName == this.nutrientName &&
          other.variantKey == this.variantKey &&
          other.variantName == this.variantName &&
          other.compoundAmount == this.compoundAmount &&
          other.compoundUnit == this.compoundUnit &&
          other.elementalAmount == this.elementalAmount &&
          other.elementalUnit == this.elementalUnit &&
          other.amountAccuracyStatus == this.amountAccuracyStatus &&
          other.sourceText == this.sourceText &&
          other.confidence == this.confidence &&
          other.note == this.note &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class ProductIngredientsCompanion extends UpdateCompanion<ProductIngredient> {
  final Value<int> id;
  final Value<int?> productId;
  final Value<String> nutrientKey;
  final Value<String> nutrientName;
  final Value<String?> variantKey;
  final Value<String?> variantName;
  final Value<double?> compoundAmount;
  final Value<String?> compoundUnit;
  final Value<double?> elementalAmount;
  final Value<String?> elementalUnit;
  final Value<String> amountAccuracyStatus;
  final Value<String?> sourceText;
  final Value<int> confidence;
  final Value<String?> note;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  const ProductIngredientsCompanion({
    this.id = const Value.absent(),
    this.productId = const Value.absent(),
    this.nutrientKey = const Value.absent(),
    this.nutrientName = const Value.absent(),
    this.variantKey = const Value.absent(),
    this.variantName = const Value.absent(),
    this.compoundAmount = const Value.absent(),
    this.compoundUnit = const Value.absent(),
    this.elementalAmount = const Value.absent(),
    this.elementalUnit = const Value.absent(),
    this.amountAccuracyStatus = const Value.absent(),
    this.sourceText = const Value.absent(),
    this.confidence = const Value.absent(),
    this.note = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  ProductIngredientsCompanion.insert({
    this.id = const Value.absent(),
    this.productId = const Value.absent(),
    required String nutrientKey,
    required String nutrientName,
    this.variantKey = const Value.absent(),
    this.variantName = const Value.absent(),
    this.compoundAmount = const Value.absent(),
    this.compoundUnit = const Value.absent(),
    this.elementalAmount = const Value.absent(),
    this.elementalUnit = const Value.absent(),
    required String amountAccuracyStatus,
    this.sourceText = const Value.absent(),
    this.confidence = const Value.absent(),
    this.note = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  }) : nutrientKey = Value(nutrientKey),
       nutrientName = Value(nutrientName),
       amountAccuracyStatus = Value(amountAccuracyStatus);
  static Insertable<ProductIngredient> custom({
    Expression<int>? id,
    Expression<int>? productId,
    Expression<String>? nutrientKey,
    Expression<String>? nutrientName,
    Expression<String>? variantKey,
    Expression<String>? variantName,
    Expression<double>? compoundAmount,
    Expression<String>? compoundUnit,
    Expression<double>? elementalAmount,
    Expression<String>? elementalUnit,
    Expression<String>? amountAccuracyStatus,
    Expression<String>? sourceText,
    Expression<int>? confidence,
    Expression<String>? note,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (productId != null) 'product_id': productId,
      if (nutrientKey != null) 'nutrient_key': nutrientKey,
      if (nutrientName != null) 'nutrient_name': nutrientName,
      if (variantKey != null) 'variant_key': variantKey,
      if (variantName != null) 'variant_name': variantName,
      if (compoundAmount != null) 'compound_amount': compoundAmount,
      if (compoundUnit != null) 'compound_unit': compoundUnit,
      if (elementalAmount != null) 'elemental_amount': elementalAmount,
      if (elementalUnit != null) 'elemental_unit': elementalUnit,
      if (amountAccuracyStatus != null)
        'amount_accuracy_status': amountAccuracyStatus,
      if (sourceText != null) 'source_text': sourceText,
      if (confidence != null) 'confidence': confidence,
      if (note != null) 'note': note,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  ProductIngredientsCompanion copyWith({
    Value<int>? id,
    Value<int?>? productId,
    Value<String>? nutrientKey,
    Value<String>? nutrientName,
    Value<String?>? variantKey,
    Value<String?>? variantName,
    Value<double?>? compoundAmount,
    Value<String?>? compoundUnit,
    Value<double?>? elementalAmount,
    Value<String?>? elementalUnit,
    Value<String>? amountAccuracyStatus,
    Value<String?>? sourceText,
    Value<int>? confidence,
    Value<String?>? note,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
  }) {
    return ProductIngredientsCompanion(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      nutrientKey: nutrientKey ?? this.nutrientKey,
      nutrientName: nutrientName ?? this.nutrientName,
      variantKey: variantKey ?? this.variantKey,
      variantName: variantName ?? this.variantName,
      compoundAmount: compoundAmount ?? this.compoundAmount,
      compoundUnit: compoundUnit ?? this.compoundUnit,
      elementalAmount: elementalAmount ?? this.elementalAmount,
      elementalUnit: elementalUnit ?? this.elementalUnit,
      amountAccuracyStatus: amountAccuracyStatus ?? this.amountAccuracyStatus,
      sourceText: sourceText ?? this.sourceText,
      confidence: confidence ?? this.confidence,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
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
    if (nutrientKey.present) {
      map['nutrient_key'] = Variable<String>(nutrientKey.value);
    }
    if (nutrientName.present) {
      map['nutrient_name'] = Variable<String>(nutrientName.value);
    }
    if (variantKey.present) {
      map['variant_key'] = Variable<String>(variantKey.value);
    }
    if (variantName.present) {
      map['variant_name'] = Variable<String>(variantName.value);
    }
    if (compoundAmount.present) {
      map['compound_amount'] = Variable<double>(compoundAmount.value);
    }
    if (compoundUnit.present) {
      map['compound_unit'] = Variable<String>(compoundUnit.value);
    }
    if (elementalAmount.present) {
      map['elemental_amount'] = Variable<double>(elementalAmount.value);
    }
    if (elementalUnit.present) {
      map['elemental_unit'] = Variable<String>(elementalUnit.value);
    }
    if (amountAccuracyStatus.present) {
      map['amount_accuracy_status'] = Variable<String>(
        amountAccuracyStatus.value,
      );
    }
    if (sourceText.present) {
      map['source_text'] = Variable<String>(sourceText.value);
    }
    if (confidence.present) {
      map['confidence'] = Variable<int>(confidence.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ProductIngredientsCompanion(')
          ..write('id: $id, ')
          ..write('productId: $productId, ')
          ..write('nutrientKey: $nutrientKey, ')
          ..write('nutrientName: $nutrientName, ')
          ..write('variantKey: $variantKey, ')
          ..write('variantName: $variantName, ')
          ..write('compoundAmount: $compoundAmount, ')
          ..write('compoundUnit: $compoundUnit, ')
          ..write('elementalAmount: $elementalAmount, ')
          ..write('elementalUnit: $elementalUnit, ')
          ..write('amountAccuracyStatus: $amountAccuracyStatus, ')
          ..write('sourceText: $sourceText, ')
          ..write('confidence: $confidence, ')
          ..write('note: $note, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $ProductsTable products = $ProductsTable(this);
  late final $ProductIngredientsTable productIngredients =
      $ProductIngredientsTable(this);
  late final ProductDao productDao = ProductDao(this as AppDatabase);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    products,
    productIngredients,
  ];
}

typedef $$ProductsTableCreateCompanionBuilder =
    ProductsCompanion Function({
      Value<int> id,
      required String name,
      Value<String?> brand,
      Value<double?> price,
      Value<String> currency,
      Value<int> totalQuantity,
      Value<double> servingSize,
      Value<String?> servingType,
      Value<String?> imagePath,
      Value<String?> note,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
    });
typedef $$ProductsTableUpdateCompanionBuilder =
    ProductsCompanion Function({
      Value<int> id,
      Value<String> name,
      Value<String?> brand,
      Value<double?> price,
      Value<String> currency,
      Value<int> totalQuantity,
      Value<double> servingSize,
      Value<String?> servingType,
      Value<String?> imagePath,
      Value<String?> note,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
    });

final class $$ProductsTableReferences
    extends BaseReferences<_$AppDatabase, $ProductsTable, Product> {
  $$ProductsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$ProductIngredientsTable, List<ProductIngredient>>
  _productIngredientsRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.productIngredients,
        aliasName: $_aliasNameGenerator(
          db.products.id,
          db.productIngredients.productId,
        ),
      );

  $$ProductIngredientsTableProcessedTableManager get productIngredientsRefs {
    final manager = $$ProductIngredientsTableTableManager(
      $_db,
      $_db.productIngredients,
    ).filter((f) => f.productId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _productIngredientsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
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
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get brand => $composableBuilder(
    column: $table.brand,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get price => $composableBuilder(
    column: $table.price,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get currency => $composableBuilder(
    column: $table.currency,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get totalQuantity => $composableBuilder(
    column: $table.totalQuantity,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get servingSize => $composableBuilder(
    column: $table.servingSize,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get servingType => $composableBuilder(
    column: $table.servingType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get imagePath => $composableBuilder(
    column: $table.imagePath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> productIngredientsRefs(
    Expression<bool> Function($$ProductIngredientsTableFilterComposer f) f,
  ) {
    final $$ProductIngredientsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.productIngredients,
      getReferencedColumn: (t) => t.productId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProductIngredientsTableFilterComposer(
            $db: $db,
            $table: $db.productIngredients,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
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
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get brand => $composableBuilder(
    column: $table.brand,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get price => $composableBuilder(
    column: $table.price,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get currency => $composableBuilder(
    column: $table.currency,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get totalQuantity => $composableBuilder(
    column: $table.totalQuantity,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get servingSize => $composableBuilder(
    column: $table.servingSize,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get servingType => $composableBuilder(
    column: $table.servingType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get imagePath => $composableBuilder(
    column: $table.imagePath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
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

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get brand =>
      $composableBuilder(column: $table.brand, builder: (column) => column);

  GeneratedColumn<double> get price =>
      $composableBuilder(column: $table.price, builder: (column) => column);

  GeneratedColumn<String> get currency =>
      $composableBuilder(column: $table.currency, builder: (column) => column);

  GeneratedColumn<int> get totalQuantity => $composableBuilder(
    column: $table.totalQuantity,
    builder: (column) => column,
  );

  GeneratedColumn<double> get servingSize => $composableBuilder(
    column: $table.servingSize,
    builder: (column) => column,
  );

  GeneratedColumn<String> get servingType => $composableBuilder(
    column: $table.servingType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get imagePath =>
      $composableBuilder(column: $table.imagePath, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  Expression<T> productIngredientsRefs<T extends Object>(
    Expression<T> Function($$ProductIngredientsTableAnnotationComposer a) f,
  ) {
    final $$ProductIngredientsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.productIngredients,
          getReferencedColumn: (t) => t.productId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$ProductIngredientsTableAnnotationComposer(
                $db: $db,
                $table: $db.productIngredients,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$ProductsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ProductsTable,
          Product,
          $$ProductsTableFilterComposer,
          $$ProductsTableOrderingComposer,
          $$ProductsTableAnnotationComposer,
          $$ProductsTableCreateCompanionBuilder,
          $$ProductsTableUpdateCompanionBuilder,
          (Product, $$ProductsTableReferences),
          Product,
          PrefetchHooks Function({bool productIngredientsRefs})
        > {
  $$ProductsTableTableManager(_$AppDatabase db, $ProductsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ProductsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ProductsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ProductsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> brand = const Value.absent(),
                Value<double?> price = const Value.absent(),
                Value<String> currency = const Value.absent(),
                Value<int> totalQuantity = const Value.absent(),
                Value<double> servingSize = const Value.absent(),
                Value<String?> servingType = const Value.absent(),
                Value<String?> imagePath = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => ProductsCompanion(
                id: id,
                name: name,
                brand: brand,
                price: price,
                currency: currency,
                totalQuantity: totalQuantity,
                servingSize: servingSize,
                servingType: servingType,
                imagePath: imagePath,
                note: note,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String name,
                Value<String?> brand = const Value.absent(),
                Value<double?> price = const Value.absent(),
                Value<String> currency = const Value.absent(),
                Value<int> totalQuantity = const Value.absent(),
                Value<double> servingSize = const Value.absent(),
                Value<String?> servingType = const Value.absent(),
                Value<String?> imagePath = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => ProductsCompanion.insert(
                id: id,
                name: name,
                brand: brand,
                price: price,
                currency: currency,
                totalQuantity: totalQuantity,
                servingSize: servingSize,
                servingType: servingType,
                imagePath: imagePath,
                note: note,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$ProductsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({productIngredientsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (productIngredientsRefs) db.productIngredients,
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (productIngredientsRefs)
                    await $_getPrefetchedData<
                      Product,
                      $ProductsTable,
                      ProductIngredient
                    >(
                      currentTable: table,
                      referencedTable: $$ProductsTableReferences
                          ._productIngredientsRefsTable(db),
                      managerFromTypedResult: (p0) => $$ProductsTableReferences(
                        db,
                        table,
                        p0,
                      ).productIngredientsRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.productId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$ProductsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ProductsTable,
      Product,
      $$ProductsTableFilterComposer,
      $$ProductsTableOrderingComposer,
      $$ProductsTableAnnotationComposer,
      $$ProductsTableCreateCompanionBuilder,
      $$ProductsTableUpdateCompanionBuilder,
      (Product, $$ProductsTableReferences),
      Product,
      PrefetchHooks Function({bool productIngredientsRefs})
    >;
typedef $$ProductIngredientsTableCreateCompanionBuilder =
    ProductIngredientsCompanion Function({
      Value<int> id,
      Value<int?> productId,
      required String nutrientKey,
      required String nutrientName,
      Value<String?> variantKey,
      Value<String?> variantName,
      Value<double?> compoundAmount,
      Value<String?> compoundUnit,
      Value<double?> elementalAmount,
      Value<String?> elementalUnit,
      required String amountAccuracyStatus,
      Value<String?> sourceText,
      Value<int> confidence,
      Value<String?> note,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
    });
typedef $$ProductIngredientsTableUpdateCompanionBuilder =
    ProductIngredientsCompanion Function({
      Value<int> id,
      Value<int?> productId,
      Value<String> nutrientKey,
      Value<String> nutrientName,
      Value<String?> variantKey,
      Value<String?> variantName,
      Value<double?> compoundAmount,
      Value<String?> compoundUnit,
      Value<double?> elementalAmount,
      Value<String?> elementalUnit,
      Value<String> amountAccuracyStatus,
      Value<String?> sourceText,
      Value<int> confidence,
      Value<String?> note,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
    });

final class $$ProductIngredientsTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $ProductIngredientsTable,
          ProductIngredient
        > {
  $$ProductIngredientsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $ProductsTable _productIdTable(_$AppDatabase db) =>
      db.products.createAlias(
        $_aliasNameGenerator(db.productIngredients.productId, db.products.id),
      );

  $$ProductsTableProcessedTableManager? get productId {
    final $_column = $_itemColumn<int>('product_id');
    if ($_column == null) return null;
    final manager = $$ProductsTableTableManager(
      $_db,
      $_db.products,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_productIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$ProductIngredientsTableFilterComposer
    extends Composer<_$AppDatabase, $ProductIngredientsTable> {
  $$ProductIngredientsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nutrientKey => $composableBuilder(
    column: $table.nutrientKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nutrientName => $composableBuilder(
    column: $table.nutrientName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get variantKey => $composableBuilder(
    column: $table.variantKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get variantName => $composableBuilder(
    column: $table.variantName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get compoundAmount => $composableBuilder(
    column: $table.compoundAmount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get compoundUnit => $composableBuilder(
    column: $table.compoundUnit,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get elementalAmount => $composableBuilder(
    column: $table.elementalAmount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get elementalUnit => $composableBuilder(
    column: $table.elementalUnit,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get amountAccuracyStatus => $composableBuilder(
    column: $table.amountAccuracyStatus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sourceText => $composableBuilder(
    column: $table.sourceText,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get confidence => $composableBuilder(
    column: $table.confidence,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$ProductsTableFilterComposer get productId {
    final $$ProductsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.productId,
      referencedTable: $db.products,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProductsTableFilterComposer(
            $db: $db,
            $table: $db.products,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ProductIngredientsTableOrderingComposer
    extends Composer<_$AppDatabase, $ProductIngredientsTable> {
  $$ProductIngredientsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nutrientKey => $composableBuilder(
    column: $table.nutrientKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nutrientName => $composableBuilder(
    column: $table.nutrientName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get variantKey => $composableBuilder(
    column: $table.variantKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get variantName => $composableBuilder(
    column: $table.variantName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get compoundAmount => $composableBuilder(
    column: $table.compoundAmount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get compoundUnit => $composableBuilder(
    column: $table.compoundUnit,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get elementalAmount => $composableBuilder(
    column: $table.elementalAmount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get elementalUnit => $composableBuilder(
    column: $table.elementalUnit,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get amountAccuracyStatus => $composableBuilder(
    column: $table.amountAccuracyStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sourceText => $composableBuilder(
    column: $table.sourceText,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get confidence => $composableBuilder(
    column: $table.confidence,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$ProductsTableOrderingComposer get productId {
    final $$ProductsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.productId,
      referencedTable: $db.products,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProductsTableOrderingComposer(
            $db: $db,
            $table: $db.products,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ProductIngredientsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ProductIngredientsTable> {
  $$ProductIngredientsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get nutrientKey => $composableBuilder(
    column: $table.nutrientKey,
    builder: (column) => column,
  );

  GeneratedColumn<String> get nutrientName => $composableBuilder(
    column: $table.nutrientName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get variantKey => $composableBuilder(
    column: $table.variantKey,
    builder: (column) => column,
  );

  GeneratedColumn<String> get variantName => $composableBuilder(
    column: $table.variantName,
    builder: (column) => column,
  );

  GeneratedColumn<double> get compoundAmount => $composableBuilder(
    column: $table.compoundAmount,
    builder: (column) => column,
  );

  GeneratedColumn<String> get compoundUnit => $composableBuilder(
    column: $table.compoundUnit,
    builder: (column) => column,
  );

  GeneratedColumn<double> get elementalAmount => $composableBuilder(
    column: $table.elementalAmount,
    builder: (column) => column,
  );

  GeneratedColumn<String> get elementalUnit => $composableBuilder(
    column: $table.elementalUnit,
    builder: (column) => column,
  );

  GeneratedColumn<String> get amountAccuracyStatus => $composableBuilder(
    column: $table.amountAccuracyStatus,
    builder: (column) => column,
  );

  GeneratedColumn<String> get sourceText => $composableBuilder(
    column: $table.sourceText,
    builder: (column) => column,
  );

  GeneratedColumn<int> get confidence => $composableBuilder(
    column: $table.confidence,
    builder: (column) => column,
  );

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$ProductsTableAnnotationComposer get productId {
    final $$ProductsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.productId,
      referencedTable: $db.products,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProductsTableAnnotationComposer(
            $db: $db,
            $table: $db.products,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ProductIngredientsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ProductIngredientsTable,
          ProductIngredient,
          $$ProductIngredientsTableFilterComposer,
          $$ProductIngredientsTableOrderingComposer,
          $$ProductIngredientsTableAnnotationComposer,
          $$ProductIngredientsTableCreateCompanionBuilder,
          $$ProductIngredientsTableUpdateCompanionBuilder,
          (ProductIngredient, $$ProductIngredientsTableReferences),
          ProductIngredient,
          PrefetchHooks Function({bool productId})
        > {
  $$ProductIngredientsTableTableManager(
    _$AppDatabase db,
    $ProductIngredientsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ProductIngredientsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ProductIngredientsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ProductIngredientsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int?> productId = const Value.absent(),
                Value<String> nutrientKey = const Value.absent(),
                Value<String> nutrientName = const Value.absent(),
                Value<String?> variantKey = const Value.absent(),
                Value<String?> variantName = const Value.absent(),
                Value<double?> compoundAmount = const Value.absent(),
                Value<String?> compoundUnit = const Value.absent(),
                Value<double?> elementalAmount = const Value.absent(),
                Value<String?> elementalUnit = const Value.absent(),
                Value<String> amountAccuracyStatus = const Value.absent(),
                Value<String?> sourceText = const Value.absent(),
                Value<int> confidence = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => ProductIngredientsCompanion(
                id: id,
                productId: productId,
                nutrientKey: nutrientKey,
                nutrientName: nutrientName,
                variantKey: variantKey,
                variantName: variantName,
                compoundAmount: compoundAmount,
                compoundUnit: compoundUnit,
                elementalAmount: elementalAmount,
                elementalUnit: elementalUnit,
                amountAccuracyStatus: amountAccuracyStatus,
                sourceText: sourceText,
                confidence: confidence,
                note: note,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int?> productId = const Value.absent(),
                required String nutrientKey,
                required String nutrientName,
                Value<String?> variantKey = const Value.absent(),
                Value<String?> variantName = const Value.absent(),
                Value<double?> compoundAmount = const Value.absent(),
                Value<String?> compoundUnit = const Value.absent(),
                Value<double?> elementalAmount = const Value.absent(),
                Value<String?> elementalUnit = const Value.absent(),
                required String amountAccuracyStatus,
                Value<String?> sourceText = const Value.absent(),
                Value<int> confidence = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => ProductIngredientsCompanion.insert(
                id: id,
                productId: productId,
                nutrientKey: nutrientKey,
                nutrientName: nutrientName,
                variantKey: variantKey,
                variantName: variantName,
                compoundAmount: compoundAmount,
                compoundUnit: compoundUnit,
                elementalAmount: elementalAmount,
                elementalUnit: elementalUnit,
                amountAccuracyStatus: amountAccuracyStatus,
                sourceText: sourceText,
                confidence: confidence,
                note: note,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$ProductIngredientsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({productId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
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
                      dynamic
                    >
                  >(state) {
                    if (productId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.productId,
                                referencedTable:
                                    $$ProductIngredientsTableReferences
                                        ._productIdTable(db),
                                referencedColumn:
                                    $$ProductIngredientsTableReferences
                                        ._productIdTable(db)
                                        .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$ProductIngredientsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ProductIngredientsTable,
      ProductIngredient,
      $$ProductIngredientsTableFilterComposer,
      $$ProductIngredientsTableOrderingComposer,
      $$ProductIngredientsTableAnnotationComposer,
      $$ProductIngredientsTableCreateCompanionBuilder,
      $$ProductIngredientsTableUpdateCompanionBuilder,
      (ProductIngredient, $$ProductIngredientsTableReferences),
      ProductIngredient,
      PrefetchHooks Function({bool productId})
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$ProductsTableTableManager get products =>
      $$ProductsTableTableManager(_db, _db.products);
  $$ProductIngredientsTableTableManager get productIngredients =>
      $$ProductIngredientsTableTableManager(_db, _db.productIngredients);
}
