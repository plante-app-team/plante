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
      'likes_count',
      serializers.serialize(object.likesCount,
          specifiedType: const FullType(int)),
      'liked_by_me',
      serializers.serialize(object.likedByMe,
          specifiedType: const FullType(bool)),
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
    value = object.moderatorVeganChoiceReasons;
    if (value != null) {
      result
        ..add('moderator_vegan_choice_reasons')
        ..add(serializers.serialize(value,
            specifiedType: const FullType(String)));
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
      final key = iterator.current! as String;
      iterator.moveNext();
      final Object? value = iterator.current;
      switch (key) {
        case 'server_id':
          result.serverId = serializers.deserialize(value,
              specifiedType: const FullType(int)) as int?;
          break;
        case 'barcode':
          result.barcode = serializers.deserialize(value,
              specifiedType: const FullType(String))! as String;
          break;
        case 'vegan_status':
          result.veganStatus = serializers.deserialize(value,
              specifiedType: const FullType(String)) as String?;
          break;
        case 'vegan_status_source':
          result.veganStatusSource = serializers.deserialize(value,
              specifiedType: const FullType(String)) as String?;
          break;
        case 'moderator_vegan_choice_reasons':
          result.moderatorVeganChoiceReasons = serializers.deserialize(value,
              specifiedType: const FullType(String)) as String?;
          break;
        case 'moderator_vegan_sources_text':
          result.moderatorVeganSourcesText = serializers.deserialize(value,
              specifiedType: const FullType(String)) as String?;
          break;
        case 'likes_count':
          result.likesCount = serializers.deserialize(value,
              specifiedType: const FullType(int))! as int;
          break;
        case 'liked_by_me':
          result.likedByMe = serializers.deserialize(value,
              specifiedType: const FullType(bool))! as bool;
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
  final String? moderatorVeganChoiceReasons;
  @override
  final String? moderatorVeganSourcesText;
  @override
  final int likesCount;
  @override
  final bool likedByMe;

  factory _$BackendProduct([void Function(BackendProductBuilder)? updates]) =>
      (new BackendProductBuilder()..update(updates))._build();

  _$BackendProduct._(
      {this.serverId,
      required this.barcode,
      this.veganStatus,
      this.veganStatusSource,
      this.moderatorVeganChoiceReasons,
      this.moderatorVeganSourcesText,
      required this.likesCount,
      required this.likedByMe})
      : super._() {
    BuiltValueNullFieldError.checkNotNull(
        barcode, r'BackendProduct', 'barcode');
    BuiltValueNullFieldError.checkNotNull(
        likesCount, r'BackendProduct', 'likesCount');
    BuiltValueNullFieldError.checkNotNull(
        likedByMe, r'BackendProduct', 'likedByMe');
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
        moderatorVeganChoiceReasons == other.moderatorVeganChoiceReasons &&
        moderatorVeganSourcesText == other.moderatorVeganSourcesText &&
        likesCount == other.likesCount &&
        likedByMe == other.likedByMe;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, serverId.hashCode);
    _$hash = $jc(_$hash, barcode.hashCode);
    _$hash = $jc(_$hash, veganStatus.hashCode);
    _$hash = $jc(_$hash, veganStatusSource.hashCode);
    _$hash = $jc(_$hash, moderatorVeganChoiceReasons.hashCode);
    _$hash = $jc(_$hash, moderatorVeganSourcesText.hashCode);
    _$hash = $jc(_$hash, likesCount.hashCode);
    _$hash = $jc(_$hash, likedByMe.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'BackendProduct')
          ..add('serverId', serverId)
          ..add('barcode', barcode)
          ..add('veganStatus', veganStatus)
          ..add('veganStatusSource', veganStatusSource)
          ..add('moderatorVeganChoiceReasons', moderatorVeganChoiceReasons)
          ..add('moderatorVeganSourcesText', moderatorVeganSourcesText)
          ..add('likesCount', likesCount)
          ..add('likedByMe', likedByMe))
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

  String? _moderatorVeganChoiceReasons;
  String? get moderatorVeganChoiceReasons =>
      _$this._moderatorVeganChoiceReasons;
  set moderatorVeganChoiceReasons(String? moderatorVeganChoiceReasons) =>
      _$this._moderatorVeganChoiceReasons = moderatorVeganChoiceReasons;

  String? _moderatorVeganSourcesText;
  String? get moderatorVeganSourcesText => _$this._moderatorVeganSourcesText;
  set moderatorVeganSourcesText(String? moderatorVeganSourcesText) =>
      _$this._moderatorVeganSourcesText = moderatorVeganSourcesText;

  int? _likesCount;
  int? get likesCount => _$this._likesCount;
  set likesCount(int? likesCount) => _$this._likesCount = likesCount;

  bool? _likedByMe;
  bool? get likedByMe => _$this._likedByMe;
  set likedByMe(bool? likedByMe) => _$this._likedByMe = likedByMe;

  BackendProductBuilder();

  BackendProductBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _serverId = $v.serverId;
      _barcode = $v.barcode;
      _veganStatus = $v.veganStatus;
      _veganStatusSource = $v.veganStatusSource;
      _moderatorVeganChoiceReasons = $v.moderatorVeganChoiceReasons;
      _moderatorVeganSourcesText = $v.moderatorVeganSourcesText;
      _likesCount = $v.likesCount;
      _likedByMe = $v.likedByMe;
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
  BackendProduct build() => _build();

  _$BackendProduct _build() {
    BackendProduct._defaults(this);
    final _$result = _$v ??
        new _$BackendProduct._(
            serverId: serverId,
            barcode: BuiltValueNullFieldError.checkNotNull(
                barcode, r'BackendProduct', 'barcode'),
            veganStatus: veganStatus,
            veganStatusSource: veganStatusSource,
            moderatorVeganChoiceReasons: moderatorVeganChoiceReasons,
            moderatorVeganSourcesText: moderatorVeganSourcesText,
            likesCount: BuiltValueNullFieldError.checkNotNull(
                likesCount, r'BackendProduct', 'likesCount'),
            likedByMe: BuiltValueNullFieldError.checkNotNull(
                likedByMe, r'BackendProduct', 'likedByMe'));
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
