import 'dart:io';

import 'package:plante/location/ip_location_provider.dart';
import 'package:plante/model/coord.dart';
import 'package:test/test.dart';

import '../z_fakes/fake_http_client.dart';

void main() {
  late FakeHttpClient httpClient;
  late IpLocationProvider ipLocationProvider;

  setUp(() async {
    httpClient = FakeHttpClient();
    ipLocationProvider = IpLocationProvider(httpClient);
  });

  test('good scenario', () async {
    httpClient.setResponse('.*freegeoip.*', '''
    {
      "longitude": 10,
      "latitude": 20
    }
    ''');

    final pos = await ipLocationProvider.positionByIP();
    expect(pos, equals(Coord(lat: 20, lon: 10)));
  });

  test('IOException', () async {
    httpClient.setResponseException('.*freegeoip.*', const SocketException(''));
    final pos = await ipLocationProvider.positionByIP();
    expect(pos, isNull);
  });

  test('invalid JSON', () async {
    httpClient.setResponse('.*freegeoip.*', '''
    {{{{{{{{{{{{
      "longitude": 10,
      "latitude": 20
    }
    ''');
    final pos = await ipLocationProvider.positionByIP();
    expect(pos, isNull);
  });

  test('JSON without lat and lon', () async {
    httpClient.setResponse('.*freegeoip.*', '''
    {
      "x": 10,
      "y": 20
    }
    ''');
    final pos = await ipLocationProvider.positionByIP();
    expect(pos, isNull);
  });

  test('lat and lon are not numbers', () async {
    httpClient.setResponse('.*freegeoip.*', '''
    {
      "longitude": "10",
      "latitude": "20"
    }
    ''');
    final pos = await ipLocationProvider.positionByIP();
    expect(pos, isNull);
  });
}
