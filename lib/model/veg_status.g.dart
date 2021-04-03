// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'veg_status.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const VegStatus _$positive = const VegStatus._('positive');
const VegStatus _$negative = const VegStatus._('negative');
const VegStatus _$possible = const VegStatus._('possible');
const VegStatus _$unknown = const VegStatus._('unknown');

VegStatus _$valueOf(String name) {
  switch (name) {
    case 'positive':
      return _$positive;
    case 'negative':
      return _$negative;
    case 'possible':
      return _$possible;
    case 'unknown':
      return _$unknown;
    default:
      throw new ArgumentError(name);
  }
}

final BuiltSet<VegStatus> _$values = new BuiltSet<VegStatus>(const <VegStatus>[
  _$positive,
  _$negative,
  _$possible,
  _$unknown,
]);

Serializer<VegStatus> _$vegStatusSerializer = new _$VegStatusSerializer();

class _$VegStatusSerializer implements PrimitiveSerializer<VegStatus> {
  @override
  final Iterable<Type> types = const <Type>[VegStatus];
  @override
  final String wireName = 'VegStatus';

  @override
  Object serialize(Serializers serializers, VegStatus object,
          {FullType specifiedType = FullType.unspecified}) =>
      object.name;

  @override
  VegStatus deserialize(Serializers serializers, Object serialized,
          {FullType specifiedType = FullType.unspecified}) =>
      VegStatus.valueOf(serialized as String);
}

// ignore_for_file: always_put_control_body_on_new_line,always_specify_types,annotate_overrides,avoid_annotating_with_dynamic,avoid_as,avoid_catches_without_on_clauses,avoid_returning_this,lines_longer_than_80_chars,omit_local_variable_types,prefer_expression_function_bodies,sort_constructors_first,test_types_in_equals,unnecessary_const,unnecessary_new
