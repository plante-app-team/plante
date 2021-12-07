import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plante/l10n/strings.dart';
import 'package:plante/model/country_table.dart';
import 'package:plante/model/product.dart';
import 'package:plante/model/product_lang_slice.dart';
import 'package:plante/model/shop.dart';
import 'package:plante/model/veg_status.dart';
import 'package:plante/model/veg_status_source.dart';
import 'package:plante/outside/map/extra_properties/product_at_shop_extra_property_type.dart';
import 'package:plante/outside/map/extra_properties/products_at_shops_extra_properties_manager.dart';
import 'package:plante/outside/map/user_address/user_address_piece.dart';
import 'package:plante/outside/map/user_address/user_address_type.dart';
import 'package:plante/ui/base/components/product_card.dart';
import 'package:plante/ui/shop/_suggested_products_model.dart';
import 'package:plante/ui/shop/shop_product_range_page.dart';

import '../../widget_tester_extension.dart';
import '../../z_fakes/fake_caching_user_address_pieces_obtainer.dart';
import '../../z_fakes/fake_products_obtainer.dart';
import '../../z_fakes/fake_shops_manager.dart';
import '../../z_fakes/fake_suggested_products_manager.dart';
import 'shop_product_range_page_test_commons.dart';

void main() {
  late ShopProductRangePageTestCommons commons;
  late FakeSuggestedProductsManager suggestedProductsManager;
  late FakeProductsObtainer productsObtainer;
  late FakeCachingUserAddressPiecesObtainer userAddressObtainer;
  late ProductsAtShopsExtraPropertiesManager productsExtraProperties;
  late FakeShopsManager shopsManager;

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
    userAddressObtainer = commons.userAddressObtainer;
    productsExtraProperties = commons.productsExtraProperties;
    shopsManager = commons.shopsManager;
    // Let's remove the confirmed products so it would be easier
    // to test the suggested ones.
    // Some tests will reintroduce confirmed products when they need it.
    commons.setConfirmedProducts(const []);
  });

  testWidgets('suggested products title with country',
      (WidgetTester tester) async {
    final country = CountryTable.getCountry(commons.countryCode);
    userAddressObtainer.setResultFor(UserAddressType.CAMERA_LOCATION,
        UserAddressPiece.COUNTRY_CODE, commons.countryCode);

    final widget = ShopProductRangePage.createForTesting(aShop);
    final context = await tester.superPump(widget);

    // Title here
    final title = context
        .strings.shop_product_range_page_suggested_products_country
        .replaceAll('<SHOP>', aShop.name)
        .replaceAll('<COUNTRY>', country!.localize(context)!);
    expect(find.text(title), findsOneWidget);

    // Suggested products are also here (checking just in case)
    expect(find.text(suggestedProducts[0].name!), findsOneWidget);
    expect(find.text(suggestedProducts[1].name!), findsOneWidget);
  });

  testWidgets('no suggested products without country',
      (WidgetTester tester) async {
    userAddressObtainer.setResultFor(
        UserAddressType.CAMERA_LOCATION, UserAddressPiece.COUNTRY_CODE, null);

    final widget = ShopProductRangePage.createForTesting(aShop);
    final context = await tester.superPump(widget);

    // No title 1
    final title = context
        .strings.shop_product_range_page_suggested_products_country_unknown
        .replaceAll('<SHOP>', aShop.name);
    expect(find.text(title), findsNothing);

    // No title 2
    final country = CountryTable.getCountry(commons.countryCode);
    final countryTitle = context
        .strings.shop_product_range_page_suggested_products_country
        .replaceAll('<SHOP>', aShop.name)
        .replaceAll('<COUNTRY>', country!.localize(context)!);
    expect(find.text(countryTitle), findsNothing);

    // No suggested products
    expect(find.text(suggestedProducts[0].name!), findsNothing);
    expect(find.text(suggestedProducts[1].name!), findsNothing);
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

  testWidgets('suggestion product negative presence vote',
      (WidgetTester tester) async {
    commons.setConfirmedProducts(const []);
    commons.setSuggestedProducts(suggestedProducts);

    final widget = ShopProductRangePage.createForTesting(aShop);
    final context = await tester.superPump(widget);

    // Both products are present
    expect(find.text(suggestedProducts[0].name!), findsOneWidget);
    expect(find.text(suggestedProducts[1].name!), findsOneWidget);
    // Suggestion is not yet marked as bad
    var badSuggestions = await productsExtraProperties.getBarcodesWithBoolValue(
        ProductAtShopExtraPropertyType.BAD_SUGGESTION,
        true,
        [commons.aShop.osmUID]);
    expect(badSuggestions, isEmpty);

    // Verify the proper product
    final card = find.byType(ProductCard).evaluate().first.widget;
    expect(
        find.descendant(
            of: find.byWidget(card),
            matching: find.text(suggestedProducts[0].name!)),
        findsOneWidget);
    // Negative presence vote
    await tester.superTap(find.descendant(
        of: find.byWidget(card),
        matching: find.text(context.strings.global_no)));
    await tester.superTap(find.descendant(
        of: find.byKey(const Key('yes_no_dialog')),
        matching: find.text(context.strings.global_yes)));

    // Only 1 product is present
    expect(find.text(suggestedProducts[0].name!), findsNothing);
    expect(find.text(suggestedProducts[1].name!), findsOneWidget);
    // Suggestion is now marked as bad
    badSuggestions = await productsExtraProperties.getBarcodesWithBoolValue(
        ProductAtShopExtraPropertyType.BAD_SUGGESTION,
        true,
        [commons.aShop.osmUID]);
    expect(
        badSuggestions,
        equals({
          commons.aShop.osmUID: {suggestedProducts[0].barcode}
        }));
  });

  testWidgets('suggestion product positive presence vote',
      (WidgetTester tester) async {
    commons.setConfirmedProducts(const []);
    commons.setSuggestedProducts(suggestedProducts);

    final widget = ShopProductRangePage.createForTesting(aShop);
    final context = await tester.superPump(widget);

    // Product is not yet put to the shop
    shopsManager.verify_putProductToShops_called(times: 0);

    // Both products are below the suggested products title
    var suggestedProductsTitleCenter =
        tester.getCenter(find.byKey(const Key('suggested_products_title')));
    var center0 = tester.getCenter(find.text(suggestedProducts[0].name!));
    var center1 = tester.getCenter(find.text(suggestedProducts[1].name!));
    expect(suggestedProductsTitleCenter.dy, lessThan(center0.dy));
    expect(suggestedProductsTitleCenter.dy, lessThan(center1.dy));

    // Verify we will click the product we want to click
    final card = find.byType(ProductCard).evaluate().first.widget;
    expect(
        find.descendant(
            of: find.byWidget(card),
            matching: find.text(suggestedProducts[0].name!)),
        findsOneWidget);
    // Positive presence vote
    await tester.superTap(find.descendant(
        of: find.byWidget(card),
        matching: find.text(context.strings.global_yes)));
    await tester.superTap(find.descendant(
        of: find.byKey(const Key('yes_no_dialog')),
        matching: find.text(context.strings.global_yes)));

    // Product is now put to the shop
    shopsManager.verify_putProductToShops_called(times: 1);

    // Positively-voted product is now confirmed
    suggestedProductsTitleCenter =
        tester.getCenter(find.byKey(const Key('suggested_products_title')));
    center0 = tester.getCenter(find.text(suggestedProducts[0].name!));
    center1 = tester.getCenter(find.text(suggestedProducts[1].name!));
    expect(center0.dy, lessThan(suggestedProductsTitleCenter.dy));
    expect(suggestedProductsTitleCenter.dy, lessThan(center1.dy));
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
