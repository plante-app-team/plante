import 'package:flutter/widgets.dart';
import 'package:get_it/get_it.dart';
import 'package:mockito/mockito.dart';
import 'package:plante/base/permissions_manager.dart';
import 'package:plante/base/result.dart';
import 'package:plante/base/settings.dart';
import 'package:plante/lang/input_products_lang_storage.dart';
import 'package:plante/lang/sys_lang_code_holder.dart';
import 'package:plante/lang/user_langs_manager.dart';
import 'package:plante/location/user_location_manager.dart';
import 'package:plante/logging/analytics.dart';
import 'package:plante/model/coord.dart';
import 'package:plante/model/lang_code.dart';
import 'package:plante/model/shared_preferences_holder.dart';
import 'package:plante/model/user_params.dart';
import 'package:plante/model/user_params_controller.dart';
import 'package:plante/outside/backend/backend.dart';
import 'package:plante/outside/backend/user_avatar_manager.dart';
import 'package:plante/outside/backend/user_reports_maker.dart';
import 'package:plante/outside/map/address_obtainer.dart';
import 'package:plante/outside/map/directions_manager.dart';
import 'package:plante/outside/map/displayed_distance_units_manager.dart';
import 'package:plante/outside/map/osm/osm_searcher.dart';
import 'package:plante/outside/map/roads_manager.dart';
import 'package:plante/outside/map/shops_manager.dart';
import 'package:plante/outside/map/user_address/caching_user_address_pieces_obtainer.dart';
import 'package:plante/outside/map/user_address/user_address_piece.dart';
import 'package:plante/outside/map/user_address/user_address_type.dart';
import 'package:plante/products/products_manager.dart';
import 'package:plante/products/products_obtainer.dart';
import 'package:plante/products/suggestions/suggested_products_manager.dart';
import 'package:plante/products/viewed_products_storage.dart';
import 'package:plante/ui/map/latest_camera_pos_storage.dart';
import 'package:plante/ui/map/shop_creation/shops_creation_manager.dart';
import 'package:plante/ui/photos/photos_taker.dart';

import 'common_mocks.mocks.dart';
import 'z_fakes/fake_address_obtainer.dart';
import 'z_fakes/fake_analytics.dart';
import 'z_fakes/fake_caching_user_address_pieces_obtainer.dart';
import 'z_fakes/fake_input_products_lang_storage.dart';
import 'z_fakes/fake_products_obtainer.dart';
import 'z_fakes/fake_settings.dart';
import 'z_fakes/fake_shared_preferences.dart';
import 'z_fakes/fake_shops_manager.dart';
import 'z_fakes/fake_suggested_products_manager.dart';
import 'z_fakes/fake_user_avatar_manager.dart';
import 'z_fakes/fake_user_langs_manager.dart';
import 'z_fakes/fake_user_location_manager.dart';
import 'z_fakes/fake_user_params_controller.dart';

typedef DependencyProvider = dynamic Function();

class TestDiRegistry {
  TestDiRegistry._();

  static Future<void> register(
      dynamic Function(TestDiRegistrar) callback) async {
    await GetIt.I.reset();
    final registrar = TestDiRegistrar._();
    await callback.call(registrar);
    registrar._registerDefaults();
  }
}

/// See [register]
class TestDiRegistrar {
  final _dependenciesInstances = <Type, dynamic>{};

  TestDiRegistrar._();

  /// Register an instance of the T type.
  /// Of no instances of the T type would be registered, a default value
  /// would be created.
  T register<T extends Object>(T instance) {
    _registerInstance<T>(instance);
    return instance;
  }

