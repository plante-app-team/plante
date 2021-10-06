import 'package:plante/model/user_params.dart';
import 'package:plante/outside/backend/mobile_app_config.dart';
import 'package:plante/outside/backend/mobile_app_config_manager.dart';

/// Fake config manager to simplify testing.
class FakeMobileAppConfigManager implements MobileAppConfigManager {
  final _observers = <MobileAppConfigManagerObserver>[];
  MobileAppConfig? _config;

  FakeMobileAppConfigManager({MobileAppConfig? defaultConfig}) {
    _config = defaultConfig ?? MobileAppConfig((e) => e
      ..remoteUserParams.replace(UserParams((e) => e
          ..backendId = '321'
          ..name = 'Bob')
      )
      ..nominatimEnabled = true
    );
  }

  @override
  Future<void> get initFuture => Future.value();

  @override
  Future<MobileAppConfig?> getConfig() async {
    return _config;
  }

  @override
  void addObserver(MobileAppConfigManagerObserver observer) => _observers.add(observer);

  @override
  void removeObserver(MobileAppConfigManagerObserver observer) => _observers.remove(observer);

  @override
  void onUserParamsUpdate(UserParams? userParams) {
    throw UnimplementedError();
  }
}
