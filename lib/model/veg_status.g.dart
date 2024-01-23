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

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
