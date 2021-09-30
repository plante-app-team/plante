import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:plante/base/result.dart';
import 'package:plante/model/coord.dart';
import 'package:plante/model/coords_bounds.dart';
import 'package:plante/model/shop.dart';
import 'package:plante/outside/backend/backend_shop.dart';
import 'package:plante/outside/map/directions_manager.dart';
import 'package:plante/outside/map/osm_shop.dart';
import 'package:plante/outside/map/osm_uid.dart';
import 'package:plante/outside/map/shops_manager_types.dart';
import 'package:plante/ui/map/map_page/map_page_model.dart';

import '../../../common_mocks.mocks.dart';

void main() {
  late MockLocationController locationController;
  late MockShopsManager shopsManager;
  late MockLatestCameraPosStorage latestCameraPosStorage;
  late MockAddressObtainer addressObtainer;
  late MapPageModel model;

  final shopsManagerListeners = <ShopsManagerListener>[];

  Map<OsmUID, Shop>? latestLoadedShops;
  MapPageModelError? latestError;

  final shops = {
    OsmUID.parse('1:1234'): Shop((e) => e
      ..osmShop.replace(OsmShop((e) => e
        ..osmUID = OsmUID.parse('1:1234')
        ..longitude = 11
        ..latitude = 11
        ..name = 'Spar'
        ..type = 'Supermarket'))
      ..backendShop.replace(BackendShop((e) => e
        ..osmUID = OsmUID.parse('1:1234')
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

    final directionsManager = MockDirectionsManager();
    when(directionsManager.areDirectionsAvailable())
        .thenAnswer((_) async => false);

    model = MapPageModel(locationController, shopsManager, addressObtainer,
        latestCameraPosStorage, directionsManager, (shops) {
      latestLoadedShops = shops;
    }, (error) {
      latestError = error;
    }, () {}, () {});
  });

  test('successful shops load', () async {
    when(shopsManager.fetchShops(any)).thenAnswer((_) async => Ok(shops));

    expect(latestLoadedShops, isNull);
    expect(latestError, isNull);

    await model.onCameraMoved(CoordsBounds(
        southwest: Coord(lat: 14.999, lon: 14.999),
        northeast: Coord(lat: 15.001, lon: 15.001)));

    expect(latestLoadedShops, equals(shops));
    expect(latestError, isNull);
  });

  test('shops reloaded on shops manager change notification', () async {
    when(shopsManager.fetchShops(any)).thenAnswer((_) async => Ok(shops));

    verifyNever(shopsManager.fetchShops(any));
    await model.onCameraMoved(CoordsBounds(
        southwest: Coord(lat: 14.999, lon: 14.999),
        northeast: Coord(lat: 15.001, lon: 15.001)));
    verify(shopsManager.fetchShops(any));

    clearInteractions(shopsManager);

    verifyNever(shopsManager.fetchShops(any));
    shopsManagerListeners.forEach((listener) {
      listener.onLocalShopsChange();
    });
    verify(shopsManager.fetchShops(any));
  });
}
