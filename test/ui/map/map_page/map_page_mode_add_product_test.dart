import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plante/l10n/strings.dart';
import 'package:plante/model/product_lang_slice.dart';
import 'package:plante/model/shop.dart';
import 'package:plante/outside/backend/backend_shop.dart';
import 'package:plante/outside/backend/product_at_shop_source.dart';
import 'package:plante/outside/map/osm/osm_shop.dart';
import 'package:plante/outside/map/osm/osm_uid.dart';
import 'package:plante/ui/map/map_page/map_page.dart';
import 'package:plante/ui/map/map_page/map_page_mode_create_shop.dart';
import 'package:plante/ui/map/map_page/map_page_mode_select_shops_where_product_sold_base.dart';
import 'package:plante/ui/map/map_page/map_page_testing_storage.dart';

import '../../../common_finders_extension.dart';
import '../../../common_mocks.mocks.dart';
import '../../../widget_tester_extension.dart';
import '../../../z_fakes/fake_analytics.dart';
import '../../../z_fakes/fake_shops_manager.dart';
import 'map_page_modes_test_commons.dart';

void main() {
  late MapPageModesTestCommons commons;
  late MockGoogleMapController mapController;
  late FakeShopsManager shopsManager;
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

    final widget = await commons.createIdleMapPage(tester,
        requestedMode: MapPageRequestedMode.ADD_PRODUCT, product: product);

    final displayedShops = widget.getDisplayedShopsForTesting();
    expect(displayedShops.length, equals(shops.length));
    expect(displayedShops, containsAll(shops));
  });

  testWidgets('user hint', (WidgetTester tester) async {
    final widget = MapPage(
        mapControllerForTesting: mapController,
        requestedMode: MapPageRequestedMode.ADD_PRODUCT,
        product: product);
    final context = await commons.initIdleMapPage(widget, tester);

    expect(find.text(context.strings.map_page_click_on_shop_where_product_sold),
        findsOneWidget);
  });

  testWidgets('can put products to shops', (WidgetTester tester) async {
    final widget = MapPage(
        mapControllerForTesting: mapController,
        requestedMode: MapPageRequestedMode.ADD_PRODUCT,
        product: product);
    final context = await commons.initIdleMapPage(widget, tester);

    widget.onMarkerClickForTesting([shops[0]]);
    await tester.pumpAndSettle();
    await tester.superTap(find.text(context.strings.global_yes));

    widget.onMarkerClickForTesting([shops[1]]);
    await tester.pumpAndSettle();
    await tester.superTap(find.text(context.strings.global_yes));

    shopsManager.verity_createShop_called(times: 0);

    await tester.superTap(find.text(context.strings.global_done));

    // Expecting the page to be closed
    expect(find.byType(MapPage), findsNothing);
    // Verify the product is added to the shop
    final createShopParams = shopsManager.calls_putProductToShops().single;
    expect(createShopParams.product, equals(product));
    expect(createShopParams.shops, equals([shops[0], shops[1]]));
    expect(createShopParams.source, equals(ProductAtShopSource.MANUAL));
  });

  testWidgets('can put products to shops cluster', (WidgetTester tester) async {
    final widget = MapPage(
        mapControllerForTesting: mapController,
        requestedMode: MapPageRequestedMode.ADD_PRODUCT,
        product: product);
    final context = await commons.initIdleMapPage(widget, tester);

    widget.onMarkerClickForTesting([shops[0], shops[1]]);
    await tester.pumpAndSettle();

    // Button 1 click
    final yesButton1 =
        find.text(context.strings.global_yes).evaluate().first.widget;
    await tester.superTap(find.byWidget(yesButton1));
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

    await tester.superTap(find.byWidget(yesButton2));

    shopsManager.verity_createShop_called(times: 0);
    expect(find.byKey(const Key('shop_card_scroll')), findsNothing);
    await tester.superTap(find.text(context.strings.global_done));

    // Expecting the page to be closed
    expect(find.byType(MapPage), findsNothing);
    // Verify the product is added to the shops
    final createShopParams = shopsManager.calls_putProductToShops().single;
    expect(createShopParams.product, equals(product));
    expect(createShopParams.shops, equals([shops[1], shops[0]]));
  });

  testWidgets('cannot put products to shops when no products are selected',
      (WidgetTester tester) async {
    final widget = MapPage(
        mapControllerForTesting: mapController,
        requestedMode: MapPageRequestedMode.ADD_PRODUCT,
        product: product);
    final context = await commons.initIdleMapPage(widget, tester);

    await tester.superTap(find.text(context.strings.global_done));

    // Expecting the page to still be open
    expect(find.byType(MapPage), findsOneWidget);
    // Verify no product is added to any shop
    shopsManager.verify_putProductToShops_called(times: 0);
  });

  testWidgets('unselect shop', (WidgetTester tester) async {
    final widget = MapPage(
        mapControllerForTesting: mapController,
        requestedMode: MapPageRequestedMode.ADD_PRODUCT,
        product: product);
    final context = await commons.initIdleMapPage(widget, tester);

    // Select
    widget.onMarkerClickForTesting([shops[0]]);
    await tester.pumpAndSettle();
    await tester.superTap(find.text(context.strings.global_yes));
    // Verify
    expect(widget.getModeForTesting().selectedShops(), equals({shops[0]}));

    // Unselect
    widget.onMarkerClickForTesting([shops[0]]);
    await tester.pumpAndSettle();
    await tester.superTap(find.text(context.strings.global_no));
    // Verify
    expect(widget.getModeForTesting().selectedShops(), equals(<Shop>{}));

    await tester.superTap(find.text(context.strings.global_done));

    // Expecting the page to still be open
    expect(find.byType(MapPage), findsOneWidget);
    // Verify no product is added to any shop
    shopsManager.verity_createShop_called(times: 0);
  });

  testWidgets('can cancel the mode after shops are selected',
      (WidgetTester tester) async {
    final widget = MapPage(
        mapControllerForTesting: mapController,
        requestedMode: MapPageRequestedMode.ADD_PRODUCT,
        product: product);
    final context = await commons.initIdleMapPage(widget, tester);

    // Select
    widget.onMarkerClickForTesting([shops[0]]);
    await tester.pumpAndSettle();
    await tester.superTap(find.text(context.strings.global_yes));

    // Cancel
    await tester.superTap(find.text(context.strings.global_cancel));
    await tester.superTap(find.text(context.strings.global_yes));

    // Expecting the page to be closed
    expect(find.byType(MapPage), findsNothing);
    // Verify no product is added to any shop
    shopsManager.verity_createShop_called(times: 0);
  });

  testWidgets('can cancel the mode when no shops are selected',
      (WidgetTester tester) async {
    final widget = MapPage(
        mapControllerForTesting: mapController,
        requestedMode: MapPageRequestedMode.ADD_PRODUCT,
        product: product);
    final context = await commons.initIdleMapPage(widget, tester);

    await tester.superTap(find.text(context.strings.global_cancel));

    // Expecting the page to be closed
    expect(find.byType(MapPage), findsNothing);
    // Verify no product is added to any shop
    shopsManager.verity_createShop_called(times: 0);
  });

  testWidgets('can cancel a shop selection', (WidgetTester tester) async {
    final widget = await commons.createIdleMapPage(tester,
        requestedMode: MapPageRequestedMode.ADD_PRODUCT, product: product);

    // Tap
    widget.onMarkerClickForTesting([shops[0]]);
    await tester.pumpAndSettle();
    // Cancel
    await tester.superTap(find.byKey(const Key('card_cancel_btn')));
    // Verify
    expect(widget.getModeForTesting().selectedShops(), equals(<Shop>{}));
  });

  testWidgets('cannot select more than MAX shops', (WidgetTester tester) async {
    final manyShops = <Shop>[];
    for (var i = 0; i < MAP_PAGE_MODE_SELECTED_SHOPS_MAX * 2; ++i) {
      manyShops.add(Shop((e) => e
        ..osmShop.replace(OsmShop((e) => e
          ..osmUID = OsmUID.parse('1:$i')
          ..longitude = commons.shopsBounds.center.lon
          ..latitude = commons.shopsBounds.center.lat
          ..name = 'Spar$i'))
        ..backendShop.replace(BackendShop((e) => e
          ..osmUID = OsmUID.parse('1:$i')
          ..productsCount = i))));
    }
    await shopsManager.clearCache();
    shopsManager.addPreloadedArea(commons.shopsBounds, manyShops);

    final widget = MapPage(
        mapControllerForTesting: mapController,
        requestedMode: MapPageRequestedMode.ADD_PRODUCT,
        product: product);
    final context = await commons.initIdleMapPage(widget, tester);

    for (final shop in manyShops) {
      widget.onMarkerClickForTesting([shop]);
      await tester.pumpAndSettle();
      await tester.superTap(find.text(context.strings.global_yes));
    }
    expect(widget.getModeForTesting().selectedShops(),
        equals(manyShops.take(MAP_PAGE_MODE_SELECTED_SHOPS_MAX).toSet()));
  });

  testWidgets('can provide initially selected shops',
      (WidgetTester tester) async {
    final widget = await commons.createIdleMapPage(tester,
        requestedMode: MapPageRequestedMode.ADD_PRODUCT,
        product: product,
        initialSelectedShops: [shops[0]]);

    expect(widget.getModeForTesting().selectedShops(), equals({shops[0]}));
  });

  testWidgets('can switch mode to the Add Shop Mode',
      (WidgetTester tester) async {
    final widget = MapPage(
        mapControllerForTesting: mapController,
        requestedMode: MapPageRequestedMode.ADD_PRODUCT,
        product: product);
    final context = await commons.initIdleMapPage(widget, tester);

    expect(find.text(context.strings.map_page_click_where_new_shop_located),
        findsNothing);
    expect(widget.getModeForTesting().runtimeType,
        isNot(equals(MapPageModeCreateShop)));

    await tester.superTap(find.byKey(const Key('add_shop_fab')));

    expect(find.text(context.strings.map_page_click_where_new_shop_located),
        findsOneWidget);
    expect(
        widget.getModeForTesting().runtimeType, equals(MapPageModeCreateShop));
  });

  testWidgets('add product mode switch event', (WidgetTester tester) async {
    expect(analytics.allEvents().length, equals(0));

    await commons.createIdleMapPage(tester,
        requestedMode: MapPageRequestedMode.ADD_PRODUCT,
        product: product,
        initialSelectedShops: [shops[0]]);

    expect(analytics.allEvents().length, equals(1));
    expect(analytics.wasEventSent('map_page_mode_switch_add_product'), isTrue);
  });

  testWidgets('no shops hint', (WidgetTester tester) async {
    final widget = MapPage(
        mapControllerForTesting: mapController,
        requestedMode: MapPageRequestedMode.ADD_PRODUCT,
        product: product);
    final context = await commons.initIdleMapPage(widget, tester);

    expect(
        find.richTextContaining(
            context.strings.map_page_no_shops_hint_in_select_shops_mode),
        findsNothing);

    // No shops!
    await commons.clearFetchedShops(widget, tester, context);

    expect(
        find.richTextContaining(
            context.strings.map_page_no_shops_hint_in_select_shops_mode),
        findsOneWidget);

    // Fetch shops!
    await commons.fillFetchedShops(widget, tester);
    widget.onMapIdleForTesting();
    await tester.pumpAndSettle();

    expect(
        find.richTextContaining(
            context.strings.map_page_no_shops_hint_in_select_shops_mode),
        findsNothing);
  });
}
