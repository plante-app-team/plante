import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plante/model/shop.dart';
import 'package:plante/outside/products/suggestions/suggestion_type.dart';
import 'package:plante/ui/map/components/map_filter_check_button.dart';
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
  late List<Shop> emptyShops;
  late List<Shop> notEmptyShops;

  setUp(() async {
    commons = MapPageModesTestCommons();
    await commons.setUp();
    mapController = commons.mapController;
    shops = commons.shops;
    analytics = commons.analytics;
    suggestedProductsManager = commons.suggestedProductsManager;

    emptyShops = shops.where((shop) => shop.productsCount <= 0).toList();
    notEmptyShops = shops.where((shop) => !emptyShops.contains(shop)).toList();
    expect(emptyShops.length, greaterThan(0));
    expect(notEmptyShops.length, greaterThan(0));
  });

  T firstWidgetWith<T extends Widget>(String keyStr) {
    return find.byKey(Key(keyStr)).evaluate().first.widget as T;
  }

  testWidgets('User selects to display not empty shops',
      (WidgetTester tester) async {
    final widget = MapPage(mapControllerForTesting: mapController);
    await commons.initIdleMapPage(widget, tester);

    var displayedShops = widget.getDisplayedShopsForTesting();
    expect(displayedShops.length, equals(shops.length));
    expect(displayedShops, containsAll(shops));

    await tester
        .superTap(find.byKey(const Key('button_filter_not_empty_shops')));

    displayedShops = widget.getDisplayedShopsForTesting();
    expect(displayedShops.length, lessThan(shops.length));
  });

  testWidgets(
      'shops with suggested products only - are displayed as shops with products',
      (WidgetTester tester) async {
    suggestedProductsManager.clearAllSuggestions();
    // Now empty shops have some suggested products
    emptyShops.forEach((shop) => suggestedProductsManager.setSuggestionsForShop(
        shop.osmUID, ['123', '321'], SuggestionType.RADIUS));

    final widget = await commons.createIdleMapPage(tester);

    // Shops with suggestions but with 0 products are displayed
    final displayedShops = widget.getDisplayedShopsForTesting();
    emptyShops.forEach((shop) => expect(displayedShops, contains(shop)));
  });

  Future<void> filterEventsTest(
    WidgetTester tester, {
    required String key,
    required bool enabledByDefault,
    required String eventShown,
  }) async {
    await commons.createIdleMapPage(tester);
    expect(analytics.allEvents(), equals([]));

    if (enabledByDefault) {
      // Ensure the enabled-by-default filter does nothing when clicked
      await tester.tapMapFilter(key);
      expect(analytics.allEvents(), equals([]));

      // Let's disable it!
      final String anotherFilter;
      if (key == 'button_filter_all_shops') {
        anotherFilter = 'button_filter_not_empty_shops';
      } else {
        anotherFilter = 'button_filter_all_shops';
      }
      await tester.tapMapFilter(anotherFilter);
      analytics.clearEvents();
    }

    await tester.tapMapFilter(key);
    expect(analytics.wasEventSent(eventShown), equals(true));
    // Ensure it was the only event
    expect(analytics.allEvents().length, equals(1),
        reason: analytics.allEvents().toString());
  }

  testWidgets('all filters analytics', (WidgetTester tester) async {
    await filterEventsTest(
      tester,
      key: 'button_filter_all_shops',
      enabledByDefault: true,
      eventShown: 'all_shops_shown',
    );
  });

  testWidgets('not empty shops filter analytics', (WidgetTester tester) async {
    await filterEventsTest(
      tester,
      key: 'button_filter_not_empty_shops',
      enabledByDefault: false,
      eventShown: 'shops_with_products_shown',
    );
  });

  testWidgets('shops filters are stored persistently',
      (WidgetTester tester) async {
    var widget = MapPage(
        key: const Key('page1'), mapControllerForTesting: mapController);
    await commons.initIdleMapPage(widget, tester);

    var checkboxNotEmptyShops =
        firstWidgetWith<MapFilterCheckButton>('button_filter_not_empty_shops');
    var checkboxAllShops =
        firstWidgetWith<MapFilterCheckButton>('button_filter_all_shops');
    expect(checkboxNotEmptyShops.checked, isFalse);
    expect(checkboxAllShops.checked, isTrue);

    await tester.tapMapFilter('button_filter_not_empty_shops');

    // Verify the values are changed
    checkboxNotEmptyShops =
        firstWidgetWith<MapFilterCheckButton>('button_filter_not_empty_shops');
    checkboxAllShops =
        firstWidgetWith<MapFilterCheckButton>('button_filter_all_shops');
    expect(checkboxNotEmptyShops.checked, isTrue);
    expect(checkboxAllShops.checked, isFalse);

    // Create a new page
    widget = MapPage(
        key: const Key('page2'), mapControllerForTesting: mapController);
    await commons.initIdleMapPage(widget, tester);

    // Verify the values are still the same
    checkboxNotEmptyShops =
        firstWidgetWith<MapFilterCheckButton>('button_filter_not_empty_shops');
    checkboxAllShops =
        firstWidgetWith<MapFilterCheckButton>('button_filter_all_shops');
    expect(checkboxNotEmptyShops.checked, isTrue);
    expect(checkboxAllShops.checked, isFalse);
  });
}

extension on WidgetTester {
  Future<void> dragToMapFilter(String key) async {
    final filterList = find.byKey(const Key('filter_listview'));

    // The drag will stop when the filter is visible, so we drag
    // both ways - the target filter is either on the left or
    // on the right side

    // Right
    await superDragUntilVisible(
        find.byKey(Key(key)), filterList, const Offset(-500, 0));
    // Left
    await superDragUntilVisible(
        find.byKey(Key(key)), filterList, const Offset(500, 0));
  }

  Future<void> tapMapFilter(String key) async {
    await dragToMapFilter(key);
    await superTap(find.byKey(Key(key)));
  }
}
