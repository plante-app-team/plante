import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mockito/mockito.dart';
import 'package:plante/base/result.dart';
import 'package:plante/lang/user_langs_manager.dart';
import 'package:plante/logging/analytics.dart';
import 'package:plante/model/lang_code.dart';
import 'package:plante/model/product.dart';
import 'package:plante/model/product_lang_slice.dart';
import 'package:plante/model/user_params.dart';
import 'package:plante/model/user_params_controller.dart';
import 'package:plante/model/veg_status.dart';
import 'package:plante/model/veg_status_source.dart';
import 'package:plante/model/viewed_products_storage.dart';
import 'package:plante/outside/backend/backend.dart';
import 'package:plante/outside/products/products_obtainer.dart';
import 'package:plante/lang/sys_lang_code_holder.dart';
import 'package:plante/ui/scan/viewed_products_history_page.dart';

import '../../common_mocks.mocks.dart';
import '../../fake_analytics.dart';
import '../../fake_user_langs_manager.dart';
import '../../fake_user_params_controller.dart';
import '../../widget_tester_extension.dart';

void main() {
  late MockProductsObtainer productsObtainer;
  late ViewedProductsStorage viewedProductsStorage;

  setUp(() async {
    await GetIt.I.reset();
    GetIt.I.registerSingleton<Analytics>(FakeAnalytics());
    GetIt.I.registerSingleton<Backend>(MockBackend());
    GetIt.I.registerSingleton<UserLangsManager>(
        FakeUserLangsManager([LangCode.en]));

    GetIt.I
        .registerSingleton<SysLangCodeHolder>(SysLangCodeHolder.inited('en'));

    productsObtainer = MockProductsObtainer();
    GetIt.I.registerSingleton<ProductsObtainer>(productsObtainer);

    viewedProductsStorage =
        ViewedProductsStorage(loadPersistentProducts: false);
    GetIt.I.registerSingleton<ViewedProductsStorage>(viewedProductsStorage);

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
  });

  testWidgets('viewed products shown', (WidgetTester tester) async {
    viewedProductsStorage.addProduct(_makeProduct('1'));
    viewedProductsStorage.addProduct(_makeProduct('2'));

    await tester.superPump(const ViewedProductsHistoryPage());

    expect(find.text('Product 1'), findsOneWidget);
    expect(find.text('Product 2'), findsOneWidget);
  });

  testWidgets('viewed product added', (WidgetTester tester) async {
    viewedProductsStorage.addProduct(_makeProduct('1'));

    await tester.superPump(const ViewedProductsHistoryPage());

    expect(find.text('Product 1'), findsOneWidget);
    expect(find.text('Product 2'), findsNothing);

    viewedProductsStorage.addProduct(_makeProduct('2'));
    await tester.pumpAndSettle();

    expect(find.text('Product 1'), findsOneWidget);
    expect(find.text('Product 2'), findsOneWidget);
  });

  testWidgets('viewed products order and order change',
      (WidgetTester tester) async {
    final p1 = _makeProduct('1');
    final p2 = _makeProduct('2');

    viewedProductsStorage.addProduct(p2);
    viewedProductsStorage.addProduct(p1);

    await tester.superPump(const ViewedProductsHistoryPage());

    var product1Pos = tester.getTopLeft(find.text('Product 1'));
    var product2Pos = tester.getTopLeft(find.text('Product 2'));
    expect(product1Pos.dy < product2Pos.dy, isTrue);

    viewedProductsStorage.addProduct(p2);
    await tester.pumpAndSettle();

    product1Pos = tester.getTopLeft(find.text('Product 1'));
    product2Pos = tester.getTopLeft(find.text('Product 2'));
    expect(product1Pos.dy < product2Pos.dy, isFalse);
  });

  testWidgets('product click', (WidgetTester tester) async {
    when(productsObtainer.getProduct(any)).thenAnswer((invc) async =>
        Ok(_makeProduct('${invc.positionalArguments[0] as String} updated')));

    final p1 = _makeProduct('1');
    viewedProductsStorage.addProduct(p1);

    await tester.superPump(const ViewedProductsHistoryPage());

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
    ..vegetarianStatus = VegStatus.positive
    ..veganStatusSource = VegStatusSource.community
    ..vegetarianStatusSource = VegStatusSource.community).productForTests();
}
