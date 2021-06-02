// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'shop_product_range.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$ShopProductRange extends ShopProductRange {
  @override
  final Shop shop;
  @override
  final BuiltList<Product> products;
  @override
  final BuiltMap<String, int> productsLastSeenSecsUtc;

  factory _$ShopProductRange(
          [void Function(ShopProductRangeBuilder)? updates]) =>
      (new ShopProductRangeBuilder()..update(updates)).build();

  _$ShopProductRange._(
      {required this.shop,
      required this.products,
      required this.productsLastSeenSecsUtc})
      : super._() {
    BuiltValueNullFieldError.checkNotNull(shop, 'ShopProductRange', 'shop');
    BuiltValueNullFieldError.checkNotNull(
        products, 'ShopProductRange', 'products');
    BuiltValueNullFieldError.checkNotNull(
        productsLastSeenSecsUtc, 'ShopProductRange', 'productsLastSeenSecsUtc');
  }

  @override
  ShopProductRange rebuild(void Function(ShopProductRangeBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  ShopProductRangeBuilder toBuilder() =>
      new ShopProductRangeBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is ShopProductRange &&
        shop == other.shop &&
        products == other.products &&
        productsLastSeenSecsUtc == other.productsLastSeenSecsUtc;
  }

  @override
  int get hashCode {
    return $jf($jc($jc($jc(0, shop.hashCode), products.hashCode),
        productsLastSeenSecsUtc.hashCode));
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper('ShopProductRange')
          ..add('shop', shop)
          ..add('products', products)
          ..add('productsLastSeenSecsUtc', productsLastSeenSecsUtc))
        .toString();
  }
}

class ShopProductRangeBuilder
    implements Builder<ShopProductRange, ShopProductRangeBuilder> {
  _$ShopProductRange? _$v;

  ShopBuilder? _shop;
  ShopBuilder get shop => _$this._shop ??= new ShopBuilder();
  set shop(ShopBuilder? shop) => _$this._shop = shop;

  ListBuilder<Product>? _products;
  ListBuilder<Product> get products =>
      _$this._products ??= new ListBuilder<Product>();
  set products(ListBuilder<Product>? products) => _$this._products = products;

  MapBuilder<String, int>? _productsLastSeenSecsUtc;
  MapBuilder<String, int> get productsLastSeenSecsUtc =>
      _$this._productsLastSeenSecsUtc ??= new MapBuilder<String, int>();
  set productsLastSeenSecsUtc(
          MapBuilder<String, int>? productsLastSeenSecsUtc) =>
      _$this._productsLastSeenSecsUtc = productsLastSeenSecsUtc;

  ShopProductRangeBuilder();

  ShopProductRangeBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _shop = $v.shop.toBuilder();
      _products = $v.products.toBuilder();
      _productsLastSeenSecsUtc = $v.productsLastSeenSecsUtc.toBuilder();
      _$v = null;
    }
    return this;
  }

  @override
  void replace(ShopProductRange other) {
    ArgumentError.checkNotNull(other, 'other');
    _$v = other as _$ShopProductRange;
  }

  @override
  void update(void Function(ShopProductRangeBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  _$ShopProductRange build() {
    _$ShopProductRange _$result;
    try {
      _$result = _$v ??
          new _$ShopProductRange._(
              shop: shop.build(),
              products: products.build(),
              productsLastSeenSecsUtc: productsLastSeenSecsUtc.build());
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'shop';
        shop.build();
        _$failedField = 'products';
        products.build();
        _$failedField = 'productsLastSeenSecsUtc';
        productsLastSeenSecsUtc.build();
      } catch (e) {
        throw new BuiltValueNestedFieldError(
            'ShopProductRange', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: always_put_control_body_on_new_line,always_specify_types,annotate_overrides,avoid_annotating_with_dynamic,avoid_as,avoid_catches_without_on_clauses,avoid_returning_this,lines_longer_than_80_chars,omit_local_variable_types,prefer_expression_function_bodies,sort_constructors_first,test_types_in_equals,unnecessary_const,unnecessary_new
