import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:mockito/mockito.dart';
import 'package:plante/base/base.dart';
import 'package:plante/base/permissions_manager.dart';
import 'package:plante/base/result.dart';
import 'package:plante/location/location_controller.dart';
import 'package:plante/logging/analytics.dart';
import 'package:plante/model/shop.dart';
import 'package:plante/outside/backend/backend_shop.dart';
import 'package:plante/outside/map/address_obtainer.dart';
import 'package:plante/outside/map/osm_address.dart';
import 'package:plante/outside/map/osm_shop.dart';
import 'package:plante/outside/map/shops_manager.dart';
import 'package:plante/outside/map/shops_manager_types.dart';
import 'package:plante/ui/map/latest_camera_pos_storage.dart';

import '../../common_mocks.mocks.dart';
import '../../fake_analytics.dart';
import '../../fake_shared_preferences.dart';

class MapPageModesTestCommons {
  late MockPermissionsManager permissionsManager;
  late MockShopsManager shopsManager;
  late MockLocationController locationController;
  late MockGoogleMapController mapController;
  late FakeSharedPreferences prefs;
  late MockLatestCameraPosStorage latestCameraPosStorage;
  late FakeAnalytics analytics;
  late MockAddressObtainer addressObtainer;

  final shopsManagerListeners = <ShopsManagerListener>[];

  final FutureAddress readyAddress =
      Future.value(Ok(OsmAddress((e) => e..road = 'Broadway')));

  final shops = [
    Shop((e) => e
      ..osmShop.replace(OsmShop((e) => e
        ..osmId = '0'
        ..longitude = 10
        ..latitude = 10
        ..name = 'Spar0'))
      ..backendShop.replace(BackendShop((e) => e
        ..osmId = '0'
        ..productsCount = 0))),
    Shop((e) => e
      ..osmShop.replace(OsmShop((e) => e
        ..osmId = '1'
        ..longitude = 11
        ..latitude = 11
        ..name = 'Spar1'))
      ..backendShop.replace(BackendShop((e) => e
        ..osmId = '1'
        ..productsCount = 1))),
    Shop((e) => e
      ..osmShop.replace(OsmShop((e) => e
        ..osmId = '2'
        ..longitude = 12
        ..latitude = 12
        ..name = 'Spar2'))
      ..backendShop.replace(BackendShop((e) => e
        ..osmId = '2'
        ..productsCount = 2))),
    Shop((e) => e
      ..osmShop.replace(OsmShop((e) => e
        ..osmId = '3'
        ..longitude = 13
        ..latitude = 13
        ..name = 'Spar3'))
      ..backendShop.replace(BackendShop((e) => e
        ..osmId = '3'
        ..productsCount = 3))),
  ];
  late Map<String, Shop> shopsMap;

  Future<void> setUp() async {
    fillFetchedShops();

    await GetIt.I.reset();
    analytics = FakeAnalytics();
    GetIt.I.registerSingleton<Analytics>(analytics);

    permissionsManager = MockPermissionsManager();
    GetIt.I.registerSingleton<PermissionsManager>(permissionsManager);
    shopsManager = MockShopsManager();
    GetIt.I.registerSingleton<ShopsManager>(shopsManager);
    locationController = MockLocationController();
    GetIt.I.registerSingleton<LocationController>(locationController);
    mapController = MockGoogleMapController();
    prefs = FakeSharedPreferences();
    latestCameraPosStorage = MockLatestCameraPosStorage();
    GetIt.I.registerSingleton<LatestCameraPosStorage>(latestCameraPosStorage);
    addressObtainer = MockAddressObtainer();
    GetIt.I.registerSingleton<AddressObtainer>(addressObtainer);

    shopsManagerListeners.clear();
    when(shopsManager.addListener(any)).thenAnswer((invc) {
      final listener = invc.positionalArguments[0] as ShopsManagerListener;
      shopsManagerListeners.add(listener);
    });
    when(shopsManager.removeListener(any)).thenAnswer((invc) {
      final listener = invc.positionalArguments[0] as ShopsManagerListener;
      shopsManagerListeners.remove(listener);
    });

    when(shopsManager.fetchShops(any, any))
        .thenAnswer((_) async => Ok(shopsMap));

    when(locationController.lastKnownPositionInstant()).thenReturn(null);
    when(locationController.lastKnownPosition()).thenAnswer((_) async => null);
    when(locationController.currentPosition()).thenAnswer((_) async => null);
    when(mapController.getVisibleRegion()).thenAnswer((_) async => LatLngBounds(
        southwest: const LatLng(10, 10), northeast: const LatLng(20, 20)));
    when(mapController.dispose()).thenAnswer((_) {});
    when(mapController.setMapStyle(any)).thenAnswer((_) async {});
    when(mapController.getZoomLevel()).thenAnswer((_) async => 10);
    when(shopsManager.putProductToShops(any, any))
        .thenAnswer((_) async => Ok(None()));
    when(shopsManager.createShop(
            name: anyNamed('name'),
            coords: anyNamed('coords'),
            type: anyNamed('type')))
        .thenAnswer((invc) async {
      final name = invc.namedArguments[const Symbol('name')] as String;
      final coords =
          invc.namedArguments[const Symbol('coords')] as Point<double>;
      final id = randInt(100, 500);
      return Ok(Shop((e) => e
        ..osmShop.replace(OsmShop((e) => e
          ..osmId = id.toString()
          ..longitude = coords.x
          ..latitude = coords.y
          ..name = name))
        ..backendShop.replace(BackendShop((e) => e
          ..osmId = id.toString()
          ..productsCount = 0))));
    });
    when(permissionsManager.openAppSettings()).thenAnswer((_) async => true);
    when(permissionsManager.status(any))
        .thenAnswer((_) async => PermissionState.granted);

    when(latestCameraPosStorage.get()).thenAnswer((_) async => null);
    when(latestCameraPosStorage.getCached()).thenAnswer((_) => null);
    when(latestCameraPosStorage.set(any)).thenAnswer((_) async {});

    when(addressObtainer.addressOfShop(any)).thenAnswer((_) => readyAddress);
    when(addressObtainer.addressOfCoords(any)).thenAnswer((_) => readyAddress);
  }

  void fillFetchedShops() {
    shopsMap = {for (final shop in shops) shop.osmId: shop};
  }

  void clearFetchedShops() {
    shopsMap = {};
  }
}
