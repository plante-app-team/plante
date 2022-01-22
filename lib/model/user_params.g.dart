// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_params.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

Serializer<UserParams> _$userParamsSerializer = new _$UserParamsSerializer();

class _$UserParamsSerializer implements StructuredSerializer<UserParams> {
  @override
  final Iterable<Type> types = const [UserParams, _$UserParams];
  @override
  final String wireName = 'UserParams';

  @override
  Iterable<Object?> serialize(Serializers serializers, UserParams object,
      {FullType specifiedType = FullType.unspecified}) {
    final result = <Object?>[
      'has_avatar',
      serializers.serialize(object.hasAvatar,
          specifiedType: const FullType(bool)),
    ];
    Object? value;
    value = object.backendId;
    if (value != null) {
      result
        ..add('user_id')
        ..add(serializers.serialize(value,
            specifiedType: const FullType(String)));
    }
    value = object.backendClientToken;
    if (value != null) {
      result
        ..add('client_token')
        ..add(serializers.serialize(value,
            specifiedType: const FullType(String)));
    }
    value = object.name;
    if (value != null) {
      result
        ..add('name')
        ..add(serializers.serialize(value,
            specifiedType: const FullType(String)));
    }
    value = object.userGroup;
    if (value != null) {
      result
        ..add('rights_group')
        ..add(serializers.serialize(value, specifiedType: const FullType(int)));
    }
    value = object.langsPrioritized;
    if (value != null) {
      result
        ..add('langs_prioritized')
        ..add(serializers.serialize(value,
            specifiedType:
                const FullType(BuiltList, const [const FullType(String)])));
    }
    return result;
  }

  @override
  UserParams deserialize(Serializers serializers, Iterable<Object?> serialized,
      {FullType specifiedType = FullType.unspecified}) {
    final result = new UserParamsBuilder();

    final iterator = serialized.iterator;
    while (iterator.moveNext()) {
      final key = iterator.current as String;
      iterator.moveNext();
      final Object? value = iterator.current;
      switch (key) {
        case 'user_id':
          result.backendId = serializers.deserialize(value,
              specifiedType: const FullType(String)) as String?;
          break;
        case 'client_token':
          result.backendClientToken = serializers.deserialize(value,
              specifiedType: const FullType(String)) as String?;
          break;
        case 'name':
          result.name = serializers.deserialize(value,
              specifiedType: const FullType(String)) as String?;
          break;
        case 'has_avatar':
          result.hasAvatar = serializers.deserialize(value,
              specifiedType: const FullType(bool)) as bool;
          break;
        case 'rights_group':
          result.userGroup = serializers.deserialize(value,
              specifiedType: const FullType(int)) as int?;
          break;
        case 'langs_prioritized':
          result.langsPrioritized.replace(serializers.deserialize(value,
                  specifiedType: const FullType(
                      BuiltList, const [const FullType(String)]))!
              as BuiltList<Object?>);
          break;
      }
    }

    return result.build();
  }
}

class _$UserParams extends UserParams {
  @override
  final String? backendId;
  @override
  final String? backendClientToken;
  @override
  final String? name;
  @override
  final bool hasAvatar;
  @override
  final int? userGroup;
  @override
  final BuiltList<String>? langsPrioritized;

  factory _$UserParams([void Function(UserParamsBuilder)? updates]) =>
      (new UserParamsBuilder()..update(updates)).build();

  _$UserParams._(
      {this.backendId,
      this.backendClientToken,
      this.name,
      required this.hasAvatar,
      this.userGroup,
      this.langsPrioritized})
      : super._() {
    BuiltValueNullFieldError.checkNotNull(hasAvatar, 'UserParams', 'hasAvatar');
  }

  @override
  UserParams rebuild(void Function(UserParamsBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  UserParamsBuilder toBuilder() => new UserParamsBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is UserParams &&
        backendId == other.backendId &&
        backendClientToken == other.backendClientToken &&
        name == other.name &&
        hasAvatar == other.hasAvatar &&
        userGroup == other.userGroup &&
        langsPrioritized == other.langsPrioritized;
  }

  @override
  int get hashCode {
    return $jf($jc(
        $jc(
            $jc(
                $jc(
                    $jc($jc(0, backendId.hashCode),
                        backendClientToken.hashCode),
                    name.hashCode),
                hasAvatar.hashCode),
            userGroup.hashCode),
        langsPrioritized.hashCode));
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper('UserParams')
          ..add('backendId', backendId)
          ..add('backendClientToken', backendClientToken)
          ..add('name', name)
          ..add('hasAvatar', hasAvatar)
          ..add('userGroup', userGroup)
          ..add('langsPrioritized', langsPrioritized))
        .toString();
  }
}

class UserParamsBuilder implements Builder<UserParams, UserParamsBuilder> {
  _$UserParams? _$v;

  String? _backendId;
  String? get backendId => _$this._backendId;
  set backendId(String? backendId) => _$this._backendId = backendId;

  String? _backendClientToken;
  String? get backendClientToken => _$this._backendClientToken;
  set backendClientToken(String? backendClientToken) =>
      _$this._backendClientToken = backendClientToken;

  String? _name;
  String? get name => _$this._name;
  set name(String? name) => _$this._name = name;

  bool? _hasAvatar;
  bool? get hasAvatar => _$this._hasAvatar;
  set hasAvatar(bool? hasAvatar) => _$this._hasAvatar = hasAvatar;

  int? _userGroup;
  int? get userGroup => _$this._userGroup;
  set userGroup(int? userGroup) => _$this._userGroup = userGroup;

  ListBuilder<String>? _langsPrioritized;
  ListBuilder<String> get langsPrioritized =>
      _$this._langsPrioritized ??= new ListBuilder<String>();
  set langsPrioritized(ListBuilder<String>? langsPrioritized) =>
      _$this._langsPrioritized = langsPrioritized;

  UserParamsBuilder() {
    UserParams._setDefaults(this);
  }

  UserParamsBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _backendId = $v.backendId;
      _backendClientToken = $v.backendClientToken;
      _name = $v.name;
      _hasAvatar = $v.hasAvatar;
      _userGroup = $v.userGroup;
      _langsPrioritized = $v.langsPrioritized?.toBuilder();
      _$v = null;
    }
    return this;
  }

  @override
  void replace(UserParams other) {
    ArgumentError.checkNotNull(other, 'other');
    _$v = other as _$UserParams;
  }

  @override
  void update(void Function(UserParamsBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  _$UserParams build() {
    _$UserParams _$result;
    try {
      _$result = _$v ??
          new _$UserParams._(
              backendId: backendId,
              backendClientToken: backendClientToken,
              name: name,
              hasAvatar: BuiltValueNullFieldError.checkNotNull(
                  hasAvatar, 'UserParams', 'hasAvatar'),
              userGroup: userGroup,
              langsPrioritized: _langsPrioritized?.build());
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'langsPrioritized';
        _langsPrioritized?.build();
      } catch (e) {
        throw new BuiltValueNestedFieldError(
            'UserParams', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: always_put_control_body_on_new_line,always_specify_types,annotate_overrides,avoid_annotating_with_dynamic,avoid_as,avoid_catches_without_on_clauses,avoid_returning_this,deprecated_member_use_from_same_package,lines_longer_than_80_chars,omit_local_variable_types,prefer_expression_function_bodies,sort_constructors_first,test_types_in_equals,unnecessary_const,unnecessary_new
