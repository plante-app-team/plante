import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mockito/mockito.dart';
import 'package:plante/base/permissions_manager.dart';
import 'package:plante/base/result.dart';
import 'package:plante/base/settings.dart';
import 'package:plante/l10n/strings.dart';
import 'package:plante/lang/input_products_lang_storage.dart';
import 'package:plante/lang/user_langs_manager.dart';
import 'package:plante/location/location_controller.dart';
import 'package:plante/logging/analytics.dart';
import 'package:plante/model/lang_code.dart';
import 'package:plante/model/product.dart';
import 'package:plante/model/product_lang_slice.dart';
import 'package:plante/model/shop.dart';
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
import 'package:plante/lang/sys_lang_code_holder.dart';
import 'package:plante/outside/products/products_obtainer.dart';
import 'package:plante/ui/photos_taker.dart';
import 'package:plante/ui/scan/barcode_scan_page.dart';
import 'package:plante/ui/product/display_product_page.dart';
import 'package:plante/ui/product/init_product_page.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart' as qr;

import '../../common_mocks.dart';
import '../../common_mocks.mocks.dart';
import '../../fake_analytics.dart';
import '../../fake_input_products_lang_storage.dart';
import '../../fake_settings.dart';
import '../../fake_user_params_controller.dart';
import '../../widget_tester_extension.dart';

