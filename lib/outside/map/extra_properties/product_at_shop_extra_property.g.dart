// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'product_at_shop_extra_property.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$ProductAtShopExtraProperty extends ProductAtShopExtraProperty {
  @override
  final int? intVal;
  @override
  final String barcode;
  @override
  final int typeCode;
  @override
  final int whenSetSecsSinceEpoch;
  @override
  final OsmUID osmUID;

  factory _$ProductAtShopExtraProperty(
          [void Function(ProductAtShopExtraPropertyBuilder)? updates]) =>
      (new ProductAtShopExtraPropertyBuilder()..update(updates))._build();

  _$ProductAtShopExtraProperty._(
      {this.intVal,
      required this.barcode,
      required this.typeCode,
      required this.whenSetSecsSinceEpoch,
      required this.osmUID})
      : super._() {
    BuiltValueNullFieldError.checkNotNull(
        barcode, r'ProductAtShopExtraProperty', 'barcode');
    BuiltValueNullFieldError.checkNotNull(
        typeCode, r'ProductAtShopExtraProperty', 'typeCode');
    BuiltValueNullFieldError.checkNotNull(whenSetSecsSinceEpoch,
        r'ProductAtShopExtraProperty', 'whenSetSecsSinceEpoch');
    BuiltValueNullFieldError.checkNotNull(
        osmUID, r'ProductAtShopExtraProperty', 'osmUID');
  }

  @override
  ProductAtShopExtraProperty rebuild(
          void Function(ProductAtShopExtraPropertyBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  ProductAtShopExtraPropertyBuilder toBuilder() =>
      new ProductAtShopExtraPropertyBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is ProductAtShopExtraProperty &&
        intVal == other.intVal &&
        barcode == other.barcode &&
        typeCode == other.typeCode &&
        whenSetSecsSinceEpoch == other.whenSetSecsSinceEpoch &&
        osmUID == other.osmUID;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, intVal.hashCode);
    _$hash = $jc(_$hash, barcode.hashCode);
    _$hash = $jc(_$hash, typeCode.hashCode);
    _$hash = $jc(_$hash, whenSetSecsSinceEpoch.hashCode);
    _$hash = $jc(_$hash, osmUID.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'ProductAtShopExtraProperty')
          ..add('intVal', intVal)
          ..add('barcode', barcode)
          ..add('typeCode', typeCode)
          ..add('whenSetSecsSinceEpoch', whenSetSecsSinceEpoch)
          ..add('osmUID', osmUID))
        .toString();
  }
}

class ProductAtShopExtraPropertyBuilder
    implements
        Builder<ProductAtShopExtraProperty, ProductAtShopExtraPropertyBuilder> {
  _$ProductAtShopExtraProperty? _$v;

  int? _intVal;
  int? get intVal => _$this._intVal;
  set intVal(int? intVal) => _$this._intVal = intVal;

  String? _barcode;
  String? get barcode => _$this._barcode;
  set barcode(String? barcode) => _$this._barcode = barcode;

  int? _typeCode;
  int? get typeCode => _$this._typeCode;
  set typeCode(int? typeCode) => _$this._typeCode = typeCode;

  int? _whenSetSecsSinceEpoch;
  int? get whenSetSecsSinceEpoch => _$this._whenSetSecsSinceEpoch;
  set whenSetSecsSinceEpoch(int? whenSetSecsSinceEpoch) =>
      _$this._whenSetSecsSinceEpoch = whenSetSecsSinceEpoch;

  OsmUID? _osmUID;
  OsmUID? get osmUID => _$this._osmUID;
  set osmUID(OsmUID? osmUID) => _$this._osmUID = osmUID;

  ProductAtShopExtraPropertyBuilder();

  ProductAtShopExtraPropertyBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _intVal = $v.intVal;
      _barcode = $v.barcode;
      _typeCode = $v.typeCode;
      _whenSetSecsSinceEpoch = $v.whenSetSecsSinceEpoch;
      _osmUID = $v.osmUID;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(ProductAtShopExtraProperty other) {
    ArgumentError.checkNotNull(other, 'other');
    _$v = other as _$ProductAtShopExtraProperty;
  }

  @override
  void update(void Function(ProductAtShopExtraPropertyBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  ProductAtShopExtraProperty build() => _build();

  _$ProductAtShopExtraProperty _build() {
    final _$result = _$v ??
        new _$ProductAtShopExtraProperty._(
            intVal: intVal,
            barcode: BuiltValueNullFieldError.checkNotNull(
                barcode, r'ProductAtShopExtraProperty', 'barcode'),
            typeCode: BuiltValueNullFieldError.checkNotNull(
                typeCode, r'ProductAtShopExtraProperty', 'typeCode'),
            whenSetSecsSinceEpoch: BuiltValueNullFieldError.checkNotNull(
                whenSetSecsSinceEpoch,
                r'ProductAtShopExtraProperty',
                'whenSetSecsSinceEpoch'),
            osmUID: BuiltValueNullFieldError.checkNotNull(
                osmUID, r'ProductAtShopExtraProperty', 'osmUID'));
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
