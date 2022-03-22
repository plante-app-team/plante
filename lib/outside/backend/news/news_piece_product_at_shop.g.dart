// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'news_piece_product_at_shop.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

Serializer<NewsPieceProductAtShop> _$newsPieceProductAtShopSerializer =
    new _$NewsPieceProductAtShopSerializer();

class _$NewsPieceProductAtShopSerializer
    implements StructuredSerializer<NewsPieceProductAtShop> {
  @override
  final Iterable<Type> types = const [
    NewsPieceProductAtShop,
    _$NewsPieceProductAtShop
  ];
  @override
  final String wireName = 'NewsPieceProductAtShop';

  @override
  Iterable<Object?> serialize(
      Serializers serializers, NewsPieceProductAtShop object,
      {FullType specifiedType = FullType.unspecified}) {
    final result = <Object?>[
      'barcode',
      serializers.serialize(object.barcode,
          specifiedType: const FullType(String)),
      'shop_uid',
      serializers.serialize(object.shopUID,
          specifiedType: const FullType(OsmUID)),
    ];

    return result;
  }

  @override
  NewsPieceProductAtShop deserialize(
      Serializers serializers, Iterable<Object?> serialized,
      {FullType specifiedType = FullType.unspecified}) {
    final result = new NewsPieceProductAtShopBuilder();

    final iterator = serialized.iterator;
    while (iterator.moveNext()) {
      final key = iterator.current as String;
      iterator.moveNext();
      final Object? value = iterator.current;
      switch (key) {
        case 'barcode':
          result.barcode = serializers.deserialize(value,
              specifiedType: const FullType(String)) as String;
          break;
        case 'shop_uid':
          result.shopUID = serializers.deserialize(value,
              specifiedType: const FullType(OsmUID)) as OsmUID;
          break;
      }
    }

    return result.build();
  }
}

class _$NewsPieceProductAtShop extends NewsPieceProductAtShop {
  @override
  final String barcode;
  @override
  final OsmUID shopUID;

  factory _$NewsPieceProductAtShop(
          [void Function(NewsPieceProductAtShopBuilder)? updates]) =>
      (new NewsPieceProductAtShopBuilder()..update(updates)).build();

  _$NewsPieceProductAtShop._({required this.barcode, required this.shopUID})
      : super._() {
    BuiltValueNullFieldError.checkNotNull(
        barcode, 'NewsPieceProductAtShop', 'barcode');
    BuiltValueNullFieldError.checkNotNull(
        shopUID, 'NewsPieceProductAtShop', 'shopUID');
  }

  @override
  NewsPieceProductAtShop rebuild(
          void Function(NewsPieceProductAtShopBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  NewsPieceProductAtShopBuilder toBuilder() =>
      new NewsPieceProductAtShopBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is NewsPieceProductAtShop &&
        barcode == other.barcode &&
        shopUID == other.shopUID;
  }

  @override
  int get hashCode {
    return $jf($jc($jc(0, barcode.hashCode), shopUID.hashCode));
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper('NewsPieceProductAtShop')
          ..add('barcode', barcode)
          ..add('shopUID', shopUID))
        .toString();
  }
}

class NewsPieceProductAtShopBuilder
    implements Builder<NewsPieceProductAtShop, NewsPieceProductAtShopBuilder> {
  _$NewsPieceProductAtShop? _$v;

  String? _barcode;
  String? get barcode => _$this._barcode;
  set barcode(String? barcode) => _$this._barcode = barcode;

  OsmUID? _shopUID;
  OsmUID? get shopUID => _$this._shopUID;
  set shopUID(OsmUID? shopUID) => _$this._shopUID = shopUID;

  NewsPieceProductAtShopBuilder();

  NewsPieceProductAtShopBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _barcode = $v.barcode;
      _shopUID = $v.shopUID;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(NewsPieceProductAtShop other) {
    ArgumentError.checkNotNull(other, 'other');
    _$v = other as _$NewsPieceProductAtShop;
  }

  @override
  void update(void Function(NewsPieceProductAtShopBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  _$NewsPieceProductAtShop build() {
    final _$result = _$v ??
        new _$NewsPieceProductAtShop._(
            barcode: BuiltValueNullFieldError.checkNotNull(
                barcode, 'NewsPieceProductAtShop', 'barcode'),
            shopUID: BuiltValueNullFieldError.checkNotNull(
                shopUID, 'NewsPieceProductAtShop', 'shopUID'));
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: always_put_control_body_on_new_line,always_specify_types,annotate_overrides,avoid_annotating_with_dynamic,avoid_as,avoid_catches_without_on_clauses,avoid_returning_this,deprecated_member_use_from_same_package,lines_longer_than_80_chars,omit_local_variable_types,prefer_expression_function_bodies,sort_constructors_first,test_types_in_equals,unnecessary_const,unnecessary_new
