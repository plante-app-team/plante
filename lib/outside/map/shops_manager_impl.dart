import 'dart:math';

import 'package:plante/base/result.dart';
import 'package:plante/model/product.dart';
import 'package:plante/model/shop.dart';
import 'package:plante/model/shop_product_range.dart';
import 'package:plante/model/shop_type.dart';
import 'package:plante/outside/backend/backend.dart';
import 'package:plante/outside/backend/backend_error.dart';
import 'package:plante/outside/map/open_street_map.dart';
import 'package:plante/outside/map/osm_shop.dart';
import 'package:plante/outside/map/shops_manager_types.dart';
import 'package:plante/outside/products/products_manager.dart';
import 'package:plante/outside/products/products_manager_error.dart';

class ShopsManagerImpl {
  final _recentlyCreatedShops = <String, Shop>{};
  final _listeners = <ShopsManagerListener>[];
  final OpenStreetMap _openStreetMap;
  final Backend _backend;
  final ProductsManager _productsManager;

  ShopsManagerImpl(this._openStreetMap, this._backend, this._productsManager);

  void addListener(ShopsManagerListener listener) {
    _listeners.add(listener);
  }

  void removeListener(ShopsManagerListener listener) {
    _listeners.remove(listener);
  }

  Future<Result<Map<String, Shop>, ShopsManagerError>> fetchShops(
      Point<double> northeast, Point<double> southwest) async {
    final osmShopsResult =
        await _openStreetMap.fetchShops(northeast, southwest);
    if (osmShopsResult.isErr) {
      return Err(_convertOsmErr(osmShopsResult.unwrapErr()));
    }
    final osmShops = osmShopsResult.unwrap();
    final backendShopsResult =
        await _backend.requestShops(osmShops.map((e) => e.osmId));
    if (backendShopsResult.isErr) {
      return Err(_convertBackendErr(backendShopsResult.unwrapErr()));
    }
    final backendShops = backendShopsResult.unwrap();

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
    shops.addAll(_recentlyCreatedShops);
    return Ok(shops);
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
      final productResult = await _productsManager.inflate(backendProduct);
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
    bool someChange = false;
    for (final shop in shops) {
      final res = await _backend.putProductToShop(product.barcode, shop.osmId);
      if (res.isErr) {
        if (someChange) {
          _listeners.forEach((e) {
            e.onLocalShopsChange();
          });
        }
        return Err(_convertBackendErr(res.unwrapErr()));
      }
      someChange = true;
    }
    _listeners.forEach((e) {
      e.onLocalShopsChange();
    });
    return Ok(None());
  }

  Future<Result<Shop, ShopsManagerError>> createShop(
      {required String name,
      required Point<double> coords,
      required ShopType type}) async {
    final res = await _backend.createShop(
        name: name, coords: coords, type: type.osmName);
    if (res.isOk) {
      final backendShop = res.unwrap();
      final shop = Shop((e) => e
        ..backendShop.replace(backendShop)
        ..osmShop.replace(OsmShop((e) => e
          ..osmId = backendShop.osmId
          ..name = name
          ..type = type.osmName
          ..longitude = coords.x
          ..latitude = coords.y)));
      _recentlyCreatedShops[shop.osmId] = shop;
      _listeners.forEach((e) {
        e.onLocalShopsChange();
      });
      return Ok(shop);
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
      return ShopsManagerError.OTHER;
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
