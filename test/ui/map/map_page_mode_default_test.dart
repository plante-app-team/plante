import 'package:flutter_test/flutter_test.dart';
import 'package:plante/model/shop.dart';
import 'package:plante/ui/base/components/shop_card.dart';
import 'package:plante/ui/map/map_page.dart';
import 'package:plante/l10n/strings.dart';

import '../../widget_tester_extension.dart';
import 'map_page_modes_test_commons.dart';
import 'map_page_modes_test_commons.mocks.dart';

void main() {
  late MapPageModesTestCommons commons;
  late MockGoogleMapController mapController;
  late List<Shop> shops;

  setUp(() async {
    commons = MapPageModesTestCommons();
    await commons.setUp();
    mapController = commons.mapController;
    shops = commons.shops;
  });

  testWidgets('empty shops are not displayed by default', (WidgetTester tester) async {
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

  testWidgets('empty shops are displayed only when user wants', (WidgetTester tester) async {
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
    expect(widget.getModeForTesting().accentedShops(), equals({shops[1], shops[2]}));

    expect(find.text(shops[0].name), findsNothing);
    expect(find.text(shops[3].name), findsNothing);
  });

  testWidgets('when many cards are shown, shops with many products are first', (WidgetTester tester) async {
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

  testWidgets('shop card changes when shops update', (WidgetTester tester) async {
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
    commons.shopsMap = { for (final shop in commons.shops) shop.osmId: shop };
    // Notify about the update
    commons.shopsManagerListeners.forEach((listener) {
      listener.onLocalShopsChange();
    });
    await tester.pumpAndSettle();

    expect(find.text(context.strings.shop_card_no_products_in_shop),
        findsNothing);
    expect(find.text(context.strings.shop_card_there_are_products_in_shop),
        findsOneWidget);
  });
}
