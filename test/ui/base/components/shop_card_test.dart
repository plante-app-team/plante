import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mockito/mockito.dart';
import 'package:plante/base/permissions_manager.dart';
import 'package:plante/base/result.dart';
import 'package:plante/l10n/strings.dart';
import 'package:plante/lang/sys_lang_code_holder.dart';
import 'package:plante/lang/user_langs_manager.dart';
import 'package:plante/logging/analytics.dart';
import 'package:plante/model/lang_code.dart';
import 'package:plante/model/product.dart';
import 'package:plante/model/product_lang_slice.dart';
import 'package:plante/model/shop.dart';
import 'package:plante/model/shop_product_range.dart';
import 'package:plante/model/user_params.dart';
import 'package:plante/model/user_params_controller.dart';
import 'package:plante/model/viewed_products_storage.dart';
import 'package:plante/outside/backend/backend.dart';
import 'package:plante/outside/backend/backend_shop.dart';
import 'package:plante/outside/map/address_obtainer.dart';
import 'package:plante/outside/map/extra_properties/map_extra_properties_cacher.dart';
import 'package:plante/outside/map/extra_properties/products_at_shops_extra_properties_manager.dart';
import 'package:plante/outside/map/osm/osm_shop.dart';
import 'package:plante/outside/map/osm/osm_short_address.dart';
import 'package:plante/outside/map/osm/osm_uid.dart';
import 'package:plante/outside/map/shops_manager.dart';
import 'package:plante/outside/map/user_address/caching_user_address_pieces_obtainer.dart';
import 'package:plante/outside/off/off_shops_manager.dart';
import 'package:plante/outside/products/products_obtainer.dart';
import 'package:plante/outside/products/suggestions/suggested_products_manager.dart';
import 'package:plante/ui/base/components/address_widget.dart';
import 'package:plante/ui/base/components/shop_card.dart';
import 'package:plante/ui/scan/barcode_scan_page.dart';
import 'package:plante/ui/shop/shop_product_range_page.dart';

import '../../../common_finders_extension.dart';
import '../../../common_mocks.mocks.dart';
import '../../../widget_tester_extension.dart';
import '../../../z_fakes/fake_analytics.dart';
import '../../../z_fakes/fake_caching_user_address_pieces_obtainer.dart';
import '../../../z_fakes/fake_suggested_products_manager.dart';
import '../../../z_fakes/fake_user_langs_manager.dart';
import '../../../z_fakes/fake_user_params_controller.dart';

