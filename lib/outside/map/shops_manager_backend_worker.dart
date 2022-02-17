import 'package:plante/base/result.dart';
import 'package:plante/model/coord.dart';
import 'package:plante/model/coords_bounds.dart';
import 'package:plante/model/product.dart';
import 'package:plante/model/shop.dart';
import 'package:plante/model/shop_product_range.dart';
import 'package:plante/model/shop_type.dart';
import 'package:plante/outside/backend/backend.dart';
import 'package:plante/outside/backend/backend_error.dart';
import 'package:plante/outside/backend/backend_shop.dart';
import 'package:plante/outside/backend/product_at_shop_source.dart';
import 'package:plante/outside/backend/product_presence_vote_result.dart';
import 'package:plante/outside/map/fetched_shops.dart';
import 'package:plante/outside/map/osm/open_street_map.dart';
import 'package:plante/outside/map/osm/osm_overpass.dart';
import 'package:plante/outside/map/osm/osm_shop.dart';
import 'package:plante/outside/map/osm/osm_uid.dart';
import 'package:plante/outside/map/shops_manager_types.dart';
import 'package:plante/products/products_obtainer.dart';

class ShopsManagerBackendWorker {
  final Backend _backend;
  final ProductsObtainer _productsObtainer;

  ShopsManagerBackendWorker(this._backend, this._productsObtainer);

  Future<Result<FetchedShops, ShopsManagerError>> fetchShops(
      OsmOverpass overpass,
      {required CoordsBounds osmBounds,
      required CoordsBounds planteBounds,
      Iterable<OsmShop>? preloadedOsmShops}) async {
    // Either request OSM shops or use preloaded
    final Iterable<OsmShop> osmShops;
    if (preloadedOsmShops == null) {
      final osmShopsResult = await overpass.fetchShops(bounds: osmBounds);
      if (osmShopsResult.isErr) {
        return Err(osmShopsResult.unwrapErr().convert());
      }
      osmShops = osmShopsResult.unwrap();
    } else {
      osmShops = preloadedOsmShops;
    }

    // Request Plante shops
    final backendShopsResponseRes =
        await _backend.requestShopsWithin(planteBounds);
    if (backendShopsResponseRes.isErr) {
      return Err(backendShopsResponseRes.unwrapErr().convert());
    }

    final osmShopsWithinPlanteBounds =
        osmShops.where((e) => planteBounds.contains(e.coord)).toList();
    final backendShopsResponse = backendShopsResponseRes.unwrap();
    // It's quite possible that [backendShops] would have some shops
    // which are not present in [osmShopsWithinPlanteBounds].
    // That happens when another user adds a new shop to the map and
    // the OSM shops here are used from local persistent cache, which
    // wasn't updated yet.
    // NOTE: we don't persistently cache Plante shops, that's why
    // we treat the Plante shops returned from the Plante backend as
    // the source of truth.
    final backendShops = backendShopsResponse.shops.values;
    final reqRes = await _acquireMissingOsmShops(
        osmShopsWithinPlanteBounds, backendShops, overpass);
    if (reqRes.isErr) {
      return Err(reqRes.unwrapErr());
    }
    osmShopsWithinPlanteBounds.addAll(reqRes.unwrap());
    // Combine OSM and Plante shops
    final shops =
        _combineOsmAndPlanteShops(osmShopsWithinPlanteBounds, backendShops);

    // Finish forming the result
    final osmShopsMap = {
      for (final osmShop in osmShops) osmShop.osmUID: osmShop
    };

    final barcodesMap = backendShopsResponse.barcodes
        .toMap()
        .map((key, value) => MapEntry(OsmUID.parse(key), value.toList()));
    return Ok(FetchedShops(
      shops,
      barcodesMap,
      planteBounds,
      osmShopsMap,
      osmBounds,
    ));
  }

  Future<Result<List<OsmShop>, ShopsManagerError>> _acquireMissingOsmShops(
      Iterable<OsmShop> osmShops,
      Iterable<BackendShop> backendShops,
      OsmOverpass overpass) async {
    final backendUids = backendShops.map((e) => e.osmUID);
    final osmUids = osmShops.map((e) => e.osmUID);
    final missingOsmUids =
        backendUids.toSet().where((e) => !osmUids.contains(e));
    if (missingOsmUids.isEmpty) {
      return Ok(const []);
    }
    final missingShops =
        await overpass.fetchShops(osmUIDs: missingOsmUids.toList());
    if (missingShops.isErr) {
      return Err(missingShops.unwrapErr().convert());
    }
    return Ok(missingShops.unwrap());
  }

