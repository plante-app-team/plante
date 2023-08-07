import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:plante/l10n/strings.dart';
import 'package:plante/logging/analytics.dart';
import 'package:plante/model/user_params.dart';
import 'package:plante/model/user_params_controller.dart';
import 'package:plante/outside/backend/backend.dart';
import 'package:plante/outside/backend/cmds/login_cmd.dart';
import 'package:plante/outside/backend/cmds/update_user_params_cmd.dart';
import 'package:plante/outside/identity/apple_authorizer.dart';
import 'package:plante/outside/identity/apple_user.dart';
import 'package:plante/outside/identity/google_authorizer.dart';
import 'package:plante/outside/identity/google_user.dart';
import 'package:plante/ui/first_screen/external_auth_page.dart';

import '../../common_mocks.mocks.dart';
import '../../test_di_registry.dart';
import '../../widget_tester_extension.dart';
import '../../z_fakes/fake_analytics.dart';
import '../../z_fakes/fake_backend.dart';
import '../../z_fakes/fake_user_params_controller.dart';

void main() {
  late FakeAnalytics analytics;
  late MockGoogleAuthorizer googleAuthorizer;
  late MockAppleAuthorizer appleAuthorizer;
  late FakeUserParamsController userParamsController;
  late FakeBackend backend;

  setUp(() async {
    googleAuthorizer = MockGoogleAuthorizer();
    appleAuthorizer = MockAppleAuthorizer();
    userParamsController = FakeUserParamsController();
    backend = FakeBackend(userParamsController);
    analytics = FakeAnalytics();

    await TestDiRegistry.register((r) {
      r.register<GoogleAuthorizer>(googleAuthorizer);
      r.register<AppleAuthorizer>(appleAuthorizer);
      r.register<Backend>(backend);
      r.register<Analytics>(analytics);
      r.register<UserParamsController>(userParamsController);
    });

    backend.setResponse_testing(UPDATE_USER_PARAMS_CMD, '{}');
  });

  testWidgets('Google: successful Google Sign in', (WidgetTester tester) async {
    final googleUser = GoogleUser('bob', 'bob@bo.net', '123', DateTime.now());
    when(googleAuthorizer.auth()).thenAnswer((_) async => googleUser);
    backend.setResponse_testing(
        LOGIN_OR_REGISTER_CMD, jsonEncode(UserParams().toJson()));

    expect(analytics.allEvents(), equals([]));

    await tester.superPump(const ExternalAuthPage());

    await tester.superTap(find.text('Google'));

    // We expect the Google name to be sent to the server
    final expectedParams = UserParams((e) => e.name = 'bob');
    expect(await userParamsController.getUserParams(), equals(expectedParams));
    final req =
        backend.getRequestsMatching_testing(LOGIN_OR_REGISTER_CMD).first;
    expect(
        req.url.queryParameters['googleIdToken'], equals(googleUser.idToken));

    expect(analytics.allEvents().length, equals(2));
    expect(analytics.wasEventSent('google_auth_start'), isTrue);
    expect(analytics.wasEventSent('google_auth_success'), isTrue);
  });

  testWidgets('Google: not successful Google Sign in',
      (WidgetTester tester) async {
    when(googleAuthorizer.auth()).thenAnswer((_) async => null);

    await tester.superPump(const ExternalAuthPage());

    await tester.superTap(find.text('Google'));
    expect(await userParamsController.getUserParams(), isNull);
    expect(
        backend.getRequestsMatching_testing(UPDATE_USER_PARAMS_CMD), isEmpty);

    expect(analytics.allEvents().length, equals(2));
    expect(analytics.wasEventSent('google_auth_start'), isTrue);
    expect(analytics.wasEventSent('google_auth_google_failure'), isTrue);
  });

  testWidgets('Google: not successful backend sign in',
      (WidgetTester tester) async {
    final googleUser = GoogleUser('bob', 'bob@bo.net', '123', DateTime.now());
    when(googleAuthorizer.auth()).thenAnswer((_) async => googleUser);
    backend.setResponse_testing(LOGIN_OR_REGISTER_CMD, '', responseCode: 500);

    expect(analytics.allEvents(), equals([]));

    await tester.superPump(const ExternalAuthPage());

    await tester.superTap(find.text('Google'));
    expect(await userParamsController.getUserParams(), isNull);
    expect(
        backend.getRequestsMatching_testing(UPDATE_USER_PARAMS_CMD), isEmpty);

    expect(analytics.wasEventSent('google_auth_start'), isTrue);
    expect(analytics.wasEventSent('auth_backend_failure'), isTrue);
    expect(analytics.allEvents().length, equals(2));
  });

  testWidgets('Google: not successful backend params update',
      (WidgetTester tester) async {
    final googleUser = GoogleUser('bob', 'bob@bo.net', '123', DateTime.now());
    when(googleAuthorizer.auth()).thenAnswer((_) async => googleUser);
    backend.setResponse_testing(
        LOGIN_OR_REGISTER_CMD, jsonEncode(UserParams().toJson()));
    backend.setResponse_testing(UPDATE_USER_PARAMS_CMD, '', responseCode: 500);

    await tester.superPump(const ExternalAuthPage());

    await tester.superTap(find.text('Google'));
    // Params were tried to be updated
    expect(backend.getRequestsMatching_testing(UPDATE_USER_PARAMS_CMD),
        isNot(isEmpty));
    // But params were not stored
    expect(await userParamsController.getUserParams(), isNull);
  });

  testWidgets('Apple: successful Apple Sign in', (WidgetTester tester) async {
    final appleUser = AppleUser('bob', 'bob@bo.net', '123', DateTime.now());
    when(appleAuthorizer.auth()).thenAnswer((_) async => appleUser);
    backend.setResponse_testing(
        LOGIN_OR_REGISTER_CMD, jsonEncode(UserParams().toJson()));

    expect(analytics.allEvents(), equals([]));

    final context = await tester.superPump(const ExternalAuthPage());

    await tester.superTap(
        find.text(context.strings.external_auth_page_continue_with_apple));

    // We expect the Apple name to be sent to the server
    final expectedParams = UserParams((e) => e.name = 'bob');
    expect(await userParamsController.getUserParams(), equals(expectedParams));
    final req =
        backend.getRequestsMatching_testing(LOGIN_OR_REGISTER_CMD).first;
    expect(req.url.queryParameters['appleAuthorizationCode'],
        equals(appleUser.authorizationCode));

    expect(analytics.allEvents().length, equals(2));
    expect(analytics.wasEventSent('apple_auth_start'), isTrue);
    expect(analytics.wasEventSent('apple_auth_success'), isTrue);
  });

  testWidgets('Apple: not successful Apple Sign in',
      (WidgetTester tester) async {
    when(appleAuthorizer.auth()).thenAnswer((_) async => null);

    final context = await tester.superPump(const ExternalAuthPage());

    await tester.superTap(
        find.text(context.strings.external_auth_page_continue_with_apple));
    expect(await userParamsController.getUserParams(), isNull);
    expect(
        backend.getRequestsMatching_testing(UPDATE_USER_PARAMS_CMD), isEmpty);

    expect(analytics.allEvents().length, equals(2));
    expect(analytics.wasEventSent('apple_auth_start'), isTrue);
    expect(analytics.wasEventSent('apple_auth_apple_failure'), isTrue);
  });

  testWidgets('Apple: not successful backend sign in',
      (WidgetTester tester) async {
    final appleUser = AppleUser('bob', 'bob@bo.net', '123', DateTime.now());
    when(appleAuthorizer.auth()).thenAnswer((_) async => appleUser);
    backend.setResponse_testing(LOGIN_OR_REGISTER_CMD, '', responseCode: 500);

    expect(analytics.allEvents(), equals([]));

    final context = await tester.superPump(const ExternalAuthPage());

    await tester.superTap(
        find.text(context.strings.external_auth_page_continue_with_apple));
    expect(await userParamsController.getUserParams(), isNull);
    expect(
        backend.getRequestsMatching_testing(UPDATE_USER_PARAMS_CMD), isEmpty);

    expect(analytics.allEvents().length, equals(2));
    expect(analytics.wasEventSent('apple_auth_start'), isTrue);
    expect(analytics.wasEventSent('auth_backend_failure'), isTrue);
  });

  testWidgets('Apple: not successful backend params update',
      (WidgetTester tester) async {
    final appleUser = AppleUser('bob', 'bob@bo.net', '123', DateTime.now());
    when(appleAuthorizer.auth()).thenAnswer((_) async => appleUser);
    backend.setResponse_testing(
        LOGIN_OR_REGISTER_CMD, jsonEncode(UserParams().toJson()));
    backend.setResponse_testing(UPDATE_USER_PARAMS_CMD, '', responseCode: 500);

    final context = await tester.superPump(const ExternalAuthPage());

    await tester.superTap(
        find.text(context.strings.external_auth_page_continue_with_apple));
    // Params were tried to be updated
    expect(backend.getRequestsMatching_testing(UPDATE_USER_PARAMS_CMD),
        isNot(isEmpty));
    // But params were not stored
    expect(await userParamsController.getUserParams(), isNull);
  });
}
