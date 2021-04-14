import 'dart:io';

import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';
import 'package:untitled_vegan_app/model/veg_status.dart';
import 'package:untitled_vegan_app/model/veg_status_source.dart';
import 'package:untitled_vegan_app/outside/backend/backend.dart';
import 'package:untitled_vegan_app/outside/backend/backend_error.dart';
import 'package:untitled_vegan_app/model/user_params.dart';
import 'package:untitled_vegan_app/outside/backend/backend_product.dart';

import '../../fake_http_client.dart';
import '../../fake_user_params_controller.dart';
import 'backend_test.mocks.dart';

@GenerateMocks([BackendObserver])
void main() {
  setUp(() {
  });

  test('successful registration', () async {
    final httpClient = FakeHttpClient();
    final userParamsController = FakeUserParamsController();
    final backend = Backend(userParamsController, httpClient);

    httpClient.setResponse(".*register_user.*", """
      {
        "user_id": "123",
        "client_token": "321"
      }
    """);

    final result = await backend.loginOrRegister("google ID");
    final expectedParams = UserParams((v) => v
      ..backendId = "123"
      ..backendClientToken = "321");
    expect(result.unwrap(), equals(expectedParams));
  });

  test('successful login', () async {
    final httpClient = FakeHttpClient();
    final userParamsController = FakeUserParamsController();
    final backend = Backend(userParamsController, httpClient);

    httpClient.setResponse(".*register_user.*", """
      {
        "error": "already_registered"
      }
    """);
    httpClient.setResponse(".*login_user.*", """
      {
        "user_id": "123",
        "client_token": "321"
      }
    """);

    final result = await backend.loginOrRegister("google ID");
    final expectedParams = UserParams((v) => v
      ..backendId = "123"
      ..backendClientToken = "321");
    expect(result.unwrap(), equals(expectedParams));
  });

  test('check whether logged in', () async {
    final httpClient = FakeHttpClient();
    final userParamsController = FakeUserParamsController();
    final backend = Backend(userParamsController, httpClient);

    expect(await backend.isLoggedIn(), isFalse);
    await userParamsController.setUserParams(UserParams((v) => v.backendId = "123"));
    expect(await backend.isLoggedIn(), isFalse);
    await userParamsController.setUserParams(UserParams((v) => v.backendClientToken = "321"));
    expect(await backend.isLoggedIn(), isTrue);
  });

  test('login when already logged in', () async {
    final httpClient = FakeHttpClient();
    final existingParams = UserParams((v) => v
      ..backendId = "123"
      ..backendClientToken = "321"
      ..name = "Bob");
    final userParamsController = FakeUserParamsController();
    await userParamsController.setUserParams(existingParams);

    final backend = Backend(userParamsController, httpClient);
    final result = await backend.loginOrRegister("google ID");
    expect(result.unwrap(), equals(existingParams));
  });

  test('registration failure - email not verified', () async {
    final httpClient = FakeHttpClient();
    final userParamsController = FakeUserParamsController();
    final backend = Backend(userParamsController, httpClient);

    httpClient.setResponse(".*register_user.*", """
      {
        "error": "google_email_not_verified"
      }
    """);

    final result = await backend.loginOrRegister("google ID");
    expect(
        result.unwrapErr().errorKind, equals(
        BackendErrorKind.GOOGLE_EMAIL_NOT_VERIFIED));
  });

  test('registration request not 200', () async {
    final httpClient = FakeHttpClient();
    final userParamsController = FakeUserParamsController();
    final backend = Backend(userParamsController, httpClient);
    httpClient.setResponse(".*register_user.*", "", responseCode: 500);
    final result = await backend.loginOrRegister("google ID");
    expect(result.unwrapErr().errorKind, equals(BackendErrorKind.OTHER));
  });

  test('registration request bad json', () async {
    final httpClient = FakeHttpClient();
    final userParamsController = FakeUserParamsController();
    final backend = Backend(userParamsController, httpClient);
    httpClient.setResponse(".*register_user.*", "{{{{bad bad bad}");
    final result = await backend.loginOrRegister("google ID");
    expect(result.unwrapErr().errorKind, equals(BackendErrorKind.INVALID_JSON));
  });

  test('registration request json error', () async {
    final httpClient = FakeHttpClient();
    final userParamsController = FakeUserParamsController();
    final backend = Backend(userParamsController, httpClient);
    httpClient.setResponse(".*register_user.*", """
      {
        "error": "some_error"
      }
    """);
    final result = await backend.loginOrRegister("google ID");
    expect(result.unwrapErr().errorKind, equals(BackendErrorKind.OTHER));
  });

  test('login request not 200', () async {
    final httpClient = FakeHttpClient();
    final userParamsController = FakeUserParamsController();
    final backend = Backend(userParamsController, httpClient);
    httpClient.setResponse(".*register_user.*", """
      {
        "error": "already_registered"
      }
    """);
    httpClient.setResponse(".*login_user.*", "", responseCode: 500);
    final result = await backend.loginOrRegister("google ID");
    expect(result.unwrapErr().errorKind, equals(BackendErrorKind.OTHER));
  });

  test('login request bad json', () async {
    final httpClient = FakeHttpClient();
    final userParamsController = FakeUserParamsController();
    final backend = Backend(userParamsController, httpClient);
    httpClient.setResponse(".*register_user.*", """
      {
        "error": "already_registered"
      }
    """);
    httpClient.setResponse(".*login_user.*", "{{{{bad bad bad}");
    final result = await backend.loginOrRegister("google ID");
    expect(result.unwrapErr().errorKind, equals(BackendErrorKind.INVALID_JSON));
  });

  test('login request json error', () async {
    final httpClient = FakeHttpClient();
    final userParamsController = FakeUserParamsController();
    final backend = Backend(userParamsController, httpClient);
    httpClient.setResponse(".*register_user.*", """
      {
        "error": "already_registered"
      }
    """);
    httpClient.setResponse(".*login_user.*", """
      {
        "error": "some_error"
      }
    """);
    final result = await backend.loginOrRegister("google ID");
    expect(result.unwrapErr().errorKind, equals(BackendErrorKind.OTHER));
  });

  test('registration network error', () async {
    final httpClient = FakeHttpClient();
    final userParamsController = FakeUserParamsController();
    final backend = Backend(userParamsController, httpClient);
    httpClient.setResponseException(".*register_user.*", SocketException(""));
    final result = await backend.loginOrRegister("google ID");
    expect(result.unwrapErr().errorKind, equals(BackendErrorKind.NETWORK_ERROR));
  });

  test('login network error', () async {
    final httpClient = FakeHttpClient();
    final userParamsController = FakeUserParamsController();
    final backend = Backend(userParamsController, httpClient);
    httpClient.setResponse(".*register_user.*", """
      {
        "error": "already_registered"
      }
    """);
    httpClient.setResponseException(".*register_user.*", SocketException(""));
    final result = await backend.loginOrRegister("google ID");
    expect(result.unwrapErr().errorKind, equals(BackendErrorKind.NETWORK_ERROR));
  });

  test('observer notified about server errors', () async {
    final httpClient = FakeHttpClient();
    final userParamsController = FakeUserParamsController();
    final backend = Backend(userParamsController, httpClient);
    final observer = MockBackendObserver();
    backend.addObserver(observer);

    httpClient.setResponse(".*register_user.*", """
      {
        "error": "some_error"
      }
    """);

    verifyNever(observer.onBackendError(any));
    await backend.loginOrRegister("google ID");
    verify(observer.onBackendError(any));
  });

  test('update user params', () async {
    final httpClient = FakeHttpClient();
    final userParamsController = FakeUserParamsController();
    final initialParams = UserParams((v) => v
      ..backendId = "123"
      ..name = "Bob"
      ..backendClientToken = "aaa");
    userParamsController.setUserParams(initialParams);

    final backend = Backend(userParamsController, httpClient);
    httpClient.setResponse(".*update_user_data.*", """ { "result": "ok" } """);

    final updatedParams = initialParams.rebuild((v) => v
      ..name = "Jack"
      ..genderStr = "male"
      ..birthdayStr = "20.07.1993"
      ..eatsMilk = false
      ..eatsEggs = false
      ..eatsHoney = true);
    final result = await backend.updateUserParams(updatedParams);
    expect(result.isOk, isTrue);

    final requests = httpClient.getRequestsMatching(".*update_user_data.*");
    expect(requests.length, equals(1));
    final request = requests[0];

    expect(request.url.queryParameters["name"], equals("Jack"));
    expect(request.url.queryParameters["gender"], equals("male"));
    expect(request.url.queryParameters["birthday"], equals("20.07.1993"));
    expect(request.url.queryParameters["eatsMilk"], equals("false"));
    expect(request.url.queryParameters["eatsEggs"], equals("false"));
    expect(request.url.queryParameters["eatsHoney"], equals("true"));
  });

  test('update user params has client token', () async {
    final httpClient = FakeHttpClient();
    final userParamsController = FakeUserParamsController();
    final initialParams = UserParams((v) => v
      ..backendId = "123"
      ..name = "Bob"
      ..backendClientToken = "my_token");
    userParamsController.setUserParams(initialParams);

    final backend = Backend(userParamsController, httpClient);
    httpClient.setResponse(".*update_user_data.*", """ { "result": "ok" } """);

    await backend.updateUserParams(initialParams.rebuild((v) => v.name = "Nora"));
    final request = httpClient.getRequestsMatching(".*update_user_data.*")[0];

    expect(request.headers["Authorization"], equals("Bearer my_token"));
  });

  test('update user params when not authorized', () async {
    final httpClient = FakeHttpClient();
    final userParamsController = FakeUserParamsController();
    final initialParams = UserParams((v) => v
      ..backendId = "123"
      ..name = "Bob");
    userParamsController.setUserParams(initialParams);

    final backend = Backend(userParamsController, httpClient);
    httpClient.setResponse(".*update_user_data.*", """ { "result": "ok" } """);

    await backend.updateUserParams(initialParams.rebuild((v) => v.name = "Nora"));
    final request = httpClient.getRequestsMatching(".*update_user_data.*")[0];

    expect(request.headers["Authorization"], equals(null));
  });

  test('update user params network error', () async {
    final httpClient = FakeHttpClient();
    final userParamsController = FakeUserParamsController();
    final initialParams = UserParams((v) => v
      ..backendId = "123"
      ..name = "Bob"
      ..backendClientToken = "aaa");
    userParamsController.setUserParams(initialParams);

    final backend = Backend(userParamsController, httpClient);
    httpClient.setResponseException(".*update_user_data.*", HttpException(""));

    final updatedParams = initialParams.rebuild((v) => v
      ..name = "Jack"
      ..genderStr = "male"
      ..birthdayStr = "20.07.1993");
    final result = await backend.updateUserParams(updatedParams);
    expect(result.unwrapErr().errorKind, BackendErrorKind.NETWORK_ERROR);
  });

  test('request product', () async {
    final httpClient = FakeHttpClient();
    final userParamsController = FakeUserParamsController();
    final initialParams = UserParams((v) => v
      ..backendId = "123"
      ..name = "Bob"
      ..backendClientToken = "aaa");
    userParamsController.setUserParams(initialParams);

    final backend = Backend(userParamsController, httpClient);
    httpClient.setResponse(".*product_data.*", """
     {
       "barcode": "123",
       "vegetarian_status": "${VegStatus.positive.name}",
       "vegetarian_status_source": "${VegStatusSource.community.name}",
       "vegan_status": "${VegStatus.negative.name}",
       "vegan_status_source": "${VegStatusSource.moderator.name}"
     }
      """);

    final result = await backend.requestProduct("123");
    final product = result.unwrap();
    final expectedProduct = BackendProduct((v) => v
      ..barcode = "123"
      ..vegetarianStatus = VegStatus.positive.name
      ..vegetarianStatusSource = VegStatusSource.community.name
      ..veganStatus = VegStatus.negative.name
      ..veganStatusSource = VegStatusSource.moderator.name);
    expect(product, equals(expectedProduct));

    final requests = httpClient.getRequestsMatching(".*product_data.*");
    expect(requests.length, equals(1));
    final request = requests[0];
    expect(request.headers["Authorization"], equals("Bearer aaa"));
  });

  test('request product not found', () async {
    final httpClient = FakeHttpClient();
    final userParamsController = FakeUserParamsController();
    final initialParams = UserParams((v) => v
      ..backendId = "123"
      ..name = "Bob"
      ..backendClientToken = "aaa");
    userParamsController.setUserParams(initialParams);

    final backend = Backend(userParamsController, httpClient);
    httpClient.setResponse(".*product_data.*", """
     {
       "error": "product_not_found"
     }
      """);

    final result = await backend.requestProduct("123");
    final product = result.unwrap();
    expect(product, isNull);
  });

  test('request product http error', () async {
    final httpClient = FakeHttpClient();
    final userParamsController = FakeUserParamsController();
    final initialParams = UserParams((v) => v
      ..backendId = "123"
      ..name = "Bob"
      ..backendClientToken = "aaa");
    userParamsController.setUserParams(initialParams);

    final backend = Backend(userParamsController, httpClient);
    httpClient.setResponse(".*product_data.*", "", responseCode: 500);

    final result = await backend.requestProduct("123");
    expect(result.isErr, isTrue);

    final requests = httpClient.getRequestsMatching(".*product_data.*");
    expect(requests.length, equals(1));
    final request = requests[0];
    expect(request.headers["Authorization"], equals("Bearer aaa"));
  });

  test('request product invalid JSON', () async {
    final httpClient = FakeHttpClient();
    final userParamsController = FakeUserParamsController();
    final initialParams = UserParams((v) => v
      ..backendId = "123"
      ..name = "Bob"
      ..backendClientToken = "aaa");
    userParamsController.setUserParams(initialParams);

    final backend = Backend(userParamsController, httpClient);
    httpClient.setResponse(".*product_data.*", """
     {{{{{{{{{{{{
       "barcode": "123",
       "vegetarian_status": "${VegStatus.positive.name}",
       "vegetarian_status_source": "${VegStatusSource.community.name}",
       "vegan_status": "${VegStatus.negative.name}",
       "vegan_status_source": "${VegStatusSource.moderator.name}"
     }
      """);

    final result = await backend.requestProduct("123");
    expect(result.unwrapErr().errorKind, BackendErrorKind.INVALID_JSON);

    final requests = httpClient.getRequestsMatching(".*product_data.*");
    expect(requests.length, equals(1));
    final request = requests[0];
    expect(request.headers["Authorization"], equals("Bearer aaa"));
  });

  test('request product network exception', () async {
    final httpClient = FakeHttpClient();
    final userParamsController = FakeUserParamsController();
    final initialParams = UserParams((v) => v
      ..backendId = "123"
      ..name = "Bob"
      ..backendClientToken = "aaa");
    userParamsController.setUserParams(initialParams);

    final backend = Backend(userParamsController, httpClient);
    httpClient.setResponseException(".*product_data.*", SocketException(""));

    final result = await backend.requestProduct("123");
    expect(result.unwrapErr().errorKind, BackendErrorKind.NETWORK_ERROR);
  });

  test('create update product', () async {
    final httpClient = FakeHttpClient();
    final userParamsController = FakeUserParamsController();
    final initialParams = UserParams((v) => v
      ..backendId = "123"
      ..name = "Bob"
      ..backendClientToken = "aaa");
    userParamsController.setUserParams(initialParams);

    final backend = Backend(userParamsController, httpClient);
    httpClient.setResponse(
        ".*create_update_product.*",
        """ { "result": "ok" } """);

    final result = await backend.createUpdateProduct(
        "123",
        vegetarianStatus: VegStatus.positive,
        veganStatus: VegStatus.negative);
    expect(result.isOk, isTrue);

    final requests = httpClient.getRequestsMatching(".*create_update_product.*");
    expect(requests.length, equals(1));
    final request = requests[0];
    expect(
        request.url.queryParameters["vegetarianStatus"],
        equals(VegStatus.positive.name));
    expect(
        request.url.queryParameters["veganStatus"],
        equals(VegStatus.negative.name));
    expect(request.headers["Authorization"], equals("Bearer aaa"));
  });

  test('create update product vegetarian status only', () async {
    final httpClient = FakeHttpClient();
    final userParamsController = FakeUserParamsController();
    final initialParams = UserParams((v) => v
      ..backendId = "123"
      ..name = "Bob"
      ..backendClientToken = "aaa");
    userParamsController.setUserParams(initialParams);

    final backend = Backend(userParamsController, httpClient);
    httpClient.setResponse(
        ".*create_update_product.*",
        """ { "result": "ok" } """);

    final result = await backend.createUpdateProduct(
        "123",
        vegetarianStatus: VegStatus.positive);
    expect(result.isOk, isTrue);

    final requests = httpClient.getRequestsMatching(".*create_update_product.*");
    expect(requests.length, equals(1));
    final request = requests[0];
    expect(
        request.url.queryParameters["vegetarianStatus"],
        equals(VegStatus.positive.name));
    expect(
        request.url.queryParameters["veganStatus"],
        isNull);
    expect(request.headers["Authorization"], equals("Bearer aaa"));
  });

  test('create update product vegan status only', () async {
    final httpClient = FakeHttpClient();
    final userParamsController = FakeUserParamsController();
    final initialParams = UserParams((v) => v
      ..backendId = "123"
      ..name = "Bob"
      ..backendClientToken = "aaa");
    userParamsController.setUserParams(initialParams);

    final backend = Backend(userParamsController, httpClient);
    httpClient.setResponse(
        ".*create_update_product.*",
        """ { "result": "ok" } """);

    final result = await backend.createUpdateProduct(
        "123",
        veganStatus: VegStatus.negative);
    expect(result.isOk, isTrue);

    final requests = httpClient.getRequestsMatching(".*create_update_product.*");
    expect(requests.length, equals(1));
    final request = requests[0];
    expect(
        request.url.queryParameters["vegetarianStatus"],
        isNull);
    expect(
        request.url.queryParameters["veganStatus"],
        equals(VegStatus.negative.name));
    expect(request.headers["Authorization"], equals("Bearer aaa"));
  });

  test('create update product http error', () async {
    final httpClient = FakeHttpClient();
    final userParamsController = FakeUserParamsController();
    final initialParams = UserParams((v) => v
      ..backendId = "123"
      ..name = "Bob"
      ..backendClientToken = "aaa");
    userParamsController.setUserParams(initialParams);

    final backend = Backend(userParamsController, httpClient);
    httpClient.setResponse(".*create_update_product.*", "", responseCode: 500);

    final result = await backend.createUpdateProduct(
        "123",
        vegetarianStatus: VegStatus.positive,
        veganStatus: VegStatus.negative);
    expect(result.isErr, isTrue);
  });

  test('create update product invalid JSON response', () async {
    final httpClient = FakeHttpClient();
    final userParamsController = FakeUserParamsController();
    final initialParams = UserParams((v) => v
      ..backendId = "123"
      ..name = "Bob"
      ..backendClientToken = "aaa");
    userParamsController.setUserParams(initialParams);

    final backend = Backend(userParamsController, httpClient);
    httpClient.setResponse(".*create_update_product.*", "{{{{}");

    final result = await backend.createUpdateProduct(
        "123",
        vegetarianStatus: VegStatus.positive,
        veganStatus: VegStatus.negative);
    expect(result.isErr, isTrue);
  });

  test('create update product network error', () async {
    final httpClient = FakeHttpClient();
    final userParamsController = FakeUserParamsController();
    final initialParams = UserParams((v) => v
      ..backendId = "123"
      ..name = "Bob"
      ..backendClientToken = "aaa");
    userParamsController.setUserParams(initialParams);

    final backend = Backend(userParamsController, httpClient);
    httpClient.setResponseException(
        ".*create_update_product.*", SocketException(""));

    final result = await backend.createUpdateProduct(
        "123",
        vegetarianStatus: VegStatus.positive,
        veganStatus: VegStatus.negative);
    expect(result.unwrapErr().errorKind, BackendErrorKind.NETWORK_ERROR);
  });

  test('send report', () async {
    final httpClient = FakeHttpClient();
    final userParamsController = FakeUserParamsController();
    final initialParams = UserParams((v) => v
      ..backendId = "123"
      ..name = "Bob"
      ..backendClientToken = "aaa");
    userParamsController.setUserParams(initialParams);

    final backend = Backend(userParamsController, httpClient);
    httpClient.setResponse(
        ".*make_report.*",
        """ { "result": "ok" } """);

    final result = await backend.sendReport(
        "123",
        "that's a baaaad product");
    expect(result.isOk, isTrue);
  });

  test('send report network error', () async {
    final httpClient = FakeHttpClient();
    final userParamsController = FakeUserParamsController();
    final initialParams = UserParams((v) => v
      ..backendId = "123"
      ..name = "Bob"
      ..backendClientToken = "aaa");
    userParamsController.setUserParams(initialParams);

    final backend = Backend(userParamsController, httpClient);
    httpClient.setResponseException(".*make_report.*", SocketException(""));

    final result = await backend.sendReport(
        "123",
        "that's a baaaad product");
    expect(result.unwrapErr().errorKind, BackendErrorKind.NETWORK_ERROR);
  });
}
