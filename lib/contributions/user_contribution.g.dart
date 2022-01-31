// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_contribution.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

Serializer<UserContribution> _$userContributionSerializer =
    new _$UserContributionSerializer();

class _$UserContributionSerializer
    implements StructuredSerializer<UserContribution> {
  @override
  final Iterable<Type> types = const [UserContribution, _$UserContribution];
  @override
  final String wireName = 'UserContribution';

  @override
  Iterable<Object?> serialize(Serializers serializers, UserContribution object,
      {FullType specifiedType = FullType.unspecified}) {
    final result = <Object?>[
      'time_utc',
      serializers.serialize(object.timeSecsUtc,
          specifiedType: const FullType(int)),
      'type',
      serializers.serialize(object.typeCode,
          specifiedType: const FullType(int)),
    ];
    Object? value;
    value = object.barcode;
    if (value != null) {
      result
        ..add('barcode')
        ..add(serializers.serialize(value,
            specifiedType: const FullType(String)));
    }
    value = object.osmUID;
    if (value != null) {
      result
        ..add('shop_uid')
        ..add(serializers.serialize(value,
            specifiedType: const FullType(OsmUID)));
    }
    return result;
  }

  @override
  UserContribution deserialize(
      Serializers serializers, Iterable<Object?> serialized,
      {FullType specifiedType = FullType.unspecified}) {
    final result = new UserContributionBuilder();

    final iterator = serialized.iterator;
    while (iterator.moveNext()) {
      final key = iterator.current as String;
      iterator.moveNext();
      final Object? value = iterator.current;
      switch (key) {
        case 'time_utc':
          result.timeSecsUtc = serializers.deserialize(value,
              specifiedType: const FullType(int)) as int;
          break;
        case 'type':
          result.typeCode = serializers.deserialize(value,
              specifiedType: const FullType(int)) as int;
          break;
        case 'barcode':
          result.barcode = serializers.deserialize(value,
              specifiedType: const FullType(String)) as String?;
          break;
        case 'shop_uid':
          result.osmUID = serializers.deserialize(value,
              specifiedType: const FullType(OsmUID)) as OsmUID?;
          break;
      }
    }

    return result.build();
  }
}

class _$UserContribution extends UserContribution {
  @override
  final int timeSecsUtc;
  @override
  final int typeCode;
  @override
  final String? barcode;
  @override
  final OsmUID? osmUID;

  factory _$UserContribution(
          [void Function(UserContributionBuilder)? updates]) =>
      (new UserContributionBuilder()..update(updates)).build();

  _$UserContribution._(
      {required this.timeSecsUtc,
      required this.typeCode,
      this.barcode,
      this.osmUID})
      : super._() {
    BuiltValueNullFieldError.checkNotNull(
        timeSecsUtc, 'UserContribution', 'timeSecsUtc');
    BuiltValueNullFieldError.checkNotNull(
        typeCode, 'UserContribution', 'typeCode');
  }

  @override
  UserContribution rebuild(void Function(UserContributionBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  UserContributionBuilder toBuilder() =>
      new UserContributionBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is UserContribution &&
        timeSecsUtc == other.timeSecsUtc &&
        typeCode == other.typeCode &&
        barcode == other.barcode &&
        osmUID == other.osmUID;
  }

  @override
  int get hashCode {
    return $jf($jc(
        $jc($jc($jc(0, timeSecsUtc.hashCode), typeCode.hashCode),
            barcode.hashCode),
        osmUID.hashCode));
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper('UserContribution')
          ..add('timeSecsUtc', timeSecsUtc)
          ..add('typeCode', typeCode)
          ..add('barcode', barcode)
          ..add('osmUID', osmUID))
        .toString();
  }
}

class UserContributionBuilder
    implements Builder<UserContribution, UserContributionBuilder> {
  _$UserContribution? _$v;

  int? _timeSecsUtc;
  int? get timeSecsUtc => _$this._timeSecsUtc;
  set timeSecsUtc(int? timeSecsUtc) => _$this._timeSecsUtc = timeSecsUtc;

  int? _typeCode;
  int? get typeCode => _$this._typeCode;
  set typeCode(int? typeCode) => _$this._typeCode = typeCode;

  String? _barcode;
  String? get barcode => _$this._barcode;
  set barcode(String? barcode) => _$this._barcode = barcode;

  OsmUID? _osmUID;
  OsmUID? get osmUID => _$this._osmUID;
  set osmUID(OsmUID? osmUID) => _$this._osmUID = osmUID;

  UserContributionBuilder();

  UserContributionBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _timeSecsUtc = $v.timeSecsUtc;
      _typeCode = $v.typeCode;
      _barcode = $v.barcode;
      _osmUID = $v.osmUID;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(UserContribution other) {
    ArgumentError.checkNotNull(other, 'other');
    _$v = other as _$UserContribution;
  }

  @override
  void update(void Function(UserContributionBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  _$UserContribution build() {
    final _$result = _$v ??
        new _$UserContribution._(
            timeSecsUtc: BuiltValueNullFieldError.checkNotNull(
                timeSecsUtc, 'UserContribution', 'timeSecsUtc'),
            typeCode: BuiltValueNullFieldError.checkNotNull(
                typeCode, 'UserContribution', 'typeCode'),
            barcode: barcode,
            osmUID: osmUID);
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: always_put_control_body_on_new_line,always_specify_types,annotate_overrides,avoid_annotating_with_dynamic,avoid_as,avoid_catches_without_on_clauses,avoid_returning_this,deprecated_member_use_from_same_package,lines_longer_than_80_chars,omit_local_variable_types,prefer_expression_function_bodies,sort_constructors_first,test_types_in_equals,unnecessary_const,unnecessary_new
