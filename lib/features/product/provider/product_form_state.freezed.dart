// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'product_form_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ProductIngredientFormState {

 int? get id; String get nutrientKey; String get nutrientName; String get variantKey; String get variantName; double? get compoundAmount; String get compoundUnit; double? get elementalAmount; String get elementalUnit; AmountAccuracyStatus get amountAccuracyStatus; String get note; String get sourceText; int get confidence;
/// Create a copy of ProductIngredientFormState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProductIngredientFormStateCopyWith<ProductIngredientFormState> get copyWith => _$ProductIngredientFormStateCopyWithImpl<ProductIngredientFormState>(this as ProductIngredientFormState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProductIngredientFormState&&(identical(other.id, id) || other.id == id)&&(identical(other.nutrientKey, nutrientKey) || other.nutrientKey == nutrientKey)&&(identical(other.nutrientName, nutrientName) || other.nutrientName == nutrientName)&&(identical(other.variantKey, variantKey) || other.variantKey == variantKey)&&(identical(other.variantName, variantName) || other.variantName == variantName)&&(identical(other.compoundAmount, compoundAmount) || other.compoundAmount == compoundAmount)&&(identical(other.compoundUnit, compoundUnit) || other.compoundUnit == compoundUnit)&&(identical(other.elementalAmount, elementalAmount) || other.elementalAmount == elementalAmount)&&(identical(other.elementalUnit, elementalUnit) || other.elementalUnit == elementalUnit)&&(identical(other.amountAccuracyStatus, amountAccuracyStatus) || other.amountAccuracyStatus == amountAccuracyStatus)&&(identical(other.note, note) || other.note == note)&&(identical(other.sourceText, sourceText) || other.sourceText == sourceText)&&(identical(other.confidence, confidence) || other.confidence == confidence));
}


@override
int get hashCode => Object.hash(runtimeType,id,nutrientKey,nutrientName,variantKey,variantName,compoundAmount,compoundUnit,elementalAmount,elementalUnit,amountAccuracyStatus,note,sourceText,confidence);

@override
String toString() {
  return 'ProductIngredientFormState(id: $id, nutrientKey: $nutrientKey, nutrientName: $nutrientName, variantKey: $variantKey, variantName: $variantName, compoundAmount: $compoundAmount, compoundUnit: $compoundUnit, elementalAmount: $elementalAmount, elementalUnit: $elementalUnit, amountAccuracyStatus: $amountAccuracyStatus, note: $note, sourceText: $sourceText, confidence: $confidence)';
}


}

