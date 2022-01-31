import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plante/model/shop.dart';
import 'package:plante/outside/products/suggestions/suggestion_type.dart';
import 'package:plante/ui/base/components/check_button_plante.dart';
import 'package:plante/ui/map/map_page/map_page.dart';
import 'package:plante/ui/map/map_page/map_page_testing_storage.dart';

import '../../../common_mocks.mocks.dart';
import '../../../widget_tester_extension.dart';
import '../../../z_fakes/fake_analytics.dart';
import '../../../z_fakes/fake_suggested_products_manager.dart';
import 'map_page_modes_test_commons.dart';

void main() {
  late MapPageModesTestCommons commons;
  late MockGoogleMapController mapController;
  late FakeAnalytics analytics;
  late FakeSuggestedProductsManager suggestedProductsManager;
  late List<Shop> shops;

  setUp(() async {
    commons = MapPageModesTestCommons();
    await commons.setUp();
    mapController = commons.mapController;
    shops = commons.shops;
    analytics = commons.analytics;
    suggestedProductsManager = commons.suggestedProductsManager;
  });

  T firstWidgetWith<T extends Widget>(String keyStr) {
    return find.byKey(Key(keyStr)).evaluate().first.widget as T;
  }

  testWidgets('User selects to display all shops', (WidgetTester tester) async {
    expect(shops[0].productsCount, equals(0));

    final widget = MapPage(mapControllerForTesting: mapController);
    await commons.initIdleMapPage(widget, tester);

    var displayedShops = widget.getDisplayedShopsForTesting();
    expect(displayedShops.length, lessThan(shops.length));

    await tester.superTap(find.byKey(const Key('button_filter_all_shops')));

    displayedShops = widget.getDisplayedShopsForTesting();
    expect(displayedShops.length, equals(shops.length));
    expect(displayedShops, containsAll(shops));
  });

  testWidgets('empty shops are displayed only when user wants',
      (WidgetTester tester) async {
    expect(shops[0].productsCount, equals(0));

    final widget = MapPage(mapControllerForTesting: mapController);
    await commons.initIdleMapPage(widget, tester);

    var displayedShops = widget.getDisplayedShopsForTesting();
    expect(displayedShops.length, lessThan(shops.length));

    final filterList = find.byKey(const Key('filter_listview'));
    await tester.dragUntilVisible(find.byKey(const Key('filter_empty_shops')),
        filterList, const Offset(-500, 0));
    await tester.pumpAndSettle();
    await tester.superTap(find.byKey(const Key('filter_empty_shops')));

    displayedShops = widget.getDisplayedShopsForTesting();
    expect(displayedShops.length, equals(shops.length));
    expect(displayedShops, containsAll(shops));
  });

  Future<void> userCanDisableSuggestions(WidgetTester tester,
      {required String filterKey, required SuggestionType type}) async {
    suggestedProductsManager.clearAllSuggestions();
    // Now shop[0] has some suggested products
    suggestedProductsManager.setSuggestionsForShop(
        shops[0].osmUID, ['123', '321'], type);

    final widget =
        await commons.createIdleMapPage(tester, key: Key('map_for_$filterKey'));

    // Shop[0] is displayed
    var displayedShops = widget.getDisplayedShopsForTesting();
    expect(displayedShops, contains(shops[0]));

    final filterList = find.byKey(const Key('filter_listview'));
    await tester.dragUntilVisible(
        find.byKey(Key(filterKey)), filterList, const Offset(-500, 0));
    await tester.pumpAndSettle();

    await tester.superTap(find.byKey(Key(filterKey)));
    await tester.pageBack();

    // Shop[0] is no longer displayed
    displayedShops = widget.getDisplayedShopsForTesting();
    expect(displayedShops, isNot(contains(shops[0])));
  }

  testWidgets('user can disable display of shops with suggested products',
      (WidgetTester tester) async {
    for (final type in SuggestionType.values) {
      final String filterKey;
      switch (type) {
        case SuggestionType.OFF:
          filterKey = 'filter_shops_with_off_suggested_products';
          break;
        case SuggestionType.RADIUS:
          filterKey = 'filter_shops_with_rad_suggested_products';
          break;
      }

      await userCanDisableSuggestions(tester, filterKey: filterKey, type: type);
    }
  });

  testWidgets('user can disable display of shops with confirmed products',
      (WidgetTester tester) async {
    final widget = await commons.createIdleMapPage(tester);
    final notEmptyShops = shops.where((shop) => 0 < shop.productsCount).toSet();

    // Not empty shops are displayed
    var displayedShops = widget.getDisplayedShopsForTesting();
    expect(displayedShops, equals(notEmptyShops));

    await tester
        .superTap(find.byKey(const Key('button_filter_not_empty_shops')));

    // Not empty shops are no longer displayed
    displayedShops = widget.getDisplayedShopsForTesting();
    expect(displayedShops, isNot(equals(notEmptyShops)));
    for (final shop in notEmptyShops) {
      expect(displayedShops, isNot(contains(shop)));
    }
  });

  Future<void> shopFilterTest(WidgetTester tester,
      {required String key,
      required bool enabledByDefault,
      required String eventShown,
      required String eventHidden}) async {
    await commons.createIdleMapPage(tester);
    expect(analytics.allEvents(), equals([]));

    final filterList = find.byKey(const Key('filter_listview'));
    await tester.dragUntilVisible(
        find.byKey(Key(key)), filterList, const Offset(-500, 0));
    await tester.pumpAndSettle();

    await tester.superTap(find.byKey(Key(key)));

    expect(analytics.wasEventSent(eventShown), equals(!enabledByDefault));
    expect(analytics.wasEventSent(eventHidden), equals(enabledByDefault));
    analytics.clearEvents();

    await tester.superTap(find.byKey(Key(key)));

    expect(analytics.wasEventSent(eventShown), equals(enabledByDefault));
    expect(analytics.wasEventSent(eventHidden), equals(!enabledByDefault));
  }

  testWidgets('all filters analytics', (WidgetTester tester) async {
    await shopFilterTest(
      tester,
      key: 'button_filter_all_shops',
      enabledByDefault: false,
      eventShown: 'all_shops_shown',
      eventHidden: 'all_shops_hidden',
    );
  });

  testWidgets('not empty shops filter analytics', (WidgetTester tester) async {
    await shopFilterTest(
      tester,
      key: 'button_filter_not_empty_shops',
      enabledByDefault: true,
      eventShown: 'shops_with_products_shown',
      eventHidden: 'shops_with_products_hidden',
    );
  });

  testWidgets('suggested radius shops filter analytics',
      (WidgetTester tester) async {
    await shopFilterTest(
      tester,
      key: 'filter_shops_with_rad_suggested_products',
      enabledByDefault: true,
      eventShown: 'shops_with_rad_suggestions_shown',
      eventHidden: 'shops_with_rad_suggestions_hidden',
    );
  });

  testWidgets('suggested OFF shops filter analytics',
      (WidgetTester tester) async {
    await shopFilterTest(
      tester,
      key: 'filter_shops_with_off_suggested_products',
      enabledByDefault: true,
      eventShown: 'shops_with_off_suggestions_shown',
      eventHidden: 'shops_with_off_suggestions_hidden',
    );
  });

  testWidgets('empty shops filter analytics', (WidgetTester tester) async {
    await shopFilterTest(
      tester,
      key: 'filter_empty_shops',
      enabledByDefault: false,
      eventShown: 'empty_shops_shown',
      eventHidden: 'empty_shops_hidden',
    );
  });

  testWidgets('shops filters are stored persistently',
      (WidgetTester tester) async {
    var widget = MapPage(
        key: const Key('page1'), mapControllerForTesting: mapController);
    await commons.initIdleMapPage(widget, tester);
    final filterList = find.byKey(const Key('filter_listview'));

    // check not empty shops filter
    var checkboxNotEmptyShops =
        firstWidgetWith<CheckButtonPlante>('button_filter_not_empty_shops');
    expect(checkboxNotEmptyShops.checked, isTrue);
    await tester
        .superTap(find.byKey(const Key('button_filter_not_empty_shops')));
    // Verify each value is changed
    checkboxNotEmptyShops =
        firstWidgetWith<CheckButtonPlante>('button_filter_not_empty_shops');
    expect(checkboxNotEmptyShops.checked, isFalse);

    //test rad filter
    await tester.dragUntilVisible(
        find.byKey(const Key('filter_shops_with_rad_suggested_products')),
        filterList,
        const Offset(-500, 0));
    await tester.pumpAndSettle();
    var checkboxSuggestionsRad = firstWidgetWith<CheckButtonPlante>(
        'filter_shops_with_rad_suggested_products');
    expect(checkboxSuggestionsRad.checked, isTrue);
    //change rad value
    await tester.superTap(
        find.byKey(const Key('filter_shops_with_rad_suggested_products')));
    checkboxSuggestionsRad = firstWidgetWith<CheckButtonPlante>(
        'filter_shops_with_rad_suggested_products');
    expect(checkboxSuggestionsRad.checked, isFalse);

    //Test Off filter
    await tester.dragUntilVisible(
        find.byKey(const Key('filter_shops_with_off_suggested_products')),
        filterList,
        const Offset(-500, 0));
    await tester.pumpAndSettle();
    var buttonSuggestionsoff = firstWidgetWith<CheckButtonPlante>(
        'filter_shops_with_off_suggested_products');
    expect(buttonSuggestionsoff.checked, isTrue);
    //change value off filter
    await tester.superTap(
        find.byKey(const Key('filter_shops_with_off_suggested_products')));
    buttonSuggestionsoff = firstWidgetWith<CheckButtonPlante>(
        'filter_shops_with_off_suggested_products');
    expect(buttonSuggestionsoff.checked, isFalse);
    //Test empty shops filter
    await tester.dragUntilVisible(find.byKey(const Key('filter_empty_shops')),
        filterList, const Offset(-500, 0));
    await tester.pumpAndSettle();
    var buttonEmptyShops =
        firstWidgetWith<CheckButtonPlante>('filter_empty_shops');
    expect(buttonEmptyShops.checked, isFalse);
    //change value empty shops
    await tester.superTap(find.byKey(const Key('filter_empty_shops')));
    buttonEmptyShops = firstWidgetWith<CheckButtonPlante>('filter_empty_shops');
    expect(buttonEmptyShops.checked, isTrue);

    // Create a new page
    widget = MapPage(
        key: const Key('page2'), mapControllerForTesting: mapController);
    await commons.initIdleMapPage(widget, tester);

    // Verify each value is still the same
    checkboxNotEmptyShops =
        firstWidgetWith<CheckButtonPlante>('button_filter_not_empty_shops');
    expect(checkboxNotEmptyShops.checked, isFalse);

    await tester.dragUntilVisible(
        find.byKey(const Key('filter_shops_with_rad_suggested_products')),
        filterList,
        const Offset(-500, 0));
    await tester.pumpAndSettle();
    checkboxSuggestionsRad = firstWidgetWith<CheckButtonPlante>(
        'filter_shops_with_rad_suggested_products');
    expect(checkboxSuggestionsRad.checked, isFalse);

    await tester.dragUntilVisible(
        find.byKey(const Key('filter_shops_with_off_suggested_products')),
        filterList,
        const Offset(-500, 0));
    await tester.pumpAndSettle();
    buttonSuggestionsoff = firstWidgetWith<CheckButtonPlante>(
        'filter_shops_with_off_suggested_products');
    expect(buttonSuggestionsoff.checked, isFalse);

    await tester.dragUntilVisible(find.byKey(const Key('filter_empty_shops')),
        filterList, const Offset(-500, 0));
    await tester.pumpAndSettle();
    buttonEmptyShops = firstWidgetWith<CheckButtonPlante>('filter_empty_shops');
    expect(buttonEmptyShops.checked, isTrue);
  });
}
