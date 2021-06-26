import 'dart:math';

import 'package:plante/outside/map/open_street_map.dart';
import 'package:plante/outside/map/osm_address.dart';
import 'package:plante/outside/map/osm_shop.dart';
import 'package:test/test.dart';

import '../../fake_http_client.dart';

void main() {
  late FakeHttpClient _http;
  late OpenStreetMap _osm;

  setUp(() async {
    _http = FakeHttpClient();
    _osm = OpenStreetMap(_http);
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

    _http.setResponse('.*', osmResp);

    final shopsRes = await _osm.fetchShops(const Point(0, 0), const Point(1, 1));
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
  });

  test('fetchShops empty response', () async {
    const osmResp = '''
    {
      "elements": [
      ]
    }
    ''';

    _http.setResponse('.*', osmResp);

    final shopsRes = await _osm.fetchShops(const Point(0, 0), const Point(1, 1));
    expect(shopsRes.unwrap().length, equals(0));
  });

  test('fetchShops not 200', () async {
    const osmResp = '''
    {
      "elements": [
      ]
    }
    ''';

    _http.setResponse('.*', osmResp, responseCode: 400);

    final shopsRes = await _osm.fetchShops(const Point(0, 0), const Point(1, 1));
    expect(shopsRes.unwrapErr(), equals(OpenStreetMapError.OTHER));
  });

  test('fetchShops invalid json', () async {
    const osmResp = '''
    {
      "elements": [(((((((((
      ]
    }
    ''';

    _http.setResponse('.*', osmResp);
    final shopsRes = await _osm.fetchShops(const Point(0, 0), const Point(1, 1));
    expect(shopsRes.unwrapErr(), equals(OpenStreetMapError.OTHER));
  });

  test('fetchShops no elements in json', () async {
    const osmResp = '''
    {
      "elephants": [
      ]
    }
    ''';

    _http.setResponse('.*', osmResp);
    final shopsRes = await _osm.fetchShops(const Point(0, 0), const Point(1, 1));
    expect(shopsRes.unwrapErr(), equals(OpenStreetMapError.OTHER));
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

    _http.setResponse('.*', osmResp);

    final shopsRes = await _osm.fetchShops(const Point(0, 0), const Point(1, 1));
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

    _http.setResponse('.*', osmResp);

    final shopsRes = await _osm.fetchShops(const Point(0, 0), const Point(1, 1));
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

    _http.setResponse('.*', osmResp);

    final shopsRes = await _osm.fetchShops(const Point(0, 0), const Point(1, 1));
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

    _http.setResponse('.*', osmResp);

    final shopsRes = await _osm.fetchShops(const Point(0, 0), const Point(1, 1));
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

    _http.setResponse('.*', osmResp);

    final shopsRes = await _osm.fetchShops(const Point(0, 0), const Point(1, 1));
    final shops = shopsRes.unwrap();
    expect(shops.length, equals(1));
    expect(shops[0].name, 'Spar');
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

    _http.setResponse('.*', osmResp);

    final addressRes = await _osm.fetchAddress(123, 321);
    final address = addressRes.unwrap();
    expect(address, equals(OsmAddress((e) => e
      ..neighbourhood = 'Nice neighbourhood'
      ..road = 'Broadway'
      ..cityDistrict = 'Nice district'
      ..houseNumber = '4')));
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

    _http.setResponse('.*', osmResp);

    final addressRes = await _osm.fetchAddress(123, 321);
    expect(addressRes.unwrapErr(), equals(OpenStreetMapError.OTHER));
  });

  test('fetchAddress response without neighborhood', () async {
    const osmResp = '''
    {
       "address":{
          "house_number":"4",
          "road":"Broadway",
          "city_district":"Nice district"
       }
    }
    ''';

    _http.setResponse('.*', osmResp);

    final addressRes = await _osm.fetchAddress(123, 321);
    final address = addressRes.unwrap();
    expect(address, equals(OsmAddress((e) => e
      ..neighbourhood = null
      ..road = 'Broadway'
      ..cityDistrict = 'Nice district'
      ..houseNumber = '4')));
  });

  test('fetchAddress response without road', () async {
    const osmResp = '''
    {
       "address":{
          "house_number":"4",
          "city_district":"Nice district",
          "neighbourhood":"Nice neighbourhood"
       }
    }
    ''';

    _http.setResponse('.*', osmResp);

    final addressRes = await _osm.fetchAddress(123, 321);
    final address = addressRes.unwrap();
    expect(address, equals(OsmAddress((e) => e
      ..neighbourhood = 'Nice neighbourhood'
      ..road = null
      ..cityDistrict = 'Nice district'
      ..houseNumber = '4')));
  });

  test('fetchAddress response without city district', () async {
    const osmResp = '''
    {
       "address":{
          "house_number":"4",
          "road":"Broadway",
          "neighbourhood":"Nice neighbourhood"
       }
    }
    ''';

    _http.setResponse('.*', osmResp);

    final addressRes = await _osm.fetchAddress(123, 321);
    final address = addressRes.unwrap();
    expect(address, equals(OsmAddress((e) => e
      ..neighbourhood = 'Nice neighbourhood'
      ..road = 'Broadway'
      ..cityDistrict = null
      ..houseNumber = '4')));
  });

  test('fetchAddress response without house number', () async {
    const osmResp = '''
    {
       "address":{
          "road":"Broadway",
          "city_district":"Nice district",
          "neighbourhood":"Nice neighbourhood"
       }
    }
    ''';

    _http.setResponse('.*', osmResp);

    final addressRes = await _osm.fetchAddress(123, 321);
    final address = addressRes.unwrap();
    expect(address, equals(OsmAddress((e) => e
      ..neighbourhood = 'Nice neighbourhood'
      ..road = 'Broadway'
      ..cityDistrict = 'Nice district'
      ..houseNumber = null)));
  });

  test('fetchAddress not 200', () async {
    const osmResp = '''
    {
       "address":{
          "road":"Broadway",
          "city_district":"Nice district",
          "neighbourhood":"Nice neighbourhood"
       }
    }
    ''';
    _http.setResponse('.*', osmResp, responseCode: 400);

    final addressRes = await _osm.fetchAddress(123, 321);
    expect(addressRes.unwrapErr(), equals(OpenStreetMapError.OTHER));
  });

  test('fetchAddress invalid json', () async {
    const osmResp = '''
    {{{{{{
       "address":{
          "road":"Broadway",
          "city_district":"Nice district",
          "neighbourhood":"Nice neighbourhood"
       }
    }
    ''';
    _http.setResponse('.*', osmResp);
    final addressRes = await _osm.fetchAddress(123, 321);
    expect(addressRes.unwrapErr(), equals(OpenStreetMapError.OTHER));
  });
}
