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
    final result = <Object?>[];
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
    value = object.genderStr;
    if (value != null) {
      result
        ..add('gender')
        ..add(serializers.serialize(value,
            specifiedType: const FullType(String)));
    }
    value = object.birthdayStr;
    if (value != null) {
      result
        ..add('birthday')
        ..add(serializers.serialize(value,
            specifiedType: const FullType(String)));
    }
    value = object.eatsMilk;
    if (value != null) {
      result
        ..add('eats_milk')
        ..add(
            serializers.serialize(value, specifiedType: const FullType(bool)));
    }
    value = object.eatsEggs;
    if (value != null) {
      result
        ..add('eats_eggs')
        ..add(
            serializers.serialize(value, specifiedType: const FullType(bool)));
    }
    value = object.eatsHoney;
    if (value != null) {
      result
        ..add('eats_honey')
        ..add(
            serializers.serialize(value, specifiedType: const FullType(bool)));
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
              specifiedType: const FullType(String)) as String;
          break;
        case 'client_token':
          result.backendClientToken = serializers.deserialize(value,
              specifiedType: const FullType(String)) as String;
          break;
        case 'name':
          result.name = serializers.deserialize(value,
              specifiedType: const FullType(String)) as String;
          break;
        case 'gender':
          result.genderStr = serializers.deserialize(value,
              specifiedType: const FullType(String)) as String;
          break;
        case 'birthday':
          result.birthdayStr = serializers.deserialize(value,
              specifiedType: const FullType(String)) as String;
          break;
        case 'eats_milk':
          result.eatsMilk = serializers.deserialize(value,
              specifiedType: const FullType(bool)) as bool;
          break;
        case 'eats_eggs':
          result.eatsEggs = serializers.deserialize(value,
              specifiedType: const FullType(bool)) as bool;
          break;
        case 'eats_honey':
          result.eatsHoney = serializers.deserialize(value,
              specifiedType: const FullType(bool)) as bool;
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
  final String? genderStr;
  @override
  final String? birthdayStr;
  @override
  final bool? eatsMilk;
  @override
  final bool? eatsEggs;
  @override
  final bool? eatsHoney;

  factory _$UserParams([void Function(UserParamsBuilder)? updates]) =>
      (new UserParamsBuilder()..update(updates)).build();

  _$UserParams._(
      {this.backendId,
      this.backendClientToken,
      this.name,
      this.genderStr,
      this.birthdayStr,
      this.eatsMilk,
      this.eatsEggs,
      this.eatsHoney})
      : super._();

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
        genderStr == other.genderStr &&
        birthdayStr == other.birthdayStr &&
        eatsMilk == other.eatsMilk &&
        eatsEggs == other.eatsEggs &&
        eatsHoney == other.eatsHoney;
  }

  @override
  int get hashCode {
    return $jf($jc(
        $jc(
            $jc(
                $jc(
                    $jc(
                        $jc(
                            $jc($jc(0, backendId.hashCode),
                                backendClientToken.hashCode),
                            name.hashCode),
                        genderStr.hashCode),
                    birthdayStr.hashCode),
                eatsMilk.hashCode),
            eatsEggs.hashCode),
        eatsHoney.hashCode));
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper('UserParams')
          ..add('backendId', backendId)
          ..add('backendClientToken', backendClientToken)
          ..add('name', name)
          ..add('genderStr', genderStr)
          ..add('birthdayStr', birthdayStr)
          ..add('eatsMilk', eatsMilk)
          ..add('eatsEggs', eatsEggs)
          ..add('eatsHoney', eatsHoney))
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

  String? _genderStr;
  String? get genderStr => _$this._genderStr;
  set genderStr(String? genderStr) => _$this._genderStr = genderStr;

  String? _birthdayStr;
  String? get birthdayStr => _$this._birthdayStr;
  set birthdayStr(String? birthdayStr) => _$this._birthdayStr = birthdayStr;

  bool? _eatsMilk;
  bool? get eatsMilk => _$this._eatsMilk;
  set eatsMilk(bool? eatsMilk) => _$this._eatsMilk = eatsMilk;

  bool? _eatsEggs;
  bool? get eatsEggs => _$this._eatsEggs;
  set eatsEggs(bool? eatsEggs) => _$this._eatsEggs = eatsEggs;

  bool? _eatsHoney;
  bool? get eatsHoney => _$this._eatsHoney;
  set eatsHoney(bool? eatsHoney) => _$this._eatsHoney = eatsHoney;

  UserParamsBuilder();

  UserParamsBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _backendId = $v.backendId;
      _backendClientToken = $v.backendClientToken;
      _name = $v.name;
      _genderStr = $v.genderStr;
      _birthdayStr = $v.birthdayStr;
      _eatsMilk = $v.eatsMilk;
      _eatsEggs = $v.eatsEggs;
      _eatsHoney = $v.eatsHoney;
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
    final _$result = _$v ??
        new _$UserParams._(
            backendId: backendId,
            backendClientToken: backendClientToken,
            name: name,
            genderStr: genderStr,
            birthdayStr: birthdayStr,
            eatsMilk: eatsMilk,
            eatsEggs: eatsEggs,
            eatsHoney: eatsHoney);
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: always_put_control_body_on_new_line,always_specify_types,annotate_overrides,avoid_annotating_with_dynamic,avoid_as,avoid_catches_without_on_clauses,avoid_returning_this,lines_longer_than_80_chars,omit_local_variable_types,prefer_expression_function_bodies,sort_constructors_first,test_types_in_equals,unnecessary_const,unnecessary_new
