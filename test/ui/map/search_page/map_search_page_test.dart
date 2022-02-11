import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mockito/mockito.dart';
import 'package:plante/base/coord_utils.dart';
import 'package:plante/base/result.dart';
import 'package:plante/l10n/strings.dart';
import 'package:plante/location/user_location_manager.dart';
import 'package:plante/logging/analytics.dart';
import 'package:plante/model/coord.dart';
import 'package:plante/model/country_code.dart';
import 'package:plante/model/shop.dart';
import 'package:plante/outside/backend/backend_shop.dart';
import 'package:plante/outside/map/address_obtainer.dart';
import 'package:plante/outside/map/displayed_distance_units_manager.dart';
import 'package:plante/outside/map/osm/open_street_map.dart';
import 'package:plante/outside/map/osm/osm_address.dart';
import 'package:plante/outside/map/osm/osm_road.dart';
import 'package:plante/outside/map/osm/osm_search_result.dart';
import 'package:plante/outside/map/osm/osm_searcher.dart';
import 'package:plante/outside/map/osm/osm_shop.dart';
import 'package:plante/outside/map/osm/osm_short_address.dart';
import 'package:plante/outside/map/osm/osm_uid.dart';
import 'package:plante/outside/map/roads_manager.dart';
import 'package:plante/outside/map/shops_manager.dart';
import 'package:plante/outside/map/shops_manager_types.dart';
import 'package:plante/outside/map/user_address/user_address_piece.dart';
import 'package:plante/outside/map/user_address/user_address_type.dart';
import 'package:plante/ui/map/latest_camera_pos_storage.dart';
import 'package:plante/ui/map/search_page/map_search_page.dart';
import 'package:plante/ui/map/search_page/map_search_page_model.dart';
import 'package:plante/ui/map/search_page/map_search_page_result.dart';
import 'package:plante/ui/map/search_page/map_search_result.dart';

import '../../../common_finders_extension.dart';
import '../../../common_mocks.mocks.dart';
import '../../../widget_tester_extension.dart';
import '../../../z_fakes/fake_analytics.dart';
import '../../../z_fakes/fake_caching_user_address_pieces_obtainer.dart';
import '../../../z_fakes/fake_settings.dart';
import '../../../z_fakes/fake_shared_preferences.dart';
import '../../../z_fakes/fake_user_location_manager.dart';

