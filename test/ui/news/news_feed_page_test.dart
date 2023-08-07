import 'dart:io';

import 'package:built_collection/built_collection.dart';
import 'package:built_value/json_object.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:plante/base/coord_utils.dart';
import 'package:plante/base/date_time_extensions.dart';
import 'package:plante/base/general_error.dart';
import 'package:plante/base/result.dart';
import 'package:plante/l10n/strings.dart';
import 'package:plante/model/coord.dart';
import 'package:plante/model/lang_code.dart';
import 'package:plante/model/product.dart';
import 'package:plante/model/product_lang_slice.dart';
import 'package:plante/model/shop.dart';
import 'package:plante/model/shop_type.dart';
import 'package:plante/model/veg_status.dart';
import 'package:plante/model/veg_status_source.dart';
import 'package:plante/outside/backend/backend.dart';
import 'package:plante/outside/backend/backend_shop.dart';
import 'package:plante/outside/backend/cmds/likes_cmds.dart';
import 'package:plante/outside/backend/user_avatar_manager.dart';
import 'package:plante/outside/backend/user_reports_maker.dart';
import 'package:plante/outside/map/address_obtainer.dart';
import 'package:plante/outside/map/osm/osm_address.dart';
import 'package:plante/outside/map/osm/osm_element_type.dart';
import 'package:plante/outside/map/osm/osm_shop.dart';
import 'package:plante/outside/map/osm/osm_uid.dart';
import 'package:plante/outside/map/shops_manager.dart';
import 'package:plante/outside/map/shops_manager_types.dart';
import 'package:plante/outside/news/news_feed_manager.dart';
import 'package:plante/outside/news/news_piece.dart';
import 'package:plante/outside/news/news_piece_type.dart';
import 'package:plante/products/products_obtainer.dart';
import 'package:plante/ui/base/components/uri_image_plante.dart';
import 'package:plante/ui/map/latest_camera_pos_storage.dart';
import 'package:plante/ui/map/map_page/map_page.dart';
import 'package:plante/ui/news/news_feed_page.dart';
import 'package:plante/ui/product/display_product_page.dart';

import '../../stateful_stack_for_testing.dart';
import '../../test_di_registry.dart';
import '../../widget_tester_extension.dart';
import '../../z_fakes/fake_address_obtainer.dart';
import '../../z_fakes/fake_backend.dart';
import '../../z_fakes/fake_news_feed_manager.dart';
import '../../z_fakes/fake_products_obtainer.dart';
import '../../z_fakes/fake_shared_preferences.dart';
import '../../z_fakes/fake_shops_manager.dart';
import '../../z_fakes/fake_user_avatar_manager.dart';
import '../../z_fakes/fake_user_reports_maker.dart';

