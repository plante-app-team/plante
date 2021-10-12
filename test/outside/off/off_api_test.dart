import 'package:plante/outside/off/off_api.dart';
import 'package:test/test.dart';

import '../../z_fakes/fake_http_client.dart';
import '../../z_fakes/fake_settings.dart';

void main() {
  late OffApi offApi;
  late FakeSettings fakeSettings;

  setUp(() async {
    fakeSettings = FakeSettings();
    offApi = OffApi(fakeSettings, FakeHttpClient());
  });

  test('fetch shops from off for belgium', () async {
    final FakeHttpClient fakeClient = offApi.httpClient as FakeHttpClient;
    fakeClient.setResponse('.openfoodfacts.org/stores.json', '''{
      "count": 2,
      "tags": [
        {
          "id": "delhaize",
          "known": 0,
          "name": "Delhaize",
          "products": 10293,
          "url": "https://be.openfoodfacts.org/winkel/delhaize"
        },
        {
          "id": "colruyt",
          "known": 0,
          "name": "Colruyt",
          "products": 3399,
          "url": "https://be.openfoodfacts.org/winkel/colruyt"
        }
      ]
    }''');
    final result = await offApi.getShopsForLocation('be');
    expect(result.length, equals(2));
  });

  test('fetch products from off for delhaize belgium', () async {
    final FakeHttpClient fakeClient = offApi.httpClient as FakeHttpClient;
    fakeClient.setResponse(
        '.openfoodfacts.org/api/v2/search\\\?ingredients_analysis_tags=en:vegan\\\&stores_tags=Delhaize',
        '''{
      "count": 2,
      "page" : 1,
      "page_count" : 2,
      "page_size" : 20,
      "products": [
        {
          "product_name": "product1",
          "code" : "1234"
        },
        {
          "product_name": "product2",
          "code":"4321"
        }
      ]
    }''');
    final result =
        await offApi.getVeganProductsForShop('be', 'Delhaize', 1);
    expect(result.products?.length, equals(2));
    expect(result.count, equals(2));
    expect(result.page, equals(1));
  }, skip: false);

  test('fetch shops from off for belgium - integration', () async {
    final result = await offApi.getShopsForLocation('be');
    expect(result.length, greaterThanOrEqualTo(1));
  }, skip: true);

  test('fetch products from off for delhaize belgium - integration', () async {
    final result =
        await offApi.getVeganProductsForShop('be', 'Delhaize',1);
    expect(result.products?.length, greaterThanOrEqualTo(1));
  }, skip: true);
}