void main() {
  late MockShopsManager shopsManager;
  late MockRoadsManager roadsManager;
  late LatestCameraPosStorage cameraPosStorage;
  late MockAddressObtainer addressObtainer;
  late MockOsmSearcher osmSearcher;
  late FakeUserLocationManager userLocationManager;
  late FakeAnalytics analytics;
  late FakeCachingUserAddressPiecesObtainer userAddressObtainer;
  late DisplayedDistanceUnitsManager displayedDistanceManager;
  late FakeSettings settings;

  final userPos = Coord(lat: 15, lon: 15);
  final distanceToEntities = kmToGrad(3);
  final cameraPos =
      Coord(lat: userPos.lat + kmToGrad(1), lon: userPos.lon + kmToGrad(1));

  final localShops = [
    Shop((e) => e
      ..osmShop.replace(OsmShop((e) => e
        ..osmUID = OsmUID.parse('1:1')
        ..name = 'shop name 1'
        ..type = 'supermarket'
        ..longitude = userPos.lon + distanceToEntities
        ..latitude = userPos.lat + distanceToEntities))
      ..backendShop.replace(BackendShop((e) => e
        ..osmUID = OsmUID.parse('1:1')
        ..productsCount = 2))),
  ];

  final foundInOsmShops = [
    Shop((e) => e
      ..osmShop.replace(OsmShop((e) => e
        ..osmUID = OsmUID.parse('1:3')
        ..name = 'shop name 3'
        ..type = 'bakery'
        ..longitude = userPos.lon + distanceToEntities
        ..latitude = userPos.lat + distanceToEntities))
      ..backendShop.replace(BackendShop((e) => e
        ..osmUID = OsmUID.parse('1:3')
        ..productsCount = 3))),
  ];

  final localRoads = [
    OsmRoad((e) => e
      ..osmId = '10'
      ..name = 'road name 1'
      ..longitude = userPos.lon + distanceToEntities
      ..latitude = userPos.lat + distanceToEntities),
  ];

  final foundInOsmRoads = [
    OsmRoad((e) => e
      ..osmId = '12'
      ..name = 'road name 2'
      ..longitude = userPos.lon + distanceToEntities
      ..latitude = userPos.lat + distanceToEntities),
  ];

  void setUpFoundEntities(
      {List<Shop> localShops = const [],
      List<Shop> foundInOsmShops = const [],
      List<OsmRoad> localRoads = const [],
      List<OsmRoad> foundInOsmRoads = const []}) {
    when(shopsManager.fetchShops(any))
        .thenAnswer((_) async => Ok(localShops.toMap()));
    when(roadsManager.fetchRoadsWithinAndNearby(any))
        .thenAnswer((_) async => Ok(localRoads));
    when(osmSearcher.search(any, any, any))
        .thenAnswer((_) async => Ok(OsmSearchResult((e) => e
          ..shops.addAll(foundInOsmShops.map((e) => e.osmShop))
          ..roads.addAll(foundInOsmRoads))));

    when(shopsManager.inflateOsmShops(any)).thenAnswer((invc) async {
      final osmShops = invc.positionalArguments[0] as Iterable<OsmShop>;
      final ids = osmShops.map((e) => e.osmUID);
      final allShops = localShops + foundInOsmShops;
      final result = allShops.where((e) => ids.contains(e.osmUID));
      return Ok(result.toMap());
    });
  }

  setUp(() async {
    await GetIt.I.reset();

    shopsManager = MockShopsManager();
    GetIt.I.registerSingleton<ShopsManager>(shopsManager);
    roadsManager = MockRoadsManager();
    GetIt.I.registerSingleton<RoadsManager>(roadsManager);
    cameraPosStorage =
        LatestCameraPosStorage(FakeSharedPreferences().asHolder());
    GetIt.I.registerSingleton<LatestCameraPosStorage>(cameraPosStorage);
    addressObtainer = MockAddressObtainer();
    GetIt.I.registerSingleton<AddressObtainer>(addressObtainer);
    osmSearcher = MockOsmSearcher();
    GetIt.I.registerSingleton<OsmSearcher>(osmSearcher);
    userLocationManager = FakeUserLocationManager();
    GetIt.I.registerSingleton<UserLocationManager>(userLocationManager);
    analytics = FakeAnalytics();
    GetIt.I.registerSingleton<Analytics>(analytics);
    userAddressObtainer = FakeCachingUserAddressPiecesObtainer();
    settings = FakeSettings();
    displayedDistanceManager =
        DisplayedDistanceUnitsManager(userAddressObtainer, settings);
    GetIt.I.registerSingleton<DisplayedDistanceUnitsManager>(
        displayedDistanceManager);

    await cameraPosStorage.set(cameraPos);
    userLocationManager.setCurrentPosition(userPos);

    when(addressObtainer.addressOfCoords(any))
        .thenAnswer((_) async => Ok(OsmAddress((e) => e
          ..city = 'London'
          ..country = 'England'
          ..countryCode = 'UK')));
    when(addressObtainer.addressOfShop(any))
        .thenAnswer((_) async => Ok(OsmShortAddress((e) => e
          ..city = 'London'
          ..road = 'Broadway')));

    userAddressObtainer.setResultFor(UserAddressType.USER_LOCATION,
        UserAddressPiece.COUNTRY_CODE, CountryCode.BELGIUM);

    setUpFoundEntities(
        localShops: [],
        foundInOsmShops: [],
        localRoads: [],
        foundInOsmRoads: []);
  });

  Future<BuildContext> pumpAndWaitPreloadFinish(WidgetTester tester,
      {NavigatorObserver? navigatorObserver,
      MapSearchPageResult? initialState,
      Key? key}) async {
    final context = await tester.superPump(
        MapSearchPage(initialState: initialState, key: key),
        navigatorObserver: navigatorObserver);
    await tester.pumpAndSettle();
    return context;
  }

  void verifySearchResults(WidgetTester tester, BuildContext context,
      {required Iterable<Shop> expectedShops,
      required Iterable<OsmRoad> expectedRoads,
      bool expectNotFoundMsgIfEntitiesEmpty = true}) {
    if (expectedShops.isNotEmpty) {
      expect(find.text(context.strings.map_search_page_shops_not_found),
          findsNothing);
      Shop? prevShop;
      for (final shop in expectedShops) {
        Offset? prevCenter;
        if (prevShop != null) {
          prevCenter = tester.getCenter(find.text(prevShop.name));
        }
        final center = tester.getCenter(find.text(shop.name));
        expect(center.dy, greaterThan(prevCenter?.dy ?? -1));
        prevShop = shop;
      }
    } else {
      if (expectNotFoundMsgIfEntitiesEmpty) {
        expect(find.text(context.strings.map_search_page_shops_not_found),
            findsOneWidget);
      }
    }

    if (expectedRoads.isNotEmpty) {
      expect(find.text(context.strings.map_search_page_streets_not_found),
          findsNothing);
      OsmRoad? prevRoad;
      for (final road in expectedRoads) {
        Offset? prevCenter;
        if (prevRoad != null) {
          prevCenter = tester.getCenter(find.text(prevRoad.name));
        }
        final center = tester.getCenter(find.text(road.name));
        expect(center.dy, greaterThan(prevCenter?.dy ?? -1));
        prevRoad = road;
      }
    } else {
      if (expectNotFoundMsgIfEntitiesEmpty) {
        expect(find.text(context.strings.map_search_page_streets_not_found),
            findsOneWidget);
      }
    }
  }

  testWidgets('preloaded entities are preloaded', (WidgetTester tester) async {
    verifyNever(shopsManager.fetchShops(any));
    verifyNever(roadsManager.fetchRoadsWithinAndNearby(any));
    verifyNever(addressObtainer.addressOfCoords(any));

    await pumpAndWaitPreloadFinish(tester);

    verify(shopsManager.fetchShops(any));
    verify(roadsManager.fetchRoadsWithinAndNearby(any));
    verify(addressObtainer.addressOfCoords(any));
    verifyZeroInteractions(osmSearcher);
  });

  testWidgets('both shops and streets found', (WidgetTester tester) async {
    setUpFoundEntities(
        localShops: localShops,
        foundInOsmShops: foundInOsmShops,
        localRoads: localRoads,
        foundInOsmRoads: foundInOsmRoads);

    final context = await pumpAndWaitPreloadFinish(tester);
    await tester.superEnterText(
        find.byKey(const Key('map_search_bar_text_field')), 'name');
    await tester
        .superTap(find.text(context.strings.map_search_bar_button_title));

    verifySearchResults(
      tester,
      context,
      expectedShops: foundInOsmShops + localShops,
      expectedRoads: foundInOsmRoads + localRoads,
    );

    expect(find.text(context.strings.map_page_show_found_shops_on_map),
        findsOneWidget);
  });

  testWidgets('only shops found', (WidgetTester tester) async {
    setUpFoundEntities(
        localShops: localShops,
        foundInOsmShops: foundInOsmShops,
        localRoads: [],
        foundInOsmRoads: []);

    final context = await pumpAndWaitPreloadFinish(tester);
    await tester.superEnterText(
        find.byKey(const Key('map_search_bar_text_field')), 'name');
    await tester
        .superTap(find.text(context.strings.map_search_bar_button_title));

    verifySearchResults(
      tester,
      context,
      expectedShops: foundInOsmShops + localShops,
      expectedRoads: [],
    );

    expect(find.text(context.strings.map_page_show_found_shops_on_map),
        findsOneWidget);
  });

  testWidgets('only roads found', (WidgetTester tester) async {
    setUpFoundEntities(
        localShops: [],
        foundInOsmShops: [],
        localRoads: localRoads,
        foundInOsmRoads: foundInOsmRoads);

    final context = await pumpAndWaitPreloadFinish(tester);
    await tester.superEnterText(
        find.byKey(const Key('map_search_bar_text_field')), 'name');
    await tester
        .superTap(find.text(context.strings.map_search_bar_button_title));

    verifySearchResults(
      tester,
      context,
      expectedShops: [],
      expectedRoads: foundInOsmRoads + localRoads,
    );

    expect(find.text(context.strings.map_page_show_found_shops_on_map),
        findsNothing);
  });

  testWidgets('nothing found', (WidgetTester tester) async {
    setUpFoundEntities(
        localShops: [],
        foundInOsmShops: [],
        localRoads: [],
        foundInOsmRoads: []);

    final context = await pumpAndWaitPreloadFinish(tester);
    await tester.superEnterText(
        find.byKey(const Key('map_search_bar_text_field')), 'name');
    await tester
        .superTap(find.text(context.strings.map_search_bar_button_title));

    verifySearchResults(
      tester,
      context,
      expectedShops: [],
      expectedRoads: [],
    );

    expect(find.text(context.strings.map_page_show_found_shops_on_map),
        findsNothing);
  });

  testWidgets('osm search error', (WidgetTester tester) async {
    setUpFoundEntities(
        localShops: localShops,
        foundInOsmShops: foundInOsmShops,
        localRoads: localRoads,
        foundInOsmRoads: foundInOsmRoads);

    when(osmSearcher.search(any, any, any))
        .thenAnswer((_) async => Err(OpenStreetMapError.OTHER));

    final context = await pumpAndWaitPreloadFinish(tester);
    await tester.superEnterText(
        find.byKey(const Key('map_search_bar_text_field')), 'name');
    await tester
        .superTap(find.text(context.strings.map_search_bar_button_title));

    // Expecting only local entities, not the [foundInOsm..] ones
    verifySearchResults(
      tester,
      context,
      expectedShops: localShops,
      expectedRoads: localRoads,
    );
  });

  testWidgets('shops local search error', (WidgetTester tester) async {
    setUpFoundEntities(
        localShops: localShops,
        foundInOsmShops: foundInOsmShops,
        localRoads: localRoads,
        foundInOsmRoads: foundInOsmRoads);

    when(shopsManager.fetchShops(any))
        .thenAnswer((_) async => Err(ShopsManagerError.OTHER));

    final context = await pumpAndWaitPreloadFinish(tester);
    await tester.superEnterText(
        find.byKey(const Key('map_search_bar_text_field')), 'name');
    await tester
        .superTap(find.text(context.strings.map_search_bar_button_title));

    // Expecting everything remote + local except for shops - local shops
    // search was set up to fail.
    verifySearchResults(
      tester,
      context,
      expectedShops: foundInOsmShops,
      expectedRoads: foundInOsmRoads + localRoads,
    );
  });

  testWidgets('streets local search error', (WidgetTester tester) async {
    setUpFoundEntities(
        localShops: localShops,
        foundInOsmShops: foundInOsmShops,
        localRoads: localRoads,
        foundInOsmRoads: foundInOsmRoads);

    when(roadsManager.fetchRoadsWithinAndNearby(any))
        .thenAnswer((_) async => Err(RoadsManagerError.OTHER));

    final context = await pumpAndWaitPreloadFinish(tester);
    await tester.superEnterText(
        find.byKey(const Key('map_search_bar_text_field')), 'name');
    await tester
        .superTap(find.text(context.strings.map_search_bar_button_title));

    // Expecting everything remote + local except for roads - local roads
    // search was set up to fail.
    verifySearchResults(
      tester,
      context,
      expectedShops: foundInOsmShops + localShops,
      expectedRoads: foundInOsmRoads,
    );
  });

  testWidgets('all searches ended up with errors', (WidgetTester tester) async {
    setUpFoundEntities(
        localShops: localShops,
        foundInOsmShops: foundInOsmShops,
        localRoads: localRoads,
        foundInOsmRoads: foundInOsmRoads);

    when(osmSearcher.search(any, any, any))
        .thenAnswer((_) async => Err(OpenStreetMapError.OTHER));
    when(shopsManager.fetchShops(any))
        .thenAnswer((_) async => Err(ShopsManagerError.OTHER));
    when(roadsManager.fetchRoadsWithinAndNearby(any))
        .thenAnswer((_) async => Err(RoadsManagerError.OTHER));

    final context = await pumpAndWaitPreloadFinish(tester);
    await tester.superEnterText(
        find.byKey(const Key('map_search_bar_text_field')), 'name');
    await tester
        .superTap(find.text(context.strings.map_search_bar_button_title));

    verifySearchResults(
      tester,
      context,
      expectedShops: [],
      expectedRoads: [],
    );
  });

  testWidgets('clear query', (WidgetTester tester) async {
    setUpFoundEntities(
        localShops: localShops,
        foundInOsmShops: foundInOsmShops,
        localRoads: localRoads,
        foundInOsmRoads: foundInOsmRoads);

    final context = await pumpAndWaitPreloadFinish(tester);
    await tester.superEnterText(
        find.byKey(const Key('map_search_bar_text_field')), 'name');
    await tester
        .superTap(find.text(context.strings.map_search_bar_button_title));

    verifySearchResults(
      tester,
      context,
      expectedShops: foundInOsmShops + localShops,
      expectedRoads: foundInOsmRoads + localRoads,
    );

    expect(
        find.text(context.strings.map_search_page_search_hint), findsNothing);
    await tester.superTap(find.byKey(const Key('map_search_bar_cancel')));

    verifySearchResults(
      tester,
      context,
      expectedShops: [],
      expectedRoads: [],
      expectNotFoundMsgIfEntitiesEmpty: false,
    );
    expect(
        find.text(context.strings.map_search_page_search_hint), findsOneWidget);
  });

  testWidgets('clear query when search not finished yet',
      (WidgetTester tester) async {
    setUpFoundEntities(
        localShops: localShops,
        foundInOsmShops: foundInOsmShops,
        localRoads: localRoads,
        foundInOsmRoads: foundInOsmRoads);

    // Shops search will be slow
    final shopsSearchCompleter =
        Completer<Result<Map<OsmUID, Shop>, ShopsManagerError>>();
    when(shopsManager.fetchShops(any))
        .thenAnswer((_) async => shopsSearchCompleter.future);

    final context = await pumpAndWaitPreloadFinish(tester);
    await tester.superEnterText(
        find.byKey(const Key('map_search_bar_text_field')), 'name');
    await tester
        .superTap(find.text(context.strings.map_search_bar_button_title));

    // Search canceled while still in progress
    await tester.superTap(find.byKey(const Key('map_search_bar_cancel')));
    // And then slow query is finished
    shopsSearchCompleter.complete(Ok(localShops.toMap()));
    await tester.pumpAndSettle();

    // No search results displayed
    verifySearchResults(
      tester,
      context,
      expectedShops: [],
      expectedRoads: [],
      expectNotFoundMsgIfEntitiesEmpty: false,
    );
    expect(
        find.text(context.strings.map_search_page_search_hint), findsOneWidget);
  });

  testWidgets('distance from user to entity shown',
      (WidgetTester tester) async {
    setUpFoundEntities(
        localShops: localShops,
        foundInOsmShops: foundInOsmShops,
        localRoads: [],
        foundInOsmRoads: []);

    final context = await pumpAndWaitPreloadFinish(tester);
    await tester.superEnterText(
        find.byKey(const Key('map_search_bar_text_field')), 'name');

    final allShops = localShops + foundInOsmShops;

    // NOTE: grad to kms math is complex so we simply hardcode the expected
    // number of kilometers.

    expect(find.text('4.2 ${context.strings.global_kilometers}'), findsNothing);
    await tester
        .superTap(find.text(context.strings.map_search_bar_button_title));
    expect(find.text('4.2 ${context.strings.global_kilometers}'),
        findsNWidgets(allShops.length));
  });

  testWidgets('distance from camera to entity shown when user location unknown',
      (WidgetTester tester) async {
    userLocationManager.setCurrentPosition(null);

    setUpFoundEntities(
        localShops: localShops,
        foundInOsmShops: foundInOsmShops,
        localRoads: [],
        foundInOsmRoads: []);

    final context = await pumpAndWaitPreloadFinish(tester);
    await tester.superEnterText(
        find.byKey(const Key('map_search_bar_text_field')), 'name');

    final allShops = localShops + foundInOsmShops;

    // NOTE: grad to kms math is complex so we simply hardcode the expected
    // number of kilometers.
    expect(find.text('2.8 ${context.strings.global_kilometers}'), findsNothing);
    await tester
        .superTap(find.text(context.strings.map_search_bar_button_title));
    expect(find.text('2.8 ${context.strings.global_kilometers}'),
        findsNWidgets(allShops.length));
  });

  testWidgets('distance from user is shown in miles when settings say so',
      (WidgetTester tester) async {
    setUpFoundEntities(
        localShops: localShops,
        foundInOsmShops: foundInOsmShops,
        localRoads: [],
        foundInOsmRoads: []);

    // Kilometers first
    var context =
        await pumpAndWaitPreloadFinish(tester, key: const Key('page1'));
    await tester.superEnterText(
        find.byKey(const Key('map_search_bar_text_field')), 'name');
    await tester
        .superTap(find.text(context.strings.map_search_bar_button_title));
    expect(
        find.textContaining(context.strings.global_kilometers), findsWidgets);
    expect(find.textContaining(context.strings.global_miles), findsNothing);

    // Now miles
    await settings.setDistanceInMiles(true);

    context = await pumpAndWaitPreloadFinish(tester, key: const Key('page2'));
    await tester.superEnterText(
        find.byKey(const Key('map_search_bar_text_field')), 'name');
    await tester
        .superTap(find.text(context.strings.map_search_bar_button_title));
    expect(
        find.textContaining(context.strings.global_kilometers), findsNothing);
    expect(find.textContaining(context.strings.global_miles), findsWidgets);
  });

  testWidgets('behaviour when osm and local shops intersect',
      (WidgetTester tester) async {
    setUpFoundEntities(
        localShops: localShops,
        foundInOsmShops: localShops + foundInOsmShops,
        localRoads: localRoads,
        foundInOsmRoads: foundInOsmRoads);

    final context = await pumpAndWaitPreloadFinish(tester);
    await tester.superEnterText(
        find.byKey(const Key('map_search_bar_text_field')), 'name');
    await tester
        .superTap(find.text(context.strings.map_search_bar_button_title));

    // Found in OSM shops include local shops - this is why
    // the local shops are in the beginning of the found shops list.
    // If the lists didn't intersect, the order would be the other way around.
    verifySearchResults(
      tester,
      context,
      expectedShops: localShops + foundInOsmShops,
      expectedRoads: foundInOsmRoads + localRoads,
    );
  });

  testWidgets('behaviour when osm and local roads intersect',
      (WidgetTester tester) async {
    setUpFoundEntities(
        localShops: localShops,
        foundInOsmShops: foundInOsmShops,
        localRoads: localRoads,
        foundInOsmRoads: localRoads + foundInOsmRoads);

    final context = await pumpAndWaitPreloadFinish(tester);
    await tester.superEnterText(
        find.byKey(const Key('map_search_bar_text_field')), 'name');
    await tester
        .superTap(find.text(context.strings.map_search_bar_button_title));

    // Found in OSM roads include local roads - this is why
    // the local roads are in the beginning of the found roads list.
    // If the lists didn't intersect, the order would be the other way around.
    verifySearchResults(
      tester,
      context,
      expectedShops: foundInOsmShops + localShops,
      expectedRoads: localRoads + foundInOsmRoads,
    );
  });

  testWidgets('found locally entities similarity to query is checked',
      (WidgetTester tester) async {
    final localShopsRenamed = localShops
        .map((shop) =>
            shop.rebuildWithName('that is a totally different thing 1'))
        .toList();
    final localRoadsRenamed = localRoads
        .map((e) =>
            e.rebuild((e) => e.name = 'that is a totally different thing 2'))
        .toList();

    setUpFoundEntities(
        localShops: localShopsRenamed,
        foundInOsmShops: foundInOsmShops,
        localRoads: localRoadsRenamed,
        foundInOsmRoads: foundInOsmRoads);

    final context = await pumpAndWaitPreloadFinish(tester);
    await tester.superEnterText(
        find.byKey(const Key('map_search_bar_text_field')), 'name');
    await tester
        .superTap(find.text(context.strings.map_search_bar_button_title));

    // We expect the local entities to NOT be found, because their names
    // are not similar to what we've requested.
    verifySearchResults(
      tester,
      context,
      expectedShops: foundInOsmShops,
      expectedRoads: foundInOsmRoads,
    );
  });

  testWidgets('found in OSM entities similarity to query IS NOT checked',
      (WidgetTester tester) async {
    final osmShopsRenamed = foundInOsmShops
        .map((shop) =>
            shop.rebuildWithName('that is a totally different thing 1'))
        .toList();
    final osmRoadsRenamed = foundInOsmRoads
        .map((e) =>
            e.rebuild((e) => e.name = 'that is a totally different thing 2'))
        .toList();

    setUpFoundEntities(
        localShops: localShops,
        foundInOsmShops: osmShopsRenamed,
        localRoads: localRoads,
        foundInOsmRoads: osmRoadsRenamed);

    final context = await pumpAndWaitPreloadFinish(tester);
    await tester.superEnterText(
        find.byKey(const Key('map_search_bar_text_field')), 'name');
    await tester
        .superTap(find.text(context.strings.map_search_bar_button_title));

    // We expect OSM entities to be found because we don't expect the app
    // to check their names - OSM already did a search and found the
    // entities so we should trust it.
    verifySearchResults(
      tester,
      context,
      expectedShops: osmShopsRenamed + localShops,
      expectedRoads: osmRoadsRenamed + localRoads,
    );
  });

  testWidgets('found shop click', (WidgetTester tester) async {
    setUpFoundEntities(localShops: localShops);

    final navigatorObserver = MockNavigatorObserver();

    final context = await pumpAndWaitPreloadFinish(tester,
        navigatorObserver: navigatorObserver);
    await tester.superEnterText(
        find.byKey(const Key('map_search_bar_text_field')), 'name');
    await tester
        .superTap(find.text(context.strings.map_search_bar_button_title));

    verifySearchResults(
      tester,
      context,
      expectedShops: localShops,
      expectedRoads: [],
    );

    clearInteractions(navigatorObserver);

    await tester.superTap(find.text(localShops.first.name));

    final capturedRoute = verify(navigatorObserver.didPop(captureAny, any))
        .captured
        .first as Route<dynamic>;

    final pageResult = await capturedRoute.popped as MapSearchPageResult;
    expect(pageResult.chosenShops, equals([localShops.first]));
  });

  testWidgets('found road click', (WidgetTester tester) async {
    setUpFoundEntities(localRoads: localRoads);

    final navigatorObserver = MockNavigatorObserver();

    final context = await pumpAndWaitPreloadFinish(tester,
        navigatorObserver: navigatorObserver);
    await tester.superEnterText(
        find.byKey(const Key('map_search_bar_text_field')), 'name');
    await tester
        .superTap(find.text(context.strings.map_search_bar_button_title));

    verifySearchResults(
      tester,
      context,
      expectedShops: [],
      expectedRoads: localRoads,
    );

    clearInteractions(navigatorObserver);

    await tester.superTap(find.text(localRoads.first.name));

    final capturedRoute = verify(navigatorObserver.didPop(captureAny, any))
        .captured
        .first as Route<dynamic>;
    final pageResult = await capturedRoute.popped as MapSearchPageResult;
    expect(pageResult.chosenRoad, localRoads.first);
  });

  testWidgets('shops with same name are sorted by distance to user',
      (WidgetTester tester) async {
    final shops = [
      Shop((e) => e
        ..osmShop.replace(OsmShop((e) => e
          ..osmUID = OsmUID.parse('1:1')
          ..name = 'shop name'
          ..type = 'supermarket'
          ..longitude = userPos.lon + distanceToEntities + 1
          ..latitude = userPos.lat + distanceToEntities + 1))
        ..backendShop.replace(BackendShop((e) => e
          ..osmUID = OsmUID.parse('1:1')
          ..productsCount = 2))),
      Shop((e) => e
        ..osmShop.replace(OsmShop((e) => e
          ..osmUID = OsmUID.parse('1:2')
          ..name = 'shop name'
          ..type = 'supermarket'
          ..longitude = userPos.lon + distanceToEntities + 3
          ..latitude = userPos.lat + distanceToEntities + 3))
        ..backendShop.replace(BackendShop((e) => e
          ..osmUID = OsmUID.parse('1:2')
          ..productsCount = 2))),
      Shop((e) => e
        ..osmShop.replace(OsmShop((e) => e
          ..osmUID = OsmUID.parse('1:3')
          ..name = 'shop name'
          ..type = 'supermarket'
          ..longitude = userPos.lon + distanceToEntities + 2
          ..latitude = userPos.lat + distanceToEntities + 2))
        ..backendShop.replace(BackendShop((e) => e
          ..osmUID = OsmUID.parse('1:3')
          ..productsCount = 2))),
    ];

    final distances = [
      metersBetween(userPos, shops[0].coord),
      metersBetween(userPos, shops[1].coord),
      metersBetween(userPos, shops[2].coord),
    ];

    setUpFoundEntities(localShops: shops);

    final context = await pumpAndWaitPreloadFinish(tester);
    await tester.superEnterText(
        find.byKey(const Key('map_search_bar_text_field')), 'shop name');
    await tester
        .superTap(find.text(context.strings.map_search_bar_button_title));

    final expectedDistances = [distances[0], distances[2], distances[1]];

    double? prevDistance;
    for (final distance in expectedDistances) {
      Offset? prevCenter;
      if (prevDistance != null) {
        prevCenter = tester.getCenter(find
            .text(displayedDistanceManager.metersToStr(prevDistance, context)));
      }
      final center = tester.getCenter(
          find.text(displayedDistanceManager.metersToStr(distance, context)));
      expect(center.dy, greaterThan(prevCenter?.dy ?? -1));
      prevDistance = distance;
    }
  });

  testWidgets('roads with same name are sorted by distance to user',
      (WidgetTester tester) async {
    final roads = [
      OsmRoad((e) => e
        ..osmId = '10'
        ..name = 'road name'
        ..longitude = userPos.lon + distanceToEntities + 1
        ..latitude = userPos.lat + distanceToEntities + 1),
      OsmRoad((e) => e
        ..osmId = '11'
        ..name = 'road name'
        ..longitude = userPos.lon + distanceToEntities + 3
        ..latitude = userPos.lat + distanceToEntities + 3),
      OsmRoad((e) => e
        ..osmId = '12'
        ..name = 'road name'
        ..longitude = userPos.lon + distanceToEntities + 2
        ..latitude = userPos.lat + distanceToEntities + 2),
    ];

    final distances = [
      metersBetween(userPos, roads[0].coord),
      metersBetween(userPos, roads[1].coord),
      metersBetween(userPos, roads[2].coord),
    ];

    setUpFoundEntities(localRoads: roads);

    final context = await pumpAndWaitPreloadFinish(tester);
    await tester.superEnterText(
        find.byKey(const Key('map_search_bar_text_field')), 'road name');
    await tester
        .superTap(find.text(context.strings.map_search_bar_button_title));

    final expectedDistances = [distances[0], distances[2], distances[1]];

    double? prevDistance;
    for (final distance in expectedDistances) {
      Offset? prevCenter;
      if (prevDistance != null) {
        prevCenter = tester.getCenter(find
            .text(displayedDistanceManager.metersToStr(prevDistance, context)));
      }
      final center = tester.getCenter(
          find.text(displayedDistanceManager.metersToStr(distance, context)));
      expect(center.dy, greaterThan(prevCenter?.dy ?? -1));
      prevDistance = distance;
    }
  });

  testWidgets('close roads with same names are merged',
      (WidgetTester tester) async {
    final roads = [
      OsmRoad((e) => e
        ..osmId = '10'
        ..name = 'road name'
        ..longitude = userPos.lon + distanceToEntities
        ..latitude = userPos.lat + distanceToEntities),
      OsmRoad((e) => e
        ..osmId = '11'
        ..name = 'road name'
        ..longitude = userPos.lon + distanceToEntities + kmToGrad(1)
        ..latitude = userPos.lat + distanceToEntities + kmToGrad(1)),
      OsmRoad((e) => e
        ..osmId = '12'
        ..name = 'road name'
        ..longitude = userPos.lon +
            distanceToEntities +
            kmToGrad(
                MapSearchPageModel.MAX_DISTANCE_BETWEEN_MERGED_ROADS_KMS * 3)
        ..latitude = userPos.lat +
            distanceToEntities +
            kmToGrad(
                MapSearchPageModel.MAX_DISTANCE_BETWEEN_MERGED_ROADS_KMS * 3)),
    ];

    final distances = [
      metersBetween(userPos, roads[0].coord),
      metersBetween(userPos, roads[1].coord),
      metersBetween(userPos, roads[2].coord),
    ];

    setUpFoundEntities(localRoads: roads);

    final context = await pumpAndWaitPreloadFinish(tester);
    await tester.superEnterText(
        find.byKey(const Key('map_search_bar_text_field')), 'road name');
    await tester
        .superTap(find.text(context.strings.map_search_bar_button_title));

    final expectedDistances = [distances[0], distances[2]];
    final notExpectedDistances = [distances[1]];

    for (final distance in expectedDistances) {
      expect(find.text(displayedDistanceManager.metersToStr(distance, context)),
          findsOneWidget);
    }
    for (final distance in notExpectedDistances) {
      expect(find.text(displayedDistanceManager.metersToStr(distance, context)),
          findsNothing);
    }
  });

  testWidgets('close shops with same names are NOT merged',
      (WidgetTester tester) async {
    final shops = [
      Shop((e) => e
        ..osmShop.replace(OsmShop((e) => e
          ..osmUID = OsmUID.parse('1:1')
          ..name = 'shop name'
          ..type = 'supermarket'
          ..longitude = userPos.lon + distanceToEntities
          ..latitude = userPos.lat + distanceToEntities))
        ..backendShop.replace(BackendShop((e) => e
          ..osmUID = OsmUID.parse('1:1')
          ..productsCount = 2))),
      Shop((e) => e
        ..osmShop.replace(OsmShop((e) => e
          ..osmUID = OsmUID.parse('1:2')
          ..name = 'shop name'
          ..type = 'supermarket'
          ..longitude = userPos.lon + distanceToEntities + kmToGrad(1)
          ..latitude = userPos.lat + distanceToEntities + kmToGrad(1)))
        ..backendShop.replace(BackendShop((e) => e
          ..osmUID = OsmUID.parse('1:2')
          ..productsCount = 2))),
      Shop((e) => e
        ..osmShop.replace(OsmShop((e) => e
          ..osmUID = OsmUID.parse('1:3')
          ..name = 'shop name'
          ..type = 'supermarket'
          ..longitude = userPos.lon +
              distanceToEntities +
              kmToGrad(
                  MapSearchPageModel.MAX_DISTANCE_BETWEEN_MERGED_ROADS_KMS * 3)
          ..latitude = userPos.lat +
              distanceToEntities +
              kmToGrad(
                  MapSearchPageModel.MAX_DISTANCE_BETWEEN_MERGED_ROADS_KMS *
                      3)))
        ..backendShop.replace(BackendShop((e) => e
          ..osmUID = OsmUID.parse('1:3')
          ..productsCount = 2))),
    ];

    final distances = [
      metersBetween(userPos, shops[0].coord),
      metersBetween(userPos, shops[1].coord),
      metersBetween(userPos, shops[2].coord),
    ];

    setUpFoundEntities(localShops: shops);

    final context = await pumpAndWaitPreloadFinish(tester);
    await tester.superEnterText(
        find.byKey(const Key('map_search_bar_text_field')), 'shop name');
    await tester
        .superTap(find.text(context.strings.map_search_bar_button_title));

    final expectedDistances = [distances[0], distances[1], distances[2]];

    for (final distance in expectedDistances) {
      expect(find.text(displayedDistanceManager.metersToStr(distance, context)),
          findsOneWidget);
    }
  });

  testWidgets('search page creation with initial state',
      (WidgetTester tester) async {
    final searchResults = MapSearchPageResult.create(
        chosenRoad: localRoads[0],
        query: 'cool query',
        allFound: MapSearchResult.create(
            localShops + foundInOsmShops, localRoads + foundInOsmRoads));

    final context =
        await pumpAndWaitPreloadFinish(tester, initialState: searchResults);

    verifySearchResults(
      tester,
      context,
      expectedShops: localShops + foundInOsmShops,
      expectedRoads: localRoads + foundInOsmRoads,
    );
    expect(find.text('cool query'), findsOneWidget);
  });

  testWidgets('shops addresses are displayed', (WidgetTester tester) async {
    final shops = [
      Shop((e) => e
        ..osmShop.replace(OsmShop((e) => e
          ..osmUID = OsmUID.parse('1:1')
          ..name = 'shop name 1'
          ..type = 'supermarket'
          ..longitude = userPos.lon
          ..latitude = userPos.lat))
        ..backendShop.replace(BackendShop((e) => e
          ..osmUID = OsmUID.parse('1:1')
          ..productsCount = 2))),
      Shop((e) => e
        ..osmShop.replace(OsmShop((e) => e
          ..osmUID = OsmUID.parse('1:2')
          ..name = 'shop name 2'
          ..type = 'supermarket'
          ..longitude = userPos.lon
          ..latitude = userPos.lat))
        ..backendShop.replace(BackendShop((e) => e
          ..osmUID = OsmUID.parse('1:2')
          ..productsCount = 2))),
    ];

    final addresses = [
      OsmShortAddress((e) => e
        ..city = 'London'
        ..road = 'Broadway'),
      OsmShortAddress((e) => e
        ..city = 'London'
        ..road = 'Baker street'),
    ];

    when(addressObtainer.addressOfShop(shops[0]))
        .thenAnswer((_) async => Ok(addresses[0]));
    when(addressObtainer.addressOfShop(shops[1]))
        .thenAnswer((_) async => Ok(addresses[1]));

    setUpFoundEntities(localShops: shops);

    final context = await pumpAndWaitPreloadFinish(tester);
    await tester.superEnterText(
        find.byKey(const Key('map_search_bar_text_field')), 'shop name');
    await tester
        .superTap(find.text(context.strings.map_search_bar_button_title));

    expect(find.richTextContaining(addresses[0].road!), findsWidgets);
    expect(find.richTextContaining(addresses[1].road!), findsWidgets);
  });

  testWidgets('click on "Show on map"', (WidgetTester tester) async {
    setUpFoundEntities(
        localShops: localShops,
        foundInOsmShops: foundInOsmShops,
        localRoads: [],
        foundInOsmRoads: []);

    final navigatorObserver = MockNavigatorObserver();
    final context = await pumpAndWaitPreloadFinish(tester,
        navigatorObserver: navigatorObserver);
    await tester.superEnterText(
        find.byKey(const Key('map_search_bar_text_field')), 'name');
    await tester
        .superTap(find.text(context.strings.map_search_bar_button_title));

    await tester
        .superTap(find.text(context.strings.map_page_show_found_shops_on_map));

    final capturedRoute = verify(navigatorObserver.didPop(captureAny, any))
        .captured
        .first as Route<dynamic>;
    final pageResult = await capturedRoute.popped as MapSearchPageResult;
    expect(pageResult.chosenShops!.toSet(),
        equals((localShops + foundInOsmShops).toSet()));
  });
}

extension _ShopsListExt on Iterable<Shop> {
  Map<OsmUID, Shop> toMap() {
    return {for (var e in this) e.osmUID: e};
  }
}

extension _ShopExt on Shop {
  Shop rebuildWithName(String newName) {
    return rebuild(
        (e) => e..osmShop.replace(osmShop.rebuild((e) => e.name = newName)));
  }
}
