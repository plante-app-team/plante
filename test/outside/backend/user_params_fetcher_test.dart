import 'dart:async';

import 'package:mockito/mockito.dart';
import 'package:plante/model/user_params.dart';
import 'package:plante/model/user_params_controller.dart';
import 'package:plante/outside/backend/mobile_app_config.dart';
import 'package:plante/outside/backend/mobile_app_config_manager.dart';
import 'package:plante/outside/backend/user_params_fetcher.dart';
import 'package:test/test.dart';

import '../../common_mocks.mocks.dart';
import '../../z_fakes/fake_user_params_controller.dart';

void main() {
  late FakeUserParamsController userParamsController;
  late MockMobileAppConfigManager mobileAppConfigManager;
  late List<MobileAppConfigManagerObserver> mobileAppConfigManagerObservers;
  late UserParamsFetcher userParamsFetcher;

  setUp(() {
    userParamsController = FakeUserParamsController();
    mobileAppConfigManager = MockMobileAppConfigManager();
    mobileAppConfigManagerObservers = [];
    when(mobileAppConfigManager.addObserver(any)).thenAnswer((invc) {
      mobileAppConfigManagerObservers
          .add(invc.positionalArguments[0] as MobileAppConfigManagerObserver);
    });

    userParamsFetcher =
        UserParamsFetcher(userParamsController, mobileAppConfigManager);
    userParamsFetcher.toString(); // Making it used
  });

  test('updates user params on remote user params changes', () async {
    final initialParams = UserParams((e) => e
      ..backendId = '123'
      ..backendClientToken = '321'
      ..name = 'Bob');
    await userParamsController.setUserParams(initialParams);
    final userParamsObserver = _FakeObserver();
    userParamsController.addObserver(userParamsObserver);

    expect(await userParamsController.getUserParams(), equals(initialParams));
    expect(userParamsObserver.notificationsCount, equals(0));

    final remoteUserParams = UserParams((e) => e
          ..backendId = '123'
          ..backendClientToken = null // Backend doesn't provide us with token
          ..name = 'Bob Kelso' // Bame updated
        );
    final config = MobileAppConfig((e) => e
      ..remoteUserParams.replace(remoteUserParams)
      ..nominatimEnabled = false);
    when(mobileAppConfigManager.getConfig()).thenAnswer((_) async => config);
    mobileAppConfigManagerObservers
        .forEach((e) => e.onMobileAppConfigChange(config));
    await Future.delayed(const Duration(milliseconds: 10));

    var expectedUserParams = remoteUserParams;
    // We expect UserParamsFetcher to set backend token manually
    expectedUserParams = expectedUserParams.rebuild(
        (e) => e..backendClientToken = initialParams.backendClientToken);
    // We expect UserParamsFetcher to force-set user to be a vegan
    expectedUserParams = expectedUserParams.rebuild((e) => e
      ..eatsHoney = false
      ..eatsMilk = false
      ..eatsEggs = false);

    expect(await userParamsController.getUserParams(),
        isNot(equals(initialParams)));
    expect(
        await userParamsController.getUserParams(), equals(expectedUserParams));
    expect(userParamsObserver.notificationsCount, equals(1));
  });

  test('does not change user params when there is no remote config', () async {
    final initialParams = UserParams((e) => e
      ..backendId = '123'
      ..backendClientToken = '321'
      ..name = 'Bob');
    await userParamsController.setUserParams(initialParams);

    expect(await userParamsController.getUserParams(), equals(initialParams));

    const MobileAppConfig? remoteConfig = null;
    when(mobileAppConfigManager.getConfig())
        .thenAnswer((_) async => remoteConfig);
    mobileAppConfigManagerObservers
        .forEach((e) => e.onMobileAppConfigChange(remoteConfig));
    await Future.delayed(const Duration(milliseconds: 10));

    expect(await userParamsController.getUserParams(), equals(initialParams));
  });

  test('does not change user params when there are no initial params',
      () async {
    expect(await userParamsController.getUserParams(), isNull);

    final remoteUserParams = UserParams((e) => e
          ..backendId = '123'
          ..backendClientToken = null // Backend doesn't provide us with token
          ..name = 'Bob Kelso' // Bame updated
        );
    final config = MobileAppConfig((e) => e
      ..remoteUserParams.replace(remoteUserParams)
      ..nominatimEnabled = false);
    when(mobileAppConfigManager.getConfig()).thenAnswer((_) async => config);
    mobileAppConfigManagerObservers
        .forEach((e) => e.onMobileAppConfigChange(config));
    await Future.delayed(const Duration(milliseconds: 10));

    // Still null is expected
    expect(await userParamsController.getUserParams(), isNull);
  });

  test('does not change user params when new params equal to old params',
      () async {
    final initialParams = UserParams((e) => e
      ..backendId = '123'
      ..backendClientToken = '321'
      ..name = 'Bob'
      ..eatsHoney = false
      ..eatsMilk = false
      ..eatsEggs = false);
    await userParamsController.setUserParams(initialParams);
    final userParamsObserver = _FakeObserver();
    userParamsController.addObserver(userParamsObserver);

    final config = MobileAppConfig((e) => e
      ..remoteUserParams.replace(initialParams)
      ..nominatimEnabled = false);
    when(mobileAppConfigManager.getConfig()).thenAnswer((_) async => config);
    mobileAppConfigManagerObservers
        .forEach((e) => e.onMobileAppConfigChange(config));
    await Future.delayed(const Duration(milliseconds: 10));

    // Expected params to no change
    expect(await userParamsController.getUserParams(), equals(initialParams));
    // Expecting not change notifications
    expect(userParamsObserver.notificationsCount, equals(0));
  });
}

class _FakeObserver implements UserParamsControllerObserver {
  int notificationsCount = 0;
  @override
  void onUserParamsUpdate(UserParams? userParams) {
    notificationsCount += 1;
  }
}
