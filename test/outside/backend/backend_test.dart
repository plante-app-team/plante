import 'dart:convert';
import 'dart:io';

import 'package:mockito/mockito.dart';
import 'package:plante/model/coord.dart';
import 'package:plante/model/coords_bounds.dart';
import 'package:plante/model/lang_code.dart';
import 'package:plante/model/shop.dart';
import 'package:plante/model/user_params.dart';
import 'package:plante/model/veg_status.dart';
import 'package:plante/model/veg_status_source.dart';
import 'package:plante/outside/backend/backend.dart';
import 'package:plante/outside/backend/backend_error.dart';
import 'package:plante/outside/backend/backend_product.dart';
import 'package:plante/outside/backend/backend_products_at_shop.dart';
import 'package:plante/outside/backend/backend_shop.dart';
import 'package:plante/outside/map/osm_shop.dart';
import 'package:plante/outside/map/osm_uid.dart';
import 'package:test/test.dart';

import '../../common_mocks.mocks.dart';
import '../../z_fakes/fake_analytics.dart';
import '../../z_fakes/fake_http_client.dart';
import '../../z_fakes/fake_settings.dart';
import '../../z_fakes/fake_user_params_controller.dart';

void main() {
  final fakeSettings = FakeSettings();
  late FakeAnalytics analytics;

  setUp(() {
    analytics = FakeAnalytics();
  });

  test('successful login/registration', () async {
    final httpClient = FakeHttpClient();
    final userParamsController = FakeUserParamsController();
    final backend =
        Backend(analytics, userParamsController, httpClient, fakeSettings);

    httpClient.setResponse('.*login_or_register_user.*', '''
      {
        "user_id": "123",
        "client_token": "321"
      }
    ''');

    final result = await backend.loginOrRegister(googleIdToken: 'google ID');
    final expectedParams = UserParams((v) => v
      ..backendId = '123'
      ..backendClientToken = '321');
    expect(result.unwrap(), equals(expectedParams));
  });

  test('check whether logged in', () async {
    final httpClient = FakeHttpClient();
    final userParamsController = FakeUserParamsController();
    final backend =
        Backend(analytics, userParamsController, httpClient, fakeSettings);

    expect(await backend.isLoggedIn(), isFalse);
    await userParamsController
        .setUserParams(UserParams((v) => v.backendId = '123'));
    expect(await backend.isLoggedIn(), isFalse);
    await userParamsController
        .setUserParams(UserParams((v) => v.backendClientToken = '321'));
    expect(await backend.isLoggedIn(), isTrue);
  });

  test('login when already logged in', () async {
    final httpClient = FakeHttpClient();
    final existingParams = UserParams((v) => v
      ..backendId = '123'
      ..backendClientToken = '321'
      ..name = 'Bob');
    final userParamsController = FakeUserParamsController();
    await userParamsController.setUserParams(existingParams);

    final backend =
        Backend(analytics, userParamsController, httpClient, fakeSettings);
    final result = await backend.loginOrRegister(googleIdToken: 'google ID');
    expect(result.unwrap(), equals(existingParams));
  });

  test('registration failure - email not verified', () async {
    final httpClient = FakeHttpClient();
    final userParamsController = FakeUserParamsController();
    final backend =
        Backend(analytics, userParamsController, httpClient, fakeSettings);

    httpClient.setResponse('.*login_or_register_user.*', '''
      {
        "error": "google_email_not_verified"
      }
    ''');

    final result = await backend.loginOrRegister(googleIdToken: 'google ID');
    expect(result.unwrapErr().errorKind,
        equals(BackendErrorKind.GOOGLE_EMAIL_NOT_VERIFIED));
  });

  test('registration request not 200', () async {
    final httpClient = FakeHttpClient();
    final userParamsController = FakeUserParamsController();
    final backend =
        Backend(analytics, userParamsController, httpClient, fakeSettings);
    httpClient.setResponse('.*login_or_register_user.*', '', responseCode: 500);
    final result = await backend.loginOrRegister(googleIdToken: 'google ID');
    expect(result.unwrapErr().errorKind, equals(BackendErrorKind.OTHER));
  });

  test('registration request bad json', () async {
    final httpClient = FakeHttpClient();
    final userParamsController = FakeUserParamsController();
    final backend =
        Backend(analytics, userParamsController, httpClient, fakeSettings);
    httpClient.setResponse('.*login_or_register_user.*', '{{{{bad bad bad}');
    final result = await backend.loginOrRegister(googleIdToken: 'google ID');
    expect(result.unwrapErr().errorKind, equals(BackendErrorKind.INVALID_JSON));
  });

  test('registration request json error', () async {
    final httpClient = FakeHttpClient();
    final userParamsController = FakeUserParamsController();
    final backend =
        Backend(analytics, userParamsController, httpClient, fakeSettings);
    httpClient.setResponse('.*login_or_register_user.*', '''
      {
        "error": "some_error"
      }
    ''');
    final result = await backend.loginOrRegister(googleIdToken: 'google ID');
    expect(result.unwrapErr().errorKind, equals(BackendErrorKind.OTHER));
  });

  test('registration network error', () async {
    final httpClient = FakeHttpClient();
    final userParamsController = FakeUserParamsController();
    final backend =
        Backend(analytics, userParamsController, httpClient, fakeSettings);
    httpClient.setResponseException(
        '.*login_or_register_user.*', const SocketException(''));
    final result = await backend.loginOrRegister(googleIdToken: 'google ID');
    expect(
        result.unwrapErr().errorKind, equals(BackendErrorKind.NETWORK_ERROR));
  });

  test('observer notified about server errors', () async {
    final httpClient = FakeHttpClient();
    final userParamsController = FakeUserParamsController();
    final backend =
        Backend(analytics, userParamsController, httpClient, fakeSettings);
    final observer = MockBackendObserver();
    backend.addObserver(observer);

    httpClient.setResponse('.*login_or_register_user.*', '''
      {
        "error": "some_error"
      }
    ''');

    verifyNever(observer.onBackendError(any));
    await backend.loginOrRegister(googleIdToken: 'google ID');
    verify(observer.onBackendError(any));
  });

  test('update user params', () async {
    final httpClient = FakeHttpClient();
    final userParamsController = await _initUserParams();
    final initialParams = userParamsController.cachedUserParams!;

    final backend =
        Backend(analytics, userParamsController, httpClient, fakeSettings);
    httpClient.setResponse('.*update_user_data.*', ''' { "result": "ok" } ''');

    final updatedParams = initialParams.rebuild((v) => v
      ..name = 'Jack'
      ..langsPrioritized.replace(['en', 'nl']));
    final result = await backend.updateUserParams(updatedParams);
    expect(result.isOk, isTrue);

    final requests = httpClient.getRequestsMatching('.*update_user_data.*');
    expect(requests.length, equals(1));
    final request = requests[0];

    expect(request.url.queryParameters['name'], equals('Jack'));
    expect(
        request.url
            .toString()
            .contains('langsPrioritized=en&langsPrioritized=nl'),
        isTrue);
  });

  test('update user params has client token', () async {
    final httpClient = FakeHttpClient();
    final userParamsController = FakeUserParamsController();
    final initialParams = UserParams((v) => v
      ..backendId = '123'
      ..name = 'Bob'
      ..backendClientToken = 'my_token');
    await userParamsController.setUserParams(initialParams);

    final backend =
        Backend(analytics, userParamsController, httpClient, fakeSettings);
    httpClient.setResponse('.*update_user_data.*', ''' { "result": "ok" } ''');

    await backend
        .updateUserParams(initialParams.rebuild((v) => v.name = 'Nora'));
    final request = httpClient.getRequestsMatching('.*update_user_data.*')[0];

    expect(request.headers['Authorization'], equals('Bearer my_token'));
  });

  test('update user params when not authorized', () async {
    final httpClient = FakeHttpClient();
    final userParamsController = FakeUserParamsController();
    final initialParams = UserParams((v) => v
      ..backendId = '123'
      ..name = 'Bob');
    await userParamsController.setUserParams(initialParams);

    final backend =
        Backend(analytics, userParamsController, httpClient, fakeSettings);
    httpClient.setResponse('.*update_user_data.*', ''' { "result": "ok" } ''');

    await backend
        .updateUserParams(initialParams.rebuild((v) => v.name = 'Nora'));
    final request = httpClient.getRequestsMatching('.*update_user_data.*')[0];

    expect(request.headers['Authorization'], equals(null));
  });

  test('update user params network error', () async {
    final httpClient = FakeHttpClient();
    final userParamsController = await _initUserParams();
    final initialParams = userParamsController.cachedUserParams!;

    final backend =
        Backend(analytics, userParamsController, httpClient, fakeSettings);
    httpClient.setResponseException(
        '.*update_user_data.*', const HttpException(''));

    final updatedParams = initialParams.rebuild((v) => v.name = 'Jack');
    final result = await backend.updateUserParams(updatedParams);
    expect(result.unwrapErr().errorKind, BackendErrorKind.NETWORK_ERROR);
  });

  test('request product', () async {
    final httpClient = FakeHttpClient();
    final backend =
        Backend(analytics, await _initUserParams(), httpClient, fakeSettings);
    httpClient.setResponse('.*products_data.*', '''
     {
       "last_page": true,
       "products": [
         {
           "barcode": "123",
           "vegan_status": "${VegStatus.negative.name}",
           "vegan_status_source": "${VegStatusSource.moderator.name}"
         }
       ]
     }
      ''');

    final result = await backend.requestProducts(['123'], 0);
    final product = result.unwrap().products.first;
    final expectedProduct = BackendProduct((v) => v
      ..barcode = '123'
      ..veganStatus = VegStatus.negative.name
      ..veganStatusSource = VegStatusSource.moderator.name);
    expect(product, equals(expectedProduct));

    final requests = httpClient.getRequestsMatching('.*products_data.*');
    expect(requests.length, equals(1));
    final request = requests[0];
    expect(request.headers['Authorization'], equals('Bearer aaa'));
  });

  test('request many products', () async {
    final httpClient = FakeHttpClient();
    final backend =
        Backend(analytics, await _initUserParams(), httpClient, fakeSettings);

    httpClient.setResponse('.*products_data.*page=0.*', '''
         {
           "last_page": false,
           "products": [
             {
               "barcode": "123",
               "vegan_status": "${VegStatus.negative.name}",
               "vegan_status_source": "${VegStatusSource.moderator.name}"
             }
           ]
         }
          ''');
    httpClient.setResponse('.*products_data.*page=1.*', '''
         {
           "last_page": true,
           "products": [
             {
               "barcode": "124",
               "vegan_status": "${VegStatus.negative.name}",
               "vegan_status_source": "${VegStatusSource.moderator.name}"
             }
           ]
         }
          ''');
    httpClient.setResponse('.*products_data.*page=2.*', '''
         {
           "last_page": true,
           "products": []
         }
          ''');

    var resultWrapped = await backend.requestProducts(['123', '124'], 0);
    var result = resultWrapped.unwrap();
    expect(result.lastPage, isFalse);
    expect(
        result.products,
        equals([
          BackendProduct((v) => v
            ..barcode = '123'
            ..veganStatus = VegStatus.negative.name
            ..veganStatusSource = VegStatusSource.moderator.name)
        ]));

    resultWrapped = await backend.requestProducts(['123', '124'], 1);
    result = resultWrapped.unwrap();
    expect(result.lastPage, isTrue);
    expect(
        result.products,
        equals([
          BackendProduct((v) => v
            ..barcode = '124'
            ..veganStatus = VegStatus.negative.name
            ..veganStatusSource = VegStatusSource.moderator.name)
        ]));

    resultWrapped = await backend.requestProducts(['123', '124'], 2);
    result = resultWrapped.unwrap();
    expect(result.lastPage, isTrue);
    expect(result.products, isEmpty);

    final requests = httpClient.getRequestsMatching('.*products_data.*');
    expect(requests.length, equals(3));
    expect(requests[0].headers['Authorization'], equals('Bearer aaa'));
    expect(requests[1].headers['Authorization'], equals('Bearer aaa'));
    expect(requests[2].headers['Authorization'], equals('Bearer aaa'));
  });

  test('request product not found', () async {
    final httpClient = FakeHttpClient();
    final backend =
        Backend(analytics, await _initUserParams(), httpClient, fakeSettings);
    httpClient.setResponse('.*products_data.*', '''
         {
           "last_page": true,
           "products": []
         }
          ''');

    final result = await backend.requestProducts(['123'], 0);
    final products = result.unwrap().products;
    expect(products, isEmpty);
  });

  test('request product http error', () async {
    final httpClient = FakeHttpClient();
    final backend =
        Backend(analytics, await _initUserParams(), httpClient, fakeSettings);
    httpClient.setResponse('.*products_data.*', '', responseCode: 500);

    final result = await backend.requestProducts(['123'], 0);
    expect(result.isErr, isTrue);

    final requests = httpClient.getRequestsMatching('.*products_data.*');
    expect(requests.length, equals(1));
    final request = requests[0];
    expect(request.headers['Authorization'], equals('Bearer aaa'));
  });

  test('request product invalid JSON', () async {
    final httpClient = FakeHttpClient();
    final backend =
        Backend(analytics, await _initUserParams(), httpClient, fakeSettings);
    httpClient.setResponse('.*products_data.*', '''
         {{{{{{{{{{{{{{{{{{
           "last_page": true,
           "products": []
         }
          ''');

    final result = await backend.requestProducts(['123'], 0);
    expect(result.unwrapErr().errorKind, BackendErrorKind.INVALID_JSON);

    final requests = httpClient.getRequestsMatching('.*products_data.*');
    expect(requests.length, equals(1));
    final request = requests[0];
    expect(request.headers['Authorization'], equals('Bearer aaa'));
  });

  test('request product network exception', () async {
    final httpClient = FakeHttpClient();
    final backend =
        Backend(analytics, await _initUserParams(), httpClient, fakeSettings);
    httpClient.setResponseException(
        '.*products_data.*', const SocketException(''));

    final result = await backend.requestProducts(['123'], 0);
    expect(result.unwrapErr().errorKind, BackendErrorKind.NETWORK_ERROR);
  });

  test('create update product', () async {
    final httpClient = FakeHttpClient();
    final backend =
        Backend(analytics, await _initUserParams(), httpClient, fakeSettings);
    httpClient
        .setResponse('.*create_update_product.*', ''' { "result": "ok" } ''');

    final result = await backend.createUpdateProduct('123',
        veganStatus: VegStatus.negative,
        changedLangs: [LangCode.en, LangCode.ru]);
    expect(result.isOk, isTrue);

    final requests =
        httpClient.getRequestsMatching('.*create_update_product.*');
    expect(requests.length, equals(1));
    final request = requests[0];
    expect(request.url.queryParameters['veganStatus'],
        equals(VegStatus.negative.name));
    expect(request.url.toString().contains('langs=en&langs=ru'), isTrue);
    expect(request.headers['Authorization'], equals('Bearer aaa'));
  });

  test('create update product without langs', () async {
    final httpClient = FakeHttpClient();
    final backend =
        Backend(analytics, await _initUserParams(), httpClient, fakeSettings);
    httpClient
        .setResponse('.*create_update_product.*', ''' { "result": "ok" } ''');

    final result = await backend.createUpdateProduct('123',
        veganStatus: VegStatus.negative, changedLangs: []);
    expect(result.isOk, isTrue);

    final requests =
        httpClient.getRequestsMatching('.*create_update_product.*');
    expect(requests.length, equals(1));
    final request = requests[0];
    expect(request.url.queryParameters['veganStatus'],
        equals(VegStatus.negative.name));
    expect(request.url.toString().contains('langs'), isFalse);
    expect(request.headers['Authorization'], equals('Bearer aaa'));
  });

  test('create update product http error', () async {
    final httpClient = FakeHttpClient();
    final backend =
        Backend(analytics, await _initUserParams(), httpClient, fakeSettings);
    httpClient.setResponse('.*create_update_product.*', '', responseCode: 500);

    final result = await backend.createUpdateProduct('123',
        veganStatus: VegStatus.negative);
    expect(result.isErr, isTrue);
  });

  test('create update product invalid JSON response', () async {
    final httpClient = FakeHttpClient();
    final backend =
        Backend(analytics, await _initUserParams(), httpClient, fakeSettings);
    httpClient.setResponse('.*create_update_product.*', '{{{{}');

    final result = await backend.createUpdateProduct('123',
        veganStatus: VegStatus.negative);
    expect(result.isErr, isTrue);
  });

  test('create update product network error', () async {
    final httpClient = FakeHttpClient();
    final backend =
        Backend(analytics, await _initUserParams(), httpClient, fakeSettings);
    httpClient.setResponseException(
        '.*create_update_product.*', const SocketException(''));

    final result = await backend.createUpdateProduct('123',
        veganStatus: VegStatus.negative);
    expect(result.unwrapErr().errorKind, BackendErrorKind.NETWORK_ERROR);
  });

  test('send report', () async {
    final httpClient = FakeHttpClient();
    final backend =
        Backend(analytics, await _initUserParams(), httpClient, fakeSettings);
    httpClient.setResponse('.*make_report.*', ''' { "result": "ok" } ''');

    final result = await backend.sendReport('123', "that's a baaaad product");
    expect(result.isOk, isTrue);
  });

  test('send report analytics', () async {
    final httpClient = FakeHttpClient();
    final backend =
        Backend(analytics, await _initUserParams(), httpClient, fakeSettings);
    httpClient.setResponse('.*make_report.*', ''' { "result": "ok" } ''');

    expect(analytics.allEvents(), equals([]));
    await backend.sendReport('123', "that's a baaaad product");
    expect(analytics.allEvents().length, equals(1));
    expect(
        analytics.firstSentEvent('report_sent').second,
        equals({
          'barcode': '123',
          'report': "that's a baaaad product",
        }));
  });

  test('send report network error', () async {
    final httpClient = FakeHttpClient();
    final backend =
        Backend(analytics, await _initUserParams(), httpClient, fakeSettings);
    httpClient.setResponseException(
        '.*make_report.*', const SocketException(''));

    final result = await backend.sendReport('123', "that's a baaaad product");
    expect(result.unwrapErr().errorKind, BackendErrorKind.NETWORK_ERROR);
  });

  test('mobile app config obtaining', () async {
    final httpClient = FakeHttpClient();
    final backend =
        Backend(analytics, await _initUserParams(), httpClient, fakeSettings);
    httpClient.setResponse('.*mobile_app_config.*', '''
        {
          "user_data": { "name": "Bob Kelso", "user_id": "123" },
          "nominatim_enabled": false
        }
        ''');

    final result = await backend.mobileAppConfig();
    expect(result.isOk, isTrue);

    final obtainedConfig = result.unwrap();
    expect(obtainedConfig.nominatimEnabled, isFalse);
    final obtainedParams = obtainedConfig.remoteUserParams;
    expect(obtainedParams.name, equals('Bob Kelso'));
    expect(obtainedParams.backendId, equals('123'));
  });

  test('mobile app config obtaining invalid JSON response', () async {
    final httpClient = FakeHttpClient();
    final backend =
        Backend(analytics, await _initUserParams(), httpClient, fakeSettings);
    httpClient.setResponse('.*mobile_app_config.*', '''
        {{{{{{{{{{{{{{{{{
          "user_data": { "name": "Bob Kelso", "user_id": "123" },
          "nominatim_enabled": false
        }
        ''');

    final result = await backend.mobileAppConfig();
    expect(result.unwrapErr().errorKind, equals(BackendErrorKind.INVALID_JSON));
  });

  test('mobile app config obtaining network error', () async {
    final httpClient = FakeHttpClient();
    final backend =
        Backend(analytics, await _initUserParams(), httpClient, fakeSettings);
    httpClient.setResponseException(
        '.*mobile_app_config.*', const SocketException(''));

    final result = await backend.mobileAppConfig();
    expect(
        result.unwrapErr().errorKind, equals(BackendErrorKind.NETWORK_ERROR));
  });

  test('requesting products at shops', () async {
    final httpClient = FakeHttpClient();
    final backend =
        Backend(analytics, await _initUserParams(), httpClient, fakeSettings);
    httpClient.setResponse('.*products_at_shops_data.*', '''
          {
            "results_v2" : {
              "1:8711880917" : {
                "shop_osm_uid" : "1:8711880917",
                "products" : [ {
                  "server_id" : 23,
                  "barcode" : "4605932001284",
                  "vegan_status" : "positive",
                  "vegan_status_source" : "community"
                } ],
                "products_last_seen_utc" : { }
              },
              "1:8771781029" : {
                "shop_osm_uid" : "1:8771781029",
                "products" : [ {
                  "server_id" : 16,
                  "barcode" : "4612742721165",
                  "vegan_status" : "positive",
                  "vegan_status_source" : "community"
                }, {
                  "server_id" : 17,
                  "barcode" : "9001414603703",
                  "vegan_status" : "positive",
                  "vegan_status_source" : "community"
                } ],
                "products_last_seen_utc" : {
                  "4612742721165": 123456
                }
              }
            }
          }
        ''');

    final result = await backend.requestProductsAtShops(
        ['1:8711880917', '1:8771781029'].map((e) => OsmUID.parse(e)));
    expect(result.isOk, isTrue);

    final shops = result.unwrap();
    expect(shops.length, equals(2));

    final BackendProductsAtShop shop1;
    final BackendProductsAtShop shop2;
    if (shops[0].osmUID.toString() == '1:8711880917') {
      shop1 = shops[0];
      shop2 = shops[1];
    } else {
      shop1 = shops[1];
      shop2 = shops[0];
    }

    final expectedProduct1 = BackendProduct.fromJson(jsonDecode('''
    {
      "server_id" : 23,
      "barcode" : "4605932001284",
      "vegan_status" : "positive",
      "vegan_status_source" : "community"
    }''') as Map<String, dynamic>);
    final expectedProduct2 = BackendProduct.fromJson(jsonDecode('''
    {
      "server_id" : 16,
      "barcode" : "4612742721165",
      "vegan_status" : "positive",
      "vegan_status_source" : "community"
    }''') as Map<String, dynamic>);
    final expectedProduct3 = BackendProduct.fromJson(jsonDecode('''
    {
      "server_id" : 17,
      "barcode" : "9001414603703",
      "vegan_status" : "positive",
      "vegan_status_source" : "community"
    }''') as Map<String, dynamic>);

    expect(shop1.products.length, equals(1));
    expect(shop1.products[0], equals(expectedProduct1));

    expect(shop2.products.length, equals(2));
    expect(shop2.products[0], equals(expectedProduct2));
    expect(shop2.products[1], equals(expectedProduct3));

    expect(shop1.productsLastSeenUtc.length, equals(0));
    expect(shop2.productsLastSeenUtc.length, equals(1));
    expect(shop2.productsLastSeenUtc['4612742721165'], equals(123456));
  });

  test('requesting products at shops empty response', () async {
    final httpClient = FakeHttpClient();
    final backend =
        Backend(analytics, await _initUserParams(), httpClient, fakeSettings);
    httpClient.setResponse('.*products_at_shops_data.*', '''
          {
            "results_v2" : {}
          }
        ''');

    final result = await backend.requestProductsAtShops(
        ['1:8711880917', '1:8771781029'].map((e) => OsmUID.parse(e)));
    expect(result.unwrap().length, equals(0));
  });

  test('requesting products at shops invalid JSON response', () async {
    final httpClient = FakeHttpClient();
    final backend =
        Backend(analytics, await _initUserParams(), httpClient, fakeSettings);
    httpClient.setResponse('.*products_at_shops_data.*', '''
          {{{{{{{{{{{{{{{{{{{{{{
            "results_v2" : {
              "1:8711880917" : {
                "shop_osm_uid" : "1:8711880917",
                "products" : [ {
                  "server_id" : 23,
                  "barcode" : "4605932001284",
                  "vegan_status" : "positive",
                  "vegan_status_source" : "community"
                } ],
                "products_last_seen_utc" : { }
              }
            }
          }
        ''');

    final result = await backend.requestProductsAtShops(
        ['1:8711880917', '1:8771781029'].map((e) => OsmUID.parse(e)));
    expect(result.unwrapErr().errorKind, equals(BackendErrorKind.INVALID_JSON));
  });

  test('requesting products at shops JSON without results response', () async {
    final httpClient = FakeHttpClient();
    final backend =
        Backend(analytics, await _initUserParams(), httpClient, fakeSettings);
    httpClient.setResponse('.*products_at_shops_data.*', '''
          {
            "rezzzults" : {}
          }
        ''');

    final result = await backend.requestProductsAtShops(
        ['1:8711880917', '1:8771781029'].map((e) => OsmUID.parse(e)));
    expect(result.unwrapErr().errorKind, equals(BackendErrorKind.INVALID_JSON));
  });

  test('requesting products at shops network error', () async {
    final httpClient = FakeHttpClient();
    final backend =
        Backend(analytics, await _initUserParams(), httpClient, fakeSettings);
    httpClient.setResponseException(
        '.*products_at_shops_data.*', const SocketException(''));

    final result = await backend.requestProductsAtShops(
        ['1:8711880917', '1:8771781029'].map((e) => OsmUID.parse(e)));
    expect(
        result.unwrapErr().errorKind, equals(BackendErrorKind.NETWORK_ERROR));
  });

  test('requesting shops by UIDs', () async {
    final httpClient = FakeHttpClient();
    final backend =
        Backend(analytics, await _initUserParams(), httpClient, fakeSettings);
    httpClient.setResponse('.*/shops_data/.*', '''
          {
            "results_v2" : {
              "1:8711880917" : {
                "osm_uid" : "1:8711880917",
                "products_count" : 1
              },
              "1:8771781029" : {
                "osm_uid" : "1:8771781029",
                "products_count" : 2
              }
            }
          }
        ''');

    final result = await backend.requestShopsByOsmUIDs(
        ['1:8711880917', '1:8771781029'].map((e) => OsmUID.parse(e)));
    expect(result.isOk, isTrue);

    final shops = result.unwrap();
    expect(shops.length, equals(2));

    final BackendShop shop1;
    final BackendShop shop2;
    if (shops[0].osmUID == OsmUID.parse('1:8711880917')) {
      shop1 = shops[0];
      shop2 = shops[1];
    } else {
      shop1 = shops[1];
      shop2 = shops[0];
    }

    expect(shop1.productsCount, equals(1));
    expect(shop2.productsCount, equals(2));
  });

  test('requesting shops by UIDs empty response', () async {
    final httpClient = FakeHttpClient();
    final backend =
        Backend(analytics, await _initUserParams(), httpClient, fakeSettings);
    httpClient.setResponse('.*/shops_data/.*', '''
          {
            "results_v2" : {}
          }
        ''');

    final result = await backend.requestShopsByOsmUIDs(
        ['1:8711880917', '1:8771781029'].map((e) => OsmUID.parse(e)));
    expect(result.unwrap().length, equals(0));
  });

  test('requesting shops by UIDs invalid JSON response', () async {
    final httpClient = FakeHttpClient();
    final backend =
        Backend(analytics, await _initUserParams(), httpClient, fakeSettings);
    httpClient.setResponse('.*/shops_data/.*', '''
          {{{{{{{{{{{{{{{{{{{{{{
            "results_v2" : {
            }
          }
        ''');

    final result = await backend.requestShopsByOsmUIDs(
        ['1:8711880917', '1:8771781029'].map((e) => OsmUID.parse(e)));
    expect(result.unwrapErr().errorKind, equals(BackendErrorKind.INVALID_JSON));
  });

  test('requesting shops by UIDs JSON without results response', () async {
    final httpClient = FakeHttpClient();
    final backend =
        Backend(analytics, await _initUserParams(), httpClient, fakeSettings);
    httpClient.setResponse('.*/shops_data/.*', '''
          {
            "rezzzults" : {}
          }
        ''');

    final result = await backend.requestShopsByOsmUIDs(
        ['1:8711880917', '1:8771781029'].map((e) => OsmUID.parse(e)));
    expect(result.unwrapErr().errorKind, equals(BackendErrorKind.INVALID_JSON));
  });

  test('requesting shops by UIDs network error', () async {
    final httpClient = FakeHttpClient();
    final backend =
        Backend(analytics, await _initUserParams(), httpClient, fakeSettings);
    httpClient.setResponseException(
        '.*/shops_data/.*', const SocketException(''));

    final result = await backend.requestShopsByOsmUIDs(
        ['1:8711880917', '1:8771781029'].map((e) => OsmUID.parse(e)));
    expect(
        result.unwrapErr().errorKind, equals(BackendErrorKind.NETWORK_ERROR));
  });

  test('requesting shops by bounds', () async {
    final httpClient = FakeHttpClient();
    final backend =
        Backend(analytics, await _initUserParams(), httpClient, fakeSettings);
    httpClient.setResponse('.*/shops_in_bounds_data/.*', '''
          {
            "results" : {
              "1:8711880917" : {
                "osm_uid" : "1:8711880917",
                "products_count" : 1
              },
              "1:8771781029" : {
                "osm_uid" : "1:8771781029",
                "products_count" : 2
              }
            }
          }
        ''');

    final result = await backend.requestShopsWithin(CoordsBounds(
        southwest: Coord(lat: 14.999, lon: 14.999),
        northeast: Coord(lat: 15.001, lon: 15.001)));
    expect(result.isOk, isTrue);

    final shops = result.unwrap();
    expect(shops.length, equals(2));

    final BackendShop shop1;
    final BackendShop shop2;
    if (shops[0].osmUID == OsmUID.parse('1:8711880917')) {
      shop1 = shops[0];
      shop2 = shops[1];
    } else {
      shop1 = shops[1];
      shop2 = shops[0];
    }

    expect(shop1.productsCount, equals(1));
    expect(shop2.productsCount, equals(2));
  });

  test('requesting shops by bounds empty response', () async {
    final httpClient = FakeHttpClient();
    final backend =
        Backend(analytics, await _initUserParams(), httpClient, fakeSettings);
    httpClient.setResponse('.*/shops_in_bounds_data/.*', '''
          {
            "results" : {}
          }
        ''');

    final result = await backend.requestShopsWithin(CoordsBounds(
        southwest: Coord(lat: 14.999, lon: 14.999),
        northeast: Coord(lat: 15.001, lon: 15.001)));
    expect(result.unwrap().length, equals(0));
  });

  test('requesting shops by bounds invalid JSON response', () async {
    final httpClient = FakeHttpClient();
    final backend =
        Backend(analytics, await _initUserParams(), httpClient, fakeSettings);
    httpClient.setResponse('.*/shops_in_bounds_data/.*', '''
          {{{{{{{{{{{{{{{{{{{{{{
            "results" : {
            }
          }
        ''');

    final result = await backend.requestShopsWithin(CoordsBounds(
        southwest: Coord(lat: 14.999, lon: 14.999),
        northeast: Coord(lat: 15.001, lon: 15.001)));
    expect(result.unwrapErr().errorKind, equals(BackendErrorKind.INVALID_JSON));
  });

  test('requesting shops by bounds JSON without results response', () async {
    final httpClient = FakeHttpClient();
    final backend =
        Backend(analytics, await _initUserParams(), httpClient, fakeSettings);
    httpClient.setResponse('.*/shops_in_bounds_data/.*', '''
          {
            "rezzzults" : {}
          }
        ''');

    final result = await backend.requestShopsWithin(CoordsBounds(
        southwest: Coord(lat: 14.999, lon: 14.999),
        northeast: Coord(lat: 15.001, lon: 15.001)));
    expect(result.unwrapErr().errorKind, equals(BackendErrorKind.INVALID_JSON));
  });

  test('requesting shops by bounds network error', () async {
    final httpClient = FakeHttpClient();
    final backend =
        Backend(analytics, await _initUserParams(), httpClient, fakeSettings);
    httpClient.setResponseException(
        '.*/shops_in_bounds_data/.*', const SocketException(''));

    final result = await backend.requestShopsWithin(CoordsBounds(
        southwest: Coord(lat: 14.999, lon: 14.999),
        northeast: Coord(lat: 15.001, lon: 15.001)));
    expect(
        result.unwrapErr().errorKind, equals(BackendErrorKind.NETWORK_ERROR));
  });

  test('product presence vote', () async {
    final httpClient = FakeHttpClient();
    final backend =
        Backend(analytics, await _initUserParams(), httpClient, fakeSettings);
    httpClient
        .setResponse('.*product_presence_vote.*', ''' { "result": "ok" } ''');

    var result = await backend.productPresenceVote(
        '123456', OsmUID.parse('1:123'), true);
    expect(result.isOk, isTrue);

    result = await backend.productPresenceVote(
        '1:123456', OsmUID.parse('1:123'), false);
    expect(result.isOk, isTrue);
  });

  test('product presence vote "deleted" param', () async {
    final httpClient = FakeHttpClient();
    final backend =
        Backend(analytics, await _initUserParams(), httpClient, fakeSettings);

    // Deleted: true
    httpClient.setResponse('.*product_presence_vote.*', '''
         {
           "result": "ok",
           "deleted": true
         }
         ''');
    var result = await backend.productPresenceVote(
        '123456', OsmUID.parse('1:123'), false);
    expect(result.unwrap().productDeleted, isTrue);

    // Deleted: false
    httpClient.setResponse('.*product_presence_vote.*', '''
         {
           "result": "ok",
           "deleted": false
         }
         ''');
    result = await backend.productPresenceVote(
        '123456', OsmUID.parse('1:123'), false);
    expect(result.unwrap().productDeleted, isFalse);

    // Deleted: N/A
    httpClient.setResponse('.*product_presence_vote.*', '''
         {
           "result": "ok"
         }
         ''');
    result = await backend.productPresenceVote(
        '123456', OsmUID.parse('1:123'), false);
    expect(result.unwrap().productDeleted, isFalse);
  });

  test('product presence vote analytics events', () async {
    final httpClient = FakeHttpClient();
    final backend =
        Backend(analytics, await _initUserParams(), httpClient, fakeSettings);
    httpClient
        .setResponse('.*product_presence_vote.*', ''' { "result": "ok" } ''');

    expect(analytics.allEvents(), equals([]));

    await backend.productPresenceVote('123456', OsmUID.parse('1:1'), true);
    expect(analytics.allEvents().length, equals(1));
    expect(analytics.firstSentEvent('product_presence_vote').second,
        equals({'barcode': '123456', 'shop': '1:1', 'vote': true}));
    analytics.clearEvents();

    await backend.productPresenceVote('123456', OsmUID.parse('1:1'), false);
    expect(analytics.allEvents().length, equals(1));
    expect(analytics.firstSentEvent('product_presence_vote').second,
        equals({'barcode': '123456', 'shop': '1:1', 'vote': false}));
  });

  test('product presence vote error', () async {
    final httpClient = FakeHttpClient();
    final backend =
        Backend(analytics, await _initUserParams(), httpClient, fakeSettings);
    httpClient.setResponseException(
        '.*product_presence_vote.*', const SocketException(''));

    final result = await backend.productPresenceVote(
        '123456', OsmUID.parse('1:123'), true);
    expect(result.isErr, isTrue);
  });

  test('put product to shop', () async {
    final httpClient = FakeHttpClient();
    final backend =
        Backend(analytics, await _initUserParams(), httpClient, fakeSettings);
    httpClient
        .setResponse('.*put_product_to_shop.*', ''' { "result": "ok" } ''');

    final shop = Shop((e) => e
      ..osmShop.replace(OsmShop((e) => e
        ..osmUID = OsmUID.parse('1:2')
        ..longitude = 11
        ..latitude = 12
        ..name = 'Spar2')));
    final result = await backend.putProductToShop('123456', shop);
    expect(result.isOk, isTrue);

    final request = httpClient.getRequestsMatching('.*').single;
    final url = request.url.toString();
    expect(url, contains('lat=12'));
    expect(url, contains('lon=11'));
  });

  test('put product to shop error', () async {
    final httpClient = FakeHttpClient();
    final backend =
        Backend(analytics, await _initUserParams(), httpClient, fakeSettings);
    httpClient.setResponseException(
        '.*put_product_to_shop.*', const SocketException(''));

    final shop = Shop((e) => e
      ..osmShop.replace(OsmShop((e) => e
        ..osmUID = OsmUID.parse('1:2')
        ..longitude = 11
        ..latitude = 12
        ..name = 'Spar2')));
    final result = await backend.putProductToShop('123456', shop);
    expect(result.isErr, isTrue);
  });

  test('create shop', () async {
    final httpClient = FakeHttpClient();
    final backend =
        Backend(analytics, await _initUserParams(), httpClient, fakeSettings);
    httpClient
        .setResponse('.*create_shop.*', ''' { "osm_uid": "1:123456" } ''');

    final result = await backend.createShop(
        name: 'hello there',
        coord: Coord(lat: 321, lon: 123),
        type: 'supermarket');
    expect(result.isOk, isTrue);
    expect(OsmUID.parse('1:123456'), equals(result.unwrap().osmUID));
    expect(0, equals(result.unwrap().productsCount));
  });

  test('create shop error', () async {
    final httpClient = FakeHttpClient();
    final backend =
        Backend(analytics, await _initUserParams(), httpClient, fakeSettings);
    httpClient.setResponseException(
        '.*create_shop.*', const SocketException(''));

    final result = await backend.createShop(
        name: 'hello there',
        coord: Coord(lat: 321, lon: 123),
        type: 'supermarket');
    expect(result.isErr, isTrue);
  });

  test('create shop not expected json response', () async {
    final httpClient = FakeHttpClient();
    final backend =
        Backend(analytics, await _initUserParams(), httpClient, fakeSettings);
    httpClient.setResponse('.*create_shop.*', ''' { "result": "ok" } ''');

    final result = await backend.createShop(
        name: 'hello there',
        coord: Coord(lat: 321, lon: 123),
        type: 'supermarket');

    // 'osm_uid' was expected, not 'result'
    expect(result.isErr, isTrue);
    expect(result.unwrapErr().errorKind, BackendErrorKind.INVALID_JSON);
  });
}

Future<FakeUserParamsController> _initUserParams() async {
  final userParamsController = FakeUserParamsController();
  final initialParams = UserParams((v) => v
    ..backendId = '123'
    ..name = 'Bob'
    ..backendClientToken = 'aaa');
  await userParamsController.setUserParams(initialParams);
  return userParamsController;
}
