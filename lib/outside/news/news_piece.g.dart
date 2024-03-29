// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'news_piece.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

Serializer<NewsPiece> _$newsPieceSerializer = new _$NewsPieceSerializer();

class _$NewsPieceSerializer implements StructuredSerializer<NewsPiece> {
  @override
  final Iterable<Type> types = const [NewsPiece, _$NewsPiece];
  @override
  final String wireName = 'NewsPiece';

  @override
  Iterable<Object?> serialize(Serializers serializers, NewsPiece object,
      {FullType specifiedType = FullType.unspecified}) {
    final result = <Object?>[
      'id',
      serializers.serialize(object.serverId,
          specifiedType: const FullType(int)),
      'lat',
      serializers.serialize(object.lat, specifiedType: const FullType(double)),
      'lon',
      serializers.serialize(object.lon, specifiedType: const FullType(double)),
      'creator_user_id',
      serializers.serialize(object.creatorUserId,
          specifiedType: const FullType(String)),
      'creator_user_name',
      serializers.serialize(object.creatorUserName,
          specifiedType: const FullType(String)),
      'creation_time',
      serializers.serialize(object.creationTimeSecs,
          specifiedType: const FullType(int)),
      'type',
      serializers.serialize(object.typeCode,
          specifiedType: const FullType(int)),
      'data',
      serializers.serialize(object.data,
          specifiedType: const FullType(BuiltMap,
              const [const FullType(String), const FullType(JsonObject)])),
      'typedData',
      serializers.serialize(object.typedData,
          specifiedType: const FullType(Object)),
    ];
    Object? value;
    value = object.creatorUserAvatarId;
    if (value != null) {
      result
        ..add('creator_user_avatar_id')
        ..add(serializers.serialize(value,
            specifiedType: const FullType(String)));
    }
    return result;
  }

  @override
  NewsPiece deserialize(Serializers serializers, Iterable<Object?> serialized,
      {FullType specifiedType = FullType.unspecified}) {
    final result = new NewsPieceBuilder();

    final iterator = serialized.iterator;
    while (iterator.moveNext()) {
      final key = iterator.current! as String;
      iterator.moveNext();
      final Object? value = iterator.current;
      switch (key) {
        case 'id':
          result.serverId = serializers.deserialize(value,
              specifiedType: const FullType(int))! as int;
          break;
        case 'lat':
          result.lat = serializers.deserialize(value,
              specifiedType: const FullType(double))! as double;
          break;
        case 'lon':
          result.lon = serializers.deserialize(value,
              specifiedType: const FullType(double))! as double;
          break;
        case 'creator_user_id':
          result.creatorUserId = serializers.deserialize(value,
              specifiedType: const FullType(String))! as String;
          break;
        case 'creator_user_name':
          result.creatorUserName = serializers.deserialize(value,
              specifiedType: const FullType(String))! as String;
          break;
        case 'creator_user_avatar_id':
          result.creatorUserAvatarId = serializers.deserialize(value,
              specifiedType: const FullType(String)) as String?;
          break;
        case 'creation_time':
          result.creationTimeSecs = serializers.deserialize(value,
              specifiedType: const FullType(int))! as int;
          break;
        case 'type':
          result.typeCode = serializers.deserialize(value,
              specifiedType: const FullType(int))! as int;
          break;
        case 'data':
          result.data.replace(serializers.deserialize(value,
              specifiedType: const FullType(BuiltMap, const [
                const FullType(String),
                const FullType(JsonObject)
              ]))!);
          break;
        case 'typedData':
          result.typedData = serializers.deserialize(value,
              specifiedType: const FullType(Object));
          break;
      }
    }

    return result.build();
  }
}

class _$NewsPiece extends NewsPiece {
  @override
  final int serverId;
  @override
  final double lat;
  @override
  final double lon;
  @override
  final String creatorUserId;
  @override
  final String creatorUserName;
  @override
  final String? creatorUserAvatarId;
  @override
  final int creationTimeSecs;
  @override
  final int typeCode;
  @override
  final BuiltMap<String, JsonObject> data;
  @override
  final Object typedData;

  factory _$NewsPiece([void Function(NewsPieceBuilder)? updates]) =>
      (new NewsPieceBuilder()..update(updates))._build();

  _$NewsPiece._(
      {required this.serverId,
      required this.lat,
      required this.lon,
      required this.creatorUserId,
      required this.creatorUserName,
      this.creatorUserAvatarId,
      required this.creationTimeSecs,
      required this.typeCode,
      required this.data,
      required this.typedData})
      : super._() {
    BuiltValueNullFieldError.checkNotNull(serverId, r'NewsPiece', 'serverId');
    BuiltValueNullFieldError.checkNotNull(lat, r'NewsPiece', 'lat');
    BuiltValueNullFieldError.checkNotNull(lon, r'NewsPiece', 'lon');
    BuiltValueNullFieldError.checkNotNull(
        creatorUserId, r'NewsPiece', 'creatorUserId');
    BuiltValueNullFieldError.checkNotNull(
        creatorUserName, r'NewsPiece', 'creatorUserName');
    BuiltValueNullFieldError.checkNotNull(
        creationTimeSecs, r'NewsPiece', 'creationTimeSecs');
    BuiltValueNullFieldError.checkNotNull(typeCode, r'NewsPiece', 'typeCode');
    BuiltValueNullFieldError.checkNotNull(data, r'NewsPiece', 'data');
    BuiltValueNullFieldError.checkNotNull(typedData, r'NewsPiece', 'typedData');
  }

