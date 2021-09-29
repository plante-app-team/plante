import 'dart:convert';

import 'package:plante/outside/map/osm_nominatim.dart';
import 'package:plante/outside/map/osm_road.dart';
import 'package:plante/outside/map/osm_search_result.dart';
import 'package:plante/outside/map/osm_shop.dart';
import 'package:test/test.dart';

import '../../z_fakes/fake_http_client.dart';
import 'open_street_map_test_commons.dart';

void main() {
  late OpenStreetMapTestCommons commons;
  late FakeHttpClient http;
  late OsmNominatim nominatim;

  setUp(() async {
    commons = OpenStreetMapTestCommons();
    await commons.setUp();
    http = commons.http;
    nominatim = commons.nominatim;
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
        "class": "highway",
        "type": "residential",
        "namedetails": {
          "name": "Broadway Street"
        },
        "address": {
          "road": "Broadway Street",
          "city_district": "Nice district",
          "city": "London"
        }
      },
      {
        "osm_type": "way",
        "osm_id": 437497419,
        "lat": "56.3213453",
        "lon": "44.0187501",
        "class": "highway",
        "type": "residential",
        "namedetails": {
          "name": "Broadway Street"
        },
        "address": {
          "road": "Broadway Street",
          "city_district": "Bad district",
          "city": "London"
        }
      },
      {
        "osm_type": "node",
        "osm_id": 6266574214,
        "lat": "56.321002",
        "lon": "44.0143096",
        "class": "shop",
        "type": "supermarket",
        "namedetails": {
          "name": "Broadway shop"
        },
        "address": {
          "house_number": "34A",
          "road": "Broadway Street",
          "city_district": "Bad district",
          "city": "London"
        }
      }
    ]
    ''';

    http.setResponse('.*', osmResp);

    final searchResRes =
        await nominatim.search('United States', 'London', 'Broadway');
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
            ..osmUID = '1:6266574214'
            ..name = 'Broadway shop'
            ..type = 'supermarket'
            ..latitude = 56.321002
            ..longitude = 44.0143096
            ..city = 'London'
            ..road = 'Broadway Street'
            ..houseNumber = '34A'),
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
        "class": "shop",
        "type": "supermarket",
        "namedetails": {
          "name": "Broadway shop"
        },
        "address": {
          "house_number": "34A",
          "road": "Broadway Street",
          "city_district": "Bad district",
          "city": "London"
        }
      }
    ]
    ''';

    http.setResponse('.*', validOsmResp);
    expect(
        (await nominatim.search('United States', 'London', 'Broadway'))
            .unwrap()
            .shops,
        isNotEmpty);

    final invalidOsmResp = removeSearchResponseKeys(validOsmResp, field);

    http.setResponse('.*', invalidOsmResp);
    expect(
        (await nominatim.search('United States', 'London', 'Broadway'))
            .unwrap()
            .shops,
        isEmpty);
  }

  test('searched and found shop has no ID', () async {
    await testFoundShopWithoutField('osm_id');
  });

  test('searched and found shop has no name', () async {
    await testFoundShopWithoutField('namedetails');
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
        "class": "highway",
        "type": "residential",
        "namedetails": {
          "name": "Broadway Street"
        },
        "address": {
          "road": "Broadway Street",
          "city_district": "Nice district",
          "city": "London"
        }
      }
    ]
    ''';

    http.setResponse('.*', validOsmResp);
    expect(
        (await nominatim.search('United States', 'London', 'Broadway'))
            .unwrap()
            .roads,
        isNotEmpty);

    final invalidOsmResp = removeSearchResponseKeys(validOsmResp, field);

    http.setResponse('.*', invalidOsmResp);
    expect(
        (await nominatim.search('United States', 'London', 'Broadway'))
            .unwrap()
            .roads,
        isEmpty);
  }

  test('searched and found road has no ID', () async {
    await testFoundRoadWithoutField('osm_id');
  });

  test('searched and found road has no name', () async {
    await testFoundRoadWithoutField('namedetails');
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
        "class": "highway",
        "type": "residential",
        "namedetails": {
          "name": "Broadway Street"
        },
        "address": {
          "road": "Broadway Street",
          "city_district": "Nice district",
          "city": "London"
        }
      }
    ]
    ''';

    http.setResponse('.*', validOsmResp);
    expect(
        (await nominatim.search('United States', 'London', 'Broadway'))
            .unwrap()
            .roads,
        isNotEmpty);

    http.setResponse('.*', validOsmResp, responseCode: 500);
    expect(
        (await nominatim.search('United States', 'London', 'Broadway')).isErr,
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
        "class": "highway",
        "type": "residential",
        "namedetails": {
          "name": "Broadway Street"
        },
        "address": {
          "road": "Broadway Street",
          "city_district": "Nice district",
          "city": "London"
        }
      }
    ]
    ''';

    http.setResponse('.*', validOsmResp);
    expect(
        (await nominatim.search('United States', 'London', 'Broadway'))
            .unwrap()
            .roads,
        isNotEmpty);

    const invalidOsmResp = '$validOsmResp}}}}}}}}}}';
    http.setResponse('.*', invalidOsmResp);
    expect(
        (await nominatim.search('United States', 'London', 'Broadway')).isErr,
        isTrue);
  });

  test('found roads have similar locations', () async {
    const osmResp = '''
    [
      {
        "osm_type": "way",
        "osm_id": 318119915,
        "lat": "56.3232248",
        "lon": "44.0103222",
        "class": "highway",
        "type": "residential",
        "namedetails": {
          "name": "Broadway Street"
        },
        "address": {
          "road": "Broadway Street",
          "city_district": "Nice district",
          "city": "London",
          "postcode": "654001"
        }
      },
      {
        "osm_type": "way",
        "osm_id": 437497419,
        "lat": "56.3213453",
        "lon": "44.0187501",
        "class": "highway",
        "type": "residential",
        "namedetails": {
          "name": "Broadway Street"
        },
        "address": {
          "road": "Broadway Street",
          "city_district": "Nice district",
          "city": "London",
          "postcode": "654002"
        }
      }
    ]
    ''';

    http.setResponse('.*', osmResp);
    final searchResRes =
        await nominatim.search('United States', 'London', 'Broadway');
    final searchRes = searchResRes.unwrap();

    // We expect the second road to be not included in the result
    // since its name is almost same.
    final expectedSearchRes = OsmSearchResult(
      (e) => e
        ..roads.addAll([
          OsmRoad((e) => e
            ..osmId = '318119915'
            ..name = 'Broadway Street'
            ..latitude = 56.3232248
            ..longitude = 44.0103222),
        ]),
    );

    expect(searchRes, equals(expectedSearchRes));
  });

  test('found shops have similar locations', () async {
    const osmResp = '''
    [
      {
        "osm_type": "node",
        "osm_id": 6266574214,
        "lat": "56.321002",
        "lon": "44.0143096",
        "class": "shop",
        "type": "supermarket",
        "address": {
          "house_number": "34A",
          "road": "Broadway Street",
          "city_district": "Bad district",
          "city": "London"
        },
        "namedetails": {
          "name": "Broadway shop"
        }
      },
      {
        "osm_type": "node",
        "osm_id": 6266574215,
        "lat": "56.321002",
        "lon": "44.0143096",
        "class": "shop",
        "type": "supermarket",
        "address": {
          "house_number": "34A",
          "road": "Broadway Street",
          "city_district": "Bad district",
          "city": "London"
        },
        "namedetails": {
          "name": "Broadway shop"
        }
      }
    ]
    ''';

    http.setResponse('.*', osmResp);
    final searchResRes =
        await nominatim.search('United States', 'London', 'Broadway');
    final searchRes = searchResRes.unwrap();

    // We expect BOTH shops to be found even thought their names are identical.
    // Similar names elimination works for roads only, because roads usually
    // consist of many parts, and shops don't.
    final expectedSearchRes = OsmSearchResult(
      (e) => e
        ..shops.addAll([
          OsmShop((e) => e
            ..osmUID = '1:6266574214'
            ..name = 'Broadway shop'
            ..type = 'supermarket'
            ..latitude = 56.321002
            ..longitude = 44.0143096
            ..city = 'London'
            ..road = 'Broadway Street'
            ..houseNumber = '34A'),
          OsmShop((e) => e
            ..osmUID = '1:6266574215'
            ..name = 'Broadway shop'
            ..type = 'supermarket'
            ..latitude = 56.321002
            ..longitude = 44.0143096
            ..city = 'London'
            ..road = 'Broadway Street'
            ..houseNumber = '34A'),
        ]),
    );

    expect(searchRes, equals(expectedSearchRes));
  });
}
