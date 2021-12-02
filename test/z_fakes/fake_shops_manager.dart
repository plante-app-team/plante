import 'package:plante/base/base.dart';
import 'package:plante/base/date_time_extensions.dart';
import 'package:plante/base/pair.dart';
import 'package:plante/base/result.dart';
import 'package:plante/model/coord.dart';
import 'package:plante/model/coords_bounds.dart';
import 'package:plante/model/product.dart';
import 'package:plante/model/shop.dart';
import 'package:plante/model/shop_product_range.dart';
import 'package:plante/model/shop_type.dart';
import 'package:plante/outside/backend/backend_shop.dart';
import 'package:plante/outside/backend/product_presence_vote_result.dart';
import 'package:plante/outside/map/osm/osm_element_type.dart';
import 'package:plante/outside/map/osm/osm_shop.dart';
import 'package:plante/outside/map/osm/osm_uid.dart';
import 'package:plante/outside/map/shops_manager.dart';
import 'package:plante/outside/map/shops_manager_types.dart';

// ignore_for_file: non_constant_identifier_names

class FakeShopsManager implements ShopsManager {
  final _listeners = <ShopsManagerListener>[];
  final _shopsAreas = <CoordsBounds, List<Shop>>{};
  final _shopsRanges = <OsmUID, Result<ShopProductRange, ShopsManagerError>>{};

  ArgResCallback<CoordsBounds, Future<Iterable<Shop>>> _shopsLoader =
      (_) async => const [];

  final _fetchShopsCalls = <CoordsBounds>[];
  final _putProductToShopsCalls = <PutProductToShopsParams>[];
  var _createShopCalls = 0;
  var _fetchRangesCalls = 0;
  final _productPresenceVoteCalls = <Pair<Shop, Product>, List<bool>>{};

  void addPreloadedArea(CoordsBounds bounds, Iterable<Shop> shops) {
    _shopsAreas[bounds] = shops.toList();
    _notifyListeners();
  }

  void updatePreloadedArea(CoordsBounds bounds, Iterable<Shop> shops) {
    if (_shopsAreas[bounds] == null) {
      throw AssertionError(
          'Nothing to update - area $bounds is not loaded: $_shopsAreas');
    }
    _shopsAreas[bounds] = shops.toList();
    _notifyListeners();
  }

  void setAsyncShopsLoader(
      ArgResCallback<CoordsBounds, Future<Iterable<Shop>>> loader) {
    _shopsLoader = loader;
  }

  void setShopsLoader(ArgResCallback<CoordsBounds, Iterable<Shop>> loader) {
    _shopsLoader = (CoordsBounds bounds) async => loader.call(bounds);
  }

  void setShopRange(
      OsmUID uid, Result<ShopProductRange, ShopsManagerError> range) {
    _shopsRanges[uid] = range;
    _notifyListeners();
  }

  void clear_verifiedCalls() {
    _fetchShopsCalls.clear();
    _putProductToShopsCalls.clear();
    _createShopCalls = 0;
    _fetchRangesCalls = 0;
    _productPresenceVoteCalls.clear();
  }

  void verify_fetchShops_called({int? times}) {
    _verifyCalls(times, _fetchShopsCalls.length, 'fetchShops');
  }

  void _verifyCalls(int? times, int actualTimes, String fnName) {
    if (times != null) {
      if (times != actualTimes) {
        throw AssertionError(
            'fetchShops called $actualTimes times instead of $times');
      }
    } else if (actualTimes == 0) {
      throw AssertionError('fetchShops called 0 times');
    }
  }

  void verify_putProductToShops_called({int? times}) {
    _verifyCalls(times, _putProductToShopsCalls.length, 'putProductToShops');
  }

  void verity_createShop_called({int? times}) {
    _verifyCalls(times, _createShopCalls, 'createShop');
  }

  void verity_fetchShopProductRange_called({int? times}) {
    _verifyCalls(times, _fetchRangesCalls, 'fetchShopProductRange');
  }

  void verity_productPresenceVote_called({int? times}) {
    _verifyCalls(
        times, _productPresenceVoteCalls.length, 'productPresenceVote');
  }

  List<CoordsBounds> calls_fetchShop() => _fetchShopsCalls.toList();
  List<PutProductToShopsParams> calls_putProductToShops() =>
      _putProductToShopsCalls.toList();
  List<bool> calls_productPresenceVote(Shop shop, Product product) =>
      _productPresenceVoteCalls[Pair(shop, product)] ?? const [];

  //
  // Class implementation below
  //

  @override
  int get loadedAreasCount => _shopsAreas.length;

  @override
  void addListener(ShopsManagerListener listener) {
    _listeners.add(listener);
  }