/// @nodoc
abstract mixin class $ProductIngredientFormStateCopyWith<$Res>  {
  factory $ProductIngredientFormStateCopyWith(ProductIngredientFormState value, $Res Function(ProductIngredientFormState) _then) = _$ProductIngredientFormStateCopyWithImpl;
@useResult
$Res call({
 int? id, String nutrientKey, String nutrientName, String variantKey, String variantName, double? compoundAmount, String compoundUnit, double? elementalAmount, String elementalUnit, AmountAccuracyStatus amountAccuracyStatus, String note, String sourceText, int confidence
});




}
/// @nodoc
class _$ProductIngredientFormStateCopyWithImpl<$Res>
    implements $ProductIngredientFormStateCopyWith<$Res> {
  _$ProductIngredientFormStateCopyWithImpl(this._self, this._then);

  final ProductIngredientFormState _self;
  final $Res Function(ProductIngredientFormState) _then;

/// Create a copy of ProductIngredientFormState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = freezed,Object? nutrientKey = null,Object? nutrientName = null,Object? variantKey = null,Object? variantName = null,Object? compoundAmount = freezed,Object? compoundUnit = null,Object? elementalAmount = freezed,Object? elementalUnit = null,Object? amountAccuracyStatus = null,Object? note = null,Object? sourceText = null,Object? confidence = null,}) {
  return _then(_self.copyWith(
id: freezed == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int?,nutrientKey: null == nutrientKey ? _self.nutrientKey : nutrientKey // ignore: cast_nullable_to_non_nullable
as String,nutrientName: null == nutrientName ? _self.nutrientName : nutrientName // ignore: cast_nullable_to_non_nullable
as String,variantKey: null == variantKey ? _self.variantKey : variantKey // ignore: cast_nullable_to_non_nullable
as String,variantName: null == variantName ? _self.variantName : variantName // ignore: cast_nullable_to_non_nullable
as String,compoundAmount: freezed == compoundAmount ? _self.compoundAmount : compoundAmount // ignore: cast_nullable_to_non_nullable
as double?,compoundUnit: null == compoundUnit ? _self.compoundUnit : compoundUnit // ignore: cast_nullable_to_non_nullable
as String,elementalAmount: freezed == elementalAmount ? _self.elementalAmount : elementalAmount // ignore: cast_nullable_to_non_nullable
as double?,elementalUnit: null == elementalUnit ? _self.elementalUnit : elementalUnit // ignore: cast_nullable_to_non_nullable
as String,amountAccuracyStatus: null == amountAccuracyStatus ? _self.amountAccuracyStatus : amountAccuracyStatus // ignore: cast_nullable_to_non_nullable
as AmountAccuracyStatus,note: null == note ? _self.note : note // ignore: cast_nullable_to_non_nullable
as String,sourceText: null == sourceText ? _self.sourceText : sourceText // ignore: cast_nullable_to_non_nullable
as String,confidence: null == confidence ? _self.confidence : confidence // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [ProductIngredientFormState].
extension ProductIngredientFormStatePatterns on ProductIngredientFormState {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ProductIngredientFormState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ProductIngredientFormState() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ProductIngredientFormState value)  $default,){
final _that = this;
switch (_that) {
case _ProductIngredientFormState():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ProductIngredientFormState value)?  $default,){
final _that = this;
switch (_that) {
case _ProductIngredientFormState() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int? id,  String nutrientKey,  String nutrientName,  String variantKey,  String variantName,  double? compoundAmount,  String compoundUnit,  double? elementalAmount,  String elementalUnit,  AmountAccuracyStatus amountAccuracyStatus,  String note,  String sourceText,  int confidence)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ProductIngredientFormState() when $default != null:
return $default(_that.id,_that.nutrientKey,_that.nutrientName,_that.variantKey,_that.variantName,_that.compoundAmount,_that.compoundUnit,_that.elementalAmount,_that.elementalUnit,_that.amountAccuracyStatus,_that.note,_that.sourceText,_that.confidence);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int? id,  String nutrientKey,  String nutrientName,  String variantKey,  String variantName,  double? compoundAmount,  String compoundUnit,  double? elementalAmount,  String elementalUnit,  AmountAccuracyStatus amountAccuracyStatus,  String note,  String sourceText,  int confidence)  $default,) {final _that = this;
switch (_that) {
case _ProductIngredientFormState():
return $default(_that.id,_that.nutrientKey,_that.nutrientName,_that.variantKey,_that.variantName,_that.compoundAmount,_that.compoundUnit,_that.elementalAmount,_that.elementalUnit,_that.amountAccuracyStatus,_that.note,_that.sourceText,_that.confidence);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int? id,  String nutrientKey,  String nutrientName,  String variantKey,  String variantName,  double? compoundAmount,  String compoundUnit,  double? elementalAmount,  String elementalUnit,  AmountAccuracyStatus amountAccuracyStatus,  String note,  String sourceText,  int confidence)?  $default,) {final _that = this;
switch (_that) {
case _ProductIngredientFormState() when $default != null:
return $default(_that.id,_that.nutrientKey,_that.nutrientName,_that.variantKey,_that.variantName,_that.compoundAmount,_that.compoundUnit,_that.elementalAmount,_that.elementalUnit,_that.amountAccuracyStatus,_that.note,_that.sourceText,_that.confidence);case _:
  return null;

}
}

}

/// @nodoc


