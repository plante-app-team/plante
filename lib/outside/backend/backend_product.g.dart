// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'backend_product.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

Serializer<BackendProduct> _$backendProductSerializer =
    new _$BackendProductSerializer();

class _$BackendProductSerializer
    implements StructuredSerializer<BackendProduct> {
  @override
  final Iterable<Type> types = const [BackendProduct, _$BackendProduct];
  @override
  final String wireName = 'BackendProduct';

  @override
  Iterable<Object?> serialize(Serializers serializers, BackendProduct object,
      {FullType specifiedType = FullType.unspecified}) {
    final result = <Object?>[
      'barcode',
      serializers.serialize(object.barcode,
          specifiedType: const FullType(String)),
    ];
    Object? value;
    value = object.serverId;
    if (value != null) {
      result
        ..add('server_id')
        ..add(serializers.serialize(value, specifiedType: const FullType(int)));
    }
    value = object.veganStatus;
    if (value != null) {
      result
        ..add('vegan_status')
        ..add(serializers.serialize(value,
            specifiedType: const FullType(String)));
    }
    value = object.veganStatusSource;
    if (value != null) {
      result
        ..add('vegan_status_source')
        ..add(serializers.serialize(value,
            specifiedType: const FullType(String)));
    }
    value = object.moderatorVeganChoiceReason;
    if (value != null) {
      result
        ..add('moderator_vegan_choice_reason')
        ..add(serializers.serialize(value, specifiedType: const FullType(int)));
    }
    value = object.moderatorVeganSourcesText;
    if (value != null) {
      result
        ..add('moderator_vegan_sources_text')
        ..add(serializers.serialize(value,
            specifiedType: const FullType(String)));
    }
    return result;
  }

  @override
  BackendProduct deserialize(
      Serializers serializers, Iterable<Object?> serialized,
      {FullType specifiedType = FullType.unspecified}) {
    final result = new BackendProductBuilder();

    final iterator = serialized.iterator;
    while (iterator.moveNext()) {
      final key = iterator.current as String;
      iterator.moveNext();
      final Object? value = iterator.current;
      switch (key) {
        case 'server_id':
          result.serverId = serializers.deserialize(value,
              specifiedType: const FullType(int)) as int?;
          break;
        case 'barcode':
          result.barcode = serializers.deserialize(value,
              specifiedType: const FullType(String)) as String;
          break;
        case 'vegan_status':
          result.veganStatus = serializers.deserialize(value,
              specifiedType: const FullType(String)) as String?;
          break;
        case 'vegan_status_source':
          result.veganStatusSource = serializers.deserialize(value,
              specifiedType: const FullType(String)) as String?;
          break;
        case 'moderator_vegan_choice_reason':
          result.moderatorVeganChoiceReason = serializers.deserialize(value,
              specifiedType: const FullType(int)) as int?;
          break;
        case 'moderator_vegan_sources_text':
          result.moderatorVeganSourcesText = serializers.deserialize(value,
              specifiedType: const FullType(String)) as String?;
          break;
      }
    }

    return result.build();
  }
}

class _$BackendProduct extends BackendProduct {
  @override
  final int? serverId;
  @override
  final String barcode;
  @override
  final String? veganStatus;
  @override
  final String? veganStatusSource;
  @override
  final int? moderatorVeganChoiceReason;
  @override
  final String? moderatorVeganSourcesText;

  factory _$BackendProduct([void Function(BackendProductBuilder)? updates]) =>
      (new BackendProductBuilder()..update(updates)).build();

  _$BackendProduct._(
      {this.serverId,
      required this.barcode,
      this.veganStatus,
      this.veganStatusSource,
      this.moderatorVeganChoiceReason,
      this.moderatorVeganSourcesText})
      : super._() {
    BuiltValueNullFieldError.checkNotNull(barcode, 'BackendProduct', 'barcode');
  }

