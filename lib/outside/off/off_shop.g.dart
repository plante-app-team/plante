// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'off_shop.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

Serializer<OffShop> _$offShopSerializer = new _$OffShopSerializer();

class _$OffShopSerializer implements StructuredSerializer<OffShop> {
  @override
  final Iterable<Type> types = const [OffShop, _$OffShop];
  @override
  final String wireName = 'OffShop';

  @override
  Iterable<Object?> serialize(Serializers serializers, OffShop object,
      {FullType specifiedType = FullType.unspecified}) {
    final result = <Object?>[
      'id',
      serializers.serialize(object.id, specifiedType: const FullType(String)),
      'products',
      serializers.serialize(object.productsCount,
          specifiedType: const FullType(int)),
    ];
    Object? value;
    value = object.name;
    if (value != null) {
      result
        ..add('name')
        ..add(serializers.serialize(value,
            specifiedType: const FullType(String)));
    }
    return result;
  }

  @override
  OffShop deserialize(Serializers serializers, Iterable<Object?> serialized,
      {FullType specifiedType = FullType.unspecified}) {
    final result = new OffShopBuilder();

    final iterator = serialized.iterator;
    while (iterator.moveNext()) {
      final key = iterator.current as String;
      iterator.moveNext();
      final Object? value = iterator.current;
      switch (key) {
        case 'id':
          result.id = serializers.deserialize(value,
              specifiedType: const FullType(String)) as String;
          break;
        case 'name':
          result.name = serializers.deserialize(value,
              specifiedType: const FullType(String)) as String?;
          break;
        case 'products':
          result.productsCount = serializers.deserialize(value,
              specifiedType: const FullType(int)) as int;
          break;
      }
    }

    return result.build();
  }
}

class _$OffShop extends OffShop {
  @override
  final String id;
  @override
  final String? name;
  @override
  final int productsCount;

  factory _$OffShop([void Function(OffShopBuilder)? updates]) =>
      (new OffShopBuilder()..update(updates)).build();

  _$OffShop._({required this.id, this.name, required this.productsCount})
      : super._() {
    BuiltValueNullFieldError.checkNotNull(id, 'OffShop', 'id');
    BuiltValueNullFieldError.checkNotNull(
        productsCount, 'OffShop', 'productsCount');
  }

  @override
  OffShop rebuild(void Function(OffShopBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  OffShopBuilder toBuilder() => new OffShopBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is OffShop &&
        id == other.id &&
        name == other.name &&
        productsCount == other.productsCount;
  }

  @override
  int get hashCode {
    return $jf(
        $jc($jc($jc(0, id.hashCode), name.hashCode), productsCount.hashCode));
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper('OffShop')
          ..add('id', id)
          ..add('name', name)
          ..add('productsCount', productsCount))
        .toString();
  }
}

class OffShopBuilder implements Builder<OffShop, OffShopBuilder> {
  _$OffShop? _$v;

  String? _id;
  String? get id => _$this._id;
  set id(String? id) => _$this._id = id;

  String? _name;
  String? get name => _$this._name;
  set name(String? name) => _$this._name = name;

  int? _productsCount;
  int? get productsCount => _$this._productsCount;
  set productsCount(int? productsCount) =>
      _$this._productsCount = productsCount;

  OffShopBuilder() {
    OffShop._setDefaults(this);
  }

  OffShopBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _id = $v.id;
      _name = $v.name;
      _productsCount = $v.productsCount;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(OffShop other) {
    ArgumentError.checkNotNull(other, 'other');
    _$v = other as _$OffShop;
  }

  @override
  void update(void Function(OffShopBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  _$OffShop build() {
    final _$result = _$v ??
        new _$OffShop._(
            id: BuiltValueNullFieldError.checkNotNull(id, 'OffShop', 'id'),
            name: name,
            productsCount: BuiltValueNullFieldError.checkNotNull(
                productsCount, 'OffShop', 'productsCount'));
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: always_put_control_body_on_new_line,always_specify_types,annotate_overrides,avoid_annotating_with_dynamic,avoid_as,avoid_catches_without_on_clauses,avoid_returning_this,deprecated_member_use_from_same_package,lines_longer_than_80_chars,omit_local_variable_types,prefer_expression_function_bodies,sort_constructors_first,test_types_in_equals,unnecessary_const,unnecessary_new