class _ProductIngredientFormState implements ProductIngredientFormState {
  const _ProductIngredientFormState({this.id, this.nutrientKey = '', this.nutrientName = '', this.variantKey = '', this.variantName = '', this.compoundAmount, this.compoundUnit = '', this.elementalAmount, this.elementalUnit = '', this.amountAccuracyStatus = AmountAccuracyStatus.unknown, this.note = '', this.sourceText = '', this.confidence = 0});
  

@override final  int? id;
@override@JsonKey() final  String nutrientKey;
@override@JsonKey() final  String nutrientName;
@override@JsonKey() final  String variantKey;
@override@JsonKey() final  String variantName;
@override final  double? compoundAmount;
@override@JsonKey() final  String compoundUnit;
@override final  double? elementalAmount;
@override@JsonKey() final  String elementalUnit;
@override@JsonKey() final  AmountAccuracyStatus amountAccuracyStatus;
@override@JsonKey() final  String note;
@override@JsonKey() final  String sourceText;
@override@JsonKey() final  int confidence;

/// Create a copy of ProductIngredientFormState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ProductIngredientFormStateCopyWith<_ProductIngredientFormState> get copyWith => __$ProductIngredientFormStateCopyWithImpl<_ProductIngredientFormState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ProductIngredientFormState&&(identical(other.id, id) || other.id == id)&&(identical(other.nutrientKey, nutrientKey) || other.nutrientKey == nutrientKey)&&(identical(other.nutrientName, nutrientName) || other.nutrientName == nutrientName)&&(identical(other.variantKey, variantKey) || other.variantKey == variantKey)&&(identical(other.variantName, variantName) || other.variantName == variantName)&&(identical(other.compoundAmount, compoundAmount) || other.compoundAmount == compoundAmount)&&(identical(other.compoundUnit, compoundUnit) || other.compoundUnit == compoundUnit)&&(identical(other.elementalAmount, elementalAmount) || other.elementalAmount == elementalAmount)&&(identical(other.elementalUnit, elementalUnit) || other.elementalUnit == elementalUnit)&&(identical(other.amountAccuracyStatus, amountAccuracyStatus) || other.amountAccuracyStatus == amountAccuracyStatus)&&(identical(other.note, note) || other.note == note)&&(identical(other.sourceText, sourceText) || other.sourceText == sourceText)&&(identical(other.confidence, confidence) || other.confidence == confidence));
}


@override
int get hashCode => Object.hash(runtimeType,id,nutrientKey,nutrientName,variantKey,variantName,compoundAmount,compoundUnit,elementalAmount,elementalUnit,amountAccuracyStatus,note,sourceText,confidence);

@override
String toString() {
  return 'ProductIngredientFormState(id: $id, nutrientKey: $nutrientKey, nutrientName: $nutrientName, variantKey: $variantKey, variantName: $variantName, compoundAmount: $compoundAmount, compoundUnit: $compoundUnit, elementalAmount: $elementalAmount, elementalUnit: $elementalUnit, amountAccuracyStatus: $amountAccuracyStatus, note: $note, sourceText: $sourceText, confidence: $confidence)';
}


}

