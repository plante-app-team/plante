import 'package:plante/model/coord.dart';
import 'package:plante/model/coords_bounds.dart';
import 'package:plante/outside/map/open_street_map.dart';
import 'package:plante/outside/map/osm_address.dart';
import 'package:plante/outside/map/osm_shop.dart';
import 'package:test/test.dart';

import '../../z_fakes/fake_analytics.dart';
import '../../z_fakes/fake_http_client.dart';

void main() {
  late FakeHttpClient http;
  late FakeAnalytics analytics;
  late OpenStreetMap osm;

  setUp(() async {
    http = FakeHttpClient();
    analytics = FakeAnalytics();
    osm = OpenStreetMap(http, analytics);
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

    final shopsRes = await osm.fetchShops(CoordsBounds(
        southwest: Coord(lat: 0, lon: 0), northeast: Coord(lat: 1, lon: 1)));
    final shops = shopsRes.unwrap();
    expect(shops.length, equals(3));

    final expectedShop1 = OsmShop((e) => e
      ..osmId = '992336735'
      ..name = 'Spar'
      ..type = 'supermarket'
      ..latitude = 56.3202185
      ..longitude = 44.0097146);
    final expectedShop2 = OsmShop((e) => e
      ..osmId = '1641239353'
      ..name = 'Orehovskiy'
      ..type = 'convenience'
      ..latitude = 56.3257464
      ..longitude = 44.0121258);
    final expectedShop3 = OsmShop((e) => e
      ..osmId = '12702145'
      ..name = 'Grozd'
      ..type = 'supermarket'
      ..latitude = 51.4702343
      ..longitude = 45.9190756);
    expect(shops, contains(expectedShop1));
    expect(shops, contains(expectedShop2));
    expect(shops, contains(expectedShop3));

    expectSingleOverpassUrlQueried(); // See function comment
  });

  test('fetchShops empty response', () async {
    const osmResp = '''
    {
      "elements": [
      ]
    }
    ''';

    http.setResponse('.*', osmResp);

    final shopsRes = await osm.fetchShops(CoordsBounds(
        southwest: Coord(lat: 0, lon: 0), northeast: Coord(lat: 1, lon: 1)));
    expect(shopsRes.unwrap().length, equals(0));

    // Empty response is still a successful response
    expectSingleOverpassUrlQueried(); // See function comment
  });

  test('fetchShops not 200', () async {
    const osmResp = '''
    {
      "elements": [
      ]
    }
    ''';

    http.setResponse('.*', osmResp, responseCode: 400);

    final shopsRes = await osm.fetchShops(CoordsBounds(
        southwest: Coord(lat: 0, lon: 0), northeast: Coord(lat: 1, lon: 1)));
    expect(shopsRes.unwrapErr(), equals(OpenStreetMapError.OTHER));

    // On HTTP errors all Overpass URLs expected to be queried 1 by 1
    expectAllOverpassUrlsQueried(); // See function comment
  });

  test('fetchShops 400 for 1st and 2nd URLs and 200 for 3rd', () async {
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

    final shopsRes = await osm.fetchShops(CoordsBounds(
        southwest: Coord(lat: 0, lon: 0), northeast: Coord(lat: 1, lon: 1)));
    expect(shopsRes.isOk, isTrue);

    // First request expected to be failed
    expect(http.getRequestsMatching('.*${forcedOrderedUrls[0]}.*').length, 1);
    // Second request expected to be failed
    expect(http.getRequestsMatching('.*${forcedOrderedUrls[1]}.*').length, 1);
    // Third request expected to be successful
    expect(http.getRequestsMatching('.*${forcedOrderedUrls[2]}.*').length, 1);
    // Fourth request expected to be absent, because third was successful
    expect(http.getRequestsMatching('.*${forcedOrderedUrls[3]}.*').length, 0);
  });

  test('fetchShops analytics events for different response codes', () async {
    for (var httpResponseCode = 100;
        httpResponseCode < 600;
        ++httpResponseCode) {
      analytics.clearEvents();
      http.reset();
      http.setResponse('.*', '', responseCode: httpResponseCode);

      await osm.fetchShops(CoordsBounds(
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

  test('fetchShops invalid json', () async {
    const osmResp = '''
    {
      "elements": [(((((((((
      ]
    }
    ''';

    http.setResponse('.*', osmResp);
    final shopsRes = await osm.fetchShops(CoordsBounds(
        southwest: Coord(lat: 0, lon: 0), northeast: Coord(lat: 1, lon: 1)));
    expect(shopsRes.unwrapErr(), equals(OpenStreetMapError.OTHER));

    // Response with an invalid JSON is still a successful response
    expectSingleOverpassUrlQueried(); // See function comment
  });

  test('fetchShops no elements in json', () async {
    const osmResp = '''
    {
      "elephants": [
      ]
    }
    ''';

    http.setResponse('.*', osmResp);
    final shopsRes = await osm.fetchShops(CoordsBounds(
        southwest: Coord(lat: 0, lon: 0), northeast: Coord(lat: 1, lon: 1)));
    expect(shopsRes.unwrapErr(), equals(OpenStreetMapError.OTHER));

    // Empty response is still a successful response
    expectSingleOverpassUrlQueried(); // See function comment
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

    final shopsRes = await osm.fetchShops(CoordsBounds(
        southwest: Coord(lat: 0, lon: 0), northeast: Coord(lat: 1, lon: 1)));
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

    final shopsRes = await osm.fetchShops(CoordsBounds(
        southwest: Coord(lat: 0, lon: 0), northeast: Coord(lat: 1, lon: 1)));
    final shops = shopsRes.unwrap();
    expect(shops.length, equals(2));
    expect(shops[0].name, 'Spar');

    final expectedShop1 = OsmShop((e) => e
      ..osmId = '992336735'
      ..name = 'Spar'
      ..type = 'supermarket'
      ..latitude = 56.3202185
      ..longitude = 44.0097146);
    final expectedShop2 = OsmShop((e) => e
      ..osmId = '1641239353'
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

    final shopsRes = await osm.fetchShops(CoordsBounds(
        southwest: Coord(lat: 0, lon: 0), northeast: Coord(lat: 1, lon: 1)));
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

    final shopsRes = await osm.fetchShops(CoordsBounds(
        southwest: Coord(lat: 0, lon: 0), northeast: Coord(lat: 1, lon: 1)));
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

    final shopsRes = await osm.fetchShops(CoordsBounds(
        southwest: Coord(lat: 0, lon: 0), northeast: Coord(lat: 1, lon: 1)));
    final shops = shopsRes.unwrap();
    expect(shops.length, equals(1));
    expect(shops[0].name, 'Spar');
  });

  test('fetchShops overpass URLs order', () async {
    // Note: in a general case testing order of items of a map is weird.
    // But [osmOverpassUrls] is prioritized - first URLs are of highest priority
    // and we need to make sure order doesn't suddenly change.
    final forcedOrdered = osm.osmOverpassUrls.keys.toList();
    expect(forcedOrdered, equals(['lz4', 'z', 'kumi', 'taiwan']));
  });

  test('fetchAddress good scenario', () async {
    const osmResp = '''
    {
       "place_id": 116516349,
       "licence":"Data OpenStreetMap contributors, ODbL 1.0. https://osm.org/copyright",
       "osm_type":"way",
       "osm_id":119305350,
       "lat":"51.575351850000004",
       "lon":"46.07271786053919",
       "display_name":"4, Broadway, Nice district, City center, City 17, Unknown state, Unknown Federal District, 410018, England",
       "address":{
          "house_number":"4",
          "road":"Broadway",
          "suburb":"City center",
          "city_district":"Nice district",
          "neighbourhood":"Nice neighbourhood",
          "city":"City 17",
          "state":"Unknown State",
          "region":"Unknown Federal District",
          "postcode":"410018",
          "country":"England",
          "country_code":"en"
       },
       "boundingbox":[
          "51.5750167",
          "51.5757347",
          "46.0724705",
          "46.0733751"
       ]
    }
    ''';

    http.setResponse('.*', osmResp);

    final addressRes = await osm.fetchAddress(123, 321);
    final address = addressRes.unwrap();
    expect(
        address,
        equals(OsmAddress((e) => e
          ..neighbourhood = 'Nice neighbourhood'
          ..road = 'Broadway'
          ..cityDistrict = 'Nice district'
          ..houseNumber = '4'
          ..countryCode = 'en')));
  });

  test('fetchAddress response without address', () async {
    const osmResp = '''
    {
       "place_id": 116516349,
       "licence":"Data OpenStreetMap contributors, ODbL 1.0. https://osm.org/copyright",
       "osm_type":"way",
       "osm_id":119305350,
       "lat":"51.575351850000004",
       "lon":"46.07271786053919",
       "display_name":"4, Broadway, Nice district, City center, City 17, Unknown state, Unknown Federal District, 410018, England",
       "boundingbox":[
          "51.5750167",
          "51.5757347",
          "46.0724705",
          "46.0733751"
       ]
    }
    ''';

    http.setResponse('.*', osmResp);

    final addressRes = await osm.fetchAddress(123, 321);
    expect(addressRes.unwrapErr(), equals(OpenStreetMapError.OTHER));
  });

  test('fetchAddress response without neighborhood', () async {
    const osmResp = '''
    {
       "address":{
          "house_number":"4",
          "road":"Broadway",
          "city_district":"Nice district",
          "country_code":"en"
       }
    }
    ''';

    http.setResponse('.*', osmResp);

    final addressRes = await osm.fetchAddress(123, 321);
    final address = addressRes.unwrap();
    expect(
        address,
        equals(OsmAddress((e) => e
          ..neighbourhood = null
          ..road = 'Broadway'
          ..cityDistrict = 'Nice district'
          ..houseNumber = '4'
          ..countryCode = 'en')));
  });

  test('fetchAddress response without road', () async {
    const osmResp = '''
    {
       "address":{
          "house_number":"4",
          "city_district":"Nice district",
          "neighbourhood":"Nice neighbourhood",
          "country_code":"en"
       }
    }
    ''';

    http.setResponse('.*', osmResp);

    final addressRes = await osm.fetchAddress(123, 321);
    final address = addressRes.unwrap();
    expect(
        address,
        equals(OsmAddress((e) => e
          ..neighbourhood = 'Nice neighbourhood'
          ..road = null
          ..cityDistrict = 'Nice district'
          ..houseNumber = '4'
          ..countryCode = 'en')));
  });

  test('fetchAddress response without city district', () async {
    const osmResp = '''
    {
       "address":{
          "house_number":"4",
          "road":"Broadway",
          "neighbourhood":"Nice neighbourhood",
          "country_code":"en"
       }
    }
    ''';

    http.setResponse('.*', osmResp);

    final addressRes = await osm.fetchAddress(123, 321);
    final address = addressRes.unwrap();
    expect(
        address,
        equals(OsmAddress((e) => e
          ..neighbourhood = 'Nice neighbourhood'
          ..road = 'Broadway'
          ..cityDistrict = null
          ..houseNumber = '4'
          ..countryCode = 'en')));
  });

  test('fetchAddress response without house number', () async {
    const osmResp = '''
    {
       "address":{
          "road":"Broadway",
          "city_district":"Nice district",
          "neighbourhood":"Nice neighbourhood",
          "country_code":"en"
       }
    }
    ''';

    http.setResponse('.*', osmResp);

    final addressRes = await osm.fetchAddress(123, 321);
    final address = addressRes.unwrap();
    expect(
        address,
        equals(OsmAddress((e) => e
          ..neighbourhood = 'Nice neighbourhood'
          ..road = 'Broadway'
          ..cityDistrict = 'Nice district'
          ..houseNumber = null
          ..countryCode = 'en')));
  });

  test('fetchAddress response without country code', () async {
    const osmResp = '''
    {
       "address":{
          "house_number":"4",
          "road":"Broadway",
          "city_district":"Nice district",
          "neighbourhood":"Nice neighbourhood"
       }
    }
    ''';

    http.setResponse('.*', osmResp);

    final addressRes = await osm.fetchAddress(123, 321);
    final address = addressRes.unwrap();
    expect(
        address,
        equals(OsmAddress((e) => e
          ..neighbourhood = 'Nice neighbourhood'
          ..road = 'Broadway'
          ..cityDistrict = 'Nice district'
          ..houseNumber = '4'
          ..countryCode = null)));
  });

  test('fetchAddress not 200', () async {
    const osmResp = '''
    {
       "address":{
          "road":"Broadway",
          "city_district":"Nice district",
          "neighbourhood":"Nice neighbourhood",
          "country_code":"en"
       }
    }
    ''';
    http.setResponse('.*', osmResp, responseCode: 400);

    final addressRes = await osm.fetchAddress(123, 321);
    expect(addressRes.unwrapErr(), equals(OpenStreetMapError.OTHER));
  });

  test('fetchAddress invalid json', () async {
    const osmResp = '''
    {{{{{{
       "address":{
          "road":"Broadway",
          "city_district":"Nice district",
          "neighbourhood":"Nice neighbourhood",
          "country_code":"en"
       }
    }
    ''';
    http.setResponse('.*', osmResp);
    final addressRes = await osm.fetchAddress(123, 321);
    expect(addressRes.unwrapErr(), equals(OpenStreetMapError.OTHER));
  });
}
