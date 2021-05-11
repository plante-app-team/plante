import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:plante/base/permissions_manager.dart';
import 'package:plante/base/result.dart';
import 'package:plante/base/settings.dart';
import 'package:plante/l10n/strings.dart';
import 'package:plante/model/product.dart';
import 'package:plante/model/veg_status.dart';
import 'package:plante/outside/backend/backend.dart';
import 'package:plante/outside/products/products_manager.dart';
import 'package:plante/ui/base/lang_code_holder.dart';
import 'package:plante/ui/scan/barcode_scan_page.dart';
import 'package:plante/ui/product/display_product_page.dart';
import 'package:plante/ui/product/init_product_page.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart' as qr;

import '../../fake_settings.dart';
import '../../widget_tester_extension.dart';
import 'barcode_scan_page_test.mocks.dart';

@GenerateMocks([ProductsManager, Backend, RouteObserver, PermissionsManager])
void main() {
  late MockProductsManager productsManager;
  late MockBackend backend;
  late MockRouteObserver<ModalRoute> routesObserver;
  late MockPermissionsManager permissionsManager;

  setUp(() async {
    await GetIt.I.reset();

    GetIt.I.registerSingleton<LangCodeHolder>(LangCodeHolder.inited("en"));
    GetIt.I.registerSingleton<Settings>(FakeSettings());
    productsManager = MockProductsManager();
    GetIt.I.registerSingleton<ProductsManager>(productsManager);
    backend = MockBackend();
    GetIt.I.registerSingleton<Backend>(backend);
    routesObserver = MockRouteObserver();
    GetIt.I.registerSingleton<RouteObserver<ModalRoute>>(routesObserver);
    permissionsManager = MockPermissionsManager();
    GetIt.I.registerSingleton<PermissionsManager>(permissionsManager);
    
    when(backend.sendProductScan(any)).thenAnswer((_) async => Ok(None()));
    when(permissionsManager.status(any)).thenAnswer((_) async => PermissionState.granted);
    when(permissionsManager.request(any)).thenAnswer((_) async => PermissionState.granted);
    when(permissionsManager.openAppSettings()).thenAnswer((_) async => true);
  });

  testWidgets("product found", (WidgetTester tester) async {
    when(productsManager.getProduct(any, any)).thenAnswer((invc) async =>
        Ok(Product((e) => e
          ..barcode = invc.positionalArguments[0] as String
          ..name = "Product name"
          ..imageFront = Uri.file("/tmp/asd")
          ..imageIngredients = Uri.file("/tmp/asd")
          ..ingredientsText = "beans"
          ..veganStatus = VegStatus.positive
          ..vegetarianStatus = VegStatus.positive)));

    final widget = BarcodeScanPage();
    final context = await tester.superPump(widget);

    expect(
        find.text(context.strings.barcode_scan_page_point_camera_at_barcode),
        findsOneWidget);
    expect(
        find.text("Product name"),
        findsNothing);
    expect(
        find.text(context.strings.barcode_scan_page_show_product),
        findsNothing);

    widget.newScanDataForTesting(_barcode("12345"));
    await tester.pumpAndSettle();

    expect(
        find.text(context.strings.barcode_scan_page_point_camera_at_barcode),
        findsNothing);
    expect(
        find.text("Product name"),
        findsOneWidget);
    expect(
        find.text(context.strings.barcode_scan_page_show_product),
        findsOneWidget);

    expect(
        find.byType(DisplayProductPage),
        findsNothing);
    await tester.tap(find.text(context.strings.barcode_scan_page_show_product));
    await tester.pumpAndSettle();
    expect(
        find.byType(DisplayProductPage),
        findsOneWidget);
  });

  testWidgets("product not found", (WidgetTester tester) async {
    when(productsManager.getProduct(any, any)).thenAnswer((invc) async => Ok(null));

    final widget = BarcodeScanPage();
    final context = await tester.superPump(widget);

    final barcode = "12345";

    expect(
        find.text(context.strings.barcode_scan_page_point_camera_at_barcode),
        findsOneWidget);
    expect(
        find.text(context.strings.barcode_scan_page_product_not_found),
        findsNothing);

    widget.newScanDataForTesting(_barcode(barcode));
    await tester.pumpAndSettle();

    expect(
        find.text(context.strings.barcode_scan_page_point_camera_at_barcode),
        findsNothing);
    expect(
        find.text(context.strings.barcode_scan_page_product_not_found),
        findsOneWidget);

    expect(
        find.byType(InitProductPage),
        findsNothing);
    await tester.tap(find.text(context.strings.barcode_scan_page_add_product));
    await tester.pumpAndSettle();
    expect(
        find.byType(InitProductPage),
        findsOneWidget);
  });

  testWidgets("scan data sent to backend", (WidgetTester tester) async {
    when(productsManager.getProduct(any, any)).thenAnswer((invc) async =>
        Ok(Product((e) => e
          ..barcode = invc.positionalArguments[0] as String)));

    final widget = BarcodeScanPage();
    await tester.superPump(widget);

    verifyNever(backend.sendProductScan(any));
    widget.newScanDataForTesting(_barcode("12345"));
    await tester.pumpAndSettle();
    verify(backend.sendProductScan(any));
  });

  testWidgets("permission message not shown by default", (WidgetTester tester) async {
    final context = await tester.superPump(BarcodeScanPage());
    expect(
        find.text(context.strings.barcode_scan_page_camera_permission_reasoning),
        findsNothing);
  });

  testWidgets("permission request", (WidgetTester tester) async {
    when(permissionsManager.status(any)).thenAnswer((_) async => PermissionState.denied);
    when(permissionsManager.request(any)).thenAnswer((_) async {
      when(permissionsManager.status(any)).thenAnswer((_) async => PermissionState.granted);
      return PermissionState.granted;
    });

    final context = await tester.superPump(BarcodeScanPage());
    await tester.pumpAndSettle();

    expect(
        find.text(context.strings.barcode_scan_page_camera_permission_reasoning),
        findsOneWidget);
    expect(
        find.text(context.strings.barcode_scan_page_point_camera_at_barcode),
        findsNothing);

    await tester.tap(find.text(context.strings.global_give_permission));
    await tester.pumpAndSettle();

    expect(
        find.text(context.strings.barcode_scan_page_camera_permission_reasoning),
        findsNothing);
    expect(
        find.text(context.strings.barcode_scan_page_point_camera_at_barcode),
        findsOneWidget);
  });

  testWidgets("permission request through settings", (WidgetTester tester) async {
    when(permissionsManager.status(any)).thenAnswer((_) async => PermissionState.permanentlyDenied);

    final context = await tester.superPump(BarcodeScanPage());
    await tester.pumpAndSettle();

    expect(
        find.text(context.strings.barcode_scan_page_camera_permission_reasoning),
        findsNothing);
    expect(
        find.text(context.strings.barcode_scan_page_point_camera_at_barcode),
        findsNothing);
    expect(
        find.text(context.strings.barcode_scan_page_camera_permission_reasoning_settings),
        findsOneWidget);

    verifyNever(permissionsManager.openAppSettings());
    await tester.tap(find.text(context.strings.global_open_app_settings));
    await tester.pumpAndSettle();
    verify(permissionsManager.openAppSettings());
  });
}

qr.Barcode _barcode(String barcode) =>
    qr.Barcode(barcode, qr.BarcodeFormat.unknown, []);
