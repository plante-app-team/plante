import 'package:built_collection/built_collection.dart';
import 'package:built_value/json_object.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:plante/base/general_error.dart';
import 'package:plante/base/permissions_manager.dart';
import 'package:plante/base/result.dart';
import 'package:plante/l10n/strings.dart';
import 'package:plante/lang/input_products_lang_storage.dart';
import 'package:plante/lang/user_langs_manager.dart';
import 'package:plante/logging/analytics.dart';
import 'package:plante/model/coord.dart';
import 'package:plante/model/lang_code.dart';
import 'package:plante/model/product.dart';
import 'package:plante/model/product_lang_slice.dart';
import 'package:plante/model/shop.dart';
import 'package:plante/model/shop_type.dart';
import 'package:plante/model/user_params.dart';
import 'package:plante/model/user_params_controller.dart';
import 'package:plante/model/veg_status.dart';
import 'package:plante/model/veg_status_source.dart';
import 'package:plante/outside/backend/backend_shop.dart';
import 'package:plante/outside/backend/news/news_feed_manager.dart';
import 'package:plante/outside/backend/news/news_piece.dart';
import 'package:plante/outside/backend/news/news_piece_type.dart';
import 'package:plante/outside/backend/user_reports_maker.dart';
import 'package:plante/outside/map/address_obtainer.dart';
import 'package:plante/outside/map/osm/osm_address.dart';
import 'package:plante/outside/map/osm/osm_element_type.dart';
import 'package:plante/outside/map/osm/osm_shop.dart';
import 'package:plante/outside/map/osm/osm_uid.dart';
import 'package:plante/outside/map/shops_manager.dart';
import 'package:plante/products/products_manager.dart';
import 'package:plante/products/products_obtainer.dart';
import 'package:plante/products/viewed_products_storage.dart';
import 'package:plante/ui/news/news_feed_page.dart';
import 'package:plante/ui/photos/photos_taker.dart';
import 'package:plante/ui/product/display_product_page.dart';

import '../../common_finders_extension.dart';
import '../../common_mocks.mocks.dart';
import '../../widget_tester_extension.dart';
import '../../z_fakes/fake_address_obtainer.dart';
import '../../z_fakes/fake_analytics.dart';
import '../../z_fakes/fake_input_products_lang_storage.dart';
import '../../z_fakes/fake_news_feed_manager.dart';
import '../../z_fakes/fake_products_obtainer.dart';
import '../../z_fakes/fake_shops_manager.dart';
import '../../z_fakes/fake_user_langs_manager.dart';
import '../../z_fakes/fake_user_params_controller.dart';

