import 'package:built_collection/built_collection.dart';
import 'package:built_value/json_object.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plante/base/result.dart';
import 'package:plante/outside/backend/news/news_piece.dart';
import 'package:plante/outside/backend/news/news_piece_product_at_shop.dart';
import 'package:plante/outside/backend/news/news_piece_type.dart';
import 'package:plante/outside/map/osm/osm_uid.dart';

void main() {
  setUp(() async {});

  test('typedData', () {
    final value = NewsPiece((e) => e
      ..serverId = 3
      ..lat = 1.5
      ..lon = 1.6
      ..creatorUserId = 'user3'
      ..creationTimeSecs = 123454
      ..typeCode = 1
      ..data = MapBuilder({
        'barcode': JsonObject('654321'),
        'shop_uid': JsonObject('1:123321')
      }));

    final productAtShopPiece = value.typedData as NewsPieceProductAtShop;
    expect(
        productAtShopPiece,
        equals(NewsPieceProductAtShop((e) => e
          ..barcode = '654321'
          ..shopUID = OsmUID.parse('1:123321'))));
  });

  test('serialize and deserialize', () {
    final value = NewsPiece((e) => e
      ..serverId = 3
      ..lat = 1.5
      ..lon = 1.6
      ..creatorUserId = 'user3'
      ..creationTimeSecs = 123454
      ..typeCode = 1
      ..data = MapBuilder({
        'barcode': JsonObject('654321'),
        'shop_uid': JsonObject('1:123321')
      }));

    final json = value.toJson();
    final deserialized = NewsPiece.fromJson(json);
    expect(deserialized, equals(value));
  });

  test('news piece with unknown type and data', () {
    final value = NewsPiece((e) => e
      ..serverId = 3
      ..lat = 1.5
      ..lon = 1.6
      ..creatorUserId = 'user3'
      ..creationTimeSecs = 123454
      ..typeCode = 1234567
      ..data = MapBuilder({
        'was': JsonObject('what'),
        'ist': JsonObject('is'),
        'das': JsonObject('that')
      }));

    expect(value.type, equals(NewsPieceType.UNKNOWN));
    expect(value.typedData is None, isTrue);
  });
}
