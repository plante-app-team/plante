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
    value = object.vegetarianStatus;
    if (value != null) {
      result
        ..add('vegetarian_status')
        ..add(serializers.serialize(value,
            specifiedType: const FullType(String)));
    }
    value = object.vegetarianStatusSource;
    if (value != null) {
      result
        ..add('vegetarian_status_source')
        ..add(serializers.serialize(value,
            specifiedType: const FullType(String)));
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
    value = object.moderatorVegetarianChoiceReason;
    if (value != null) {
      result
        ..add('moderator_vegetarian_choice_reason')
        ..add(serializers.serialize(value, specifiedType: const FullType(int)));
    }
    value = object.moderatorVegetarianSourcesText;
    if (value != null) {
      result
        ..add('moderator_vegetarian_sources_text')
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
        case 'vegetarian_status':
          result.vegetarianStatus = serializers.deserialize(value,
              specifiedType: const FullType(String)) as String?;
          break;
        case 'vegetarian_status_source':
          result.vegetarianStatusSource = serializers.deserialize(value,
              specifiedType: const FullType(String)) as String?;
          break;
        case 'vegan_status':
          result.veganStatus = serializers.deserialize(value,
              specifiedType: const FullType(String)) as String?;
          break;
        case 'vegan_status_source':
          result.veganStatusSource = serializers.deserialize(value,
              specifiedType: const FullType(String)) as String?;
          break;
        case 'moderator_vegetarian_choice_reason':
          result.moderatorVegetarianChoiceReason = serializers
              .deserialize(value, specifiedType: const FullType(int)) as int?;
          break;
        case 'moderator_vegetarian_sources_text':
          result.moderatorVegetarianSourcesText = serializers.deserialize(value,
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
  final String? vegetarianStatus;
  @override
  final String? vegetarianStatusSource;
  @override
  final String? veganStatus;
  @override
  final String? veganStatusSource;
  @override
  final int? moderatorVegetarianChoiceReason;
  @override
  final String? moderatorVegetarianSourcesText;
  @override
  final int? moderatorVeganChoiceReason;
  @override
  final String? moderatorVeganSourcesText;

  factory _$BackendProduct([void Function(BackendProductBuilder)? updates]) =>
      (new BackendProductBuilder()..update(updates)).build();

  _$BackendProduct._(
      {this.serverId,
      required this.barcode,
      this.vegetarianStatus,
      this.vegetarianStatusSource,
      this.veganStatus,
      this.veganStatusSource,
      this.moderatorVegetarianChoiceReason,
      this.moderatorVegetarianSourcesText,
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
        vegetarianStatus == other.vegetarianStatus &&
        vegetarianStatusSource == other.vegetarianStatusSource &&
        veganStatus == other.veganStatus &&
        veganStatusSource == other.veganStatusSource &&
        moderatorVegetarianChoiceReason ==
            other.moderatorVegetarianChoiceReason &&
        moderatorVegetarianSourcesText ==
            other.moderatorVegetarianSourcesText &&
        moderatorVeganChoiceReason == other.moderatorVeganChoiceReason &&
        moderatorVeganSourcesText == other.moderatorVeganSourcesText;
  }

  @override
  int get hashCode {
    return $jf($jc(
        $jc(
            $jc(
                $jc(
                    $jc(
                        $jc(
                            $jc(
                                $jc(
                                    $jc($jc(0, serverId.hashCode),
                                        barcode.hashCode),
                                    vegetarianStatus.hashCode),
                                vegetarianStatusSource.hashCode),
                            veganStatus.hashCode),
                        veganStatusSource.hashCode),
                    moderatorVegetarianChoiceReason.hashCode),
                moderatorVegetarianSourcesText.hashCode),
            moderatorVeganChoiceReason.hashCode),
        moderatorVeganSourcesText.hashCode));
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper('BackendProduct')
          ..add('serverId', serverId)
          ..add('barcode', barcode)
          ..add('vegetarianStatus', vegetarianStatus)
          ..add('vegetarianStatusSource', vegetarianStatusSource)
          ..add('veganStatus', veganStatus)
          ..add('veganStatusSource', veganStatusSource)
          ..add('moderatorVegetarianChoiceReason',
              moderatorVegetarianChoiceReason)
          ..add(
              'moderatorVegetarianSourcesText', moderatorVegetarianSourcesText)
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

  String? _vegetarianStatus;
  String? get vegetarianStatus => _$this._vegetarianStatus;
  set vegetarianStatus(String? vegetarianStatus) =>
      _$this._vegetarianStatus = vegetarianStatus;

  String? _vegetarianStatusSource;
  String? get vegetarianStatusSource => _$this._vegetarianStatusSource;
  set vegetarianStatusSource(String? vegetarianStatusSource) =>
      _$this._vegetarianStatusSource = vegetarianStatusSource;

  String? _veganStatus;
  String? get veganStatus => _$this._veganStatus;
  set veganStatus(String? veganStatus) => _$this._veganStatus = veganStatus;

  String? _veganStatusSource;
  String? get veganStatusSource => _$this._veganStatusSource;
  set veganStatusSource(String? veganStatusSource) =>
      _$this._veganStatusSource = veganStatusSource;

  int? _moderatorVegetarianChoiceReason;
  int? get moderatorVegetarianChoiceReason =>
      _$this._moderatorVegetarianChoiceReason;
  set moderatorVegetarianChoiceReason(int? moderatorVegetarianChoiceReason) =>
      _$this._moderatorVegetarianChoiceReason = moderatorVegetarianChoiceReason;

  String? _moderatorVegetarianSourcesText;
  String? get moderatorVegetarianSourcesText =>
      _$this._moderatorVegetarianSourcesText;
  set moderatorVegetarianSourcesText(String? moderatorVegetarianSourcesText) =>
      _$this._moderatorVegetarianSourcesText = moderatorVegetarianSourcesText;

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
      _vegetarianStatus = $v.vegetarianStatus;
      _vegetarianStatusSource = $v.vegetarianStatusSource;
      _veganStatus = $v.veganStatus;
      _veganStatusSource = $v.veganStatusSource;
      _moderatorVegetarianChoiceReason = $v.moderatorVegetarianChoiceReason;
      _moderatorVegetarianSourcesText = $v.moderatorVegetarianSourcesText;
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
            vegetarianStatus: vegetarianStatus,
            vegetarianStatusSource: vegetarianStatusSource,
            veganStatus: veganStatus,
            veganStatusSource: veganStatusSource,
            moderatorVegetarianChoiceReason: moderatorVegetarianChoiceReason,
            moderatorVegetarianSourcesText: moderatorVegetarianSourcesText,
            moderatorVeganChoiceReason: moderatorVeganChoiceReason,
            moderatorVeganSourcesText: moderatorVeganSourcesText);
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: always_put_control_body_on_new_line,always_specify_types,annotate_overrides,avoid_annotating_with_dynamic,avoid_as,avoid_catches_without_on_clauses,avoid_returning_this,deprecated_member_use_from_same_package,lines_longer_than_80_chars,omit_local_variable_types,prefer_expression_function_bodies,sort_constructors_first,test_types_in_equals,unnecessary_const,unnecessary_new
