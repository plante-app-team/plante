import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:plante/l10n/strings.dart';
import 'package:plante/model/product.dart';
import 'package:plante/model/product_lang_slice.dart';
import 'package:plante/model/shop.dart';
import 'package:plante/ui/map/map_page/map_page.dart';
import 'package:plante/ui/map/map_page/map_page_testing_storage.dart';

import '../../../common_mocks.mocks.dart';
import '../../../widget_tester_extension.dart';
import '../../../z_fakes/fake_analytics.dart';
import 'map_page_modes_test_commons.dart';

/// NOTE: most of the mode tests are performed in
/// map_page_mode_add_product_test, because both modes have same
/// ancestor.
void main() {
  late MapPageModesTestCommons commons;
  late MockGoogleMapController mapController;
  late FakeAnalytics analytics;
  late List<Shop> shops;

  setUp(() async {
    commons = MapPageModesTestCommons();
    await commons.setUp();
    mapController = commons.mapController;
    shops = commons.shops;
    analytics = commons.analytics;
  });

  testWidgets('can select shops', (WidgetTester tester) async {
    final navigationObserver = MockNavigatorObserver();
    final widget = MapPage(
        mapControllerForTesting: mapController,
        requestedMode: MapPageRequestedMode.SELECT_SHOPS);
    final context = await commons.initIdleMapPage(widget, tester,
        navigatorObserver: navigationObserver);

    widget.onMarkerClickForTesting([shops[0]]);
    await tester.pumpAndSettle();
    await tester.superTap(find.text(context.strings.global_yes));

    reset(navigationObserver);

    await tester.superTap(find.text(context.strings.global_done));

    final capturedRoute = verify(navigationObserver.didPop(captureAny, any))
        .captured
        .first as Route<dynamic>;
    expect(await capturedRoute.popped, equals([shops[0]]));
  });

  testWidgets('shop selection with provided product',
      (WidgetTester tester) async {
    final product = ProductLangSlice((e) => e
      ..barcode = '222'
      ..name = 'Product name').productForTests();

    final navigationObserver = MockNavigatorObserver();
    final widget = MapPage(
        mapControllerForTesting: mapController,
        requestedMode: MapPageRequestedMode.SELECT_SHOPS,
        product: product);
    final context = await commons.initIdleMapPage(widget, tester,
        navigatorObserver: navigationObserver);

    widget.onMarkerClickForTesting([shops[0]]);
    await tester.pumpAndSettle();

    final productString = context.strings.map_page_is_product_sold_q
        .replaceAll('<PRODUCT>', product.name!);
    final noProductString = context.strings.map_page_is_new_product_sold_q;
    expect(find.text(productString), findsOneWidget);
    expect(find.text(noProductString), findsNothing);
  });

  testWidgets('shop selection without provided product',
      (WidgetTester tester) async {
    final navigationObserver = MockNavigatorObserver();
    final widget = MapPage(
        mapControllerForTesting: mapController,
        requestedMode: MapPageRequestedMode.SELECT_SHOPS,
        product: null);
    final context = await commons.initIdleMapPage(widget, tester,
        navigatorObserver: navigationObserver);

    widget.onMarkerClickForTesting([shops[0]]);
    await tester.pumpAndSettle();

    final noProductString = context.strings.map_page_is_new_product_sold_q;
    expect(find.text(noProductString), findsOneWidget);
  });

  testWidgets('select shops mode switch event', (WidgetTester tester) async {
    expect(analytics.allEvents().length, equals(0));

    await commons.createIdleMapPage(tester,
        requestedMode: MapPageRequestedMode.SELECT_SHOPS);

    expect(analytics.allEvents().length, equals(1));
    expect(
        analytics.wasEventSent(
            'map_page_mode_switch_select_shops_where_product_sold'),
        isTrue);
  });
}
