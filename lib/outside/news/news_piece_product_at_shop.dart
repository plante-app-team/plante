import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/json_object.dart';
import 'package:built_value/serializer.dart';
import 'package:plante/base/build_value_helper.dart';
import 'package:plante/outside/map/osm/osm_uid.dart';

part 'news_piece_product_at_shop.g.dart';

abstract class NewsPieceProductAtShop
    implements Built<NewsPieceProductAtShop, NewsPieceProductAtShopBuilder> {
  @BuiltValueField(wireName: 'barcode')
  String get barcode;
  @BuiltValueField(wireName: 'shop_uid')
  OsmUID get shopUID;

  static NewsPieceProductAtShop? fromJson(Map<String, dynamic> json) {
    return BuildValueHelper.jsonSerializers
        .deserializeWith(NewsPieceProductAtShop.serializer, json);
  }

  static NewsPieceProductAtShop fromJsonObjects(
      BuiltMap<String, JsonObject> json) {
    return NewsPieceProductAtShop((e) => e
      ..barcode = json['barcode']!.asString
      ..shopUID = OsmUID.parse(json['shop_uid']!.asString));
  }

  Map<String, dynamic> toJson() {
    return BuildValueHelper.jsonSerializers.serializeWith(serializer, this)!
        as Map<String, dynamic>;
  }

  factory NewsPieceProductAtShop(
          [void Function(NewsPieceProductAtShopBuilder) updates]) =
      _$NewsPieceProductAtShop;
  NewsPieceProductAtShop._();
  static Serializer<NewsPieceProductAtShop> get serializer =>
      _$newsPieceProductAtShopSerializer;
}
