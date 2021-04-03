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

// ignore_for_file: always_put_control_body_on_new_line,always_specify_types,annotate_overrides,avoid_annotating_with_dynamic,avoid_as,avoid_catches_without_on_clauses,avoid_returning_this,lines_longer_than_80_chars,omit_local_variable_types,prefer_expression_function_bodies,sort_constructors_first,test_types_in_equals,unnecessary_const,unnecessary_new
