// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'shops_in_bounds_response.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

Serializer<ShopsInBoundsResponse> _$shopsInBoundsResponseSerializer =
    new _$ShopsInBoundsResponseSerializer();

class _$ShopsInBoundsResponseSerializer
    implements StructuredSerializer<ShopsInBoundsResponse> {
  @override
  final Iterable<Type> types = const [
    ShopsInBoundsResponse,
    _$ShopsInBoundsResponse
  ];
  @override
  final String wireName = 'ShopsInBoundsResponse';

  @override
  Iterable<Object?> serialize(
      Serializers serializers, ShopsInBoundsResponse object,
      {FullType specifiedType = FullType.unspecified}) {
    final result = <Object?>[
      'results',
      serializers.serialize(object.shops,
          specifiedType: const FullType(BuiltMap,
              const [const FullType(String), const FullType(BackendShop)])),
      'barcodes',
      serializers.serialize(object.barcodes,
          specifiedType: const FullType(BuiltMap, const [
            const FullType(String),
            const FullType(BuiltList, const [const FullType(String)])
          ])),
    ];

    return result;
  }

  @override
  ShopsInBoundsResponse deserialize(
      Serializers serializers, Iterable<Object?> serialized,
      {FullType specifiedType = FullType.unspecified}) {
    final result = new ShopsInBoundsResponseBuilder();

    final iterator = serialized.iterator;
    while (iterator.moveNext()) {
      final key = iterator.current! as String;
      iterator.moveNext();
      final Object? value = iterator.current;
      switch (key) {
        case 'results':
          result.shops.replace(serializers.deserialize(value,
              specifiedType: const FullType(BuiltMap, const [
                const FullType(String),
                const FullType(BackendShop)
              ]))!);
          break;
        case 'barcodes':
          result.barcodes.replace(serializers.deserialize(value,
              specifiedType: const FullType(BuiltMap, const [
                const FullType(String),
                const FullType(BuiltList, const [const FullType(String)])
              ]))!);
          break;
      }
    }

    return result.build();
  }
}

class _$ShopsInBoundsResponse extends ShopsInBoundsResponse {
  @override
  final BuiltMap<String, BackendShop> shops;
  @override
  final BuiltMap<String, BuiltList<String>> barcodes;

  factory _$ShopsInBoundsResponse(
          [void Function(ShopsInBoundsResponseBuilder)? updates]) =>
      (new ShopsInBoundsResponseBuilder()..update(updates))._build();

  _$ShopsInBoundsResponse._({required this.shops, required this.barcodes})
      : super._() {
    BuiltValueNullFieldError.checkNotNull(
        shops, r'ShopsInBoundsResponse', 'shops');
    BuiltValueNullFieldError.checkNotNull(
        barcodes, r'ShopsInBoundsResponse', 'barcodes');
  }

  @override
  ShopsInBoundsResponse rebuild(
          void Function(ShopsInBoundsResponseBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  ShopsInBoundsResponseBuilder toBuilder() =>
      new ShopsInBoundsResponseBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is ShopsInBoundsResponse &&
        shops == other.shops &&
        barcodes == other.barcodes;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, shops.hashCode);
    _$hash = $jc(_$hash, barcodes.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'ShopsInBoundsResponse')
          ..add('shops', shops)
          ..add('barcodes', barcodes))
        .toString();
  }
}

class ShopsInBoundsResponseBuilder
    implements Builder<ShopsInBoundsResponse, ShopsInBoundsResponseBuilder> {
  _$ShopsInBoundsResponse? _$v;

  MapBuilder<String, BackendShop>? _shops;
  MapBuilder<String, BackendShop> get shops =>
      _$this._shops ??= new MapBuilder<String, BackendShop>();
  set shops(MapBuilder<String, BackendShop>? shops) => _$this._shops = shops;

  MapBuilder<String, BuiltList<String>>? _barcodes;
  MapBuilder<String, BuiltList<String>> get barcodes =>
      _$this._barcodes ??= new MapBuilder<String, BuiltList<String>>();
  set barcodes(MapBuilder<String, BuiltList<String>>? barcodes) =>
      _$this._barcodes = barcodes;

  ShopsInBoundsResponseBuilder();

  ShopsInBoundsResponseBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _shops = $v.shops.toBuilder();
      _barcodes = $v.barcodes.toBuilder();
      _$v = null;
    }
    return this;
  }

  @override
  void replace(ShopsInBoundsResponse other) {
    ArgumentError.checkNotNull(other, 'other');
    _$v = other as _$ShopsInBoundsResponse;
  }

  @override
  void update(void Function(ShopsInBoundsResponseBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  ShopsInBoundsResponse build() => _build();

  _$ShopsInBoundsResponse _build() {
    _$ShopsInBoundsResponse _$result;
    try {
      _$result = _$v ??
          new _$ShopsInBoundsResponse._(
              shops: shops.build(), barcodes: barcodes.build());
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'shops';
        shops.build();
        _$failedField = 'barcodes';
        barcodes.build();
      } catch (e) {
        throw new BuiltValueNestedFieldError(
            r'ShopsInBoundsResponse', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
