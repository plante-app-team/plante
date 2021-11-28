import 'dart:io';

import 'package:openfoodfacts/openfoodfacts.dart' as off;
import 'package:openfoodfacts/utils/ProductListQueryConfiguration.dart';
import 'package:plante/outside/off/off_api.dart';
import 'package:plante/outside/off/off_shop.dart';
import 'package:test/test.dart';

import '../../z_fakes/fake_http_client.dart';
import '../../z_fakes/fake_settings.dart';

void main() {
  late OffApi offApi;
  late FakeSettings fakeSettings;
  late FakeHttpClient httpClient;

  setUp(() async {
    fakeSettings = FakeSettings();
    httpClient = FakeHttpClient();
    offApi = OffApi(fakeSettings, httpClient);
  });

  test('getProducts - integration', () async {
    final barcodes = [
      '4810410075316',
      '4680019562018',
      '4650057962767',
      '4606038053801',
      '4605825003791',
      '4601481831907',
      '4604248018269',
      '4607056943990',
      '4607018913788',
      '4607018913849',
      '4640071950192',
      '4606038066177',
      '8001300303503',
      '7340011499527',
      '4600699501398',
      '8595564502203',
      '8710400339977',
      '8718885890082',
      '4607015232578',
      '4607035890574',
      '2100100098506',
      '3017620422003',
      '4604248011949',
      '4810450001962',
      '4670008494383',
      '4601172231269',
      '4600699505426',
      '4690388108656',
      '5900020023315',
      '4607124142409',
      '4600452020487',
      '5900617003454',
      '4000417025005',
      '4680046724540',
      '4680019563442',
      '4627107450086',
      '0016229906436',
      '0016229906207',
      '5449000027474',
      '4600080282004',
      '4612742721165',
      '9001414603703',
      '4607010735548',
      '4660043853740',
      '4607061256412',
      '4602248010245',
      '4605932001284',
      '4607124141259',
      '4607005400185',
      '8410313323215'
    ];

    final obtainedBarcodes = <String>[];
    var page = 1;
    while (true) {
      final configuration = ProductListQueryConfiguration(barcodes,
          page: page, sortOption: off.SortOption.CREATED);

      final result = await offApi.getProductList(configuration);
      if (result.products == null || result.products!.isEmpty) {
        break;
      }
      final newBarcodes = result.products!.map((e) => e.barcode!);
      expect(newBarcodes.any(obtainedBarcodes.contains), isFalse);
      obtainedBarcodes.addAll(newBarcodes);
      page += 1;
    }
    // We want to test pagination mechanism so we expect >1 pages
    expect(page, greaterThan(1));
    expect(obtainedBarcodes.toSet(), equals(barcodes.toSet()));
  });

  test('get shops json network exceptions', () async {
    httpClient.setResponseException(
        '.openfoodfacts.org/stores.json', const SocketException(''));
    final result = await offApi.getShopsJsonForCountry('be');
    expect(result.unwrapErr(), equals(OffRestApiError.NETWORK));
  });

  test('get shops json error response', () async {
    httpClient.setResponse('.openfoodfacts.org/stores.json', '',
        responseCode: 500);
    final result = await offApi.getShopsJsonForCountry('be');
    expect(result.unwrapErr(), equals(OffRestApiError.OTHER));
  });

  test('get shops json invalid JSON', () async {
    const invalidJson = '''{
      "count": 2,
      "tags": [[[[[[[[[]
    }''';
    httpClient.setResponse('.openfoodfacts.org/stores.json', invalidJson);
    final result = await offApi.getShopsJsonForCountry('be');
    // We don't expect `result` to be Err, because it's a JSON string and
    // we expect it to be passed as-is, without validation.
    expect(result.unwrap(), equals(invalidJson));
  });

  test('get shops json from off for belgium', () async {
    const json = '''
    {
      "count":2,
      "tags":[
        {
          "id":"delhaize",
          "known":0,
          "name":"Delhaize",
          "products":10342,
          "url":"https://be.openfoodfacts.org/winkel/delhaize"
        },
        {
          "id":"colruyt",
          "known":0,
          "name":"Colruyt",
          "products":3410,
          "url":"https://be.openfoodfacts.org/winkel/colruyt"
        }
      ]
    }
    ''';
    httpClient.setResponse('.*stores.json.*', json);

    final result = await offApi.getShopsJsonForCountry('be');
    expect(result.unwrap(), equals(json));
  });

  test('get vegan barcodes by ingredients analysis', () async {
    httpClient.setResponse('api/v2/search', '''
    {
      "count":3,
      "page":1,
      "page_count":3,
      "page_size":1000,
      "skip":0,
      "products":[
        {"code":"3046920022651"},
        {"code":"3046920022606"},
        {"code":"3229820021027"}
      ]
    }
    ''');

    final shop = OffShop((e) => e.id = 'spar');
    final result = await offApi
        .getBarcodesVeganByIngredients('ru', shop, ['en:banana', 'en:cocoa']);
    expect(result.unwrap(),
        equals(['3046920022651', '3046920022606', '3229820021027']));

    final requests = httpClient.getRequestsMatching('.*');
    expect(requests.length, equals(1), reason: requests.toString());
    final url = requests.single.url.toString();
    expect(url, contains('ru.openfoodfacts.org'));
    expect(url, contains('api/v2/search'));
    expect(url, contains('ingredients_analysis_tags=en%3Avegan'));
    expect(url, isNot(contains('labels_tags=en%3Avegan')));
    expect(url, contains('categories_tags=en%3Abanana%7Cen%3Acocoa'));
    expect(url, contains('stores_tags=spar'));
  });

  test('get vegan barcodes by labels', () async {
    httpClient.setResponse('api/v2/search', '''
    {
      "count":3,
      "page":1,
      "page_count":3,
      "page_size":1000,
      "skip":0,
      "products":[
        {"code":"3046920022651"},
        {"code":"3046920022606"},
        {"code":"3229820021027"}
      ]
    }
    ''');

    final shop = OffShop((e) => e.id = 'spar');
    final result = await offApi.getBarcodesVeganByLabel('ru', shop);
    expect(result.unwrap(),
        equals(['3046920022651', '3046920022606', '3229820021027']));

    final requests = httpClient.getRequestsMatching('.*');
    expect(requests.length, equals(1), reason: requests.toString());
    final url = requests.single.url.toString();
    expect(url, contains('ru.openfoodfacts.org'));
    expect(url, contains('api/v2/search'));
    expect(url, isNot(contains('ingredients_analysis_tags=en%3Avegan')));
    expect(url, contains('labels_tags=en%3Avegan'));
    expect(url, isNot(contains('categories_tags')));
    expect(url, contains('stores_tags=spar'));
  });
}
