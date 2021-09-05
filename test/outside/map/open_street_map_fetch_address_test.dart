import 'package:plante/outside/map/open_street_map.dart';
import 'package:plante/outside/map/osm_address.dart';
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
          ..city = 'City 17'
          ..houseNumber = '4'
          ..countryCode = 'en'
          ..country = 'England')));
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
          "city":"City 17",
          "country":"England",
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
          ..countryCode = 'en'
          ..city = 'City 17'
          ..country = 'England')));
  });

  test('fetchAddress response without road', () async {
    const osmResp = '''
    {
       "address":{
          "city":"City 17",
          "country":"England",
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
          ..countryCode = 'en'
          ..city = 'City 17'
          ..country = 'England')));
  });

  test('fetchAddress response without city district', () async {
    const osmResp = '''
    {
       "address":{
          "city":"City 17",
          "country":"England",
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
          ..countryCode = 'en'
          ..city = 'City 17'
          ..country = 'England')));
  });

  test('fetchAddress response without house number', () async {
    const osmResp = '''
    {
       "address":{
          "city":"City 17",
          "country":"England",
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
          ..countryCode = 'en'
          ..city = 'City 17'
          ..country = 'England')));
  });

  test('fetchAddress response without country code', () async {
    const osmResp = '''
    {
       "address":{
          "city":"City 17",
          "country":"England",
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
          ..countryCode = null
          ..city = 'City 17'
          ..country = 'England')));
  });

  test('fetchAddress response without city', () async {
    const osmResp = '''
    {
       "address":{
          "country":"England",
          "house_number":"4",
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
          ..houseNumber = '4'
          ..countryCode = 'en'
          ..city = null
          ..country = 'England')));
  });

  test('fetchAddress response without country', () async {
    const osmResp = '''
    {
       "address":{
          "city":"City 17",
          "house_number":"4",
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
          ..houseNumber = '4'
          ..countryCode = 'en'
          ..city = 'City 17'
          ..country = null)));
  });

  test('fetchAddress not 200', () async {
    const osmResp = '''
    {
       "address":{
          "city":"City 17",
          "country":"England",
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
          "city":"City 17",
          "country":"England",
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
