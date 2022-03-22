import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/json_object.dart';
import 'package:built_value/serializer.dart';
import 'package:plante/base/build_value_helper.dart';
import 'package:plante/base/result.dart';
import 'package:plante/logging/log.dart';
import 'package:plante/outside/backend/news/news_piece_product_at_shop.dart';
import 'package:plante/outside/backend/news/news_piece_type.dart';

part 'news_piece.g.dart';

abstract class NewsPiece implements Built<NewsPiece, NewsPieceBuilder> {
  @BuiltValueField(wireName: 'id')
  int get serverId;
  @BuiltValueField(wireName: 'lat')
  double get lat;
  @BuiltValueField(wireName: 'lon')
  double get lon;
  @BuiltValueField(wireName: 'creator_user_id')
  String get creatorUserId;
  @BuiltValueField(wireName: 'creation_time')
  int get creationTimeSecs;
  @BuiltValueField(wireName: 'type')
  int get typeCode;

  @BuiltValueField(wireName: 'data')
  BuiltMap<String, JsonObject> get data;

  NewsPieceType get type => newsPieceTypeFromCode(typeCode);
  Object get typedData;

  @BuiltValueHook(finalizeBuilder: true)
  static void _sortItems(NewsPieceBuilder b) =>
      b.typedData = _createTypedData(b.data.build(), b.typeCode!);

  static Object _createTypedData(
      BuiltMap<String, JsonObject> data, int typeCode) {
    final type = newsPieceTypeFromCode(typeCode);
    if (type == NewsPieceType.PRODUCT_AT_SHOP) {
      return NewsPieceProductAtShop.fromJsonObjects(data);
    } else {
      Log.w('Cannot convert data to $NewsPieceProductAtShop. '
          'Type: $type, data: $data');
      return None();
    }
  }

  static NewsPiece? fromJson(Map<String, dynamic> json) {
    return BuildValueHelper.jsonSerializers
        .deserializeWith(NewsPiece.serializer, json);
  }

  Map<String, dynamic> toJson() {
    return BuildValueHelper.jsonSerializers.serializeWith(serializer, this)!
        as Map<String, dynamic>;
  }

  factory NewsPiece([void Function(NewsPieceBuilder) updates]) = _$NewsPiece;
  NewsPiece._();
  static Serializer<NewsPiece> get serializer => _$newsPieceSerializer;
}