void main() {
  var lastNewsPieceId = 0;
  var lastShopCoord = 1.0;
  var lastShopID = 0;
  var lastBarcode = 123;
  late FakeNewsFeedManager newsFeedManager;
  late FakeProductsObtainer productsObtainer;
  late FakeShopsManager shopsManager;
  late FakeAddressObtainer addressObtainer;

  setUp(() async {
    await GetIt.I.reset();
    GetIt.I.registerSingleton<Analytics>(FakeAnalytics());

    productsObtainer = FakeProductsObtainer();
    GetIt.I.registerSingleton<ProductsObtainer>(productsObtainer);
    shopsManager = FakeShopsManager();
    GetIt.I.registerSingleton<ShopsManager>(shopsManager);
    newsFeedManager = FakeNewsFeedManager();
    GetIt.I.registerSingleton<NewsFeedManager>(newsFeedManager);
    addressObtainer = FakeAddressObtainer();
    GetIt.I.registerSingleton<AddressObtainer>(addressObtainer);

    GetIt.I.registerSingleton<PermissionsManager>(MockPermissionsManager());
    GetIt.I.registerSingleton<ProductsManager>(MockProductsManager());
    GetIt.I.registerSingleton<PhotosTaker>(MockPhotosTaker());
    GetIt.I.registerSingleton<InputProductsLangStorage>(
        FakeInputProductsLangStorage.fromCode(LangCode.en));
    GetIt.I.registerSingleton<UserLangsManager>(
        FakeUserLangsManager([LangCode.en]));
    GetIt.I
        .registerSingleton<ViewedProductsStorage>(MockViewedProductsStorage());
    GetIt.I.registerSingleton<UserReportsMaker>(MockUserReportsMaker());
    final userParamsController = FakeUserParamsController();
    await userParamsController.setUserParams(UserParams((v) => v
      ..backendClientToken = '123'
      ..backendId = '321'
      ..name = 'Bob'));
    GetIt.I.registerSingleton<UserParamsController>(userParamsController);
  });

  Future<void> scroll(WidgetTester tester, double yDiff) async {
    // NOTE: we pause products retrieval before the scroll down
    // and resume it after.
    // This is needed because we expected new batches of products to be
    // retrieved when the page is scrolled down AND we don't won't
    // this retrieval to be instantaneous (otherwise all batches will be
    // loaded during the first scroll-down).
    productsObtainer.pauseProductsRetrieval();
    for (var i = 0; i < 50; ++i) {
      await tester.drag(
          find.byKey(const Key('news_pieces_list')), Offset(0, yDiff));
      await tester.pump();
    }
    productsObtainer.resumeProductsRetrieval();
    await tester.pumpAndSettle();
  }

  Future<void> scrollDown(WidgetTester tester) async {
    await scroll(tester, -3000);
  }

  Future<void> scrollUp(WidgetTester tester) async {
    await scroll(tester, 3000);
  }

  Product createProduct(String name) {
    lastBarcode += 1;
    final product = ProductLangSlice((e) => e
      ..barcode = '$lastBarcode'
      ..name = name).productForTests();
    productsObtainer.addKnownProduct(product);
    return product;
  }

  Shop createShop(String name, OsmAddress address) {
    lastShopCoord += 0.00001;
    lastShopID += 1;
    final uid = OsmUID(OsmElementType.NODE, '$lastShopID');
    final shop = Shop((e) => e
      ..osmShop.replace(OsmShop((e) => e
        ..osmUID = uid
        ..longitude = lastShopCoord
        ..latitude = lastShopCoord
        ..name = name
        ..type = ShopType.supermarket.osmName
        ..road = address.road))
      ..backendShop.replace(BackendShop((e) => e
        ..osmUID = uid
        ..productsCount = 0)));

    addressObtainer.setResponse(
        Coord(lat: lastShopCoord, lon: lastShopCoord), address);
    shopsManager.cacheShops_testing([shop]);

    return shop;
  }

  void addProductToShop(Product product, Shop shop) {
    newsFeedManager.addNewsPiece_testing(NewsPiece((e) => e
      ..serverId = ++lastNewsPieceId
      ..lat = shop.latitude
      ..lon = shop.longitude
      ..creatorUserId = 'some_user'
      ..creationTimeSecs = 123454
      ..typeCode = NewsPieceType.PRODUCT_AT_SHOP.persistentCode
      ..data = MapBuilder({
        'barcode': JsonObject(product.barcode),
        'shop_uid': JsonObject(shop.osmUID.toString())
      })));
  }

  testWidgets('news opened simple scenario', (WidgetTester tester) async {
    addProductToShop(createProduct('Product 1'),
        createShop('Shop 1', OsmAddress((e) => e.road = 'Lenina')));
    addProductToShop(createProduct('Product 2'),
        createShop('Shop 2', OsmAddress((e) => e.road = 'Seabreeze drive')));

    await tester.superPump(const NewsFeedPage());
    expect(find.text('Product 1'), findsOneWidget);
    expect(find.richTextContaining('Lenina'), findsOneWidget);
    expect(find.text('Product 2'), findsOneWidget);
    expect(find.richTextContaining('Seabreeze drive'), findsOneWidget);
  });

  testWidgets('news are ordered in the way returned by NewsFeedManager',
      (WidgetTester tester) async {
    final product1 = createProduct('Product 1');
    final product2 = createProduct('Product 2');
    final shop = createShop('Shop', OsmAddress((e) => e.road = 'Lenina'));

    addProductToShop(product1, shop);
    addProductToShop(product2, shop);
    await tester.superPump(const NewsFeedPage(key: Key('page 1')));
    var center1 = tester.getCenter(find.text(product1.name!));
    var center2 = tester.getCenter(find.text(product2.name!));
    expect(center1.dy, lessThan(center2.dy));

    newsFeedManager.deleteAllNews_testing();
    addProductToShop(product2, shop);
    addProductToShop(product1, shop);
    await tester.superPump(const NewsFeedPage(key: Key('page 2')));
    center1 = tester.getCenter(find.text(product1.name!));
    center2 = tester.getCenter(find.text(product2.name!));
    expect(center2.dy, lessThan(center1.dy));
  });

  testWidgets('news piece click', (WidgetTester tester) async {
    final product = ProductLangSlice((v) => v
      ..lang = LangCode.ru
      ..barcode = '123'
      ..veganStatus = VegStatus.negative
      ..veganStatusSource = VegStatusSource.moderator
      ..name = 'Product'
      ..brands.add('Brand name')
      ..ingredientsText = 'lemon, water'
      ..imageFront = Uri.file('/tmp/img1.jpg')
      ..imageIngredients = Uri.file('/tmp/img2.jpg')).productForTests();
    productsObtainer.addKnownProduct(product);

    addProductToShop(
        product, createShop('Shop', OsmAddress((e) => e.road = 'Lenina')));

    await tester.superPump(const NewsFeedPage());

    expect(find.byType(DisplayProductPage), findsNothing);
    await tester.superTap(find.text(product.name!));
    expect(find.byType(DisplayProductPage), findsOneWidget);
  });

  testWidgets('news second and third backend pages',
      (WidgetTester tester) async {
    // Prepare 3 pages of products' news
    for (var index = 1; index <= newsFeedManager.pageSizeTesting * 3; ++index) {
      addProductToShop(createProduct('Product $index'),
          createShop('Shop $index', OsmAddress((e) => e.road = 'Lenina')));
    }

    await tester.superPump(const NewsFeedPage());

    await scrollDown(tester);
    expect(find.text('Product ${newsFeedManager.pageSizeTesting}'),
        findsOneWidget);

    await scrollDown(tester);
    expect(find.text('Product ${newsFeedManager.pageSizeTesting * 2}'),
        findsOneWidget);

    await scrollDown(tester);
    expect(find.text('Product ${newsFeedManager.pageSizeTesting * 3}'),
        findsOneWidget);
  });

  testWidgets('first news page load failure, reload',
      (WidgetTester tester) async {
    final product = createProduct('Product 1');
    final shop = createShop('Shop', OsmAddress((e) => e.road = 'Lenina'));
    addProductToShop(product, shop);

    newsFeedManager.setErrorForPage_testing(0, GeneralError.OTHER);

    final context = await tester.superPump(const NewsFeedPage());
    expect(find.text(product.name!), findsNothing);
    expect(
        find.text(context.strings.global_something_went_wrong), findsOneWidget);

    newsFeedManager.setErrorForPage_testing(0, null);
    await tester.superTap(find.text(context.strings.global_try_again));

    expect(find.text(product.name!), findsOneWidget);
    expect(
        find.text(context.strings.global_something_went_wrong), findsNothing);
  });

  testWidgets('second news page load failure', (WidgetTester tester) async {
    // Prepare 2 pages of products' news
    for (var index = 1; index <= newsFeedManager.pageSizeTesting * 2; ++index) {
      addProductToShop(createProduct('Product $index'),
          createShop('Shop $index', OsmAddress((e) => e.road = 'Lenina')));
    }

    // Error for the second page
    newsFeedManager.setErrorForPage_testing(1, GeneralError.OTHER);

    final context = await tester.superPump(const NewsFeedPage());

    await scrollDown(tester);

    // Last product from the first page is present
    expect(find.text('Product ${newsFeedManager.pageSizeTesting}'),
        findsOneWidget);
    // And an error is also present
    expect(
        find.text(context.strings.global_something_went_wrong), findsOneWidget);
    // And the first+last products of the second page are not present
    expect(find.text('Product ${newsFeedManager.pageSizeTesting + 1}'),
        findsNothing);
    expect(find.text('Product ${newsFeedManager.pageSizeTesting * 2}'),
        findsNothing);

    // Remove the error, retry
    newsFeedManager.setErrorForPage_testing(1, null);
    await tester.superTap(find.text(context.strings.global_try_again));

    // No error
    expect(
        find.text(context.strings.global_something_went_wrong), findsNothing);
    // Both last products from pages 0 and 1 are present
    expect(find.text('Product ${newsFeedManager.pageSizeTesting}'),
        findsOneWidget);
    await scrollDown(tester);
    expect(find.text('Product ${newsFeedManager.pageSizeTesting * 2}'),
        findsOneWidget);
  });

  testWidgets('products obtaining failure', (WidgetTester tester) async {
    final product = createProduct('Product 1');
    final shop = createShop('Shop', OsmAddress((e) => e.road = 'Lenina'));
    addProductToShop(product, shop);

    productsObtainer.clearKnownProducts();
    productsObtainer.unknownProductsGenerator =
        (_) => Err(ProductsObtainerError.OTHER);

    final context = await tester.superPump(const NewsFeedPage());
    expect(find.text(product.name!), findsNothing);
    expect(
        find.text(context.strings.global_something_went_wrong), findsOneWidget);

    productsObtainer.addKnownProduct(product);
    await tester.superTap(find.text(context.strings.global_try_again));

    expect(find.text(product.name!), findsOneWidget);
    expect(
        find.text(context.strings.global_something_went_wrong), findsNothing);
  });

  testWidgets('only some products are obtained', (WidgetTester tester) async {
    final product1 = createProduct('Product 1');
    final product2 = createProduct('Product 2');
    final shop = createShop('Shop', OsmAddress((e) => e.road = 'Lenina'));
    addProductToShop(product1, shop);
    addProductToShop(product2, shop);

    productsObtainer.clearKnownProducts();
    productsObtainer.addKnownProduct(product2);

    final context = await tester.superPump(const NewsFeedPage());
    expect(find.text(product1.name!), findsNothing);
    expect(find.text(product2.name!), findsOneWidget);
    expect(
        find.text(context.strings.global_something_went_wrong), findsNothing);
  });

  testWidgets('only some shops are obtained', (WidgetTester tester) async {
    final product1 = createProduct('Product 1');
    final product2 = createProduct('Product 2');
    final shop1 = createShop('Shop1', OsmAddress((e) => e.road = 'Street 1'));
    final shop2 = createShop('Shop2', OsmAddress((e) => e.road = 'Street 2'));
    addProductToShop(product1, shop1);
    addProductToShop(product2, shop2);

    await shopsManager.clearCache();
    shopsManager.cacheShops_testing([shop2]);

    final context = await tester.superPump(const NewsFeedPage());
    expect(find.text(product1.name!), findsNothing);
    expect(find.text(product2.name!), findsOneWidget);
    expect(
        find.text(context.strings.global_something_went_wrong), findsNothing);
  });

  testWidgets('pull to refresh behaviour', (WidgetTester tester) async {
    // Prepare 2 pages of products' news
    for (var index = 1; index <= newsFeedManager.pageSizeTesting * 2; ++index) {
      addProductToShop(createProduct('Product $index'),
          createShop('Shop $index', OsmAddress((e) => e.road = 'Lenina')));
    }

    await tester.superPump(const NewsFeedPage());

    // Both first of page 0 and last product of page 1 are present
    expect(find.text('Product 1'), findsOneWidget);
    await scrollDown(tester);
    await scrollDown(tester);
    expect(find.text('Product ${newsFeedManager.pageSizeTesting * 2}'),
        findsOneWidget);

    // Prepare absolutely new news
    newsFeedManager.deleteAllNews_testing();
    addProductToShop(createProduct('New product 1'),
        createShop('New shop 1', OsmAddress((e) => e.road = 'Lenina')));
    addProductToShop(createProduct('New product 2'),
        createShop('New shop 2', OsmAddress((e) => e.road = 'Lenina')));

    // Pull to refresh
    await scrollUp(tester);
    await scrollUp(tester);

    // New news are visible
    expect(find.text('New product 1'), findsOneWidget);
    expect(find.text('New product 2'), findsOneWidget);

    // Old news are not present, even from the second page
    expect(find.text('Product 1'), findsNothing);
    expect(find.text('Product ${newsFeedManager.pageSizeTesting * 2}'),
        findsNothing);

    // They were not present on the top, they are not present on the bottom
    await scrollDown(tester);
    expect(find.text('Product 1'), findsNothing);
    expect(find.text('Product ${newsFeedManager.pageSizeTesting * 2}'),
        findsNothing);
  });
}
