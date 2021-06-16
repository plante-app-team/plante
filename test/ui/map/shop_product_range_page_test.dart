import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:plante/base/permissions_manager.dart';
import 'package:plante/base/result.dart';
import 'package:plante/model/gender.dart';
import 'package:plante/model/product.dart';
import 'package:plante/model/shop.dart';
import 'package:plante/model/shop_product_range.dart';
import 'package:plante/model/user_params.dart';
import 'package:plante/model/user_params_controller.dart';
import 'package:plante/model/veg_status.dart';
import 'package:plante/model/veg_status_source.dart';
import 'package:plante/model/viewed_products_storage.dart';
import 'package:plante/outside/backend/backend.dart';
import 'package:plante/outside/backend/backend_shop.dart';
import 'package:plante/outside/map/osm_shop.dart';
import 'package:plante/outside/map/shops_manager.dart';
import 'package:plante/outside/products/products_manager.dart';
import 'package:plante/ui/base/components/product_card.dart';
import 'package:plante/ui/base/lang_code_holder.dart';
import 'package:plante/ui/base/ui_utils.dart';
import 'package:plante/ui/map/shop_product_range_page.dart';
import 'package:plante/l10n/strings.dart';
import 'package:plante/ui/photos_taker.dart';
import 'package:plante/ui/product/display_product_page.dart';
import 'package:plante/ui/scan/barcode_scan_page.dart';

import '../../fake_user_params_controller.dart';
import '../../widget_tester_extension.dart';
import 'shop_product_range_page_test.mocks.dart';

@GenerateMocks([Backend, ShopsManager, ProductsManager, PermissionsManager,
  ViewedProductsStorage, PhotosTaker, RouteObserver])
