// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'news_cluster.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

Serializer<NewsCluster> _$newsClusterSerializer = new _$NewsClusterSerializer();

class _$NewsClusterSerializer implements StructuredSerializer<NewsCluster> {
  @override
  final Iterable<Type> types = const [NewsCluster, _$NewsCluster];
  @override
  final String wireName = 'NewsCluster';

  @override
  Iterable<Object?> serialize(Serializers serializers, NewsCluster object,
      {FullType specifiedType = FullType.unspecified}) {
    final result = <Object?>[
      'typeCode',
      serializers.serialize(object.typeCode,
          specifiedType: const FullType(int)),
      'authorId',
      serializers.serialize(object.authorId,
          specifiedType: const FullType(String)),
      'newsPieces',
      serializers.serialize(object.newsPieces,
          specifiedType:
              const FullType(BuiltList, const [const FullType(NewsPiece)])),
    ];

    return result;
  }

  @override
  NewsCluster deserialize(Serializers serializers, Iterable<Object?> serialized,
      {FullType specifiedType = FullType.unspecified}) {
    final result = new NewsClusterBuilder();

    final iterator = serialized.iterator;
    while (iterator.moveNext()) {
      final key = iterator.current! as String;
      iterator.moveNext();
      final Object? value = iterator.current;
      switch (key) {
        case 'typeCode':
          result.typeCode = serializers.deserialize(value,
              specifiedType: const FullType(int))! as int;
          break;
        case 'authorId':
          result.authorId = serializers.deserialize(value,
              specifiedType: const FullType(String))! as String;
          break;
        case 'newsPieces':
          result.newsPieces.replace(serializers.deserialize(value,
                  specifiedType: const FullType(
                      BuiltList, const [const FullType(NewsPiece)]))!
              as BuiltList<Object?>);
          break;
      }
    }

    return result.build();
  }
}

class _$NewsCluster extends NewsCluster {
  @override
  final int typeCode;
  @override
  final String authorId;
  @override
  final BuiltList<NewsPiece> newsPieces;

  factory _$NewsCluster([void Function(NewsClusterBuilder)? updates]) =>
      (new NewsClusterBuilder()..update(updates))._build();

  _$NewsCluster._(
      {required this.typeCode,
      required this.authorId,
      required this.newsPieces})
      : super._() {
    BuiltValueNullFieldError.checkNotNull(typeCode, r'NewsCluster', 'typeCode');
    BuiltValueNullFieldError.checkNotNull(authorId, r'NewsCluster', 'authorId');
    BuiltValueNullFieldError.checkNotNull(
        newsPieces, r'NewsCluster', 'newsPieces');
  }

  @override
  NewsCluster rebuild(void Function(NewsClusterBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  NewsClusterBuilder toBuilder() => new NewsClusterBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is NewsCluster &&
        typeCode == other.typeCode &&
        authorId == other.authorId &&
        newsPieces == other.newsPieces;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, typeCode.hashCode);
    _$hash = $jc(_$hash, authorId.hashCode);
    _$hash = $jc(_$hash, newsPieces.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'NewsCluster')
          ..add('typeCode', typeCode)
          ..add('authorId', authorId)
          ..add('newsPieces', newsPieces))
        .toString();
  }
}

class NewsClusterBuilder implements Builder<NewsCluster, NewsClusterBuilder> {
  _$NewsCluster? _$v;

  int? _typeCode;
  int? get typeCode => _$this._typeCode;
  set typeCode(int? typeCode) => _$this._typeCode = typeCode;

  String? _authorId;
  String? get authorId => _$this._authorId;
  set authorId(String? authorId) => _$this._authorId = authorId;

  ListBuilder<NewsPiece>? _newsPieces;
  ListBuilder<NewsPiece> get newsPieces =>
      _$this._newsPieces ??= new ListBuilder<NewsPiece>();
  set newsPieces(ListBuilder<NewsPiece>? newsPieces) =>
      _$this._newsPieces = newsPieces;

  NewsClusterBuilder();

  NewsClusterBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _typeCode = $v.typeCode;
      _authorId = $v.authorId;
      _newsPieces = $v.newsPieces.toBuilder();
      _$v = null;
    }
    return this;
  }

  @override
  void replace(NewsCluster other) {
    ArgumentError.checkNotNull(other, 'other');
    _$v = other as _$NewsCluster;
  }

  @override
  void update(void Function(NewsClusterBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  NewsCluster build() => _build();

  _$NewsCluster _build() {
    _$NewsCluster _$result;
    try {
      _$result = _$v ??
          new _$NewsCluster._(
              typeCode: BuiltValueNullFieldError.checkNotNull(
                  typeCode, r'NewsCluster', 'typeCode'),
              authorId: BuiltValueNullFieldError.checkNotNull(
                  authorId, r'NewsCluster', 'authorId'),
              newsPieces: newsPieces.build());
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'newsPieces';
        newsPieces.build();
      } catch (e) {
        throw new BuiltValueNestedFieldError(
            r'NewsCluster', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