void main() {
  final imagePath = Uri.file(File('./test/assets/img.jpg').absolute.path);
  final initialPos = Coord(lat: 1, lon: 2);
  var lastNewsPieceId = 0;
  var lastShopCoord = 1.0;
  var lastShopID = 0;
  var lastBarcode = 123;
  late FakeNewsFeedManager newsFeedManager;
  late FakeProductsObtainer productsObtainer;
  late FakeShopsManager shopsManager;
  late FakeAddressObtainer addressObtainer;
  late LatestCameraPosStorage latestCameraPosStorage;
  late FakeUserAvatarManager userAvatarManager;
  late FakeUserReportsMaker userReportsMaker;
  late FakeBackend backend;

  setUp(() async {
    productsObtainer = FakeProductsObtainer();
    shopsManager = FakeShopsManager();
    newsFeedManager = FakeNewsFeedManager();
    addressObtainer = FakeAddressObtainer();
    latestCameraPosStorage =
        LatestCameraPosStorage(FakeSharedPreferences().asHolder());
    userAvatarManager = FakeUserAvatarManager();
    userReportsMaker = FakeUserReportsMaker();

    await TestDiRegistry.register((r) {
      r.register<ProductsObtainer>(productsObtainer);
      r.register<ShopsManager>(shopsManager);
      r.register<NewsFeedManager>(newsFeedManager);
      r.register<AddressObtainer>(addressObtainer);
      r.register<LatestCameraPosStorage>(latestCameraPosStorage);
      r.register<UserAvatarManager>(userAvatarManager);
      r.register<UserReportsMaker>(userReportsMaker);
    });

    await latestCameraPosStorage.set(initialPos);
    backend = GetIt.I.get<Backend>() as FakeBackend;
    backend.setResponse_testing('/$LIKE_PRODUCT_CMD/', '{}');
    backend.setResponse_testing('/$UNLIKE_PRODUCT_CMD', '{}');
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

  Product createProduct(String name, {int likesCount = 0}) {
    lastBarcode += 1;
    final product = ProductLangSlice((e) => e
          ..barcode = '$lastBarcode'
          ..name = name)
        .productForTests()
        .rebuild((e) => e.likesCount = likesCount);
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

  Future<void> addProductToShop(Product product,
      {String creatorUserId = 'some_user',
      String creatorUserName = 'Bob',
      Shop? shop,
      int creationTimeSecs = 123454}) async {
    shop ??=
        createShop('Shop 2', OsmAddress((e) => e.road = 'Seabreeze drive'));
    newsFeedManager.addNewsPiece_testing(NewsPiece((e) => e
      ..serverId = ++lastNewsPieceId
      ..lat = shop!.latitude
      ..lon = shop.longitude
      ..creatorUserId = creatorUserId
      ..creatorUserName = creatorUserName
      ..creatorUserAvatarId = 'avatar_id'
      ..creationTimeSecs = creationTimeSecs
      ..typeCode = NewsPieceType.PRODUCT_AT_SHOP.persistentCode
      ..data = MapBuilder({
        'barcode': JsonObject(product.barcode),
        'shop_uid': JsonObject(shop.osmUID.toString())
      })));

    final barcodesMap = await shopsManager.getBarcodesCacheFor([shop.osmUID]);
    final barcodes = barcodesMap[shop.osmUID]?.toList() ?? [];
    barcodes.add(product.barcode);
    shopsManager.setBarcodesCacheFor_testing(shop, barcodes);
  }

  testWidgets('news opened simple scenario', (WidgetTester tester) async {
    await addProductToShop(createProduct('Product 1'));
    await addProductToShop(createProduct('Product 2'));

    await tester.superPump(const NewsFeedPage());
    expect(find.text('Product 1'), findsOneWidget);
    expect(find.text('Product 2'), findsOneWidget);
  });

  testWidgets('news are ordered in the way returned by NewsFeedManager',
      (WidgetTester tester) async {
    final product1 = createProduct('Product 1');
    final product2 = createProduct('Product 2');

    await addProductToShop(product1);
    await addProductToShop(product2);
    await tester.superPump(const NewsFeedPage(key: Key('page 1')));
    var center1 = tester.getCenter(find.text(product1.name!));
    var center2 = tester.getCenter(find.text(product2.name!));
    expect(center1.dy, lessThan(center2.dy));

    newsFeedManager.deleteAllNews_testing();
    await addProductToShop(product2);
    await addProductToShop(product1);
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

    await addProductToShop(product);

    await tester.superPump(const NewsFeedPage());

    expect(find.byType(DisplayProductPage), findsNothing);
    await tester.superTap(find.text(product.name!));
    expect(find.byType(DisplayProductPage), findsOneWidget);
  });

  testWidgets('news second and third backend pages',
      (WidgetTester tester) async {
    // Prepare 3 pages of products' news
    for (var index = 1; index <= newsFeedManager.pageSizeTesting * 3; ++index) {
      await addProductToShop(createProduct('Product $index'));
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
    await addProductToShop(product);

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
      await addProductToShop(createProduct('Product $index'));
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
    await addProductToShop(product);

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
    await addProductToShop(product1);
    await addProductToShop(product2);

    productsObtainer.clearKnownProducts();
    productsObtainer.addKnownProduct(product2);

    final context = await tester.superPump(const NewsFeedPage());
    expect(find.text(product1.name!), findsNothing);
    expect(find.text(product2.name!), findsOneWidget);
    expect(
        find.text(context.strings.global_something_went_wrong), findsNothing);
  });

  testWidgets('pull to refresh behaviour', (WidgetTester tester) async {
    // Prepare 2 pages of products' news
    for (var index = 1; index <= newsFeedManager.pageSizeTesting * 2; ++index) {
      await addProductToShop(createProduct('Product $index'));
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
    await addProductToShop(createProduct('New product 1'));
    await addProductToShop(createProduct('New product 2'));

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

  testWidgets('news feed is reloaded when the page is reopened after some time',
      (WidgetTester tester) async {
    await addProductToShop(createProduct('Product 1'));

    const newsLifetimeSecs = 1;

    final stack = StatefulStackForTesting(tester: tester, children: const [
      SizedBox(),
      NewsFeedPage(newsLifetimeSecs: newsLifetimeSecs),
    ]);
    await tester.superPump(stack);

    // Original news displayed
    await stack.switchStackToIndex(1);
    expect(find.text('Product 1'), findsOneWidget);

    // News completely changed, ...
    newsFeedManager.deleteAllNews_testing();
    await addProductToShop(createProduct('Product 2'));
    // But original news are still displayed
    expect(find.text('Product 1'), findsOneWidget);
    expect(find.text('Product 2'), findsNothing);

    // Hide and show the page - no changes
    await stack.switchStackToIndex(0);
    await stack.switchStackToIndex(1);
    expect(find.text('Product 1'), findsOneWidget);
    expect(find.text('Product 2'), findsNothing);

    // Wait just a little bit - still no changes
    sleep(const Duration(milliseconds: newsLifetimeSecs * 1000 ~/ 2));
    await tester.pumpAndSettle();
    await stack.switchStackToIndex(0);
    await stack.switchStackToIndex(1);
    expect(find.text('Product 1'), findsOneWidget);
    expect(find.text('Product 2'), findsNothing);

    // Wait [newsLifetimeSecs] - still no
    // changes (because the page is visible)
    sleep(const Duration(seconds: newsLifetimeSecs * 2));
    await tester.pumpAndSettle();
    expect(find.text('Product 1'), findsOneWidget);
    expect(find.text('Product 2'), findsNothing);

    // Hide and show the page - now there's a change
    await stack.switchStackToIndex(0);
    await stack.switchStackToIndex(1);
    expect(find.text('Product 1'), findsNothing);
    expect(find.text('Product 2'), findsOneWidget);
  });

  testWidgets(
      'news feed is reloaded when the page is reopened after map camera moved far enough',
      (WidgetTester tester) async {
    await addProductToShop(createProduct('Product 1'));

    const reloadNewsAfterKms = 1;

    final stack = StatefulStackForTesting(tester: tester, children: const [
      SizedBox(),
      NewsFeedPage(reloadNewsAfterKms: reloadNewsAfterKms),
    ]);
    await tester.superPump(stack);

    // Original news displayed
    await stack.switchStackToIndex(1);
    expect(find.text('Product 1'), findsOneWidget);

    // News completely changed, ...
    newsFeedManager.deleteAllNews_testing();
    await addProductToShop(createProduct('Product 2'));
    // But original news are still displayed
    expect(find.text('Product 1'), findsOneWidget);
    expect(find.text('Product 2'), findsNothing);

    // Hide and show the page - no changes
    await stack.switchStackToIndex(0);
    await stack.switchStackToIndex(1);
    expect(find.text('Product 1'), findsOneWidget);
    expect(find.text('Product 2'), findsNothing);

    // Move camera but not far enough - still no changes
    await latestCameraPosStorage.set(Coord(
      lat: initialPos.lat + kmToGrad(reloadNewsAfterKms / 5),
      lon: initialPos.lon + kmToGrad(reloadNewsAfterKms / 5),
    ));
    await tester.pumpAndSettle();
    await stack.switchStackToIndex(0);
    await stack.switchStackToIndex(1);
    expect(find.text('Product 1'), findsOneWidget);
    expect(find.text('Product 2'), findsNothing);

    // Move camera to more than [reloadNewsAfterKms] - still no
    // changes (because the page is visible)
    await latestCameraPosStorage.set(Coord(
      lat: initialPos.lat + kmToGrad(reloadNewsAfterKms * 5),
      lon: initialPos.lon + kmToGrad(reloadNewsAfterKms * 5),
    ));
    await tester.pumpAndSettle();
    expect(find.text('Product 1'), findsOneWidget);
    expect(find.text('Product 2'), findsNothing);

    // Hide and show the page - now there's a change
    await stack.switchStackToIndex(0);
    await stack.switchStackToIndex(1);
    expect(find.text('Product 1'), findsNothing);
    expect(find.text('Product 2'), findsOneWidget);
  });

  testWidgets('news pieces from with same author and same product are merged',
      (WidgetTester tester) async {
    final product = createProduct('Product 1');
    await addProductToShop(
      product,
      creatorUserId: 'user1',
    );
    await addProductToShop(
      product,
      creatorUserId: 'user1',
    );

    await tester.superPump(const NewsFeedPage());
    expect(find.text('Product 1'), findsOneWidget);
  });

  testWidgets(
      'news pieces from with same product but different authors are not merged',
      (WidgetTester tester) async {
    final product = createProduct('Product 1');
    await addProductToShop(
      product,
      creatorUserId: 'user1',
    );
    await addProductToShop(
      product,
      creatorUserId: 'user2',
    );

    await tester.superPump(const NewsFeedPage());
    expect(find.text('Product 1'), findsNWidgets(2));
  });

  testWidgets('click on product location button', (WidgetTester tester) async {
    final product = createProduct('Product');
    final shop1 =
        createShop('Shop 1', OsmAddress((e) => e.road = 'Seabreeze drive'));
    final shop2 =
        createShop('Shop 2', OsmAddress((e) => e.road = 'Oceanbreeze drive'));
    await addProductToShop(
      product,
      shop: shop1,
    );
    await addProductToShop(
      product,
      shop: shop2,
    );

    await tester.superPump(const NewsFeedPage());

    expect(find.byType(MapPage), findsNothing);
    await tester
        .superTap(find.byKey(const Key('news_piece_product_location_button')));
    expect(find.byType(MapPage), findsOneWidget);

    final mapPage = find.byType(MapPage).evaluate().first.widget as MapPage;
    expect(
        mapPage.requestedMode, equals(MapPageRequestedMode.DEMONSTRATE_SHOPS));
    expect(mapPage.initialSelectedShops, equals([shop1, shop2]));
  });

  testWidgets('click on product location button - network error',
      (WidgetTester tester) async {
    shopsManager.setFetchShopsError_testing(ShopsManagerError.NETWORK_ERROR);

    await addProductToShop(createProduct('Product'));
    final context = await tester.superPump(const NewsFeedPage());

    expect(find.text(context.strings.global_network_error), findsNothing);

    await tester
        .superTap(find.byKey(const Key('news_piece_product_location_button')));

    expect(find.text(context.strings.global_network_error), findsOneWidget);
    expect(find.byType(MapPage), findsNothing);
  });

  testWidgets('news pieces have user names and avatars',
      (WidgetTester tester) async {
    userAvatarManager.setOtherUsersAvatar_testing(imagePath);

    await addProductToShop(createProduct('Product 1'), creatorUserName: 'Bob');
    await addProductToShop(createProduct('Product 2'),
        creatorUserName: 'Kelso');

    await tester.superPump(const NewsFeedPage());
    expect(find.text('Bob'), findsOneWidget);
    expect(find.text('Kelso'), findsOneWidget);
    expect(find.byType(UriImagePlante), findsNWidgets(2));
  });

  testWidgets('news show how long ago they were created',
      (WidgetTester tester) async {
    final now = DateTime.now().toUtc();
    final hourAgo = now.add(const Duration(minutes: -80)).secondsSinceEpoch;
    final dayAgo = now.add(const Duration(hours: -30)).secondsSinceEpoch;
    await addProductToShop(createProduct('Product 1'),
        creationTimeSecs: hourAgo);
    await addProductToShop(createProduct('Product 2'),
        creationTimeSecs: dayAgo);

    await tester.superPump(const NewsFeedPage());
    expect(find.text('1 hour ago'), findsOneWidget);
    expect(find.text('yesterday'), findsOneWidget);
  });

  testWidgets('report a news piece', (WidgetTester tester) async {
    await addProductToShop(createProduct('Product 1'));
    final context = await tester.superPump(const NewsFeedPage());

    await tester.superTap(find.byKey(const Key('news_piece_options_button')));
    await tester.superTap(
        find.text(context.strings.news_feed_page_report_news_piece_btn));

    expect(userReportsMaker.getReports_testing(), isEmpty);

    await tester.superEnterText(
        find.byKey(const Key('report_text')), 'Bad, bad news piece!');
    await tester.superTap(find.text(context.strings.global_send));

    expect(userReportsMaker.getReports_testing().length, equals(1));
  });

  testWidgets('likes', (WidgetTester tester) async {
    const product1InitialLikes = 111;
    const product2InitialLikes = 222;
    final products = [
      createProduct('Product 1', likesCount: product1InitialLikes),
      createProduct('Product 2', likesCount: product2InitialLikes),
    ];
    for (final product in products) {
      await addProductToShop(product);
    }

    await tester.superPump(const NewsFeedPage());

    // Like the first product
    expect(find.text('${product1InitialLikes + 1}'), findsNothing);
    await tester.superTap(find.text('$product1InitialLikes'));
    expect(find.text('${product1InitialLikes + 1}'), findsOneWidget);

    var req = backend.getRequestsMatching_testing('/$LIKE_PRODUCT_CMD/').first;
    expect(req.url.queryParameters['barcode'], equals(products[0].barcode));
    backend.resetRequests_testing();

    // Like the second product
    await scrollDown(tester);
    expect(find.text('${product2InitialLikes + 1}'), findsNothing);
    await tester.superTap(find.text('$product2InitialLikes'));
    expect(find.text('${product2InitialLikes + 1}'), findsOneWidget);
    expect(find.text('$product1InitialLikes'), findsNothing);

    req = backend.getRequestsMatching_testing('/$LIKE_PRODUCT_CMD/').first;
    expect(req.url.queryParameters['barcode'], equals(products[1].barcode));
    backend.resetRequests_testing();

    // Unlike the second product
    await scrollDown(tester);
    expect(find.text('$product2InitialLikes'), findsNothing);
    await tester.superTap(find.text('${product2InitialLikes + 1}'));
    expect(find.text('$product2InitialLikes'), findsOneWidget);

    req = backend.getRequestsMatching_testing('/$UNLIKE_PRODUCT_CMD/').first;
    expect(req.url.queryParameters['barcode'], equals(products[1].barcode));
  });
}
