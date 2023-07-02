import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:plante/base/result.dart';
import 'package:plante/l10n/strings.dart';
import 'package:plante/model/product.dart';
import 'package:plante/model/product_lang_slice.dart';
import 'package:plante/model/user_params.dart';
import 'package:plante/model/user_params_controller.dart';
import 'package:plante/model/veg_status.dart';
import 'package:plante/model/veg_status_source.dart';
import 'package:plante/outside/map/shops_manager.dart';
import 'package:plante/products/products_obtainer.dart';
import 'package:plante/products/viewed_products_storage.dart';
import 'package:plante/ui/map/latest_camera_pos_storage.dart';
import 'package:plante/ui/profile/components/products_history_widget.dart';

import '../../../common_mocks.mocks.dart';
import '../../../test_di_registry.dart';
import '../../../widget_tester_extension.dart';
import '../../../z_fakes/fake_shared_preferences.dart';
import '../../../z_fakes/fake_shops_manager.dart';
import '../../../z_fakes/fake_user_params_controller.dart';

void main() {
  late MockProductsObtainer productsObtainer;
  late ViewedProductsStorage viewedProductsStorage;
  late FakeUserParamsController userParamsController;

  setUp(() async {
    await TestDiRegistry.register((r) async {
      productsObtainer = MockProductsObtainer();
      r.register<ProductsObtainer>(productsObtainer);

      viewedProductsStorage = ViewedProductsStorage();
      r.register<ViewedProductsStorage>(viewedProductsStorage);

      userParamsController = FakeUserParamsController();
      final user = UserParams((v) => v
        ..backendClientToken = '123'
        ..backendId = '321'
        ..name = 'Bob');
      await userParamsController.setUserParams(user);
      r.register<UserParamsController>(userParamsController);
      r.register<LatestCameraPosStorage>(
          LatestCameraPosStorage(FakeSharedPreferences().asHolder()));
      r.register<ShopsManager>(FakeShopsManager());
    });
  });

  testWidgets('viewed products shown', (WidgetTester tester) async {
    unawaited(viewedProductsStorage.addProduct(_makeProduct('1')));
    unawaited(viewedProductsStorage.addProduct(_makeProduct('2')));

    await tester.superPump(ProductsHistoryWidget(
        viewedProductsStorage, productsObtainer, userParamsController));

    expect(find.text('Product 1'), findsOneWidget);
    expect(find.text('Product 2'), findsOneWidget);
  });

  testWidgets('viewed product added', (WidgetTester tester) async {
    final context = await tester.superPump(ProductsHistoryWidget(
        viewedProductsStorage, productsObtainer, userParamsController));

    expect(find.text(context.strings.products_history_widget_no_history_hint),
        findsOneWidget);
    expect(find.text('Product 1'), findsNothing);
    expect(find.text('Product 2'), findsNothing);

    unawaited(viewedProductsStorage.addProduct(_makeProduct('1')));
    await tester.pumpAndSettle();

    expect(find.text(context.strings.products_history_widget_no_history_hint),
        findsNothing);
    expect(find.text('Product 1'), findsOneWidget);
    expect(find.text('Product 2'), findsNothing);

    unawaited(viewedProductsStorage.addProduct(_makeProduct('2')));
    await tester.pumpAndSettle();

    expect(find.text(context.strings.products_history_widget_no_history_hint),
        findsNothing);
    expect(find.text('Product 1'), findsOneWidget);
    expect(find.text('Product 2'), findsOneWidget);
  });

  testWidgets('viewed products order and order change',
      (WidgetTester tester) async {
    final p1 = _makeProduct('1');
    final p2 = _makeProduct('2');

    unawaited(viewedProductsStorage.addProduct(p2));
    unawaited(viewedProductsStorage.addProduct(p1));

    await tester.superPump(ProductsHistoryWidget(
        viewedProductsStorage, productsObtainer, userParamsController));

    var product1Pos = tester.getTopLeft(find.text('Product 1'));
    var product2Pos = tester.getTopLeft(find.text('Product 2'));
    expect(product1Pos.dy < product2Pos.dy, isTrue);

    unawaited(viewedProductsStorage.addProduct(p2));
    await tester.pumpAndSettle();

    product1Pos = tester.getTopLeft(find.text('Product 1'));
    product2Pos = tester.getTopLeft(find.text('Product 2'));
    expect(product1Pos.dy < product2Pos.dy, isFalse);
  });

  testWidgets('product click', (WidgetTester tester) async {
    when(productsObtainer.getProduct(any)).thenAnswer((invc) async =>
        Ok(_makeProduct('${invc.positionalArguments[0] as String} updated')));

    final p1 = _makeProduct('1');
    unawaited(viewedProductsStorage.addProduct(p1));

    await tester.superPump(ProductsHistoryWidget(
        viewedProductsStorage, productsObtainer, userParamsController));

    // Opened product is obtained from the manager
    // and display product page is shown
    verifyNever(productsObtainer.getProduct(any));
    expect(find.byKey(const Key('display_product_page')), findsNothing);
    expect(find.text('Product 1 updated'), findsNothing);

    await tester.tap(find.text('Product 1'));
    await tester.pumpAndSettle();

    verify(productsObtainer.getProduct(any));
    expect(find.byKey(const Key('display_product_page')), findsOneWidget);
    expect(find.text('Product 1 updated'), findsOneWidget);
  });
}

Product _makeProduct(String barcode) {
  return ProductLangSlice((e) => e
    ..barcode = barcode
    ..name = 'Product $barcode'
    ..imageFront = Uri.file('/tmp/asd')
    ..imageIngredients = Uri.file('/tmp/asd')
    ..ingredientsText = 'beans'
    ..veganStatus = VegStatus.positive
    ..veganStatusSource = VegStatusSource.community).productForTests();
}
