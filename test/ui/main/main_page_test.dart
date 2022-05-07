import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mockito/mockito.dart';
import 'package:plante/base/result.dart';
import 'package:plante/contributions/user_contributions_manager.dart';
import 'package:plante/l10n/strings.dart';
import 'package:plante/model/coord.dart';
import 'package:plante/outside/news/news_feed_manager.dart';
import 'package:plante/products/contributed_by_user_products_storage.dart';
import 'package:plante/products/viewed_products_storage.dart';
import 'package:plante/ui/main/main_page.dart';
import 'package:plante/ui/map/map_page/map_page.dart';
import 'package:plante/ui/map/map_page/map_page_testing_storage.dart';
import 'package:plante/ui/map/shop_creation/create_shop_page.dart';
import 'package:plante/ui/map/shop_creation/shops_creation_manager.dart';
import 'package:plante/ui/product/init_product_page.dart';
import 'package:plante/ui/scan/barcode_scan_page.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart' as qr;

import '../../common_mocks.mocks.dart';
import '../../test_di_registry.dart';
import '../../widget_tester_extension.dart';
import '../../z_fakes/fake_news_feed_manager.dart';
import '../../z_fakes/fake_shops_manager.dart';
import '../../z_fakes/fake_user_contributions_manager.dart';
import '../map/map_page/map_page_modes_test_commons.dart';