  @override
  NewsPiece rebuild(void Function(NewsPieceBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  NewsPieceBuilder toBuilder() => new NewsPieceBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is NewsPiece &&
        serverId == other.serverId &&
        lat == other.lat &&
        lon == other.lon &&
        creatorUserId == other.creatorUserId &&
        creatorUserName == other.creatorUserName &&
        creatorUserAvatarId == other.creatorUserAvatarId &&
        creationTimeSecs == other.creationTimeSecs &&
        typeCode == other.typeCode &&
        data == other.data &&
        typedData == other.typedData;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, serverId.hashCode);
    _$hash = $jc(_$hash, lat.hashCode);
    _$hash = $jc(_$hash, lon.hashCode);
    _$hash = $jc(_$hash, creatorUserId.hashCode);
    _$hash = $jc(_$hash, creatorUserName.hashCode);
    _$hash = $jc(_$hash, creatorUserAvatarId.hashCode);
    _$hash = $jc(_$hash, creationTimeSecs.hashCode);
    _$hash = $jc(_$hash, typeCode.hashCode);
    _$hash = $jc(_$hash, data.hashCode);
    _$hash = $jc(_$hash, typedData.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'NewsPiece')
          ..add('serverId', serverId)
          ..add('lat', lat)
          ..add('lon', lon)
          ..add('creatorUserId', creatorUserId)
          ..add('creatorUserName', creatorUserName)
          ..add('creatorUserAvatarId', creatorUserAvatarId)
          ..add('creationTimeSecs', creationTimeSecs)
          ..add('typeCode', typeCode)
          ..add('data', data)
          ..add('typedData', typedData))
        .toString();
  }
}

class NewsPieceBuilder implements Builder<NewsPiece, NewsPieceBuilder> {
  _$NewsPiece? _$v;

  int? _serverId;
  int? get serverId => _$this._serverId;
  set serverId(int? serverId) => _$this._serverId = serverId;

  double? _lat;
  double? get lat => _$this._lat;
  set lat(double? lat) => _$this._lat = lat;

  double? _lon;
  double? get lon => _$this._lon;
  set lon(double? lon) => _$this._lon = lon;

  String? _creatorUserId;
  String? get creatorUserId => _$this._creatorUserId;
  set creatorUserId(String? creatorUserId) =>
      _$this._creatorUserId = creatorUserId;

  String? _creatorUserName;
  String? get creatorUserName => _$this._creatorUserName;
  set creatorUserName(String? creatorUserName) =>
      _$this._creatorUserName = creatorUserName;

  String? _creatorUserAvatarId;
  String? get creatorUserAvatarId => _$this._creatorUserAvatarId;
  set creatorUserAvatarId(String? creatorUserAvatarId) =>
      _$this._creatorUserAvatarId = creatorUserAvatarId;

  int? _creationTimeSecs;
  int? get creationTimeSecs => _$this._creationTimeSecs;
  set creationTimeSecs(int? creationTimeSecs) =>
      _$this._creationTimeSecs = creationTimeSecs;

  int? _typeCode;
  int? get typeCode => _$this._typeCode;
  set typeCode(int? typeCode) => _$this._typeCode = typeCode;

  MapBuilder<String, JsonObject>? _data;
  MapBuilder<String, JsonObject> get data =>
      _$this._data ??= new MapBuilder<String, JsonObject>();
  set data(MapBuilder<String, JsonObject>? data) => _$this._data = data;

  Object? _typedData;
  Object? get typedData => _$this._typedData;
  set typedData(Object? typedData) => _$this._typedData = typedData;

  NewsPieceBuilder();

  NewsPieceBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _serverId = $v.serverId;
      _lat = $v.lat;
      _lon = $v.lon;
      _creatorUserId = $v.creatorUserId;
      _creatorUserName = $v.creatorUserName;
      _creatorUserAvatarId = $v.creatorUserAvatarId;
      _creationTimeSecs = $v.creationTimeSecs;
      _typeCode = $v.typeCode;
      _data = $v.data.toBuilder();
      _typedData = $v.typedData;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(NewsPiece other) {
    ArgumentError.checkNotNull(other, 'other');
    _$v = other as _$NewsPiece;
  }

  @override
  void update(void Function(NewsPieceBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  NewsPiece build() => _build();

  _$NewsPiece _build() {
    NewsPiece._sortItems(this);
    _$NewsPiece _$result;
    try {
      _$result = _$v ??
          new _$NewsPiece._(
              serverId: BuiltValueNullFieldError.checkNotNull(
                  serverId, r'NewsPiece', 'serverId'),
              lat: BuiltValueNullFieldError.checkNotNull(
                  lat, r'NewsPiece', 'lat'),
              lon: BuiltValueNullFieldError.checkNotNull(
                  lon, r'NewsPiece', 'lon'),
              creatorUserId: BuiltValueNullFieldError.checkNotNull(
                  creatorUserId, r'NewsPiece', 'creatorUserId'),
              creatorUserName: BuiltValueNullFieldError.checkNotNull(
                  creatorUserName, r'NewsPiece', 'creatorUserName'),
              creatorUserAvatarId: creatorUserAvatarId,
              creationTimeSecs: BuiltValueNullFieldError.checkNotNull(
                  creationTimeSecs, r'NewsPiece', 'creationTimeSecs'),
              typeCode: BuiltValueNullFieldError.checkNotNull(
                  typeCode, r'NewsPiece', 'typeCode'),
              data: data.build(),
              typedData: BuiltValueNullFieldError.checkNotNull(
                  typedData, r'NewsPiece', 'typedData'));
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'data';
        data.build();
      } catch (e) {
        throw new BuiltValueNestedFieldError(
            r'NewsPiece', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
