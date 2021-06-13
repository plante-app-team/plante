import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:plante/base/permissions_manager.dart';
import 'package:plante/base/result.dart';
import 'package:plante/location/location_controller.dart';
import 'package:plante/model/shop.dart';
import 'package:plante/outside/backend/backend_shop.dart';
import 'package:plante/outside/map/osm_shop.dart';
import 'package:plante/outside/map/shops_manager.dart';

import 'map_page_modes_test_commons.mocks.dart';

@GenerateMocks([PermissionsManager, ShopsManager, LocationController,
  GoogleMapController])
class MapPageModesTestCommons {
  late MockPermissionsManager permissionsManager;
  late MockShopsManager shopsManager;
  late MockLocationController locationController;
  late MockGoogleMapController mapController;

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
  late final Map<String, Shop> shopsMap;

  Future<void> setUp() async {
    shopsMap = { for (final shop in shops) shop.osmId: shop };

    await GetIt.I.reset();

    permissionsManager = MockPermissionsManager();
    GetIt.I.registerSingleton<PermissionsManager>(permissionsManager);
    shopsManager = MockShopsManager();
    GetIt.I.registerSingleton<ShopsManager>(shopsManager);
    locationController = MockLocationController();
    GetIt.I.registerSingleton<LocationController>(locationController);
    mapController = MockGoogleMapController();

    when(shopsManager.fetchShops(any, any)).thenAnswer((_) async =>
        Ok(shopsMap));

    when(locationController.lastKnownPositionInstant()).thenReturn(null);
    when(locationController.lastKnownPosition()).thenAnswer((_) async => null);
    when(mapController.getVisibleRegion()).thenAnswer(
            (_) async =>
            LatLngBounds(
                southwest: const LatLng(10, 10),
                northeast: const LatLng(20, 20)));
    when(mapController.dispose()).thenAnswer((_) {});
    when(shopsManager.putProductToShops(any, any)).thenAnswer((_) async => Ok(None()));
  }
}
