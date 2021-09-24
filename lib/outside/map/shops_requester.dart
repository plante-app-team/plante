import 'package:plante/base/result.dart';
import 'package:plante/logging/log.dart';
import 'package:plante/model/coord.dart';
import 'package:plante/model/coords_bounds.dart';
import 'package:plante/model/product.dart';
import 'package:plante/model/shop.dart';
import 'package:plante/model/shop_product_range.dart';
import 'package:plante/model/shop_type.dart';
import 'package:plante/outside/backend/backend.dart';
import 'package:plante/outside/backend/backend_error.dart';
import 'package:plante/outside/backend/backend_shop.dart';
import 'package:plante/outside/map/fetched_shops.dart';
import 'package:plante/outside/map/open_street_map.dart';
import 'package:plante/outside/map/osm_overpass.dart';
import 'package:plante/outside/map/osm_shop.dart';
import 'package:plante/outside/map/shops_manager_types.dart';
import 'package:plante/outside/products/products_manager_error.dart';
import 'package:plante/outside/products/products_obtainer.dart';

class ShopsRequester {
  final Backend _backend;
  final ProductsObtainer _productsObtainer;

  ShopsRequester(this._backend, this._productsObtainer);

  Future<Result<FetchedShops, ShopsManagerError>> fetchShops(
      OsmOverpass overpass,
      {required CoordsBounds osmBounds,
      required CoordsBounds planteBounds,
      Iterable<OsmShop>? preloadedOsmShops}) async {
    if (!osmBounds.containsBounds(planteBounds) && osmBounds != planteBounds) {
      Log.e('Plante bounds are not expected to be bigger than OSM bounds. '
          'osm bounds: $osmBounds, plante bounds: $planteBounds');
    }

    // Either request OSM shops or use preloaded
    final Iterable<OsmShop> osmShops;
    if (preloadedOsmShops == null) {
      final osmShopsResult = await overpass.fetchShops(bounds: osmBounds);
      if (osmShopsResult.isErr) {
        return Err(_convertOsmErr(osmShopsResult.unwrapErr()));
      }
      osmShops = osmShopsResult.unwrap();
    } else {
      osmShops = preloadedOsmShops;
    }

    // Request Plante shops
    final osmShopsToRequestFromPlante =
        osmShops.where((e) => planteBounds.contains(e.coord));
    final backendShopsResult = await _backend
        .requestShops(osmShopsToRequestFromPlante.map((e) => e.osmId));
    if (backendShopsResult.isErr) {
      return Err(_convertBackendErr(backendShopsResult.unwrapErr()));
    }

    // Combine OSM and Plante shops
    final backendShops = backendShopsResult.unwrap();
    final shops =
        _combineOsmAndPlanteShops(osmShopsToRequestFromPlante, backendShops);

    // Finish forming the result
    final osmShopsMap = {
      for (final osmShop in osmShops) osmShop.osmId: osmShop
    };

    return Ok(FetchedShops(
      shops,
      planteBounds,
      osmShopsMap,
      osmBounds,
    ));
  }

  Map<String, Shop> _combineOsmAndPlanteShops(
      Iterable<OsmShop> osmShops, List<BackendShop> backendShops) {
    final backendShopsMap = {
      for (final backendShop in backendShops) backendShop.osmId: backendShop
    };
    final shops = <String, Shop>{};
    for (final osmShop in osmShops) {
      final backendShopNullable = backendShopsMap[osmShop.osmId];
      var shop = Shop((e) => e.osmShop.replace(osmShop));
      if (backendShopNullable != null) {
        shop = shop.rebuild((e) => e.backendShop.replace(backendShopNullable));
      }
      shops[osmShop.osmId] = shop;
    }
    return shops;
  }

  Future<Result<Map<String, Shop>, ShopsManagerError>> inflateOsmShops(
      List<OsmShop> osmShops) async {
    final backendShopsRes =
        await _backend.requestShops(osmShops.map((e) => e.osmId));
    if (backendShopsRes.isErr) {
      return Err(_convertBackendErr(backendShopsRes.unwrapErr()));
    }
    final backendShops = backendShopsRes.unwrap();
    return Ok(_combineOsmAndPlanteShops(osmShops, backendShops));
  }

  Future<Result<ShopProductRange, ShopsManagerError>> fetchShopProductRange(
      Shop shop) async {
    // Obtain products from backend
    final backendRes = await _backend.requestProductsAtShops([shop.osmId]);
    if (backendRes.isErr) {
      return Err(_convertBackendErr(backendRes.unwrapErr()));
    }
    if (backendRes.unwrap().isEmpty) {
      return Ok(ShopProductRange((e) => e.shop.replace(shop)));
    }
    final backendProductsAtShop = backendRes.unwrap().first;

    // Inflate backend products with OFF products
    final products = <Product>[];
    ProductsManagerError? lastProductsError;
    for (final backendProduct in backendProductsAtShop.products) {
      final productResult = await _productsObtainer.inflate(backendProduct);
      if (productResult.isErr) {
        lastProductsError = productResult.unwrapErr();
        continue;
      }
      final product = productResult.unwrap();
      if (product == null) {
        continue;
      }
      products.add(product);
    }
    if (products.isEmpty && lastProductsError != null) {
      return Err(_convertProductErr(lastProductsError));
    }

    return Ok(ShopProductRange((e) => e
      ..shop.replace(shop)
      ..products.addAll(products)
      ..productsLastSeenSecsUtc
          .addEntries(backendProductsAtShop.productsLastSeenUtc.entries)));
  }

  Future<Result<None, ShopsManagerError>> putProductToShops(
      Product product, List<Shop> shops) async {
    for (final shop in shops) {
      final res = await _backend.putProductToShop(product.barcode, shop.osmId);
      if (res.isErr) {
        return Err(_convertBackendErr(res.unwrapErr()));
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
          ..osmId = backendShop.osmId
          ..name = name
          ..type = type.osmName
          ..longitude = coord.lon
          ..latitude = coord.lat))));
    } else {
      return Err(_convertBackendErr(res.unwrapErr()));
    }
  }
}

ShopsManagerError _convertOsmErr(OpenStreetMapError err) {
  switch (err) {
    case OpenStreetMapError.NETWORK:
      return ShopsManagerError.NETWORK_ERROR;
    case OpenStreetMapError.OTHER:
      return ShopsManagerError.OSM_SERVERS_ERROR;
  }
}

ShopsManagerError _convertBackendErr(BackendError err) {
  switch (err.errorKind) {
    case BackendErrorKind.NETWORK_ERROR:
      return ShopsManagerError.NETWORK_ERROR;
    default:
      return ShopsManagerError.OTHER;
  }
}

ShopsManagerError _convertProductErr(ProductsManagerError err) {
  switch (err) {
    case ProductsManagerError.NETWORK_ERROR:
      return ShopsManagerError.NETWORK_ERROR;
    default:
      return ShopsManagerError.OTHER;
  }
}
