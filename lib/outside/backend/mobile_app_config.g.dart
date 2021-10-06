// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'mobile_app_config.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

Serializer<MobileAppConfig> _$mobileAppConfigSerializer =
    new _$MobileAppConfigSerializer();

class _$MobileAppConfigSerializer
    implements StructuredSerializer<MobileAppConfig> {
  @override
  final Iterable<Type> types = const [MobileAppConfig, _$MobileAppConfig];
  @override
  final String wireName = 'MobileAppConfig';

  @override
  Iterable<Object?> serialize(Serializers serializers, MobileAppConfig object,
      {FullType specifiedType = FullType.unspecified}) {
    final result = <Object?>[
      'user_data',
      serializers.serialize(object.remoteUserParams,
          specifiedType: const FullType(UserParams)),
      'nominatim_enabled',
      serializers.serialize(object.nominatimEnabled,
          specifiedType: const FullType(bool)),
    ];

    return result;
  }

  @override
  MobileAppConfig deserialize(
      Serializers serializers, Iterable<Object?> serialized,
      {FullType specifiedType = FullType.unspecified}) {
    final result = new MobileAppConfigBuilder();

    final iterator = serialized.iterator;
    while (iterator.moveNext()) {
      final key = iterator.current as String;
      iterator.moveNext();
      final Object? value = iterator.current;
      switch (key) {
        case 'user_data':
          result.remoteUserParams.replace(serializers.deserialize(value,
              specifiedType: const FullType(UserParams))! as UserParams);
          break;
        case 'nominatim_enabled':
          result.nominatimEnabled = serializers.deserialize(value,
              specifiedType: const FullType(bool)) as bool;
          break;
      }
    }

    return result.build();
  }
}

class _$MobileAppConfig extends MobileAppConfig {
  @override
  final UserParams remoteUserParams;
  @override
  final bool nominatimEnabled;

  factory _$MobileAppConfig([void Function(MobileAppConfigBuilder)? updates]) =>
      (new MobileAppConfigBuilder()..update(updates)).build();

  _$MobileAppConfig._(
      {required this.remoteUserParams, required this.nominatimEnabled})
      : super._() {
    BuiltValueNullFieldError.checkNotNull(
        remoteUserParams, 'MobileAppConfig', 'remoteUserParams');
    BuiltValueNullFieldError.checkNotNull(
        nominatimEnabled, 'MobileAppConfig', 'nominatimEnabled');
  }

  @override
  MobileAppConfig rebuild(void Function(MobileAppConfigBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  MobileAppConfigBuilder toBuilder() =>
      new MobileAppConfigBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is MobileAppConfig &&
        remoteUserParams == other.remoteUserParams &&
        nominatimEnabled == other.nominatimEnabled;
  }

  @override
  int get hashCode {
    return $jf(
        $jc($jc(0, remoteUserParams.hashCode), nominatimEnabled.hashCode));
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper('MobileAppConfig')
          ..add('remoteUserParams', remoteUserParams)
          ..add('nominatimEnabled', nominatimEnabled))
        .toString();
  }
}

class MobileAppConfigBuilder
    implements Builder<MobileAppConfig, MobileAppConfigBuilder> {
  _$MobileAppConfig? _$v;

  UserParamsBuilder? _remoteUserParams;
  UserParamsBuilder get remoteUserParams =>
      _$this._remoteUserParams ??= new UserParamsBuilder();
  set remoteUserParams(UserParamsBuilder? remoteUserParams) =>
      _$this._remoteUserParams = remoteUserParams;

  bool? _nominatimEnabled;
  bool? get nominatimEnabled => _$this._nominatimEnabled;
  set nominatimEnabled(bool? nominatimEnabled) =>
      _$this._nominatimEnabled = nominatimEnabled;

  MobileAppConfigBuilder();

  MobileAppConfigBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _remoteUserParams = $v.remoteUserParams.toBuilder();
      _nominatimEnabled = $v.nominatimEnabled;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(MobileAppConfig other) {
    ArgumentError.checkNotNull(other, 'other');
    _$v = other as _$MobileAppConfig;
  }

  @override
  void update(void Function(MobileAppConfigBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  _$MobileAppConfig build() {
    _$MobileAppConfig _$result;
    try {
      _$result = _$v ??
          new _$MobileAppConfig._(
              remoteUserParams: remoteUserParams.build(),
              nominatimEnabled: BuiltValueNullFieldError.checkNotNull(
                  nominatimEnabled, 'MobileAppConfig', 'nominatimEnabled'));
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'remoteUserParams';
        remoteUserParams.build();
      } catch (e) {
        throw new BuiltValueNestedFieldError(
            'MobileAppConfig', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: always_put_control_body_on_new_line,always_specify_types,annotate_overrides,avoid_annotating_with_dynamic,avoid_as,avoid_catches_without_on_clauses,avoid_returning_this,deprecated_member_use_from_same_package,lines_longer_than_80_chars,omit_local_variable_types,prefer_expression_function_bodies,sort_constructors_first,test_types_in_equals,unnecessary_const,unnecessary_new
