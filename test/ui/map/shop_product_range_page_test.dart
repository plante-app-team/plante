import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:plante/base/permissions_manager.dart';
import 'package:plante/base/result.dart';
import 'package:plante/model/shop.dart';
import 'package:plante/model/shop_product_range.dart';
import 'package:plante/model/user_params_controller.dart';
import 'package:plante/outside/backend/backend.dart';
import 'package:plante/outside/backend/backend_shop.dart';
import 'package:plante/outside/map/osm_shop.dart';
import 'package:plante/outside/map/shops_manager.dart';
import 'package:plante/outside/products/products_manager.dart';
import 'package:plante/ui/base/lang_code_holder.dart';
import 'package:plante/ui/map/shop_product_range_page.dart';
import 'package:plante/l10n/strings.dart';
import 'package:plante/ui/scan/barcode_scan_page.dart';

import '../../fake_user_params_controller.dart';
import '../../widget_tester_extension.dart';
import 'shop_product_range_page_test.mocks.dart';

@GenerateMocks([Backend, ShopsManager, RouteObserver, ProductsManager,
  PermissionsManager])
void main() {
  late MockBackend backend;
  late MockShopsManager shopsManager;
  late MockRouteObserver<ModalRoute> routesObserver;
  late FakeUserParamsController userParamsController;
  late MockProductsManager productsManager;
  late MockPermissionsManager permissionsManager;

  late RouteAware routeAware;

  final aShop = Shop((e) => e
    ..osmShop.replace(OsmShop((e) => e
      ..osmId = '1'
      ..longitude = 10
      ..latitude = 10
      ..name = 'Spar'))
    ..backendShop.replace(BackendShop((e) => e
      ..osmId = '1'
      ..productsCount = 1)));

  setUp(() async {
    await GetIt.I.reset();

    backend = MockBackend();
    GetIt.I.registerSingleton<Backend>(backend);
    shopsManager = MockShopsManager();
    GetIt.I.registerSingleton<ShopsManager>(shopsManager);
    routesObserver = MockRouteObserver();
    GetIt.I.registerSingleton<RouteObserver<ModalRoute>>(routesObserver);
    userParamsController = FakeUserParamsController();
    GetIt.I.registerSingleton<UserParamsController>(userParamsController);
    productsManager = MockProductsManager();
    GetIt.I.registerSingleton<ProductsManager>(productsManager);
    permissionsManager = MockPermissionsManager();
    GetIt.I.registerSingleton<PermissionsManager>(permissionsManager);
    GetIt.I.registerSingleton<LangCodeHolder>(LangCodeHolder.inited('en'));

    final range = ShopProductRange((e) => e.shop.replace(aShop));
    when(shopsManager.fetchShopProductRange(any)).thenAnswer((_) async => Ok(range));
    when(permissionsManager.status(any)).thenAnswer((_) async => PermissionState.granted);

    when(routesObserver.subscribe(any, any)).thenAnswer((invc) {
      routeAware = invc.positionalArguments[0] as RouteAware;
    });
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

  testWidgets('add product opens the scanner for product addition', (WidgetTester tester) async {
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
  });

  testWidgets('products are fetch again when the page is shown', (WidgetTester tester) async {
    final widget = ShopProductRangePage.createForTesting(aShop);
    await tester.superPump(widget);
    await tester.pumpAndSettle();

    clearInteractions(shopsManager);
    // Notify we're in front
    routeAware.didPopNext();
    // Ensure updated shops are obtained
    verify(shopsManager.fetchShopProductRange(any));
  });
}