/// @nodoc
abstract mixin class _$ProductIngredientFormStateCopyWith<$Res> implements $ProductIngredientFormStateCopyWith<$Res> {
  factory _$ProductIngredientFormStateCopyWith(_ProductIngredientFormState value, $Res Function(_ProductIngredientFormState) _then) = __$ProductIngredientFormStateCopyWithImpl;
@override @useResult
$Res call({
 int? id, String nutrientKey, String nutrientName, String variantKey, String variantName, double? compoundAmount, String compoundUnit, double? elementalAmount, String elementalUnit, AmountAccuracyStatus amountAccuracyStatus, String note, String sourceText, int confidence
});




}
/// @nodoc
class __$ProductIngredientFormStateCopyWithImpl<$Res>
    implements _$ProductIngredientFormStateCopyWith<$Res> {
  __$ProductIngredientFormStateCopyWithImpl(this._self, this._then);

  final _ProductIngredientFormState _self;
  final $Res Function(_ProductIngredientFormState) _then;

/// Create a copy of ProductIngredientFormState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = freezed,Object? nutrientKey = null,Object? nutrientName = null,Object? variantKey = null,Object? variantName = null,Object? compoundAmount = freezed,Object? compoundUnit = null,Object? elementalAmount = freezed,Object? elementalUnit = null,Object? amountAccuracyStatus = null,Object? note = null,Object? sourceText = null,Object? confidence = null,}) {
  return _then(_ProductIngredientFormState(
id: freezed == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int?,nutrientKey: null == nutrientKey ? _self.nutrientKey : nutrientKey // ignore: cast_nullable_to_non_nullable
as String,nutrientName: null == nutrientName ? _self.nutrientName : nutrientName // ignore: cast_nullable_to_non_nullable
as String,variantKey: null == variantKey ? _self.variantKey : variantKey // ignore: cast_nullable_to_non_nullable
as String,variantName: null == variantName ? _self.variantName : variantName // ignore: cast_nullable_to_non_nullable
as String,compoundAmount: freezed == compoundAmount ? _self.compoundAmount : compoundAmount // ignore: cast_nullable_to_non_nullable
as double?,compoundUnit: null == compoundUnit ? _self.compoundUnit : compoundUnit // ignore: cast_nullable_to_non_nullable
as String,elementalAmount: freezed == elementalAmount ? _self.elementalAmount : elementalAmount // ignore: cast_nullable_to_non_nullable
as double?,elementalUnit: null == elementalUnit ? _self.elementalUnit : elementalUnit // ignore: cast_nullable_to_non_nullable
as String,amountAccuracyStatus: null == amountAccuracyStatus ? _self.amountAccuracyStatus : amountAccuracyStatus // ignore: cast_nullable_to_non_nullable
as AmountAccuracyStatus,note: null == note ? _self.note : note // ignore: cast_nullable_to_non_nullable
as String,sourceText: null == sourceText ? _self.sourceText : sourceText // ignore: cast_nullable_to_non_nullable
as String,confidence: null == confidence ? _self.confidence : confidence // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

/// @nodoc
mixin _$ProductFormState {

 int? get productId; String get name; String get brand; double? get price; String get currency; String get totalQuantity; String get servingSize; String get servingType; String get note; List<ProductIngredientFormState> get ingredients; int get activeStep; bool get isEditing;
/// Create a copy of ProductFormState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProductFormStateCopyWith<ProductFormState> get copyWith => _$ProductFormStateCopyWithImpl<ProductFormState>(this as ProductFormState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProductFormState&&(identical(other.productId, productId) || other.productId == productId)&&(identical(other.name, name) || other.name == name)&&(identical(other.brand, brand) || other.brand == brand)&&(identical(other.price, price) || other.price == price)&&(identical(other.currency, currency) || other.currency == currency)&&(identical(other.totalQuantity, totalQuantity) || other.totalQuantity == totalQuantity)&&(identical(other.servingSize, servingSize) || other.servingSize == servingSize)&&(identical(other.servingType, servingType) || other.servingType == servingType)&&(identical(other.note, note) || other.note == note)&&const DeepCollectionEquality().equals(other.ingredients, ingredients)&&(identical(other.activeStep, activeStep) || other.activeStep == activeStep)&&(identical(other.isEditing, isEditing) || other.isEditing == isEditing));
}


@override
int get hashCode => Object.hash(runtimeType,productId,name,brand,price,currency,totalQuantity,servingSize,servingType,note,const DeepCollectionEquality().hash(ingredients),activeStep,isEditing);

@override
String toString() {
  return 'ProductFormState(productId: $productId, name: $name, brand: $brand, price: $price, currency: $currency, totalQuantity: $totalQuantity, servingSize: $servingSize, servingType: $servingType, note: $note, ingredients: $ingredients, activeStep: $activeStep, isEditing: $isEditing)';
}


}

/// @nodoc
abstract mixin class $ProductFormStateCopyWith<$Res>  {
  factory $ProductFormStateCopyWith(ProductFormState value, $Res Function(ProductFormState) _then) = _$ProductFormStateCopyWithImpl;
@useResult
$Res call({
 int? productId, String name, String brand, double? price, String currency, String totalQuantity, String servingSize, String servingType, String note, List<ProductIngredientFormState> ingredients, int activeStep, bool isEditing
});




}
/// @nodoc
class _$ProductFormStateCopyWithImpl<$Res>
    implements $ProductFormStateCopyWith<$Res> {
  _$ProductFormStateCopyWithImpl(this._self, this._then);

  final ProductFormState _self;
  final $Res Function(ProductFormState) _then;

/// Create a copy of ProductFormState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? productId = freezed,Object? name = null,Object? brand = null,Object? price = freezed,Object? currency = null,Object? totalQuantity = null,Object? servingSize = null,Object? servingType = null,Object? note = null,Object? ingredients = null,Object? activeStep = null,Object? isEditing = null,}) {
  return _then(_self.copyWith(
productId: freezed == productId ? _self.productId : productId // ignore: cast_nullable_to_non_nullable
as int?,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,brand: null == brand ? _self.brand : brand // ignore: cast_nullable_to_non_nullable
as String,price: freezed == price ? _self.price : price // ignore: cast_nullable_to_non_nullable
as double?,currency: null == currency ? _self.currency : currency // ignore: cast_nullable_to_non_nullable
as String,totalQuantity: null == totalQuantity ? _self.totalQuantity : totalQuantity // ignore: cast_nullable_to_non_nullable
as String,servingSize: null == servingSize ? _self.servingSize : servingSize // ignore: cast_nullable_to_non_nullable
as String,servingType: null == servingType ? _self.servingType : servingType // ignore: cast_nullable_to_non_nullable
as String,note: null == note ? _self.note : note // ignore: cast_nullable_to_non_nullable
as String,ingredients: null == ingredients ? _self.ingredients : ingredients // ignore: cast_nullable_to_non_nullable
as List<ProductIngredientFormState>,activeStep: null == activeStep ? _self.activeStep : activeStep // ignore: cast_nullable_to_non_nullable
as int,isEditing: null == isEditing ? _self.isEditing : isEditing // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [ProductFormState].
extension ProductFormStatePatterns on ProductFormState {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ProductFormState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ProductFormState() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ProductFormState value)  $default,){
final _that = this;
switch (_that) {
case _ProductFormState():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ProductFormState value)?  $default,){
final _that = this;
switch (_that) {
case _ProductFormState() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int? productId,  String name,  String brand,  double? price,  String currency,  String totalQuantity,  String servingSize,  String servingType,  String note,  List<ProductIngredientFormState> ingredients,  int activeStep,  bool isEditing)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ProductFormState() when $default != null:
return $default(_that.productId,_that.name,_that.brand,_that.price,_that.currency,_that.totalQuantity,_that.servingSize,_that.servingType,_that.note,_that.ingredients,_that.activeStep,_that.isEditing);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int? productId,  String name,  String brand,  double? price,  String currency,  String totalQuantity,  String servingSize,  String servingType,  String note,  List<ProductIngredientFormState> ingredients,  int activeStep,  bool isEditing)  $default,) {final _that = this;
switch (_that) {
case _ProductFormState():
return $default(_that.productId,_that.name,_that.brand,_that.price,_that.currency,_that.totalQuantity,_that.servingSize,_that.servingType,_that.note,_that.ingredients,_that.activeStep,_that.isEditing);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int? productId,  String name,  String brand,  double? price,  String currency,  String totalQuantity,  String servingSize,  String servingType,  String note,  List<ProductIngredientFormState> ingredients,  int activeStep,  bool isEditing)?  $default,) {final _that = this;
switch (_that) {
case _ProductFormState() when $default != null:
return $default(_that.productId,_that.name,_that.brand,_that.price,_that.currency,_that.totalQuantity,_that.servingSize,_that.servingType,_that.note,_that.ingredients,_that.activeStep,_that.isEditing);case _:
  return null;

}
}

}

/// @nodoc


class _ProductFormState implements ProductFormState {
  const _ProductFormState({this.productId, this.name = '', this.brand = '', this.price, this.currency = 'VND', this.totalQuantity = '0', this.servingSize = '0', this.servingType = 'capsule', this.note = '', final  List<ProductIngredientFormState> ingredients = const <ProductIngredientFormState>[], this.activeStep = 0, this.isEditing = false}): _ingredients = ingredients;
  

@override final  int? productId;
@override@JsonKey() final  String name;
@override@JsonKey() final  String brand;
@override final  double? price;
@override@JsonKey() final  String currency;
@override@JsonKey() final  String totalQuantity;
@override@JsonKey() final  String servingSize;
@override@JsonKey() final  String servingType;
@override@JsonKey() final  String note;
 final  List<ProductIngredientFormState> _ingredients;
@override@JsonKey() List<ProductIngredientFormState> get ingredients {
  if (_ingredients is EqualUnmodifiableListView) return _ingredients;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_ingredients);
}

@override@JsonKey() final  int activeStep;
@override@JsonKey() final  bool isEditing;

/// Create a copy of ProductFormState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ProductFormStateCopyWith<_ProductFormState> get copyWith => __$ProductFormStateCopyWithImpl<_ProductFormState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ProductFormState&&(identical(other.productId, productId) || other.productId == productId)&&(identical(other.name, name) || other.name == name)&&(identical(other.brand, brand) || other.brand == brand)&&(identical(other.price, price) || other.price == price)&&(identical(other.currency, currency) || other.currency == currency)&&(identical(other.totalQuantity, totalQuantity) || other.totalQuantity == totalQuantity)&&(identical(other.servingSize, servingSize) || other.servingSize == servingSize)&&(identical(other.servingType, servingType) || other.servingType == servingType)&&(identical(other.note, note) || other.note == note)&&const DeepCollectionEquality().equals(other._ingredients, _ingredients)&&(identical(other.activeStep, activeStep) || other.activeStep == activeStep)&&(identical(other.isEditing, isEditing) || other.isEditing == isEditing));
}


@override
int get hashCode => Object.hash(runtimeType,productId,name,brand,price,currency,totalQuantity,servingSize,servingType,note,const DeepCollectionEquality().hash(_ingredients),activeStep,isEditing);

@override
String toString() {
  return 'ProductFormState(productId: $productId, name: $name, brand: $brand, price: $price, currency: $currency, totalQuantity: $totalQuantity, servingSize: $servingSize, servingType: $servingType, note: $note, ingredients: $ingredients, activeStep: $activeStep, isEditing: $isEditing)';
}


}

