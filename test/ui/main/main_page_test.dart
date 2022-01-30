import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mockito/mockito.dart';
import 'package:plante/base/result.dart';
import 'package:plante/l10n/strings.dart';
import 'package:plante/lang/input_products_lang_storage.dart';
import 'package:plante/lang/user_langs_manager.dart';
import 'package:plante/model/coord.dart';
import 'package:plante/model/lang_code.dart';
import 'package:plante/model/user_params.dart';
import 'package:plante/model/user_params_controller.dart';
import 'package:plante/model/viewed_products_storage.dart';
import 'package:plante/outside/backend/backend.dart';
import 'package:plante/outside/backend/user_avatar_manager.dart';
import 'package:plante/outside/products/products_manager.dart';
import 'package:plante/outside/products/products_obtainer.dart';
import 'package:plante/ui/main/main_page.dart';
import 'package:plante/ui/map/create_shop_page.dart';
import 'package:plante/ui/map/map_page/map_page.dart';
import 'package:plante/ui/map/map_page/map_page_testing_storage.dart';
import 'package:plante/ui/photos/photos_taker.dart';
import 'package:plante/ui/product/init_product_page.dart';
import 'package:plante/ui/scan/barcode_scan_page.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart' as qr;

import '../../common_mocks.mocks.dart';
import '../../widget_tester_extension.dart';
import '../../z_fakes/fake_input_products_lang_storage.dart';
import '../../z_fakes/fake_products_obtainer.dart';
import '../../z_fakes/fake_shops_manager.dart';
import '../../z_fakes/fake_user_avatar_manager.dart';
import '../../z_fakes/fake_user_langs_manager.dart';
import '../../z_fakes/fake_user_params_controller.dart';
import '../map/map_page/map_page_modes_test_commons.dart';

void main() {
  late MapPageModesTestCommons mapTestsCommons;
  late FakeProductsObtainer productsObtainer;
  late FakeShopsManager shopsManager;
  late MockViewedProductsStorage viewedProductsStorage;

  setUp(() async {
    mapTestsCommons = MapPageModesTestCommons();
    await mapTestsCommons.setUp();
    shopsManager = mapTestsCommons.shopsManager;

    productsObtainer = FakeProductsObtainer();
    GetIt.I.registerSingleton<ProductsObtainer>(productsObtainer);
    final userParamsController = FakeUserParamsController();
    await userParamsController.setUserParams(UserParams());
    GetIt.I.registerSingleton<UserParamsController>(userParamsController);
    GetIt.I.registerSingleton<UserLangsManager>(
        FakeUserLangsManager([LangCode.en]));
    viewedProductsStorage = MockViewedProductsStorage();
    GetIt.I.registerSingleton<ViewedProductsStorage>(viewedProductsStorage);
    GetIt.I.registerSingleton<ProductsManager>(MockProductsManager());

    GetIt.I.registerSingleton<InputProductsLangStorage>(
        FakeInputProductsLangStorage.fromCode(LangCode.en));

    final backend = MockBackend();
    GetIt.I.registerSingleton<Backend>(backend);
    when(backend.sendProductScan(any)).thenAnswer((_) async => Ok(None()));

    final photosTaker = MockPhotosTaker();
    when(photosTaker.retrieveLostPhoto(any)).thenAnswer((_) async => null);
    GetIt.I.registerSingleton<PhotosTaker>(photosTaker);

    GetIt.I.registerSingleton<UserAvatarManager>(
        FakeUserAvatarManager(userParamsController));
  });

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
    final context = await tester.superPump(const MainPage());

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

  testWidgets('plus button: click Add a Store twice in a row',
      (WidgetTester tester) async {
    final context = await tester.superPump(const MainPage());

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
    final context = await tester.superPump(const MainPage());

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
}
