// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'map_search_page_result.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

Serializer<MapSearchPageResult> _$mapSearchPageResultSerializer =
    new _$MapSearchPageResultSerializer();

class _$MapSearchPageResultSerializer
    implements StructuredSerializer<MapSearchPageResult> {
  @override
  final Iterable<Type> types = const [
    MapSearchPageResult,
    _$MapSearchPageResult
  ];
  @override
  final String wireName = 'MapSearchPageResult';

  @override
  Iterable<Object?> serialize(
      Serializers serializers, MapSearchPageResult object,
      {FullType specifiedType = FullType.unspecified}) {
    final result = <Object?>[];
    Object? value;
    value = object.shop;
    if (value != null) {
      result
        ..add('shop')
        ..add(
            serializers.serialize(value, specifiedType: const FullType(Shop)));
    }
    value = object.road;
    if (value != null) {
      result
        ..add('road')
        ..add(serializers.serialize(value,
            specifiedType: const FullType(OsmRoad)));
    }
    return result;
  }

  @override
  MapSearchPageResult deserialize(
      Serializers serializers, Iterable<Object?> serialized,
      {FullType specifiedType = FullType.unspecified}) {
    final result = new MapSearchPageResultBuilder();

    final iterator = serialized.iterator;
    while (iterator.moveNext()) {
      final key = iterator.current as String;
      iterator.moveNext();
      final Object? value = iterator.current;
      switch (key) {
        case 'shop':
          result.shop.replace(serializers.deserialize(value,
              specifiedType: const FullType(Shop))! as Shop);
          break;
        case 'road':
          result.road.replace(serializers.deserialize(value,
              specifiedType: const FullType(OsmRoad))! as OsmRoad);
          break;
      }
    }

    return result.build();
  }
}

class _$MapSearchPageResult extends MapSearchPageResult {
  @override
  final Shop? shop;
  @override
  final OsmRoad? road;

  factory _$MapSearchPageResult(
          [void Function(MapSearchPageResultBuilder)? updates]) =>
      (new MapSearchPageResultBuilder()..update(updates)).build();

  _$MapSearchPageResult._({this.shop, this.road}) : super._();

  @override
  MapSearchPageResult rebuild(
          void Function(MapSearchPageResultBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  MapSearchPageResultBuilder toBuilder() =>
      new MapSearchPageResultBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is MapSearchPageResult &&
        shop == other.shop &&
        road == other.road;
  }

  @override
  int get hashCode {
    return $jf($jc($jc(0, shop.hashCode), road.hashCode));
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper('MapSearchPageResult')
          ..add('shop', shop)
          ..add('road', road))
        .toString();
  }
}

class MapSearchPageResultBuilder
    implements Builder<MapSearchPageResult, MapSearchPageResultBuilder> {
  _$MapSearchPageResult? _$v;

  ShopBuilder? _shop;
  ShopBuilder get shop => _$this._shop ??= new ShopBuilder();
  set shop(ShopBuilder? shop) => _$this._shop = shop;

  OsmRoadBuilder? _road;
  OsmRoadBuilder get road => _$this._road ??= new OsmRoadBuilder();
  set road(OsmRoadBuilder? road) => _$this._road = road;

  MapSearchPageResultBuilder();

  MapSearchPageResultBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _shop = $v.shop?.toBuilder();
      _road = $v.road?.toBuilder();
      _$v = null;
    }
    return this;
  }

  @override
  void replace(MapSearchPageResult other) {
    ArgumentError.checkNotNull(other, 'other');
    _$v = other as _$MapSearchPageResult;
  }

  @override
  void update(void Function(MapSearchPageResultBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  _$MapSearchPageResult build() {
    _$MapSearchPageResult _$result;
    try {
      _$result = _$v ??
          new _$MapSearchPageResult._(
              shop: _shop?.build(), road: _road?.build());
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'shop';
        _shop?.build();
        _$failedField = 'road';
        _road?.build();
      } catch (e) {
        throw new BuiltValueNestedFieldError(
            'MapSearchPageResult', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: always_put_control_body_on_new_line,always_specify_types,annotate_overrides,avoid_annotating_with_dynamic,avoid_as,avoid_catches_without_on_clauses,avoid_returning_this,deprecated_member_use_from_same_package,lines_longer_than_80_chars,omit_local_variable_types,prefer_expression_function_bodies,sort_constructors_first,test_types_in_equals,unnecessary_const,unnecessary_new
