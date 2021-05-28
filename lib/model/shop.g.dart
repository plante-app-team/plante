// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'shop.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$Shop extends Shop {
  @override
  final OsmShop osmShop;
  @override
  final BackendProductsAtShop? backendShop;

  factory _$Shop([void Function(ShopBuilder)? updates]) =>
      (new ShopBuilder()..update(updates)).build();

  _$Shop._({required this.osmShop, this.backendShop}) : super._() {
    BuiltValueNullFieldError.checkNotNull(osmShop, 'Shop', 'osmShop');
  }

  @override
  Shop rebuild(void Function(ShopBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  ShopBuilder toBuilder() => new ShopBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is Shop &&
        osmShop == other.osmShop &&
        backendShop == other.backendShop;
  }

  @override
  int get hashCode {
    return $jf($jc($jc(0, osmShop.hashCode), backendShop.hashCode));
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper('Shop')
          ..add('osmShop', osmShop)
          ..add('backendShop', backendShop))
        .toString();
  }
}

class ShopBuilder implements Builder<Shop, ShopBuilder> {
  _$Shop? _$v;

  OsmShopBuilder? _osmShop;
  OsmShopBuilder get osmShop => _$this._osmShop ??= new OsmShopBuilder();
  set osmShop(OsmShopBuilder? osmShop) => _$this._osmShop = osmShop;

  BackendProductsAtShopBuilder? _backendShop;
  BackendProductsAtShopBuilder get backendShop =>
      _$this._backendShop ??= new BackendProductsAtShopBuilder();
  set backendShop(BackendProductsAtShopBuilder? backendShop) =>
      _$this._backendShop = backendShop;

  ShopBuilder();

  ShopBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _osmShop = $v.osmShop.toBuilder();
      _backendShop = $v.backendShop?.toBuilder();
      _$v = null;
    }
    return this;
  }

  @override
  void replace(Shop other) {
    ArgumentError.checkNotNull(other, 'other');
    _$v = other as _$Shop;
  }

  @override
  void update(void Function(ShopBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  _$Shop build() {
    _$Shop _$result;
    try {
      _$result = _$v ??
          new _$Shop._(
              osmShop: osmShop.build(), backendShop: _backendShop?.build());
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'osmShop';
        osmShop.build();
        _$failedField = 'backendShop';
        _backendShop?.build();
      } catch (e) {
        throw new BuiltValueNestedFieldError(
            'Shop', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: always_put_control_body_on_new_line,always_specify_types,annotate_overrides,avoid_annotating_with_dynamic,avoid_as,avoid_catches_without_on_clauses,avoid_returning_this,lines_longer_than_80_chars,omit_local_variable_types,prefer_expression_function_bodies,sort_constructors_first,test_types_in_equals,unnecessary_const,unnecessary_new
