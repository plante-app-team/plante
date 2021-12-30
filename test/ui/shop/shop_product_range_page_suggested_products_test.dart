import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plante/base/date_time_extensions.dart';
import 'package:plante/l10n/strings.dart';
import 'package:plante/model/country_table.dart';
import 'package:plante/model/product.dart';
import 'package:plante/model/product_lang_slice.dart';
import 'package:plante/model/shop.dart';
import 'package:plante/model/veg_status.dart';
import 'package:plante/model/veg_status_source.dart';
import 'package:plante/outside/backend/product_at_shop_source.dart';
import 'package:plante/outside/map/extra_properties/product_at_shop_extra_property_type.dart';
import 'package:plante/outside/map/extra_properties/products_at_shops_extra_properties_manager.dart';
import 'package:plante/outside/map/user_address/user_address_piece.dart';
import 'package:plante/outside/map/user_address/user_address_type.dart';
import 'package:plante/outside/products/suggestions/suggestion_type.dart';
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

  final titlesKeysMap = <SuggestionType, String>{};

  setUp(() async {
    for (final type in SuggestionType.values) {
      switch (type) {
        case SuggestionType.OFF:
          titlesKeysMap[type] = 'off_suggested_products_title';
          break;
        case SuggestionType.RADIUS:
          titlesKeysMap[type] = 'rad_suggested_products_title';
          break;
      }
    }

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
    // Each test will have individual suggestions set up
    commons.setSuggestedProducts(const {});
  });

  testWidgets('OFF suggested products title with country',
      (WidgetTester tester) async {
    commons.setSuggestedProducts({
      SuggestionType.OFF: suggestedProducts,
    });

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

  testWidgets('no OFF suggested products without country',
      (WidgetTester tester) async {
    commons.setSuggestedProducts({
      SuggestionType.OFF: suggestedProducts,
    });
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

  testWidgets('radius suggested products', (WidgetTester tester) async {
    var widget = ShopProductRangePage.createForTesting(aShop);
    var context = await tester.superPump(widget);

    final title = context
        .strings.shop_product_range_page_suggested_products_city
        .replaceAll('<SHOP>', aShop.name);

    // No title if no products
    expect(find.text(title), findsNothing);

    commons.setSuggestedProducts({
      SuggestionType.RADIUS: suggestedProducts,
    });
    widget =
        ShopProductRangePage.createForTesting(aShop, key: const Key('2nd'));
    context = await tester.superPump(widget);

    // Now there's the title
    expect(find.text(title), findsOneWidget);
  });

  testWidgets('no radius suggested products without country',
      (WidgetTester tester) async {
    // No country code
    userAddressObtainer.setResultFor(
        UserAddressType.CAMERA_LOCATION, UserAddressPiece.COUNTRY_CODE, null);
    // But products are here
    commons.setSuggestedProducts({
      SuggestionType.RADIUS: suggestedProducts,
    });

    final widget = ShopProductRangePage.createForTesting(aShop);
    final context = await tester.superPump(widget);

    // No title
    final title = context
        .strings.shop_product_range_page_suggested_products_city
        .replaceAll('<SHOP>', aShop.name);
    expect(find.text(title), findsNothing);
    // No suggested products
    expect(find.text(suggestedProducts[0].name!), findsNothing);
    expect(find.text(suggestedProducts[1].name!), findsNothing);
  });

  testWidgets(
      'title for suggested products is not displayed when there are no suggestions',
      (WidgetTester tester) async {
    // Suggestions are not there, but confirmed products are
    commons.setSuggestedProducts(const {});
    commons.setConfirmedProducts(commons.confirmedProducts);

    final widget = ShopProductRangePage.createForTesting(aShop);
    final context = await tester.superPump(widget);

    final country = CountryTable.getCountry(commons.countryCode);
    final titles = [
      context.strings.shop_product_range_page_suggested_products_city
          .replaceAll('<SHOP>', aShop.name),
      context.strings.shop_product_range_page_suggested_products_country_unknown
          .replaceAll('<SHOP>', aShop.name),
      context.strings.shop_product_range_page_suggested_products_country
          .replaceAll('<SHOP>', aShop.name)
          .replaceAll('<COUNTRY>', country!.localize(context)!),
    ];
    for (final title in titles) {
      expect(find.text(title), findsNothing);
    }
  });

  testWidgets('suggested products are below of confirmed products',
      (WidgetTester tester) async {
    for (final type in SuggestionType.values) {
      // Let's have 1 confirmed and 1 suggested products
      commons.setConfirmedProducts([confirmedProducts.first]);
      commons.setSuggestedProducts({
        type: [suggestedProducts.first]
      });

      final widget =
          ShopProductRangePage.createForTesting(aShop, key: Key('for_$type'));
      await tester.superPump(widget);

      final confirmedProductCenter =
          tester.getCenter(find.text(confirmedProducts.first.name!));
      final suggestedProductCenter =
          tester.getCenter(find.text(suggestedProducts.first.name!));
      expect(suggestedProductCenter.dy, greaterThan(confirmedProductCenter.dy));
    }
  });

  testWidgets('which suggestion type is above', (WidgetTester tester) async {
    expect(SuggestionType.values.length, equals(2),
        reason: 'with new suggestions type test needs to be reworked');

    commons.setConfirmedProducts(const []);
    commons.setSuggestedProducts({
      SuggestionType.OFF: [suggestedProducts.first],
      SuggestionType.RADIUS: [suggestedProducts.last],
    });

    final widget = ShopProductRangePage.createForTesting(aShop);
    await tester.superPump(widget);

    final suggestedProductCenter1 =
        tester.getCenter(find.text(suggestedProducts.first.name!));
    final suggestedProductCenter2 =
        tester.getCenter(find.text(suggestedProducts.last.name!));
    expect(suggestedProductCenter1.dy, greaterThan(suggestedProductCenter2.dy));
  });

  testWidgets('not fully filled suggested products are not displayed',
      (WidgetTester tester) async {
    for (final type in SuggestionType.values) {
      // Remove the product's name, making it not fully filled
      suggestedProducts[0] =
          suggestedProducts[0].rebuild((e) => e.imageFrontLangs.clear());
      commons.setSuggestedProducts({type: suggestedProducts});

      final widget =
          ShopProductRangePage.createForTesting(aShop, key: Key('for_$type'));
      await tester.superPump(widget);

      expect(find.text(suggestedProducts[0].name!), findsNothing);
      expect(find.text(suggestedProducts[1].name!), findsOneWidget);
    }
  });

  testWidgets('suggestion product negative presence vote',
      (WidgetTester tester) async {
    for (final type in SuggestionType.values) {
      commons.setConfirmedProducts(const []);
      commons.setSuggestedProducts({type: suggestedProducts});

      final widget =
          ShopProductRangePage.createForTesting(aShop, key: Key('for_$type'));
      final context = await tester.superPump(widget);

      // Both products are present
      expect(find.text(suggestedProducts[0].name!), findsOneWidget);
      expect(find.text(suggestedProducts[1].name!), findsOneWidget);
      // Suggestion is not yet marked as bad
      var badSuggestions = await productsExtraProperties
          .getBarcodesWithBoolValue(
              ProductAtShopExtraPropertyType.BAD_SUGGESTION,
              true,
              [commons.aShop.osmUID]);
      expect(
          badSuggestions.isEmpty ||
              badSuggestions[commons.aShop.osmUID]!.isEmpty,
          isTrue);

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

      // clean up for next iteration
      await productsExtraProperties.setBoolProperty(
          ProductAtShopExtraPropertyType.BAD_SUGGESTION,
          commons.aShop.osmUID,
          suggestedProducts[0].barcode,
          false);
    }
  });

  testWidgets('suggestion product positive presence vote',
      (WidgetTester tester) async {
    for (final type in SuggestionType.values) {
      commons.setConfirmedProducts(const []);
      commons.setSuggestedProducts({type: suggestedProducts});
      shopsManager.clear_verifiedCalls();
      final title = titlesKeysMap[type]!;

      final widget =
          ShopProductRangePage.createForTesting(aShop, key: Key('for_$title'));
      final context = await tester.superPump(widget);

      // Product is not yet put to the shop
      shopsManager.verify_putProductToShops_called(times: 0);

      // Both products are below the suggested products title
      var suggestedProductsTitleCenter =
          tester.getCenter(find.byKey(Key(title)));
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
      final productToShopCall = shopsManager.calls_putProductToShops().first;
      expect(productToShopCall.product, equals(suggestedProducts[0]));
      expect(productToShopCall.shops, equals([aShop]));
      expect(
          productToShopCall.source, equals(ProductAtShopSource.OFF_SUGGESTION));

      // Positively-voted product is now confirmed
      suggestedProductsTitleCenter = tester.getCenter(find.byKey(Key(title)));
      center0 = tester.getCenter(find.text(suggestedProducts[0].name!));
      center1 = tester.getCenter(find.text(suggestedProducts[1].name!));
      expect(center0.dy, lessThan(suggestedProductsTitleCenter.dy));
      expect(suggestedProductsTitleCenter.dy, lessThan(center1.dy));
    }
  });

  testWidgets('more suggestions are loaded when screen scrolled down',
      (WidgetTester tester) async {
    for (final type in SuggestionType.values) {
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
      commons.setSuggestedProducts({type: suggestedProducts});

      final widget =
          ShopProductRangePage.createForTesting(aShop, key: Key('for_$type'));
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
    }
  });

  testWidgets('suggested products do not have "Last seen" str',
      (WidgetTester tester) async {
    for (final type in SuggestionType.values) {
      final confirmedProducts = commons.confirmedProducts.toList();
      final suggestedProducts = commons.suggestedProducts.toList();
      commons.setConfirmedProducts(const []);
      commons.setSuggestedProducts({
        type: [suggestedProducts[0]]
      });

      var widget =
          ShopProductRangePage.createForTesting(aShop, key: Key('1_for_$type'));
      var context = await tester.superPump(widget);
      final lastSeenStr =
          context.strings.shop_product_range_page_product_last_seen_here;

      // Nope
      expect(find.textContaining(lastSeenStr), findsNothing);

      commons.setConfirmedProducts([confirmedProducts[0]],
          {confirmedProducts[0].barcode: DateTime.now().secondsSinceEpoch});
      commons.setSuggestedProducts(const {});
      widget =
          ShopProductRangePage.createForTesting(aShop, key: Key('2_for_$type'));
      context = await tester.superPump(widget);

      // Yep
      expect(find.textContaining(lastSeenStr), findsOneWidget);
    }
  });

  testWidgets('suggested products have a distinct hint',
      (WidgetTester tester) async {
    for (final type in SuggestionType.values) {
      final confirmedProducts = commons.confirmedProducts.toList();
      final suggestedProducts = commons.suggestedProducts.toList();
      commons.setConfirmedProducts([confirmedProducts[0]],
          {confirmedProducts[0].barcode: DateTime.now().secondsSinceEpoch});
      commons.setSuggestedProducts(const {});

      var widget = ShopProductRangePage.createForTesting(aShop,
          key: Key('page1_for_$type'));
      var context = await tester.superPump(widget);

      // Nope
      expect(
          find.text(
              context.strings.shop_product_range_page_suggested_product_hint2),
          findsNothing);

      commons.setConfirmedProducts(const []);
      commons.setSuggestedProducts({
        type: [suggestedProducts[0]]
      });
      widget = ShopProductRangePage.createForTesting(aShop,
          key: Key('page2_for_$type'));
      context = await tester.superPump(widget);

      // Yep
      expect(
          find.text(context
              .strings.shop_product_range_page_suggested_product_hint2
              .replaceAll('<SHOP>', widget.shop.name)),
          findsOneWidget);
    }
  });

  testWidgets(
      'suggested product is not shown if it is already in confirmed list',
      (WidgetTester tester) async {
    final theProduct = ProductLangSlice((v) => v
      ..barcode = '123'
      ..name = 'Nice product'
      ..imageFront = Uri.file(File('./test/assets/img.jpg').absolute.path)
      ..imageIngredients = Uri.file(File('./test/assets/img.jpg').absolute.path)
      ..veganStatus = VegStatus.positive
      ..veganStatusSource = VegStatusSource.community
      ..ingredientsText = 'Water, salt, sugar').productForTests();

    final otherSuggestedProduct = ProductLangSlice((v) => v
      ..barcode = '124'
      ..name = 'Some other'
      ..imageFront = Uri.file(File('./test/assets/img.jpg').absolute.path)
      ..imageIngredients = Uri.file(File('./test/assets/img.jpg').absolute.path)
      ..veganStatus = VegStatus.positive
      ..veganStatusSource = VegStatusSource.open_food_facts
      ..ingredientsText = 'Water, salt, sugar').productForTests();

    for (final type in SuggestionType.values) {
      commons.setConfirmedProducts([theProduct]);
      commons.setSuggestedProducts({
        type: [theProduct, otherSuggestedProduct]
      });

      final widget =
          ShopProductRangePage.createForTesting(aShop, key: Key('for_$type'));
      await tester.superPump(widget);

      expect(find.text(theProduct.name!), findsNWidgets(1));
      expect(find.text(otherSuggestedProduct.name!), findsNWidgets(1));

      final suggestedProductsTitleCenter =
          tester.getCenter(find.byKey(Key(titlesKeysMap[type]!)));
      final theProductWidgetCenter =
          tester.getCenter(find.text(theProduct.name!));
      final otherSuggestedProductWidgetCenter =
          tester.getCenter(find.text(otherSuggestedProduct.name!));

      expect(
          theProductWidgetCenter.dy, lessThan(suggestedProductsTitleCenter.dy));
      expect(suggestedProductsTitleCenter.dy,
          lessThan(otherSuggestedProductWidgetCenter.dy));
    }
  });

  testWidgets('suggested OFF product is not shown if it is already in RAD list',
      (WidgetTester tester) async {
    expect(SuggestionType.values.length, equals(2),
        reason: 'with new suggestions type test needs to be reworked');

    final theProduct = ProductLangSlice((v) => v
      ..barcode = '123'
      ..name = 'Nice product'
      ..imageFront = Uri.file(File('./test/assets/img.jpg').absolute.path)
      ..imageIngredients = Uri.file(File('./test/assets/img.jpg').absolute.path)
      ..veganStatus = VegStatus.positive
      ..veganStatusSource = VegStatusSource.community
      ..ingredientsText = 'Water, salt, sugar').productForTests();

    final otherSuggestedProduct = ProductLangSlice((v) => v
      ..barcode = '124'
      ..name = 'Some other'
      ..imageFront = Uri.file(File('./test/assets/img.jpg').absolute.path)
      ..imageIngredients = Uri.file(File('./test/assets/img.jpg').absolute.path)
      ..veganStatus = VegStatus.positive
      ..veganStatusSource = VegStatusSource.open_food_facts
      ..ingredientsText = 'Water, salt, sugar').productForTests();

    commons.setConfirmedProducts(const []);
    commons.setSuggestedProducts({
      SuggestionType.RADIUS: [theProduct],
      SuggestionType.OFF: [theProduct, otherSuggestedProduct],
    });

    final widget = ShopProductRangePage.createForTesting(aShop);
    await tester.superPump(widget);

    expect(find.text(theProduct.name!), findsNWidgets(1));
    expect(find.text(otherSuggestedProduct.name!), findsNWidgets(1));

    final suggestedOFFProductsTitleCenter =
        tester.getCenter(find.byKey(Key(titlesKeysMap[SuggestionType.OFF]!)));
    final theProductWidgetCenter =
        tester.getCenter(find.text(theProduct.name!));
    final otherSuggestedProductWidgetCenter =
        tester.getCenter(find.text(otherSuggestedProduct.name!));

    expect(theProductWidgetCenter.dy,
        lessThan(suggestedOFFProductsTitleCenter.dy));
    expect(suggestedOFFProductsTitleCenter.dy,
        lessThan(otherSuggestedProductWidgetCenter.dy));
  });
}
