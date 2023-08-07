import 'dart:convert';

import 'package:built_collection/built_collection.dart';
import 'package:http/http.dart' as http;
import 'package:mockito/mockito.dart';
import 'package:plante/base/base.dart';
import 'package:plante/base/result.dart';
import 'package:plante/model/coord.dart';
import 'package:plante/model/coords_bounds.dart';
import 'package:plante/model/product.dart';
import 'package:plante/model/shop.dart';
import 'package:plante/outside/backend/backend_product.dart';
import 'package:plante/outside/backend/backend_shop.dart';
import 'package:plante/outside/backend/cmds/create_shop_cmd.dart';
import 'package:plante/outside/backend/cmds/put_product_to_shop_cmd.dart';
import 'package:plante/outside/backend/cmds/shops_by_osm_uids_cmd.dart';
import 'package:plante/outside/backend/cmds/shops_in_bounds_cmd.dart';
import 'package:plante/outside/backend/shops_in_bounds_response.dart';
import 'package:plante/outside/map/osm/open_street_map.dart';
import 'package:plante/outside/map/osm/osm_shop.dart';
import 'package:plante/outside/map/osm/osm_uid.dart';
import 'package:plante/outside/map/shops_large_local_cache.dart';
import 'package:plante/outside/map/shops_manager.dart';

import '../../common_mocks.mocks.dart';
import '../../z_fakes/fake_analytics.dart';
import '../../z_fakes/fake_backend.dart';
import '../../z_fakes/fake_mobile_app_config_manager.dart';
import '../../z_fakes/fake_off_geo_helper.dart';
import '../../z_fakes/fake_osm_cacher.dart';
import '../../z_fakes/fake_products_obtainer.dart';

class ShopsManagerTestCommons {
  late MockOsmOverpass osm;
  late FakeBackend backend;
  late FakeProductsObtainer productsObtainer;
  late FakeAnalytics analytics;
  late FakeOsmCacher osmCacher;
  late FakeOffGeoHelper offGeoHelper;
  late ShopsManager shopsManager;

  final osmUID1 = OsmUID.parse('1:1');
  final osmUID2 = OsmUID.parse('1:2');
  var osmShops = <OsmShop>[];
  var backendShops = <BackendShop>[];
  Map<OsmUID, Shop> get fullShops {
    final result = <OsmUID, Shop>{};
    for (final osmShop in osmShops) {
      final backendShop = backendShops.where((e) => e.osmUID == osmShop.osmUID);
      final shop = Shop((e) {
        e.osmShop.replace(osmShop);
        if (backendShop.isNotEmpty) {
          e.backendShop.replace(backendShop.first);
        }
      });
      result[shop.osmUID] = shop;
    }
    return result;
  }

  final bounds = CoordsBounds(
      northeast: Coord(lat: 15.001, lon: 15.001),
      southwest: Coord(lat: 14.999, lon: 14.999));
  final farBounds = CoordsBounds(
      northeast: Coord(lat: 16.001, lon: 16.001),
      southwest: Coord(lat: 15.999, lon: 15.999));

  final rangeBackendProducts = [
    BackendProduct((e) => e.barcode = '123'),
    BackendProduct((e) => e.barcode = '124'),
    BackendProduct((e) => e.barcode = '125'),
  ];
  final rangeProducts = [
    Product((e) => e.barcode = '123'),
    Product((e) => e.barcode = '124'),
    Product((e) => e.barcode = '125'),
  ];

  ShopsManagerTestCommons._();

  static Future<ShopsManagerTestCommons> create() async {
    final instance = ShopsManagerTestCommons._();
    await instance._initAsync();
    return instance;
  }

  Future<void> dispose() async {
    await shopsManager.dispose();
  }

