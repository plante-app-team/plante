import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:mockito/mockito.dart';
import 'package:plante/model/shop.dart';
import 'package:plante/ui/map/map_page.dart';
import 'package:plante/l10n/strings.dart';
import 'package:plante/ui/map/map_page_mode_create_shop.dart';

import '../../widget_tester_extension.dart';
import 'map_page_modes_test_commons.dart';
import 'map_page_modes_test_commons.mocks.dart';

void main() {
  late MapPageModesTestCommons commons;
  late MockGoogleMapController mapController;
  late MockShopsManager shopsManager;
  late List<Shop> shops;

  setUp(() async {
    commons = MapPageModesTestCommons();
    await commons.setUp();
    mapController = commons.mapController;
    shops = commons.shops;
    shopsManager = commons.shopsManager;
  });

  Future<void> switchMode(WidgetTester tester, MapPage widget, BuildContext context) async {
    final context = await tester.superPump(widget);
    widget.onMapIdleForTesting();
    await tester.pumpAndSettle();

    await tester.tap(find.text(context.strings.map_page_plus_shop));
    await tester.pumpAndSettle();

    expect(widget.getModeForTesting().runtimeType,
        equals(MapPageModeCreateShop));
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
    expectedAllShops.addAll(shops);
    expectedAllShops.addAll(widget.getModeForTesting().additionalShops());
    expect(widget.getDisplayedShopsForTesting(), equals(expectedAllShops));

    widget.onMapClickForTesting(const LatLng(10, 20));
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

    widget.onMapClickForTesting(const LatLng(10, 20));
    await tester.pumpAndSettle();

    await tester.enterText(
        find.byKey(const Key('new_shop_name_input')),
        'new shop');
    await tester.pumpAndSettle();

    await tester.tap(find.text(context.strings.global_add));
    await tester.pumpAndSettle();

    verifyNever(shopsManager.createShop(
        name: anyNamed('name'),
        coords: anyNamed('coords'),
        type: anyNamed('type')));

    await tester.tap(find.text(context.strings.global_done));
    await tester.pumpAndSettle();

    // Product is created
    verify(shopsManager.createShop(
        name: 'new shop',
        coords: anyNamed('coords'),
        type: anyNamed('type')));
    // Mode is changed
    expect(widget.getModeForTesting().runtimeType,
        isNot(equals(MapPageModeCreateShop)));
  });
}
