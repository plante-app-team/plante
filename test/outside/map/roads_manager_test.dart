import 'package:mockito/mockito.dart';
import 'package:plante/base/result.dart';
import 'package:plante/model/coord.dart';
import 'package:plante/model/coords_bounds.dart';
import 'package:plante/outside/map/osm_cacher.dart';
import 'package:plante/outside/map/osm_interactions_queue.dart';
import 'package:plante/outside/map/osm_road.dart';
import 'package:plante/outside/map/roads_manager.dart';
import 'package:test/test.dart';

import '../../common_mocks.mocks.dart';
import '../../z_fakes/fake_osm_cacher.dart';

void main() {
  late MockOpenStreetMap osm;
  late OsmCacher cacher;
  late RoadsManager roadsManager;

  final northeast = Coord(lat: 15.001, lon: 15.001);
  final southwest = Coord(lat: 14.999, lon: 14.999);
  final bounds = CoordsBounds(northeast: northeast, southwest: southwest);
  final farNortheast = Coord(lat: 16.001, lon: 16.001);
  final farSouthwest = Coord(lat: 15.999, lon: 15.999);
  final farBounds =
      CoordsBounds(northeast: farNortheast, southwest: farSouthwest);

  final fullRoads = [
    OsmRoad((e) => e
      ..osmId = '1'
      ..name = 'road1'
      ..latitude = 15
      ..longitude = 15),
    OsmRoad((e) => e
      ..osmId = '2'
      ..name = 'road2'
      ..latitude = 15
      ..longitude = 15),
  ];

  setUp(() async {
    osm = MockOpenStreetMap();
    cacher = FakeOsmCacher();

    when(osm.fetchRoads(any)).thenAnswer((invc) async {
      final bounds = invc.positionalArguments[0] as CoordsBounds;
      return Ok(
          fullRoads.where((road) => bounds.contains(road.coord)).toList());
    });

    roadsManager = RoadsManager(osm, cacher, OsmInteractionsQueue());
  });

  test('roads fetched and then cached', () async {
    verifyZeroInteractions(osm);

    // Fetch #1
    final roadsRes = await roadsManager.fetchRoadsWithinAndNearby(bounds);
    final roads = roadsRes.unwrap();
    expect(roads, equals(fullRoads));
    // OSM expected to be touched
    verify(osm.fetchRoads(any));

    clearInteractions(osm);

    // Fetch #2
    final roadsRes2 = await roadsManager.fetchRoadsWithinAndNearby(bounds);
    final roads2 = roadsRes2.unwrap();
    expect(roads2, equals(fullRoads));
    // No backends expected to be touched! Cache expected to be used!
    verifyZeroInteractions(osm);
  });

  test('roads fetch when cache exists but it is for another area', () async {
    verifyZeroInteractions(osm);

    // Fetch #1
    final roadsRes = await roadsManager.fetchRoadsWithinAndNearby(bounds);
    expect(roadsRes.isOk, isTrue);
    // OSM expected to be touched
    verify(osm.fetchRoads(any));

    clearInteractions(osm);

    // Fetch #2, another area
    final roadsRes2 = await roadsManager.fetchRoadsWithinAndNearby(farBounds);
    expect(roadsRes2.isOk, isTrue);
    // OSM expected to be touched again!
    // Because the requested area is too far away from the cached one
    verify(osm.fetchRoads(any));
  });

  test('roads fetch when cache is barely fresh', () async {
    // Store ANCIENT persistent cache
    final osmRoadsInPersistentCache = [
      fullRoads.first,
    ];
    // Passed which almost makes the cache ancient (but 10 seconds save it)
    final passed = DateTime.now()
        .subtract(const Duration(days: RoadsManager.DAYS_BEFORE_CACHE_ANCIENT))
        .add(const Duration(seconds: 10));
    await cacher.cacheRoads(
        passed, bounds.center.makeSquare(1), osmRoadsInPersistentCache);

    // Fetch
    final roadsRes = await roadsManager.fetchRoadsWithinAndNearby(bounds);
    // Verify data from cache WAS used
    expect(roadsRes.unwrap(), equals(osmRoadsInPersistentCache));
    expect(roadsRes.unwrap(), isNot(equals(fullRoads)));
  });

  test('roads fetch when cache is too old', () async {
    // Store ANCIENT persistent cache
    final osmRoadsInPersistentCache = [
      fullRoads.first,
    ];
    final passed = DateTime.now().subtract(
        const Duration(days: RoadsManager.DAYS_BEFORE_CACHE_ANCIENT + 1));
    await cacher.cacheRoads(
        passed, bounds.center.makeSquare(1), osmRoadsInPersistentCache);

    // Fetch
    final roadsRes = await roadsManager.fetchRoadsWithinAndNearby(bounds);
    // Verify data from cache WAS NOT used, even though cache exists -
    // the cache is ancient, ancient cache is not acceptable.
    expect(roadsRes.unwrap(), isNot(equals(osmRoadsInPersistentCache)));
    expect(roadsRes.unwrap(), equals(fullRoads));
  });

  test('roads fetch deletes oldest cache when there is too much of it',
      () async {
    // Store ANCIENT persistent cache
    final osmRoadsInPersistentCache = [
      fullRoads.first,
    ];
    final now = DateTime.now();
    for (var index = 0;
        index < RoadsManager.CACHED_TERRITORIES_LIMIT * 2;
        ++index) {
      final passed = now.subtract(Duration(days: index));
      await cacher.cacheRoads(
          passed, bounds.center.makeSquare(1), osmRoadsInPersistentCache);
    }
    // Lots of cache exists (we just created it)
    var cache = await cacher.getCachedRoads();
    expect(cache.length, equals(RoadsManager.CACHED_TERRITORIES_LIMIT * 2));

    // Fetch, results are not important
    await roadsManager.fetchRoadsWithinAndNearby(bounds);

    // Amount of cached went down to the limit
    cache = await cacher.getCachedRoads();
    expect(cache.length, equals(RoadsManager.CACHED_TERRITORIES_LIMIT));

    // Let's verify the oldest cache got deleted and the newest didn't
    for (var index = 0;
        index < RoadsManager.CACHED_TERRITORIES_LIMIT;
        ++index) {
      final cachedTerritory = cache[index];
      final expectedTime = now.subtract(Duration(days: index));
      expect(cachedTerritory.whenObtained, equals(expectedTime));
    }
  });
}
