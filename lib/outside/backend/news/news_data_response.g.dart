// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'news_data_response.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

Serializer<NewsDataResponse> _$newsDataResponseSerializer =
    new _$NewsDataResponseSerializer();

class _$NewsDataResponseSerializer
    implements StructuredSerializer<NewsDataResponse> {
  @override
  final Iterable<Type> types = const [NewsDataResponse, _$NewsDataResponse];
  @override
  final String wireName = 'NewsDataResponse';

  @override
  Iterable<Object?> serialize(Serializers serializers, NewsDataResponse object,
      {FullType specifiedType = FullType.unspecified}) {
    final result = <Object?>[
      'last_page',
      serializers.serialize(object.lastPage,
          specifiedType: const FullType(bool)),
      'results',
      serializers.serialize(object.results,
          specifiedType:
              const FullType(BuiltList, const [const FullType(NewsPiece)])),
    ];

    return result;
  }

  @override
  NewsDataResponse deserialize(
      Serializers serializers, Iterable<Object?> serialized,
      {FullType specifiedType = FullType.unspecified}) {
    final result = new NewsDataResponseBuilder();

    final iterator = serialized.iterator;
    while (iterator.moveNext()) {
      final key = iterator.current as String;
      iterator.moveNext();
      final Object? value = iterator.current;
      switch (key) {
        case 'last_page':
          result.lastPage = serializers.deserialize(value,
              specifiedType: const FullType(bool)) as bool;
          break;
        case 'results':
          result.results.replace(serializers.deserialize(value,
                  specifiedType: const FullType(
                      BuiltList, const [const FullType(NewsPiece)]))!
              as BuiltList<Object?>);
          break;
      }
    }

    return result.build();
  }
}

class _$NewsDataResponse extends NewsDataResponse {
  @override
  final bool lastPage;
  @override
  final BuiltList<NewsPiece> results;

  factory _$NewsDataResponse(
          [void Function(NewsDataResponseBuilder)? updates]) =>
      (new NewsDataResponseBuilder()..update(updates)).build();

  _$NewsDataResponse._({required this.lastPage, required this.results})
      : super._() {
    BuiltValueNullFieldError.checkNotNull(
        lastPage, 'NewsDataResponse', 'lastPage');
    BuiltValueNullFieldError.checkNotNull(
        results, 'NewsDataResponse', 'results');
  }

  @override
  NewsDataResponse rebuild(void Function(NewsDataResponseBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  NewsDataResponseBuilder toBuilder() =>
      new NewsDataResponseBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is NewsDataResponse &&
        lastPage == other.lastPage &&
        results == other.results;
  }

  @override
  int get hashCode {
    return $jf($jc($jc(0, lastPage.hashCode), results.hashCode));
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper('NewsDataResponse')
          ..add('lastPage', lastPage)
          ..add('results', results))
        .toString();
  }
}

class NewsDataResponseBuilder
    implements Builder<NewsDataResponse, NewsDataResponseBuilder> {
  _$NewsDataResponse? _$v;

  bool? _lastPage;
  bool? get lastPage => _$this._lastPage;
  set lastPage(bool? lastPage) => _$this._lastPage = lastPage;

  ListBuilder<NewsPiece>? _results;
  ListBuilder<NewsPiece> get results =>
      _$this._results ??= new ListBuilder<NewsPiece>();
  set results(ListBuilder<NewsPiece>? results) => _$this._results = results;

  NewsDataResponseBuilder();

  NewsDataResponseBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _lastPage = $v.lastPage;
      _results = $v.results.toBuilder();
      _$v = null;
    }
    return this;
  }

  @override
  void replace(NewsDataResponse other) {
    ArgumentError.checkNotNull(other, 'other');
    _$v = other as _$NewsDataResponse;
  }

  @override
  void update(void Function(NewsDataResponseBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  _$NewsDataResponse build() {
    _$NewsDataResponse _$result;
    try {
      _$result = _$v ??
          new _$NewsDataResponse._(
              lastPage: BuiltValueNullFieldError.checkNotNull(
                  lastPage, 'NewsDataResponse', 'lastPage'),
              results: results.build());
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'results';
        results.build();
      } catch (e) {
        throw new BuiltValueNestedFieldError(
            'NewsDataResponse', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: always_put_control_body_on_new_line,always_specify_types,annotate_overrides,avoid_annotating_with_dynamic,avoid_as,avoid_catches_without_on_clauses,avoid_returning_this,deprecated_member_use_from_same_package,lines_longer_than_80_chars,omit_local_variable_types,prefer_expression_function_bodies,sort_constructors_first,test_types_in_equals,unnecessary_const,unnecessary_new
