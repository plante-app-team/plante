import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plante/l10n/strings.dart';
import 'package:plante/model/shop.dart';
import 'package:plante/outside/products/suggestions/suggestion_type.dart';
import 'package:plante/ui/map/components/map_shops_filter_checkbox.dart';
import 'package:plante/ui/map/map_page/map_page.dart';
import 'package:plante/ui/map/map_page/map_page_testing_storage.dart';

import '../../../common_finders_extension.dart';
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

  testWidgets('empty shops are displayed only when user wants',
      (WidgetTester tester) async {
    expect(shops[0].productsCount, equals(0));

    final widget = MapPage(mapControllerForTesting: mapController);
    final context = await commons.initIdleMapPage(widget, tester);

    var displayedShops = widget.getDisplayedShopsForTesting();
    expect(displayedShops.length, lessThan(shops.length));

    await tester.superTap(find.byKey(const Key('filter_shops_icon')));
    await tester.superTap(
        find.richTextContaining(context.strings.map_page_filter_empty_shops));

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

    await tester.superTap(find.byKey(const Key('filter_shops_icon')));
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

    await tester.superTap(find.byKey(const Key('filter_shops_icon')));
    await tester
        .superTap(find.byKey(const Key('checkbox_filter_not_empty_shops')));

    // Not empty shops are no longer displayed
    displayedShops = widget.getDisplayedShopsForTesting();
    expect(displayedShops, isNot(equals(notEmptyShops)));
    for (final shop in notEmptyShops) {
      expect(displayedShops, isNot(contains(shop)));
    }
  });

  Future<void> shopFilterTest(WidgetTester tester,
      {required String filterText,
      required bool enabledByDefault,
      required String eventShown,
      required String eventHidden}) async {
    expect(analytics.allEvents(), equals([]));

    await tester.superTap(find.byKey(const Key('filter_shops_icon')));
    await tester.superTap(find.richTextContaining(filterText));

    expect(analytics.wasEventSent(eventShown), equals(!enabledByDefault));
    expect(analytics.wasEventSent(eventHidden), equals(enabledByDefault));
    analytics.clearEvents();

    await tester.superTap(find.richTextContaining(filterText));

    expect(analytics.wasEventSent(eventShown), equals(enabledByDefault));
    expect(analytics.wasEventSent(eventHidden), equals(!enabledByDefault));
  }

  testWidgets('not empty shops filter analytics', (WidgetTester tester) async {
    final widget = MapPage(mapControllerForTesting: mapController);
    final context = await commons.initIdleMapPage(widget, tester);
    await shopFilterTest(
      tester,
      filterText: context.strings.map_page_filter_not_empty_shops,
      enabledByDefault: true,
      eventShown: 'shops_with_products_shown',
      eventHidden: 'shops_with_products_hidden',
    );
  });

  testWidgets('suggested radius shops filter analytics',
      (WidgetTester tester) async {
    final widget = MapPage(mapControllerForTesting: mapController);
    final context = await commons.initIdleMapPage(widget, tester);
    await shopFilterTest(
      tester,
      filterText:
          context.strings.map_page_filter_shops_with_radius_suggested_products,
      enabledByDefault: true,
      eventShown: 'shops_with_rad_suggestions_shown',
      eventHidden: 'shops_with_rad_suggestions_hidden',
    );
  });

  testWidgets('suggested OFF shops filter analytics',
      (WidgetTester tester) async {
    final widget = MapPage(mapControllerForTesting: mapController);
    final context = await commons.initIdleMapPage(widget, tester);
    await shopFilterTest(
      tester,
      filterText:
          context.strings.map_page_filter_shops_with_off_suggested_products,
      enabledByDefault: true,
      eventShown: 'shops_with_off_suggestions_shown',
      eventHidden: 'shops_with_off_suggestions_hidden',
    );
  });

  testWidgets('empty shops filter analytics', (WidgetTester tester) async {
    final widget = MapPage(mapControllerForTesting: mapController);
    final context = await commons.initIdleMapPage(widget, tester);
    await shopFilterTest(
      tester,
      filterText: context.strings.map_page_filter_empty_shops,
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

    await tester.superTap(find.byKey(const Key('filter_shops_icon')));

    // Verify initial values
    var checkboxNotEmptyShops = firstWidgetWith<MapShopsFilterCheckbox>(
        'checkbox_filter_not_empty_shops');
    var checkboxSuggestionsOFF = firstWidgetWith<MapShopsFilterCheckbox>(
        'filter_shops_with_off_suggested_products');
    var checkboxSuggestionsRad = firstWidgetWith<MapShopsFilterCheckbox>(
        'filter_shops_with_rad_suggested_products');
    var checkboxEmptyShops =
        firstWidgetWith<MapShopsFilterCheckbox>('filter_empty_shops');
    expect(checkboxNotEmptyShops.value, isTrue);
    expect(checkboxSuggestionsOFF.value, isTrue);
    expect(checkboxSuggestionsRad.value, isTrue);
    expect(checkboxEmptyShops.value, isFalse);

    // Change each value
    await tester
        .superTap(find.byKey(const Key('checkbox_filter_not_empty_shops')));
    await tester.superTap(
        find.byKey(const Key('filter_shops_with_off_suggested_products')));
    await tester.superTap(
        find.byKey(const Key('filter_shops_with_rad_suggested_products')));
    await tester.superTap(find.byKey(const Key('filter_empty_shops')));

    // Verify each value is changed
    checkboxNotEmptyShops = firstWidgetWith<MapShopsFilterCheckbox>(
        'checkbox_filter_not_empty_shops');
    checkboxSuggestionsOFF = firstWidgetWith<MapShopsFilterCheckbox>(
        'filter_shops_with_off_suggested_products');
    checkboxSuggestionsRad = firstWidgetWith<MapShopsFilterCheckbox>(
        'filter_shops_with_rad_suggested_products');
    checkboxEmptyShops =
        firstWidgetWith<MapShopsFilterCheckbox>('filter_empty_shops');
    expect(checkboxNotEmptyShops.value, isFalse);
    expect(checkboxSuggestionsOFF.value, isFalse);
    expect(checkboxSuggestionsRad.value, isFalse);
    expect(checkboxEmptyShops.value, isTrue);

    // Create a new page
    widget = MapPage(
        key: const Key('page2'), mapControllerForTesting: mapController);
    await commons.initIdleMapPage(widget, tester);

    // Verify each value is still the same
    checkboxNotEmptyShops = firstWidgetWith<MapShopsFilterCheckbox>(
        'checkbox_filter_not_empty_shops');
    checkboxSuggestionsOFF = firstWidgetWith<MapShopsFilterCheckbox>(
        'filter_shops_with_off_suggested_products');
    checkboxSuggestionsRad = firstWidgetWith<MapShopsFilterCheckbox>(
        'filter_shops_with_rad_suggested_products');
    checkboxEmptyShops =
        firstWidgetWith<MapShopsFilterCheckbox>('filter_empty_shops');
    expect(checkboxNotEmptyShops.value, isFalse);
    expect(checkboxSuggestionsOFF.value, isFalse);
    expect(checkboxSuggestionsRad.value, isFalse);
    expect(checkboxEmptyShops.value, isTrue);
  });
}
