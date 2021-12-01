// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'osm_address.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

Serializer<OsmAddress> _$osmAddressSerializer = new _$OsmAddressSerializer();

class _$OsmAddressSerializer implements StructuredSerializer<OsmAddress> {
  @override
  final Iterable<Type> types = const [OsmAddress, _$OsmAddress];
  @override
  final String wireName = 'OsmAddress';

  @override
  Iterable<Object?> serialize(Serializers serializers, OsmAddress object,
      {FullType specifiedType = FullType.unspecified}) {
    final result = <Object?>[];
    Object? value;
    value = object.houseNumber;
    if (value != null) {
      result
        ..add('houseNumber')
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
    value = object.neighbourhood;
    if (value != null) {
      result
        ..add('neighbourhood')
        ..add(serializers.serialize(value,
            specifiedType: const FullType(String)));
    }
    value = object.cityDistrict;
    if (value != null) {
      result
        ..add('cityDistrict')
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
    value = object.country;
    if (value != null) {
      result
        ..add('country')
        ..add(serializers.serialize(value,
            specifiedType: const FullType(String)));
    }
    value = object.countryCode;
    if (value != null) {
      result
        ..add('countryCode')
        ..add(serializers.serialize(value,
            specifiedType: const FullType(String)));
    }
    return result;
  }

  @override
  OsmAddress deserialize(Serializers serializers, Iterable<Object?> serialized,
      {FullType specifiedType = FullType.unspecified}) {
    final result = new OsmAddressBuilder();

    final iterator = serialized.iterator;
    while (iterator.moveNext()) {
      final key = iterator.current as String;
      iterator.moveNext();
      final Object? value = iterator.current;
      switch (key) {
        case 'houseNumber':
          result.houseNumber = serializers.deserialize(value,
              specifiedType: const FullType(String)) as String?;
          break;
        case 'road':
          result.road = serializers.deserialize(value,
              specifiedType: const FullType(String)) as String?;
          break;
        case 'neighbourhood':
          result.neighbourhood = serializers.deserialize(value,
              specifiedType: const FullType(String)) as String?;
          break;
        case 'cityDistrict':
          result.cityDistrict = serializers.deserialize(value,
              specifiedType: const FullType(String)) as String?;
          break;
        case 'city':
          result.city = serializers.deserialize(value,
              specifiedType: const FullType(String)) as String?;
          break;
        case 'country':
          result.country = serializers.deserialize(value,
              specifiedType: const FullType(String)) as String?;
          break;
        case 'countryCode':
          result.countryCode = serializers.deserialize(value,
              specifiedType: const FullType(String)) as String?;
          break;
      }
    }

    return result.build();
  }
}

class _$OsmAddress extends OsmAddress {
  @override
  final String? houseNumber;
  @override
  final String? road;
  @override
  final String? neighbourhood;
  @override
  final String? cityDistrict;
  @override
  final String? city;
  @override
  final String? country;
  @override
  final String? countryCode;

  factory _$OsmAddress([void Function(OsmAddressBuilder)? updates]) =>
      (new OsmAddressBuilder()..update(updates)).build();

  _$OsmAddress._(
      {this.houseNumber,
      this.road,
      this.neighbourhood,
      this.cityDistrict,
      this.city,
      this.country,
      this.countryCode})
      : super._();

  @override
  OsmAddress rebuild(void Function(OsmAddressBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  OsmAddressBuilder toBuilder() => new OsmAddressBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is OsmAddress &&
        houseNumber == other.houseNumber &&
        road == other.road &&
        neighbourhood == other.neighbourhood &&
        cityDistrict == other.cityDistrict &&
        city == other.city &&
        country == other.country &&
        countryCode == other.countryCode;
  }

  @override
  int get hashCode {
    return $jf($jc(
        $jc(
            $jc(
                $jc(
                    $jc($jc($jc(0, houseNumber.hashCode), road.hashCode),
                        neighbourhood.hashCode),
                    cityDistrict.hashCode),
                city.hashCode),
            country.hashCode),
        countryCode.hashCode));
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper('OsmAddress')
          ..add('houseNumber', houseNumber)
          ..add('road', road)
          ..add('neighbourhood', neighbourhood)
          ..add('cityDistrict', cityDistrict)
          ..add('city', city)
          ..add('country', country)
          ..add('countryCode', countryCode))
        .toString();
  }
}

class OsmAddressBuilder implements Builder<OsmAddress, OsmAddressBuilder> {
  _$OsmAddress? _$v;

  String? _houseNumber;
  String? get houseNumber => _$this._houseNumber;
  set houseNumber(String? houseNumber) => _$this._houseNumber = houseNumber;

  String? _road;
  String? get road => _$this._road;
  set road(String? road) => _$this._road = road;

  String? _neighbourhood;
  String? get neighbourhood => _$this._neighbourhood;
  set neighbourhood(String? neighbourhood) =>
      _$this._neighbourhood = neighbourhood;

  String? _cityDistrict;
  String? get cityDistrict => _$this._cityDistrict;
  set cityDistrict(String? cityDistrict) => _$this._cityDistrict = cityDistrict;

  String? _city;
  String? get city => _$this._city;
  set city(String? city) => _$this._city = city;

  String? _country;
  String? get country => _$this._country;
  set country(String? country) => _$this._country = country;

  String? _countryCode;
  String? get countryCode => _$this._countryCode;
  set countryCode(String? countryCode) => _$this._countryCode = countryCode;

  OsmAddressBuilder();

  OsmAddressBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _houseNumber = $v.houseNumber;
      _road = $v.road;
      _neighbourhood = $v.neighbourhood;
      _cityDistrict = $v.cityDistrict;
      _city = $v.city;
      _country = $v.country;
      _countryCode = $v.countryCode;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(OsmAddress other) {
    ArgumentError.checkNotNull(other, 'other');
    _$v = other as _$OsmAddress;
  }

  @override
  void update(void Function(OsmAddressBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  _$OsmAddress build() {
    final _$result = _$v ??
        new _$OsmAddress._(
            houseNumber: houseNumber,
            road: road,
            neighbourhood: neighbourhood,
            cityDistrict: cityDistrict,
            city: city,
            country: country,
            countryCode: countryCode);
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: always_put_control_body_on_new_line,always_specify_types,annotate_overrides,avoid_annotating_with_dynamic,avoid_as,avoid_catches_without_on_clauses,avoid_returning_this,deprecated_member_use_from_same_package,lines_longer_than_80_chars,omit_local_variable_types,prefer_expression_function_bodies,sort_constructors_first,test_types_in_equals,unnecessary_const,unnecessary_new
