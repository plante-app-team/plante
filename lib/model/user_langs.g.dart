// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_langs.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

Serializer<UserLangs> _$userLangsSerializer = new _$UserLangsSerializer();

class _$UserLangsSerializer implements StructuredSerializer<UserLangs> {
  @override
  final Iterable<Type> types = const [UserLangs, _$UserLangs];
  @override
  final String wireName = 'UserLangs';

  @override
  Iterable<Object?> serialize(Serializers serializers, UserLangs object,
      {FullType specifiedType = FullType.unspecified}) {
    final result = <Object?>[
      'codes',
      serializers.serialize(object.codes,
          specifiedType:
              const FullType(BuiltList, const [const FullType(LangCode)])),
      'auto',
      serializers.serialize(object.auto, specifiedType: const FullType(bool)),
    ];

    return result;
  }

  @override
  UserLangs deserialize(Serializers serializers, Iterable<Object?> serialized,
      {FullType specifiedType = FullType.unspecified}) {
    final result = new UserLangsBuilder();

    final iterator = serialized.iterator;
    while (iterator.moveNext()) {
      final key = iterator.current as String;
      iterator.moveNext();
      final Object? value = iterator.current;
      switch (key) {
        case 'codes':
          result.codes.replace(serializers.deserialize(value,
                  specifiedType: const FullType(
                      BuiltList, const [const FullType(LangCode)]))!
              as BuiltList<Object?>);
          break;
        case 'auto':
          result.auto = serializers.deserialize(value,
              specifiedType: const FullType(bool)) as bool;
          break;
      }
    }

    return result.build();
  }
}

class _$UserLangs extends UserLangs {
  @override
  final BuiltList<LangCode> codes;
  @override
  final bool auto;

  factory _$UserLangs([void Function(UserLangsBuilder)? updates]) =>
      (new UserLangsBuilder()..update(updates)).build();

  _$UserLangs._({required this.codes, required this.auto}) : super._() {
    BuiltValueNullFieldError.checkNotNull(codes, 'UserLangs', 'codes');
    BuiltValueNullFieldError.checkNotNull(auto, 'UserLangs', 'auto');
  }

  @override
  UserLangs rebuild(void Function(UserLangsBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  UserLangsBuilder toBuilder() => new UserLangsBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is UserLangs && codes == other.codes && auto == other.auto;
  }

  @override
  int get hashCode {
    return $jf($jc($jc(0, codes.hashCode), auto.hashCode));
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper('UserLangs')
          ..add('codes', codes)
          ..add('auto', auto))
        .toString();
  }
}

class UserLangsBuilder implements Builder<UserLangs, UserLangsBuilder> {
  _$UserLangs? _$v;

  ListBuilder<LangCode>? _codes;
  ListBuilder<LangCode> get codes =>
      _$this._codes ??= new ListBuilder<LangCode>();
  set codes(ListBuilder<LangCode>? codes) => _$this._codes = codes;

  bool? _auto;
  bool? get auto => _$this._auto;
  set auto(bool? auto) => _$this._auto = auto;

  UserLangsBuilder();

  UserLangsBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _codes = $v.codes.toBuilder();
      _auto = $v.auto;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(UserLangs other) {
    ArgumentError.checkNotNull(other, 'other');
    _$v = other as _$UserLangs;
  }

  @override
  void update(void Function(UserLangsBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  _$UserLangs build() {
    _$UserLangs _$result;
    try {
      _$result = _$v ??
          new _$UserLangs._(
              codes: codes.build(),
              auto: BuiltValueNullFieldError.checkNotNull(
                  auto, 'UserLangs', 'auto'));
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'codes';
        codes.build();
      } catch (e) {
        throw new BuiltValueNestedFieldError(
            'UserLangs', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: always_put_control_body_on_new_line,always_specify_types,annotate_overrides,avoid_annotating_with_dynamic,avoid_as,avoid_catches_without_on_clauses,avoid_returning_this,deprecated_member_use_from_same_package,lines_longer_than_80_chars,omit_local_variable_types,prefer_expression_function_bodies,sort_constructors_first,test_types_in_equals,unnecessary_const,unnecessary_new
