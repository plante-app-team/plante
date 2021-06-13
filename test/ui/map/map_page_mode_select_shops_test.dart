import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:plante/base/result.dart';
import 'package:plante/model/product.dart';
import 'package:plante/model/shop.dart';
import 'package:plante/outside/backend/backend_shop.dart';
import 'package:plante/outside/map/osm_shop.dart';
import 'package:plante/ui/map/map_page.dart';
import 'package:plante/l10n/strings.dart';
import 'package:plante/ui/map/map_page_mode_create_shop.dart';
import 'package:plante/ui/map/map_page_mode_select_shops_base.dart';

import '../../widget_tester_extension.dart';
import 'map_page_mode_select_shops_test.mocks.dart';
import 'map_page_modes_test_commons.dart';
import 'map_page_modes_test_commons.mocks.dart';

@GenerateMocks(
    [],
    customMocks: [MockSpec<NavigatorObserver>(returnNullOnMissingStub: true)])
void main() {
  late MapPageModesTestCommons commons;
  late MockGoogleMapController mapController;
  late List<Shop> shops;
  late MockShopsManager shopsManager;

  setUp(() async {
    commons = MapPageModesTestCommons();
    await commons.setUp();
    mapController = commons.mapController;
    shops = commons.shops;
    shopsManager = commons.shopsManager;
  });

  testWidgets('empty shops are displayed by default', (WidgetTester tester) async {
    expect(shops[0].productsCount, equals(0));

    final widget = MapPage(
        mapControllerForTesting: mapController,
        requestedMode: MapPageRequestedMode.SELECT_SHOPS);
    await tester.superPump(widget);
    widget.onMapIdleForTesting();
    await tester.pumpAndSettle();

    final displayedShops = widget.getDisplayedShopsForTesting();
    expect(displayedShops.length, equals(shops.length));
    expect(displayedShops, containsAll(shops));
  });

  testWidgets('can select shops', (WidgetTester tester) async {
    final navigationObserver = MockNavigatorObserver();
    final widget = MapPage(
        mapControllerForTesting: mapController,
        requestedMode: MapPageRequestedMode.SELECT_SHOPS);
    final context = await tester.superPump(
        widget,
        navigatorObserver: navigationObserver);
    widget.onMapIdleForTesting();
    await tester.pumpAndSettle();

    widget.onMarkerClickForTesting([shops[0]]);
    await tester.pumpAndSettle();
    await tester.tap(find.text(context.strings.global_yes));
    await tester.pumpAndSettle();

    reset(navigationObserver);

    await tester.tap(find.text(context.strings.global_done));
    await tester.pumpAndSettle();

    final capturedRoute = verify(navigationObserver.didPop(captureAny, any))
        .captured.first as Route<dynamic>;
    expect(await capturedRoute.popped, equals([shops[0]]));
  });

  testWidgets('can cancel the mode after shops are selected', (WidgetTester tester) async {
    final widget = MapPage(
        mapControllerForTesting: mapController,
        requestedMode: MapPageRequestedMode.SELECT_SHOPS);
    final context = await tester.superPump(widget);
    widget.onMapIdleForTesting();
    await tester.pumpAndSettle();

    widget.onMarkerClickForTesting([shops[0]]);
    await tester.pumpAndSettle();
    await tester.tap(find.text(context.strings.global_yes));
    await tester.pumpAndSettle();

    await tester.tap(find.text(context.strings.global_cancel));
    await tester.pumpAndSettle();
    await tester.tap(find.text(context.strings.global_yes));
    await tester.pumpAndSettle();

    // Expecting the page to be closed
    expect(find.byType(MapPage), findsNothing);
  });

  testWidgets('can cancel the mode when no shops are selected', (WidgetTester tester) async {
    final widget = MapPage(
        mapControllerForTesting: mapController,
        requestedMode: MapPageRequestedMode.SELECT_SHOPS);
    final context = await tester.superPump(widget);
    widget.onMapIdleForTesting();
    await tester.pumpAndSettle();

    await tester.tap(find.text(context.strings.global_cancel));
    await tester.pumpAndSettle();

    // Expecting the page to be closed
    expect(find.byType(MapPage), findsNothing);
  });

  testWidgets('can cancel a shop selection', (WidgetTester tester) async {
    final widget = MapPage(
        mapControllerForTesting: mapController,
        requestedMode: MapPageRequestedMode.SELECT_SHOPS);
    final context = await tester.superPump(widget);
    widget.onMapIdleForTesting();
    await tester.pumpAndSettle();

    // Tap
    widget.onMarkerClickForTesting([shops[0]]);
    await tester.pumpAndSettle();
    // Cancel
    await tester.tap(find.text(context.strings.global_no));
    await tester.pumpAndSettle();
    // Verify
    expect(widget.getModeForTesting().selectedShops(), equals(<Shop>{}));
  });

  testWidgets('cannot select more than MAX shops', (WidgetTester tester) async {
    final manyShops = <Shop>[];
    for (var i = 0; i < MAP_PAGE_MODE_SELECTED_SHOPS_MAX * 2; ++i) {
      manyShops.add(Shop((e) => e
        ..osmShop.replace(OsmShop((e) => e
          ..osmId = '$i'
          ..longitude = 10
          ..latitude = 10
          ..name = 'Spar$i'))
        ..backendShop.replace(BackendShop((e) => e
          ..osmId = '$i'
          ..productsCount = i))));
    }
    final shopsMap = { for (final shop in manyShops) shop.osmId: shop };
    when(shopsManager.fetchShops(any, any)).thenAnswer((_) async =>
        Ok(shopsMap));

    final widget = MapPage(
        mapControllerForTesting: mapController,
        requestedMode: MapPageRequestedMode.SELECT_SHOPS);
    final context = await tester.superPump(widget);
    widget.onMapIdleForTesting();
    await tester.pumpAndSettle();

    for (final shop in manyShops) {
      widget.onMarkerClickForTesting([shop]);
      await tester.pumpAndSettle();
      if (find.text(context.strings.global_yes).evaluate().isNotEmpty) {
        await tester.tap(find.text(context.strings.global_yes));
      }
      await tester.pumpAndSettle();
    }
    expect(widget.getModeForTesting().selectedShops(), equals(
        manyShops.take(MAP_PAGE_MODE_SELECTED_SHOPS_MAX).toSet()
    ));
  });

  testWidgets('can provide initially selected shops', (WidgetTester tester) async {
    final widget = MapPage(
        mapControllerForTesting: mapController,
        requestedMode: MapPageRequestedMode.SELECT_SHOPS,
        initialSelectedShops: [shops[0]]);
    await tester.superPump(widget);
    widget.onMapIdleForTesting();
    await tester.pumpAndSettle();

    expect(widget.getModeForTesting().selectedShops(), equals({shops[0]}));
  });

  testWidgets('shop selection with provided product', (WidgetTester tester) async {
    final product = Product((e) => e
      ..barcode = '222'
      ..name = 'Product name');

    final navigationObserver = MockNavigatorObserver();
    final widget = MapPage(
        mapControllerForTesting: mapController,
        requestedMode: MapPageRequestedMode.SELECT_SHOPS,
        product: product);
    final context = await tester.superPump(
        widget,
        navigatorObserver: navigationObserver);
    widget.onMapIdleForTesting();
    await tester.pumpAndSettle();

    widget.onMarkerClickForTesting([shops[0]]);
    await tester.pumpAndSettle();

    final productString = context.strings.map_page_is_product_sold_q
        .replaceAll('<PRODUCT>', product.name!)
        .replaceAll('<SHOP>', shops[0].name);
    final noProductString = context.strings.map_page_is_new_product_sold_q
        .replaceAll('<SHOP>', shops[0].name);
    expect(find.text(productString), findsOneWidget);
    expect(find.text(noProductString), findsNothing);
  });

  testWidgets('shop selection without provided product', (WidgetTester tester) async {
    final navigationObserver = MockNavigatorObserver();
    final widget = MapPage(
        mapControllerForTesting: mapController,
        requestedMode: MapPageRequestedMode.SELECT_SHOPS,
        product: null);
    final context = await tester.superPump(
        widget,
        navigatorObserver: navigationObserver);
    widget.onMapIdleForTesting();
    await tester.pumpAndSettle();

    widget.onMarkerClickForTesting([shops[0]]);
    await tester.pumpAndSettle();

    final noProductString = context.strings.map_page_is_new_product_sold_q
        .replaceAll('<SHOP>', shops[0].name);
    expect(find.text(noProductString), findsOneWidget);
  });

  testWidgets('can switch mode to the Add Shop Mode', (WidgetTester tester) async {
    expect(shops[0].productsCount, equals(0));

    final widget = MapPage(
        mapControllerForTesting: mapController,
        requestedMode: MapPageRequestedMode.SELECT_SHOPS);
    final context = await tester.superPump(widget);
    widget.onMapIdleForTesting();
    await tester.pumpAndSettle();

    expect(find.text(context.strings.map_page_click_where_new_shop_located),
        findsNothing);
    expect(widget.getModeForTesting().runtimeType,
        isNot(equals(MapPageModeCreateShop)));

    await tester.tap(find.text(context.strings.map_page_plus_shop));
    await tester.pumpAndSettle();

    expect(find.text(context.strings.map_page_click_where_new_shop_located),
        findsOneWidget);
    expect(widget.getModeForTesting().runtimeType,
        equals(MapPageModeCreateShop));
  });
}
