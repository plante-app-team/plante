
import 'package:flutter_test/flutter_test.dart';
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
import 'package:plante/ui/map/map_page_model.dart';

import 'map_page_model_test.mocks.dart';

@GenerateMocks([LocationController, ShopsManager, PermissionsManager])
void main() {
  late MockLocationController locationController;
  late MockShopsManager shopsManager;
  late MockPermissionsManager permissionsManager;
  late MapPageModel model;

  Map<String, Shop>? latestLoadedShops;
  MapPageModelError? latestError;

  final shops = {
    '1234': Shop((e) => e
      ..osmShop.replace(OsmShop((e) => e
        ..osmId = '1234'
        ..longitude = 11
        ..latitude = 11
        ..name = 'Spar'
        ..type = 'Supermarket'))
      ..backendShop.replace(BackendShop((e) => e
        ..osmId = '1234'
        ..productsCount = 3)))
  };

  setUp(() async {
    latestLoadedShops = null;
    latestError = null;

    locationController = MockLocationController();
    shopsManager = MockShopsManager();
    permissionsManager = MockPermissionsManager();

    model = MapPageModel(locationController, permissionsManager, shopsManager,
        (shops) {
          latestLoadedShops = shops;
        },
        (error) {
          latestError = error;
        },
        () {});
  });

  test('successful shops load', () async {
    when(shopsManager.fetchShops(any, any)).thenAnswer((_) async => Ok(shops));

    expect(latestLoadedShops, isNull);
    expect(latestError, isNull);

    await model.onCameraMoved(LatLngBounds(
      southwest: const LatLng(14.999, 14.999),
      northeast: const LatLng(15.001, 15.001)));

    expect(latestLoadedShops, equals(shops));
    expect(latestError, isNull);
  });

  test('multiple failed shops load attempts and 1 successful', () async {
    int attempts = 0;
    when(shopsManager.fetchShops(any, any)).thenAnswer((_) async {
      attempts += 1;
      if (attempts < MapPageModel.MAX_SHOPS_LOADS_ATTEMPTS) {
        return Err(ShopsManagerError.OTHER);
      } else {
        return Ok(shops);
      }
    });

    expect(latestLoadedShops, isNull);
    expect(latestError, isNull);
    await model.onCameraMoved(LatLngBounds(
        southwest: const LatLng(14.999, 14.999),
        northeast: const LatLng(15.001, 15.001)));
    expect(latestLoadedShops, equals(shops));
    expect(latestError, isNull);

    expect(attempts, equals(MapPageModel.MAX_SHOPS_LOADS_ATTEMPTS));
  });

  test('all shops loads failed', () async {
    when(shopsManager.fetchShops(any, any)).thenAnswer((_) async =>
        Err(ShopsManagerError.OTHER));

    expect(latestLoadedShops, isNull);
    expect(latestError, isNull);
    await model.onCameraMoved(LatLngBounds(
        southwest: const LatLng(14.999, 14.999),
        northeast: const LatLng(15.001, 15.001)));
    expect(latestLoadedShops, isNull);
    expect(latestError, equals(MapPageModelError.OTHER));
  });

  test('show loading network error makes only for 1 load attempt', () async {
    int attempts = 0;
    when(shopsManager.fetchShops(any, any)).thenAnswer((_) async {
      attempts += 1;
      return Err(ShopsManagerError.NETWORK_ERROR);
    });

    expect(latestLoadedShops, isNull);
    expect(latestError, isNull);
    await model.onCameraMoved(LatLngBounds(
        southwest: const LatLng(14.999, 14.999),
        northeast: const LatLng(15.001, 15.001)));
    expect(latestLoadedShops, isNull);
    expect(latestError, equals(MapPageModelError.NETWORK_ERROR));

    expect(attempts, equals(1));
  });

  test('shops load not performed when view bounds already loaded', () async {
    int attempts = 0;
    when(shopsManager.fetchShops(any, any)).thenAnswer((_) async {
      attempts += 1;
      return Ok(shops);
    });

    expect(latestLoadedShops, isNull);
    expect(latestError, isNull);
    verifyNever(shopsManager.fetchShops(any, any));

    await model.onCameraMoved(LatLngBounds(
        southwest: const LatLng(14.999, 14.999),
        northeast: const LatLng(15.001, 15.001)));
    expect(latestLoadedShops, equals(shops));
    expect(latestError, isNull);
    verify(shopsManager.fetchShops(any, any)).called(1);
    expect(attempts, equals(1));

    await model.onCameraMoved(LatLngBounds(
        southwest: const LatLng(14.999, 14.999),
        northeast: const LatLng(15.001, 15.001)));
    expect(latestLoadedShops, equals(shops));
    expect(latestError, isNull);
    // Attempts number is expected to be 1,
    // because shops are expected to be cached
    verifyNever(shopsManager.fetchShops(any, any));
    expect(attempts, equals(1));
  });

  test('shops load IS performed when far-away view bounds were loaded before', () async {
    int attempts = 0;
    when(shopsManager.fetchShops(any, any)).thenAnswer((_) async {
      attempts += 1;
      return Ok(shops);
    });

    expect(latestLoadedShops, isNull);
    expect(latestError, isNull);
    verifyNever(shopsManager.fetchShops(any, any));

    await model.onCameraMoved(LatLngBounds(
        southwest: const LatLng(14.999, 14.999),
        northeast: const LatLng(15.001, 15.001)));
    expect(latestLoadedShops, equals(shops));
    expect(latestError, isNull);
    verify(shopsManager.fetchShops(any, any)).called(1);
    expect(attempts, equals(1));

    await model.onCameraMoved(LatLngBounds(
        southwest: const LatLng(15.999, 15.999),
        northeast: const LatLng(16.001, 16.001)));
    expect(latestLoadedShops, equals(shops));
    expect(latestError, isNull);
    // Attempts number is expected to be 2,
    // because new request is about very far-away view bounds.
    verify(shopsManager.fetchShops(any, any)).called(1);
    expect(attempts, equals(2));
  });

  test('if 2 shops loads start while under cooldown, only second load is performed', () async {
    int attempts = 0;
    when(shopsManager.fetchShops(any, any)).thenAnswer((_) async {
      attempts += 1;
      return Ok(shops);
    });

    // Perform a first load so that the cooldown would start
    await model.onCameraMoved(LatLngBounds(
        southwest: const LatLng(15.999, 15.999),
        northeast: const LatLng(16.001, 16.001)));
    expect(attempts, equals(1));

    // Now start the second load without 'await'
    () {
      model.onCameraMoved(LatLngBounds(
          southwest: const LatLng(16.999, 16.999),
          northeast: const LatLng(17.001, 17.001)));
    }.call();
    // Wait a little bit
    // (note that this might cause a race condition on slow test runners)
    await Future.delayed(const Duration(milliseconds: 1));
    // Perform the second load
    await model.onCameraMoved(LatLngBounds(
        southwest: const LatLng(17.999, 17.999),
        northeast: const LatLng(18.001, 18.001)));

    // We expect that there were only 2 load attempts
    expect(attempts, equals(2));
    // And no errors
    expect(latestError, isNull);
    // And only 2 areas to be loaded (first and third)
    expect(model.loadedAreasCount, equals(2));
  });


  test('only 1 loading of an area is done when new area is within of the already loading one', () async {
    int attempts = 0;
    when(shopsManager.fetchShops(any, any)).thenAnswer((_) async {
      attempts += 1;
      return Ok(shops);
    });

    // Start first load without 'await'
    () {
      model.onCameraMoved(LatLngBounds(
          southwest: const LatLng(16.999, 16.999),
          northeast: const LatLng(17.001, 17.001)));
    }.call();
    // Wait a little bit
    // (note that this might cause a race condition on slow test runners)
    await Future.delayed(const Duration(milliseconds: 1));
    // Perform the second load with very similar but still different bounds
    await model.onCameraMoved(LatLngBounds(
        southwest: const LatLng(16.998, 16.998),
        northeast: const LatLng(17.002, 17.002)));

    // We expect that there was only 1 load attempt
    expect(attempts, equals(1));
    // And no errors
    expect(latestError, isNull);
    // And only 1 area to be loaded
    expect(model.loadedAreasCount, equals(1));
  });
}