void main() {
  late MockShopsManager shopsManager;
  late MockOffShopsManager offShopsManager;
  late FakeUserParamsController userParamsController;
  late MockBackend backend;

  final shopWithProduct = Shop((e) => e
    ..osmShop.replace(OsmShop((e) => e
      ..osmUID = OsmUID.parse('1:1')
      ..longitude = 11
      ..latitude = 11
      ..name = 'Spar'))
    ..backendShop.replace(BackendShop((e) => e
      ..osmUID = OsmUID.parse('1:1')
      ..productsCount = 1)));
  final shopEmpty = Shop((e) => e
    ..osmShop.replace(OsmShop((e) => e
      ..osmUID = OsmUID.parse('1:1')
      ..longitude = 11
      ..latitude = 11
      ..name = 'Spar'))
    ..backendShop.replace(BackendShop((e) => e
      ..osmUID = OsmUID.parse('1:1')
      ..productsCount = 0)));
  final product = ProductLangSlice((e) => e
    ..barcode = '123456'
    ..name = 'Product name').productForTests();

  final OsmShortAddress address = OsmShortAddress((e) => e.road = 'Broadway');
  final FutureShortAddress addressFuture = Future.value(Ok(address));

  setUp(() async {
    await GetIt.I.reset();
    GetIt.I.registerSingleton<Analytics>(FakeAnalytics());

    shopsManager = MockShopsManager();
    GetIt.I.registerSingleton<ShopsManager>(shopsManager);
    userParamsController = FakeUserParamsController();
    GetIt.I.registerSingleton<UserParamsController>(userParamsController);
    backend = MockBackend();
    GetIt.I.registerSingleton<Backend>(backend);
    offShopsManager = MockOffShopsManager();
    when(offShopsManager.findOffShopByName(any, any))
        .thenAnswer((_) async => Ok(null));
    GetIt.I.registerSingleton<OffShopsManager>(offShopsManager);
    final addressObtainer = MockAddressObtainer();
    when(addressObtainer.addressOfShop(any))
        .thenAnswer((_) async => Ok(OsmShortAddress.empty));
    GetIt.I.registerSingleton<AddressObtainer>(addressObtainer);

    final params = UserParams((v) => v.name = 'Bob');
    await userParamsController.setUserParams(params);

    GetIt.I.registerSingleton<ProductsObtainer>(MockProductsObtainer());
    GetIt.I
        .registerSingleton<SysLangCodeHolder>(SysLangCodeHolder.inited('ru'));
    GetIt.I.registerSingleton<RouteObserver<ModalRoute>>(MockRouteObserver());

    final permissionsManager = MockPermissionsManager();
    when(permissionsManager.status(any))
        .thenAnswer((_) async => PermissionState.granted);
    GetIt.I.registerSingleton<PermissionsManager>(permissionsManager);
    GetIt.I.registerSingleton<UserLangsManager>(
        FakeUserLangsManager([LangCode.en]));
    GetIt.I.registerSingleton<SuggestedProductsManager>(
        FakeSuggestedProductsManager());
    GetIt.I.registerSingleton<ProductsAtShopsExtraPropertiesManager>(
        ProductsAtShopsExtraPropertiesManager(MapExtraPropertiesCacher()));
    final userAddressObtainer = FakeCachingUserAddressPiecesObtainer();
    GetIt.I.registerSingleton<CachingUserAddressPiecesObtainer>(
        userAddressObtainer);
    GetIt.I.registerSingleton<ViewedProductsStorage>(
        ViewedProductsStorage(loadPersistentProducts: false));
  });

  testWidgets('card for range: card for empty shop',
      (WidgetTester tester) async {
    final shop = shopEmpty;
    final context = await tester.superPump(
        ShopCard.forProductRange(shop: shop, address: addressFuture));

    expect(find.text(shop.name), findsOneWidget);
    expect(find.text(context.strings.shop_card_no_products_listed),
        findsOneWidget);
    expect(find.text(context.strings.shop_card_products_listed), findsNothing);
    expect(
        find.text(context.strings.shop_card_open_shop_products), findsNothing);
    expect(find.text(context.strings.shop_card_add_product), findsOneWidget);
  });

  testWidgets('card for range: card for not empty shop',
      (WidgetTester tester) async {
    final shop = shopWithProduct;
    final context = await tester.superPump(
        ShopCard.forProductRange(shop: shop, address: addressFuture));

    expect(find.text(shop.name), findsOneWidget);
    expect(
        find.text(context.strings.shop_card_no_products_listed), findsNothing);
    expect(
        find.text(context.strings.shop_card_products_listed), findsOneWidget);
    expect(find.text(context.strings.shop_card_open_shop_products),
        findsOneWidget);
    expect(find.text(context.strings.shop_card_add_product), findsNothing);
  });

  testWidgets('card for range: card for empty shop but not empty suggestions',
      (WidgetTester tester) async {
    final shop = shopEmpty;
    final context = await tester.superPump(ShopCard.forProductRange(
        shop: shop, address: addressFuture, suggestedProductsCount: 3));

    expect(find.text(shop.name), findsOneWidget);
    expect(
        find.text(context.strings.shop_card_no_products_listed), findsNothing);
    expect(
        find.text(context.strings.shop_card_products_listed), findsOneWidget);
    expect(find.text(context.strings.shop_card_open_shop_products),
        findsOneWidget);
    expect(find.text(context.strings.shop_card_add_product), findsNothing);
  });

  testWidgets('card for range: open products button click',
      (WidgetTester tester) async {
    final shop = shopWithProduct;

    final range = ShopProductRange((e) => e.shop.replace(shop));
    when(shopsManager.fetchShopProductRange(any))
        .thenAnswer((_) async => Ok(range));

    final context = await tester.superPump(
        ShopCard.forProductRange(shop: shop, address: addressFuture));

    expect(find.byType(ShopProductRangePage), findsNothing);
    await tester.tap(find.text(context.strings.shop_card_open_shop_products));
    await tester.pumpAndSettle();
    expect(find.byType(ShopProductRangePage), findsOneWidget);
  });

  testWidgets('card for range: add product button click',
      (WidgetTester tester) async {
    final shop = shopEmpty;

    final range = ShopProductRange((e) => e.shop.replace(shop));
    when(shopsManager.fetchShopProductRange(any))
        .thenAnswer((_) async => Ok(range));

    final context = await tester.superPump(
        ShopCard.forProductRange(shop: shop, address: addressFuture));

    expect(find.byType(BarcodeScanPage), findsNothing);
    await tester.tap(find.text(context.strings.shop_card_add_product));
    await tester.pumpAndSettle();
    expect(find.byType(BarcodeScanPage), findsOneWidget);

    final scanPage =
        find.byType(BarcodeScanPage).evaluate().first.widget as BarcodeScanPage;
    expect(scanPage.addProductToShop, equals(shop));
  });

  testWidgets('card for product: title for product with name',
      (WidgetTester tester) async {
    final productWithName = ProductLangSlice((e) => e
      ..barcode = '123456'
      ..name = 'Cinnamon bun').productForTests();
    final context = await tester.superPump(ShopCard.askIfProductIsSold(
      product: productWithName,
      shop: shopEmpty,
      address: addressFuture,
      isProductSold: null,
      onIsProductSoldChanged: (_a, _b) {},
    ));

    final String expectedTitle = context.strings.map_page_is_product_sold_q
        .replaceAll('<PRODUCT>', productWithName.name!);
    final String unexpectedTitle =
        context.strings.map_page_is_new_product_sold_q;

    expect(find.text(expectedTitle), findsOneWidget);
    expect(find.text(unexpectedTitle), findsNothing);
  });

  testWidgets('card for product: title for product without name',
      (WidgetTester tester) async {
    final productWithoutName = ProductLangSlice((e) => e
      ..barcode = '123456'
      ..name = null).productForTests();
    final context = await tester.superPump(ShopCard.askIfProductIsSold(
      product: productWithoutName,
      shop: shopEmpty,
      address: addressFuture,
      isProductSold: null,
      onIsProductSoldChanged: (_a, _b) {},
    ));

    final String expectedTitle = context.strings.map_page_is_new_product_sold_q;
    expect(find.text(expectedTitle), findsOneWidget);
  });

  testWidgets('card for product: start with nothing selected',
      (WidgetTester tester) async {
    bool? isProductSold;
    final context = await tester.superPump(ShopCard.askIfProductIsSold(
      product: product,
      shop: shopEmpty,
      address: addressFuture,
      isProductSold: isProductSold,
      onIsProductSoldChanged: (_a, isSold) {
        isProductSold = isSold;
      },
    ));

    await tester.tap(find.text(context.strings.global_yes));
    await tester.pumpAndSettle();
    expect(isProductSold, equals(true));

    await tester.tap(find.text(context.strings.global_no));
    await tester.pumpAndSettle();
    expect(isProductSold, equals(false));
  });

  testWidgets('card for product: start with yes selected',
      (WidgetTester tester) async {
    bool? isProductSold = true;
    final context = await tester.superPump(ShopCard.askIfProductIsSold(
      product: product,
      shop: shopEmpty,
      address: addressFuture,
      isProductSold: isProductSold,
      onIsProductSoldChanged: (_a, isSold) {
        isProductSold = isSold;
      },
    ));

    await tester.tap(find.text(context.strings.global_yes));
    await tester.pumpAndSettle();
    expect(isProductSold, equals(null));

    await tester.tap(find.text(context.strings.global_no));
    await tester.pumpAndSettle();
    expect(isProductSold, equals(false));
  });

  testWidgets('card for product: start with no selected',
      (WidgetTester tester) async {
    bool? isProductSold = false;
    final context = await tester.superPump(ShopCard.askIfProductIsSold(
      product: product,
      shop: shopEmpty,
      address: addressFuture,
      isProductSold: isProductSold,
      onIsProductSoldChanged: (_a, isSold) {
        isProductSold = isSold;
      },
    ));

    await tester.tap(find.text(context.strings.global_yes));
    await tester.pumpAndSettle();
    expect(isProductSold, equals(true));

    await tester.tap(find.text(context.strings.global_no));
    await tester.pumpAndSettle();
    expect(isProductSold, equals(null));
  });

  testWidgets('shop address', (WidgetTester tester) async {
    final loadCompleter = Completer<void>();
    final context = await tester.superPump(ShopCard.forProductRange(
      shop: shopEmpty,
      address: addressFuture,
      loadCompletedCallback: loadCompleter.complete,
    ));

    await tester.awaitableFutureFrom(loadCompleter.future);

    final expectedStr = AddressWidget.addressString(address, false, context)!;
    expect(find.richTextContaining(expectedStr), findsWidgets);
  });

  testWidgets('directions button when callback provided',
      (WidgetTester tester) async {
    var directionsRequested = false;
    final showDirections = (Shop shop) {
      directionsRequested = true;
    };
    await tester.superPump(ShopCard.forProductRange(
      shop: shopEmpty,
      address: addressFuture,
      showDirections: showDirections,
    ));
    expect(directionsRequested, isFalse);
    await tester.superTap(find.byKey(const Key('directions_button')));
    expect(directionsRequested, isTrue);
  });

  testWidgets('directions button when callback not provided',
      (WidgetTester tester) async {
    await tester.superPump(ShopCard.forProductRange(
      shop: shopEmpty,
      address: addressFuture,
      showDirections: null,
    ));
    expect(find.byKey(const Key('directions_button')), findsNothing);
  });

  testWidgets('directions button text when shop has products',
      (WidgetTester tester) async {
    final context = await tester.superPump(ShopCard.forProductRange(
      shop: shopWithProduct,
      address: addressFuture,
      showDirections: (_) {},
    ));
    expect(find.text(context.strings.shop_card_directions), findsOneWidget);
  });

  testWidgets('directions button text when shop has no products',
      (WidgetTester tester) async {
    final context = await tester.superPump(ShopCard.forProductRange(
      shop: shopEmpty,
      address: addressFuture,
      showDirections: (_) {},
    ));
    expect(find.text(context.strings.shop_card_directions), findsNothing);
  });
}
