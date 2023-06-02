import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_scanner/mobile_scanner.dart' as qr;
import 'package:mockito/mockito.dart';
import 'package:plante/base/permissions_manager.dart';
import 'package:plante/base/result.dart';
import 'package:plante/l10n/strings.dart';
import 'package:plante/lang/user_langs_manager.dart';
import 'package:plante/location/user_location_manager.dart';
import 'package:plante/logging/analytics.dart';
import 'package:plante/model/lang_code.dart';
import 'package:plante/model/product.dart';
import 'package:plante/model/product_lang_slice.dart';
import 'package:plante/model/shop.dart';
import 'package:plante/model/veg_status.dart';
import 'package:plante/model/veg_status_source.dart';
import 'package:plante/outside/backend/backend.dart';
import 'package:plante/outside/backend/backend_shop.dart';
import 'package:plante/outside/backend/product_at_shop_source.dart';
import 'package:plante/outside/map/osm/osm_shop.dart';
import 'package:plante/outside/map/osm/osm_uid.dart';
import 'package:plante/outside/map/shops_manager.dart';
import 'package:plante/products/products_manager.dart';
import 'package:plante/products/products_obtainer.dart';
import 'package:plante/products/viewed_products_storage.dart';
import 'package:plante/ui/photos/photos_taker.dart';
import 'package:plante/ui/product/display_product_page.dart';
import 'package:plante/ui/product/init_product_page.dart';
import 'package:plante/ui/scan/barcode_scan_page.dart';

import '../../common_mocks.mocks.dart';
import '../../test_di_registry.dart';
import '../../widget_tester_extension.dart';
import '../../z_fakes/fake_analytics.dart';
import '../../z_fakes/fake_products_obtainer.dart';
import '../../z_fakes/fake_user_langs_manager.dart';
import '../../z_fakes/fake_user_location_manager.dart';

const _DEFAULT_LANG = LangCode.en;

