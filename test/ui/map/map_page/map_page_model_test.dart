import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:plante/model/coord.dart';
import 'package:plante/model/coords_bounds.dart';
import 'package:plante/model/shop.dart';
import 'package:plante/outside/backend/backend_shop.dart';
import 'package:plante/outside/map/osm/osm_shop.dart';
import 'package:plante/outside/map/osm/osm_uid.dart';
import 'package:plante/ui/map/map_page/map_page_model.dart';

import '../../../common_mocks.mocks.dart';
import '../../../z_fakes/fake_shops_manager.dart';
import '../../../z_fakes/fake_suggested_products_manager.dart';

void main() {
  late MockLocationController locationController;
  late FakeShopsManager fakeShopsManager;
  late MockLatestCameraPosStorage latestCameraPosStorage;
  late MockAddressObtainer addressObtainer;
  late FakeSuggestedProductsManager suggestedProductsManager;
  late MapPageModel model;

  Map<OsmUID, Shop>? latestLoadedShops;
  MapPageModelError? latestError;

  final shops = {
    OsmUID.parse('1:1234'): Shop((e) => e
      ..osmShop.replace(OsmShop((e) => e
        ..osmUID = OsmUID.parse('1:1234')
        ..longitude = 15
        ..latitude = 15
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
    fakeShopsManager = FakeShopsManager();
    latestCameraPosStorage = MockLatestCameraPosStorage();
    addressObtainer = MockAddressObtainer();

    final directionsManager = MockDirectionsManager();
    when(directionsManager.areDirectionsAvailable())
        .thenAnswer((_) async => false);

    suggestedProductsManager = FakeSuggestedProductsManager();

    model = MapPageModel(
        locationController,
        fakeShopsManager,
        addressObtainer,
        latestCameraPosStorage,
        directionsManager,
        suggestedProductsManager, (shops) {
      latestLoadedShops = shops;
    }, (error) {
      latestError = error;
    }, () {}, () {});
  });

  test('successful shops load', () async {
    fakeShopsManager.addPreloadedArea(
        CoordsBounds(
            southwest: Coord(lat: 14, lon: 14),
            northeast: Coord(lat: 16, lon: 16)),
        shops.values);

    expect(latestLoadedShops, isNull);
    expect(latestError, isNull);

    await model.onCameraIdle(CoordsBounds(
        southwest: Coord(lat: 14.999, lon: 14.999),
        northeast: Coord(lat: 15.001, lon: 15.001)));

    expect(latestLoadedShops, isNull);
    expect(latestError, isNull);

    await model.loadShops();

    expect(latestLoadedShops, equals(shops));
    expect(latestError, isNull);
  });

  test('shops reloaded on shops manager change notification', () async {
    fakeShopsManager.addPreloadedArea(
        CoordsBounds(
            southwest: Coord(lat: 14, lon: 14),
            northeast: Coord(lat: 16, lon: 16)),
        shops.values);

    // Initial load
    fakeShopsManager.verify_fetchShops_called(times: 0);
    await model.onCameraIdle(CoordsBounds(
        southwest: Coord(lat: 14.999, lon: 14.999),
        northeast: Coord(lat: 15.001, lon: 15.001)));
    await model.loadShops();
    fakeShopsManager.verify_fetchShops_called();

    // Reload
    await fakeShopsManager.clearCache();
    fakeShopsManager.clear_verifiedCalls();
    fakeShopsManager.verify_fetchShops_called(times: 0);
    fakeShopsManager.addPreloadedArea(
        CoordsBounds(
            southwest: Coord(lat: 14, lon: 14),
            northeast: Coord(lat: 16, lon: 16)),
        shops.values);

    await Future.delayed(const Duration(milliseconds: 1));
    fakeShopsManager.verify_fetchShops_called();
  });

  test('shops from same view port reloaded on shops manager change', () async {
    final preloadedBounds = CoordsBounds(
        southwest: Coord(lat: 14, lon: 14), northeast: Coord(lat: 16, lon: 16));
    fakeShopsManager.addPreloadedArea(preloadedBounds, shops.values);

    // Initial load
    fakeShopsManager.verify_fetchShops_called(times: 0);
    final initialViewPort = CoordsBounds(
        southwest: Coord(lat: 14.999, lon: 14.999),
        northeast: Coord(lat: 15.001, lon: 15.001));
    await model.onCameraIdle(initialViewPort);
    await model.loadShops();
    fakeShopsManager.verify_fetchShops_called();

    // Viewport moved
    await model.onCameraIdle(CoordsBounds(
        southwest: Coord(lat: 4.999, lon: 4.999),
        northeast: Coord(lat: 5.001, lon: 5.001)));

    // Reload is expected for already loaded view port
    fakeShopsManager.clear_verifiedCalls();
    fakeShopsManager.updatePreloadedArea(preloadedBounds, shops.values);
    await Future.delayed(const Duration(milliseconds: 1));
    fakeShopsManager.verify_fetchShops_called(times: 1);
    expect(fakeShopsManager.calls_fetchShop().first, equals(initialViewPort));
  });

  test('loading == true until first onCameraIdle is handled', () async {
    expect(model.loading, isTrue);
    await model.onCameraIdle(CoordsBounds(
        southwest: Coord(lat: 14.999, lon: 14.999),
        northeast: Coord(lat: 15.001, lon: 15.001)));
    expect(model.loading, isFalse);
  });
}
