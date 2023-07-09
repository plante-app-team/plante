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
      'country',
      serializers.serialize(object.country,
          specifiedType: const FullType(String)),
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
      final key = iterator.current! as String;
      iterator.moveNext();
      final Object? value = iterator.current;
      switch (key) {
        case 'id':
          result.id = serializers.deserialize(value,
              specifiedType: const FullType(String))! as String;
          break;
        case 'name':
          result.name = serializers.deserialize(value,
              specifiedType: const FullType(String)) as String?;
          break;
        case 'products':
          result.productsCount = serializers.deserialize(value,
              specifiedType: const FullType(int))! as int;
          break;
        case 'country':
          result.country = serializers.deserialize(value,
              specifiedType: const FullType(String))! as String;
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
  @override
  final String country;

  factory _$OffShop([void Function(OffShopBuilder)? updates]) =>
      (new OffShopBuilder()..update(updates))._build();

  _$OffShop._(
      {required this.id,
      this.name,
      required this.productsCount,
      required this.country})
      : super._() {
    BuiltValueNullFieldError.checkNotNull(id, r'OffShop', 'id');
    BuiltValueNullFieldError.checkNotNull(
        productsCount, r'OffShop', 'productsCount');
    BuiltValueNullFieldError.checkNotNull(country, r'OffShop', 'country');
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
        productsCount == other.productsCount &&
        country == other.country;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, id.hashCode);
    _$hash = $jc(_$hash, name.hashCode);
    _$hash = $jc(_$hash, productsCount.hashCode);
    _$hash = $jc(_$hash, country.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'OffShop')
          ..add('id', id)
          ..add('name', name)
          ..add('productsCount', productsCount)
          ..add('country', country))
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

  String? _country;
  String? get country => _$this._country;
  set country(String? country) => _$this._country = country;

  OffShopBuilder() {
    OffShop._setDefaults(this);
  }

  OffShopBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _id = $v.id;
      _name = $v.name;
      _productsCount = $v.productsCount;
      _country = $v.country;
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
  OffShop build() => _build();

  _$OffShop _build() {
    final _$result = _$v ??
        new _$OffShop._(
            id: BuiltValueNullFieldError.checkNotNull(id, r'OffShop', 'id'),
            name: name,
            productsCount: BuiltValueNullFieldError.checkNotNull(
                productsCount, r'OffShop', 'productsCount'),
            country: BuiltValueNullFieldError.checkNotNull(
                country, r'OffShop', 'country'));
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