void main() {
  const validBarcode1 = '4606038069239';
  const validBarcode2 = '1234567890128';
  late MockProductsManager productsManager;
  late FakeProductsObtainer productsObtainer;
  late MockBackend backend;
  late MockRouteObserver<ModalRoute<dynamic>> routesObserver;
  late MockPermissionsManager permissionsManager;
  late MockShopsManager shopsManager;
  late ViewedProductsStorage viewedProductsStorage;
  late FakeAnalytics analytics;

  setUp(() async {
    analytics = FakeAnalytics();
    productsManager = MockProductsManager();
    productsObtainer = FakeProductsObtainer();
    backend = MockBackend();
    routesObserver = MockRouteObserver();
    permissionsManager = MockPermissionsManager();
    shopsManager = MockShopsManager();
    final userLocationManager = FakeUserLocationManager();
    final photosTaker = MockPhotosTaker();
    viewedProductsStorage = ViewedProductsStorage();

    await TestDiRegistry.register((r) {
      r.register<Analytics>(analytics);
      r.register<ProductsManager>(productsManager);
      r.register<ProductsObtainer>(productsObtainer);
      r.register<Backend>(backend);
      r.register<RouteObserver<ModalRoute<dynamic>>>(routesObserver);
      r.register<PermissionsManager>(permissionsManager);
      r.register<ShopsManager>(shopsManager);
      r.register<UserLocationManager>(userLocationManager);
      r.register<PhotosTaker>(photosTaker);
      r.register<UserLangsManager>(FakeUserLangsManager([_DEFAULT_LANG]));
      r.register<ViewedProductsStorage>(viewedProductsStorage);
    });

    when(photosTaker.retrieveLostPhoto(any))
        .thenAnswer((realInvocation) async => null);
    when(backend.sendProductScan(any)).thenAnswer((_) async => Ok(None()));
    when(permissionsManager.status(any))
        .thenAnswer((_) async => PermissionState.granted);
    when(permissionsManager.request(any))
        .thenAnswer((_) async => PermissionState.granted);
    when(permissionsManager.openAppSettings()).thenAnswer((_) async => true);
    when(shopsManager.putProductToShops(any, any, any))
        .thenAnswer((_) async => Ok(None()));
    when(shopsManager.getShopsContainingBarcodes(any, any))
        .thenAnswer((_) async => const {});
    when(shopsManager.fetchShopsByUIDs(any))
        .thenAnswer((_) async => Ok(const {}));
    when(shopsManager.osmShopsCacheExistFor(any)).thenAnswer((_) async => true);
  });

  testWidgets('product found', (WidgetTester tester) async {
    productsObtainer
        .unknownProductsGeneratorSimple = (barcode) => ProductLangSlice((e) => e
      ..lang = _DEFAULT_LANG
      ..barcode = barcode
      ..name = 'Product name'
      ..imageFront = Uri.file('/tmp/asd')
      ..imageIngredients = Uri.file('/tmp/asd')
      ..ingredientsText = 'beans'
      ..veganStatus = VegStatus.positive
      ..veganStatusSource = VegStatusSource.community).buildSingleLangProduct();

    final widget = BarcodeScanPage();
    final context = await tester.superPump(widget);

    expect(find.text('Product name'), findsNothing);
    expect(analytics.wasEventSent('scanned_product_in_user_lang'), isFalse);
    expect(analytics.wasEventSent('scanned_product_in_foreign_lang'), isFalse);
    expect(viewedProductsStorage.getProducts(), isEmpty);

    widget.newScanDataForTesting([_barcode(validBarcode1)]);
    await tester.pumpAndSettle();

    expect(find.text('Product name'), findsOneWidget);
    expect(find.text(context.strings.barcode_scan_page_no_info_in_your_langs),
        findsNothing);
    expect(analytics.wasEventSent('scanned_product_in_user_lang'), isTrue);
    expect(analytics.wasEventSent('scanned_product_in_foreign_lang'), isFalse);
    expect(viewedProductsStorage.getProducts(), isNot(isEmpty));

    expect(find.byType(DisplayProductPage), findsNothing);
    await tester.tap(find.text('Product name'));
    await tester.pumpAndSettle();
    expect(find.byType(DisplayProductPage), findsOneWidget);
  });

  testWidgets('product found in another lang', (WidgetTester tester) async {
    const anotherLang = LangCode.nl;
    expect(anotherLang, isNot(equals(_DEFAULT_LANG)));
    productsObtainer
        .unknownProductsGeneratorSimple = (barcode) => ProductLangSlice((e) => e
      ..lang = anotherLang
      ..barcode = barcode
      ..name = 'Product name'
      ..imageFront = Uri.file('/tmp/asd')
      ..imageIngredients = Uri.file('/tmp/asd')
      ..ingredientsText = 'beans'
      ..veganStatus = VegStatus.positive
      ..veganStatusSource = VegStatusSource.community).buildSingleLangProduct();

    final widget = BarcodeScanPage();
    final context = await tester.superPump(widget);

    expect(find.text('Product name'), findsNothing);
    expect(find.text(context.strings.barcode_scan_page_no_info_in_your_langs),
        findsNothing);
    expect(analytics.wasEventSent('scanned_product_in_user_lang'), isFalse);
    expect(analytics.wasEventSent('scanned_product_in_foreign_lang'), isFalse);
    expect(viewedProductsStorage.getProducts(), isEmpty);

    widget.newScanDataForTesting([_barcode(validBarcode1)]);
    await tester.pumpAndSettle();

    expect(find.text('Product name'), findsOneWidget);
    expect(find.text(context.strings.barcode_scan_page_no_info_in_your_langs),
        findsOneWidget);
    expect(analytics.wasEventSent('scanned_product_in_user_lang'), isFalse);
    expect(analytics.wasEventSent('scanned_product_in_foreign_lang'), isTrue);
    expect(viewedProductsStorage.getProducts(), isNot(isEmpty));

    expect(find.byType(DisplayProductPage), findsNothing);
    await tester.tap(find.text('Product name'));
    await tester.pumpAndSettle();
    expect(find.byType(DisplayProductPage), findsOneWidget);

    await tester.tap(find.byKey(const Key('back_button')));
    await tester.pumpAndSettle();
    expect(find.byType(DisplayProductPage), findsNothing);

    expect(find.byType(InitProductPage), findsNothing);
    expect(analytics.wasEventSent('barcode_scan_page_clicked_add_info_in_lang'),
        isFalse);
    await tester.tap(
        find.text(context.strings.barcode_scan_page_add_info_in_your_langs));
    await tester.pumpAndSettle();
    expect(find.byType(InitProductPage), findsOneWidget);
    expect(analytics.wasEventSent('barcode_scan_page_clicked_add_info_in_lang'),
        isTrue);
  });

  testWidgets('invalid barcode scanned', (WidgetTester tester) async {
    productsObtainer
        .unknownProductsGeneratorSimple = (barcode) => ProductLangSlice((e) => e
      ..lang = _DEFAULT_LANG
      ..barcode = barcode
      ..name = 'Product name'
      ..imageFront = Uri.file('/tmp/asd')
      ..imageIngredients = Uri.file('/tmp/asd')
      ..ingredientsText = 'beans'
      ..veganStatus = VegStatus.positive
      ..veganStatusSource = VegStatusSource.community).buildSingleLangProduct();

    final widget = BarcodeScanPage();
    await tester.superPump(widget);

    widget.newScanDataForTesting([_barcode('invalid barcode!')]);
    await tester.pumpAndSettle();

    expect(find.text('Product name'), findsNothing);
    expect(analytics.wasEventSent('scanned_product_in_user_lang'), isFalse);
    expect(analytics.wasEventSent('scanned_product_in_foreign_lang'), isFalse);
  });

  testWidgets('product not found', (WidgetTester tester) async {
    final widget = BarcodeScanPage();
    final context = await tester.superPump(widget);

    const barcode = validBarcode1;

    expect(find.text(context.strings.barcode_scan_page_product_not_found),
        findsNothing);

    widget.newScanDataForTesting([_barcode(barcode)]);
    await tester.pumpAndSettle();

    expect(find.text(context.strings.barcode_scan_page_product_not_found),
        findsOneWidget);
    expect(viewedProductsStorage.getProducts(), isEmpty);

    expect(find.byType(InitProductPage), findsNothing);
    await tester.tap(find.text(context.strings.barcode_scan_page_add_product));
    await tester.pumpAndSettle();
    expect(find.byType(InitProductPage), findsOneWidget);
  });

  testWidgets('when multiple barcodes are scanned, the first one is used',
      (WidgetTester tester) async {
    productsObtainer
        .unknownProductsGeneratorSimple = (barcode) => ProductLangSlice((e) => e
      ..lang = _DEFAULT_LANG
      ..barcode = barcode
      ..name = 'Product with $barcode'
      ..imageFront = Uri.file('/tmp/asd')
      ..imageIngredients = Uri.file('/tmp/asd')
      ..ingredientsText = 'beans'
      ..veganStatus = VegStatus.positive
      ..veganStatusSource = VegStatusSource.community).buildSingleLangProduct();

    final widget = BarcodeScanPage();
    await tester.superPump(widget);

    final barcode1 = _barcode(validBarcode1);
    final barcode2 = _barcode(validBarcode2);
    widget.newScanDataForTesting([barcode1, barcode2]);
    await tester.pumpAndSettle();

    expect(find.text('Product with ${barcode1.rawValue}'), findsOneWidget);
    expect(find.text('Product with ${barcode2.rawValue}'), findsNothing);
  });

  testWidgets(
      'when multiple barcodes are scanned, the invalid ones are ignored',
      (WidgetTester tester) async {
    productsObtainer
        .unknownProductsGeneratorSimple = (barcode) => ProductLangSlice((e) => e
      ..lang = _DEFAULT_LANG
      ..barcode = barcode
      ..name = 'Product with $barcode'
      ..imageFront = Uri.file('/tmp/asd')
      ..imageIngredients = Uri.file('/tmp/asd')
      ..ingredientsText = 'beans'
      ..veganStatus = VegStatus.positive
      ..veganStatusSource = VegStatusSource.community).buildSingleLangProduct();

    final widget = BarcodeScanPage();
    await tester.superPump(widget);

    final barcode1 = _barcode('INVALID');
    final barcode2 = _barcode(validBarcode2);
    widget.newScanDataForTesting([barcode1, barcode2]);
    await tester.pumpAndSettle();

    expect(find.text('Product with ${barcode1.rawValue}'), findsNothing);
    expect(find.text('Product with ${barcode2.rawValue}'), findsOneWidget);
  });

  testWidgets(
      'when multiple barcodes are scanned, and the product of first is already displayed, second product gets displayed',
      (WidgetTester tester) async {
    productsObtainer
        .unknownProductsGeneratorSimple = (barcode) => ProductLangSlice((e) => e
      ..lang = _DEFAULT_LANG
      ..barcode = barcode
      ..name = 'Product with $barcode'
      ..imageFront = Uri.file('/tmp/asd')
      ..imageIngredients = Uri.file('/tmp/asd')
      ..ingredientsText = 'beans'
      ..veganStatus = VegStatus.positive
      ..veganStatusSource = VegStatusSource.community).buildSingleLangProduct();

    final widget = BarcodeScanPage();
    await tester.superPump(widget);

    final barcode1 = _barcode(validBarcode1);
    final barcode2 = _barcode(validBarcode2);

    // Scan 1
    widget.newScanDataForTesting([barcode1, barcode2]);
    await tester.pumpAndSettle();
    expect(find.text('Product with ${barcode1.rawValue}'), findsOneWidget);
    expect(find.text('Product with ${barcode2.rawValue}'), findsNothing);

    // Scan 2, same barcodes in same order
    widget.newScanDataForTesting([barcode1, barcode2]);
    await tester.pumpAndSettle();
    expect(find.text('Product with ${barcode1.rawValue}'), findsNothing);
    expect(find.text('Product with ${barcode2.rawValue}'), findsOneWidget);
  });

  testWidgets('scan data sent to backend', (WidgetTester tester) async {
    productsObtainer.unknownProductsGeneratorSimple =
        (barcode) => Product((e) => e.barcode = barcode);

    final widget = BarcodeScanPage();
    await tester.superPump(widget);

    verifyNever(backend.sendProductScan(any));
    widget.newScanDataForTesting([_barcode(validBarcode1)]);
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
    productsObtainer.unknownProductsGeneratorSimple =
        (barcode) => ProductLangSlice((e) => e
          ..barcode = barcode
          ..name = 'Product name'
          ..imageFront = Uri.file('/tmp/asd')
          ..imageIngredients = Uri.file('/tmp/asd')
          ..ingredientsText = 'beans'
          ..veganStatus = VegStatus.positive
          ..veganStatusSource = VegStatusSource.community).productForTests();

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
    expect(viewedProductsStorage.getProducts(), isEmpty);

    await tester.tap(find.text(context.strings.global_send));
    await tester.pumpAndSettle();

    expect(find.text('Product name'), findsOneWidget);
    expect(viewedProductsStorage.getProducts(), isNot(isEmpty));
  });

  testWidgets('manual barcode search, but barcode is invalid',
      (WidgetTester tester) async {
    productsObtainer.unknownProductsGeneratorSimple =
        (barcode) => ProductLangSlice((e) => e
          ..barcode = barcode
          ..name = 'Product name'
          ..imageFront = Uri.file('/tmp/asd')
          ..imageIngredients = Uri.file('/tmp/asd')
          ..ingredientsText = 'beans'
          ..veganStatus = VegStatus.positive
          ..veganStatusSource = VegStatusSource.community).productForTests();

    final widget = BarcodeScanPage();
    final context = await tester.superPump(widget);

    expect(find.byKey(const Key('manual_barcode_input')), findsNothing);

    await tester.tap(find.byKey(const Key('input_mode_switch')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('manual_barcode_input')), findsWidgets);
    await tester.enterText(
        find.byKey(const Key('manual_barcode_input')), '460603806923967891234');
    await tester.pumpAndSettle();

    expect(find.text(context.strings.barcode_scan_page_invalid_barcode),
        findsNothing);

    await tester.tap(find.text(context.strings.global_send));
    await tester.pumpAndSettle();

    expect(find.text('Product name'), findsNothing);
    expect(viewedProductsStorage.getProducts(), isEmpty);
    expect(find.text(context.strings.barcode_scan_page_invalid_barcode),
        findsWidgets);
  });

  testWidgets('cancel found product card', (WidgetTester tester) async {
    productsObtainer.unknownProductsGeneratorSimple =
        (barcode) => ProductLangSlice((e) => e
          ..barcode = barcode
          ..name = 'Product name'
          ..imageFront = Uri.file('/tmp/asd')
          ..imageIngredients = Uri.file('/tmp/asd')
          ..ingredientsText = 'beans'
          ..veganStatus = VegStatus.positive
          ..veganStatusSource = VegStatusSource.community).productForTests();

    final widget = BarcodeScanPage();
    await tester.superPump(widget);

    widget.newScanDataForTesting([_barcode(validBarcode1)]);
    await tester.pumpAndSettle();

    expect(find.text('Product name'), findsOneWidget);

    await tester.tap(find.byKey(const Key('card_cancel_btn')));
    await tester.pumpAndSettle();

    expect(find.text('Product name'), findsNothing);
  });

  testWidgets('cancel not found product card', (WidgetTester tester) async {
    final widget = BarcodeScanPage();
    final context = await tester.superPump(widget);

    widget.newScanDataForTesting([_barcode(validBarcode1)]);
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
        ..osmUID = OsmUID.parse('1:1')
        ..longitude = 11
        ..latitude = 11
        ..name = 'Spar'))
      ..backendShop.replace(BackendShop((e) => e
        ..osmUID = OsmUID.parse('1:1')
        ..productsCount = 2)));
    final product = ProductLangSlice((e) => e
      ..barcode = validBarcode1
      ..name = 'Beans can'
      ..imageFront = Uri.file('/tmp/asd')
      ..imageIngredients = Uri.file('/tmp/asd')
      ..ingredientsText = 'beans'
      ..veganStatus = VegStatus.positive
      ..veganStatusSource = VegStatusSource.community).productForTests();
    productsObtainer.addKnownProduct(product);

    final widget = BarcodeScanPage(addProductToShop: shop);
    final context = await tester.superPump(widget);

    final expectedQuestion = context.strings.barcode_scan_page_is_product_sold_q
        .replaceAll('<PRODUCT>', 'Beans can')
        .replaceAll('<SHOP>', shop.name);

    expect(find.text(expectedQuestion), findsNothing);
    widget.newScanDataForTesting([_barcode(validBarcode1)]);
    await tester.pumpAndSettle();
    expect(find.text(expectedQuestion), findsOneWidget);

    expect(find.byType(BarcodeScanPage), findsOneWidget);
    verifyNever(shopsManager.putProductToShops(any, any, any));
    await tester.tap(find.text(context.strings.global_yes));
    await tester.pumpAndSettle();
    // Expecting the page to close
    expect(find.byType(BarcodeScanPage), findsNothing);
    // Expecting the product to be put to the shop
    verify(shopsManager.putProductToShops(
        product, [shop], ProductAtShopSource.MANUAL));
  });

  testWidgets(
      'opened to add a product to shop, existing product, then canceled',
      (WidgetTester tester) async {
    final shop = Shop((e) => e
      ..osmShop.replace(OsmShop((e) => e
        ..osmUID = OsmUID.parse('1:1')
        ..longitude = 11
        ..latitude = 11
        ..name = 'Spar'))
      ..backendShop.replace(BackendShop((e) => e
        ..osmUID = OsmUID.parse('1:1')
        ..productsCount = 2)));
    final product = ProductLangSlice((e) => e
      ..barcode = validBarcode1
      ..name = 'Beans can'
      ..imageFront = Uri.file('/tmp/asd')
      ..imageIngredients = Uri.file('/tmp/asd')
      ..ingredientsText = 'beans'
      ..veganStatus = VegStatus.positive
      ..veganStatusSource = VegStatusSource.community).productForTests();
    productsObtainer.addKnownProduct(product);

    final widget = BarcodeScanPage(addProductToShop: shop);
    final context = await tester.superPump(widget);

    final expectedQuestion = context.strings.barcode_scan_page_is_product_sold_q
        .replaceAll('<PRODUCT>', 'Beans can')
        .replaceAll('<SHOP>', shop.name);

    expect(find.text(expectedQuestion), findsNothing);
    widget.newScanDataForTesting([_barcode(validBarcode1)]);
    await tester.pumpAndSettle();
    expect(find.text(expectedQuestion), findsOneWidget);

    expect(find.byType(BarcodeScanPage), findsOneWidget);
    verifyNever(shopsManager.putProductToShops(any, any, any));
    await tester.tap(find.text(context.strings.global_no));
    await tester.pumpAndSettle();
    // Expecting the page to close
    expect(find.byType(BarcodeScanPage), findsNothing);
    // Expecting the product to be NOT put to the shop
    verifyNever(shopsManager.putProductToShops(any, any, any));
  });

  testWidgets('opened to add a product to shop, new product',
      (WidgetTester tester) async {
    final shop = Shop((e) => e
      ..osmShop.replace(OsmShop((e) => e
        ..osmUID = OsmUID.parse('1:1')
        ..longitude = 11
        ..latitude = 11
        ..name = 'Spar'))
      ..backendShop.replace(BackendShop((e) => e
        ..osmUID = OsmUID.parse('1:1')
        ..productsCount = 2)));

    final widget = BarcodeScanPage(addProductToShop: shop);
    final context = await tester.superPump(widget);

    expect(find.text(context.strings.barcode_scan_page_product_not_found),
        findsNothing);
    widget.newScanDataForTesting([_barcode(validBarcode1)]);
    await tester.pumpAndSettle();
    expect(find.text(context.strings.barcode_scan_page_product_not_found),
        findsOneWidget);

    expect(find.byType(BarcodeScanPage), findsOneWidget);
    expect(find.byType(InitProductPage), findsNothing);
    verifyNever(shopsManager.putProductToShops(any, any, any));
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
    productsObtainer.unknownProductsGeneratorSimple =
        (barcode) => Product((e) => e.barcode = barcode);

    final widget = BarcodeScanPage();
    await tester.superPump(widget);

    analytics.clearEvents();

    widget.newScanDataForTesting([_barcode(validBarcode1)], byCamera: true);

    expect(analytics.allEvents().length, equals(1));
    expect(analytics.sentEventParams('barcode_scan'),
        equals({'barcode': validBarcode1}));
    expect(analytics.wasEventSent('barcode_manual'), isFalse);
  });

  testWidgets('barcode manual input analytics', (WidgetTester tester) async {
    productsObtainer.unknownProductsGeneratorSimple =
        (barcode) => Product((e) => e.barcode = barcode);

    final widget = BarcodeScanPage();
    await tester.superPump(widget);

    analytics.clearEvents();

    widget.newScanDataForTesting([_barcode(validBarcode1)], byCamera: false);

    expect(analytics.allEvents().length, equals(1));
    expect(analytics.sentEventParams('barcode_manual'),
        equals({'barcode': validBarcode1}));
    expect(analytics.wasEventSent('barcode_scan'), isFalse);
  });
}

qr.Barcode _barcode(String barcode) => qr.Barcode(rawValue: barcode);