void main() {
  late MapPageModesTestCommons mapTestsCommons;
  late FakeShopsManager shopsManager;
  late MockViewedProductsStorage viewedProductsStorage;
  late MockContributedByUserProductsStorage contributedByUserProductsStorage;
  late FakeUserContributionsManager userContributionsManager;
  late FakeNewsFeedManager newsFeedManager;

  setUp(() async {
    viewedProductsStorage = MockViewedProductsStorage();
    contributedByUserProductsStorage = MockContributedByUserProductsStorage();
    userContributionsManager = FakeUserContributionsManager();
    newsFeedManager = FakeNewsFeedManager();

    await TestDiRegistry.register((r) async {
      mapTestsCommons = MapPageModesTestCommons();
      await mapTestsCommons.setUpImpl(r);
      shopsManager = mapTestsCommons.shopsManager;

      r.register<ViewedProductsStorage>(viewedProductsStorage);
      r.register<ContributedByUserProductsStorage>(
          contributedByUserProductsStorage);
      r.register<UserContributionsManager>(userContributionsManager);
      r.register<NewsFeedManager>(newsFeedManager);
    });

    when(contributedByUserProductsStorage.getProducts()).thenReturn(const []);
  });

  Future<void> forceMapIdleState(WidgetTester tester) async {
    final mapPage = find.byType(MapPage).evaluate().first.widget as MapPage;
    mapPage.onMapIdleForTesting();
    await tester.pumpAndSettle();
  }

  Widget currentPage() {
    final stack = find
        .byKey(const Key('main_pages_stack'))
        .evaluate()
        .first
        .widget as IndexedStack;
    return stack.children[stack.index!];
  }

  testWidgets('plus button: add a product', (WidgetTester tester) async {
    final context = await tester.superPump(const MainPage());

    // Force switch from the barcodes page
    await tester.superTap(find.byKey(const Key('bottom_bar_map')));
    expect(
        currentPage().key, isNot(equals(const Key('main_barcode_scan_page'))));

    // Add FAB
    await tester.superTap(find.byKey(const Key('bottom_bar_plus_fab')));
    // Add a product
    await tester.superTap(find.text(context.strings.main_page_add_product));
    expect(currentPage().key, equals(const Key('main_barcode_scan_page')));

    // Scan the barcode
    final scanPage = currentPage() as BarcodeScanPage;
    scanPage.newScanDataForTesting(
        qr.Barcode('4606038069239', qr.BarcodeFormat.unknown, []));
    await tester.pumpAndSettle();

    // Ensure the product is not found
    expect(find.text(context.strings.barcode_scan_page_product_not_found),
        findsOneWidget);

    // Start product's addition
    expect(find.byType(InitProductPage), findsNothing);
    await tester
        .superTap(find.text(context.strings.barcode_scan_page_add_product));
    expect(find.byType(InitProductPage), findsOneWidget);
  });

  testWidgets('plus button: click Add a Product twice in a row',
      (WidgetTester tester) async {
    final context = await tester.superPump(const MainPage());

    // Force switch from the barcodes page
    await tester.superTap(find.byKey(const Key('bottom_bar_map')));
    expect(
        currentPage().key, isNot(equals(const Key('main_barcode_scan_page'))));

    // Click the 'Add a product' button
    await tester.superTap(find.byKey(const Key('bottom_bar_plus_fab')));
    await tester.superTap(find.text(context.strings.main_page_add_product));
    expect(currentPage().key, equals(const Key('main_barcode_scan_page')));

    // No hint is shown yet, because the barcode scan page just opened
    expect(find.text(context.strings.main_page_add_product_hint), findsNothing);

    // Click the 'Add a product' button, again
    await tester.superTap(find.byKey(const Key('bottom_bar_plus_fab')));
    await tester.superTap(find.text(context.strings.main_page_add_product));
    expect(currentPage().key, equals(const Key('main_barcode_scan_page')));

    // Now hint is shown, because the barcode scan page was already opened
    expect(
        find.text(context.strings.main_page_add_product_hint), findsOneWidget);
  });

  testWidgets('plus button: add a store', (WidgetTester tester) async {
    final context = await tester.superPump(
        MainPage(mapControllerForTesting: mapTestsCommons.mapController));
    await forceMapIdleState(tester);

    // Force switch from the map page
    await tester.superTap(find.byKey(const Key('bottom_bar_barcode')));
    expect(currentPage().key, isNot(equals(const Key('main_map_page'))));

    // Add FAB
    await tester.superTap(find.byKey(const Key('bottom_bar_plus_fab')));
    // Add a shop
    await tester.superTap(find.text(context.strings.main_page_add_shop));
    expect(currentPage().key, equals(const Key('main_map_page')));

    // We expect the shops creation mode
    expect(find.text(context.strings.map_page_click_where_new_shop_located),
        findsOneWidget);

    // Now let's create the shop!
    //
    final mapPage = currentPage() as MapPage;

    // Click where the shop's located
    mapPage.onMapClickForTesting(Coord(lat: 10, lon: 20));
    await tester.pumpAndSettle();

    // Open CreateShopPage
    expect(find.byType(CreateShopPage), findsNothing);
    await tester.superTap(find.text(context.strings.global_yes));
    expect(find.byType(CreateShopPage), findsOneWidget);

    // Enter shop's name
    await tester.superEnterText(
        find.byKey(const Key('new_shop_name_input')), 'new shop');

    // Select shop's type
    await tester.superTap(find.byKey(const Key('shop_type_dropdown')));
    await tester.superTapDropDownItem(context.strings.shop_type_supermarket);

    // Finish shop creation!
    shopsManager.verity_createShop_called(times: 0);
    await tester.superTap(find.text(context.strings.global_done));
    shopsManager.verity_createShop_called(times: 1);

    // We expect the shops creation mode to finish
    expect(find.text(context.strings.map_page_click_where_new_shop_located),
        findsNothing);
  });

  testWidgets('plus button: add a store uses ShopsCreationManager',
      (WidgetTester tester) async {
    final mockShopsCreationManager = MockShopsCreationManager();
    when(mockShopsCreationManager.startShopCreation(any, any))
        .thenAnswer((_) async => Ok(null));
    GetIt.I.unregister<ShopsCreationManager>();
    GetIt.I.registerSingleton<ShopsCreationManager>(mockShopsCreationManager);

    final context = await tester.superPump(
        MainPage(mapControllerForTesting: mapTestsCommons.mapController));
    await forceMapIdleState(tester);

    // Add FAB
    await tester.superTap(find.byKey(const Key('bottom_bar_plus_fab')));
    // Add a shop
    await tester.superTap(find.text(context.strings.main_page_add_shop));
    expect(currentPage().key, equals(const Key('main_map_page')));
    // We expect the shops creation mode
    expect(find.text(context.strings.map_page_click_where_new_shop_located),
        findsOneWidget);

    // Now let's create the shop!
    final mapPage = currentPage() as MapPage;
    // Click where the shop's located
    mapPage.onMapClickForTesting(Coord(lat: 10, lon: 20));
    await tester.pumpAndSettle();

    // Verify ShopsCreationManager is used.
    // We want ShopsCreationManager to be used because it checks if there
    // are any stores nearby and asks the user about them.
    verifyZeroInteractions(mockShopsCreationManager);
    await tester.superTap(find.text(context.strings.global_yes));
    verify(mockShopsCreationManager.startShopCreation(any, any));
  });

  testWidgets('plus button: click Add a Store twice in a row',
      (WidgetTester tester) async {
    final context = await tester.superPump(
        MainPage(mapControllerForTesting: mapTestsCommons.mapController));
    await forceMapIdleState(tester);

    // Force switch from the map page
    await tester.superTap(find.byKey(const Key('bottom_bar_barcode')));
    expect(currentPage().key, isNot(equals(const Key('main_map_page'))));

    // Click the "Add a shop" button
    await tester.superTap(find.byKey(const Key('bottom_bar_plus_fab')));
    await tester.superTap(find.text(context.strings.main_page_add_shop));
    expect(currentPage().key, equals(const Key('main_map_page')));

    // We expect the shops creation mode
    expect(find.text(context.strings.map_page_click_where_new_shop_located),
        findsOneWidget);

    // Click the "Add a shop" button, again
    await tester.superTap(find.byKey(const Key('bottom_bar_plus_fab')));
    await tester.superTap(find.text(context.strings.main_page_add_shop));
    expect(currentPage().key, equals(const Key('main_map_page')));

    // We still expect the shops creation mode
    expect(find.text(context.strings.map_page_click_where_new_shop_located),
        findsOneWidget);
  });

  testWidgets('plus button: add a store is canceled when pages are switched',
      (WidgetTester tester) async {
    final context = await tester.superPump(
        MainPage(mapControllerForTesting: mapTestsCommons.mapController));
    await forceMapIdleState(tester);

    // Force switch from the map page
    await tester.superTap(find.byKey(const Key('bottom_bar_barcode')));
    expect(currentPage().key, isNot(equals(const Key('main_map_page'))));

    // Click the "Add a shop" button
    await tester.superTap(find.byKey(const Key('bottom_bar_plus_fab')));
    await tester.superTap(find.text(context.strings.main_page_add_shop));
    expect(currentPage().key, equals(const Key('main_map_page')));

    // We expect the shops creation mode
    expect(find.text(context.strings.map_page_click_where_new_shop_located),
        findsOneWidget);

    // Now let's switch active page from map ...
    await tester.superTap(find.byKey(const Key('bottom_bar_barcode')));
    expect(currentPage().key, equals(const Key('main_barcode_scan_page')));
    expect(currentPage().key, isNot(equals(const Key('main_map_page'))));
    // ... and then back to map
    await tester.superTap(find.byKey(const Key('bottom_bar_map')));
    expect(
        currentPage().key, isNot(equals(const Key('main_barcode_scan_page'))));
    expect(currentPage().key, equals(const Key('main_map_page')));

    // We expect the shops creation mode to be canceled by pages switching
    expect(find.text(context.strings.map_page_click_where_new_shop_located),
        findsNothing);
  });

  testWidgets(
      'plus button: add a store item is not available until shops are loaded',
      (WidgetTester tester) async {
    final context = await tester.superPump(
        MainPage(mapControllerForTesting: mapTestsCommons.mapController));

    // No Add Store button
    await tester.superTap(find.byKey(const Key('bottom_bar_plus_fab')));
    expect(find.text(context.strings.main_page_add_shop), findsNothing);

    // Idle state means the shops are loaded
    await forceMapIdleState(tester);

    // Close the popup
    await tester.superTap(find.byKey(const Key('bottom_bar_map')));

    // Not there is an Add Store button
    await tester.superTap(find.byKey(const Key('bottom_bar_plus_fab')));
    expect(find.text(context.strings.main_page_add_shop), findsWidgets);
  });

  testWidgets('viewed products are not requested implicitly',
      (WidgetTester tester) async {
    await tester.superPump(const MainPage());

    // No interactions when MainPage is created
    verifyZeroInteractions(viewedProductsStorage);

    expect(currentPage().key, isNot(equals(const Key('main_profile_page'))));
    await tester.superTap(find.byKey(const Key('bottom_bar_profile')));
    expect(currentPage().key, equals(const Key('main_profile_page')));

    // Still no interactions even when the Profile page is opened
    // This might change in the future though, if the history products
    // list there would have the first position.
    verifyZeroInteractions(viewedProductsStorage);
  });

  testWidgets('users products are not requested implicitly',
      (WidgetTester tester) async {
    await tester.superPump(const MainPage());

    // No interactions when MainPage is created
    verifyZeroInteractions(contributedByUserProductsStorage);
    expect(userContributionsManager.getContributionsCallsCount_testing(),
        equals(0));

    expect(currentPage().key, isNot(equals(const Key('main_profile_page'))));
    await tester.superTap(find.byKey(const Key('bottom_bar_profile')));
    expect(currentPage().key, equals(const Key('main_profile_page')));

    // Now there's an interaction!
    verify(contributedByUserProductsStorage.getProducts());
    expect(userContributionsManager.getContributionsCallsCount_testing(),
        equals(1));
  });

  testWidgets('news fed is not requested implicitly',
      (WidgetTester tester) async {
    await tester.superPump(const MainPage());

    // No interactions when MainPage is created
    expect(newsFeedManager.obtainedPages_testing(), isEmpty);

    expect(currentPage().key, isNot(equals(const Key('main_news_feed_page'))));
    await tester.superTap(find.byKey(const Key('bottom_bar_news_feed')));
    expect(currentPage().key, equals(const Key('main_news_feed_page')));

    // Now there's an interaction!
    expect(newsFeedManager.obtainedPages_testing(), isNotEmpty);
  });
}
