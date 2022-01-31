import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:plante/l10n/strings.dart';
import 'package:plante/model/shop.dart';
import 'package:plante/ui/base/components/address_widget.dart';
import 'package:plante/ui/base/components/shop_card.dart';
import 'package:plante/ui/map/components/map_search_bar.dart';
import 'package:plante/ui/map/map_page/map_page.dart';
import 'package:plante/ui/map/map_page/map_page_mode.dart';
import 'package:plante/ui/map/map_page/map_page_mode_default.dart';
import 'package:plante/ui/map/map_page/map_page_testing_storage.dart';

import '../../../common_finders_extension.dart';
import '../../../common_mocks.mocks.dart';
import '../../../widget_tester_extension.dart';
import '../../../z_fakes/fake_shops_manager.dart';
import 'map_page_modes_test_commons.dart';

void main() {
  late MapPageModesTestCommons commons;
  late MockGoogleMapController mapController;
  late FakeShopsManager shopsManager;
  late MockDirectionsManager directionsManager;
  late List<Shop> shops;

  setUp(() async {
    commons = MapPageModesTestCommons();
    await commons.setUp();
    mapController = commons.mapController;
    shops = commons.shops;
    shopsManager = commons.shopsManager;
    directionsManager = commons.directionsManager;
  });

  testWidgets('empty shops are not displayed by default',
      (WidgetTester tester) async {
    expect(shops[0].productsCount, equals(0));

    final widget = await commons.createIdleMapPage(tester);

    final displayedShops = widget.getDisplayedShopsForTesting();
    expect(displayedShops.length, equals(shops.length - 1));
    expect(displayedShops, contains(shops[1]));
    expect(displayedShops, contains(shops[2]));
    expect(displayedShops, contains(shops[3]));
  });

  testWidgets('shop click', (WidgetTester tester) async {
    final widget = await commons.createIdleMapPage(tester);

    expect(find.byType(ShopCard), findsNothing);
    expect(find.text(shops[1].name), findsNothing);
    expect(widget.getModeForTesting().accentedShops(), isEmpty);

    widget.onMarkerClickForTesting([shops[1]]);
    await tester.pumpAndSettle();

    expect(find.byType(ShopCard), findsOneWidget);
    expect(find.text(shops[1].name), findsOneWidget);
    expect(widget.getModeForTesting().accentedShops(), equals({shops[1]}));

    expect(find.text(shops[0].name), findsNothing);
    expect(find.text(shops[2].name), findsNothing);
    expect(find.text(shops[3].name), findsNothing);
  });

  testWidgets('marker with many shops click', (WidgetTester tester) async {
    final widget = await commons.createIdleMapPage(tester);

    expect(find.byType(ShopCard), findsNothing);
    expect(find.text(shops[1].name), findsNothing);
    expect(find.text(shops[2].name), findsNothing);
    expect(widget.getModeForTesting().accentedShops(), isEmpty);

    widget.onMarkerClickForTesting([shops[1], shops[2]]);
    await tester.pumpAndSettle();

    expect(find.byType(ShopCard), findsNWidgets(2));
    expect(find.text(shops[1].name), findsOneWidget);
    expect(find.text(shops[2].name), findsOneWidget);
    expect(widget.getModeForTesting().accentedShops(),
        equals({shops[1], shops[2]}));

    expect(find.text(shops[0].name), findsNothing);
    expect(find.text(shops[3].name), findsNothing);
  });

  testWidgets('when many cards are shown, shops with many products are first',
      (WidgetTester tester) async {
    final widget = await commons.createIdleMapPage(tester);

    widget.onMarkerClickForTesting([shops[0], shops[1]]);
    await tester.pumpAndSettle();

    final emptyShopLeft = tester.getCenter(find.text(shops[0].name));
    final notEmptyShopLeft = tester.getCenter(find.text(shops[1].name));
    expect(emptyShopLeft.dx, greaterThan(notEmptyShopLeft.dx));
  });

  testWidgets('shop card changes when shops update',
      (WidgetTester tester) async {
    expect(shops[0].productsCount, 0);

    final widget = MapPage(mapControllerForTesting: mapController);
    final context = await commons.initIdleMapPage(widget, tester);

    widget.onMarkerClickForTesting([shops[0]]);
    await tester.pumpAndSettle();

    expect(find.text(context.strings.shop_card_no_products_listed),
        findsOneWidget);
    expect(find.text(context.strings.shop_card_products_listed), findsNothing);

    // Add a product to the shop, kind of
    var backendShop = commons.shops[0].backendShop!;
    backendShop = backendShop
        .rebuild((e) => e.productsCount = backendShop.productsCount + 1);

    final shopsCopy = commons.shops.toList();
    shopsCopy[0] =
        shopsCopy[0].rebuild((e) => e.backendShop.replace(backendShop));
    await commons.replaceFetchedShops(shopsCopy, tester);
    await tester.pumpAndSettle();

    expect(
        find.text(context.strings.shop_card_no_products_listed), findsNothing);
    expect(
        find.text(context.strings.shop_card_products_listed), findsOneWidget);
  });

  testWidgets('shops card closes on back press', (WidgetTester tester) async {
    final widget = await commons.createIdleMapPage(tester);

    expect(find.byType(ShopCard), findsNothing);

    widget.onMarkerClickForTesting([shops[0]]);
    await tester.pumpAndSettle();

    expect(find.byType(ShopCard), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();

    expect(find.byType(ShopCard), findsNothing);
  });

  testWidgets('no shops hint', (WidgetTester tester) async {
    final widget = MapPage(mapControllerForTesting: mapController);
    final context = await commons.initIdleMapPage(widget, tester);

    expect(find.richTextContaining(context.strings.map_page_no_shops_hint2),
        findsNothing);

    // No shops!
    await commons.clearFetchedShops(widget, tester, context);

    // 'No shops' hint is expected
    expect(find.richTextContaining(context.strings.map_page_no_shops_hint2),
        findsOneWidget);

    // Fetch shops!
    await commons.fillFetchedShops(widget, tester);

    expect(find.richTextContaining(context.strings.map_page_no_shops_hint2),
        findsNothing);
  });

  testWidgets('"no shops" hint is not shown until shops are loaded',
      (WidgetTester tester) async {
    await shopsManager.clearCache();
    final completer = Completer<List<Shop>>();
    shopsManager.setAsyncShopsLoader((_) => completer.future);

    final widget = MapPage(mapControllerForTesting: mapController);
    final context = await commons.initIdleMapPage(widget, tester);

    await tester
        .superTap(find.text(context.strings.map_page_load_shops_of_this_area));

    // No hints yet!
    expect(find.richTextContaining(context.strings.map_page_no_shops_hint2),
        findsNothing);

    // Shops loaded, and there are no shops!
    completer.complete([]);
    await tester.pumpAndSettle();

    expect(find.richTextContaining(context.strings.map_page_no_shops_hint2),
        findsOneWidget);
  });

  testWidgets('shop address is shown on the shop card',
      (WidgetTester tester) async {
    final widget = await commons.createIdleMapPage(tester);

    expect(find.byType(ShopCard), findsNothing);
    expect(find.byType(AddressWidget), findsNothing);

    widget.onMarkerClickForTesting([shops[1]]);
    await tester.pumpAndSettle();

    expect(find.byType(ShopCard), findsOneWidget);
    expect(find.byType(AddressWidget), findsOneWidget);
  });

  testWidgets('shop card directions btn when directions available',
      (WidgetTester tester) async {
    when(directionsManager.areDirectionsAvailable())
        .thenAnswer((_) async => true);

    final widget = await commons.createIdleMapPage(tester);

    final shop = shops[1];

    verifyNever(directionsManager.direct(any, any));

    widget.onMarkerClickForTesting([shop]);
    await tester.pumpAndSettle();
    await tester.superTap(find.byKey(const Key('directions_button')));

    verify(directionsManager.direct(shop.coord, shop.name));
  });

  testWidgets('shop card directions btn when directions not available',
      (WidgetTester tester) async {
    when(directionsManager.areDirectionsAvailable())
        .thenAnswer((_) async => false);

    final widget = await commons.createIdleMapPage(tester);

    widget.onMarkerClickForTesting([shops[1]]);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('directions_button')), findsNothing);
  });

  testWidgets('huge zoom out when shops ARE NOT loaded',
      (WidgetTester tester) async {
    await shopsManager.clearCache();

    final widget = MapPage(mapControllerForTesting: mapController);
    final context = await commons.initIdleMapPage(widget, tester);

    // Close zoom and expected (and not expected) widgets
    await commons.moveCamera(commons.shopsBounds.center,
        MapPageMode.DEFAULT_MIN_ZOOM, widget, tester);
    expect(find.text(context.strings.map_page_load_shops_of_this_area),
        findsOneWidget);
    expect(
        find.text(context.strings.map_page_zoom_in_to_see_shops), findsNothing);
    expect(find.byType(MapSearchBar), findsNothing);
    expect(find.byKey(const Key('filter_shops_icon')), findsNothing);

    // Map zoomed out really much
    await commons.moveCamera(commons.shopsBounds.center,
        MapPageModeDefault.MIN_ZOOM, widget, tester);

    // Again, expected and not expected widgets
    expect(find.text(context.strings.map_page_load_shops_of_this_area),
        findsNothing);
    expect(find.text(context.strings.map_page_zoom_in_to_see_shops),
        findsOneWidget);
    expect(find.byType(MapSearchBar), findsNothing);
    expect(find.byKey(const Key('filter_shops_icon')), findsNothing);

    // Map zoomed back in - first check done again
    await commons.moveCamera(commons.shopsBounds.center,
        MapPageMode.DEFAULT_MAX_ZOOM, widget, tester);
    expect(find.text(context.strings.map_page_load_shops_of_this_area),
        findsOneWidget);
    expect(
        find.text(context.strings.map_page_zoom_in_to_see_shops), findsNothing);
    expect(find.byType(MapSearchBar), findsNothing);
    expect(find.byKey(const Key('filter_shops_icon')), findsNothing);
  });

  testWidgets('huge zoom out when shops ARE loaded',
      (WidgetTester tester) async {
    final widget = MapPage(mapControllerForTesting: mapController);
    final context = await commons.initIdleMapPage(widget, tester);

    // Close zoom and expected (and not expected) widgets
    await commons.moveCamera(commons.shopsBounds.center,
        MapPageMode.DEFAULT_MIN_ZOOM, widget, tester);
    expect(find.text(context.strings.map_page_load_shops_of_this_area),
        findsNothing);
    expect(
        find.text(context.strings.map_page_zoom_in_to_see_shops), findsNothing);
    expect(find.byType(MapSearchBar), findsOneWidget);
    expect(find.byKey(const Key('filter_listview')), findsOneWidget);

    // Map zoomed out really much
    await commons.moveCamera(commons.shopsBounds.center,
        MapPageModeDefault.MIN_ZOOM, widget, tester);

    // Again, expected and not expected widgets
    expect(find.text(context.strings.map_page_load_shops_of_this_area),
        findsNothing);
    expect(find.text(context.strings.map_page_zoom_in_to_see_shops),
        findsOneWidget);
    expect(find.byType(MapSearchBar), findsNothing);
    expect(find.byKey(const Key('filter_listview')), findsNothing);

    // Map zoomed back in - first check done again
    await commons.moveCamera(commons.shopsBounds.center,
        MapPageMode.DEFAULT_MAX_ZOOM, widget, tester);
    expect(find.text(context.strings.map_page_load_shops_of_this_area),
        findsNothing);
    expect(
        find.text(context.strings.map_page_zoom_in_to_see_shops), findsNothing);
    expect(find.byType(MapSearchBar), findsOneWidget);
    expect(find.byKey(const Key('filter_listview')), findsOneWidget);
  });
}
