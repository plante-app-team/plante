import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:plante/base/result.dart';
import 'package:plante/l10n/strings.dart';
import 'package:plante/model/shop.dart';
import 'package:plante/ui/base/components/shop_address_widget.dart';
import 'package:plante/ui/base/components/shop_card.dart';
import 'package:plante/ui/map/map_page/map_page.dart';

import '../../../common_mocks.mocks.dart';
import '../../../widget_tester_extension.dart';
import '../../../z_fakes/fake_analytics.dart';
import 'map_page_modes_test_commons.dart';

void main() {
  late MapPageModesTestCommons commons;
  late MockGoogleMapController mapController;
  late FakeAnalytics analytics;
  late MockShopsManager shopsManager;
  late List<Shop> shops;

  setUp(() async {
    commons = MapPageModesTestCommons();
    await commons.setUp();
    mapController = commons.mapController;
    shops = commons.shops;
    analytics = commons.analytics;
    shopsManager = commons.shopsManager;
  });

  testWidgets('empty shops are not displayed by default',
      (WidgetTester tester) async {
    expect(shops[0].productsCount, equals(0));

    final widget = MapPage(mapControllerForTesting: mapController);
    await tester.superPump(widget);
    widget.onMapIdleForTesting();
    await tester.pumpAndSettle();

    final displayedShops = widget.getDisplayedShopsForTesting();
    expect(displayedShops.length, equals(shops.length - 1));
    expect(displayedShops, contains(shops[1]));
    expect(displayedShops, contains(shops[2]));
    expect(displayedShops, contains(shops[3]));
  });

  testWidgets('empty shops are displayed only when user wants',
      (WidgetTester tester) async {
    expect(shops[0].productsCount, equals(0));

    final widget = MapPage(mapControllerForTesting: mapController);
    final context = await tester.superPump(widget);
    widget.onMapIdleForTesting();
    await tester.pumpAndSettle();

    await tester.tap(find.text(context.strings.map_page_empty_shops));

    final displayedShops = widget.getDisplayedShopsForTesting();
    expect(displayedShops.length, equals(shops.length));
    expect(displayedShops, containsAll(shops));
  });

  testWidgets('shop click', (WidgetTester tester) async {
    final widget = MapPage(mapControllerForTesting: mapController);
    await tester.superPump(widget);
    widget.onMapIdleForTesting();
    await tester.pumpAndSettle();

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
    final widget = MapPage(mapControllerForTesting: mapController);
    await tester.superPump(widget);
    widget.onMapIdleForTesting();
    await tester.pumpAndSettle();

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
    final widget = MapPage(mapControllerForTesting: mapController);
    await tester.superPump(widget);
    widget.onMapIdleForTesting();
    await tester.pumpAndSettle();

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
    final context = await tester.superPump(widget);
    widget.onMapIdleForTesting();
    await tester.pumpAndSettle();

    widget.onMarkerClickForTesting([shops[0]]);
    await tester.pumpAndSettle();

    expect(find.text(context.strings.shop_card_no_products_in_shop),
        findsOneWidget);
    expect(find.text(context.strings.shop_card_there_are_products_in_shop),
        findsNothing);

    // Add a product to the shop, kind of
    var backendShop = commons.shops[0].backendShop!;
    backendShop = backendShop
        .rebuild((e) => e.productsCount = backendShop.productsCount + 1);
    commons.shops[0] =
        commons.shops[0].rebuild((e) => e.backendShop.replace(backendShop));
    commons.shopsMap = {for (final shop in commons.shops) shop.osmId: shop};
    // Notify about the update
    commons.shopsManagerListeners.forEach((listener) {
      listener.onLocalShopsChange();
    });
    await tester.pumpAndSettle();

    expect(
        find.text(context.strings.shop_card_no_products_in_shop), findsNothing);
    expect(find.text(context.strings.shop_card_there_are_products_in_shop),
        findsOneWidget);
  });

  testWidgets('shops card closes on back press', (WidgetTester tester) async {
    final widget = MapPage(mapControllerForTesting: mapController);
    await tester.superPump(widget);
    widget.onMapIdleForTesting();
    await tester.pumpAndSettle();

    expect(find.byType(ShopCard), findsNothing);

    widget.onMarkerClickForTesting([shops[0]]);
    await tester.pumpAndSettle();

    expect(find.byType(ShopCard), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();

    expect(find.byType(ShopCard), findsNothing);
  });

  testWidgets('empty shops analytics', (WidgetTester tester) async {
    final widget = MapPage(mapControllerForTesting: mapController);
    final context = await tester.superPump(widget);
    widget.onMapIdleForTesting();
    await tester.pumpAndSettle();

    expect(analytics.allEvents(), equals([]));

    await tester.tap(find.text(context.strings.map_page_empty_shops));

    expect(analytics.wasEventSent('empty_shops_shown'), isTrue);
    analytics.clearEvents();

    await tester.tap(find.text(context.strings.map_page_empty_shops));

    expect(analytics.wasEventSent('empty_shops_hidden'), isTrue);
  });

  testWidgets('no shops hint when empty shops are not displayed',
      (WidgetTester tester) async {
    // Shops available!
    commons.fillFetchedShops();

    final widget = MapPage(mapControllerForTesting: mapController);
    final context = await tester.superPump(widget);
    widget.onMapIdleForTesting();
    await tester.pumpAndSettle();

    expect(find.text(context.strings.map_page_no_shops_hint_default_mode_1),
        findsNothing);
    expect(find.text(context.strings.map_page_no_shops_hint_default_mode_2),
        findsNothing);

    // No shops!
    commons.clearFetchedShops();
    widget.onMapIdleForTesting();
    await tester.pumpAndSettle();

    expect(find.text(context.strings.map_page_no_shops_hint_default_mode_1),
        findsOneWidget);
    expect(find.text(context.strings.map_page_no_shops_hint_default_mode_2),
        findsNothing);

    // Fetch shops!
    commons.fillFetchedShops();
    widget.onMapIdleForTesting();
    await tester.pumpAndSettle();

    expect(find.text(context.strings.map_page_no_shops_hint_default_mode_1),
        findsNothing);
    expect(find.text(context.strings.map_page_no_shops_hint_default_mode_2),
        findsNothing);
  });

  testWidgets('no shops hint when empty shops are displayed',
      (WidgetTester tester) async {
    // Shops available!
    commons.fillFetchedShops();

    final widget = MapPage(mapControllerForTesting: mapController);
    final context = await tester.superPump(widget);
    // Show empty shops
    await tester.tap(find.text(context.strings.map_page_empty_shops));

    widget.onMapIdleForTesting();
    await tester.pumpAndSettle();

    expect(find.text(context.strings.map_page_no_shops_hint_default_mode_1),
        findsNothing);
    expect(find.text(context.strings.map_page_no_shops_hint_default_mode_2),
        findsNothing);

    // No shops!
    commons.clearFetchedShops();
    widget.onMapIdleForTesting();
    await tester.pumpAndSettle();

    expect(find.text(context.strings.map_page_no_shops_hint_default_mode_1),
        findsNothing);
    expect(find.text(context.strings.map_page_no_shops_hint_default_mode_2),
        findsOneWidget);

    // Fetch shops!
    commons.fillFetchedShops();
    widget.onMapIdleForTesting();
    await tester.pumpAndSettle();

    expect(find.text(context.strings.map_page_no_shops_hint_default_mode_1),
        findsNothing);
    expect(find.text(context.strings.map_page_no_shops_hint_default_mode_2),
        findsNothing);
  });

  testWidgets('no shops hint dynamic switching', (WidgetTester tester) async {
    final widget = MapPage(mapControllerForTesting: mapController);
    final context = await tester.superPump(widget);

    // No shops!
    commons.clearFetchedShops();
    widget.onMapIdleForTesting();
    await tester.pumpAndSettle();

    // Hint 1
    expect(find.text(context.strings.map_page_no_shops_hint_default_mode_1),
        findsOneWidget);
    expect(find.text(context.strings.map_page_no_shops_hint_default_mode_2),
        findsNothing);

    // Show empty shops
    await tester.tap(find.text(context.strings.map_page_empty_shops));
    await tester.pumpAndSettle();

    // Hint 2
    expect(find.text(context.strings.map_page_no_shops_hint_default_mode_1),
        findsNothing);
    expect(find.text(context.strings.map_page_no_shops_hint_default_mode_2),
        findsOneWidget);

    // Hide empty shops
    await tester.tap(find.text(context.strings.map_page_empty_shops));
    await tester.pumpAndSettle();

    // Hint 1
    expect(find.text(context.strings.map_page_no_shops_hint_default_mode_1),
        findsOneWidget);
    expect(find.text(context.strings.map_page_no_shops_hint_default_mode_2),
        findsNothing);
  });

  testWidgets('no shops hint is not shown until shops are loaded',
      (WidgetTester tester) async {
    final completer = Completer<Map<String, Shop>>();
    when(shopsManager.fetchShops(any))
        .thenAnswer((_) async => Ok(await completer.future));

    final widget = MapPage(mapControllerForTesting: mapController);
    final context = await tester.superPump(widget);
    widget.onMapIdleForTesting();
    await tester.pump(const Duration(milliseconds: 10));

    // No hints yet!
    expect(find.text(context.strings.map_page_no_shops_hint_default_mode_1),
        findsNothing);
    expect(find.text(context.strings.map_page_no_shops_hint_default_mode_2),
        findsNothing);

    // Shops loaded, and there are no shops!
    completer.complete({});
    await tester.pumpAndSettle();

    expect(find.text(context.strings.map_page_no_shops_hint_default_mode_1),
        findsOneWidget);
    expect(find.text(context.strings.map_page_no_shops_hint_default_mode_2),
        findsNothing);
  });

  testWidgets('shop address is shown on the shop card',
      (WidgetTester tester) async {
    final widget = MapPage(mapControllerForTesting: mapController);
    await tester.superPump(widget);
    widget.onMapIdleForTesting();
    await tester.pumpAndSettle();

    expect(find.byType(ShopCard), findsNothing);
    expect(find.byType(ShopAddressWidget), findsNothing);

    widget.onMarkerClickForTesting([shops[1]]);
    await tester.pumpAndSettle();

    expect(find.byType(ShopCard), findsOneWidget);
    expect(find.byType(ShopAddressWidget), findsOneWidget);
  });
}
