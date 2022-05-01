import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plante/model/shop.dart';
import 'package:plante/ui/base/components/shop_card.dart';
import 'package:plante/ui/map/map_page/map_page.dart';
import 'package:plante/ui/map/map_page/map_page_testing_storage.dart';

import '../../../common_mocks.mocks.dart';
import '../../../widget_tester_extension.dart';
import 'map_page_modes_test_commons.dart';

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

  testWidgets('demonstrate shops', (WidgetTester tester) async {
    final widget = MapPage(
        mapControllerForTesting: mapController,
        requestedMode: MapPageRequestedMode.DEMONSTRATE_SHOPS,
        initialSelectedShops: [shops.first]);
    await commons.initIdleMapPage(widget, tester);

    expect(widget.getDisplayedShopsForTesting(), equals({shops.first}));

    expect(find.byType(ShopCard), findsOneWidget);
    expect(find.text(shops.first.name), findsOneWidget);
    expect(widget.getModeForTesting().accentedShops(), equals({shops.first}));
  });

  testWidgets('page closes when the shops card is closed',
      (WidgetTester tester) async {
    final widget = MapPage(
        mapControllerForTesting: mapController,
        requestedMode: MapPageRequestedMode.DEMONSTRATE_SHOPS,
        initialSelectedShops: [shops.first]);
    await commons.initIdleMapPage(widget, tester);

    expect(find.byType(ShopCard), findsOneWidget);

    expect(find.byType(MapPage), findsOneWidget);
    await tester.superTap(find.byKey(const Key('card_cancel_btn')));
    expect(find.byType(MapPage), findsNothing);
  });

  testWidgets('page closes when the back button is clicked',
      (WidgetTester tester) async {
    final widget = MapPage(
        mapControllerForTesting: mapController,
        requestedMode: MapPageRequestedMode.DEMONSTRATE_SHOPS,
        initialSelectedShops: [shops.first]);
    await commons.initIdleMapPage(widget, tester);

    expect(find.byType(MapPage), findsOneWidget);
    await tester.superTap(find.byKey(const Key('back_button')));
    expect(find.byType(MapPage), findsNothing);
  });
}
