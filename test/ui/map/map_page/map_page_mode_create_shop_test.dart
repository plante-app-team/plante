import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plante/l10n/strings.dart';
import 'package:plante/model/coord.dart';
import 'package:plante/model/shop.dart';
import 'package:plante/ui/map/create_shop_page.dart';
import 'package:plante/ui/map/map_page/map_page.dart';
import 'package:plante/ui/map/map_page/map_page_mode_create_shop.dart';
import 'package:plante/ui/map/map_page/map_page_mode_select_shops_where_product_sold.dart';
import 'package:plante/ui/map/map_page/map_page_testing_storage.dart';

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

  setUp(() async {
    commons = MapPageModesTestCommons();
    await commons.setUp();
    mapController = commons.mapController;
    shops = commons.shops;
    shopsManager = commons.shopsManager;
    analytics = commons.analytics;
  });

  Future<void> switchMode(
      WidgetTester tester, MapPage widget, BuildContext context) async {
    await tester.superPump(widget);
    widget.onMapIdleForTesting();
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('add_shop_fab')));
    await tester.pumpAndSettle();

    expect(
        widget.getModeForTesting().runtimeType, equals(MapPageModeCreateShop));
  }

  testWidgets('keeps selected shops', (WidgetTester tester) async {
    final widget = MapPage(
        mapControllerForTesting: mapController,
        requestedMode: MapPageRequestedMode.SELECT_SHOPS,
        initialSelectedShops: [shops[1]]);
    final context = await tester.superPump(widget);
    await switchMode(tester, widget, context);

    expect(widget.getModeForTesting().selectedShops(), equals({shops[1]}));
  });

  testWidgets('all shops markers are hidden', (WidgetTester tester) async {
    final widget = MapPage(
        mapControllerForTesting: mapController,
        requestedMode: MapPageRequestedMode.SELECT_SHOPS);
    final context = await tester.superPump(widget);
    await switchMode(tester, widget, context);

    expect(widget.getDisplayedShopsForTesting(), isEmpty);
  });

  testWidgets('map click', (WidgetTester tester) async {
    final widget = MapPage(
        mapControllerForTesting: mapController,
        requestedMode: MapPageRequestedMode.SELECT_SHOPS,
        initialSelectedShops: [shops[1]]);
    final context = await tester.superPump(widget);
    await switchMode(tester, widget, context);

    expect(widget.getModeForTesting().accentedShops(), equals(<Shop>{}));
    expect(widget.getModeForTesting().additionalShops(), equals(<Shop>{}));
    final expectedAllShops = <Shop>{};
    expectedAllShops.addAll(widget.getModeForTesting().additionalShops());
    expect(widget.getDisplayedShopsForTesting(), equals(expectedAllShops));

    widget.onMapClickForTesting(Coord(lat: 10, lon: 20));
    await tester.pumpAndSettle();

    expect(widget.getModeForTesting().accentedShops().length, equals(1));
    final shopBeingCreated = widget.getModeForTesting().accentedShops().first;
    expect(shopBeingCreated.latitude, equals(10));
    expect(shopBeingCreated.longitude, equals(20));
  });

  testWidgets('shop creation', (WidgetTester tester) async {
    final widget = MapPage(
        mapControllerForTesting: mapController,
        requestedMode: MapPageRequestedMode.SELECT_SHOPS,
        initialSelectedShops: [shops[1]]);
    final context = await tester.superPump(widget);
    await switchMode(tester, widget, context);

    expect(find.text(context.strings.map_page_is_shop_location_correct),
        findsNothing);
    widget.onMapClickForTesting(Coord(lat: 10, lon: 20));
    await tester.pumpAndSettle();
    expect(find.text(context.strings.map_page_is_shop_location_correct),
        findsOneWidget);

    expect(find.byType(CreateShopPage), findsNothing);
    await tester.superTap(find.text(context.strings.global_yes));
    expect(find.byType(CreateShopPage), findsOneWidget);

    await tester.enterText(
        find.byKey(const Key('new_shop_name_input')), 'new shop');
    await tester.pumpAndSettle();

    await tester.superTap(find.byKey(const Key('shop_type_dropdown')));
    await tester.superTapDropDownItem(context.strings.shop_type_supermarket);

    shopsManager.verity_createShop_called(times: 0);

    await tester.superTap(find.text(context.strings.global_done));

    // Shop is created
    shopsManager.verity_createShop_called(times: 1);
    // Mode is changed
    expect(widget.getModeForTesting().runtimeType,
        equals(MapPageModeSelectShopsWhereProductSold));

    // New mode has the created shop in its selection
    final selectedCreatedShop = widget
        .getModeForTesting()
        .selectedShops()
        .where((shop) => shop.name == 'new shop');
    expect(selectedCreatedShop.length, equals(1));
  });

  testWidgets('user hints transition', (WidgetTester tester) async {
    final widget = MapPage(
        mapControllerForTesting: mapController,
        requestedMode: MapPageRequestedMode.SELECT_SHOPS,
        initialSelectedShops: [shops[1]]);
    final context = await tester.superPump(widget);

    // Old hint
    expect(find.text(context.strings.map_page_click_on_shop_where_product_sold),
        findsOneWidget);
    expect(find.text(context.strings.map_page_click_where_new_shop_located),
        findsNothing);

    await switchMode(tester, widget, context);

    // New hint
    expect(find.text(context.strings.map_page_click_on_shop_where_product_sold),
        findsNothing);
    expect(find.text(context.strings.map_page_click_where_new_shop_located),
        findsOneWidget);
  });

  testWidgets('cancellation returns to previous mode',
      (WidgetTester tester) async {
    final widget = MapPage(
        mapControllerForTesting: mapController,
        requestedMode: MapPageRequestedMode.SELECT_SHOPS,
        initialSelectedShops: [shops[1]]);
    final context = await tester.superPump(widget);
    await switchMode(tester, widget, context);

    expect(
        widget.getModeForTesting().runtimeType, equals(MapPageModeCreateShop));

    await tester.superTap(find.byKey(const Key('close_create_shop_button')));

    expect(widget.getModeForTesting().runtimeType,
        equals(MapPageModeSelectShopsWhereProductSold));
  });

  testWidgets('create shop mode switch event', (WidgetTester tester) async {
    final widget = MapPage(
        mapControllerForTesting: mapController,
        requestedMode: MapPageRequestedMode.SELECT_SHOPS,
        initialSelectedShops: [shops[1]]);
    final context = await tester.superPump(widget);

    analytics.clearEvents();
    await switchMode(tester, widget, context);
    expect(analytics.allEvents().length, equals(1));
    expect(analytics.wasEventSent('map_page_mode_switch_create_shop'), isTrue);
  });
}
