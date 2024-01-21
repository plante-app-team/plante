import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:mockito/mockito.dart';
import 'package:plante/base/permissions_manager.dart';
import 'package:plante/base/result.dart';
import 'package:plante/l10n/strings.dart';
import 'package:plante/location/user_location_manager.dart';
import 'package:plante/logging/analytics.dart';
import 'package:plante/model/coord.dart';
import 'package:plante/model/coords_bounds.dart';
import 'package:plante/model/product.dart';
import 'package:plante/model/shop.dart';
import 'package:plante/outside/backend/backend_shop.dart';
import 'package:plante/outside/map/address_obtainer.dart';
import 'package:plante/outside/map/directions_manager.dart';
import 'package:plante/outside/map/osm/osm_address.dart';
import 'package:plante/outside/map/osm/osm_shop.dart';
import 'package:plante/outside/map/osm/osm_uid.dart';
import 'package:plante/outside/map/shops_manager.dart';
import 'package:plante/products/suggestions/suggested_products_manager.dart';
import 'package:plante/ui/map/latest_camera_pos_storage.dart';
import 'package:plante/ui/map/map_page/map_page.dart';
import 'package:plante/ui/map/map_page/map_page_testing_storage.dart';
import 'package:plante/ui/map/shop_creation/shops_creation_manager.dart';

import '../../../common_mocks.mocks.dart';
import '../../../test_di_registry.dart';
import '../../../widget_tester_extension.dart';
import '../../../z_fakes/fake_analytics.dart';
import '../../../z_fakes/fake_shared_preferences.dart';
import '../../../z_fakes/fake_shops_manager.dart';
import '../../../z_fakes/fake_suggested_products_manager.dart';

class MapPageModesTestCommons {
  late MockPermissionsManager permissionsManager;
  late FakeShopsManager shopsManager;
  late MockUserLocationManager userLocationManager;
  late MockGoogleMapController mapController;
  late MapPageController mapPageController;
  late FakeSharedPreferences prefs;
  late MockLatestCameraPosStorage latestCameraPosStorage;
  late FakeAnalytics analytics;
  late MockAddressObtainer addressObtainer;
  late MockDirectionsManager directionsManager;
  late FakeSuggestedProductsManager suggestedProductsManager;
  late ShopsCreationManager shopsCreationManager;

  final readyAddress = OsmAddress((e) => e.road = 'Broadway');

  final shops = <Shop>[];
  final shopsBounds = CoordsBounds(
    southwest: Coord(lat: 10, lon: 10),
    northeast: Coord(lat: 11, lon: 11),
  );

  Future<void> setUpImpl(TestDiRegistrar registrar) async {
    analytics = FakeAnalytics();
    permissionsManager = MockPermissionsManager();
    shopsManager = FakeShopsManager();
    userLocationManager = MockUserLocationManager();
    mapController = MockGoogleMapController();
    mapPageController = MapPageController();
    prefs = FakeSharedPreferences();
    latestCameraPosStorage = MockLatestCameraPosStorage();
    addressObtainer = MockAddressObtainer();
    directionsManager = MockDirectionsManager();
    suggestedProductsManager = FakeSuggestedProductsManager();
    shopsCreationManager = ShopsCreationManager(shopsManager);

    registrar.register<Analytics>(analytics);
    registrar.register<PermissionsManager>(permissionsManager);
    registrar.register<ShopsManager>(shopsManager);
    registrar.register<UserLocationManager>(userLocationManager);
    registrar.register<LatestCameraPosStorage>(latestCameraPosStorage);
    registrar.register<AddressObtainer>(addressObtainer);
    registrar.register<DirectionsManager>(directionsManager);
    registrar.register<SuggestedProductsManager>(suggestedProductsManager);
    registrar.register<ShopsCreationManager>(shopsCreationManager);

    await fillFetchedShops();

    when(userLocationManager.lastKnownPositionInstant()).thenReturn(null);
    when(userLocationManager.lastKnownPosition()).thenAnswer((_) async => null);
    when(userLocationManager.currentPosition(
            explicitUserRequest: anyNamed('explicitUserRequest')))
        .thenAnswer((_) async => null);
    when(mapController.getVisibleRegion()).thenAnswer((_) async => LatLngBounds(
        southwest: LatLng(shopsBounds.south, shopsBounds.west),
        northeast: LatLng(shopsBounds.north, shopsBounds.east)));
    when(mapController.dispose()).thenAnswer((_) {});
    when(mapController.setMapStyle(any)).thenAnswer((_) async {});
    when(mapController.getZoomLevel()).thenAnswer((_) async => 10);
    when(permissionsManager.openAppSettings()).thenAnswer((_) async => true);
    when(permissionsManager.status(any))
        .thenAnswer((_) async => PermissionState.granted);

    when(latestCameraPosStorage.get()).thenAnswer((_) async => null);
    when(latestCameraPosStorage.getCached()).thenAnswer((_) => null);
    when(latestCameraPosStorage.set(any)).thenAnswer((_) async {});

    when(addressObtainer.addressOfShop(any))
        .thenAnswer((_) async => Ok(readyAddress.toShort()));
    when(addressObtainer.addressOfCoords(any))
        .thenAnswer((_) async => Ok(readyAddress));
    when(addressObtainer.shortAddressOfCoords(any))
        .thenAnswer((_) async => Ok(readyAddress.toShort()));

    when(directionsManager.areDirectionsAvailable())
        .thenAnswer((_) async => false);
  }

