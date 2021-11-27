import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plante/l10n/strings.dart';
import 'package:plante/model/country.dart';
import 'package:plante/model/product.dart';
import 'package:plante/model/product_lang_slice.dart';
import 'package:plante/model/shop.dart';
import 'package:plante/model/veg_status.dart';
import 'package:plante/model/veg_status_source.dart';
import 'package:plante/ui/shop/_suggested_products_model.dart';
import 'package:plante/ui/shop/shop_product_range_page.dart';

import '../../widget_tester_extension.dart';
import '../../z_fakes/fake_off_shops_manager.dart';
import '../../z_fakes/fake_products_obtainer.dart';
import '../../z_fakes/fake_suggested_products_manager.dart';
import 'shop_product_range_page_test_commons.dart';

void main() {
  late ShopProductRangePageTestCommons commons;
  late FakeSuggestedProductsManager suggestedProductsManager;
  late FakeProductsObtainer productsObtainer;
  late FakeOffShopsManager offShopsManager;

  late Shop aShop;
  late List<Product> confirmedProducts;
  late List<Product> suggestedProducts;

  setUp(() async {
    commons = await ShopProductRangePageTestCommons.create();
    aShop = commons.aShop;
    confirmedProducts = commons.confirmedProducts;
    suggestedProducts = commons.suggestedProducts;
    suggestedProductsManager = commons.suggestedProductsManager;
    productsObtainer = commons.productsObtainer;
    offShopsManager = commons.offShopsmanager;
    // Let's remove the confirmed products so it would be easier
    // to test the suggested ones.
    // Some tests will reintroduce confirmed products when they need it.
    commons.setConfirmedProducts(const []);
  });

  testWidgets('suggested products title offShop not found',
      (WidgetTester tester) async {
    final widget = ShopProductRangePage.createForTesting(aShop);
    final context = await tester.superPump(widget);

    final title = context
        .strings.shop_product_range_page_suggested_products_country_unknown
        .replaceAll('<SHOP>', aShop.name);
    expect(find.text(title), findsOneWidget);
    final countryTitle = context
        .strings.shop_product_range_page_suggested_products_country
        .replaceAll('<SHOP>', aShop.name)
        .replaceAll('<COUNTRY>', Country.fr.localize(context)!);
    expect(find.text(countryTitle), findsNothing);
  });

  testWidgets('suggested products title with country',
      (WidgetTester tester) async {
    offShopsManager.setOffShop(Country.fr, aShop.name);
    final widget = ShopProductRangePage.createForTesting(aShop);
    final context = await tester.superPump(widget);
    final title = context
        .strings.shop_product_range_page_suggested_products_country
        .replaceAll('<SHOP>', aShop.name)
        .replaceAll('<COUNTRY>', Country.fr.localize(context)!);
    expect(find.text(title), findsOneWidget);
  });

  testWidgets('suggested products title without country',
      (WidgetTester tester) async {
    offShopsManager.setOffShop(null, aShop.name);
    final widget = ShopProductRangePage.createForTesting(aShop);
    final context = await tester.superPump(widget);
    final title = context
        .strings.shop_product_range_page_suggested_products_country_unknown
        .replaceAll('<SHOP>', aShop.name);
    expect(find.text(title), findsOneWidget);
    final countryTitle = context
        .strings.shop_product_range_page_suggested_products_country
        .replaceAll('<SHOP>', aShop.name)
        .replaceAll('<COUNTRY>', Country.fr.localize(context)!);
    expect(find.text(countryTitle), findsNothing);
  });

  testWidgets(
      'title for suggested products is not displayed when there are no suggestions',
      (WidgetTester tester) async {
    // Suggestions are not there, but confirmed products are
    commons.setSuggestedProducts(const []);
    commons.setConfirmedProducts(commons.confirmedProducts);

    final widget = ShopProductRangePage.createForTesting(aShop);
    final context = await tester.superPump(widget);

    final title = context
        .strings.shop_product_range_page_suggested_products_country_unknown
        .replaceAll('<SHOP>', aShop.name);
    expect(find.text(title), findsNothing);
  });

  testWidgets('suggested products are below of confirmed products',
      (WidgetTester tester) async {
    // Let's have 1 confirmed and 1 suggested products
    commons.setConfirmedProducts([confirmedProducts.first]);
    commons.setSuggestedProducts([suggestedProducts.first]);

    final widget = ShopProductRangePage.createForTesting(aShop);
    await tester.superPump(widget);

    final confirmedProductCenter =
        tester.getCenter(find.text(confirmedProducts.first.name!));
    final suggestedProductCenter =
        tester.getCenter(find.text(suggestedProducts.first.name!));
    expect(suggestedProductCenter.dy, greaterThan(confirmedProductCenter.dy));
  });

  testWidgets('not fully filled suggested products are not displayed',
      (WidgetTester tester) async {
    // Remove the product's name, making it not fully filled
    suggestedProducts[0] =
        suggestedProducts[0].rebuild((e) => e.imageFrontLangs.clear());
    commons.setSuggestedProducts(suggestedProducts);

    final widget = ShopProductRangePage.createForTesting(aShop);
    await tester.superPump(widget);

    expect(find.text(suggestedProducts[0].name!), findsNothing);
    expect(find.text(suggestedProducts[1].name!), findsOneWidget);
  });

  testWidgets('more suggestions are loaded when screen scrolled down',
      (WidgetTester tester) async {
    suggestedProductsManager.clearAllSuggestions();
    suggestedProducts.clear();
    const batchSize = SuggestedProductsModel.LOADED_BATCH_SIZE;
    for (var index = 0; index < batchSize * 10; ++index) {
      suggestedProducts.add(ProductLangSlice((v) => v
        ..barcode = '$index'
        ..name = 'Apple$index'
        ..imageFront = Uri.file(File('./test/assets/img.jpg').absolute.path)
        ..veganStatus = VegStatus.possible
        ..veganStatusSource = VegStatusSource.open_food_facts
        ..imageIngredients =
            Uri.file(File('./test/assets/img.jpg').absolute.path)
        ..ingredientsText = 'Water, salt, sugar').productForTests());
    }
    commons.setSuggestedProducts(suggestedProducts);

    final widget = ShopProductRangePage.createForTesting(aShop);
    await tester.superPump(widget);

    final scrollDown = () async {
      // NOTE: we pause products retrieval before the scroll down
      // and resume it after.
      // This is needed because we expected new batches of products to be
      // retrieved when the page is scrolled down AND we don't won't
      // this retrieval to be instantaneous (otherwise all batches will be
      // loaded during the first scroll-down).
      productsObtainer.pauseProductsRetrieval();
      for (var i = 0; i < 10; ++i) {
        await tester.drag(
            find.byKey(const Key('products_list')), const Offset(0, -3000));
        await tester.pump();
      }
      productsObtainer.resumeProductsRetrieval();
    };

    // Scroll down and verify the last product from the first batch is visible
    // and the first product from the second batch is not yet there
    await scrollDown();
    expect(find.text(suggestedProducts[batchSize - 1].name!), findsOneWidget);
    expect(find.text(suggestedProducts[batchSize].name!), findsNothing);

    // Wait for the second batch to get loaded and
    // verify its first product
    await tester.pumpAndSettle();
    expect(find.text(suggestedProducts[batchSize].name!), findsOneWidget);

    // Scroll down and verify the last product from the second batch is visible
    // and the first product from the third batch is not yet there
    await scrollDown();
    expect(find.text(suggestedProducts[(batchSize * 2) - 1].name!),
        findsOneWidget);
    expect(find.text(suggestedProducts[batchSize * 2].name!), findsNothing);

    // Wait for the third batch to get loaded and
    // verify its first product
    await tester.pumpAndSettle();
    expect(find.text(suggestedProducts[batchSize * 2].name!), findsOneWidget);
  });
}
