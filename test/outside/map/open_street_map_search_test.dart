import 'dart:convert';

import 'package:plante/outside/map/open_street_map.dart';
import 'package:plante/outside/map/osm_road.dart';
import 'package:plante/outside/map/osm_search_result.dart';
import 'package:plante/outside/map/osm_shop.dart';
import 'package:test/test.dart';

import '../../z_fakes/fake_http_client.dart';
import 'open_street_map_test_commons.dart';

void main() {
  late OpenStreetMapTestCommons commons;
  late FakeHttpClient http;
  late OpenStreetMap osm;

  setUp(() async {
    commons = OpenStreetMapTestCommons();
    await commons.setUp();
    http = commons.http;
    osm = commons.osm;
  });

  String removeSearchResponseKeys(String response, String key) {
    final responseJson = jsonDecode(response);
    for (final part in responseJson as List<dynamic>) {
      final partJson = part as Map<String, dynamic>;
      partJson.remove(key);
    }
    return jsonEncode(responseJson);
  }

  test('search good scenario', () async {
    const osmResp = '''
    [
      {
        "osm_type": "way",
        "osm_id": 318119915,
        "lat": "56.3232248",
        "lon": "44.0103222",
        "display_name": "Broadway Street, Broadway, South Somerset, Jefferson City, South West England, England, TA19 9RX, United States",
        "class": "highway",
        "type": "residential"
      },
      {
        "osm_type": "way",
        "osm_id": 437497419,
        "lat": "56.3213453",
        "lon": "44.0187501",
        "display_name": "Broadway Street, Wow such a City, Cole County, Missouri, 65102, United Kingdom",
        "class": "highway",
        "type": "residential"
      },
      {
        "osm_type": "node",
        "osm_id": 6266574214,
        "lat": "56.321002",
        "lon": "44.0143096",
        "display_name": "Broadway shop, Jefferson City, Cole County, Missouri, 65102, United States",
        "class": "shop",
        "type": "supermarket"
      }
    ]
    ''';

    http.setResponse('.*', osmResp);

    final searchResRes =
        await osm.search('United States', 'Jefferson City', 'Broadway');
    final searchRes = searchResRes.unwrap();

    final expectedSearchRes = OsmSearchResult(
      (e) => e
        ..roads.addAll([
          OsmRoad((e) => e
            ..osmId = '318119915'
            ..name = 'Broadway Street'
            ..latitude = 56.3232248
            ..longitude = 44.0103222),
          OsmRoad((e) => e
            ..osmId = '437497419'
            ..name = 'Broadway Street'
            ..latitude = 56.3213453
            ..longitude = 44.0187501),
        ])
        ..shops.addAll([
          OsmShop((e) => e
            ..osmId = '6266574214'
            ..name = 'Broadway shop'
            ..type = 'supermarket'
            ..latitude = 56.321002
            ..longitude = 44.0143096),
        ]),
    );

    expect(searchRes, equals(expectedSearchRes));
  });

  Future<void> testFoundShopWithoutField(String field) async {
    const validOsmResp = '''
    [
      {
        "osm_type": "node",
        "osm_id": 6266574214,
        "lat": "56.321002",
        "lon": "44.0143096",
        "display_name": "Broadway shop, Jefferson City, Cole County, Missouri, 65102, United States",
        "class": "shop",
        "type": "supermarket"
      }
    ]
    ''';

    http.setResponse('.*', validOsmResp);
    expect(
        (await osm.search('United States', 'Jefferson City', 'Broadway'))
            .unwrap()
            .shops,
        isNotEmpty);

    final invalidOsmResp = removeSearchResponseKeys(validOsmResp, field);

    http.setResponse('.*', invalidOsmResp);
    expect(
        (await osm.search('United States', 'Jefferson City', 'Broadway'))
            .unwrap()
            .shops,
        isEmpty);
  }

  test('searched and found shop has no ID', () async {
    await testFoundShopWithoutField('osm_id');
  });

  test('searched and found shop has no name', () async {
    await testFoundShopWithoutField('display_name');
  });

  test('searched and found shop has no type', () async {
    await testFoundShopWithoutField('type');
  });

  test('searched and found shop has no lat', () async {
    await testFoundShopWithoutField('lat');
  });

  test('searched and found shop has no lon', () async {
    await testFoundShopWithoutField('lon');
  });

  Future<void> testFoundRoadWithoutField(String field) async {
    const validOsmResp = '''
    [
      {
        "osm_type": "way",
        "osm_id": 318119915,
        "lat": "56.3232248",
        "lon": "44.0103222",
        "display_name": "Broadway Street, Broadway, South Somerset, Jefferson City, South West England, England, TA19 9RX, United States",
        "class": "highway",
        "type": "residential"
      }
    ]
    ''';

    http.setResponse('.*', validOsmResp);
    expect(
        (await osm.search('United States', 'Jefferson City', 'Broadway'))
            .unwrap()
            .roads,
        isNotEmpty);

    final invalidOsmResp = removeSearchResponseKeys(validOsmResp, field);

    http.setResponse('.*', invalidOsmResp);
    expect(
        (await osm.search('United States', 'Jefferson City', 'Broadway'))
            .unwrap()
            .roads,
        isEmpty);
  }

  test('searched and found road has no ID', () async {
    await testFoundRoadWithoutField('osm_id');
  });

  test('searched and found road has no name', () async {
    await testFoundRoadWithoutField('display_name');
  });

  test('searched and found road has no class', () async {
    await testFoundRoadWithoutField('class');
  });

  test('searched and found road has no lat', () async {
    await testFoundRoadWithoutField('lat');
  });

  test('searched and found road has no lon', () async {
    await testFoundRoadWithoutField('lon');
  });

  test('search result not 200', () async {
    const validOsmResp = '''
    [
      {
        "osm_type": "way",
        "osm_id": 318119915,
        "lat": "56.3232248",
        "lon": "44.0103222",
        "display_name": "Broadway Street, Broadway, South Somerset, Jefferson City, South West England, England, TA19 9RX, United States",
        "class": "highway",
        "type": "residential"
      }
    ]
    ''';

    http.setResponse('.*', validOsmResp);
    expect(
        (await osm.search('United States', 'Jefferson City', 'Broadway'))
            .unwrap()
            .roads,
        isNotEmpty);

    http.setResponse('.*', validOsmResp, responseCode: 500);
    expect(
        (await osm.search('United States', 'Jefferson City', 'Broadway')).isErr,
        isTrue);
  });

  test('search result invalid json', () async {
    const validOsmResp = '''
    [
      {
        "osm_type": "way",
        "osm_id": 318119915,
        "lat": "56.3232248",
        "lon": "44.0103222",
        "display_name": "Broadway Street, Broadway, South Somerset, Jefferson City, South West England, England, TA19 9RX, United States",
        "class": "highway",
        "type": "residential"
      }
    ]
    ''';

    http.setResponse('.*', validOsmResp);
    expect(
        (await osm.search('United States', 'Jefferson City', 'Broadway'))
            .unwrap()
            .roads,
        isNotEmpty);

    const invalidOsmResp = '$validOsmResp}}}}}}}}}}';
    http.setResponse('.*', invalidOsmResp);
    expect(
        (await osm.search('United States', 'Jefferson City', 'Broadway')).isErr,
        isTrue);
  });

  test('found roads have similar names', () async {
    const osmResp = '''
    [
      {
        "osm_type": "way",
        "osm_id": 318119915,
        "lat": "56.3213453",
        "lon": "44.0187501",
        "display_name": "Broadway Street, Jefferson City, Cole County, Missouri, 65102, United States",
        "class": "highway",
        "type": "residential"
      },
      {
        "osm_type": "way",
        "osm_id": 437497419,
        "lat": "56.3213453",
        "lon": "44.0187501",
        "display_name": "Broadway Street, Jefferson City, Cole County, Missouri, 65103, United States",
        "class": "highway",
        "type": "residential"
      }
    ]
    ''';

    http.setResponse('.*', osmResp);
    final searchResRes =
        await osm.search('United States', 'Jefferson City', 'Broadway');
    final searchRes = searchResRes.unwrap();

    // We expect the second road to be not included in the result
    // since its name is almost same.
    final expectedSearchRes = OsmSearchResult(
      (e) => e
        ..roads.addAll([
          OsmRoad((e) => e
            ..osmId = '318119915'
            ..name = 'Broadway Street'
            ..latitude = 56.3213453
            ..longitude = 44.0187501),
        ]),
    );

    expect(searchRes, equals(expectedSearchRes));
  });

  test('found shops have similar names', () async {
    const osmResp = '''
    [
      {
        "osm_type": "node",
        "osm_id": 6266574214,
        "lat": "56.321002",
        "lon": "44.0143096",
        "display_name": "Broadway shop, Jefferson City, Cole County, Missouri, 65101, United States",
        "class": "shop",
        "type": "supermarket"
      },
      {
        "osm_type": "node",
        "osm_id": 6266574215,
        "lat": "56.321002",
        "lon": "44.0143096",
        "display_name": "Broadway shop, Jefferson City, Cole County, Missouri, 65101, United States",
        "class": "shop",
        "type": "supermarket"
      }
    ]
    ''';

    http.setResponse('.*', osmResp);
    final searchResRes =
        await osm.search('United States', 'Jefferson City', 'Broadway');
    final searchRes = searchResRes.unwrap();

    // We expect BOTH shops to be found even thought their names are identical.
    // Similar names elimination works for roads only, because roads usually
    // consist of many parts, and shops don't.
    final expectedSearchRes = OsmSearchResult(
      (e) => e
        ..shops.addAll([
          OsmShop((e) => e
            ..osmId = '6266574214'
            ..name = 'Broadway shop'
            ..type = 'supermarket'
            ..latitude = 56.321002
            ..longitude = 44.0143096),
          OsmShop((e) => e
            ..osmId = '6266574215'
            ..name = 'Broadway shop'
            ..type = 'supermarket'
            ..latitude = 56.321002
            ..longitude = 44.0143096),
        ]),
    );

    expect(searchRes, equals(expectedSearchRes));
  });
}