  Future<void> _initAsync() async {
    osmShops = [
      OsmShop((e) => e
        ..osmUID = osmUID1
        ..name = 'shop1'
        ..type = 'supermarket'
        ..longitude = 15
        ..latitude = 15),
      OsmShop((e) => e
        ..osmUID = osmUID2
        ..name = 'shop2'
        ..type = 'convenience'
        ..longitude = 15
        ..latitude = 15),
    ];
    backendShops = [
      BackendShop((e) => e
        ..osmUID = osmUID1
        ..productsCount = 2),
      BackendShop((e) => e
        ..osmUID = osmUID2
        ..productsCount = 1),
    ];

    osm = MockOsmOverpass();
    backend = FakeBackend();
    productsObtainer = FakeProductsObtainer();
    analytics = FakeAnalytics();
    osmCacher = FakeOsmCacher();
    offGeoHelper = FakeOffGeoHelper();
    shopsManager = await createShopsManager(first: true);

    backend.setResponse_testing(PUT_PRODUCT_TO_SHOP_CMD, '{}');
    when(osm.fetchShops(
            bounds: anyNamed('bounds'), osmUIDs: anyNamed('osmUIDs')))
        .thenAnswer((invc) async {
      final bounds =
          invc.namedArguments[const Symbol('bounds')] as CoordsBounds?;
      final osmUIDs =
          invc.namedArguments[const Symbol('osmUIDs')] as Iterable<OsmUID>?;
      var result = osmShops.toList();
      if (bounds != null) {
        result = result.where((e) => bounds.contains(e.coord)).toList();
      }
      if (osmUIDs != null) {
        result = result.where((e) => osmUIDs.contains(e.osmUID)).toList();
      }
      return Ok(result);
    });
    backend.setResponseFunction_testing(SHOPS_IN_BOUNDS_CMD, (req) {
      final coordsMap = {
        for (final osmShop in osmShops) osmShop.osmUID: osmShop.coord
      };
      final north = double.parse(req.url.queryParameters['north']!);
      final south = double.parse(req.url.queryParameters['south']!);
      final west = double.parse(req.url.queryParameters['west']!);
      final east = double.parse(req.url.queryParameters['east']!);
      final bounds = CoordsBounds(
        southwest: Coord(lat: south, lon: west),
        northeast: Coord(lat: north, lon: east),
      );
      final result = <BackendShop>[];
      for (final backendShop in backendShops) {
        final coord = coordsMap[backendShop.osmUID];
        if (coord != null && bounds.contains(coord)) {
          result.add(backendShop);
        }
      }
      return Ok(
          jsonEncode(createShopsInBoundsResponse(shops: result).toJson()));
    });

    backend.setResponseFunction_testing('/$SHOPS_BY_OSM_UIDS_CMD/', (req) {
      final request = req as http.Request;
      final uidsStrs = jsonDecode(request.body)['osm_uids'] as List<dynamic>;
      final uids = uidsStrs.map((e) => OsmUID.parse(e as String));
      final shops = {
        for (final shop in backendShops.where((e) => uids.contains(e.osmUID)))
          shop.osmUID.toString(): shop.toJson()
      };
      return Ok(jsonEncode({SHOPS_BY_OSM_UIDS_CMD_RESULT_FIELD: shops}));
    });

    productsObtainer.addKnownProducts(rangeProducts);

    backend.setResponseFunction_testing(CREATE_SHOP_CMD, (req) {
      final lon = double.parse(req.url.queryParameters['lon']!);
      final lat = double.parse(req.url.queryParameters['lat']!);
      final name = req.url.queryParameters['name'];
      final type = req.url.queryParameters['type'];
      final coord = Coord(lat: lat, lon: lon);

      final backendShop = BackendShop((e) => e
        ..osmUID = OsmUID.parse('1:${randInt(1, 99999)}')
        ..productsCount = 0);
      backendShops.add(backendShop);

      final osmShop = OsmShop((e) => e
        ..osmUID = backendShop.osmUID
        ..longitude = coord.lon
        ..latitude = coord.lat
        ..name = name
        ..type = type);
      osmShops.add(osmShop);

      fullShops[backendShop.osmUID] = Shop((e) => e
        ..backendShop.replace(backendShop)
        ..osmShop.replace(osmShop));
      return Ok(jsonEncode({'osm_uid': backendShop.osmUID.toString()}));
    });
  }

  Future<ShopsManager> createShopsManager(
      {bool first = false, ShopsLargeLocalCache? largeCache}) async {
    if (!first) {
      await shopsManager.dispose();
    }
    return ShopsManager(
      OpenStreetMap.forTesting(
          overpass: osm, configManager: FakeMobileAppConfigManager()),
      backend,
      productsObtainer,
      analytics,
      osmCacher,
      offGeoHelper,
      largeCache: largeCache,
    );
  }

  ShopsInBoundsResponse createShopsInBoundsResponse({
    Iterable<BackendShop> shops = const [],
    Map<OsmUID, List<String>> barcodes = const {},
  }) {
    final shopsConverted = {
      for (final shop in shops) shop.osmUID.toString(): shop
    };
    final barcodesConverted = barcodes.map(
        (key, value) => MapEntry(key.toString(), BuiltList<String>(value)));
    return ShopsInBoundsResponse((e) => e
      ..shops.addAll(shopsConverted)
      ..barcodes.addAll(barcodesConverted));
  }
}
