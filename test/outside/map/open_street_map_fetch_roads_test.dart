import 'package:plante/model/coord.dart';
import 'package:plante/model/coords_bounds.dart';
import 'package:plante/outside/map/open_street_map.dart';
import 'package:plante/outside/map/osm_road.dart';
import 'package:test/test.dart';

import '../../z_fakes/fake_analytics.dart';
import '../../z_fakes/fake_http_client.dart';
import 'open_street_map_test_commons.dart';

void main() {
  late OpenStreetMapTestCommons commons;
  late FakeHttpClient http;
  late FakeAnalytics analytics;
  late OpenStreetMap osm;

  setUp(() async {
    commons = OpenStreetMapTestCommons();
    await commons.setUp();
    http = commons.http;
    analytics = commons.analytics;
    osm = commons.osm;
  });

  /// Second, third, ... Overpass URLs are queried when a query to the previous
  /// has failed in a specific case.
  /// All overpass URLs would be expected to be queried when there are a lot
  /// of such failures.
  void expectAllOverpassUrlsQueried() {
    final forcedOrdered = osm.osmOverpassUrls.values.toList();
    for (var index = 0; index < forcedOrdered.length; ++index) {
      expect(http.getRequestsMatching('.*${forcedOrdered[index]}.*').length,
          equals(1));
    }
  }

  /// Other than the first Overpass URL are queried only on specific errors
  /// of the first URL.
  /// So if such a specific failure did not occur, or no failure occurred
  /// at all, then only a single URL would be expected to be queried.
  void expectSingleOverpassUrlQueried() {
    final forcedOrdered = osm.osmOverpassUrls.values.toList();
    for (var index = 0; index < forcedOrdered.length; ++index) {
      final expectedCount = index == 0 ? 1 : 0;
      expect(http.getRequestsMatching('.*${forcedOrdered[index]}.*').length,
          equals(expectedCount));
    }
  }

  test('fetchRoads good scenario', () async {
    const osmResp = '''
   {
      "elements":[
        {
          "type":"way",
          "id":10507539,
          "center":{
            "lat":51.5310266,
            "lon":45.9801769
          },
          "nodes":[
            342481779,
            3061855892
          ],
          "tags":{
            "highway":"primary",
            "name":"Polytechnical street",
            "oneway":"yes",
            "surface":"asphalt"
          }
        },
        {
          "type":"way",
          "id":10507577,
          "center":{
            "lat":51.5487303,
            "lon":46.0140838
          },
          "nodes":[
            3065980714,
            1165759201
          ],
          "tags":{
            "highway":"primary",
            "name":"Sokolova street"
          }
        }
      ]
    }
    ''';

    http.setResponse('.*', osmResp);

    final roadsRes = await osm.fetchRoads(CoordsBounds(
        southwest: Coord(lat: 0, lon: 0), northeast: Coord(lat: 1, lon: 1)));
    final roads = roadsRes.unwrap();
    expect(roads.length, equals(2));

    final expectedRoad1 = OsmRoad((e) => e
      ..osmId = '10507539'
      ..name = 'Polytechnical street'
      ..latitude = 51.5310266
      ..longitude = 45.9801769);
    final expectedRoad2 = OsmRoad((e) => e
      ..osmId = '10507577'
      ..name = 'Sokolova street'
      ..latitude = 51.5487303
      ..longitude = 46.0140838);
    expect(roads, contains(expectedRoad1));
    expect(roads, contains(expectedRoad2));

    expectSingleOverpassUrlQueried(); // See function comment
  });

  test('fetchRoads empty response', () async {
    const osmResp = '''
    {
      "elements": [
      ]
    }
    ''';

    http.setResponse('.*', osmResp);

    final roadsRes = await osm.fetchRoads(CoordsBounds(
        southwest: Coord(lat: 0, lon: 0), northeast: Coord(lat: 1, lon: 1)));
    expect(roadsRes.unwrap().length, equals(0));

    // Empty response is still a successful response
    expectSingleOverpassUrlQueried(); // See function comment
  });

  test('fetchRoads not 200', () async {
    const osmResp = '''
    {
      "elements": [
      ]
    }
    ''';

    http.setResponse('.*', osmResp, responseCode: 400);

    final roadsRes = await osm.fetchRoads(CoordsBounds(
        southwest: Coord(lat: 0, lon: 0), northeast: Coord(lat: 1, lon: 1)));
    expect(roadsRes.unwrapErr(), equals(OpenStreetMapError.OTHER));

    // On HTTP errors all Overpass URLs expected to be queried 1 by 1
    expectAllOverpassUrlsQueried(); // See function comment
  });

  test('fetchRoads 400 for 1st and 2nd URLs and 200 for 3rd', () async {
    const okOsmResp = '''
    {
      "elements": [
      ]
    }
    ''';

    final forcedOrderedUrls = osm.osmOverpassUrls.values.toList();
    http.setResponse('.*${forcedOrderedUrls[0]}.*', okOsmResp,
        responseCode: 400);
    http.setResponse('.*${forcedOrderedUrls[1]}.*', okOsmResp,
        responseCode: 400);
    http.setResponse('.*${forcedOrderedUrls[2]}.*', okOsmResp,
        responseCode: 200);
    http.setResponse('.*${forcedOrderedUrls[3]}.*', okOsmResp,
        responseCode: 400);

    final roadsRes = await osm.fetchRoads(CoordsBounds(
        southwest: Coord(lat: 0, lon: 0), northeast: Coord(lat: 1, lon: 1)));
    expect(roadsRes.isOk, isTrue);

    // First request expected to be failed
    expect(http.getRequestsMatching('.*${forcedOrderedUrls[0]}.*').length, 1);
    // Second request expected to be failed
    expect(http.getRequestsMatching('.*${forcedOrderedUrls[1]}.*').length, 1);
    // Third request expected to be successful
    expect(http.getRequestsMatching('.*${forcedOrderedUrls[2]}.*').length, 1);
    // Fourth request expected to be absent, because third was successful
    expect(http.getRequestsMatching('.*${forcedOrderedUrls[3]}.*').length, 0);
  });

  test('fetchRoads analytics events for different response codes', () async {
    for (var httpResponseCode = 100;
        httpResponseCode < 600;
        ++httpResponseCode) {
      analytics.clearEvents();
      http.reset();
      http.setResponse('.*', '', responseCode: httpResponseCode);

      await osm.fetchRoads(CoordsBounds(
          southwest: Coord(lat: 0, lon: 0), northeast: Coord(lat: 1, lon: 1)));

      // We expect analytics event only in case of 2 error codes
      if (httpResponseCode == 403 || httpResponseCode == 429) {
        for (final urlName in osm.osmOverpassUrls.keys) {
          expect(
              analytics
                  .wasEventSent('osm_${urlName}_failure_$httpResponseCode'),
              isTrue);
        }
        expect(
            analytics.allEvents().length, equals(osm.osmOverpassUrls.length));
      } else {
        expect(analytics.allEvents(), isEmpty);
      }
    }
  });

  test('fetchRoads invalid json', () async {
    const osmResp = '''
    {
      "elements": [(((((((((
      ]
    }
    ''';

    http.setResponse('.*', osmResp);
    final roadsRes = await osm.fetchRoads(CoordsBounds(
        southwest: Coord(lat: 0, lon: 0), northeast: Coord(lat: 1, lon: 1)));
    expect(roadsRes.unwrapErr(), equals(OpenStreetMapError.OTHER));

    // Response with an invalid JSON is still a successful response
    expectSingleOverpassUrlQueried(); // See function comment
  });

  test('fetchRoads no elements in json', () async {
    const osmResp = '''
    {
      "elephants": [
      ]
    }
    ''';

    http.setResponse('.*', osmResp);
    final roadsRes = await osm.fetchRoads(CoordsBounds(
        southwest: Coord(lat: 0, lon: 0), northeast: Coord(lat: 1, lon: 1)));
    expect(roadsRes.unwrapErr(), equals(OpenStreetMapError.OTHER));

    // Empty response is still a successful response
    expectSingleOverpassUrlQueried(); // See function comment
  });

  test('fetchRoads road without name', () async {
    const osmResp = '''
   {
      "elements":[
        {
          "type":"way",
          "id":10507539,
          "center":{
            "lat":51.5310266,
            "lon":45.9801769
          },
          "nodes":[
            342481779,
            3061855892
          ],
          "tags":{
            "highway":"primary",
            "name":"Polytechnical street",
            "oneway":"yes",
            "surface":"asphalt"
          }
        },
        {
          "type":"way",
          "id":10507577,
          "center":{
            "lat":51.5487303,
            "lon":46.0140838
          },
          "nodes":[
            3065980714,
            1165759201
          ],
          "tags":{
            "highway":"primary"
          }
        }
      ]
    }
    ''';

    http.setResponse('.*', osmResp);

    final roadsRes = await osm.fetchRoads(CoordsBounds(
        southwest: Coord(lat: 0, lon: 0), northeast: Coord(lat: 1, lon: 1)));
    final roads = roadsRes.unwrap();
    expect(roads.length, equals(1));
    expect(roads[0].name, 'Polytechnical street');
  });

  test('fetchRoads shop without id', () async {
    const osmResp = '''
   {
      "elements":[
        {
          "type":"way",
          "id":10507539,
          "center":{
            "lat":51.5310266,
            "lon":45.9801769
          },
          "nodes":[
            342481779,
            3061855892
          ],
          "tags":{
            "highway":"primary",
            "name":"Polytechnical street",
            "oneway":"yes",
            "surface":"asphalt"
          }
        },
        {
          "type":"way",
          "center":{
            "lat":51.5487303,
            "lon":46.0140838
          },
          "nodes":[
            3065980714,
            1165759201
          ],
          "tags":{
            "highway":"primary",
            "name":"Sokolova street"
          }
        }
      ]
    }
    ''';

    http.setResponse('.*', osmResp);

    final roadsRes = await osm.fetchRoads(CoordsBounds(
        southwest: Coord(lat: 0, lon: 0), northeast: Coord(lat: 1, lon: 1)));
    final roads = roadsRes.unwrap();
    expect(roads.length, equals(1));
    expect(roads[0].name, 'Polytechnical street');
  });

  test('fetchRoads road without lat', () async {
    const osmResp = '''
   {
      "elements":[
        {
          "type":"way",
          "id":10507539,
          "center":{
            "lat":51.5310266,
            "lon":45.9801769
          },
          "nodes":[
            342481779,
            3061855892
          ],
          "tags":{
            "highway":"primary",
            "name":"Polytechnical street",
            "oneway":"yes",
            "surface":"asphalt"
          }
        },
        {
          "type":"way",
          "id":10507577,
          "center":{
            "lon":46.0140838
          },
          "nodes":[
            3065980714,
            1165759201
          ],
          "tags":{
            "highway":"primary",
            "name":"Sokolova street"
          }
        }
      ]
    }
    ''';

    http.setResponse('.*', osmResp);

    final roadsRes = await osm.fetchRoads(CoordsBounds(
        southwest: Coord(lat: 0, lon: 0), northeast: Coord(lat: 1, lon: 1)));
    final roads = roadsRes.unwrap();
    expect(roads.length, equals(1));
    expect(roads[0].name, 'Polytechnical street');
  });

  test('fetchRoads shop without lon', () async {
    const osmResp = '''
   {
      "elements":[
        {
          "type":"way",
          "id":10507539,
          "center":{
            "lat":51.5310266,
            "lon":45.9801769
          },
          "nodes":[
            342481779,
            3061855892
          ],
          "tags":{
            "highway":"primary",
            "name":"Polytechnical street",
            "oneway":"yes",
            "surface":"asphalt"
          }
        },
        {
          "type":"way",
          "id":10507577,
          "center":{
            "lat":51.5487303
          },
          "nodes":[
            3065980714,
            1165759201
          ],
          "tags":{
            "highway":"primary",
            "name":"Sokolova street"
          }
        }
      ]
    }
    ''';

    http.setResponse('.*', osmResp);

    final roadsRes = await osm.fetchRoads(CoordsBounds(
        southwest: Coord(lat: 0, lon: 0), northeast: Coord(lat: 1, lon: 1)));
    final roads = roadsRes.unwrap();
    expect(roads.length, equals(1));
    expect(roads[0].name, 'Polytechnical street');
  });

  test('fetchRoads overpass URLs order', () async {
    // Note: in a general case testing order of items of a map is weird.
    // But [osmOverpassUrls] is prioritized - first URLs are of highest priority
    // and we need to make sure order doesn't suddenly change.
    final forcedOrdered = osm.osmOverpassUrls.keys.toList();
    expect(forcedOrdered, equals(['lz4', 'z', 'kumi', 'taiwan']));
  });
}
