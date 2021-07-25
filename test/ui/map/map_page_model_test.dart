import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:mockito/mockito.dart';
import 'package:plante/base/result.dart';
import 'package:plante/model/shop.dart';
import 'package:plante/outside/backend/backend_shop.dart';
import 'package:plante/outside/map/osm_shop.dart';
import 'package:plante/outside/map/shops_manager_types.dart';
import 'package:plante/ui/map/map_page_model.dart';

import '../../common_mocks.mocks.dart';

void main() {
  late MockLocationController locationController;
  late MockShopsManager shopsManager;
  late MockLatestCameraPosStorage latestCameraPosStorage;
  late MockAddressObtainer addressObtainer;
  late MapPageModel model;

  final shopsManagerListeners = <ShopsManagerListener>[];

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
    latestCameraPosStorage = MockLatestCameraPosStorage();
    addressObtainer = MockAddressObtainer();

    shopsManagerListeners.clear();
    when(shopsManager.addListener(any)).thenAnswer((invc) {
      final listener = invc.positionalArguments[0] as ShopsManagerListener;
      shopsManagerListeners.add(listener);
    });

    model = MapPageModel(locationController, shopsManager, addressObtainer,
        latestCameraPosStorage, (shops) {
      latestLoadedShops = shops;
    }, (error) {
      latestError = error;
    }, () {});
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

  test('shops reloaded on shops manager change notification', () async {
    when(shopsManager.fetchShops(any, any)).thenAnswer((_) async => Ok(shops));

    verifyNever(shopsManager.fetchShops(any, any));
    await model.onCameraMoved(LatLngBounds(
        southwest: const LatLng(14.999, 14.999),
        northeast: const LatLng(15.001, 15.001)));
    verify(shopsManager.fetchShops(any, any));

    clearInteractions(shopsManager);

    verifyNever(shopsManager.fetchShops(any, any));
    shopsManagerListeners.forEach((listener) {
      listener.onLocalShopsChange();
    });
    verify(shopsManager.fetchShops(any, any));
  });
}
