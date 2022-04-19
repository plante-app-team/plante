import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mockito/mockito.dart';
import 'package:plante/logging/analytics.dart';
import 'package:plante/model/coord.dart';
import 'package:plante/model/coords_bounds.dart';
import 'package:plante/model/shop.dart';
import 'package:plante/outside/backend/backend_shop.dart';
import 'package:plante/outside/map/osm/osm_shop.dart';
import 'package:plante/outside/map/osm/osm_uid.dart';
import 'package:plante/ui/base/page_state_plante.dart';
import 'package:plante/ui/base/ui_value.dart';
import 'package:plante/ui/map/map_page/map_page_model.dart';
import 'package:plante/ui/map/shop_creation/shops_creation_manager.dart';

import '../../../common_mocks.mocks.dart';
import '../../../widget_tester_extension.dart';
import '../../../z_fakes/fake_analytics.dart';
import '../../../z_fakes/fake_caching_user_address_pieces_obtainer.dart';
import '../../../z_fakes/fake_shared_preferences.dart';
import '../../../z_fakes/fake_shops_manager.dart';
import '../../../z_fakes/fake_suggested_products_manager.dart';

void main() {
  late MockUserLocationManager userLocationManager;
  late FakeShopsManager fakeShopsManager;
  late MockLatestCameraPosStorage latestCameraPosStorage;
  late MockAddressObtainer addressObtainer;
  late FakeCachingUserAddressPiecesObtainer userAddressObtainer;
  late FakeSuggestedProductsManager suggestedProductsManager;
  late ShopsCreationManager shopsCreationManager;
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
    await GetIt.I.reset();
    GetIt.I.registerSingleton<Analytics>(FakeAnalytics());

    latestLoadedShops = null;
    latestError = null;

    userLocationManager = MockUserLocationManager();
    fakeShopsManager = FakeShopsManager();
    latestCameraPosStorage = MockLatestCameraPosStorage();
    addressObtainer = MockAddressObtainer();
    userAddressObtainer = FakeCachingUserAddressPiecesObtainer();

    suggestedProductsManager = FakeSuggestedProductsManager();
    shopsCreationManager = ShopsCreationManager(fakeShopsManager);
  });

  Future<void> createModel(WidgetTester tester) async {
    final directionsManager = MockDirectionsManager();
    when(directionsManager.areDirectionsAvailable())
        .thenAnswer((_) async => false);

    await tester.superPump(const HelperWidget());
    final state = tester.state<_HelperWidgetState>(find.byType(HelperWidget));
    final uiValuesFactory = UIValuesFactory(() => state.ref);

    model = MapPageModel(
        FakeSharedPreferences().asHolder(),
        userLocationManager,
        fakeShopsManager,
        addressObtainer,
        latestCameraPosStorage,
        directionsManager,
        suggestedProductsManager,
        userAddressObtainer,
        shopsCreationManager,
        UIValue<bool>(false, state.ref), (shops) {
      latestLoadedShops = shops;
    }, (error) {
      latestError = error;
    }, uiValuesFactory);
  }

  testWidgets('successful shops load', (WidgetTester tester) async {
    await createModel(tester);

    fakeShopsManager.addPreloadedArea_testing(
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

  testWidgets('shops reloaded on shops manager change notification',
      (WidgetTester tester) async {
    await createModel(tester);

    fakeShopsManager.addPreloadedArea_testing(
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
    fakeShopsManager.addPreloadedArea_testing(
        CoordsBounds(
            southwest: Coord(lat: 14, lon: 14),
            northeast: Coord(lat: 16, lon: 16)),
        shops.values);

    await tester.pumpAndSettle();
    fakeShopsManager.verify_fetchShops_called();
  });

  testWidgets('shops from same view port reloaded on shops manager change',
      (WidgetTester tester) async {
    await createModel(tester);

    final preloadedBounds = CoordsBounds(
        southwest: Coord(lat: 14, lon: 14), northeast: Coord(lat: 16, lon: 16));
    fakeShopsManager.addPreloadedArea_testing(preloadedBounds, shops.values);

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
    await tester.pumpAndSettle();
    fakeShopsManager.verify_fetchShops_called(times: 1);
    expect(fakeShopsManager.calls_fetchShop().first, equals(initialViewPort));
  });

  testWidgets(
      'shops from the loaded viewport are not being reloaded while a new viewport is being loaded',
      (WidgetTester tester) async {
    // When a new viewport is being loaded it also modifies cache of ShopsManager,
    // thus causing MapPageModel to get notified about local shops cache change.
    // Such notifications _should not_ cause MapPageModel to reload the last loaded
    // viewport, because it's outdated at this point - a new one is being loaded

    await createModel(tester);

    final preloadedBounds = CoordsBounds(
        southwest: Coord(lat: 14, lon: 14), northeast: Coord(lat: 16, lon: 16));
    fakeShopsManager.addPreloadedArea_testing(preloadedBounds, shops.values);

    // Initial load
    fakeShopsManager.verify_fetchShops_called(times: 0);
    final initialViewPort = CoordsBounds(
        southwest: Coord(lat: 14.999, lon: 14.999),
        northeast: Coord(lat: 15.001, lon: 15.001));
    await model.onCameraIdle(initialViewPort);
    await model.loadShops();
    fakeShopsManager.verify_fetchShops_called();

    // Viewport moved
    final secondViewPort = CoordsBounds(
        southwest: Coord(lat: 4.999, lon: 4.999),
        northeast: Coord(lat: 5.001, lon: 5.001));
    await model.onCameraIdle(secondViewPort);

    fakeShopsManager.clear_verifiedCalls();
    // NOTE: we don't add [secondViewPort] as a preloaded area to
    // fakeShopsManager - we expect it to be loaded by the [loadShops] call
    // and to modify cache of [fakeShopsManager].
    await model.loadShops();
    // Verify shops were fetched only once by the loadShops call
    fakeShopsManager.verify_fetchShops_called(times: 1);
    expect(fakeShopsManager.calls_fetchShop().first,
        isNot(equals(initialViewPort)));
    expect(fakeShopsManager.calls_fetchShop().first, equals(secondViewPort));
  });

  testWidgets('loading == true until first onCameraIdle is handled',
      (WidgetTester tester) async {
    await createModel(tester);

    expect(model.loading.cachedVal, isTrue);
    await model.onCameraIdle(CoordsBounds(
        southwest: Coord(lat: 14.999, lon: 14.999),
        northeast: Coord(lat: 15.001, lon: 15.001)));
    expect(model.loading.cachedVal, isFalse);
  });
}

class HelperWidget extends PagePlante {
  const HelperWidget({Key? key}) : super(key: key);

  @override
  _HelperWidgetState createState() => _HelperWidgetState();
}

class _HelperWidgetState extends PageStatePlante<HelperWidget> {
  _HelperWidgetState() : super('_HelperWidgetState');

  @override
  Widget buildPage(BuildContext context) {
    return Container();
  }
}
