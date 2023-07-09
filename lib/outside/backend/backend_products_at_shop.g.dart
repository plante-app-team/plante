// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'backend_products_at_shop.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

Serializer<BackendProductsAtShop> _$backendProductsAtShopSerializer =
    new _$BackendProductsAtShopSerializer();

class _$BackendProductsAtShopSerializer
    implements StructuredSerializer<BackendProductsAtShop> {
  @override
  final Iterable<Type> types = const [
    BackendProductsAtShop,
    _$BackendProductsAtShop
  ];
  @override
  final String wireName = 'BackendProductsAtShop';

  @override
  Iterable<Object?> serialize(
      Serializers serializers, BackendProductsAtShop object,
      {FullType specifiedType = FullType.unspecified}) {
    final result = <Object?>[
      'shop_osm_uid',
      serializers.serialize(object.osmUID,
          specifiedType: const FullType(OsmUID)),
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
  BackendProductsAtShop deserialize(
      Serializers serializers, Iterable<Object?> serialized,
      {FullType specifiedType = FullType.unspecified}) {
    final result = new BackendProductsAtShopBuilder();

    final iterator = serialized.iterator;
    while (iterator.moveNext()) {
      final key = iterator.current! as String;
      iterator.moveNext();
      final Object? value = iterator.current;
      switch (key) {
        case 'shop_osm_uid':
          result.osmUID = serializers.deserialize(value,
              specifiedType: const FullType(OsmUID))! as OsmUID;
          break;
        case 'products':
          result.products.replace(serializers.deserialize(value,
                  specifiedType: const FullType(
                      BuiltList, const [const FullType(BackendProduct)]))!
              as BuiltList<Object?>);
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

class _$BackendProductsAtShop extends BackendProductsAtShop {
  @override
  final OsmUID osmUID;
  @override
  final BuiltList<BackendProduct> products;
  @override
  final BuiltMap<String, int> productsLastSeenUtc;

  factory _$BackendProductsAtShop(
          [void Function(BackendProductsAtShopBuilder)? updates]) =>
      (new BackendProductsAtShopBuilder()..update(updates))._build();

  _$BackendProductsAtShop._(
      {required this.osmUID,
      required this.products,
      required this.productsLastSeenUtc})
      : super._() {
    BuiltValueNullFieldError.checkNotNull(
        osmUID, r'BackendProductsAtShop', 'osmUID');
    BuiltValueNullFieldError.checkNotNull(
        products, r'BackendProductsAtShop', 'products');
    BuiltValueNullFieldError.checkNotNull(
        productsLastSeenUtc, r'BackendProductsAtShop', 'productsLastSeenUtc');
  }

  @override
  BackendProductsAtShop rebuild(
          void Function(BackendProductsAtShopBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  BackendProductsAtShopBuilder toBuilder() =>
      new BackendProductsAtShopBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is BackendProductsAtShop &&
        osmUID == other.osmUID &&
        products == other.products &&
        productsLastSeenUtc == other.productsLastSeenUtc;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, osmUID.hashCode);
    _$hash = $jc(_$hash, products.hashCode);
    _$hash = $jc(_$hash, productsLastSeenUtc.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'BackendProductsAtShop')
          ..add('osmUID', osmUID)
          ..add('products', products)
          ..add('productsLastSeenUtc', productsLastSeenUtc))
        .toString();
  }
}

class BackendProductsAtShopBuilder
    implements Builder<BackendProductsAtShop, BackendProductsAtShopBuilder> {
  _$BackendProductsAtShop? _$v;

  OsmUID? _osmUID;
  OsmUID? get osmUID => _$this._osmUID;
  set osmUID(OsmUID? osmUID) => _$this._osmUID = osmUID;

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

  BackendProductsAtShopBuilder();

  BackendProductsAtShopBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _osmUID = $v.osmUID;
      _products = $v.products.toBuilder();
      _productsLastSeenUtc = $v.productsLastSeenUtc.toBuilder();
      _$v = null;
    }
    return this;
  }

  @override
  void replace(BackendProductsAtShop other) {
    ArgumentError.checkNotNull(other, 'other');
    _$v = other as _$BackendProductsAtShop;
  }

  @override
  void update(void Function(BackendProductsAtShopBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  BackendProductsAtShop build() => _build();

  _$BackendProductsAtShop _build() {
    _$BackendProductsAtShop _$result;
    try {
      _$result = _$v ??
          new _$BackendProductsAtShop._(
              osmUID: BuiltValueNullFieldError.checkNotNull(
                  osmUID, r'BackendProductsAtShop', 'osmUID'),
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
            r'BackendProductsAtShop', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
