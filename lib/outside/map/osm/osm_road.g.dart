// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'osm_road.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

Serializer<OsmRoad> _$osmRoadSerializer = new _$OsmRoadSerializer();

class _$OsmRoadSerializer implements StructuredSerializer<OsmRoad> {
  @override
  final Iterable<Type> types = const [OsmRoad, _$OsmRoad];
  @override
  final String wireName = 'OsmRoad';

  @override
  Iterable<Object?> serialize(Serializers serializers, OsmRoad object,
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

    return result;
  }

  @override
  OsmRoad deserialize(Serializers serializers, Iterable<Object?> serialized,
      {FullType specifiedType = FullType.unspecified}) {
    final result = new OsmRoadBuilder();

    final iterator = serialized.iterator;
    while (iterator.moveNext()) {
      final key = iterator.current! as String;
      iterator.moveNext();
      final Object? value = iterator.current;
      switch (key) {
        case 'osmId':
          result.osmId = serializers.deserialize(value,
              specifiedType: const FullType(String))! as String;
          break;
        case 'name':
          result.name = serializers.deserialize(value,
              specifiedType: const FullType(String))! as String;
          break;
        case 'latitude':
          result.latitude = serializers.deserialize(value,
              specifiedType: const FullType(double))! as double;
          break;
        case 'longitude':
          result.longitude = serializers.deserialize(value,
              specifiedType: const FullType(double))! as double;
          break;
      }
    }

    return result.build();
  }
}

class _$OsmRoad extends OsmRoad {
  @override
  final String osmId;
  @override
  final String name;
  @override
  final double latitude;
  @override
  final double longitude;

  factory _$OsmRoad([void Function(OsmRoadBuilder)? updates]) =>
      (new OsmRoadBuilder()..update(updates))._build();

  _$OsmRoad._(
      {required this.osmId,
      required this.name,
      required this.latitude,
      required this.longitude})
      : super._() {
    BuiltValueNullFieldError.checkNotNull(osmId, r'OsmRoad', 'osmId');
    BuiltValueNullFieldError.checkNotNull(name, r'OsmRoad', 'name');
    BuiltValueNullFieldError.checkNotNull(latitude, r'OsmRoad', 'latitude');
    BuiltValueNullFieldError.checkNotNull(longitude, r'OsmRoad', 'longitude');
  }

  @override
  OsmRoad rebuild(void Function(OsmRoadBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  OsmRoadBuilder toBuilder() => new OsmRoadBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is OsmRoad &&
        osmId == other.osmId &&
        name == other.name &&
        latitude == other.latitude &&
        longitude == other.longitude;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, osmId.hashCode);
    _$hash = $jc(_$hash, name.hashCode);
    _$hash = $jc(_$hash, latitude.hashCode);
    _$hash = $jc(_$hash, longitude.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'OsmRoad')
          ..add('osmId', osmId)
          ..add('name', name)
          ..add('latitude', latitude)
          ..add('longitude', longitude))
        .toString();
  }
}

class OsmRoadBuilder implements Builder<OsmRoad, OsmRoadBuilder> {
  _$OsmRoad? _$v;

  String? _osmId;
  String? get osmId => _$this._osmId;
  set osmId(String? osmId) => _$this._osmId = osmId;

  String? _name;
  String? get name => _$this._name;
  set name(String? name) => _$this._name = name;

  double? _latitude;
  double? get latitude => _$this._latitude;
  set latitude(double? latitude) => _$this._latitude = latitude;

  double? _longitude;
  double? get longitude => _$this._longitude;
  set longitude(double? longitude) => _$this._longitude = longitude;

  OsmRoadBuilder();

  OsmRoadBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _osmId = $v.osmId;
      _name = $v.name;
      _latitude = $v.latitude;
      _longitude = $v.longitude;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(OsmRoad other) {
    ArgumentError.checkNotNull(other, 'other');
    _$v = other as _$OsmRoad;
  }

  @override
  void update(void Function(OsmRoadBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  OsmRoad build() => _build();

  _$OsmRoad _build() {
    final _$result = _$v ??
        new _$OsmRoad._(
            osmId: BuiltValueNullFieldError.checkNotNull(
                osmId, r'OsmRoad', 'osmId'),
            name:
                BuiltValueNullFieldError.checkNotNull(name, r'OsmRoad', 'name'),
            latitude: BuiltValueNullFieldError.checkNotNull(
                latitude, r'OsmRoad', 'latitude'),
            longitude: BuiltValueNullFieldError.checkNotNull(
                longitude, r'OsmRoad', 'longitude'));
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
