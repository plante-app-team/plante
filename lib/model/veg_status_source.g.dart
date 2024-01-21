// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'veg_status_source.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const VegStatusSource _$open_food_facts =
    const VegStatusSource._('open_food_facts');
const VegStatusSource _$community = const VegStatusSource._('community');
const VegStatusSource _$moderator = const VegStatusSource._('moderator');
const VegStatusSource _$unknown = const VegStatusSource._('unknown');

VegStatusSource _$valueOf(String name) {
  switch (name) {
    case 'open_food_facts':
      return _$open_food_facts;
    case 'community':
      return _$community;
    case 'moderator':
      return _$moderator;
    case 'unknown':
      return _$unknown;
    default:
      throw new ArgumentError(name);
  }
}

final BuiltSet<VegStatusSource> _$values =
    new BuiltSet<VegStatusSource>(const <VegStatusSource>[
  _$open_food_facts,
  _$community,
  _$moderator,
  _$unknown,
]);

Serializer<VegStatusSource> _$vegStatusSourceSerializer =
    new _$VegStatusSourceSerializer();

class _$VegStatusSourceSerializer
    implements PrimitiveSerializer<VegStatusSource> {
  @override
  final Iterable<Type> types = const <Type>[VegStatusSource];
  @override
  final String wireName = 'VegStatusSource';

  @override
  Object serialize(Serializers serializers, VegStatusSource object,
          {FullType specifiedType = FullType.unspecified}) =>
      object.name;

  @override
  VegStatusSource deserialize(Serializers serializers, Object serialized,
          {FullType specifiedType = FullType.unspecified}) =>
      VegStatusSource.valueOf(serialized as String);
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