void main() {
  late MockBackend backend;
  late MockShopsManager shopsManager;
  late FakeUserParamsController userParamsController;
  late MockProductsManager productsManager;
  late MockPermissionsManager permissionsManager;

  final aShop = Shop((e) => e
    ..osmShop.replace(OsmShop((e) => e
      ..osmId = '1'
      ..longitude = 10
      ..latitude = 10
      ..name = 'Spar'))
    ..backendShop.replace(BackendShop((e) => e
      ..osmId = '1'
      ..productsCount = 1)));

  final products = [
    Product((v) => v
      ..barcode = '123'
      ..name = 'Apple'
      ..imageFront = Uri.file(File('./test/assets/img.jpg').absolute.path)
      ..vegetarianStatus = VegStatus.possible
      ..vegetarianStatusSource = VegStatusSource.open_food_facts
      ..veganStatus = VegStatus.possible
      ..veganStatusSource = VegStatusSource.open_food_facts
      ..imageIngredients = Uri.file(File('./test/assets/img.jpg').absolute.path)
      ..ingredientsText = 'Water, salt, sugar'),
    Product((v) => v
      ..barcode = '124'
      ..name = 'Pineapple'
      ..imageFront = Uri.file(File('./test/assets/img.jpg').absolute.path)
      ..vegetarianStatus = VegStatus.positive
      ..vegetarianStatusSource = VegStatusSource.open_food_facts
      ..veganStatus = VegStatus.positive
      ..veganStatusSource = VegStatusSource.open_food_facts
      ..imageIngredients = Uri.file(File('./test/assets/img.jpg').absolute.path)
      ..ingredientsText = 'Water, salt, sugar'),
  ];
  final productsLastSeen = {
    products[0]: DateTime(2011, 1, 1),
    products[1]: DateTime(2012, 2, 2),
  };
  final productsLastSeenSecs = productsLastSeen.map((key, value) =>
      MapEntry(key.barcode, (value.millisecondsSinceEpoch / 1000).round()));
  final range = ShopProductRange((e) => e
    ..shop.replace(aShop)
    ..products.addAll(products)
    ..productsLastSeenSecsUtc.addAll(productsLastSeenSecs));

  setUp(() async {
    await GetIt.I.reset();

    backend = MockBackend();
    GetIt.I.registerSingleton<Backend>(backend);
    shopsManager = MockShopsManager();
    GetIt.I.registerSingleton<ShopsManager>(shopsManager);
    userParamsController = FakeUserParamsController();
    GetIt.I.registerSingleton<UserParamsController>(userParamsController);
    productsManager = MockProductsManager();
    GetIt.I.registerSingleton<ProductsManager>(productsManager);
    permissionsManager = MockPermissionsManager();
    GetIt.I.registerSingleton<PermissionsManager>(permissionsManager);
    GetIt.I.registerSingleton<LangCodeHolder>(LangCodeHolder.inited('en'));
    GetIt.I.registerSingleton<ViewedProductsStorage>(MockViewedProductsStorage());
    GetIt.I.registerSingleton<RouteObserver<ModalRoute>>(MockRouteObserver());

    final photosTaker = MockPhotosTaker();
    GetIt.I.registerSingleton<PhotosTaker>(photosTaker);
    when(photosTaker.retrieveLostPhoto()).thenAnswer((_) async => null);

    final params = UserParams((v) => v
      ..name = 'Bob'
      ..genderStr = Gender.FEMALE.name
      ..eatsMilk = false
      ..eatsEggs = false
      ..eatsHoney = false);
    await userParamsController.setUserParams(params);

    when(shopsManager.fetchShopProductRange(any)).thenAnswer((_) async => Ok(range));
    when(permissionsManager.status(any)).thenAnswer((_) async => PermissionState.granted);
    when(backend.productPresenceVote(any, any, any)).thenAnswer((_) async =>
        Ok(None()));
    when(productsManager.createUpdateProduct(any, any)).thenAnswer(
            (invoc) async => Ok(invoc.positionalArguments[0] as Product));
  });

  testWidgets('shop name in title', (WidgetTester tester) async {
    final widget = ShopProductRangePage.createForTesting(aShop);
    await tester.superPump(widget);
    expect(find.text(aShop.name), findsOneWidget);
  });

  testWidgets('close screen button', (WidgetTester tester) async {
    final widget = ShopProductRangePage.createForTesting(aShop);
    await tester.superPump(widget);

    expect(find.byType(ShopProductRangePage), findsOneWidget);
    await tester.tap(find.byKey(const Key('close_button')));
    await tester.pumpAndSettle();
    expect(find.byType(ShopProductRangePage), findsNothing);
  });

  testWidgets('add product behaviour', (WidgetTester tester) async {
    final widget = ShopProductRangePage.createForTesting(aShop);
    final context = await tester.superPump(widget);
    await tester.pumpAndSettle();

    expect(find.byType(BarcodeScanPage), findsNothing);
    await tester.tap(find.text(
        context.strings.shop_product_range_page_add_product));
    await tester.pumpAndSettle();
    expect(find.byType(BarcodeScanPage), findsOneWidget);

    final scanPage = find.byType(BarcodeScanPage)
        .evaluate().first.widget as BarcodeScanPage;
    expect(scanPage.addProductToShop, equals(aShop));

    // Now close the scan page
    clearInteractions(shopsManager);
    scanPage.closeForTesting();
    await tester.pumpAndSettle();
    // Ensure updated shops are obtained
    verify(shopsManager.fetchShopProductRange(any));
  });

  testWidgets('displayed product range', (WidgetTester tester) async {
    final widget = ShopProductRangePage.createForTesting(aShop);
    final context = await tester.superPump(widget);
    await tester.pumpAndSettle();

    final cards = find.byType(ProductCard)
        .evaluate().map((e) => e.widget).toList();
    for (var i = 0; i < cards.length; ++i) {
      expect(find.descendant(
          of: find.byWidget(cards[i]),
          matching: find.text(products[i].name!)), findsOneWidget);

      final expectedDateStr = dateToStr(
          productsLastSeen[products[i]]!, context);
      final expectedLastSeenStr =
          '${context.strings.shop_product_range_page_product_last_seen_here}'
          '$expectedDateStr';
      expect(find.descendant(
          of: find.byWidget(cards[i]),
          matching: find.text(expectedLastSeenStr)), findsOneWidget);
    }
  });

  testWidgets('click on a product', (WidgetTester tester) async {
    final widget = ShopProductRangePage.createForTesting(aShop);
    await tester.superPump(widget);
    await tester.pumpAndSettle();

    expect(find.byType(DisplayProductPage), findsNothing);
    await tester.tap(find.text(products[0].name!));
    await tester.pumpAndSettle();
    expect(find.byType(DisplayProductPage), findsOneWidget);
  });

  testWidgets('vote for product presence', (WidgetTester tester) async {
    final widget = ShopProductRangePage.createForTesting(aShop);
    final context = await tester.superPump(widget);
    await tester.pumpAndSettle();

    var card = find.byType(ProductCard).evaluate().first.widget;
    final product = products[0];

    // Verify the proper product
    expect(find.descendant(
        of: find.byWidget(card),
        matching: find.text(product.name!)), findsOneWidget);

    // Verify the old date
    final expectedOldDateStr = dateToStr(
        productsLastSeen[product]!, context);
    final expectedOldLastSeenStr =
        '${context.strings.shop_product_range_page_product_last_seen_here}'
        '$expectedOldDateStr';
    expect(find.descendant(
        of: find.byWidget(card),
        matching: find.text(expectedOldLastSeenStr)), findsOneWidget);

    // Tap and verify the vote is sent
    verifyNever(backend.productPresenceVote(any, any, any));
    await tester.tap(find.descendant(
        of: find.byWidget(card),
        matching: find.text(context.strings.global_yes)));
    await tester.pumpAndSettle();
    await tester.tap(find.descendant(
        of: find.byKey(const Key('yes_no_dialog')),
        matching: find.text(context.strings.global_yes)));
    await tester.pumpAndSettle();
    verify(backend.productPresenceVote(product.barcode, aShop.osmId, true));

    // Verify the date is updated
    card = find.byType(ProductCard).evaluate().first.widget;
    // Old date is no more
    expect(find.descendant(
        of: find.byWidget(card),
        matching: find.text(expectedOldLastSeenStr)), findsNothing);
    // New date has come!
    final now = DateTime.now();
    final expectedNewDateStr = dateToStr(now, context);
    final expectedNewLastSeenStr =
        '${context.strings.shop_product_range_page_product_last_seen_here}'
        '$expectedNewDateStr';
    expect(find.descendant(
        of: find.byWidget(card),
        matching: find.text(expectedNewLastSeenStr)), findsOneWidget);
  });

  testWidgets('vote against product presence', (WidgetTester tester) async {
    final widget = ShopProductRangePage.createForTesting(aShop);
    final context = await tester.superPump(widget);
    await tester.pumpAndSettle();

    var card = find.byType(ProductCard).evaluate().first.widget;
    final product = products[0];

    // Verify the proper product
    expect(find.descendant(
        of: find.byWidget(card),
        matching: find.text(product.name!)), findsOneWidget);

    // Verify the old date
    final expectedOldDateStr = dateToStr(
        productsLastSeen[product]!, context);
    final expectedOldLastSeenStr =
        '${context.strings.shop_product_range_page_product_last_seen_here}'
        '$expectedOldDateStr';
    expect(find.descendant(
        of: find.byWidget(card),
        matching: find.text(expectedOldLastSeenStr)), findsOneWidget);

    // Tap and verify the vote is sent
    verifyNever(backend.productPresenceVote(any, any, any));
    await tester.tap(find.descendant(
        of: find.byWidget(card),
        matching: find.text(context.strings.global_no)));
    await tester.pumpAndSettle();
    await tester.tap(find.descendant(
        of: find.byKey(const Key('yes_no_dialog')),
        matching: find.text(context.strings.global_yes)));
    await tester.pumpAndSettle();
    verify(backend.productPresenceVote(product.barcode, aShop.osmId, false));

    // Verify the old date is still in place
    card = find.byType(ProductCard).evaluate().first.widget;
    expect(find.descendant(
        of: find.byWidget(card),
        matching: find.text(expectedOldLastSeenStr)), findsOneWidget);
  });

  testWidgets('no products', (WidgetTester tester) async {
    final range = ShopProductRange((e) => e
      ..shop.replace(aShop)
      ..products.addAll(const []));
    when(shopsManager.fetchShopProductRange(any)).thenAnswer((_) async => Ok(range));

    final widget = ShopProductRangePage.createForTesting(aShop);
    final context = await tester.superPump(widget);
    await tester.pumpAndSettle();

    // No products title
    expect(find.text(
        context.strings.shop_product_range_page_this_shop_has_no_product),
        findsOneWidget);

    // No products at all
    for (final product in products) {
      expect(find.text(product.name!), findsNothing);
    }
  });

  testWidgets('network error', (WidgetTester tester) async {
    when(shopsManager.fetchShopProductRange(any)).thenAnswer((_) async =>
        Err(ShopsManagerError.NETWORK_ERROR));

    final widget = ShopProductRangePage.createForTesting(aShop);
    final context = await tester.superPump(widget);
    await tester.pumpAndSettle();

    // Network error
    expect(find.text(
        context.strings.global_network_error),
        findsOneWidget);
    // No products
    for (final product in products) {
      expect(find.text(product.name!), findsNothing);
    }

    // Try again!
    when(shopsManager.fetchShopProductRange(any)).thenAnswer((_) async =>
        Ok(range));
    clearInteractions(shopsManager);

    await tester.tap(find.text(context.strings.global_try_again));
    await tester.pumpAndSettle();

    // Another request!
    verify(shopsManager.fetchShopProductRange(any));
    // All products!
    for (final product in products) {
      expect(find.text(product.name!), findsOneWidget);
    }
  });

  testWidgets('other error', (WidgetTester tester) async {
    when(shopsManager.fetchShopProductRange(any)).thenAnswer((_) async =>
        Err(ShopsManagerError.OTHER));

    final widget = ShopProductRangePage.createForTesting(aShop);
    final context = await tester.superPump(widget);
    await tester.pumpAndSettle();

    // An error
    expect(find.text(
        context.strings.global_something_went_wrong),
        findsOneWidget);
    // No products
    for (final product in products) {
      expect(find.text(product.name!), findsNothing);
    }
    // No try again button
    expect(find.text(context.strings.global_try_again), findsNothing);
  });

  /// Oh boi, ain't that a very fragile test
  testWidgets('product update after click', (WidgetTester tester) async {
    expect(products[0].veganStatus, equals(VegStatus.possible));

    final widget = ShopProductRangePage.createForTesting(aShop);
    final context = await tester.superPump(widget);
    await tester.pumpAndSettle();

    var card = find.byType(ProductCard).evaluate().first.widget;
    // Verify the proper product
    expect(find.descendant(
        of: find.byWidget(card),
        matching: find.text(products[0].name!)), findsOneWidget);
    // Verify initial status
    expect(find.descendant(
        of: find.byWidget(card),
        matching: find.text(context.strings.veg_status_displayed_vegan_status_possible)),
        findsOneWidget);

    expect(find.byType(DisplayProductPage), findsNothing);
    await tester.tap(find.text(products[0].name!));
    await tester.pumpAndSettle();
    expect(find.byType(DisplayProductPage), findsOneWidget);

    await tester.tap(find.text(
        context.strings.display_product_page_click_to_help_with_veg_statuses));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('vegan_positive_btn')));
    await tester.pumpAndSettle();
    await tester.drag(find.byKey(const Key('content')), const Offset(0, -3000));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('done_btn')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('back_button')));
    await tester.pumpAndSettle();

    card = find.byType(ProductCard).evaluate().first.widget;
    // Verify the proper product
    expect(find.descendant(
        of: find.byWidget(card),
        matching: find.text(products[0].name!)), findsOneWidget);
    // Verify the change
    expect(find.descendant(
        of: find.byWidget(card),
        matching: find.text(context.strings.veg_status_displayed_vegan)),
        findsOneWidget);
  });
}