  void _registerDefaults() {
    _registerProvider<UserLangsManager>(
        () => FakeUserLangsManager([LangCode.en]));
    _registerProvider<UserReportsMaker>(() => MockUserReportsMaker());
    _registerProvider<ViewedProductsStorage>(() => MockViewedProductsStorage());
    _registerProvider<ShopsManager>(() => FakeShopsManager());
    _registerProvider<SharedPreferencesHolder>(
        () => FakeSharedPreferences().asHolder());
    _registerProvider<InputProductsLangStorage>(
        () => FakeInputProductsLangStorage.fromCode(LangCode.en));
    _registerProvider<PermissionsManager>(() => MockPermissionsManager());
    _registerProvider<AddressObtainer>(() => FakeAddressObtainer());
    _registerProvider<SuggestedProductsManager>(
        () => FakeSuggestedProductsManager());
    _registerProvider<ShopsCreationManager>(
        () => ShopsCreationManager(_get<ShopsManager>()));
    _registerProvider<UserLocationManager>(() => FakeUserLocationManager());
    _registerProvider<ProductsManager>(() => MockProductsManager());
    _registerProvider<Analytics>(() => FakeAnalytics());
    _registerProvider<OsmSearcher>(() => MockOsmSearcher());
    _registerProvider<Settings>(() => FakeSettings());
    _registerProvider<DisplayedDistanceUnitsManager>(() =>
        DisplayedDistanceUnitsManager(
            _get<CachingUserAddressPiecesObtainer>(), _get<Settings>()));
    _registerProvider<ProductsObtainer>(() => FakeProductsObtainer());
    _registerProvider<RouteObserver<ModalRoute>>(() => MockRouteObserver());
    _registerProvider<SysLangCodeHolder>(() => SysLangCodeHolder());

    _registerProvider<UserParamsController>(() {
      final instance = FakeUserParamsController();
      instance.setUserParams_testing(UserParams((v) => v
        ..backendClientToken = '123'
        ..backendId = '321'
        ..name = 'Bob'));
      return instance;
    });

    _registerProvider<CachingUserAddressPiecesObtainer>(() {
      final instance = FakeCachingUserAddressPiecesObtainer();
      instance.setResultFor(
          UserAddressType.CAMERA_LOCATION, UserAddressPiece.COUNTRY_CODE, 'de');
      return instance;
    });

    _registerProvider<DirectionsManager>(() {
      final instance = MockDirectionsManager();
      when(instance.areDirectionsAvailable()).thenAnswer((_) async => false);
      return instance;
    });

    _registerProvider<PhotosTaker>(() {
      final instance = MockPhotosTaker();
      when(instance.retrieveLostPhoto(any)).thenAnswer((_) async => null);
      return instance;
    });

    _registerProvider<LatestCameraPosStorage>(() {
      final instance = LatestCameraPosStorage(_get<SharedPreferencesHolder>());
      instance.set(Coord(lat: 10, lon: 20));
      return instance;
    });

    _registerProvider<RoadsManager>(() {
      final instance = MockRoadsManager();
      when(instance.fetchRoadsWithinAndNearby(any))
          .thenAnswer((_) async => Ok(const []));
      return instance;
    });

    _registerProvider<UserAvatarManager>(() {
      final userParamsController =
          _get<UserParamsController>() as FakeUserParamsController;
      final instance = FakeUserAvatarManager(userParamsController);
      return instance;
    });

    _registerProvider<Backend>(() {
      final instance = MockBackend();
      when(instance.sendProductScan(any)).thenAnswer((_) async => Ok(None()));
      return instance;
    });
  }

  T _get<T extends Object>() {
    return GetIt.I.get<T>();
  }

  void _registerInstance<T extends Object>(T instance) {
    if (_dependenciesInstances.containsKey(T)) {
      throw ArgumentError(
          '$T is already registered: ${_dependenciesInstances[T]}');
    }
    _dependenciesInstances[T] = instance;
    GetIt.I.registerSingleton<T>(instance);
  }

  void _registerProvider<T extends Object>(DependencyProvider provider) {
    if (!_dependenciesInstances.containsKey(T)) {
      GetIt.I.registerFactory<T>(() {
        var instance = _dependenciesInstances[T] as T?;
        if (instance != null) {
          return instance;
        }
        instance = provider.call() as T;
        _dependenciesInstances[T] = instance;
        return instance;
      });
    }
  }
}
