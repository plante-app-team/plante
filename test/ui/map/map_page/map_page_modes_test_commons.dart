import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
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
import 'package:plante/model/shared_preferences_holder.dart';
import 'package:plante/model/shop.dart';
import 'package:plante/outside/backend/backend_shop.dart';
import 'package:plante/outside/map/address_obtainer.dart';
import 'package:plante/outside/map/directions_manager.dart';
import 'package:plante/outside/map/osm/osm_address.dart';
import 'package:plante/outside/map/osm/osm_searcher.dart';
import 'package:plante/outside/map/osm/osm_shop.dart';
import 'package:plante/outside/map/osm/osm_uid.dart';
import 'package:plante/outside/map/roads_manager.dart';
import 'package:plante/outside/map/shops_manager.dart';
import 'package:plante/outside/map/user_address/caching_user_address_pieces_obtainer.dart';
import 'package:plante/outside/map/user_address/user_address_piece.dart';
import 'package:plante/outside/map/user_address/user_address_type.dart';
import 'package:plante/outside/products/suggestions/suggested_products_manager.dart';
import 'package:plante/ui/map/latest_camera_pos_storage.dart';
import 'package:plante/ui/map/map_page/map_page.dart';
import 'package:plante/ui/map/map_page/map_page_testing_storage.dart';

import '../../../common_mocks.mocks.dart';
import '../../../widget_tester_extension.dart';
import '../../../z_fakes/fake_analytics.dart';
import '../../../z_fakes/fake_caching_user_address_pieces_obtainer.dart';
import '../../../z_fakes/fake_shared_preferences.dart';
import '../../../z_fakes/fake_shops_manager.dart';
import '../../../z_fakes/fake_suggested_products_manager.dart';

class MapPageModesTestCommons {
  late MockPermissionsManager permissionsManager;
  late FakeShopsManager shopsManager;
  late MockUserLocationManager userLocationManager;
  late MockGoogleMapController mapController;
  late FakeSharedPreferences prefs;
  late MockLatestCameraPosStorage latestCameraPosStorage;
  late FakeAnalytics analytics;
  late MockAddressObtainer addressObtainer;
  late MockDirectionsManager directionsManager;
  late FakeSuggestedProductsManager suggestedProductsManager;

  final readyAddress = OsmAddress((e) => e.road = 'Broadway');

  final shops = <Shop>[];
  final shopsBounds = CoordsBounds(
    southwest: Coord(lat: 10, lon: 10),
    northeast: Coord(lat: 11, lon: 11),
  );

  Future<void> setUp() async {
    await GetIt.I.reset();
    analytics = FakeAnalytics();
    GetIt.I.registerSingleton<Analytics>(analytics);

    permissionsManager = MockPermissionsManager();
    GetIt.I.registerSingleton<PermissionsManager>(permissionsManager);
    shopsManager = FakeShopsManager();
    GetIt.I.registerSingleton<ShopsManager>(shopsManager);
    userLocationManager = MockUserLocationManager();
    GetIt.I.registerSingleton<UserLocationManager>(userLocationManager);
    mapController = MockGoogleMapController();
    prefs = FakeSharedPreferences();
    latestCameraPosStorage = MockLatestCameraPosStorage();
    GetIt.I.registerSingleton<LatestCameraPosStorage>(latestCameraPosStorage);
    addressObtainer = MockAddressObtainer();
    GetIt.I.registerSingleton<AddressObtainer>(addressObtainer);
    final roadsManager = MockRoadsManager();
    GetIt.I.registerSingleton<RoadsManager>(roadsManager);
    final osmSearcher = MockOsmSearcher();
    GetIt.I.registerSingleton<OsmSearcher>(osmSearcher);
    directionsManager = MockDirectionsManager();
    GetIt.I.registerSingleton<DirectionsManager>(directionsManager);
    suggestedProductsManager = FakeSuggestedProductsManager();
    GetIt.I
        .registerSingleton<SuggestedProductsManager>(suggestedProductsManager);
    final userAddressObtainer = FakeCachingUserAddressPiecesObtainer();
    userAddressObtainer.setResultFor(
        UserAddressType.CAMERA_LOCATION, UserAddressPiece.COUNTRY_CODE, 'be');
    GetIt.I.registerSingleton<CachingUserAddressPiecesObtainer>(
        userAddressObtainer);
    GetIt.I.registerSingleton<SharedPreferencesHolder>(
        FakeSharedPreferences().asHolder());

    await fillFetchedShops();

    when(userLocationManager.lastKnownPositionInstant()).thenReturn(null);
    when(userLocationManager.lastKnownPosition()).thenAnswer((_) async => null);
    when(userLocationManager.currentPosition()).thenAnswer((_) async => null);
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

    when(roadsManager.fetchRoadsWithinAndNearby(any))
        .thenAnswer((_) async => Ok(const []));

    when(directionsManager.areDirectionsAvailable())
        .thenAnswer((_) async => false);
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
    shopsManager.addPreloadedArea(shopsBounds, shops);

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
        product: product,
        requestedMode: requestedMode,
        initialSelectedShops: initialSelectedShops);
    await initIdleMapPage(widget, tester);
    return widget;
  }
}
