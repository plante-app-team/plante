import 'dart:async';
import 'dart:io';

import 'package:mockito/mockito.dart';
import 'package:plante/base/base.dart';
import 'package:plante/base/result.dart';
import 'package:plante/lang/manual_user_langs_manager.dart';
import 'package:plante/lang/user_langs_manager_error.dart';
import 'package:plante/model/lang_code.dart';
import 'package:plante/model/user_params.dart';
import 'package:plante/outside/backend/backend_error.dart';
import 'package:plante/outside/backend/backend_response.dart';
import 'package:test/test.dart';

import '../common_mocks.mocks.dart';
import '../fake_analytics.dart';
import '../fake_user_params_controller.dart';

void main() {
  late FakeUserParamsController userParamsController;
  late MockBackend backend;
  late ManualUserLangsManager userLangsManager;

  setUp(() async {
    userParamsController = FakeUserParamsController();
    backend = MockBackend();
  });

  test('good scenario with set langs', () async {
    await userParamsController.setUserParams(UserParams((e) => e
      ..name = 'Bob'
      ..langsPrioritized.addAll(['en', 'nl'])));
    userLangsManager =
        ManualUserLangsManager(userParamsController, backend, FakeAnalytics());

    final expectedLangs = [LangCode.en, LangCode.nl];
    expect(await userLangsManager.getUserLangs(), equals(expectedLangs));
  });

  test('good scenario without set langs', () async {
    await userParamsController.setUserParams(UserParams((e) => e
      ..name = 'Bob'
      ..langsPrioritized = null));
    userLangsManager =
        ManualUserLangsManager(userParamsController, backend, FakeAnalytics());

    expect(await userLangsManager.getUserLangs(), isNull);
  });

  test('listening to langs updates', () async {
    await userParamsController.setUserParams(UserParams((e) => e
      ..name = 'Bob'
      ..langsPrioritized = null));
    userLangsManager =
        ManualUserLangsManager(userParamsController, backend, FakeAnalytics());

    expect(await userLangsManager.getUserLangs(), isNull);
    await userParamsController.setUserParams(UserParams((e) => e
      ..name = 'Bob'
      ..langsPrioritized.addAll(['en', 'nl'])));

    final expectedLangs = [LangCode.en, LangCode.nl];
    expect(await userLangsManager.getUserLangs(), equals(expectedLangs));
  });

  test('is not inited until user params controllers returns params', () async {
    final completer = Completer<UserParams>();
    final mockUserParamsController = MockUserParamsController();
    when(mockUserParamsController.getUserParams())
        .thenAnswer((_) => completer.future);

    userLangsManager = ManualUserLangsManager(
        mockUserParamsController, backend, FakeAnalytics());

    var inited = false;
    unawaited(userLangsManager.initFuture.then((_) => inited = true));

    await Future.delayed(const Duration(milliseconds: 10));
    expect(inited, isFalse);

    completer.complete(UserParams((e) => e.langsPrioritized.addAll(['en'])));
    await Future.delayed(const Duration(milliseconds: 10));
    expect(inited, isTrue);
  });

  test('will not give langs until user params controllers returns params',
      () async {
    final completer = Completer<UserParams>();
    final mockUserParamsController = MockUserParamsController();
    when(mockUserParamsController.getUserParams())
        .thenAnswer((_) => completer.future);

    userLangsManager = ManualUserLangsManager(
        mockUserParamsController, backend, FakeAnalytics());

    var langsObtained = false;
    unawaited(
        userLangsManager.getUserLangs().then((_) => langsObtained = true));

    await Future.delayed(const Duration(milliseconds: 10));
    expect(langsObtained, isFalse);

    completer.complete(UserParams((e) => e.langsPrioritized.addAll(['en'])));
    await Future.delayed(const Duration(milliseconds: 10));
    expect(langsObtained, isTrue);
  });

  test('set langs - good scenario', () async {
    final initialUserParams = UserParams((e) => e.name = 'Bob');

    await userParamsController.setUserParams(initialUserParams);
    userLangsManager =
        ManualUserLangsManager(userParamsController, backend, FakeAnalytics());

    when(backend.updateUserParams(any)).thenAnswer((_) async => Ok(true));

    final expectedFinalUserParams = initialUserParams.rebuild((e) =>
        e..langsPrioritized.addAll([LangCode.en.name, LangCode.nl.name]));

    verifyNever(backend.updateUserParams(any));
    expect(
        await userParamsController.getUserParams(), equals(initialUserParams));

    final res = await userLangsManager.setUserLangs([LangCode.en, LangCode.nl]);
    expect(res.isOk, isTrue);
    verify(backend.updateUserParams(expectedFinalUserParams));
    expect(await userParamsController.getUserParams(),
        equals(expectedFinalUserParams));
  });

  test('set langs - network error', () async {
    final initialUserParams = UserParams((e) => e.name = 'Bob');
    await userParamsController.setUserParams(initialUserParams);
    userLangsManager =
        ManualUserLangsManager(userParamsController, backend, FakeAnalytics());

    when(backend.updateUserParams(any)).thenAnswer((_) async => Err(
        BackendError.fromResp(BackendResponse.fromError(
            const SocketException(''), Uri.tryParse('ya.ru')))));

    final res = await userLangsManager.setUserLangs([LangCode.en, LangCode.nl]);
    expect(res.unwrapErr(), equals(UserLangsManagerError.NETWORK));

    // Verify user params are not changed
    expect(
        await userParamsController.getUserParams(), equals(initialUserParams));
  });

  test('set langs - other error', () async {
    final initialUserParams = UserParams((e) => e.name = 'Bob');
    await userParamsController.setUserParams(initialUserParams);
    userLangsManager =
        ManualUserLangsManager(userParamsController, backend, FakeAnalytics());

    when(backend.updateUserParams(any))
        .thenAnswer((_) async => Err(BackendError.other()));

    final res = await userLangsManager.setUserLangs([LangCode.en, LangCode.nl]);
    expect(res.unwrapErr(), equals(UserLangsManagerError.OTHER));

    // Verify user params are not changed
    expect(
        await userParamsController.getUserParams(), equals(initialUserParams));
  });

  test('set langs - analytics', () async {
    await userParamsController.setUserParams(UserParams((e) => e.name = 'Bob'));
    final analytics = FakeAnalytics();
    userLangsManager =
        ManualUserLangsManager(userParamsController, backend, analytics);
    when(backend.updateUserParams(any)).thenAnswer((_) async => Ok(true));

    expect(analytics.allEvents(), isEmpty);

    // Single lang
    var res = await userLangsManager.setUserLangs([LangCode.en]);
    expect(res.isOk, isTrue);
    expect(analytics.wasEventSent('single_manual_user_lang'), isTrue);
    expect(analytics.wasEventSent('multiple_manual_user_langs'), isFalse);
    expect(analytics.wasEventSent('zero_manual_user_langs'), isFalse);

    // Multiple langs
    analytics.clearEvents();
    res = await userLangsManager.setUserLangs([LangCode.en, LangCode.nl]);
    expect(res.isOk, isTrue);
    expect(analytics.wasEventSent('single_manual_user_lang'), isFalse);
    expect(analytics.wasEventSent('multiple_manual_user_langs'), isTrue);
    expect(analytics.wasEventSent('zero_manual_user_langs'), isFalse);

    // 0 langs
    analytics.clearEvents();
    res = await userLangsManager.setUserLangs([]);
    expect(res.isOk, isTrue);
    expect(analytics.wasEventSent('single_manual_user_lang'), isFalse);
    expect(analytics.wasEventSent('multiple_manual_user_langs'), isFalse);
    expect(analytics.wasEventSent('zero_manual_user_langs'), isTrue);
  });
}
