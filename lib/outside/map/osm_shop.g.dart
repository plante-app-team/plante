// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'osm_shop.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

Serializer<OsmShop> _$osmShopSerializer = new _$OsmShopSerializer();

class _$OsmShopSerializer implements StructuredSerializer<OsmShop> {
  @override
  final Iterable<Type> types = const [OsmShop, _$OsmShop];
  @override
  final String wireName = 'OsmShop';

  @override
  Iterable<Object?> serialize(Serializers serializers, OsmShop object,
      {FullType specifiedType = FullType.unspecified}) {
    final result = <Object?>[
      'osmId',
      serializers.serialize(object.osmId,
          specifiedType: const FullType(String)),
      'name',
      serializers.serialize(object.name, specifiedType: const FullType(String)),
      'latitude',
      serializers.serialize(object.latitude,
          specifiedType: const FullType(double)),
      'longitude',
      serializers.serialize(object.longitude,
          specifiedType: const FullType(double)),
    ];
    Object? value;
    value = object.type;
    if (value != null) {
      result
        ..add('type')
        ..add(serializers.serialize(value,
            specifiedType: const FullType(String)));
    }
    return result;
  }

  @override
  OsmShop deserialize(Serializers serializers, Iterable<Object?> serialized,
      {FullType specifiedType = FullType.unspecified}) {
    final result = new OsmShopBuilder();

    final iterator = serialized.iterator;
    while (iterator.moveNext()) {
      final key = iterator.current as String;
      iterator.moveNext();
      final Object? value = iterator.current;
      switch (key) {
        case 'osmId':
          result.osmId = serializers.deserialize(value,
              specifiedType: const FullType(String)) as String;
          break;
        case 'name':
          result.name = serializers.deserialize(value,
              specifiedType: const FullType(String)) as String;
          break;
        case 'type':
          result.type = serializers.deserialize(value,
              specifiedType: const FullType(String)) as String;
          break;
        case 'latitude':
          result.latitude = serializers.deserialize(value,
              specifiedType: const FullType(double)) as double;
          break;
        case 'longitude':
          result.longitude = serializers.deserialize(value,
              specifiedType: const FullType(double)) as double;
          break;
      }
    }

    return result.build();
  }
}

class _$OsmShop extends OsmShop {
  @override
  final String osmId;
  @override
  final String name;
  @override
  final String? type;
  @override
  final double latitude;
  @override
  final double longitude;

  factory _$OsmShop([void Function(OsmShopBuilder)? updates]) =>
      (new OsmShopBuilder()..update(updates)).build();

  _$OsmShop._(
      {required this.osmId,
      required this.name,
      this.type,
      required this.latitude,
      required this.longitude})
      : super._() {
    BuiltValueNullFieldError.checkNotNull(osmId, 'OsmShop', 'osmId');
    BuiltValueNullFieldError.checkNotNull(name, 'OsmShop', 'name');
    BuiltValueNullFieldError.checkNotNull(latitude, 'OsmShop', 'latitude');
    BuiltValueNullFieldError.checkNotNull(longitude, 'OsmShop', 'longitude');
  }

  @override
  OsmShop rebuild(void Function(OsmShopBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  OsmShopBuilder toBuilder() => new OsmShopBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is OsmShop &&
        osmId == other.osmId &&
        name == other.name &&
        type == other.type &&
        latitude == other.latitude &&
        longitude == other.longitude;
  }

  @override
  int get hashCode {
    return $jf($jc(
        $jc($jc($jc($jc(0, osmId.hashCode), name.hashCode), type.hashCode),
            latitude.hashCode),
        longitude.hashCode));
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper('OsmShop')
          ..add('osmId', osmId)
          ..add('name', name)
          ..add('type', type)
          ..add('latitude', latitude)
          ..add('longitude', longitude))
        .toString();
  }
}

class OsmShopBuilder implements Builder<OsmShop, OsmShopBuilder> {
  _$OsmShop? _$v;

  String? _osmId;
  String? get osmId => _$this._osmId;
  set osmId(String? osmId) => _$this._osmId = osmId;

  String? _name;
  String? get name => _$this._name;
  set name(String? name) => _$this._name = name;

  String? _type;
  String? get type => _$this._type;
  set type(String? type) => _$this._type = type;

  double? _latitude;
  double? get latitude => _$this._latitude;
  set latitude(double? latitude) => _$this._latitude = latitude;

  double? _longitude;
  double? get longitude => _$this._longitude;
  set longitude(double? longitude) => _$this._longitude = longitude;

  OsmShopBuilder();

  OsmShopBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _osmId = $v.osmId;
      _name = $v.name;
      _type = $v.type;
      _latitude = $v.latitude;
      _longitude = $v.longitude;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(OsmShop other) {
    ArgumentError.checkNotNull(other, 'other');
    _$v = other as _$OsmShop;
  }

  @override
  void update(void Function(OsmShopBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  _$OsmShop build() {
    final _$result = _$v ??
        new _$OsmShop._(
            osmId: BuiltValueNullFieldError.checkNotNull(
                osmId, 'OsmShop', 'osmId'),
            name:
                BuiltValueNullFieldError.checkNotNull(name, 'OsmShop', 'name'),
            type: type,
            latitude: BuiltValueNullFieldError.checkNotNull(
                latitude, 'OsmShop', 'latitude'),
            longitude: BuiltValueNullFieldError.checkNotNull(
                longitude, 'OsmShop', 'longitude'));
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: always_put_control_body_on_new_line,always_specify_types,annotate_overrides,avoid_annotating_with_dynamic,avoid_as,avoid_catches_without_on_clauses,avoid_returning_this,lines_longer_than_80_chars,omit_local_variable_types,prefer_expression_function_bodies,sort_constructors_first,test_types_in_equals,unnecessary_const,unnecessary_new
