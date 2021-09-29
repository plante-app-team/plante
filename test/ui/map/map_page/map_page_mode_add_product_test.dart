import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:plante/base/result.dart';
import 'package:plante/l10n/strings.dart';
import 'package:plante/model/product_lang_slice.dart';
import 'package:plante/model/shop.dart';
import 'package:plante/outside/backend/backend_shop.dart';
import 'package:plante/outside/map/osm_shop.dart';
import 'package:plante/ui/map/map_page/map_page.dart';
import 'package:plante/ui/map/map_page/map_page_mode_create_shop.dart';
import 'package:plante/ui/map/map_page/map_page_mode_select_shops_where_product_sold_base.dart';

import '../../../common_mocks.mocks.dart';
import '../../../widget_tester_extension.dart';
import '../../../z_fakes/fake_analytics.dart';
import 'map_page_modes_test_commons.dart';

void main() {
  late MapPageModesTestCommons commons;
  late MockGoogleMapController mapController;
  late MockShopsManager shopsManager;
  late FakeAnalytics analytics;
  late List<Shop> shops;
  final product = ProductLangSlice((e) => e
    ..barcode = '222'
    ..name = 'name').productForTests();

  setUp(() async {
    commons = MapPageModesTestCommons();
    await commons.setUp();
    mapController = commons.mapController;
    shops = commons.shops;
    shopsManager = commons.shopsManager;
    analytics = commons.analytics;
  });

  testWidgets('empty shops are displayed by default',
      (WidgetTester tester) async {
    expect(shops[0].productsCount, equals(0));

    final widget = MapPage(
        mapControllerForTesting: mapController,
        requestedMode: MapPageRequestedMode.ADD_PRODUCT,
        product: product);
    await tester.superPump(widget);
    widget.onMapIdleForTesting();
    await tester.pumpAndSettle();

    final displayedShops = widget.getDisplayedShopsForTesting();
    expect(displayedShops.length, equals(shops.length));
    expect(displayedShops, containsAll(shops));
  });

  testWidgets('user hint', (WidgetTester tester) async {
    final widget = MapPage(
        mapControllerForTesting: mapController,
        requestedMode: MapPageRequestedMode.ADD_PRODUCT,
        product: product);
    final context = await tester.superPump(widget);

    expect(find.text(context.strings.map_page_click_on_shop_where_product_sold),
        findsOneWidget);
  });

  testWidgets('can put products to shops', (WidgetTester tester) async {
    final widget = MapPage(
        mapControllerForTesting: mapController,
        requestedMode: MapPageRequestedMode.ADD_PRODUCT,
        product: product);
    final context = await tester.superPump(widget);
    widget.onMapIdleForTesting();
    await tester.pumpAndSettle();

    widget.onMarkerClickForTesting([shops[0]]);
    await tester.pumpAndSettle();
    await tester.tap(find.text(context.strings.global_yes));
    await tester.pumpAndSettle();

    widget.onMarkerClickForTesting([shops[1]]);
    await tester.pumpAndSettle();
    await tester.tap(find.text(context.strings.global_yes));
    await tester.pumpAndSettle();

    verifyNever(shopsManager.putProductToShops(any, any));

    await tester.tap(find.text(context.strings.global_done));
    await tester.pumpAndSettle();

    // Expecting the page to be closed
    expect(find.byType(MapPage), findsNothing);
    // Verify the product is added to the shop
    verify(shopsManager.putProductToShops(product, [shops[0], shops[1]]));
  });

  testWidgets('can put products to shops cluster', (WidgetTester tester) async {
    final widget = MapPage(
        mapControllerForTesting: mapController,
        requestedMode: MapPageRequestedMode.ADD_PRODUCT,
        product: product);
    final context = await tester.superPump(widget);
    widget.onMapIdleForTesting();
    await tester.pumpAndSettle();

    widget.onMarkerClickForTesting([shops[0], shops[1]]);
    await tester.pumpAndSettle();

    // Button 1 click
    final yesButton1 =
        find.text(context.strings.global_yes).evaluate().first.widget;
    await tester.tap(find.byWidget(yesButton1));
    await tester.pumpAndSettle();
    // Open cards again
    widget.onMarkerClickForTesting([shops[0], shops[1]]);
    await tester.pumpAndSettle();
    // Scroll to card 2
    final yesButton2 =
        find.text(context.strings.global_yes).evaluate().last.widget;
    await tester.dragUntilVisible(find.byWidget(yesButton2),
        find.byKey(const Key('shop_card_scroll')), const Offset(0, 400));
    await tester.pumpAndSettle();
    // Button 2 click

    await tester.tap(find.byWidget(yesButton2));
    await tester.pumpAndSettle();

    verifyNever(shopsManager.putProductToShops(any, any));
    expect(find.byKey(const Key('shop_card_scroll')), findsNothing);
    await tester.tap(find.text(context.strings.global_done));
    await tester.pumpAndSettle();

    // Expecting the page to be closed
    expect(find.byType(MapPage), findsNothing);
    // Verify the product is added to the shops
    verify(shopsManager.putProductToShops(product, [shops[1], shops[0]]));
  });

  testWidgets('cannot put products to shops when no products are selected',
      (WidgetTester tester) async {
    final widget = MapPage(
        mapControllerForTesting: mapController,
        requestedMode: MapPageRequestedMode.ADD_PRODUCT,
        product: product);
    final context = await tester.superPump(widget);
    widget.onMapIdleForTesting();
    await tester.pumpAndSettle();

    await tester.tap(find.text(context.strings.global_done));
    await tester.pumpAndSettle();

    // Expecting the page to still be open
    expect(find.byType(MapPage), findsOneWidget);
    // Verify no product is added to any shop
    verifyNever(shopsManager.putProductToShops(any, any));
  });

  testWidgets('unselect shop', (WidgetTester tester) async {
    final widget = MapPage(
        mapControllerForTesting: mapController,
        requestedMode: MapPageRequestedMode.ADD_PRODUCT,
        product: product);
    final context = await tester.superPump(widget);
    widget.onMapIdleForTesting();
    await tester.pumpAndSettle();

    // Select
    widget.onMarkerClickForTesting([shops[0]]);
    await tester.pumpAndSettle();
    await tester.tap(find.text(context.strings.global_yes));
    await tester.pumpAndSettle();
    // Verify
    expect(widget.getModeForTesting().selectedShops(), equals({shops[0]}));

    // Unselect
    widget.onMarkerClickForTesting([shops[0]]);
    await tester.pumpAndSettle();
    await tester.tap(find.text(context.strings.global_no));
    await tester.pumpAndSettle();
    // Verify
    expect(widget.getModeForTesting().selectedShops(), equals(<Shop>{}));

    await tester.tap(find.text(context.strings.global_done));
    await tester.pumpAndSettle();

    // Expecting the page to still be open
    expect(find.byType(MapPage), findsOneWidget);
    // Verify no product is added to any shop
    verifyNever(shopsManager.putProductToShops(any, any));
  });

  testWidgets('can cancel the mode after shops are selected',
      (WidgetTester tester) async {
    final widget = MapPage(
        mapControllerForTesting: mapController,
        requestedMode: MapPageRequestedMode.ADD_PRODUCT,
        product: product);
    final context = await tester.superPump(widget);
    widget.onMapIdleForTesting();
    await tester.pumpAndSettle();

    // Select
    widget.onMarkerClickForTesting([shops[0]]);
    await tester.pumpAndSettle();
    await tester.tap(find.text(context.strings.global_yes));
    await tester.pumpAndSettle();

    // Cancel
    await tester.tap(find.text(context.strings.global_cancel));
    await tester.pumpAndSettle();
    await tester.tap(find.text(context.strings.global_yes));
    await tester.pumpAndSettle();

    // Expecting the page to be closed
    expect(find.byType(MapPage), findsNothing);
    // Verify no product is added to any shop
    verifyNever(shopsManager.putProductToShops(any, any));
  });

  testWidgets('can cancel the mode when no shops are selected',
      (WidgetTester tester) async {
    final widget = MapPage(
        mapControllerForTesting: mapController,
        requestedMode: MapPageRequestedMode.ADD_PRODUCT,
        product: product);
    final context = await tester.superPump(widget);
    widget.onMapIdleForTesting();
    await tester.pumpAndSettle();

    await tester.tap(find.text(context.strings.global_cancel));
    await tester.pumpAndSettle();

    // Expecting the page to be closed
    expect(find.byType(MapPage), findsNothing);
    // Verify no product is added to any shop
    verifyNever(shopsManager.putProductToShops(any, any));
  });

  testWidgets('can cancel a shop selection', (WidgetTester tester) async {
    final widget = MapPage(
        mapControllerForTesting: mapController,
        requestedMode: MapPageRequestedMode.ADD_PRODUCT,
        product: product);
    await tester.superPump(widget);
    widget.onMapIdleForTesting();
    await tester.pumpAndSettle();

    // Tap
    widget.onMarkerClickForTesting([shops[0]]);
    await tester.pumpAndSettle();
    // Cancel
    await tester.tap(find.byKey(const Key('card_cancel_btn')));
    await tester.pumpAndSettle();
    // Verify
    expect(widget.getModeForTesting().selectedShops(), equals(<Shop>{}));
  });

  testWidgets('cannot select more than MAX shops', (WidgetTester tester) async {
    final manyShops = <Shop>[];
    for (var i = 0; i < MAP_PAGE_MODE_SELECTED_SHOPS_MAX * 2; ++i) {
      manyShops.add(Shop((e) => e
        ..osmShop.replace(OsmShop((e) => e
          ..osmUID = '1:$i'
          ..longitude = 10
          ..latitude = 10
          ..name = 'Spar$i'))
        ..backendShop.replace(BackendShop((e) => e
          ..osmUID = '1:$i'
          ..productsCount = i))));
    }
    final shopsMap = {for (final shop in manyShops) shop.osmUID: shop};
    when(shopsManager.fetchShops(any)).thenAnswer((_) async => Ok(shopsMap));

    final widget = MapPage(
        mapControllerForTesting: mapController,
        requestedMode: MapPageRequestedMode.ADD_PRODUCT,
        product: product);
    final context = await tester.superPump(widget);
    widget.onMapIdleForTesting();
    await tester.pumpAndSettle();

    for (final shop in manyShops) {
      widget.onMarkerClickForTesting([shop]);
      await tester.pumpAndSettle();
      await tester.tap(find.text(context.strings.global_yes));
      await tester.pumpAndSettle();
    }
    expect(widget.getModeForTesting().selectedShops(),
        equals(manyShops.take(MAP_PAGE_MODE_SELECTED_SHOPS_MAX).toSet()));
  });

  testWidgets('can provide initially selected shops',
      (WidgetTester tester) async {
    final widget = MapPage(
        mapControllerForTesting: mapController,
        requestedMode: MapPageRequestedMode.ADD_PRODUCT,
        product: product,
        initialSelectedShops: [shops[0]]);
    await tester.superPump(widget);
    widget.onMapIdleForTesting();
    await tester.pumpAndSettle();

    expect(widget.getModeForTesting().selectedShops(), equals({shops[0]}));
  });

  testWidgets('can switch mode to the Add Shop Mode',
      (WidgetTester tester) async {
    final widget = MapPage(
        mapControllerForTesting: mapController,
        requestedMode: MapPageRequestedMode.ADD_PRODUCT,
        product: product);
    final context = await tester.superPump(widget);
    widget.onMapIdleForTesting();
    await tester.pumpAndSettle();

    expect(find.text(context.strings.map_page_click_where_new_shop_located),
        findsNothing);
    expect(widget.getModeForTesting().runtimeType,
        isNot(equals(MapPageModeCreateShop)));

    await tester.tap(find.byKey(const Key('add_shop_fab')));
    await tester.pumpAndSettle();

    expect(find.text(context.strings.map_page_click_where_new_shop_located),
        findsOneWidget);
    expect(
        widget.getModeForTesting().runtimeType, equals(MapPageModeCreateShop));
  });

  testWidgets('add product mode switch event', (WidgetTester tester) async {
    expect(analytics.allEvents().length, equals(0));

    final widget = MapPage(
        mapControllerForTesting: mapController,
        requestedMode: MapPageRequestedMode.ADD_PRODUCT,
        product: product,
        initialSelectedShops: [shops[0]]);
    await tester.superPump(widget);
    widget.onMapIdleForTesting();
    await tester.pumpAndSettle();

    expect(analytics.allEvents().length, equals(1));
    expect(analytics.wasEventSent('map_page_mode_switch_add_product'), isTrue);
  });

  testWidgets('no shops hint', (WidgetTester tester) async {
    // Shops available!
    commons.fillFetchedShops();

    final widget = MapPage(
        mapControllerForTesting: mapController,
        requestedMode: MapPageRequestedMode.ADD_PRODUCT,
        product: product);
    final context = await tester.superPump(widget);
    widget.onMapIdleForTesting();
    await tester.pumpAndSettle();

    widget.onMapIdleForTesting();
    await tester.pumpAndSettle();

    expect(
        find.text(context.strings.map_page_no_shops_hint_in_select_shops_mode),
        findsNothing);

    // No shops!
    commons.clearFetchedShops();
    widget.onMapIdleForTesting();
    await tester.pumpAndSettle();

    expect(
        find.text(context.strings.map_page_no_shops_hint_in_select_shops_mode),
        findsOneWidget);

    // Fetch shops!
    commons.fillFetchedShops();
    widget.onMapIdleForTesting();
    await tester.pumpAndSettle();

    expect(
        find.text(context.strings.map_page_no_shops_hint_in_select_shops_mode),
        findsNothing);
  });
}
