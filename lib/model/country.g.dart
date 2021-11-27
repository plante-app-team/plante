// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'country.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const Country _$ad = const Country._('ad');
const Country _$ae = const Country._('ae');
const Country _$af = const Country._('af');
const Country _$ag = const Country._('ag');
const Country _$be = const Country._('be');
const Country _$nl = const Country._('nl');
const Country _$fr = const Country._('fr');
const Country _$de = const Country._('de');
const Country _$lu = const Country._('lu');
const Country _$ru = const Country._('ru');

Country _$valueOf(String name) {
  switch (name) {
    case 'ad':
      return _$ad;
    case 'ae':
      return _$ae;
    case 'af':
      return _$af;
    case 'ag':
      return _$ag;
    case 'be':
      return _$be;
    case 'nl':
      return _$nl;
    case 'fr':
      return _$fr;
    case 'de':
      return _$de;
    case 'lu':
      return _$lu;
    case 'ru':
      return _$ru;
    default:
      throw new ArgumentError(name);
  }
}

final BuiltSet<Country> _$values = new BuiltSet<Country>(const <Country>[
  _$ad,
  _$ae,
  _$af,
  _$ag,
  _$be,
  _$nl,
  _$fr,
  _$de,
  _$lu,
  _$ru,
]);

Serializer<Country> _$countrySerializer = new _$CountrySerializer();

class _$CountrySerializer implements PrimitiveSerializer<Country> {
  @override
  final Iterable<Type> types = const <Type>[Country];
  @override
  final String wireName = 'Country';

  @override
  Object serialize(Serializers serializers, Country object,
          {FullType specifiedType = FullType.unspecified}) =>
      object.name;

  @override
  Country deserialize(Serializers serializers, Object serialized,
          {FullType specifiedType = FullType.unspecified}) =>
      Country.valueOf(serialized as String);
}

// ignore_for_file: always_put_control_body_on_new_line,always_specify_types,annotate_overrides,avoid_annotating_with_dynamic,avoid_as,avoid_catches_without_on_clauses,avoid_returning_this,deprecated_member_use_from_same_package,lines_longer_than_80_chars,omit_local_variable_types,prefer_expression_function_bodies,sort_constructors_first,test_types_in_equals,unnecessary_const,unnecessary_new
