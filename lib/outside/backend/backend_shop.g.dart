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
      'osm_uid',
      serializers.serialize(object.osmUID,
          specifiedType: const FullType(OsmUID)),
      'products_count',
      serializers.serialize(object.productsCount,
          specifiedType: const FullType(int)),
      'deleted',
      serializers.serialize(object.deleted,
          specifiedType: const FullType(bool)),
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
        case 'osm_uid':
          result.osmUID = serializers.deserialize(value,
              specifiedType: const FullType(OsmUID)) as OsmUID;
          break;
        case 'products_count':
          result.productsCount = serializers.deserialize(value,
              specifiedType: const FullType(int)) as int;
          break;
        case 'deleted':
          result.deleted = serializers.deserialize(value,
              specifiedType: const FullType(bool)) as bool;
          break;
      }
    }

    return result.build();
  }
}

class _$BackendShop extends BackendShop {
  @override
  final OsmUID osmUID;
  @override
  final int productsCount;
  @override
  final bool deleted;

  factory _$BackendShop([void Function(BackendShopBuilder)? updates]) =>
      (new BackendShopBuilder()..update(updates)).build();

  _$BackendShop._(
      {required this.osmUID,
      required this.productsCount,
      required this.deleted})
      : super._() {
    BuiltValueNullFieldError.checkNotNull(osmUID, 'BackendShop', 'osmUID');
    BuiltValueNullFieldError.checkNotNull(
        productsCount, 'BackendShop', 'productsCount');
    BuiltValueNullFieldError.checkNotNull(deleted, 'BackendShop', 'deleted');
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
        osmUID == other.osmUID &&
        productsCount == other.productsCount &&
        deleted == other.deleted;
  }

  @override
  int get hashCode {
    return $jf($jc($jc($jc(0, osmUID.hashCode), productsCount.hashCode),
        deleted.hashCode));
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper('BackendShop')
          ..add('osmUID', osmUID)
          ..add('productsCount', productsCount)
          ..add('deleted', deleted))
        .toString();
  }
}

class BackendShopBuilder implements Builder<BackendShop, BackendShopBuilder> {
  _$BackendShop? _$v;

  OsmUID? _osmUID;
  OsmUID? get osmUID => _$this._osmUID;
  set osmUID(OsmUID? osmUID) => _$this._osmUID = osmUID;

  int? _productsCount;
  int? get productsCount => _$this._productsCount;
  set productsCount(int? productsCount) =>
      _$this._productsCount = productsCount;

  bool? _deleted;
  bool? get deleted => _$this._deleted;
  set deleted(bool? deleted) => _$this._deleted = deleted;

  BackendShopBuilder() {
    BackendShop._setDefaults(this);
  }

  BackendShopBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _osmUID = $v.osmUID;
      _productsCount = $v.productsCount;
      _deleted = $v.deleted;
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
            osmUID: BuiltValueNullFieldError.checkNotNull(
                osmUID, 'BackendShop', 'osmUID'),
            productsCount: BuiltValueNullFieldError.checkNotNull(
                productsCount, 'BackendShop', 'productsCount'),
            deleted: BuiltValueNullFieldError.checkNotNull(
                deleted, 'BackendShop', 'deleted'));
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: always_put_control_body_on_new_line,always_specify_types,annotate_overrides,avoid_annotating_with_dynamic,avoid_as,avoid_catches_without_on_clauses,avoid_returning_this,deprecated_member_use_from_same_package,lines_longer_than_80_chars,omit_local_variable_types,prefer_expression_function_bodies,sort_constructors_first,test_types_in_equals,unnecessary_const,unnecessary_new
