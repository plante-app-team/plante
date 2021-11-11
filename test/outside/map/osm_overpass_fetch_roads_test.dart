import 'dart:io';

import 'package:plante/model/coord.dart';
import 'package:plante/model/coords_bounds.dart';
import 'package:plante/outside/map/open_street_map.dart';
import 'package:plante/outside/map/osm_overpass.dart';
import 'package:plante/outside/map/osm_road.dart';
import 'package:test/test.dart';

import '../../z_fakes/fake_analytics.dart';
import '../../z_fakes/fake_http_client.dart';
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

    final roadsRes = await overpass.fetchRoads(CoordsBounds(
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

    commons.expectSingleOverpassUrlQueried(); // See function comment
  });

  test('fetchRoads empty response', () async {
    const osmResp = '''
    {
      "elements": [
      ]
    }
    ''';

    http.setResponse('.*', osmResp);

    final roadsRes = await overpass.fetchRoads(CoordsBounds(
        southwest: Coord(lat: 0, lon: 0), northeast: Coord(lat: 1, lon: 1)));
    expect(roadsRes.unwrap().length, equals(0));

    // Empty response is still a successful response
    commons.expectSingleOverpassUrlQueried(); // See function comment
  });

  test('fetchRoads not 200', () async {
    const osmResp = '''
    {
      "elements": [
      ]
    }
    ''';

    http.setResponse('.*', osmResp, responseCode: 400);

    final roadsRes = await overpass.fetchRoads(CoordsBounds(
        southwest: Coord(lat: 0, lon: 0), northeast: Coord(lat: 1, lon: 1)));
    expect(roadsRes.unwrapErr(), equals(OpenStreetMapError.OTHER));

    // On HTTP errors all Overpass URLs expected to be queried 1 by 1
    commons.expectAllOverpassUrlsQueried(); // See function comment
  });

  test('fetchRoads 400 for 1st and 200 2nd URL', () async {
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

    final roadsRes = await overpass.fetchRoads(CoordsBounds(
        southwest: Coord(lat: 0, lon: 0), northeast: Coord(lat: 1, lon: 1)));
    expect(roadsRes.isOk, isTrue);

    // First request expected to be failed
    expect(http.getRequestsMatching('.*${forcedOrderedUrls[0]}.*').length, 1);
    // Second request expected to be successful
    expect(http.getRequestsMatching('.*${forcedOrderedUrls[1]}.*').length, 1);
  });

  test('fetchRoads exception for 1st and 200 2nd URL', () async {
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

    final roadsRes = await overpass.fetchRoads(CoordsBounds(
        southwest: Coord(lat: 0, lon: 0), northeast: Coord(lat: 1, lon: 1)));
    expect(roadsRes.isOk, isTrue);

    // First request expected to be failed
    expect(http.getRequestsMatching('.*${forcedOrderedUrls[0]}.*').length, 1);
    // Second request expected to be successful
    expect(http.getRequestsMatching('.*${forcedOrderedUrls[1]}.*').length, 1);
  });

  test('fetchRoads analytics events for different response codes', () async {
    for (var httpResponseCode = 100;
        httpResponseCode < 600;
        ++httpResponseCode) {
      analytics.clearEvents();
      http.reset();
      http.setResponse('.*', '', responseCode: httpResponseCode);

      await overpass.fetchRoads(CoordsBounds(
          southwest: Coord(lat: 0, lon: 0), northeast: Coord(lat: 1, lon: 1)));

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

  test('fetchRoads invalid json', () async {
    const osmResp = '''
    {
      "elements": [(((((((((
      ]
    }
    ''';

    http.setResponse('.*', osmResp);
    final roadsRes = await overpass.fetchRoads(CoordsBounds(
        southwest: Coord(lat: 0, lon: 0), northeast: Coord(lat: 1, lon: 1)));
    expect(roadsRes.unwrapErr(), equals(OpenStreetMapError.OTHER));

    // Response with an invalid JSON is still a successful response
    commons.expectSingleOverpassUrlQueried(); // See function comment
  });

  test('fetchRoads no elements in json', () async {
    const osmResp = '''
    {
      "elephants": [
      ]
    }
    ''';

    http.setResponse('.*', osmResp);
    final roadsRes = await overpass.fetchRoads(CoordsBounds(
        southwest: Coord(lat: 0, lon: 0), northeast: Coord(lat: 1, lon: 1)));
    expect(roadsRes.unwrapErr(), equals(OpenStreetMapError.OTHER));

    // Empty response is still a successful response
    commons.expectSingleOverpassUrlQueried(); // See function comment
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

    final roadsRes = await overpass.fetchRoads(CoordsBounds(
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

    final roadsRes = await overpass.fetchRoads(CoordsBounds(
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

    final roadsRes = await overpass.fetchRoads(CoordsBounds(
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

    final roadsRes = await overpass.fetchRoads(CoordsBounds(
        southwest: Coord(lat: 0, lon: 0), northeast: Coord(lat: 1, lon: 1)));
    final roads = roadsRes.unwrap();
    expect(roads.length, equals(1));
    expect(roads[0].name, 'Polytechnical street');
  });

  test('fetchRoads overpass URLs order', () async {
    // Note: in a general case testing order of items of a map is weird.
    // But [osmOverpassUrls] is prioritized - first URLs are of highest priority
    // and we need to make sure order doesn't suddenly change.
    final forcedOrdered = overpass.urls.keys.toList();
    expect(forcedOrdered, equals(['main_overpass', 'kumi']));
  });
}