  @override
  void removeListener(ShopsManagerListener listener) {
    _listeners.remove(listener);
  }

  void _notifyListeners() {
    _listeners.forEach((listener) => listener.onLocalShopsChange());
  }

  @override
  Future<bool> osmShopsCacheExistFor(CoordsBounds bounds) async {
    for (final area in _shopsAreas.keys) {
      if (area.containsBounds(bounds)) {
        return true;
      }
    }
    return false;
  }

  @override
  Future<void> clearCache() async {
    _shopsAreas.clear();
  }

  @override
  Future<Result<Shop, ShopsManagerError>> createShop(
      {required String name,
      required Coord coord,
      required ShopType type}) async {
    _createShopCalls += 1;
    final osmUid =
        OsmUID(OsmElementType.NODE, randInt(0, 999999999).toString());
    final newShop = Shop((e) => e
      ..osmShop.replace(OsmShop((e) => e
        ..osmUID = osmUid
        ..longitude = coord.lon
        ..latitude = coord.lat
        ..name = name))
      ..backendShop.replace(BackendShop((e) => e
        ..osmUID = osmUid
        ..productsCount = 0)));

    var notify = false;
    for (final areaShops in _shopsAreas.entries) {
      if (areaShops.key.contains(coord)) {
        areaShops.value.add(newShop);
        notify = true;
      }
    }
    if (notify) {
      _notifyListeners();
    }
    return Ok(newShop);
  }

  @override
  Future<Result<Map<OsmUID, Shop>, ShopsManagerError>> fetchShops(
      CoordsBounds bounds) async {
    _fetchShopsCalls.add(bounds);
    for (final areaShops in _shopsAreas.entries) {
      if (areaShops.key.containsBounds(bounds)) {
        final shops =
            areaShops.value.where((e) => bounds.contains(e.coord)).toList();
        final result = {for (final shop in shops) shop.osmUID: shop};
        return Ok(result);
      }
    }
    _shopsAreas[bounds] = (await _shopsLoader.call(bounds)).toList();
    _notifyListeners();
    final result = {for (final shop in _shopsAreas[bounds]!) shop.osmUID: shop};
    return Ok(result);
  }

  @override
  Future<Result<Map<OsmUID, Shop>, ShopsManagerError>> inflateOsmShops(
      Iterable<OsmShop> shops) async {
    final resultShops = <OsmUID, Shop>{};
    for (final osmShop in shops) {
      for (final areaShops in _shopsAreas.entries) {
        final foundShops =
            areaShops.value.where((shop) => shop.osmUID == osmShop.osmUID);
        if (foundShops.isNotEmpty) {
          resultShops[osmShop.osmUID] = foundShops.first;
        }
      }
    }

    for (final osmShop in shops) {
      if (resultShops.containsKey(osmShop.osmUID)) {
        continue;
      }
      resultShops[osmShop.osmUID] = Shop((e) => e..osmShop.replace(osmShop));
    }

    return Ok(resultShops);
  }

  @override
  Future<Result<ProductPresenceVoteResult, ShopsManagerError>>
      productPresenceVote(Product product, Shop shop, bool positive) async {
    final key = Pair(shop, product);
    if (!_productPresenceVoteCalls.containsKey(key)) {
      _productPresenceVoteCalls[key] = <bool>[];
    }
    _productPresenceVoteCalls[key]!.add(positive);
    return Ok(ProductPresenceVoteResult(productDeleted: false));
  }

  @override
  Future<Result<None, ShopsManagerError>> putProductToShops(
      Product product, List<Shop> shops) async {
    _putProductToShopsCalls.add(PutProductToShopsParams(product, shops));
    for (final shop in shops) {
      var range = _shopsRanges[shop.osmUID];
      if (range?.isErr == true) {
        return Err(range!.unwrapErr());
      }
      range ??= Ok(ShopProductRange((e) => e.shop = shop.toBuilder()));
      range = Ok(range
          .unwrap()
          .rebuildWithProduct(product, DateTime.now().secondsSinceEpoch));
      _shopsRanges[shop.osmUID] = range;
    }
    _notifyListeners();
    return Ok(None());
  }

  @override
  Future<Result<ShopProductRange, ShopsManagerError>> fetchShopProductRange(
      Shop shop,
      {bool noCache = false}) async {
    _fetchRangesCalls += 1;
    final emptyRange = ShopProductRange((e) => e.shop.replace(shop));
    return _shopsRanges[shop.osmUID] ?? Ok(emptyRange);
  }
}

class PutProductToShopsParams {
  final Product product;
  final List<Shop> shops;
  PutProductToShopsParams(this.product, this.shops);
}
