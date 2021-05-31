import 'dart:math';

import 'package:plante/base/result.dart';
import 'package:plante/model/product.dart';
import 'package:plante/model/shop.dart';
import 'package:plante/model/shop_product_range.dart';
import 'package:plante/outside/backend/backend.dart';
import 'package:plante/outside/backend/backend_error.dart';
import 'package:plante/outside/map/open_street_map.dart';
import 'package:plante/outside/products/products_manager.dart';
import 'package:plante/outside/products/products_manager_error.dart';

enum ShopsManagerError { NETWORK_ERROR, OTHER }

class ShopsManager {
  final OpenStreetMap _openStreetMap;
  final Backend _backend;
  final ProductsManager _productsManager;

  ShopsManager(this._openStreetMap, this._backend, this._productsManager);

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
      ..productsLastSeenUtc
          .addEntries(backendProductsAtShop.productsLastSeenUtc.entries)));
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
