import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';
import 'package:plante/base/build_value_helper.dart';
import 'package:plante/outside/news/news_piece.dart';

part 'news_data_response.g.dart';

abstract class NewsDataResponse
    implements Built<NewsDataResponse, NewsDataResponseBuilder> {
  @BuiltValueField(wireName: 'last_page')
  bool get lastPage;
  @BuiltValueField(wireName: 'results')
  BuiltList<NewsPiece> get results;

  static NewsDataResponse? fromJson(Map<String, dynamic> json) {
    return BuildValueHelper.jsonSerializers
        .deserializeWith(NewsDataResponse.serializer, json);
  }

  factory NewsDataResponse([void Function(NewsDataResponseBuilder) updates]) =
      _$NewsDataResponse;
  NewsDataResponse._();
  static Serializer<NewsDataResponse> get serializer =>
      _$newsDataResponseSerializer;
}
