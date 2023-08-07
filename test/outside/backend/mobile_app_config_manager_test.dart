import 'dart:async';
import 'dart:convert';

import 'package:plante/base/result.dart';
import 'package:plante/model/user_params.dart';
import 'package:plante/outside/backend/cmds/mobile_app_config_cmd.dart';
import 'package:plante/outside/backend/mobile_app_config.dart';
import 'package:plante/outside/backend/mobile_app_config_manager.dart';
import 'package:test/test.dart';

import '../../z_fakes/fake_backend.dart';
import '../../z_fakes/fake_shared_preferences.dart';
import '../../z_fakes/fake_user_params_controller.dart';

void main() {
  late FakeBackend backend;
  late FakeUserParamsController userParamsController;
  late FakeSharedPreferences prefs;

  setUp(() {
    backend = FakeBackend();
    userParamsController = FakeUserParamsController();
    prefs = FakeSharedPreferences();
  });

  test('first initialization scenario', () async {
    final remoteConfig = MobileAppConfig((e) => e
      ..remoteUserParams.replace(UserParams((e) => e.backendId = '123'))
      ..nominatimEnabled = true);
    backend.setResponse_testing(
        MOBILE_APP_CONFIG_CMD, jsonEncode(remoteConfig.toJson()));
    final observer = _FakeObserver();

    final mobileAppConfigManager =
        MobileAppConfigManager(backend, userParamsController, prefs.asHolder());
    mobileAppConfigManager.addObserver(observer);

    MobileAppConfig? obtainedConfig;
    unawaited(mobileAppConfigManager
        .getConfig()
        .then((value) => obtainedConfig = value));
    expect(obtainedConfig, isNull);
    expect(
        prefs.getString(MobileAppConfigManager.PREF_MOBILE_APP_CONFIG), isNull);
    expect(observer.lastConfigChangeValue, isNull);

    await mobileAppConfigManager.initFuture;
    await Future.delayed(const Duration(milliseconds: 10));

    obtainedConfig = await mobileAppConfigManager.getConfig();
    expect(obtainedConfig, equals(remoteConfig));
    expect(prefs.getString(MobileAppConfigManager.PREF_MOBILE_APP_CONFIG),
        isNotNull);
    expect(observer.lastConfigChangeValue, equals(remoteConfig));
  });

  test('second initialization scenario', () async {
    final remoteConfig1 = MobileAppConfig((e) => e
      ..remoteUserParams.replace(UserParams((e) => e.backendId = '123'))
      ..nominatimEnabled = true);
    backend.setResponse_testing(
        MOBILE_APP_CONFIG_CMD, jsonEncode(remoteConfig1.toJson()));

    // First init
    final mobileAppConfigManager1 =
        MobileAppConfigManager(backend, userParamsController, prefs.asHolder());
    await mobileAppConfigManager1.initFuture;
    await Future.delayed(const Duration(milliseconds: 10));

    // Second init
    // Remote config 2 will be obtained from the backend with a delay
    final remoteConfig2Completer = Completer<MobileAppConfig>();
    backend.setResponseAsyncFunction_testing(
        MOBILE_APP_CONFIG_CMD,
        (argument) async =>
            Ok(jsonEncode((await remoteConfig2Completer.future).toJson())));

    final mobileAppConfigManager2 =
        MobileAppConfigManager(backend, userParamsController, prefs.asHolder());
    final observer = _FakeObserver();
    mobileAppConfigManager2.addObserver(observer);
    await mobileAppConfigManager2.initFuture;

    // Old config is expected while backend hasn't responded
    expect(await mobileAppConfigManager2.getConfig(), equals(remoteConfig1));
    // Observer expected to be not notified about the
    // initial config loaded from prefs
    expect(observer.lastConfigChangeValue, isNull);
    final config1InPrefs =
        prefs.getString(MobileAppConfigManager.PREF_MOBILE_APP_CONFIG);

    // The backend responds!
    final remoteConfig2 = MobileAppConfig((e) => e
      ..remoteUserParams.replace(UserParams((e) => e.backendId = '321'))
      ..nominatimEnabled = false);
    remoteConfig2Completer.complete(remoteConfig2);
    await Future.delayed(const Duration(milliseconds: 10));

    expect(remoteConfig2, isNot(equals(remoteConfig1)));
    // Config 2 now is expected
    expect(await mobileAppConfigManager2.getConfig(), equals(remoteConfig2));
    // Observer expected to be notified about the second config
    expect(observer.lastConfigChangeValue, equals(remoteConfig2));
    // Second config expected to be stored in prefs now
    final config2InPrefs =
        prefs.getString(MobileAppConfigManager.PREF_MOBILE_APP_CONFIG);
    expect(config2InPrefs, isNot(equals(config1InPrefs)));
  });

  test('invalid config in prefs on second initialization', () async {
    final remoteConfig1 = MobileAppConfig((e) => e
      ..remoteUserParams.replace(UserParams((e) => e.backendId = '123'))
      ..nominatimEnabled = true);
    backend.setResponse_testing(
        MOBILE_APP_CONFIG_CMD, jsonEncode(remoteConfig1.toJson()));

    // First init
    final mobileAppConfigManager1 =
        MobileAppConfigManager(backend, userParamsController, prefs.asHolder());
    await mobileAppConfigManager1.initFuture;
    await Future.delayed(const Duration(milliseconds: 10));

    // Let's corrupt the stored config!
    await prefs.setString(
        MobileAppConfigManager.PREF_MOBILE_APP_CONFIG, 'Ahaha!');

    // Second init
    // Remote config 2 will be obtained from the backend with a delay
    final remoteConfig2Completer = Completer<MobileAppConfig>();
    backend.setResponseAsyncFunction_testing(
        MOBILE_APP_CONFIG_CMD,
        (argument) async =>
            Ok(jsonEncode((await remoteConfig2Completer.future).toJson())));

    final mobileAppConfigManager2 =
        MobileAppConfigManager(backend, userParamsController, prefs.asHolder());
    await mobileAppConfigManager2.initFuture;

    // Prefs are expected to be cleared
    expect(
        prefs.getString(MobileAppConfigManager.PREF_MOBILE_APP_CONFIG), isNull);
    // Null config is expected while backend hasn't responded
    expect(await mobileAppConfigManager2.getConfig(), isNull);

    // The backend responds!
    final remoteConfig2 = MobileAppConfig((e) => e
      ..remoteUserParams.replace(UserParams((e) => e.backendId = '321'))
      ..nominatimEnabled = false);
    remoteConfig2Completer.complete(remoteConfig2);
    await Future.delayed(const Duration(milliseconds: 10));

    // Prefs are expected to be refilled
    expect(prefs.getString(MobileAppConfigManager.PREF_MOBILE_APP_CONFIG),
        isNotNull);
    // Config 2 now is expected
    expect(await mobileAppConfigManager2.getConfig(), equals(remoteConfig2));
  });

  test('second initialization backend config is same as the old one', () async {
    final remoteConfig = MobileAppConfig((e) => e
      ..remoteUserParams.replace(UserParams((e) => e.backendId = '123'))
      ..nominatimEnabled = true);
    backend.setResponse_testing(
        MOBILE_APP_CONFIG_CMD, jsonEncode(remoteConfig.toJson()));

    // First init
    final mobileAppConfigManager1 =
        MobileAppConfigManager(backend, userParamsController, prefs.asHolder());
    await mobileAppConfigManager1.initFuture;
    await Future.delayed(const Duration(milliseconds: 10));

    backend.resetRequests_testing();
    expect(backend.getRequestsMatching_testing(MOBILE_APP_CONFIG_CMD), isEmpty);

    // Second init
    final mobileAppConfigManager2 =
        MobileAppConfigManager(backend, userParamsController, prefs.asHolder());
    final observer = _FakeObserver();
    mobileAppConfigManager2.addObserver(observer);
    await mobileAppConfigManager2.initFuture;
    await Future.delayed(const Duration(milliseconds: 10));

    // Verify the backend was queried
    expect(backend.getRequestsMatching_testing(MOBILE_APP_CONFIG_CMD),
        isNot(isEmpty));
    // The config is expected to be the same
    expect(await mobileAppConfigManager2.getConfig(), equals(remoteConfig));
    // Observer expected to be not notified about the
    // second config because it's same as the first one
    expect(observer.lastConfigChangeValue, isNull);
  });

  test('backend error on first initialization', () async {
    backend.setResponse_testing(MOBILE_APP_CONFIG_CMD, '', responseCode: 500);

    // First init
    final mobileAppConfigManager =
        MobileAppConfigManager(backend, userParamsController, prefs.asHolder());
    await mobileAppConfigManager.initFuture;
    await Future.delayed(const Duration(milliseconds: 10));

    expect(await mobileAppConfigManager.getConfig(), isNull);
  });

  test('backend error on second initialization', () async {
    final remoteConfig = MobileAppConfig((e) => e
      ..remoteUserParams.replace(UserParams((e) => e.backendId = '123'))
      ..nominatimEnabled = true);
    backend.setResponse_testing(
        MOBILE_APP_CONFIG_CMD, jsonEncode(remoteConfig.toJson()));

    // First init
    final mobileAppConfigManager1 =
        MobileAppConfigManager(backend, userParamsController, prefs.asHolder());
    await mobileAppConfigManager1.initFuture;
    await Future.delayed(const Duration(milliseconds: 10));

    backend.reset_testing();
    expect(backend.getRequestsMatching_testing(MOBILE_APP_CONFIG_CMD), isEmpty);
    backend.setResponse_testing(MOBILE_APP_CONFIG_CMD, '', responseCode: 500);

    // Second init
    final mobileAppConfigManager2 =
        MobileAppConfigManager(backend, userParamsController, prefs.asHolder());
    final observer = _FakeObserver();
    mobileAppConfigManager2.addObserver(observer);
    await mobileAppConfigManager2.initFuture;
    await Future.delayed(const Duration(milliseconds: 10));

    // Verify the backend was queried
    expect(backend.getRequestsMatching_testing(MOBILE_APP_CONFIG_CMD),
        isNot(isEmpty));
    // The config is expected to be the same
    expect(await mobileAppConfigManager2.getConfig(), equals(remoteConfig));
    // Observer expected to be not notified because there was no
    // second config
    expect(observer.lastConfigChangeValue, isNull);
  });

  test('user params controller user params changes', () async {
    final userParams = UserParams((e) => e.backendId = '123');
    final remoteConfig = MobileAppConfig((e) => e
      ..remoteUserParams.replace(userParams)
      ..nominatimEnabled = true);
    backend.setResponse_testing(
        MOBILE_APP_CONFIG_CMD, jsonEncode(remoteConfig.toJson()));
    await userParamsController.setUserParams(userParams);

    final mobileAppConfigManager =
        MobileAppConfigManager(backend, userParamsController, prefs.asHolder());
    await mobileAppConfigManager.initFuture;
    await Future.delayed(const Duration(milliseconds: 10));
    final observer = _FakeObserver();
    mobileAppConfigManager.addObserver(observer);

    // Ok config, no notifications
    expect(await mobileAppConfigManager.getConfig(), equals(remoteConfig));
    expect(observer.notificationsCount, equals(0));

    // User params are erased for some reason
    await userParamsController.setUserParams(null);
    await Future.delayed(const Duration(milliseconds: 10));

    // No config, 1 notification
    expect(await mobileAppConfigManager.getConfig(), isNull);
    expect(observer.notificationsCount, equals(1));
    expect(observer.lastConfigChangeValue, isNull);

    // User params are back!
    backend.resetRequests_testing();
    await userParamsController.setUserParams(userParams);
    await Future.delayed(const Duration(milliseconds: 10));

    // Backend is queried again
    expect(backend.getRequestsMatching_testing(MOBILE_APP_CONFIG_CMD),
        isNot(isEmpty));
    // Ok config, another notification
    expect(await mobileAppConfigManager.getConfig(), equals(remoteConfig));
    expect(observer.notificationsCount, equals(2));
    expect(observer.lastConfigChangeValue, equals(remoteConfig));
  });
}

class _FakeObserver implements MobileAppConfigManagerObserver {
  int notificationsCount = 0;
  MobileAppConfig? lastConfigChangeValue;
  @override
  void onMobileAppConfigChange(MobileAppConfig? config) {
    notificationsCount += 1;
    lastConfigChangeValue = config;
  }
}
