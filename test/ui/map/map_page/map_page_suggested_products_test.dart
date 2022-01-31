import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mockito/mockito.dart';
import 'package:plante/base/result.dart';
import 'package:plante/l10n/strings.dart';
import 'package:plante/model/shop.dart';
import 'package:plante/outside/products/suggestions/suggested_products_manager.dart';
import 'package:plante/outside/products/suggestions/suggestion_type.dart';
import 'package:plante/outside/products/suggestions/suggestions_for_shop.dart';
import 'package:plante/ui/map/map_page/map_page.dart';
import 'package:plante/ui/map/map_page/map_page_mode.dart';
import 'package:plante/ui/map/map_page/map_page_mode_default.dart';
import 'package:plante/ui/map/map_page/map_page_model.dart';
import 'package:plante/ui/map/map_page/map_page_testing_storage.dart';

import '../../../common_mocks.mocks.dart';
import '../../../z_fakes/fake_suggested_products_manager.dart';
import 'map_page_modes_test_commons.dart';

typedef _SuggestionsStream = StreamController<
    Result<SuggestionsForShop, SuggestedProductsManagerError>>;

void main() {
  late MapPageModesTestCommons commons;
  late MockGoogleMapController mapController;
  late FakeSuggestedProductsManager suggestedProductsManager;
  late List<Shop> shops;

  setUp(() async {
    commons = MapPageModesTestCommons();
    await commons.setUp();
    mapController = commons.mapController;
    suggestedProductsManager = commons.suggestedProductsManager;
    shops = commons.shops;
  });

  testWidgets('markers of suggested products are shown on the map',
      (WidgetTester tester) async {
    expect(shops[0].productsCount, equals(0));

    for (final type in SuggestionType.values) {
      final mapKeyPrefix = type.toString();
      suggestedProductsManager.clearAllSuggestions();

      // Map 1
      var widget = await commons.createIdleMapPage(tester,
          key: Key('${mapKeyPrefix}map1'));

      // Shop[0] is not displayed because it has 0 products
      var displayedShops = widget.getDisplayedShopsForTesting();
      expect(displayedShops, isNot(contains(shops[0])));

      // Now shop[0] has some suggested products
      suggestedProductsManager.setSuggestionsForShop(
          shops[0].osmUID, ['123', '321'], type);

      // Map 2
      widget = await commons.createIdleMapPage(tester,
          key: Key('${mapKeyPrefix}map2'));

      // Shop[0] is now displayed because it has several suggestions
      displayedShops = widget.getDisplayedShopsForTesting();
      expect(displayedShops, contains(shops[0]));
    }
  });

  testWidgets('suggested products marker click', (WidgetTester tester) async {
    for (final type in SuggestionType.values) {
      suggestedProductsManager.clearAllSuggestions();
      suggestedProductsManager.setSuggestionsForShop(
          shops[0].osmUID, ['123', '321'], type);

      final mapKey = type.toString();
      final widget =
          MapPage(mapControllerForTesting: mapController, key: Key(mapKey));
      final context = await commons.initIdleMapPage(widget, tester);

      expect(
          find.text(context.strings.shop_card_products_listed), findsNothing);
      widget.onMarkerClickForTesting([shops[0]]);
      await tester.pumpAndSettle();
      expect(
          find.text(context.strings.shop_card_products_listed), findsOneWidget);
    }
  });

  testWidgets('markers of suggested products are loaded gradually',
      (WidgetTester tester) async {
    final suggestionsStream = _SuggestionsStream();
    final suggestedProductsManager = MockSuggestedProductsManager();
    when(suggestedProductsManager.getSuggestedBarcodes(any, any, any,
            types: anyNamed('types')))
        .thenAnswer((_) {
      return suggestionsStream.stream;
    });
    GetIt.I.unregister(instance: commons.suggestedProductsManager);
    GetIt.I
        .registerSingleton<SuggestedProductsManager>(suggestedProductsManager);

    // Remove all products from shops so that suggestions
    // testing would be more convenient - shops without products are
    // not displayed on the map by default, but shops with suggestions are.
    final shops =
        commons.shops.map((e) => e.rebuildWith(productsCount: 0)).toList();
    await commons.replaceFetchedShops(shops, tester);

    final pushSuggestion = (SuggestionsForShop suggestion) async {
      await tester.runAsync(() async => suggestionsStream.add(Ok(suggestion)));
      await tester.pumpAndSettle();
    };
    final absorptionDelay = () async {
      await tester.runAsync(() async =>
          await Future.delayed(MapPageModel.delayBetweenSuggestionsAbsorption));
      await tester.pumpAndSettle();
    };

    // No markers at first
    final page = await commons.createIdleMapPage(tester);
    expect(page.getDisplayedShopsForTesting(), isEmpty);

    // Still no markers even after we push a suggestion - suggestions
    // are being loaded/absorbed gradually to not make the map freeze
    await pushSuggestion(
        SuggestionsForShop(shops[0].osmUID, SuggestionType.OFF, const ['123']));
    expect(page.getDisplayedShopsForTesting(), isEmpty);

    // Wait for the needed delay and push another suggestion - this time it
    // is expected to be displayed, because we waited the needed time.
    await absorptionDelay();
    await pushSuggestion(SuggestionsForShop(
        shops[1].osmUID, SuggestionType.RADIUS, const ['123']));
    expect(page.getDisplayedShopsForTesting(), equals([shops[0], shops[1]]));

    // Push a third suggestion, and check it's not displayed yet,
    // because no time was waited
    await pushSuggestion(
        SuggestionsForShop(shops[2].osmUID, SuggestionType.OFF, const ['123']));
    expect(page.getDisplayedShopsForTesting(), equals([shops[0], shops[1]]));

    // Now wait again, push again, and verify every suggestion is displayed
    await absorptionDelay();
    await pushSuggestion(SuggestionsForShop(
        shops[3].osmUID, SuggestionType.RADIUS, const ['123']));
    expect(page.getDisplayedShopsForTesting(),
        equals([shops[0], shops[1], shops[2], shops[3]]));

    await suggestionsStream.close();
  });

  testWidgets(
      'suggested products loading gets canceled and restarted on map moves',
      (WidgetTester tester) async {
    final suggestionsStreams = <_SuggestionsStream>[];
    final suggestedProductsManager = MockSuggestedProductsManager();
    when(suggestedProductsManager.getSuggestedBarcodes(any, any, any,
            types: anyNamed('types')))
        .thenAnswer((_) {
      suggestionsStreams.add(_SuggestionsStream());
      return suggestionsStreams.last.stream;
    });
    GetIt.I.unregister(instance: commons.suggestedProductsManager);
    GetIt.I
        .registerSingleton<SuggestedProductsManager>(suggestedProductsManager);

    final page = await commons.createIdleMapPage(tester);

    // Ensure the first stream is being listened to.
    expect(suggestionsStreams.length, equals(1));
    expect(suggestionsStreams[0].hasListener, isTrue);

    // Move camera
    await tester.runAsync(() async {
      await commons.moveCamera(commons.shopsBounds.center,
          MapPageMode.DEFAULT_MIN_ZOOM, page, tester);
    });

    // Ensure the first stream subscription has been canceled
    // and another stream has been requested.
    expect(suggestionsStreams.length, equals(2));
    expect(suggestionsStreams[0].hasListener, isFalse);
    expect(suggestionsStreams[1].hasListener, isTrue);
  });

  testWidgets('suggested products loading gets canceled on map zoom out',
      (WidgetTester tester) async {
    final suggestionsStreams = <_SuggestionsStream>[];
    final suggestedProductsManager = MockSuggestedProductsManager();
    when(suggestedProductsManager.getSuggestedBarcodes(any, any, any,
            types: anyNamed('types')))
        .thenAnswer((_) {
      suggestionsStreams.add(_SuggestionsStream());
      return suggestionsStreams.last.stream;
    });
    GetIt.I.unregister(instance: commons.suggestedProductsManager);
    GetIt.I
        .registerSingleton<SuggestedProductsManager>(suggestedProductsManager);

    final page = await commons.createIdleMapPage(tester);

    // Ensure the first stream is being listened to.
    expect(suggestionsStreams.length, equals(1));
    expect(suggestionsStreams[0].hasListener, isTrue);

    // Zoom out
    await tester.runAsync(() async {
      await commons.moveCamera(commons.shopsBounds.center,
          MapPageModeDefault.MIN_ZOOM, page, tester);
    });

    // Ensure the first stream subscription has been canceled
    // and another stream has not been requested yet.
    expect(suggestionsStreams.length, equals(1));
    expect(suggestionsStreams[0].hasListener, isFalse);

    // Map zoomed back in - we expect suggestions load to restart.
    await tester.runAsync(() async {
      await commons.moveCamera(commons.shopsBounds.center,
          MapPageMode.DEFAULT_MAX_ZOOM, page, tester);
    });

    // Ensure another suggestions loading has started.
    expect(suggestionsStreams.length, equals(2));
    expect(suggestionsStreams[0].hasListener, isFalse);
    expect(suggestionsStreams[1].hasListener, isTrue);
  });
}