void main() {
  late MockProductsManager productsManager;
  late MockProductsObtainer productsObtainer;
  late MockBackend backend;
  late MockRouteObserver<ModalRoute> routesObserver;
  late MockPermissionsManager permissionsManager;
  late MockShopsManager shopsManager;
  late FakeAnalytics analytics;

  setUp(() async {
    await GetIt.I.reset();
    analytics = FakeAnalytics();
    GetIt.I.registerSingleton<Analytics>(analytics);

    GetIt.I
        .registerSingleton<SysLangCodeHolder>(SysLangCodeHolder.inited('en'));
    GetIt.I.registerSingleton<Settings>(FakeSettings());
    productsManager = MockProductsManager();
    GetIt.I.registerSingleton<ProductsManager>(productsManager);
    productsObtainer = MockProductsObtainer();
    GetIt.I.registerSingleton<ProductsObtainer>(productsObtainer);
    backend = MockBackend();
    GetIt.I.registerSingleton<Backend>(backend);
    routesObserver = MockRouteObserver();
    GetIt.I.registerSingleton<RouteObserver<ModalRoute>>(routesObserver);
    permissionsManager = MockPermissionsManager();
    GetIt.I.registerSingleton<PermissionsManager>(permissionsManager);
    GetIt.I
        .registerSingleton<ViewedProductsStorage>(MockViewedProductsStorage());
    shopsManager = MockShopsManager();
    GetIt.I.registerSingleton<ShopsManager>(shopsManager);
    final locationController = MockLocationController();
    when(locationController.lastKnownPositionInstant()).thenReturn(null);
    when(locationController.lastKnownPosition()).thenAnswer((_) async => null);
    GetIt.I.registerSingleton<LocationController>(locationController);
    final photosTaker = MockPhotosTaker();
    GetIt.I.registerSingleton<PhotosTaker>(photosTaker);
    GetIt.I.registerSingleton<InputProductsLangStorage>(
        FakeInputProductsLangStorage.fromCode(LangCode.en));
    GetIt.I.registerSingleton<UserLangsManager>(
        mockUserLangsManagerWith(LangCode.en));

    when(photosTaker.retrieveLostPhoto())
        .thenAnswer((realInvocation) async => null);

    final userParamsController = FakeUserParamsController();
    final user = UserParams((v) => v
      ..backendClientToken = '123'
      ..backendId = '321'
      ..name = 'Bob'
      ..eatsEggs = false
      ..eatsMilk = false
      ..eatsHoney = false);
    await userParamsController.setUserParams(user);
    GetIt.I.registerSingleton<UserParamsController>(userParamsController);

    when(backend.sendProductScan(any)).thenAnswer((_) async => Ok(None()));
    when(permissionsManager.status(any))
        .thenAnswer((_) async => PermissionState.granted);
    when(permissionsManager.request(any))
        .thenAnswer((_) async => PermissionState.granted);
    when(permissionsManager.openAppSettings()).thenAnswer((_) async => true);
    when(shopsManager.putProductToShops(any, any))
        .thenAnswer((_) async => Ok(None()));
  });

  testWidgets('product found', (WidgetTester tester) async {
    when(productsObtainer.getProduct(any)).thenAnswer((invc) async => Ok(
        ProductLangSlice((e) => e
              ..barcode = invc.positionalArguments[0] as String
              ..name = 'Product name'
              ..imageFront = Uri.file('/tmp/asd')
              ..imageIngredients = Uri.file('/tmp/asd')
              ..ingredientsText = 'beans'
              ..veganStatus = VegStatus.positive
              ..vegetarianStatus = VegStatus.positive
              ..veganStatusSource = VegStatusSource.community
              ..vegetarianStatusSource = VegStatusSource.community)
            .productForTests()));

    final widget = BarcodeScanPage();
    await tester.superPump(widget);

    expect(find.text('Product name'), findsNothing);

    widget.newScanDataForTesting(_barcode('12345'));
    await tester.pumpAndSettle();

    expect(find.text('Product name'), findsOneWidget);

    expect(find.byType(DisplayProductPage), findsNothing);
    await tester.tap(find.text('Product name'));
    await tester.pumpAndSettle();
    expect(find.byType(DisplayProductPage), findsOneWidget);
  });

  testWidgets('product not found', (WidgetTester tester) async {
    when(productsObtainer.getProduct(any)).thenAnswer((invc) async => Ok(null));

    final widget = BarcodeScanPage();
    final context = await tester.superPump(widget);

    const barcode = '12345';

    expect(find.text(context.strings.barcode_scan_page_product_not_found),
        findsNothing);

    widget.newScanDataForTesting(_barcode(barcode));
    await tester.pumpAndSettle();

    expect(find.text(context.strings.barcode_scan_page_product_not_found),
        findsOneWidget);

    expect(find.byType(InitProductPage), findsNothing);
    await tester.tap(find.text(context.strings.barcode_scan_page_add_product));
    await tester.pumpAndSettle();
    expect(find.byType(InitProductPage), findsOneWidget);
  });

  testWidgets('scan data sent to backend', (WidgetTester tester) async {
    when(productsObtainer.getProduct(any)).thenAnswer((invc) async =>
        Ok(Product((e) => e..barcode = invc.positionalArguments[0] as String)));

    final widget = BarcodeScanPage();
    await tester.superPump(widget);

    verifyNever(backend.sendProductScan(any));
    widget.newScanDataForTesting(_barcode('12345'));
    await tester.pumpAndSettle();
    verify(backend.sendProductScan(any));
  });

  testWidgets('permission message not shown by default',
      (WidgetTester tester) async {
    final context = await tester.superPump(BarcodeScanPage());
    expect(
        find.text(
            context.strings.barcode_scan_page_camera_permission_reasoning),
        findsNothing);
  });

  testWidgets('permission request', (WidgetTester tester) async {
    when(permissionsManager.status(any))
        .thenAnswer((_) async => PermissionState.denied);
    when(permissionsManager.request(any)).thenAnswer((_) async {
      when(permissionsManager.status(any))
          .thenAnswer((_) async => PermissionState.granted);
      return PermissionState.granted;
    });

    final context = await tester.superPump(BarcodeScanPage());
    await tester.pumpAndSettle();

    await tester.tap(find.text(context.strings.barcode_scan_page_scan_product));
    await tester.pumpAndSettle();

    expect(
        find.text(
            context.strings.barcode_scan_page_camera_permission_reasoning),
        findsNothing);
  });

  testWidgets('permission request through settings',
      (WidgetTester tester) async {
    when(permissionsManager.status(any))
        .thenAnswer((_) async => PermissionState.permanentlyDenied);

    final context = await tester.superPump(BarcodeScanPage());
    await tester.pumpAndSettle();

    verifyNever(permissionsManager.openAppSettings());
    await tester.tap(find.text(context.strings.barcode_scan_page_scan_product));
    await tester.pumpAndSettle();
    expect(
        find.text(
            context.strings.barcode_scan_page_camera_permission_go_to_settings),
        findsOneWidget);
    await tester.tap(find.text(
        context.strings.barcode_scan_page_camera_permission_go_to_settings));
    await tester.pumpAndSettle();
    verify(permissionsManager.openAppSettings());

    // Second request will be granted
    when(permissionsManager.request(PermissionKind.CAMERA))
        .thenAnswer((_) async {
      when(permissionsManager.status(PermissionKind.CAMERA))
          .thenAnswer((_) async => PermissionState.granted);
      return PermissionState.granted;
    });

    // Second request
    await tester.tap(find.text(context.strings.barcode_scan_page_scan_product));
    await tester.pumpAndSettle();
    verify(permissionsManager.status(PermissionKind.CAMERA));
  });

  testWidgets(
      'permission request through settings not shown when '
      'manual barcode search enabled', (WidgetTester tester) async {
    when(permissionsManager.status(any))
        .thenAnswer((_) async => PermissionState.permanentlyDenied);

    final context = await tester.superPump(BarcodeScanPage());
    await tester.pumpAndSettle();

    expect(find.text(context.strings.barcode_scan_page_scan_product),
        findsOneWidget);

    await tester.tap(find.byKey(const Key('input_mode_switch')));
    await tester.pumpAndSettle();

    expect(find.text(context.strings.barcode_scan_page_scan_product),
        findsNothing);
  });

  testWidgets('manual barcode search', (WidgetTester tester) async {
    when(productsObtainer.getProduct(any)).thenAnswer((invc) async => Ok(
        ProductLangSlice((e) => e
              ..barcode = invc.positionalArguments[0] as String
              ..name = 'Product name'
              ..imageFront = Uri.file('/tmp/asd')
              ..imageIngredients = Uri.file('/tmp/asd')
              ..ingredientsText = 'beans'
              ..veganStatus = VegStatus.positive
              ..vegetarianStatus = VegStatus.positive
              ..veganStatusSource = VegStatusSource.community
              ..vegetarianStatusSource = VegStatusSource.community)
            .productForTests()));

    final widget = BarcodeScanPage();
    final context = await tester.superPump(widget);

    expect(find.byKey(const Key('manual_barcode_input')), findsNothing);

    await tester.tap(find.byKey(const Key('input_mode_switch')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('manual_barcode_input')), findsWidgets);
    await tester.enterText(
        find.byKey(const Key('manual_barcode_input')), '4000417025005');
    await tester.pumpAndSettle();

    expect(find.text('Product name'), findsNothing);

    await tester.tap(find.text(context.strings.global_send));
    await tester.pumpAndSettle();

    expect(find.text('Product name'), findsOneWidget);
  });

  testWidgets('manual barcode search, but barcode is invalid',
      (WidgetTester tester) async {
    when(productsObtainer.getProduct(any)).thenAnswer((invc) async => Ok(
        ProductLangSlice((e) => e
              ..barcode = invc.positionalArguments[0] as String
              ..name = 'Product name'
              ..imageFront = Uri.file('/tmp/asd')
              ..imageIngredients = Uri.file('/tmp/asd')
              ..ingredientsText = 'beans'
              ..veganStatus = VegStatus.positive
              ..vegetarianStatus = VegStatus.positive
              ..veganStatusSource = VegStatusSource.community
              ..vegetarianStatusSource = VegStatusSource.community)
            .productForTests()));

    final widget = BarcodeScanPage();
    final context = await tester.superPump(widget);

    expect(find.byKey(const Key('manual_barcode_input')), findsNothing);

    await tester.tap(find.byKey(const Key('input_mode_switch')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('manual_barcode_input')), findsWidgets);
    await tester.enterText(
        find.byKey(const Key('manual_barcode_input')), '1234567891234');
    await tester.pumpAndSettle();

    expect(find.text(context.strings.barcode_scan_page_invalid_barcode),
        findsNothing);

    await tester.tap(find.text(context.strings.global_send));
    await tester.pumpAndSettle();

    expect(find.text('Product name'), findsNothing);
    expect(find.text(context.strings.barcode_scan_page_invalid_barcode),
        findsWidgets);
  });

  testWidgets('cancel found product card', (WidgetTester tester) async {
    when(productsObtainer.getProduct(any)).thenAnswer((invc) async => Ok(
        ProductLangSlice((e) => e
              ..barcode = invc.positionalArguments[0] as String
              ..name = 'Product name'
              ..imageFront = Uri.file('/tmp/asd')
              ..imageIngredients = Uri.file('/tmp/asd')
              ..ingredientsText = 'beans'
              ..veganStatus = VegStatus.positive
              ..vegetarianStatus = VegStatus.positive
              ..veganStatusSource = VegStatusSource.community
              ..vegetarianStatusSource = VegStatusSource.community)
            .productForTests()));

    final widget = BarcodeScanPage();
    await tester.superPump(widget);

    widget.newScanDataForTesting(_barcode('12345'));
    await tester.pumpAndSettle();

    expect(find.text('Product name'), findsOneWidget);

    await tester.tap(find.byKey(const Key('card_cancel_btn')));
    await tester.pumpAndSettle();

    expect(find.text('Product name'), findsNothing);
  });

  testWidgets('cancel not found product card', (WidgetTester tester) async {
    when(productsObtainer.getProduct(any)).thenAnswer((invc) async => Ok(null));

    final widget = BarcodeScanPage();
    final context = await tester.superPump(widget);

    const barcode = '12345';

    widget.newScanDataForTesting(_barcode(barcode));
    await tester.pumpAndSettle();

    expect(find.text(context.strings.barcode_scan_page_product_not_found),
        findsOneWidget);

    await tester.tap(find.byKey(const Key('card_cancel_btn')));
    await tester.pumpAndSettle();

    expect(find.text(context.strings.barcode_scan_page_product_not_found),
        findsNothing);
  });

  testWidgets('opened to add a product to shop, existing product',
      (WidgetTester tester) async {
    final shop = Shop((e) => e
      ..osmShop.replace(OsmShop((e) => e
        ..osmId = '1'
        ..longitude = 11
        ..latitude = 11
        ..name = 'Spar'))
      ..backendShop.replace(BackendShop((e) => e
        ..osmId = '1'
        ..productsCount = 2)));
    final product = ProductLangSlice((e) => e
      ..barcode = '12345'
      ..name = 'Beans can'
      ..imageFront = Uri.file('/tmp/asd')
      ..imageIngredients = Uri.file('/tmp/asd')
      ..ingredientsText = 'beans'
      ..veganStatus = VegStatus.positive
      ..vegetarianStatus = VegStatus.positive
      ..veganStatusSource = VegStatusSource.community
      ..vegetarianStatusSource = VegStatusSource.community).productForTests();
    when(productsObtainer.getProduct(any)).thenAnswer((_) async => Ok(product));

    final widget = BarcodeScanPage(addProductToShop: shop);
    final context = await tester.superPump(widget);

    final expectedQuestion = context.strings.barcode_scan_page_is_product_sold_q
        .replaceAll('<PRODUCT>', 'Beans can')
        .replaceAll('<SHOP>', shop.name);

    expect(find.text(expectedQuestion), findsNothing);
    widget.newScanDataForTesting(_barcode('12345'));
    await tester.pumpAndSettle();
    expect(find.text(expectedQuestion), findsOneWidget);

    expect(find.byType(BarcodeScanPage), findsOneWidget);
    verifyNever(shopsManager.putProductToShops(any, any));
    await tester.tap(find.text(context.strings.global_yes));
    await tester.pumpAndSettle();
    // Expecting the page to close
    expect(find.byType(BarcodeScanPage), findsNothing);
    // Expecting the product to be put to the shop
    verify(shopsManager.putProductToShops(product, [shop]));
  });

  testWidgets(
      'opened to add a product to shop, existing product, then canceled',
      (WidgetTester tester) async {
    final shop = Shop((e) => e
      ..osmShop.replace(OsmShop((e) => e
        ..osmId = '1'
        ..longitude = 11
        ..latitude = 11
        ..name = 'Spar'))
      ..backendShop.replace(BackendShop((e) => e
        ..osmId = '1'
        ..productsCount = 2)));
    final product = ProductLangSlice((e) => e
      ..barcode = '12345'
      ..name = 'Beans can'
      ..imageFront = Uri.file('/tmp/asd')
      ..imageIngredients = Uri.file('/tmp/asd')
      ..ingredientsText = 'beans'
      ..veganStatus = VegStatus.positive
      ..vegetarianStatus = VegStatus.positive
      ..veganStatusSource = VegStatusSource.community
      ..vegetarianStatusSource = VegStatusSource.community).productForTests();
    when(productsObtainer.getProduct(any)).thenAnswer((_) async => Ok(product));

    final widget = BarcodeScanPage(addProductToShop: shop);
    final context = await tester.superPump(widget);

    final expectedQuestion = context.strings.barcode_scan_page_is_product_sold_q
        .replaceAll('<PRODUCT>', 'Beans can')
        .replaceAll('<SHOP>', shop.name);

    expect(find.text(expectedQuestion), findsNothing);
    widget.newScanDataForTesting(_barcode('12345'));
    await tester.pumpAndSettle();
    expect(find.text(expectedQuestion), findsOneWidget);

    expect(find.byType(BarcodeScanPage), findsOneWidget);
    verifyNever(shopsManager.putProductToShops(any, any));
    await tester.tap(find.text(context.strings.global_no));
    await tester.pumpAndSettle();
    // Expecting the page to close
    expect(find.byType(BarcodeScanPage), findsNothing);
    // Expecting the product to be NOT put to the shop
    verifyNever(shopsManager.putProductToShops(any, any));
  });

  testWidgets('opened to add a product to shop, new product',
      (WidgetTester tester) async {
    final shop = Shop((e) => e
      ..osmShop.replace(OsmShop((e) => e
        ..osmId = '1'
        ..longitude = 11
        ..latitude = 11
        ..name = 'Spar'))
      ..backendShop.replace(BackendShop((e) => e
        ..osmId = '1'
        ..productsCount = 2)));
    when(productsObtainer.getProduct(any)).thenAnswer((_) async => Ok(null));

    final widget = BarcodeScanPage(addProductToShop: shop);
    final context = await tester.superPump(widget);

    expect(find.text(context.strings.barcode_scan_page_product_not_found),
        findsNothing);
    widget.newScanDataForTesting(_barcode('12345'));
    await tester.pumpAndSettle();
    expect(find.text(context.strings.barcode_scan_page_product_not_found),
        findsOneWidget);

    expect(find.byType(BarcodeScanPage), findsOneWidget);
    expect(find.byType(InitProductPage), findsNothing);
    verifyNever(shopsManager.putProductToShops(any, any));
    await tester.tap(find.text(context.strings.barcode_scan_page_add_product));
    await tester.pumpAndSettle();
    // Expecting the page to close
    expect(find.byType(BarcodeScanPage), findsNothing);
    // Expecting product addition to be started
    expect(find.byType(InitProductPage), findsOneWidget);

    final initProductPage =
        find.byType(InitProductPage).evaluate().first.widget as InitProductPage;
    expect(initProductPage.initialShops, equals([shop]));
  });

  testWidgets('barcode scan analytics', (WidgetTester tester) async {
    when(productsObtainer.getProduct(any)).thenAnswer((invc) async =>
        Ok(Product((e) => e..barcode = invc.positionalArguments[0] as String)));

    final widget = BarcodeScanPage();
    await tester.superPump(widget);

    analytics.clearEvents();

    widget.newScanDataForTesting(_barcode('12345'), byCamera: true);

    expect(analytics.allEvents().length, equals(1));
    expect(analytics.sentEventParams('barcode_scan'),
        equals({'barcode': '12345'}));
    expect(analytics.wasEventSent('barcode_manual'), isFalse);
  });

  testWidgets('barcode manual input analytics', (WidgetTester tester) async {
    when(productsObtainer.getProduct(any)).thenAnswer((invc) async =>
        Ok(Product((e) => e..barcode = invc.positionalArguments[0] as String)));

    final widget = BarcodeScanPage();
    await tester.superPump(widget);

    analytics.clearEvents();

    widget.newScanDataForTesting(_barcode('12345'), byCamera: false);

    expect(analytics.allEvents().length, equals(1));
    expect(analytics.sentEventParams('barcode_manual'),
        equals({'barcode': '12345'}));
    expect(analytics.wasEventSent('barcode_scan'), isFalse);
  });
}

qr.Barcode _barcode(String barcode) =>
    qr.Barcode(barcode, qr.BarcodeFormat.unknown, []);
