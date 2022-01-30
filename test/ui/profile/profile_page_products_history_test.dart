import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mockito/mockito.dart';
import 'package:plante/l10n/strings.dart';
import 'package:plante/model/lang_code.dart';
import 'package:plante/model/product_lang_slice.dart';
import 'package:plante/model/user_params.dart';
import 'package:plante/model/veg_status.dart';
import 'package:plante/model/veg_status_source.dart';
import 'package:plante/model/viewed_products_storage.dart';
import 'package:plante/ui/profile/profile_page.dart';

import '../../common_mocks.mocks.dart';
import '../../widget_tester_extension.dart';
import '../../z_fakes/fake_analytics.dart';
import 'profile_page_test_commons.dart';

void main() {
  late ProfilePageTestCommons commons;
  late ViewedProductsStorage viewedProductsStorage;
  late FakeAnalytics analytics;

  setUp(() async {
    commons = await ProfilePageTestCommons.create();
    await commons.userParamsController
        .setUserParams(UserParams((e) => e.name = 'Bob Kelso'));
    viewedProductsStorage = commons.viewedProductsStorage;
    analytics = commons.analytics;
  });

  testWidgets('can switch to history by button', (WidgetTester tester) async {
    final page = ProfilePage();
    final context = await tester.superPump(page);

    expect(page.displayedProductsList(),
        equals(ProfilePageProductsList.MY_PRODUCTS));
    await tester
        .superTap(find.text(context.strings.profile_page_products_history));
    expect(
        page.displayedProductsList(), equals(ProfilePageProductsList.HISTORY));
  });

  testWidgets('can switch to history by swiping', (WidgetTester tester) async {
    final page = ProfilePage();
    await tester.superPump(page);

    expect(page.displayedProductsList(),
        equals(ProfilePageProductsList.MY_PRODUCTS));
    await tester.drag(find.byKey(const Key('products_lists_page_view')),
        const Offset(-1000, 0));
    expect(
        page.displayedProductsList(), equals(ProfilePageProductsList.HISTORY));
  });

  testWidgets('history is loaded only once, when opened',
      (WidgetTester tester) async {
    final product = ProductLangSlice((e) => e
      ..lang = LangCode.en
      ..barcode = '123'
      ..name = 'Product name'
      ..imageFront = Uri.file('/tmp/asd')
      ..imageIngredients = Uri.file('/tmp/asd')
      ..ingredientsText = 'beans'
      ..veganStatus = VegStatus.positive
      ..veganStatusSource = VegStatusSource.community).buildSingleLangProduct();

    GetIt.I.unregister(instance: viewedProductsStorage);
    viewedProductsStorage = MockViewedProductsStorage();
    GetIt.I.registerSingleton<ViewedProductsStorage>(viewedProductsStorage);

    var productsRequestsCount = 0;
    when(viewedProductsStorage.getProducts()).thenAnswer((_) {
      productsRequestsCount += 1;
      return [product];
    });
    when(viewedProductsStorage.updates())
        .thenAnswer((_) => const Stream.empty());

    final page = ProfilePage();
    final context = await tester.superPump(page);
    expect(page.displayedProductsList(),
        equals(ProfilePageProductsList.MY_PRODUCTS));

    // No loads yet
    expect(productsRequestsCount, equals(0));

    // Open history products
    await tester
        .superTap(find.text(context.strings.profile_page_products_history));
    expect(
        page.displayedProductsList(), equals(ProfilePageProductsList.HISTORY));

    // 1 load now
    expect(productsRequestsCount, equals(1));

    // Return to 'my products' and back to history
    await tester
        .superTap(find.text(context.strings.profile_page_products_my_products));
    expect(page.displayedProductsList(),
        equals(ProfilePageProductsList.MY_PRODUCTS));
    await tester
        .superTap(find.text(context.strings.profile_page_products_history));
    expect(
        page.displayedProductsList(), equals(ProfilePageProductsList.HISTORY));

    // Still just one load
    expect(productsRequestsCount, equals(1));
  });

  testWidgets('analytics event is sent when history opened',
      (WidgetTester tester) async {
    final page = ProfilePage();
    final context = await tester.superPump(page);

    expect(analytics.allEvents(), isEmpty);
    expect(analytics.wasEventSent('profile_products_switch_history'), isFalse);

    await tester
        .superTap(find.text(context.strings.profile_page_products_history));
    expect(
        page.displayedProductsList(), equals(ProfilePageProductsList.HISTORY));

    expect(analytics.allEvents(), isNot(isEmpty));
    expect(analytics.allEvents().length, equals(1),
        reason: analytics.allEvents().toString());
    expect(analytics.wasEventSent('profile_products_switch_history'), isTrue);
  });
}
