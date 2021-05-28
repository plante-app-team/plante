// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'backend_shop.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

Serializer<BackendShop> _$backendShopSerializer = new _$BackendShopSerializer();

class _$BackendShopSerializer implements StructuredSerializer<BackendShop> {
  @override
  final Iterable<Type> types = const [BackendShop, _$BackendShop];
  @override
  final String wireName = 'BackendShop';

  @override
  Iterable<Object?> serialize(Serializers serializers, BackendShop object,
      {FullType specifiedType = FullType.unspecified}) {
    final result = <Object?>[
      'osm_id',
      serializers.serialize(object.osmId,
          specifiedType: const FullType(String)),
      'products_count',
      serializers.serialize(object.productsCount,
          specifiedType: const FullType(int)),
    ];

    return result;
  }

  @override
  BackendShop deserialize(Serializers serializers, Iterable<Object?> serialized,
      {FullType specifiedType = FullType.unspecified}) {
    final result = new BackendShopBuilder();

    final iterator = serialized.iterator;
    while (iterator.moveNext()) {
      final key = iterator.current as String;
      iterator.moveNext();
      final Object? value = iterator.current;
      switch (key) {
        case 'osm_id':
          result.osmId = serializers.deserialize(value,
              specifiedType: const FullType(String)) as String;
          break;
        case 'products_count':
          result.productsCount = serializers.deserialize(value,
              specifiedType: const FullType(int)) as int;
          break;
      }
    }

    return result.build();
  }
}

class _$BackendShop extends BackendShop {
  @override
  final String osmId;
  @override
  final int productsCount;

  factory _$BackendShop([void Function(BackendShopBuilder)? updates]) =>
      (new BackendShopBuilder()..update(updates)).build();

  _$BackendShop._({required this.osmId, required this.productsCount})
      : super._() {
    BuiltValueNullFieldError.checkNotNull(osmId, 'BackendShop', 'osmId');
    BuiltValueNullFieldError.checkNotNull(
        productsCount, 'BackendShop', 'productsCount');
  }

  @override
  BackendShop rebuild(void Function(BackendShopBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  BackendShopBuilder toBuilder() => new BackendShopBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is BackendShop &&
        osmId == other.osmId &&
        productsCount == other.productsCount;
  }

  @override
  int get hashCode {
    return $jf($jc($jc(0, osmId.hashCode), productsCount.hashCode));
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper('BackendShop')
          ..add('osmId', osmId)
          ..add('productsCount', productsCount))
        .toString();
  }
}

class BackendShopBuilder implements Builder<BackendShop, BackendShopBuilder> {
  _$BackendShop? _$v;

  String? _osmId;
  String? get osmId => _$this._osmId;
  set osmId(String? osmId) => _$this._osmId = osmId;

  int? _productsCount;
  int? get productsCount => _$this._productsCount;
  set productsCount(int? productsCount) =>
      _$this._productsCount = productsCount;

  BackendShopBuilder();

  BackendShopBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _osmId = $v.osmId;
      _productsCount = $v.productsCount;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(BackendShop other) {
    ArgumentError.checkNotNull(other, 'other');
    _$v = other as _$BackendShop;
  }

  @override
  void update(void Function(BackendShopBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  _$BackendShop build() {
    final _$result = _$v ??
        new _$BackendShop._(
            osmId: BuiltValueNullFieldError.checkNotNull(
                osmId, 'BackendShop', 'osmId'),
            productsCount: BuiltValueNullFieldError.checkNotNull(
                productsCount, 'BackendShop', 'productsCount'));
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: always_put_control_body_on_new_line,always_specify_types,annotate_overrides,avoid_annotating_with_dynamic,avoid_as,avoid_catches_without_on_clauses,avoid_returning_this,lines_longer_than_80_chars,omit_local_variable_types,prefer_expression_function_bodies,sort_constructors_first,test_types_in_equals,unnecessary_const,unnecessary_new
