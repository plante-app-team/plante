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
      'osmUID',
      serializers.serialize(object.osmUID,
          specifiedType: const FullType(OsmUID)),
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
    value = object.city;
    if (value != null) {
      result
        ..add('city')
        ..add(serializers.serialize(value,
            specifiedType: const FullType(String)));
    }
    value = object.road;
    if (value != null) {
      result
        ..add('road')
        ..add(serializers.serialize(value,
            specifiedType: const FullType(String)));
    }
    value = object.houseNumber;
    if (value != null) {
      result
        ..add('houseNumber')
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
      final key = iterator.current! as String;
      iterator.moveNext();
      final Object? value = iterator.current;
      switch (key) {
        case 'osmUID':
          result.osmUID = serializers.deserialize(value,
              specifiedType: const FullType(OsmUID))! as OsmUID;
          break;
        case 'name':
          result.name = serializers.deserialize(value,
              specifiedType: const FullType(String))! as String;
          break;
        case 'type':
          result.type = serializers.deserialize(value,
              specifiedType: const FullType(String)) as String?;
          break;
        case 'latitude':
          result.latitude = serializers.deserialize(value,
              specifiedType: const FullType(double))! as double;
          break;
        case 'longitude':
          result.longitude = serializers.deserialize(value,
              specifiedType: const FullType(double))! as double;
          break;
        case 'city':
          result.city = serializers.deserialize(value,
              specifiedType: const FullType(String)) as String?;
          break;
        case 'road':
          result.road = serializers.deserialize(value,
              specifiedType: const FullType(String)) as String?;
          break;
        case 'houseNumber':
          result.houseNumber = serializers.deserialize(value,
              specifiedType: const FullType(String)) as String?;
          break;
      }
    }

    return result.build();
  }
}

class _$OsmShop extends OsmShop {
  @override
  final OsmUID osmUID;
  @override
  final String name;
  @override
  final String? type;
  @override
  final double latitude;
  @override
  final double longitude;
  @override
  final String? city;
  @override
  final String? road;
  @override
  final String? houseNumber;

  factory _$OsmShop([void Function(OsmShopBuilder)? updates]) =>
      (new OsmShopBuilder()..update(updates))._build();

  _$OsmShop._(
      {required this.osmUID,
      required this.name,
      this.type,
      required this.latitude,
      required this.longitude,
      this.city,
      this.road,
      this.houseNumber})
      : super._() {
    BuiltValueNullFieldError.checkNotNull(osmUID, r'OsmShop', 'osmUID');
    BuiltValueNullFieldError.checkNotNull(name, r'OsmShop', 'name');
    BuiltValueNullFieldError.checkNotNull(latitude, r'OsmShop', 'latitude');
    BuiltValueNullFieldError.checkNotNull(longitude, r'OsmShop', 'longitude');
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
        osmUID == other.osmUID &&
        name == other.name &&
        type == other.type &&
        latitude == other.latitude &&
        longitude == other.longitude &&
        city == other.city &&
        road == other.road &&
        houseNumber == other.houseNumber;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, osmUID.hashCode);
    _$hash = $jc(_$hash, name.hashCode);
    _$hash = $jc(_$hash, type.hashCode);
    _$hash = $jc(_$hash, latitude.hashCode);
    _$hash = $jc(_$hash, longitude.hashCode);
    _$hash = $jc(_$hash, city.hashCode);
    _$hash = $jc(_$hash, road.hashCode);
    _$hash = $jc(_$hash, houseNumber.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'OsmShop')
          ..add('osmUID', osmUID)
          ..add('name', name)
          ..add('type', type)
          ..add('latitude', latitude)
          ..add('longitude', longitude)
          ..add('city', city)
          ..add('road', road)
          ..add('houseNumber', houseNumber))
        .toString();
  }
}

class OsmShopBuilder implements Builder<OsmShop, OsmShopBuilder> {
  _$OsmShop? _$v;

  OsmUID? _osmUID;
  OsmUID? get osmUID => _$this._osmUID;
  set osmUID(OsmUID? osmUID) => _$this._osmUID = osmUID;

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

  String? _city;
  String? get city => _$this._city;
  set city(String? city) => _$this._city = city;

  String? _road;
  String? get road => _$this._road;
  set road(String? road) => _$this._road = road;

  String? _houseNumber;
  String? get houseNumber => _$this._houseNumber;
  set houseNumber(String? houseNumber) => _$this._houseNumber = houseNumber;

  OsmShopBuilder();

  OsmShopBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _osmUID = $v.osmUID;
      _name = $v.name;
      _type = $v.type;
      _latitude = $v.latitude;
      _longitude = $v.longitude;
      _city = $v.city;
      _road = $v.road;
      _houseNumber = $v.houseNumber;
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
  OsmShop build() => _build();

  _$OsmShop _build() {
    final _$result = _$v ??
        new _$OsmShop._(
            osmUID: BuiltValueNullFieldError.checkNotNull(
                osmUID, r'OsmShop', 'osmUID'),
            name:
                BuiltValueNullFieldError.checkNotNull(name, r'OsmShop', 'name'),
            type: type,
            latitude: BuiltValueNullFieldError.checkNotNull(
                latitude, r'OsmShop', 'latitude'),
            longitude: BuiltValueNullFieldError.checkNotNull(
                longitude, r'OsmShop', 'longitude'),
            city: city,
            road: road,
            houseNumber: houseNumber);
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
