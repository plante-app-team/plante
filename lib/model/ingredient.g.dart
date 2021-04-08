// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ingredient.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

Serializer<Ingredient> _$ingredientSerializer = new _$IngredientSerializer();

class _$IngredientSerializer implements StructuredSerializer<Ingredient> {
  @override
  final Iterable<Type> types = const [Ingredient, _$Ingredient];
  @override
  final String wireName = 'Ingredient';

  @override
  Iterable<Object?> serialize(Serializers serializers, Ingredient object,
      {FullType specifiedType = FullType.unspecified}) {
    final result = <Object?>[
      'name',
      serializers.serialize(object.name, specifiedType: const FullType(String)),
    ];
    Object? value;
    value = object.vegetarianStatus;
    if (value != null) {
      result
        ..add('vegetarianStatus')
        ..add(serializers.serialize(value,
            specifiedType: const FullType(VegStatus)));
    }
    value = object.veganStatus;
    if (value != null) {
      result
        ..add('veganStatus')
        ..add(serializers.serialize(value,
            specifiedType: const FullType(VegStatus)));
    }
    return result;
  }

  @override
  Ingredient deserialize(Serializers serializers, Iterable<Object?> serialized,
      {FullType specifiedType = FullType.unspecified}) {
    final result = new IngredientBuilder();

    final iterator = serialized.iterator;
    while (iterator.moveNext()) {
      final key = iterator.current as String;
      iterator.moveNext();
      final Object? value = iterator.current;
      switch (key) {
        case 'name':
          result.name = serializers.deserialize(value,
              specifiedType: const FullType(String)) as String;
          break;
        case 'vegetarianStatus':
          result.vegetarianStatus = serializers.deserialize(value,
              specifiedType: const FullType(VegStatus)) as VegStatus;
          break;
        case 'veganStatus':
          result.veganStatus = serializers.deserialize(value,
              specifiedType: const FullType(VegStatus)) as VegStatus;
          break;
      }
    }

    return result.build();
  }
}

class _$Ingredient extends Ingredient {
  @override
  final String name;
  @override
  final VegStatus? vegetarianStatus;
  @override
  final VegStatus? veganStatus;

  factory _$Ingredient([void Function(IngredientBuilder)? updates]) =>
      (new IngredientBuilder()..update(updates)).build();

  _$Ingredient._({required this.name, this.vegetarianStatus, this.veganStatus})
      : super._() {
    BuiltValueNullFieldError.checkNotNull(name, 'Ingredient', 'name');
  }

  @override
  Ingredient rebuild(void Function(IngredientBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  IngredientBuilder toBuilder() => new IngredientBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is Ingredient &&
        name == other.name &&
        vegetarianStatus == other.vegetarianStatus &&
        veganStatus == other.veganStatus;
  }

  @override
  int get hashCode {
    return $jf($jc($jc($jc(0, name.hashCode), vegetarianStatus.hashCode),
        veganStatus.hashCode));
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper('Ingredient')
          ..add('name', name)
          ..add('vegetarianStatus', vegetarianStatus)
          ..add('veganStatus', veganStatus))
        .toString();
  }
}

class IngredientBuilder implements Builder<Ingredient, IngredientBuilder> {
  _$Ingredient? _$v;

  String? _name;
  String? get name => _$this._name;
  set name(String? name) => _$this._name = name;

  VegStatus? _vegetarianStatus;
  VegStatus? get vegetarianStatus => _$this._vegetarianStatus;
  set vegetarianStatus(VegStatus? vegetarianStatus) =>
      _$this._vegetarianStatus = vegetarianStatus;

  VegStatus? _veganStatus;
  VegStatus? get veganStatus => _$this._veganStatus;
  set veganStatus(VegStatus? veganStatus) => _$this._veganStatus = veganStatus;

  IngredientBuilder();

  IngredientBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _name = $v.name;
      _vegetarianStatus = $v.vegetarianStatus;
      _veganStatus = $v.veganStatus;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(Ingredient other) {
    ArgumentError.checkNotNull(other, 'other');
    _$v = other as _$Ingredient;
  }

  @override
  void update(void Function(IngredientBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  _$Ingredient build() {
    final _$result = _$v ??
        new _$Ingredient._(
            name: BuiltValueNullFieldError.checkNotNull(
                name, 'Ingredient', 'name'),
            vegetarianStatus: vegetarianStatus,
            veganStatus: veganStatus);
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: always_put_control_body_on_new_line,always_specify_types,annotate_overrides,avoid_annotating_with_dynamic,avoid_as,avoid_catches_without_on_clauses,avoid_returning_this,lines_longer_than_80_chars,omit_local_variable_types,prefer_expression_function_bodies,sort_constructors_first,test_types_in_equals,unnecessary_const,unnecessary_new