  Future<void> setUp() async {
    await TestDiRegistry.register(setUpImpl);
  }

  Future<void> fillFetchedShops([MapPage? widget, WidgetTester? tester]) async {
    shops.addAll([
      Shop((e) => e
        ..osmShop.replace(OsmShop((e) => e
          ..osmUID = OsmUID.parse('1:0')
          ..longitude = 10.10
          ..latitude = 10.10
          ..name = 'Spar0'))
        ..backendShop.replace(BackendShop((e) => e
          ..osmUID = OsmUID.parse('1:0')
          ..productsCount = 0))),
      Shop((e) => e
        ..osmShop.replace(OsmShop((e) => e
          ..osmUID = OsmUID.parse('1:1')
          ..longitude = 10.11
          ..latitude = 10.11
          ..name = 'Spar1'))
        ..backendShop.replace(BackendShop((e) => e
          ..osmUID = OsmUID.parse('1:1')
          ..productsCount = 1))),
      Shop((e) => e
        ..osmShop.replace(OsmShop((e) => e
          ..osmUID = OsmUID.parse('1:2')
          ..longitude = 10.12
          ..latitude = 10.12
          ..name = 'Spar2'))
        ..backendShop.replace(BackendShop((e) => e
          ..osmUID = OsmUID.parse('1:2')
          ..productsCount = 2))),
      Shop((e) => e
        ..osmShop.replace(OsmShop((e) => e
          ..osmUID = OsmUID.parse('1:3')
          ..longitude = 10.13
          ..latitude = 10.13
          ..name = 'Spar3'))
        ..backendShop.replace(BackendShop((e) => e
          ..osmUID = OsmUID.parse('1:3')
          ..productsCount = 3))),
    ]);
    shopsManager.addPreloadedArea_testing(shopsBounds, shops);

    widget?.onMapIdleForTesting();
    await tester?.pumpAndSettle();
  }

  Future<void> clearFetchedShops(
      MapPage widget, WidgetTester tester, BuildContext context,
      {bool clickTryToLoad = true}) async {
    shops.clear();
    await shopsManager.clearCache();

    widget.onMapIdleForTesting();
    await tester.pumpAndSettle();
    if (clickTryToLoad) {
      await tester.superTap(
          find.text(context.strings.map_page_load_shops_of_this_area));
    }
  }

  Future<void> replaceFetchedShops(
      Iterable<Shop> newShops, WidgetTester tester) async {
    shopsManager.updatePreloadedArea(shopsBounds, newShops);
    await tester.pumpAndSettle();
  }

  Future<void> moveCamera(
      Coord center, double zoom, MapPage widget, WidgetTester tester) async {
    final newVisibleRegion = center.makeSquare(shopsBounds.width);
    when(mapController.getVisibleRegion()).thenAnswer((_) async => LatLngBounds(
        southwest: LatLng(newVisibleRegion.south, newVisibleRegion.west),
        northeast: LatLng(newVisibleRegion.north, newVisibleRegion.east)));
    when(mapController.getZoomLevel()).thenAnswer((_) async => zoom);
    widget.onMapMoveForTesting(center, zoom);
    widget.onMapIdleForTesting();
    await tester.pumpAndSettle();
  }

  Future<BuildContext> initIdleMapPage(MapPage widget, WidgetTester tester,
      {NavigatorObserver? navigatorObserver}) async {
    final context =
        await tester.superPump(widget, navigatorObserver: navigatorObserver);
    widget.onMapIdleForTesting();
    await tester.pumpAndSettle();
    return context;
  }

  Future<MapPage> createIdleMapPage(WidgetTester tester,
      {Key? key,
      Product? product,
      List<Shop> initialSelectedShops = const [],
      MapPageRequestedMode requestedMode =
          MapPageRequestedMode.DEFAULT}) async {
    final widget = MapPage(
        key: key,
        mapControllerForTesting: mapController,
        controller: mapPageController,
        product: product,
        requestedMode: requestedMode,
        initialSelectedShops: initialSelectedShops);
    await initIdleMapPage(widget, tester);
    return widget;
  }
}
