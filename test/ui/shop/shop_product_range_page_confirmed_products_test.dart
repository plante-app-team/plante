import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plante/base/result.dart';
import 'package:plante/l10n/strings.dart';
import 'package:plante/model/product.dart';
import 'package:plante/model/product_lang_slice.dart';
import 'package:plante/model/shop.dart';
import 'package:plante/model/shop_product_range.dart';
import 'package:plante/model/veg_status.dart';
import 'package:plante/model/veg_status_source.dart';
import 'package:plante/ui/base/components/product_card.dart';
import 'package:plante/ui/base/ui_utils.dart';
import 'package:plante/ui/product/display_product_page.dart';
import 'package:plante/ui/shop/shop_product_range_page.dart';

import '../../widget_tester_extension.dart';
import '../../z_fakes/fake_shops_manager.dart';
import 'shop_product_range_page_test_commons.dart';

void main() {
  late ShopProductRangePageTestCommons commons;
  late FakeShopsManager shopsManager;

  late Shop aShop;
  late List<Product> products;
  late Map<Product, DateTime> productsLastSeen;
  late ShopProductRange range;

  setUp(() async {
    commons = await ShopProductRangePageTestCommons.create();
    aShop = commons.aShop;
    products = commons.confirmedProducts;
    productsLastSeen = commons.confirmedProductsLastSeen;
    range = commons.range;
    shopsManager = commons.shopsManager;
  });

  testWidgets('product range reloading on product range updates',
      (WidgetTester tester) async {
    final widget = ShopProductRangePage.createForTesting(aShop);
    await tester.superPump(widget);

    shopsManager.clear_verifiedCalls();
    await tester.pumpAndSettle();
    shopsManager.verity_fetchShopProductRange_called(times: 0);

    // Ensure shop's product range is requested after listeners notification
    shopsManager.setShopRange(aShop.osmUID, Ok(range));
    await tester.pumpAndSettle();
    shopsManager.verity_fetchShopProductRange_called();
  });

  testWidgets('displayed product range', (WidgetTester tester) async {
    final widget = ShopProductRangePage.createForTesting(aShop);
    final context = await tester.superPump(widget);

    final cards =
        find.byType(ProductCard).evaluate().map((e) => e.widget).toList();
    for (var i = 0; i < cards.length; ++i) {
      expect(
          find.descendant(
              of: find.byWidget(cards[i]),
              matching: find.text(products[i].name!)),
          findsOneWidget);

      final expectedDateStr =
          dateToStr(productsLastSeen[products[i]]!, context);
      final expectedLastSeenStr =
          '${context.strings.shop_product_range_page_product_last_seen_here}'
          '$expectedDateStr';
      expect(
          find.descendant(
              of: find.byWidget(cards[i]),
              matching: find.text(expectedLastSeenStr)),
          findsOneWidget);
    }
  });

  testWidgets('click on a product', (WidgetTester tester) async {
    final widget = ShopProductRangePage.createForTesting(aShop);
    await tester.superPump(widget);

    expect(find.byType(DisplayProductPage), findsNothing);
    await tester.tap(find.text(products[0].name!));
    await tester.pumpAndSettle();
    expect(find.byType(DisplayProductPage), findsOneWidget);
  });

  testWidgets('vote for product presence', (WidgetTester tester) async {
    final widget = ShopProductRangePage.createForTesting(aShop);
    final context = await tester.superPump(widget);

    final card = find.byType(ProductCard).evaluate().first.widget;
    final product = products[0];

    // Verify the proper product
    expect(
        find.descendant(
            of: find.byWidget(card), matching: find.text(product.name!)),
        findsOneWidget);

    // Tap and verify the vote is sent
    shopsManager.verity_productPresenceVote_called(times: 0);
    await tester.tap(find.descendant(
        of: find.byWidget(card),
        matching: find.text(context.strings.global_yes)));
    await tester.pumpAndSettle();
    await tester.tap(find.descendant(
        of: find.byKey(const Key('yes_no_dialog')),
        matching: find.text(context.strings.global_yes)));
    await tester.pumpAndSettle();
    shopsManager.verity_productPresenceVote_called();
    expect(
        shopsManager.calls_productPresenceVote(aShop, product), equals([true]));
  });

  testWidgets('vote against product presence', (WidgetTester tester) async {
    final widget = ShopProductRangePage.createForTesting(aShop);
    final context = await tester.superPump(widget);

    final card = find.byType(ProductCard).evaluate().first.widget;
    final product = products[0];

    // Verify the proper product
    expect(
        find.descendant(
            of: find.byWidget(card), matching: find.text(product.name!)),
        findsOneWidget);

    // Tap and verify the vote is sent
    shopsManager.verity_productPresenceVote_called(times: 0);
    await tester.tap(find.descendant(
        of: find.byWidget(card),
        matching: find.text(context.strings.global_no)));
    await tester.pumpAndSettle();
    await tester.tap(find.descendant(
        of: find.byKey(const Key('yes_no_dialog')),
        matching: find.text(context.strings.global_yes)));
    await tester.pumpAndSettle();
    shopsManager.verity_productPresenceVote_called();
    expect(shopsManager.calls_productPresenceVote(aShop, product),
        equals([false]));
  });

  testWidgets('products are sorted by their last-seen property (order 1)',
      (WidgetTester tester) async {
    final products = [
      ProductLangSlice((v) => v
        ..barcode = '123'
        ..name = 'Apple'
        ..imageFront = Uri.file(File('./test/assets/img.jpg').absolute.path)
        ..veganStatus = VegStatus.positive
        ..veganStatusSource = VegStatusSource.open_food_facts
        ..ingredientsText = 'Water, salt, sugar').productForTests(),
      ProductLangSlice((v) => v
        ..barcode = '124'
        ..name = 'Pineapple'
        ..imageFront = Uri.file(File('./test/assets/img.jpg').absolute.path)
        ..veganStatus = VegStatus.positive
        ..veganStatusSource = VegStatusSource.open_food_facts
        ..ingredientsText = 'Water, salt, sugar').productForTests(),
    ];
    final productsLastSeen = {
      products[0]: DateTime(2012, 1, 1),
      products[1]: DateTime(2011, 2, 2),
    };
    final productsLastSeenSecs = productsLastSeen.map((key, value) =>
        MapEntry(key.barcode, (value.millisecondsSinceEpoch / 1000).round()));
    final range = ShopProductRange((e) => e
      ..shop.replace(aShop)
      ..products.addAll(products)
      ..productsLastSeenSecsUtc.addAll(productsLastSeenSecs));
    shopsManager.setShopRange(aShop.osmUID, Ok(range));

    final widget = ShopProductRangePage.createForTesting(aShop);
    await tester.superPump(widget);

    final product0Center = tester.getCenter(find.text(products[0].name!));
    final product1Center = tester.getCenter(find.text(products[1].name!));
    expect(product1Center.dy, greaterThan(product0Center.dy));
  });

  testWidgets('products are sorted by their last-seen property (order 2)',
      (WidgetTester tester) async {
    final products = [
      ProductLangSlice((v) => v
        ..barcode = '123'
        ..name = 'Apple'
        ..imageFront = Uri.file(File('./test/assets/img.jpg').absolute.path)
        ..veganStatus = VegStatus.positive
        ..veganStatusSource = VegStatusSource.open_food_facts
        ..ingredientsText = 'Water, salt, sugar').productForTests(),
      ProductLangSlice((v) => v
        ..barcode = '124'
        ..name = 'Pineapple'
        ..imageFront = Uri.file(File('./test/assets/img.jpg').absolute.path)
        ..veganStatus = VegStatus.positive
        ..veganStatusSource = VegStatusSource.open_food_facts
        ..ingredientsText = 'Water, salt, sugar').productForTests(),
    ];
    final productsLastSeen = {
      products[0]: DateTime(2012, 1, 1),
      products[1]: DateTime(2013, 2, 2),
    };
    final productsLastSeenSecs = productsLastSeen.map((key, value) =>
        MapEntry(key.barcode, (value.millisecondsSinceEpoch / 1000).round()));
    final range = ShopProductRange((e) => e
      ..shop.replace(aShop)
      ..products.addAll(products)
      ..productsLastSeenSecsUtc.addAll(productsLastSeenSecs));
    shopsManager.setShopRange(aShop.osmUID, Ok(range));

    final widget = ShopProductRangePage.createForTesting(aShop);
    await tester.superPump(widget);

    final product0Center = tester.getCenter(find.text(products[0].name!));
    final product1Center = tester.getCenter(find.text(products[1].name!));
    expect(product1Center.dy, lessThan(product0Center.dy));
  });

  testWidgets('products reloading changes order only when products set changes',
      (WidgetTester tester) async {
    final products = [
      ProductLangSlice((v) => v
        ..barcode = '123'
        ..name = 'Apple'
        ..imageFront = Uri.file(File('./test/assets/img.jpg').absolute.path)
        ..veganStatus = VegStatus.positive
        ..veganStatusSource = VegStatusSource.open_food_facts
        ..ingredientsText = 'Water, salt, sugar').productForTests(),
      ProductLangSlice((v) => v
        ..barcode = '124'
        ..name = 'Pineapple'
        ..imageFront = Uri.file(File('./test/assets/img.jpg').absolute.path)
        ..veganStatus = VegStatus.positive
        ..veganStatusSource = VegStatusSource.open_food_facts
        ..ingredientsText = 'Water, salt, sugar').productForTests(),
    ];
    var productsLastSeen = {
      products[0]: DateTime(2012, 1, 1),
      products[1]: DateTime(2011, 2, 2),
    };
    var productsLastSeenSecs = productsLastSeen.map((key, value) =>
        MapEntry(key.barcode, (value.millisecondsSinceEpoch / 1000).round()));
    var range = ShopProductRange((e) => e
      ..shop.replace(aShop)
      ..products.addAll(products)
      ..productsLastSeenSecsUtc.addAll(productsLastSeenSecs));
    shopsManager.setShopRange(aShop.osmUID, Ok(range));

    // Create widget
    final widget = ShopProductRangePage.createForTesting(aShop);
    await tester.superPump(widget);

    // Initial order
    var product0Center = tester.getCenter(find.text(products[0].name!));
    var product1Center = tester.getCenter(find.text(products[1].name!));
    expect(product1Center.dy, greaterThan(product0Center.dy));

    // Change the 'last seen' property
    productsLastSeen = {
      products[0]: DateTime(2012, 1, 1),
      products[1]: DateTime(2013, 2, 2),
    };
    productsLastSeenSecs = productsLastSeen.map((key, value) =>
        MapEntry(key.barcode, (value.millisecondsSinceEpoch / 1000).round()));
    range = ShopProductRange((e) => e
      ..shop.replace(aShop)
      ..products.addAll(products)
      ..productsLastSeenSecsUtc.addAll(productsLastSeenSecs));
    shopsManager.setShopRange(aShop.osmUID, Ok(range));
    await tester.pumpAndSettle();

    // Verify initial order is kept, even though
    // the 'last seen' properties have changed
    product0Center = tester.getCenter(find.text(products[0].name!));
    product1Center = tester.getCenter(find.text(products[1].name!));
    expect(product1Center.dy, greaterThan(product0Center.dy));

    // Add another product, unrelated to first 2
    products.add(ProductLangSlice((v) => v
      ..barcode = '223'
      ..name = 'Some unrelated product'
      ..imageFront = Uri.file(File('./test/assets/img.jpg').absolute.path)
      ..veganStatus = VegStatus.positive
      ..veganStatusSource = VegStatusSource.open_food_facts
      ..ingredientsText = 'Water, salt, sugar').productForTests());

    // NOTE: we'll keep the 'last seen' properties same

    // Range with the new product
    range = ShopProductRange((e) => e
      ..shop.replace(aShop)
      ..products.addAll(products)
      ..productsLastSeenSecsUtc.addAll(productsLastSeenSecs));
    shopsManager.setShopRange(aShop.osmUID, Ok(range));
    await tester.pumpAndSettle();

    // Verify initial order is NOT kept!
    // Second product is not first.
    product0Center = tester.getCenter(find.text(products[0].name!));
    product1Center = tester.getCenter(find.text(products[1].name!));
    expect(product1Center.dy, lessThan(product0Center.dy));
  });

  testWidgets('voting removes vote options', (WidgetTester tester) async {
    final widget = ShopProductRangePage.createForTesting(aShop);
    final context = await tester.superPump(widget);

    // YES vote

    var card = find.byType(ProductCard).evaluate().first.widget;
    var product = products[0];

    // Verify the proper product
    expect(
        find.descendant(
            of: find.byWidget(card), matching: find.text(product.name!)),
        findsOneWidget);

    // Vote
    await tester.tap(find.descendant(
        of: find.byWidget(card),
        matching: find.text(context.strings.global_yes)));
    await tester.pumpAndSettle();
    await tester.tap(find.descendant(
        of: find.byKey(const Key('yes_no_dialog')),
        matching: find.text(context.strings.global_yes)));
    await tester.pumpAndSettle();

    // Verify the vote options are gone from the card
    card = find.byType(ProductCard).evaluate().first.widget;
    expect(
        find.descendant(
            of: find.byWidget(card),
            matching: find.text(context.strings.global_yes)),
        findsNothing);
    expect(
        find.descendant(
            of: find.byWidget(card),
            matching: find.text(context.strings.global_no)),
        findsNothing);

    // NO vote

    card = find.byType(ProductCard).evaluate().toList()[1].widget;
    product = products[1];

    // Verify the proper product
    expect(
        find.descendant(
            of: find.byWidget(card), matching: find.text(product.name!)),
        findsOneWidget);

    // Vote
    await tester.tap(find.descendant(
        of: find.byWidget(card),
        matching: find.text(context.strings.global_no)));
    await tester.pumpAndSettle();
    await tester.tap(find.descendant(
        of: find.byKey(const Key('yes_no_dialog')),
        matching: find.text(context.strings.global_yes)));
    await tester.pumpAndSettle();

    // Verify the vote options are gone from the card
    card = find.byType(ProductCard).evaluate().first.widget;
    expect(
        find.descendant(
            of: find.byWidget(card),
            matching: find.text(context.strings.global_yes)),
        findsNothing);
    expect(
        find.descendant(
            of: find.byWidget(card),
            matching: find.text(context.strings.global_no)),
        findsNothing);
  });

  testWidgets('cancelled voting does not remove vote options',
      (WidgetTester tester) async {
    final widget = ShopProductRangePage.createForTesting(aShop);
    final context = await tester.superPump(widget);

    // YES vote

    var card = find.byType(ProductCard).evaluate().first.widget;
    final product = products[0];

    // Verify the proper product
    expect(
        find.descendant(
            of: find.byWidget(card), matching: find.text(product.name!)),
        findsOneWidget);

    // Vote
    await tester.tap(find.descendant(
        of: find.byWidget(card),
        matching: find.text(context.strings.global_yes)));
    await tester.pumpAndSettle();
    await tester.tap(find.descendant(
        of: find.byKey(const Key('yes_no_dialog')),
        matching: find.text(context.strings.global_no)));
    await tester.pumpAndSettle();

    // Verify the vote options are STILL on the card
    card = find.byType(ProductCard).evaluate().first.widget;
    expect(
        find.descendant(
            of: find.byWidget(card),
            matching: find.text(context.strings.global_yes)),
        findsOneWidget);
    expect(
        find.descendant(
            of: find.byWidget(card),
            matching: find.text(context.strings.global_no)),
        findsOneWidget);

    // NO vote

    // Tap and verify the vote is sent
    await tester.tap(find.descendant(
        of: find.byWidget(card),
        matching: find.text(context.strings.global_no)));
    await tester.pumpAndSettle();
    await tester.tap(find.descendant(
        of: find.byKey(const Key('yes_no_dialog')),
        matching: find.text(context.strings.global_no)));
    await tester.pumpAndSettle();

    // Verify the vote options are STILL on the card
    card = find.byType(ProductCard).evaluate().first.widget;
    expect(
        find.descendant(
            of: find.byWidget(card),
            matching: find.text(context.strings.global_yes)),
        findsOneWidget);
    expect(
        find.descendant(
            of: find.byWidget(card),
            matching: find.text(context.strings.global_no)),
        findsOneWidget);
  });
}
