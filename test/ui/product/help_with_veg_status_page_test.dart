import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mockito/mockito.dart';
import 'package:plante/base/result.dart';
import 'package:plante/l10n/strings.dart';
import 'package:plante/logging/analytics.dart';
import 'package:plante/model/product.dart';
import 'package:plante/model/product_lang_slice.dart';
import 'package:plante/model/veg_status.dart';
import 'package:plante/model/veg_status_source.dart';
import 'package:plante/outside/products/products_manager.dart';
import 'package:plante/outside/products/products_manager_error.dart';
import 'package:plante/ui/product/help_with_veg_status_page.dart';

import '../../common_mocks.mocks.dart';
import '../../widget_tester_extension.dart';
import '../../z_fakes/fake_analytics.dart';

void main() {
  late MockProductsManager productsManager;
  late FakeAnalytics analytics;

  setUp(() async {
    await GetIt.I.reset();
    analytics = FakeAnalytics();
    GetIt.I.registerSingleton<Analytics>(analytics);

    productsManager = MockProductsManager();
    when(productsManager.createUpdateProduct(any)).thenAnswer(
        (invoc) async => Ok(invoc.positionalArguments[0] as Product));
    GetIt.I.registerSingleton<ProductsManager>(productsManager);
  });

  testWidgets('good scenario', (WidgetTester tester) async {
    final product = ProductLangSlice((v) => v
      ..barcode = '123'
      ..name = 'My product'
      ..veganStatus = VegStatus.possible
      ..veganStatusSource = VegStatusSource.open_food_facts).productForTests();

    var done = false;
    Product? savedProduct;
    final doneCallback = () {
      done = true;
    };
    final productUpdateCallback = (Product product) {
      savedProduct = product;
    };
    final context = await tester.superPump(HelpWithVegStatusPage(product,
        doneCallback: doneCallback,
        productUpdatedCallback: productUpdateCallback));

    await tester.tap(find.byKey(const Key('vegan_positive_btn')));
    await tester.pumpAndSettle();

    expect(done, isFalse);
    expect(savedProduct, isNull);
    expect(analytics.wasEventSent('help_with_veg_status_success'), isFalse);

    await tester.tap(find.text(context.strings.global_done));
    await tester.pumpAndSettle();

    expect(done, isTrue);
    expect(
        savedProduct,
        equals(product.rebuild((e) => e
          ..veganStatus = VegStatus.positive
          ..veganStatusSource = VegStatusSource.community)));
    expect(analytics.wasEventSent('help_with_veg_status_success'), isTrue);
  });

  testWidgets('saving error', (WidgetTester tester) async {
    when(productsManager.createUpdateProduct(any))
        .thenAnswer((invoc) async => Err(ProductsManagerError.NETWORK_ERROR));

    final product = ProductLangSlice((v) => v
      ..barcode = '123'
      ..name = 'My product'
      ..veganStatus = VegStatus.possible
      ..veganStatusSource = VegStatusSource.open_food_facts).productForTests();

    var done = false;
    Product? savedProduct;
    final doneCallback = () {
      done = true;
    };
    final productUpdateCallback = (Product product) {
      savedProduct = product;
    };
    final context = await tester.superPump(HelpWithVegStatusPage(product,
        doneCallback: doneCallback,
        productUpdatedCallback: productUpdateCallback));

    await tester.tap(find.byKey(const Key('vegan_positive_btn')));
    await tester.pumpAndSettle();

    expect(analytics.wasEventSent('help_with_veg_status_failure'), isFalse);

    await tester.tap(find.text(context.strings.global_done));
    await tester.pumpAndSettle();

    expect(analytics.wasEventSent('help_with_veg_status_failure'), isTrue);
    expect(done, isFalse);
    expect(savedProduct, isNull);
  });

  testWidgets('cannot save without explicit selection',
      (WidgetTester tester) async {
    final product = ProductLangSlice((v) => v
      ..barcode = '123'
      ..name = 'My product'
      ..veganStatus = VegStatus.positive
      ..veganStatusSource = VegStatusSource.open_food_facts).productForTests();

    var done = false;
    Product? savedProduct;
    final doneCallback = () {
      done = true;
    };
    final productUpdateCallback = (Product product) {
      savedProduct = product;
    };
    final context = await tester.superPump(HelpWithVegStatusPage(product,
        doneCallback: doneCallback,
        productUpdatedCallback: productUpdateCallback));

    // Save attempt #1
    await tester.tap(find.text(context.strings.global_done));
    await tester.pumpAndSettle();

    // ...nope
    expect(done, isFalse);
    expect(savedProduct, isNull);

    // Set status
    await tester.tap(find.byKey(const Key('vegan_negative_btn')));
    await tester.pumpAndSettle();

    // Save attempt #2
    await tester.tap(find.text(context.strings.global_done));
    await tester.pumpAndSettle();

    expect(done, isTrue);
    expect(
        savedProduct,
        equals(product.rebuild((e) => e
          ..veganStatus = VegStatus.negative
          ..veganStatusSource = VegStatusSource.community)));
  });
}
