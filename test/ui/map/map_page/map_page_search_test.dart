import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:plante/model/coord.dart';
import 'package:plante/outside/map/osm/osm_road.dart';
import 'package:plante/ui/base/components/shop_card.dart';
import 'package:plante/ui/map/components/map_search_bar.dart';
import 'package:plante/ui/map/map_page/map_page_testing_storage.dart';
import 'package:plante/ui/map/search_page/map_search_page.dart';
import 'package:plante/ui/map/search_page/map_search_page_result.dart';
import 'package:plante/ui/map/search_page/map_search_result.dart';

import '../../../common_mocks.mocks.dart';
import '../../../widget_tester_extension.dart';
import 'map_page_modes_test_commons.dart';

void main() {
  late MapPageModesTestCommons commons;
  late MockGoogleMapController mapController;
  late MockLatestCameraPosStorage latestCameraPosStorage;

  final roads = [
    OsmRoad((e) => e
      ..osmId = '123321'
      ..name = 'cool road 1'
      ..latitude = 123
      ..longitude = 123),
    OsmRoad((e) => e
      ..osmId = '123321'
      ..name = 'cool road 2'
      ..latitude = 123
      ..longitude = 123),
  ];

  setUp(() async {
    commons = MapPageModesTestCommons();
    await commons.setUp();
    mapController = commons.mapController;
    latestCameraPosStorage = commons.latestCameraPosStorage;

    when(latestCameraPosStorage.getCached())
        .thenAnswer((_) => Coord(lat: 20, lon: 10));
    when(latestCameraPosStorage.get())
        .thenAnswer((_) async => Coord(lat: 20, lon: 10));
  });

  testWidgets('searchbar click opens search page', (WidgetTester tester) async {
    await commons.createIdleMapPage(tester);

    expect(find.byType(MapSearchPage), findsNothing);
    await tester.superTap(find.byType(MapSearchBar));
    expect(find.byType(MapSearchPage), findsOneWidget);
  });

  testWidgets('shop found', (WidgetTester tester) async {
    final widget = await commons.createIdleMapPage(tester);

    verifyNever(mapController.animateCamera(any));
    expect(find.byType(ShopCard), findsNothing);

    final shop = commons.shops.first;
    widget.onSearchResultsForTesting(
        MapSearchPageResult.create(chosenShops: [shop]));
    await tester.pumpAndSettle();

    verify(mapController.animateCamera(any));
    expect(find.byType(ShopCard), findsOneWidget);
  });

  testWidgets('many shops found', (WidgetTester tester) async {
    final widget = await commons.createIdleMapPage(tester);

    verifyNever(mapController.animateCamera(any));
    expect(find.byType(ShopCard), findsNothing);

    widget.onSearchResultsForTesting(
        MapSearchPageResult.create(chosenShops: commons.shops));
    await tester.pumpAndSettle();

    verify(mapController.animateCamera(any));
    expect(find.byType(ShopCard, skipOffstage: false),
        findsNWidgets(commons.shops.length));
  });

  testWidgets('road found', (WidgetTester tester) async {
    final widget = await commons.createIdleMapPage(tester);

    verifyNever(mapController.animateCamera(any));

    widget.onSearchResultsForTesting(
        MapSearchPageResult.create(chosenRoad: roads[0]));
    await tester.pumpAndSettle();

    verify(mapController.animateCamera(any));
    expect(find.byType(ShopCard), findsNothing);
  });

  testWidgets(
      'when search is finished, map page has the last query in search bar',
      (WidgetTester tester) async {
    final widget = await commons.createIdleMapPage(tester);

    expect(find.text('cool query'), findsNothing);
    widget.onSearchResultsForTesting(
        MapSearchPageResult.create(chosenRoad: roads[0], query: 'cool query'));
    await tester.pumpAndSettle();
    expect(find.text('cool query'), findsOneWidget);
  });

  testWidgets(
      'when there are search results search bar clicks open search page with the results',
      (WidgetTester tester) async {
    final searchResults = MapSearchPageResult.create(
        chosenRoad: roads[0],
        query: 'cool road',
        allFound: MapSearchResult.create([], roads));

    final widget = await commons.createIdleMapPage(tester);

    widget.onSearchResultsForTesting(searchResults);
    await tester.pumpAndSettle();

    expect(find.text(roads[0].name), findsNothing);
    expect(find.text(roads[1].name), findsNothing);
    expect(find.byType(MapSearchPage), findsNothing);

    await tester.superTap(find.byType(MapSearchBar));

    expect(find.text(roads[0].name), findsOneWidget);
    expect(find.text(roads[1].name), findsOneWidget);
    expect(find.byType(MapSearchPage), findsOneWidget);
  });

  testWidgets('map page can clear search results', (WidgetTester tester) async {
    final searchResults = MapSearchPageResult.create(
        chosenShops: commons.shops,
        query: 'cool shops',
        allFound: MapSearchResult.create([], roads));

    final widget = await commons.createIdleMapPage(tester);

    widget.onSearchResultsForTesting(searchResults);
    await tester.pumpAndSettle();

    expect(find.text('cool shops'), findsOneWidget);
    expect(find.byType(ShopCard), findsWidgets);
    await tester.superTap(find.byKey(const Key('map_search_bar_cancel')));
    expect(find.text('cool shops'), findsNothing);
    // Shop card is also expected to be hidden
    expect(find.byType(ShopCard), findsNothing);

    expect(find.byType(MapSearchPage), findsNothing);
    await tester.superTap(find.byType(MapSearchBar));
    expect(find.byType(MapSearchPage), findsOneWidget);
    expect(find.text(roads[0].name), findsNothing);
    expect(find.text(roads[1].name), findsNothing);
  });

  testWidgets('when there are search results clicks on back open search page',
      (WidgetTester tester) async {
    final searchResults = MapSearchPageResult.create(
        chosenRoad: roads[0],
        query: 'cool road',
        allFound: MapSearchResult.create([], roads));

    final widget = await commons.createIdleMapPage(tester);

    widget.onSearchResultsForTesting(searchResults);
    await tester.pumpAndSettle();

    expect(find.byType(MapSearchPage), findsNothing);

    // Back press
    final popper =
        find.byType(WillPopScope).evaluate().first.widget as WillPopScope;
    await popper.onWillPop!.call();
    await tester.pumpAndSettle();

    expect(find.byType(MapSearchPage), findsOneWidget);
  });

  testWidgets(
      'when there are no search results clicks on back do not open search page',
      (WidgetTester tester) async {
    await commons.createIdleMapPage(tester);

    // No search result
    // widget.onSearchResultsForTesting(searchResults);
    // await tester.pumpAndSettle();

    // Back press
    final popper =
        find.byType(WillPopScope).evaluate().first.widget as WillPopScope;
    await popper.onWillPop!.call();
    await tester.pumpAndSettle();

    // Search results didn't open
    expect(find.byType(MapSearchPage), findsNothing);
  });
}
