import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plante/base/result.dart';
import 'package:plante/l10n/strings.dart';
import 'package:plante/model/product.dart';
import 'package:plante/model/product_lang_slice.dart';
import 'package:plante/model/shop.dart';
import 'package:plante/model/shop_product_range.dart';
import 'package:plante/model/user_params.dart';
import 'package:plante/model/veg_status.dart';
import 'package:plante/model/veg_status_source.dart';
import 'package:plante/outside/map/osm/osm_short_address.dart';
import 'package:plante/outside/map/shops_manager_types.dart';
import 'package:plante/outside/products/suggestions/suggestion_type.dart';
import 'package:plante/ui/base/components/address_widget.dart';
import 'package:plante/ui/base/components/product_card.dart';
import 'package:plante/ui/product/display_product_page.dart';
import 'package:plante/ui/scan/barcode_scan_page.dart';
import 'package:plante/ui/shop/shop_product_range_page.dart';

import '../../common_finders_extension.dart';
import '../../widget_tester_extension.dart';
import '../../z_fakes/fake_shops_manager.dart';
import '../../z_fakes/fake_user_params_controller.dart';
import 'shop_product_range_page_test_commons.dart';

void main() {
  late ShopProductRangePageTestCommons commons;
  late FakeShopsManager shopsManager;
  late FakeUserParamsController userParamsController;

  late Shop aShop;
  late List<Product> products;
  late ShopProductRange range;
  late OsmShortAddress address;

  setUp(() async {
    commons = await ShopProductRangePageTestCommons.create();
    aShop = commons.aShop;
    products = commons.confirmedProducts;
    range = commons.range;
    address = commons.address;
    shopsManager = commons.shopsManager;
    userParamsController = commons.userParamsController;
  });

  testWidgets('shop name in title', (WidgetTester tester) async {
    final widget = ShopProductRangePage.createForTesting(aShop);
    await tester.superPump(widget);
    expect(find.text(aShop.name), findsOneWidget);
  });

  testWidgets('scroll to top button not visible', (WidgetTester tester) async {
    final widget = ShopProductRangePage.createForTesting(aShop);
    await tester.superPump(widget);

    expect(find.byKey(const Key('back_to_top_button')), findsNothing);
  });

  testWidgets('scroll to top button visible', (WidgetTester tester) async {
    final widget = ShopProductRangePage.createForTesting(aShop);
    await tester.superPump(widget);

    final listFinder = find.byKey(const Key('products_list'));
    final toTopButton = find.byKey(const Key('back_to_top_button'));

    // scrollable finders
    final scrollable = find.byWidgetPredicate((w) => w is Scrollable);
    final scrollableOfList =
        find.descendant(of: listFinder, matching: scrollable);

    expect(toTopButton, findsNothing);

    // Scroll until the item to be found appears.
    await tester.scrollUntilVisible(toTopButton, 60,
        scrollable: scrollableOfList);
    await tester.pumpAndSettle();

    expect(toTopButton, findsOneWidget);
  });

  testWidgets('scroll to top button, scrolling to top',
      (WidgetTester tester) async {
    final widget = ShopProductRangePage.createForTesting(aShop);
    await tester.superPump(widget);

    final listFinder = find.byKey(const Key('products_list'));
    final toTopButton = find.byKey(const Key('back_to_top_button'));

    // scrollable finders
    final scrollable = find.byWidgetPredicate((w) => w is Scrollable);
    final scrollableOfList =
        find.descendant(of: listFinder, matching: scrollable);

    // Scroll until the item to be found appears.
    await tester.scrollUntilVisible(toTopButton, 60,
        scrollable: scrollableOfList);
    await tester.pumpAndSettle();

    expect(toTopButton, findsOneWidget);

    await tester.tap(toTopButton);
    await tester.pumpAndSettle();
    expect(toTopButton, findsNothing);
  });

  testWidgets('has shop address', (WidgetTester tester) async {
    commons.setConfirmedProducts(const []);
    commons.setSuggestedProducts(const {});

    final addressCompleter = Completer<void>();

    final widget = ShopProductRangePage.createForTesting(aShop,
        addressLoadFinishCallback: addressCompleter.complete);
    final context = await tester.superPump(widget);
    await tester.awaitableFutureFrom(addressCompleter.future);

    final expectedStr = AddressWidget.addressString(address, false, context)!;
    expect(find.richTextContaining(expectedStr), findsWidgets);
  });

  testWidgets('close screen button', (WidgetTester tester) async {
    final widget = ShopProductRangePage.createForTesting(aShop);
    await tester.superPump(widget);

    expect(find.byType(ShopProductRangePage), findsOneWidget);
    await tester.tap(find.byKey(const Key('close_button')));
    await tester.pumpAndSettle();
    expect(find.byType(ShopProductRangePage), findsNothing);
  });

  testWidgets('add product behaviour', (WidgetTester tester) async {
    final widget = ShopProductRangePage.createForTesting(aShop);
    final context = await tester.superPump(widget);

    expect(find.byType(BarcodeScanPage), findsNothing);
    await tester
        .tap(find.text(context.strings.shop_product_range_page_add_product));
    await tester.pumpAndSettle();
    expect(find.byType(BarcodeScanPage), findsOneWidget);

    final scanPage =
        find.byType(BarcodeScanPage).evaluate().first.widget as BarcodeScanPage;
    expect(scanPage.addProductToShop, equals(aShop));
  });

  testWidgets('no products', (WidgetTester tester) async {
    commons.setConfirmedProducts(const []);
    commons.setSuggestedProducts(const {});

    final widget = ShopProductRangePage.createForTesting(aShop);
    final context = await tester.superPump(widget);

    // No products title
    expect(
        find.text(
            context.strings.shop_product_range_page_this_shop_has_no_product),
        findsOneWidget);

    // No products at all
    for (final product in products) {
      expect(find.text(product.name!), findsNothing);
    }
  });

  testWidgets('network error', (WidgetTester tester) async {
    shopsManager.setShopRange(
        aShop.osmUID, Err(ShopsManagerError.NETWORK_ERROR));

    final widget = ShopProductRangePage.createForTesting(aShop);
    final context = await tester.superPump(widget);

    // Network error
    expect(find.text(context.strings.global_network_error), findsOneWidget);
    // No products
    for (final product in products) {
      expect(find.text(product.name!), findsNothing);
    }

    // Try again!
    shopsManager.setShopRange(aShop.osmUID, Ok(range));
    shopsManager.clear_verifiedCalls();

    await tester.tap(find.text(context.strings.global_try_again));
    await tester.pumpAndSettle();

    // Another request!
    shopsManager.verity_fetchShopProductRange_called();
    // All products!
    for (final product in products) {
      expect(find.text(product.name!), findsOneWidget);
    }
  });

  testWidgets('other error', (WidgetTester tester) async {
    shopsManager.setShopRange(aShop.osmUID, Err(ShopsManagerError.OTHER));

    final widget = ShopProductRangePage.createForTesting(aShop);
    final context = await tester.superPump(widget);

    // An error
    expect(
        find.text(context.strings.global_something_went_wrong), findsOneWidget);
    // No products
    for (final product in products) {
      expect(find.text(product.name!), findsNothing);
    }
    // No try again button
    expect(find.text(context.strings.global_try_again), findsNothing);
  });

  /// Oh boi, ain't that a very fragile test
  Future<void> testProductUpdateAfterClick(WidgetTester tester, Product product,
      [Key? key]) async {
    final widget = ShopProductRangePage.createForTesting(aShop, key: key);
    final context = await tester.superPump(widget);

    var card = find.byType(ProductCard).evaluate().first.widget;
    // Verify the proper product
    expect(
        find.descendant(
            of: find.byWidget(card), matching: find.text(product.name!)),
        findsOneWidget);
    // Verify initial status
    expect(
        find.descendant(
            of: find.byWidget(card),
            matching: find.text(
                context.strings.veg_status_displayed_vegan_status_possible)),
        findsOneWidget);

    expect(find.byType(DisplayProductPage), findsNothing);
    await tester.tap(find.text(product.name!));
    await tester.pumpAndSettle();
    expect(find.byType(DisplayProductPage), findsOneWidget);

    await tester.tap(find.text(
        context.strings.display_product_page_click_to_help_with_veg_statuses));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('vegan_positive_btn')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('done_btn')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('back_button')));
    await tester.pumpAndSettle();

    card = find.byType(ProductCard).evaluate().first.widget;
    // Verify the proper product
    expect(
        find.descendant(
            of: find.byWidget(card), matching: find.text(product.name!)),
        findsOneWidget);
    // Verify the change
    expect(
        find.descendant(
            of: find.byWidget(card),
            matching: find.text(context.strings.veg_status_displayed_vegan)),
        findsOneWidget);
  }

  testWidgets('confirmed product update after click',
      (WidgetTester tester) async {
    // Remove all suggested products
    commons.setSuggestedProducts(const {});

    expect(products[0].veganStatus, equals(VegStatus.possible));
    await testProductUpdateAfterClick(tester, products[0]);
  });

  testWidgets('suggested product update after click',
      (WidgetTester tester) async {
    for (final type in SuggestionType.values) {
      // Remove all confirmed products
      commons.setConfirmedProducts(const []);
      commons.setSuggestedProducts({
        type: commons.suggestedProducts,
      });

      expect(
          commons.suggestedProducts[0].veganStatus, equals(VegStatus.possible));
      await testProductUpdateAfterClick(
          tester, commons.suggestedProducts[0], Key(type.toString()));
    }
  });

  testWidgets('non-vegan products are not shown to a vegan',
      (WidgetTester tester) async {
    final products = [
      ProductLangSlice((v) => v
        ..barcode = '123'
        ..name = 'Milk apple'
        ..imageFront = Uri.file(File('./test/assets/img.jpg').absolute.path)
        ..veganStatus = VegStatus.negative
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
    commons.setConfirmedProducts(products);

    final veganUser = UserParams((v) => v.name = 'Bob');
    await userParamsController.setUserParams(veganUser);

    final widget = ShopProductRangePage.createForTesting(aShop);
    await tester.superPump(widget);

    expect(find.text(products[0].name!), findsNothing);
    expect(find.text(products[1].name!), findsOneWidget);
  });
}
