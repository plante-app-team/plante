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
    final result = <Object?>[
      'foundShops',
      serializers.serialize(object.foundShops,
          specifiedType:
              const FullType(BuiltList, const [const FullType(Shop)])),
      'foundRoads',
      serializers.serialize(object.foundRoads,
          specifiedType:
              const FullType(BuiltList, const [const FullType(OsmRoad)])),
    ];
    Object? value;
    value = object.chosenShops;
    if (value != null) {
      result
        ..add('chosenShops')
        ..add(serializers.serialize(value,
            specifiedType:
                const FullType(BuiltList, const [const FullType(Shop)])));
    }
    value = object.chosenRoad;
    if (value != null) {
      result
        ..add('chosenRoad')
        ..add(serializers.serialize(value,
            specifiedType: const FullType(OsmRoad)));
    }
    value = object.query;
    if (value != null) {
      result
        ..add('query')
        ..add(serializers.serialize(value,
            specifiedType: const FullType(String)));
    }
    value = object.scrollOffset;
    if (value != null) {
      result
        ..add('scrollOffset')
        ..add(serializers.serialize(value,
            specifiedType: const FullType(double)));
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
        case 'chosenShops':
          result.chosenShops.replace(serializers.deserialize(value,
                  specifiedType:
                      const FullType(BuiltList, const [const FullType(Shop)]))!
              as BuiltList<Object?>);
          break;
        case 'chosenRoad':
          result.chosenRoad.replace(serializers.deserialize(value,
              specifiedType: const FullType(OsmRoad))! as OsmRoad);
          break;
        case 'foundShops':
          result.foundShops.replace(serializers.deserialize(value,
                  specifiedType:
                      const FullType(BuiltList, const [const FullType(Shop)]))!
              as BuiltList<Object?>);
          break;
        case 'foundRoads':
          result.foundRoads.replace(serializers.deserialize(value,
                  specifiedType: const FullType(
                      BuiltList, const [const FullType(OsmRoad)]))!
              as BuiltList<Object?>);
          break;
        case 'query':
          result.query = serializers.deserialize(value,
              specifiedType: const FullType(String)) as String?;
          break;
        case 'scrollOffset':
          result.scrollOffset = serializers.deserialize(value,
              specifiedType: const FullType(double)) as double?;
          break;
      }
    }

    return result.build();
  }
}

class _$MapSearchPageResult extends MapSearchPageResult {
  @override
  final BuiltList<Shop>? chosenShops;
  @override
  final OsmRoad? chosenRoad;
  @override
  final BuiltList<Shop> foundShops;
  @override
  final BuiltList<OsmRoad> foundRoads;
  @override
  final String? query;
  @override
  final double? scrollOffset;

  factory _$MapSearchPageResult(
          [void Function(MapSearchPageResultBuilder)? updates]) =>
      (new MapSearchPageResultBuilder()..update(updates)).build();

  _$MapSearchPageResult._(
      {this.chosenShops,
      this.chosenRoad,
      required this.foundShops,
      required this.foundRoads,
      this.query,
      this.scrollOffset})
      : super._() {
    BuiltValueNullFieldError.checkNotNull(
        foundShops, 'MapSearchPageResult', 'foundShops');
    BuiltValueNullFieldError.checkNotNull(
        foundRoads, 'MapSearchPageResult', 'foundRoads');
  }

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
        chosenShops == other.chosenShops &&
        chosenRoad == other.chosenRoad &&
        foundShops == other.foundShops &&
        foundRoads == other.foundRoads &&
        query == other.query &&
        scrollOffset == other.scrollOffset;
  }

  @override
  int get hashCode {
    return $jf($jc(
        $jc(
            $jc(
                $jc($jc($jc(0, chosenShops.hashCode), chosenRoad.hashCode),
                    foundShops.hashCode),
                foundRoads.hashCode),
            query.hashCode),
        scrollOffset.hashCode));
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper('MapSearchPageResult')
          ..add('chosenShops', chosenShops)
          ..add('chosenRoad', chosenRoad)
          ..add('foundShops', foundShops)
          ..add('foundRoads', foundRoads)
          ..add('query', query)
          ..add('scrollOffset', scrollOffset))
        .toString();
  }
}

class MapSearchPageResultBuilder
    implements Builder<MapSearchPageResult, MapSearchPageResultBuilder> {
  _$MapSearchPageResult? _$v;

  ListBuilder<Shop>? _chosenShops;
  ListBuilder<Shop> get chosenShops =>
      _$this._chosenShops ??= new ListBuilder<Shop>();
  set chosenShops(ListBuilder<Shop>? chosenShops) =>
      _$this._chosenShops = chosenShops;

  OsmRoadBuilder? _chosenRoad;
  OsmRoadBuilder get chosenRoad => _$this._chosenRoad ??= new OsmRoadBuilder();
  set chosenRoad(OsmRoadBuilder? chosenRoad) => _$this._chosenRoad = chosenRoad;

  ListBuilder<Shop>? _foundShops;
  ListBuilder<Shop> get foundShops =>
      _$this._foundShops ??= new ListBuilder<Shop>();
  set foundShops(ListBuilder<Shop>? foundShops) =>
      _$this._foundShops = foundShops;

  ListBuilder<OsmRoad>? _foundRoads;
  ListBuilder<OsmRoad> get foundRoads =>
      _$this._foundRoads ??= new ListBuilder<OsmRoad>();
  set foundRoads(ListBuilder<OsmRoad>? foundRoads) =>
      _$this._foundRoads = foundRoads;

  String? _query;
  String? get query => _$this._query;
  set query(String? query) => _$this._query = query;

  double? _scrollOffset;
  double? get scrollOffset => _$this._scrollOffset;
  set scrollOffset(double? scrollOffset) => _$this._scrollOffset = scrollOffset;

  MapSearchPageResultBuilder();

  MapSearchPageResultBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _chosenShops = $v.chosenShops?.toBuilder();
      _chosenRoad = $v.chosenRoad?.toBuilder();
      _foundShops = $v.foundShops.toBuilder();
      _foundRoads = $v.foundRoads.toBuilder();
      _query = $v.query;
      _scrollOffset = $v.scrollOffset;
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
              chosenShops: _chosenShops?.build(),
              chosenRoad: _chosenRoad?.build(),
              foundShops: foundShops.build(),
              foundRoads: foundRoads.build(),
              query: query,
              scrollOffset: scrollOffset);
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'chosenShops';
        _chosenShops?.build();
        _$failedField = 'chosenRoad';
        _chosenRoad?.build();
        _$failedField = 'foundShops';
        foundShops.build();
        _$failedField = 'foundRoads';
        foundRoads.build();
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