  @override
  BackendProduct rebuild(void Function(BackendProductBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  BackendProductBuilder toBuilder() =>
      new BackendProductBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is BackendProduct &&
        serverId == other.serverId &&
        barcode == other.barcode &&
        veganStatus == other.veganStatus &&
        veganStatusSource == other.veganStatusSource &&
        moderatorVeganChoiceReason == other.moderatorVeganChoiceReason &&
        moderatorVeganSourcesText == other.moderatorVeganSourcesText;
  }

  @override
  int get hashCode {
    return $jf($jc(
        $jc(
            $jc(
                $jc($jc($jc(0, serverId.hashCode), barcode.hashCode),
                    veganStatus.hashCode),
                veganStatusSource.hashCode),
            moderatorVeganChoiceReason.hashCode),
        moderatorVeganSourcesText.hashCode));
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper('BackendProduct')
          ..add('serverId', serverId)
          ..add('barcode', barcode)
          ..add('veganStatus', veganStatus)
          ..add('veganStatusSource', veganStatusSource)
          ..add('moderatorVeganChoiceReason', moderatorVeganChoiceReason)
          ..add('moderatorVeganSourcesText', moderatorVeganSourcesText))
        .toString();
  }
}

class BackendProductBuilder
    implements Builder<BackendProduct, BackendProductBuilder> {
  _$BackendProduct? _$v;

  int? _serverId;
  int? get serverId => _$this._serverId;
  set serverId(int? serverId) => _$this._serverId = serverId;

  String? _barcode;
  String? get barcode => _$this._barcode;
  set barcode(String? barcode) => _$this._barcode = barcode;

  String? _veganStatus;
  String? get veganStatus => _$this._veganStatus;
  set veganStatus(String? veganStatus) => _$this._veganStatus = veganStatus;

  String? _veganStatusSource;
  String? get veganStatusSource => _$this._veganStatusSource;
  set veganStatusSource(String? veganStatusSource) =>
      _$this._veganStatusSource = veganStatusSource;

  int? _moderatorVeganChoiceReason;
  int? get moderatorVeganChoiceReason => _$this._moderatorVeganChoiceReason;
  set moderatorVeganChoiceReason(int? moderatorVeganChoiceReason) =>
      _$this._moderatorVeganChoiceReason = moderatorVeganChoiceReason;

  String? _moderatorVeganSourcesText;
  String? get moderatorVeganSourcesText => _$this._moderatorVeganSourcesText;
  set moderatorVeganSourcesText(String? moderatorVeganSourcesText) =>
      _$this._moderatorVeganSourcesText = moderatorVeganSourcesText;

  BackendProductBuilder();

  BackendProductBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _serverId = $v.serverId;
      _barcode = $v.barcode;
      _veganStatus = $v.veganStatus;
      _veganStatusSource = $v.veganStatusSource;
      _moderatorVeganChoiceReason = $v.moderatorVeganChoiceReason;
      _moderatorVeganSourcesText = $v.moderatorVeganSourcesText;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(BackendProduct other) {
    ArgumentError.checkNotNull(other, 'other');
    _$v = other as _$BackendProduct;
  }

  @override
  void update(void Function(BackendProductBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  _$BackendProduct build() {
    final _$result = _$v ??
        new _$BackendProduct._(
            serverId: serverId,
            barcode: BuiltValueNullFieldError.checkNotNull(
                barcode, 'BackendProduct', 'barcode'),
            veganStatus: veganStatus,
            veganStatusSource: veganStatusSource,
            moderatorVeganChoiceReason: moderatorVeganChoiceReason,
            moderatorVeganSourcesText: moderatorVeganSourcesText);
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: always_put_control_body_on_new_line,always_specify_types,annotate_overrides,avoid_annotating_with_dynamic,avoid_as,avoid_catches_without_on_clauses,avoid_returning_this,deprecated_member_use_from_same_package,lines_longer_than_80_chars,omit_local_variable_types,prefer_expression_function_bodies,sort_constructors_first,test_types_in_equals,unnecessary_const,unnecessary_new