  Map<OsmUID, Shop> _combineOsmAndPlanteShops(
      Iterable<OsmShop> osmShops, Iterable<BackendShop> backendShops) {
    final backendShopsMap = {
      for (final backendShop in backendShops) backendShop.osmUID: backendShop
    };
    final shops = <OsmUID, Shop>{};
    for (final osmShop in osmShops) {
      final backendShopNullable = backendShopsMap[osmShop.osmUID];
      var shop = Shop((e) => e.osmShop.replace(osmShop));
      if (backendShopNullable != null) {
        shop = shop.rebuild((e) => e.backendShop.replace(backendShopNullable));
      }
      shops[osmShop.osmUID] = shop;
    }
    shops.removeWhere((key, value) => value.deleted);
    return shops;
  }

  Future<Result<Map<OsmUID, Shop>, ShopsManagerError>> inflateOsmShops(
      List<OsmShop> osmShops) async {
    final backendShopsRes =
        await _backend.requestShopsByOsmUIDs(osmShops.map((e) => e.osmUID));
    if (backendShopsRes.isErr) {
      return Err(backendShopsRes.unwrapErr().convert());
    }
    final backendShops = backendShopsRes.unwrap();
    return Ok(_combineOsmAndPlanteShops(osmShops, backendShops));
  }

  Future<Result<ShopProductRange, ShopsManagerError>> fetchShopProductRange(
      Shop shop) async {
    // Obtain products from backend
    final backendRes = await _backend.requestProductsAtShops([shop.osmUID]);
    if (backendRes.isErr) {
      return Err(backendRes.unwrapErr().convert());
    }
    if (backendRes.unwrap().isEmpty) {
      return Ok(ShopProductRange((e) => e.shop.replace(shop)));
    }
    final backendProductsAtShop = backendRes.unwrap().first;

    final products = <Product>[];
    if (backendProductsAtShop.products.isNotEmpty) {
      // Inflate backend products with OFF products
      final result = await _productsObtainer
          .inflateProducts(backendProductsAtShop.products.toList());
      if (result.isErr) {
        return Err(result.unwrapErr().convert());
      }
      products.addAll(result.unwrap());
    }

    return Ok(ShopProductRange((e) => e
      ..shop.replace(shop)
      ..products.addAll(products)
      ..productsLastSeenSecsUtc
          .addEntries(backendProductsAtShop.productsLastSeenUtc.entries)));
  }

  Future<Result<None, ShopsManagerError>> putProductToShops(
      Product product, List<Shop> shops, ProductAtShopSource source) async {
    for (final shop in shops) {
      final res =
          await _backend.putProductToShop(product.barcode, shop, source);
      if (res.isErr) {
        return Err(res.unwrapErr().convert());
      }
    }
    return Ok(None());
  }

  Future<Result<Shop, ShopsManagerError>> createShop(
      {required String name,
      required Coord coord,
      required ShopType type}) async {
    final res =
        await _backend.createShop(name: name, coord: coord, type: type.osmName);
    if (res.isOk) {
      final backendShop = res.unwrap();
      return Ok(Shop((e) => e
        ..backendShop.replace(backendShop)
        ..osmShop.replace(OsmShop((e) => e
          ..osmUID = backendShop.osmUID
          ..name = name
          ..type = type.osmName
          ..longitude = coord.lon
          ..latitude = coord.lat))));
    } else {
      return Err(res.unwrapErr().convert());
    }
  }

  Future<Result<ProductPresenceVoteResult, ShopsManagerError>>
      productPresenceVote(Product product, Shop shop, bool positive) async {
    final result = await _backend.productPresenceVote(
        product.barcode, shop.osmUID, positive);
    if (result.isErr) {
      return Err(result.unwrapErr().convert());
    }
    return Ok(result.unwrap());
  }
}

extension _OpenStreetMapErrorExt on OpenStreetMapError {
  ShopsManagerError convert() {
    switch (this) {
      case OpenStreetMapError.NETWORK:
        return ShopsManagerError.NETWORK_ERROR;
      case OpenStreetMapError.OTHER:
        return ShopsManagerError.OSM_SERVERS_ERROR;
    }
  }
}

extension _BackendErrorExt on BackendError {
  ShopsManagerError convert() {
    switch (errorKind) {
      case BackendErrorKind.NETWORK_ERROR:
        return ShopsManagerError.NETWORK_ERROR;
      default:
        return ShopsManagerError.OTHER;
    }
  }
}

extension _ProductsObtainerErrorExt on ProductsObtainerError {
  ShopsManagerError convert() {
    switch (this) {
      case ProductsObtainerError.NETWORK:
        return ShopsManagerError.NETWORK_ERROR;
      default:
        return ShopsManagerError.OTHER;
    }
  }
}
