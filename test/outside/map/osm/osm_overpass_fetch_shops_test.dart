import 'dart:io';

import 'package:plante/model/coord.dart';
import 'package:plante/model/coords_bounds.dart';
import 'package:plante/outside/map/osm/open_street_map.dart';
import 'package:plante/outside/map/osm/osm_element_type.dart';
import 'package:plante/outside/map/osm/osm_overpass.dart';
import 'package:plante/outside/map/osm/osm_shop.dart';
import 'package:plante/outside/map/osm/osm_uid.dart';
import 'package:test/test.dart';

import '../../../z_fakes/fake_analytics.dart';
import '../../../z_fakes/fake_http_client.dart';
import 'open_street_map_test_commons.dart';

void main() {
  late OpenStreetMapTestCommons commons;
  late FakeHttpClient http;
  late FakeAnalytics analytics;
  late OsmOverpass overpass;

  setUp(() async {
    commons = OpenStreetMapTestCommons();
    await commons.setUp();
    http = commons.http;
    analytics = commons.analytics;
    overpass = commons.overpass;
  });

  test('fetchShops good scenario', () async {
    const osmResp = '''
    {
      "elements": [
        {
          "type": "node",
          "id": 992336735,
          "lat": 56.3202185,
          "lon": 44.0097146,
          "tags": {
            "name": "Spar",
            "opening_hours": "Mo-Su 07:00-23:00",
            "shop": "supermarket"
          }
        },
        {
          "type": "node",
          "id": 1641239353,
          "lat": 56.3257464,
          "lon": 44.0121258,
          "tags": {
            "name": "Orehovskiy",
            "shop": "convenience"
          }
        },
        {
          "type": "relation",
          "id": 12702145,
          "center": {
            "lat": 51.4702343,
            "lon": 45.9190756
          },
          "members": [
            {
              "type": "way",
              "ref": 942131328,
              "role": "outer"
            },
            {
              "type": "way",
              "ref": 942131327,
              "role": "outer"
            }
          ],
          "tags": {
            "name": "Grozd",
            "shop": "supermarket",
            "type": "multipolygon"
          }
        }
      ]
    }
    ''';

    http.setResponse('.*', osmResp);

    final shopsRes = await overpass.fetchShops(
        bounds: CoordsBounds(
            southwest: Coord(lat: 0, lon: 0),
            northeast: Coord(lat: 1, lon: 1)));
    final shops = shopsRes.unwrap();
    expect(shops.length, equals(3));

    final expectedShop1 = OsmShop((e) => e
      ..osmUID = OsmUID.parse('1:992336735')
      ..name = 'Spar'
      ..type = 'supermarket'
      ..latitude = 56.3202185
      ..longitude = 44.0097146);
    final expectedShop2 = OsmShop((e) => e
      ..osmUID = OsmUID.parse('1:1641239353')
      ..name = 'Orehovskiy'
      ..type = 'convenience'
      ..latitude = 56.3257464
      ..longitude = 44.0121258);
    final expectedShop3 = OsmShop((e) => e
      ..osmUID = OsmUID.parse('2:12702145')
      ..name = 'Grozd'
      ..type = 'supermarket'
      ..latitude = 51.4702343
      ..longitude = 45.9190756);
    expect(shops, contains(expectedShop1));
    expect(shops, contains(expectedShop2));
    expect(shops, contains(expectedShop3));

    commons.expectSingleOverpassUrlQueried(); // See function comment
  });

  test('fetchShops empty response', () async {
    const osmResp = '''
    {
      "elements": [
      ]
    }
    ''';

    http.setResponse('.*', osmResp);

    final shopsRes = await overpass.fetchShops(
        bounds: CoordsBounds(
            southwest: Coord(lat: 0, lon: 0),
            northeast: Coord(lat: 1, lon: 1)));
    expect(shopsRes.unwrap().length, equals(0));

    // Empty response is still a successful response
    commons.expectSingleOverpassUrlQueried(); // See function comment
  });

  test('fetchShops not 200', () async {
    const osmResp = '''
    {
      "elements": [
      ]
    }
    ''';

    http.setResponse('.*', osmResp, responseCode: 400);

    final shopsRes = await overpass.fetchShops(
        bounds: CoordsBounds(
            southwest: Coord(lat: 0, lon: 0),
            northeast: Coord(lat: 1, lon: 1)));
    expect(shopsRes.unwrapErr(), equals(OpenStreetMapError.OTHER));

    // On HTTP errors all Overpass URLs expected to be queried 1 by 1
    commons.expectAllOverpassUrlsQueried(); // See function comment
  });

  test('fetchShops 400 for 1st and 200 for 2nd URL', () async {
    const okOsmResp = '''
    {
      "elements": [
      ]
    }
    ''';

    final forcedOrderedUrls = overpass.urls.values.toList();
    http.setResponse('.*${forcedOrderedUrls[0]}.*', okOsmResp,
        responseCode: 400);
    http.setResponse('.*${forcedOrderedUrls[1]}.*', okOsmResp,
        responseCode: 200);

    final shopsRes = await overpass.fetchShops(
        bounds: CoordsBounds(
            southwest: Coord(lat: 0, lon: 0),
            northeast: Coord(lat: 1, lon: 1)));
    expect(shopsRes.isOk, isTrue);

    // First request expected to be failed
    expect(http.getRequestsMatching('.*${forcedOrderedUrls[0]}.*').length, 1);
    // Second request expected to be successful
    expect(http.getRequestsMatching('.*${forcedOrderedUrls[1]}.*').length, 1);
  });

  test('fetchShops exception for 1st and 200 for 2nd URL', () async {
    const okOsmResp = '''
    {
      "elements": [
      ]
    }
    ''';

    final forcedOrderedUrls = overpass.urls.values.toList();
    http.setResponseException(
        '.*${forcedOrderedUrls[0]}.*', const SocketException(''));
    http.setResponse('.*${forcedOrderedUrls[1]}.*', okOsmResp,
        responseCode: 200);

    final shopsRes = await overpass.fetchShops(
        bounds: CoordsBounds(
            southwest: Coord(lat: 0, lon: 0),
            northeast: Coord(lat: 1, lon: 1)));
    expect(shopsRes.isOk, isTrue);

    // First request expected to be failed
    expect(http.getRequestsMatching('.*${forcedOrderedUrls[0]}.*').length, 1);
    // Second request expected to be successful
    expect(http.getRequestsMatching('.*${forcedOrderedUrls[1]}.*').length, 1);
  });

  test('fetchShops analytics events for different response codes', () async {
    for (var httpResponseCode = 100;
        httpResponseCode < 600;
        ++httpResponseCode) {
      analytics.clearEvents();
      http.reset();
      http.setResponse('.*', '', responseCode: httpResponseCode);

      await overpass.fetchShops(
          bounds: CoordsBounds(
              southwest: Coord(lat: 0, lon: 0),
              northeast: Coord(lat: 1, lon: 1)));

      // We expect analytics event only in case of 2 error codes
      if (httpResponseCode == 403 || httpResponseCode == 429) {
        for (final urlName in overpass.urls.keys) {
          expect(
              analytics
                  .wasEventSent('osm_${urlName}_failure_$httpResponseCode'),
              isTrue);
        }
        expect(analytics.allEvents().length, equals(overpass.urls.length));
      } else {
        expect(analytics.allEvents(), isEmpty);
      }
    }
  });

  test('fetchShops invalid json', () async {
    const osmResp = '''
    {
      "elements": [(((((((((
      ]
    }
    ''';

    http.setResponse('.*', osmResp);
    final shopsRes = await overpass.fetchShops(
        bounds: CoordsBounds(
            southwest: Coord(lat: 0, lon: 0),
            northeast: Coord(lat: 1, lon: 1)));
    expect(shopsRes.unwrapErr(), equals(OpenStreetMapError.OTHER));

    // Response with an invalid JSON is still a successful response
    commons.expectSingleOverpassUrlQueried(); // See function comment
  });

  test('fetchShops no elements in json', () async {
    const osmResp = '''
    {
      "elephants": [
      ]
    }
    ''';

    http.setResponse('.*', osmResp);
    final shopsRes = await overpass.fetchShops(
        bounds: CoordsBounds(
            southwest: Coord(lat: 0, lon: 0),
            northeast: Coord(lat: 1, lon: 1)));
    expect(shopsRes.unwrapErr(), equals(OpenStreetMapError.OTHER));

    // Empty response is still a successful response
    commons.expectSingleOverpassUrlQueried(); // See function comment
  });

  test('fetchShops shop without name', () async {
    const osmResp = '''
    {
      "elements": [
        {
          "type": "node",
          "id": 992336735,
          "lat": 56.3202185,
          "lon": 44.0097146,
          "tags": {
            "name": "Spar",
            "shop": "supermarket"
          }
        },
        {
          "type": "node",
          "id": 1641239353,
          "lat": 56.3257464,
          "lon": 44.0121258,
          "tags": {
            "shop": "convenience"
          }
        }
      ]
    }
    ''';

    http.setResponse('.*', osmResp);

    final shopsRes = await overpass.fetchShops(
        bounds: CoordsBounds(
            southwest: Coord(lat: 0, lon: 0),
            northeast: Coord(lat: 1, lon: 1)));
    final shops = shopsRes.unwrap();
    expect(shops.length, equals(1));
    expect(shops[0].name, 'Spar');
  });

  test('fetchShops shop without type', () async {
    const osmResp = '''
    {
      "elements": [
        {
          "type": "node",
          "id": 992336735,
          "lat": 56.3202185,
          "lon": 44.0097146,
          "tags": {
            "name": "Spar",
            "shop": "supermarket"
          }
        },
        {
          "type": "node",
          "id": 1641239353,
          "lat": 56.3257464,
          "lon": 44.0121258,
          "tags": {
            "name": "Orehovskiy"
          }
        }
      ]
    }
    ''';

    http.setResponse('.*', osmResp);

    final shopsRes = await overpass.fetchShops(
        bounds: CoordsBounds(
            southwest: Coord(lat: 0, lon: 0),
            northeast: Coord(lat: 1, lon: 1)));
    final shops = shopsRes.unwrap();
    expect(shops.length, equals(2));
    expect(shops[0].name, 'Spar');

    final expectedShop1 = OsmShop((e) => e
      ..osmUID = OsmUID.parse('1:992336735')
      ..name = 'Spar'
      ..type = 'supermarket'
      ..latitude = 56.3202185
      ..longitude = 44.0097146);
    final expectedShop2 = OsmShop((e) => e
      ..osmUID = OsmUID.parse('1:1641239353')
      ..name = 'Orehovskiy'
      ..type = null
      ..latitude = 56.3257464
      ..longitude = 44.0121258);
    expect(shops, contains(expectedShop1));
    expect(shops, contains(expectedShop2));
  });

  test('fetchShops shop without id', () async {
    const osmResp = '''
    {
      "elements": [
        {
          "type": "node",
          "id": 992336735,
          "lat": 56.3202185,
          "lon": 44.0097146,
          "tags": {
            "name": "Spar",
            "shop": "supermarket"
          }
        },
        {
          "type": "node",
          "lat": 56.3257464,
          "lon": 44.0121258,
          "tags": {
            "name": "Orehovskiy",
            "shop": "convenience"
          }
        }
      ]
    }
    ''';

    http.setResponse('.*', osmResp);

    final shopsRes = await overpass.fetchShops(
        bounds: CoordsBounds(
            southwest: Coord(lat: 0, lon: 0),
            northeast: Coord(lat: 1, lon: 1)));
    final shops = shopsRes.unwrap();
    expect(shops.length, equals(1));
    expect(shops[0].name, 'Spar');
  });

  test('fetchShops shop without lat', () async {
    const osmResp = '''
    {
      "elements": [
        {
          "type": "node",
          "id": 992336735,
          "lat": 56.3202185,
          "lon": 44.0097146,
          "tags": {
            "name": "Spar",
            "opening_hours": "Mo-Su 07:00-23:00",
            "shop": "supermarket"
          }
        },
        {
          "type": "node",
          "id": 1641239353,
          "lon": 44.0121258,
          "tags": {
            "name": "Orehovskiy",
            "shop": "convenience"
          }
        }
      ]
    }
    ''';

    http.setResponse('.*', osmResp);

    final shopsRes = await overpass.fetchShops(
        bounds: CoordsBounds(
            southwest: Coord(lat: 0, lon: 0),
            northeast: Coord(lat: 1, lon: 1)));
    final shops = shopsRes.unwrap();
    expect(shops.length, equals(1));
    expect(shops[0].name, 'Spar');
  });

  test('fetchShops shop without lon', () async {
    const osmResp = '''
    {
      "elements": [
        {
          "type": "node",
          "id": 992336735,
          "lat": 56.3202185,
          "lon": 44.0097146,
          "tags": {
            "name": "Spar",
            "opening_hours": "Mo-Su 07:00-23:00",
            "shop": "supermarket"
          }
        },
        {
          "type": "node",
          "id": 1641239353,
          "lat": 44.0121258,
          "tags": {
            "name": "Orehovskiy",
            "shop": "convenience"
          }
        }
      ]
    }
    ''';

    http.setResponse('.*', osmResp);

    final shopsRes = await overpass.fetchShops(
        bounds: CoordsBounds(
            southwest: Coord(lat: 0, lon: 0),
            northeast: Coord(lat: 1, lon: 1)));
    final shops = shopsRes.unwrap();
    expect(shops.length, equals(1));
    expect(shops[0].name, 'Spar');
  });

  test('fetchShops overpass URLs order', () async {
    // Note: in a general case testing order of items of a map is weird.
    // But [urls] is prioritized - first URLs are of highest priority
    // and we need to make sure order doesn't suddenly change.
    final forcedOrdered = overpass.urls.keys.toList();
    expect(forcedOrdered, equals(['main_overpass', 'kumi']));
  });

  test('fetchShops with OSM UIDs', () async {
    const nodeId = '992336735';
    const wayId = '1641239353';
    const relationId = '12702145';
    const osmResp = '''
    {
      "elements": [
        {
          "type": "node",
          "id": $nodeId,
          "lat": 56.3202185,
          "lon": 44.0097146,
          "tags": {
            "name": "Spar",
            "opening_hours": "Mo-Su 07:00-23:00",
            "shop": "supermarket"
          }
        },
        {
          "type": "way",
          "id": $wayId,
          "lat": 56.3257464,
          "lon": 44.0121258,
          "tags": {
            "name": "Orehovskiy",
            "shop": "convenience"
          }
        },
        {
          "type": "relation",
          "id": $relationId,
          "center": {
            "lat": 51.4702343,
            "lon": 45.9190756
          },
          "members": [
            {
              "type": "way",
              "ref": 942131327,
              "role": "outer"
            }
          ],
          "tags": {
            "name": "Grozd",
            "shop": "supermarket",
            "type": "multipolygon"
          }
        }
      ]
    }
    ''';

    http.setResponse('.*', osmResp);

    final shopsRes = await overpass.fetchShops(osmUIDs: [
      const OsmUID(OsmElementType.NODE, nodeId),
      const OsmUID(OsmElementType.WAY, wayId),
      const OsmUID(OsmElementType.RELATION, relationId),
    ]);
    final shops = shopsRes.unwrap();
    expect(shops.where((e) => e.osmUID.osmId == nodeId).length, equals(1));
    expect(shops.where((e) => e.osmUID.osmId == wayId).length, equals(1));
    expect(shops.where((e) => e.osmUID.osmId == relationId).length, equals(1));

    final requests = http.getRequestsMatching('.*');
    expect(requests.length, equals(1));

    final request = Uri.decodeFull(requests.first.url.toString());

    // Ensure our regex check type+id properly (there's no NODE with wayId)
    expect(request,
        isNot(matches(RegExp('.*node\\[shop~"[^"]*"\\]\\(id:$wayId\\);.*'))));
    // Check type+id pairs
    expect(request,
        matches(RegExp('.*node\\[shop~"[^"]*"\\]\\(id:$nodeId\\);.*')));
    expect(
        request, matches(RegExp('.*way\\[shop~"[^"]*"\\]\\(id:$wayId\\);.*')));
    expect(request,
        matches(RegExp('.*relation\\[shop~"[^"]*"\\]\\(id:$relationId\\);.*')));
  });

  test('fetchShops OSM UID for node only', () async {
    http.setResponse('.*', ' { "elements": [] } ');

    await overpass.fetchShops(osmUIDs: [
      const OsmUID(OsmElementType.NODE, '123'),
    ]);

    final requests = http.getRequestsMatching('.*');
    expect(requests.length, equals(1));
    final request = Uri.decodeFull(requests.first.url.toString());

    // Only Node expected to be found in the request
    expect(request, matches(RegExp(r'.*node\[shop.*')));
    expect(request, isNot(matches(RegExp(r'.*way\[shop.*'))));
    expect(request, isNot(matches(RegExp(r'.*relation\[shop.*'))));
  });

  test('fetchShops OSM UID for way only', () async {
    http.setResponse('.*', ' { "elements": [] } ');

    await overpass.fetchShops(osmUIDs: [
      const OsmUID(OsmElementType.WAY, '123'),
    ]);

    final requests = http.getRequestsMatching('.*');
    expect(requests.length, equals(1));
    final request = Uri.decodeFull(requests.first.url.toString());

    // Only Node expected to be found in the request
    expect(request, isNot(matches(RegExp(r'.*node\[shop.*'))));
    expect(request, matches(RegExp(r'.*way\[shop.*')));
    expect(request, isNot(matches(RegExp(r'.*relation\[shop.*'))));
  });

  test('fetchShops OSM UID for relation only', () async {
    http.setResponse('.*', ' { "elements": [] } ');

    await overpass.fetchShops(osmUIDs: [
      const OsmUID(OsmElementType.RELATION, '123'),
    ]);

    final requests = http.getRequestsMatching('.*');
    expect(requests.length, equals(1));
    final request = Uri.decodeFull(requests.first.url.toString());

    // Only Node expected to be found in the request
    expect(request, isNot(matches(RegExp(r'.*node\[shop.*'))));
    expect(request, isNot(matches(RegExp(r'.*way\[shop.*'))));
    expect(request, matches(RegExp(r'.*relation\[shop.*')));
  });
}
