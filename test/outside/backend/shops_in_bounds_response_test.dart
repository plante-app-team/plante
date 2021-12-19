import 'dart:convert';

import 'package:built_collection/built_collection.dart';
import 'package:plante/outside/backend/backend_shop.dart';
import 'package:plante/outside/backend/shops_in_bounds_response.dart';
import 'package:plante/outside/map/osm/osm_uid.dart';
import 'package:test/test.dart';

void main() {
  test('from json', () {
    const jsonStr = '''
          {
            "results" : {
              "1:8711880917" : {
                "osm_uid" : "1:8711880917",
                "products_count" : 1
              },
              "1:8771781029" : {
                "osm_uid" : "1:8771781029",
                "products_count" : 2
              }
            },
            "barcodes" : {
              "1:8711880917" : [ "123", "345" ],
              "1:8771781029" : [ "678", "890" ]
            }
          }
        ''';
    final expected = ShopsInBoundsResponse((e) => e
      ..shops['1:8711880917'] = BackendShop((e) => e
        ..osmUID = OsmUID.parse('1:8711880917')
        ..productsCount = 1)
      ..shops['1:8771781029'] = BackendShop((e) => e
        ..osmUID = OsmUID.parse('1:8771781029')
        ..productsCount = 2)
      ..barcodes['1:8711880917'] = BuiltList.from(['123', '345'])
      ..barcodes['1:8771781029'] = BuiltList.from(['678', '890']));

    final json = jsonDecode(jsonStr);
    final result = ShopsInBoundsResponse.fromJson(json);

    expect(result, equals(expected));
  });
}
