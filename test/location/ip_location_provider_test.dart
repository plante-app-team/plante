import 'dart:io';
import 'dart:math';

import 'package:plante/location/ip_location_provider.dart';
import 'package:test/test.dart';

import '../fake_http_client.dart';

void main() {
  late FakeHttpClient httpClient;
  late IpLocationProvider ipLocationProvider;

  setUp(() async {
    httpClient = FakeHttpClient();
    ipLocationProvider = IpLocationProvider(httpClient);
  });

  test('good scenario', () async {
    httpClient.setResponse('.*ipregistry.*', '''
    {
      "location": {
        "longitude": 10,
        "latitude": 20
      }
    }
    ''');

    final pos = await ipLocationProvider.positionByIP();
    expect(pos, equals(const Point<double>(10, 20)));
  });

  test('IOException', () async {
    httpClient.setResponseException(
        '.*ipregistry.*', const SocketException(''));
    final pos = await ipLocationProvider.positionByIP();
    expect(pos, isNull);
  });

  test('invalid JSON', () async {
    httpClient.setResponse('.*ipregistry.*', '''
    {{{{{{{{{{{{
      "location": {
        "longitude": 10,
        "latitude": 20
      }
    }
    ''');
    final pos = await ipLocationProvider.positionByIP();
    expect(pos, isNull);
  });

  test('JSON without location', () async {
    httpClient.setResponse('.*ipregistry.*', '''
    {
      "longitude": 10,
      "latitude": 20
    }
    ''');
    final pos = await ipLocationProvider.positionByIP();
    expect(pos, isNull);
  });

  test('JSON without lat and lon', () async {
    httpClient.setResponse('.*ipregistry.*', '''
    {
      "location": {
        "x": 10,
        "y": 20
      }
    }
    ''');
    final pos = await ipLocationProvider.positionByIP();
    expect(pos, isNull);
  });

  test('lat and lon are not numbers', () async {
    httpClient.setResponse('.*ipregistry.*', '''
    {
      "location": {
        "longitude": "10",
        "latitude": "20"
      }
    }
    ''');
    final pos = await ipLocationProvider.positionByIP();
    expect(pos, isNull);
  });
}
