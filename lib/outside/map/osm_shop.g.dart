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
      final key = iterator.current as String;
      iterator.moveNext();
      final Object? value = iterator.current;
      switch (key) {
        case 'osmUID':
          result.osmUID = serializers.deserialize(value,
              specifiedType: const FullType(String)) as String;
          break;
        case 'name':
          result.name = serializers.deserialize(value,
              specifiedType: const FullType(String)) as String;
          break;
        case 'type':
          result.type = serializers.deserialize(value,
              specifiedType: const FullType(String)) as String?;
          break;
        case 'latitude':
          result.latitude = serializers.deserialize(value,
              specifiedType: const FullType(double)) as double;
          break;
        case 'longitude':
          result.longitude = serializers.deserialize(value,
              specifiedType: const FullType(double)) as double;
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
  final String osmUID;
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
      (new OsmShopBuilder()..update(updates)).build();

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
    BuiltValueNullFieldError.checkNotNull(osmUID, 'OsmShop', 'osmUID');
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
    return $jf($jc(
        $jc(
            $jc(
                $jc(
                    $jc(
                        $jc($jc($jc(0, osmUID.hashCode), name.hashCode),
                            type.hashCode),
                        latitude.hashCode),
                    longitude.hashCode),
                city.hashCode),
            road.hashCode),
        houseNumber.hashCode));
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper('OsmShop')
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

  String? _osmUID;
  String? get osmUID => _$this._osmUID;
  set osmUID(String? osmUID) => _$this._osmUID = osmUID;

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
  _$OsmShop build() {
    final _$result = _$v ??
        new _$OsmShop._(
            osmUID: BuiltValueNullFieldError.checkNotNull(
                osmUID, 'OsmShop', 'osmUID'),
            name:
                BuiltValueNullFieldError.checkNotNull(name, 'OsmShop', 'name'),
            type: type,
            latitude: BuiltValueNullFieldError.checkNotNull(
                latitude, 'OsmShop', 'latitude'),
            longitude: BuiltValueNullFieldError.checkNotNull(
                longitude, 'OsmShop', 'longitude'),
            city: city,
            road: road,
            houseNumber: houseNumber);
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: always_put_control_body_on_new_line,always_specify_types,annotate_overrides,avoid_annotating_with_dynamic,avoid_as,avoid_catches_without_on_clauses,avoid_returning_this,deprecated_member_use_from_same_package,lines_longer_than_80_chars,omit_local_variable_types,prefer_expression_function_bodies,sort_constructors_first,test_types_in_equals,unnecessary_const,unnecessary_new