/// @nodoc
abstract mixin class _$ProductFormStateCopyWith<$Res> implements $ProductFormStateCopyWith<$Res> {
  factory _$ProductFormStateCopyWith(_ProductFormState value, $Res Function(_ProductFormState) _then) = __$ProductFormStateCopyWithImpl;
@override @useResult
$Res call({
 int? productId, String name, String brand, double? price, String currency, String totalQuantity, String servingSize, String servingType, String note, List<ProductIngredientFormState> ingredients, int activeStep, bool isEditing
});




}
/// @nodoc
class __$ProductFormStateCopyWithImpl<$Res>
    implements _$ProductFormStateCopyWith<$Res> {
  __$ProductFormStateCopyWithImpl(this._self, this._then);

  final _ProductFormState _self;
  final $Res Function(_ProductFormState) _then;

/// Create a copy of ProductFormState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? productId = freezed,Object? name = null,Object? brand = null,Object? price = freezed,Object? currency = null,Object? totalQuantity = null,Object? servingSize = null,Object? servingType = null,Object? note = null,Object? ingredients = null,Object? activeStep = null,Object? isEditing = null,}) {
  return _then(_ProductFormState(
productId: freezed == productId ? _self.productId : productId // ignore: cast_nullable_to_non_nullable
as int?,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,brand: null == brand ? _self.brand : brand // ignore: cast_nullable_to_non_nullable
as String,price: freezed == price ? _self.price : price // ignore: cast_nullable_to_non_nullable
as double?,currency: null == currency ? _self.currency : currency // ignore: cast_nullable_to_non_nullable
as String,totalQuantity: null == totalQuantity ? _self.totalQuantity : totalQuantity // ignore: cast_nullable_to_non_nullable
as String,servingSize: null == servingSize ? _self.servingSize : servingSize // ignore: cast_nullable_to_non_nullable
as String,servingType: null == servingType ? _self.servingType : servingType // ignore: cast_nullable_to_non_nullable
as String,note: null == note ? _self.note : note // ignore: cast_nullable_to_non_nullable
as String,ingredients: null == ingredients ? _self._ingredients : ingredients // ignore: cast_nullable_to_non_nullable
as List<ProductIngredientFormState>,activeStep: null == activeStep ? _self.activeStep : activeStep // ignore: cast_nullable_to_non_nullable
as int,isEditing: null == isEditing ? _self.isEditing : isEditing // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
