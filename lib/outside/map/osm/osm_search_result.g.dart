// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'osm_search_result.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

Serializer<OsmSearchResult> _$osmSearchResultSerializer =
    new _$OsmSearchResultSerializer();

class _$OsmSearchResultSerializer
    implements StructuredSerializer<OsmSearchResult> {
  @override
  final Iterable<Type> types = const [OsmSearchResult, _$OsmSearchResult];
  @override
  final String wireName = 'OsmSearchResult';

  @override
  Iterable<Object?> serialize(Serializers serializers, OsmSearchResult object,
      {FullType specifiedType = FullType.unspecified}) {
    final result = <Object?>[
      'shops',
      serializers.serialize(object.shops,
          specifiedType:
              const FullType(BuiltList, const [const FullType(OsmShop)])),
      'roads',
      serializers.serialize(object.roads,
          specifiedType:
              const FullType(BuiltList, const [const FullType(OsmRoad)])),
    ];

    return result;
  }

  @override
  OsmSearchResult deserialize(
      Serializers serializers, Iterable<Object?> serialized,
      {FullType specifiedType = FullType.unspecified}) {
    final result = new OsmSearchResultBuilder();

    final iterator = serialized.iterator;
    while (iterator.moveNext()) {
      final key = iterator.current as String;
      iterator.moveNext();
      final Object? value = iterator.current;
      switch (key) {
        case 'shops':
          result.shops.replace(serializers.deserialize(value,
                  specifiedType: const FullType(
                      BuiltList, const [const FullType(OsmShop)]))!
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

class _$OsmSearchResult extends OsmSearchResult {
  @override
  final BuiltList<OsmShop> shops;
  @override
  final BuiltList<OsmRoad> roads;

  factory _$OsmSearchResult([void Function(OsmSearchResultBuilder)? updates]) =>
      (new OsmSearchResultBuilder()..update(updates)).build();

  _$OsmSearchResult._({required this.shops, required this.roads}) : super._() {
    BuiltValueNullFieldError.checkNotNull(shops, 'OsmSearchResult', 'shops');
    BuiltValueNullFieldError.checkNotNull(roads, 'OsmSearchResult', 'roads');
  }

  @override
  OsmSearchResult rebuild(void Function(OsmSearchResultBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  OsmSearchResultBuilder toBuilder() =>
      new OsmSearchResultBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is OsmSearchResult &&
        shops == other.shops &&
        roads == other.roads;
  }

  @override
  int get hashCode {
    return $jf($jc($jc(0, shops.hashCode), roads.hashCode));
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper('OsmSearchResult')
          ..add('shops', shops)
          ..add('roads', roads))
        .toString();
  }
}

class OsmSearchResultBuilder
    implements Builder<OsmSearchResult, OsmSearchResultBuilder> {
  _$OsmSearchResult? _$v;

  ListBuilder<OsmShop>? _shops;
  ListBuilder<OsmShop> get shops =>
      _$this._shops ??= new ListBuilder<OsmShop>();
  set shops(ListBuilder<OsmShop>? shops) => _$this._shops = shops;

  ListBuilder<OsmRoad>? _roads;
  ListBuilder<OsmRoad> get roads =>
      _$this._roads ??= new ListBuilder<OsmRoad>();
  set roads(ListBuilder<OsmRoad>? roads) => _$this._roads = roads;

  OsmSearchResultBuilder();

  OsmSearchResultBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _shops = $v.shops.toBuilder();
      _roads = $v.roads.toBuilder();
      _$v = null;
    }
    return this;
  }

  @override
  void replace(OsmSearchResult other) {
    ArgumentError.checkNotNull(other, 'other');
    _$v = other as _$OsmSearchResult;
  }

  @override
  void update(void Function(OsmSearchResultBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  _$OsmSearchResult build() {
    _$OsmSearchResult _$result;
    try {
      _$result = _$v ??
          new _$OsmSearchResult._(shops: shops.build(), roads: roads.build());
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'shops';
        shops.build();
        _$failedField = 'roads';
        roads.build();
      } catch (e) {
        throw new BuiltValueNestedFieldError(
            'OsmSearchResult', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: always_put_control_body_on_new_line,always_specify_types,annotate_overrides,avoid_annotating_with_dynamic,avoid_as,avoid_catches_without_on_clauses,avoid_returning_this,deprecated_member_use_from_same_package,lines_longer_than_80_chars,omit_local_variable_types,prefer_expression_function_bodies,sort_constructors_first,test_types_in_equals,unnecessary_const,unnecessary_new
