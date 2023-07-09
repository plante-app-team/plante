// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'map_search_result.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

Serializer<MapSearchResult> _$mapSearchResultSerializer =
    new _$MapSearchResultSerializer();

class _$MapSearchResultSerializer
    implements StructuredSerializer<MapSearchResult> {
  @override
  final Iterable<Type> types = const [MapSearchResult, _$MapSearchResult];
  @override
  final String wireName = 'MapSearchResult';

  @override
  Iterable<Object?> serialize(Serializers serializers, MapSearchResult object,
      {FullType specifiedType = FullType.unspecified}) {
    final result = <Object?>[];
    Object? value;
    value = object.shops;
    if (value != null) {
      result
        ..add('shops')
        ..add(serializers.serialize(value,
            specifiedType:
                const FullType(BuiltList, const [const FullType(Shop)])));
    }
    value = object.roads;
    if (value != null) {
      result
        ..add('roads')
        ..add(serializers.serialize(value,
            specifiedType:
                const FullType(BuiltList, const [const FullType(OsmRoad)])));
    }
    return result;
  }

  @override
  MapSearchResult deserialize(
      Serializers serializers, Iterable<Object?> serialized,
      {FullType specifiedType = FullType.unspecified}) {
    final result = new MapSearchResultBuilder();

    final iterator = serialized.iterator;
    while (iterator.moveNext()) {
      final key = iterator.current! as String;
      iterator.moveNext();
      final Object? value = iterator.current;
      switch (key) {
        case 'shops':
          result.shops.replace(serializers.deserialize(value,
                  specifiedType:
                      const FullType(BuiltList, const [const FullType(Shop)]))!
              as BuiltList<Object?>);
          break;
        case 'roads':
          result.roads.replace(serializers.deserialize(value,
                  specifiedType: const FullType(
                      BuiltList, const [const FullType(OsmRoad)]))!
              as BuiltList<Object?>);
          break;
      }
    }

    return result.build();
  }
}

class _$MapSearchResult extends MapSearchResult {
  @override
  final BuiltList<Shop>? shops;
  @override
  final BuiltList<OsmRoad>? roads;

  factory _$MapSearchResult([void Function(MapSearchResultBuilder)? updates]) =>
      (new MapSearchResultBuilder()..update(updates))._build();

  _$MapSearchResult._({this.shops, this.roads}) : super._();

  @override
  MapSearchResult rebuild(void Function(MapSearchResultBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  MapSearchResultBuilder toBuilder() =>
      new MapSearchResultBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is MapSearchResult &&
        shops == other.shops &&
        roads == other.roads;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, shops.hashCode);
    _$hash = $jc(_$hash, roads.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'MapSearchResult')
          ..add('shops', shops)
          ..add('roads', roads))
        .toString();
  }
}

class MapSearchResultBuilder
    implements Builder<MapSearchResult, MapSearchResultBuilder> {
  _$MapSearchResult? _$v;

  ListBuilder<Shop>? _shops;
  ListBuilder<Shop> get shops => _$this._shops ??= new ListBuilder<Shop>();
  set shops(ListBuilder<Shop>? shops) => _$this._shops = shops;

  ListBuilder<OsmRoad>? _roads;
  ListBuilder<OsmRoad> get roads =>
      _$this._roads ??= new ListBuilder<OsmRoad>();
  set roads(ListBuilder<OsmRoad>? roads) => _$this._roads = roads;

  MapSearchResultBuilder();

  MapSearchResultBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _shops = $v.shops?.toBuilder();
      _roads = $v.roads?.toBuilder();
      _$v = null;
    }
    return this;
  }

  @override
  void replace(MapSearchResult other) {
    ArgumentError.checkNotNull(other, 'other');
    _$v = other as _$MapSearchResult;
  }

  @override
  void update(void Function(MapSearchResultBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  MapSearchResult build() => _build();

  _$MapSearchResult _build() {
    _$MapSearchResult _$result;
    try {
      _$result = _$v ??
          new _$MapSearchResult._(
              shops: _shops?.build(), roads: _roads?.build());
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'shops';
        _shops?.build();
        _$failedField = 'roads';
        _roads?.build();
      } catch (e) {
        throw new BuiltValueNestedFieldError(
            r'MapSearchResult', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
