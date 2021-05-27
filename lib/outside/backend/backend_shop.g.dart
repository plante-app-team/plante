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
      'shop_osm_id',
      serializers.serialize(object.osmId,
          specifiedType: const FullType(String)),
      'products',
      serializers.serialize(object.products,
          specifiedType: const FullType(
              BuiltList, const [const FullType(BackendProduct)])),
      'products_last_seen_utc',
      serializers.serialize(object.productsLastSeenUtc,
          specifiedType: const FullType(
              BuiltMap, const [const FullType(String), const FullType(int)])),
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
        case 'shop_osm_id':
          result.osmId = serializers.deserialize(value,
              specifiedType: const FullType(String)) as String;
          break;
        case 'products':
          result.products.replace(serializers.deserialize(value,
                  specifiedType: const FullType(
                      BuiltList, const [const FullType(BackendProduct)]))!
              as BuiltList<Object>);
          break;
        case 'products_last_seen_utc':
          result.productsLastSeenUtc.replace(serializers.deserialize(value,
              specifiedType: const FullType(BuiltMap,
                  const [const FullType(String), const FullType(int)]))!);
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
  final BuiltList<BackendProduct> products;
  @override
  final BuiltMap<String, int> productsLastSeenUtc;

  factory _$BackendShop([void Function(BackendShopBuilder)? updates]) =>
      (new BackendShopBuilder()..update(updates)).build();

  _$BackendShop._(
      {required this.osmId,
      required this.products,
      required this.productsLastSeenUtc})
      : super._() {
    BuiltValueNullFieldError.checkNotNull(osmId, 'BackendShop', 'osmId');
    BuiltValueNullFieldError.checkNotNull(products, 'BackendShop', 'products');
    BuiltValueNullFieldError.checkNotNull(
        productsLastSeenUtc, 'BackendShop', 'productsLastSeenUtc');
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
        products == other.products &&
        productsLastSeenUtc == other.productsLastSeenUtc;
  }

  @override
  int get hashCode {
    return $jf($jc($jc($jc(0, osmId.hashCode), products.hashCode),
        productsLastSeenUtc.hashCode));
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper('BackendShop')
          ..add('osmId', osmId)
          ..add('products', products)
          ..add('productsLastSeenUtc', productsLastSeenUtc))
        .toString();
  }
}

class BackendShopBuilder implements Builder<BackendShop, BackendShopBuilder> {
  _$BackendShop? _$v;

  String? _osmId;
  String? get osmId => _$this._osmId;
  set osmId(String? osmId) => _$this._osmId = osmId;

  ListBuilder<BackendProduct>? _products;
  ListBuilder<BackendProduct> get products =>
      _$this._products ??= new ListBuilder<BackendProduct>();
  set products(ListBuilder<BackendProduct>? products) =>
      _$this._products = products;

  MapBuilder<String, int>? _productsLastSeenUtc;
  MapBuilder<String, int> get productsLastSeenUtc =>
      _$this._productsLastSeenUtc ??= new MapBuilder<String, int>();
  set productsLastSeenUtc(MapBuilder<String, int>? productsLastSeenUtc) =>
      _$this._productsLastSeenUtc = productsLastSeenUtc;

  BackendShopBuilder();

  BackendShopBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _osmId = $v.osmId;
      _products = $v.products.toBuilder();
      _productsLastSeenUtc = $v.productsLastSeenUtc.toBuilder();
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
    _$BackendShop _$result;
    try {
      _$result = _$v ??
          new _$BackendShop._(
              osmId: BuiltValueNullFieldError.checkNotNull(
                  osmId, 'BackendShop', 'osmId'),
              products: products.build(),
              productsLastSeenUtc: productsLastSeenUtc.build());
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'products';
        products.build();
        _$failedField = 'productsLastSeenUtc';
        productsLastSeenUtc.build();
      } catch (e) {
        throw new BuiltValueNestedFieldError(
            'BackendShop', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: always_put_control_body_on_new_line,always_specify_types,annotate_overrides,avoid_annotating_with_dynamic,avoid_as,avoid_catches_without_on_clauses,avoid_returning_this,lines_longer_than_80_chars,omit_local_variable_types,prefer_expression_function_bodies,sort_constructors_first,test_types_in_equals,unnecessary_const,unnecessary_new
