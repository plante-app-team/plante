import 'package:http/testing.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';
import 'package:untitled_vegan_app/outside/backend/backend.dart';
import 'package:untitled_vegan_app/outside/backend/backend_error.dart';
import 'package:untitled_vegan_app/outside/backend/user_params_auto_wiper.dart';
import 'package:untitled_vegan_app/base/either_extension.dart';
import 'package:untitled_vegan_app/model/user_params.dart';
import 'package:untitled_vegan_app/model/user_params_controller.dart';

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
    expect(result.requireLeft(), equals(expectedParams));
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
    expect(result.requireLeft(), equals(expectedParams));
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
    expect(result.requireLeft(), equals(existingParams));
  });

  test('registration request not 200', () async {
    final httpClient = FakeHttpClient();
    final userParamsController = FakeUserParamsController();
    final backend = Backend(userParamsController, httpClient);
    httpClient.setResponse(".*register_user.*", "", responseCode: 500);
    final result = await backend.loginOrRegister("google ID");
    expect(result.requireRight().errorKind, equals(BackendErrorKind.OTHER));
  });

  test('registration request bad json', () async {
    final httpClient = FakeHttpClient();
    final userParamsController = FakeUserParamsController();
    final backend = Backend(userParamsController, httpClient);
    httpClient.setResponse(".*register_user.*", "{{{{bad bad bad}");
    final result = await backend.loginOrRegister("google ID");
    expect(result.requireRight().errorKind, equals(BackendErrorKind.INVALID_JSON));
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
    expect(result.requireRight().errorKind, equals(BackendErrorKind.OTHER));
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
    expect(result.requireRight().errorKind, equals(BackendErrorKind.OTHER));
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
    expect(result.requireRight().errorKind, equals(BackendErrorKind.INVALID_JSON));
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
    expect(result.requireRight().errorKind, equals(BackendErrorKind.OTHER));
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
    expect(result.isLeft, isTrue);

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
}
