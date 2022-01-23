import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:openfoodfacts/model/Product.dart' as off;
import 'package:openfoodfacts/openfoodfacts.dart' as off;
import 'package:openfoodfacts/utils/ProductListQueryConfiguration.dart' as off;
import 'package:plante/base/coord_utils.dart';
import 'package:plante/base/general_error.dart';
import 'package:plante/base/result.dart';
import 'package:plante/logging/analytics.dart';
import 'package:plante/logging/log.dart';
import 'package:plante/model/lang_code.dart';
import 'package:plante/model/shop.dart';
import 'package:plante/outside/map/address_obtainer.dart';
import 'package:plante/outside/map/osm/open_street_map.dart';
import 'package:plante/outside/off/off_api.dart';
import 'package:plante/outside/off/off_user.dart';

class OffGeoHelper {
  static const CLOSE_SHOPS_DISTANCE_METERS = 2000;
  static const _NEEDED_OFF_FIELDS = [
    off.ProductField.BARCODE,
    off.ProductField.COUNTRIES,
    off.ProductField.COUNTRIES_TAGS,
    off.ProductField.STORES,
  ];
  final OffApi _off;
  final AddressObtainer _addressObtainer;
  final Analytics _analytics;

  OffGeoHelper(this._off, this._addressObtainer, this._analytics);

  Future<Result<None, GeneralError>> addGeodataToProduct(
      String barcode, Iterable<Shop> shops) async {
    return await addGeodataToProducts([barcode], shops);
  }

  Future<Result<None, GeneralError>> addGeodataToProducts(
      List<String> barcodes, Iterable<Shop> shops) async {
    final result = await _addGeodataToProductsImpl(barcodes, shops);
    if (result.isOk) {
      _analytics.sendEvent('add_geodata_to_off_product_success');
    } else {
      _analytics.sendEvent('add_geodata_to_off_product_failure');
    }
    return result;
  }

  Future<Result<None, GeneralError>> _addGeodataToProductsImpl(
      List<String> barcodes, Iterable<Shop> shops) async {
    if (barcodes.isEmpty || shops.isEmpty) {
      return Ok(None());
    }

    final productsRes = await _getProducts(barcodes);
    if (productsRes.isErr) {
      return Err(productsRes.unwrapErr());
    }
    final products = productsRes.unwrap();
    final initialProductsData = {
      for (final product in products) product.barcode!: product.toData()
    };

    final shopsCountriesRes = await _countriesOf(shops);
    if (shopsCountriesRes.isErr) {
      return Err(shopsCountriesRes.unwrapErr());
    }
    final shopsCountries = shopsCountriesRes.unwrap();

    _addCountriesToProducts(shopsCountries.values.toSet(), products);
    _addShopsToProducts(shops, products);

    return await _saveProducts(products, initialProductsData);
  }

  Future<Result<Iterable<off.Product>, GeneralError>> _getProducts(
      List<String> barcodes) async {
    // Get products: countries, countries tags en, stores
    final configuration = off.ProductListQueryConfiguration(
      barcodes,
      languages: [off.OpenFoodFactsLanguage.ENGLISH],
      fields: _NEEDED_OFF_FIELDS,
    );
    final off.SearchResult offProductResult;
    try {
      offProductResult = await _off.getProductList(configuration);
    } on IOException catch (e) {
      Log.w('Network error in OffGeoHelper.addGeodataToProducts', ex: e);
      return Err(GeneralError.NETWORK);
    }

    final products = offProductResult.products;
    if (products == null || products.isEmpty) {
      Log.w(
          'OFF error in OffGeoHelper.addGeodataToProducts: $offProductResult');
      return Err(GeneralError.OTHER);
    }
    return Ok(products);
  }

  Future<Result<Map<Shop, String>, GeneralError>> _countriesOf(
      Iterable<Shop> shops) async {
    // Get countries names for each of the shops (reuse country name of
    // a shop if it's near to another already queried shop)
    final shopsCountries = <Shop, String>{};
    for (final shop in shops) {
      for (final entry in shopsCountries.entries) {
        final alreadyProcessedShop = entry.key;
        final coord1 = alreadyProcessedShop.coord;
        final coord2 = shop.coord;
        if (metersBetween(coord1, coord2) <= CLOSE_SHOPS_DISTANCE_METERS) {
          // Found a shop nearby
          shopsCountries[shop] = entry.value;
          break;
        }
      }
      if (shopsCountries[shop] != null) {
        continue;
      }

      final addressRes = await _addressObtainer.addressOfCoords(shop.coord,
          langCode: LangCode.en.name);
      if (addressRes.isErr) {
        return Err(addressRes.unwrapErr().convert());
      }
      final address = addressRes.unwrap();
      final country = address.country;
      if (country == null) {
        Log.w('No country for $shop in OffGeoHelper._countriesOf');
        return Err(GeneralError.OTHER);
      }
      shopsCountries[shop] = country;
    }
    return Ok(shopsCountries);
  }

  void _addCountriesToProducts(
      Set<String> countries, Iterable<off.Product> products) {
    // Add countries if they're not there yet
    for (final product in products) {
      // NOTE: [Product.countries] has a list of countries in a complex format:
      // - countries are either in product's main language,
      // - or countries have a lang prefix, e.g.: "fr:Belgique".
      // The new list of countries we have, however, is in English, so we need
      // to compare existing countries list when it's in English.
      // To achieve that, we use [countriesTags] instead of [countries].
      final productCountries = product.countriesTags ?? [];
      final productCountriesComparable =
          productCountries.map((e) => e.toLowerCase()).map((e) {
        if (e.startsWith(RegExp(r'\w+:'))) {
          return e.substring(e.indexOf(':') + 1);
        } else {
          return e;
        }
      });
      final newCountriesForProduct = countries.toSet();
      newCountriesForProduct.removeWhere(
          (e) => productCountriesComparable.contains(e.toLowerCase()));

      // We have list of countries in English, but product expects it in
      // its main language. To let the product know the language of countries,
      // we prepend the language as a "en:" prefix.
      final newCountriesStr =
          newCountriesForProduct.map((e) => 'en:$e').join(',');
      final countriesStr = product.countries;
      if (newCountriesStr.isNotEmpty) {
        if (countriesStr == null || countriesStr.isEmpty) {
          product.countries = newCountriesStr;
        } else {
          product.countries = '$countriesStr,$newCountriesStr';
        }
      }
    }
  }

  void _addShopsToProducts(
      Iterable<Shop> shops, Iterable<off.Product> products) {
    // Add stores to products, if they're not there yet
    final shopsNames = shops.map((e) => e.name.trim());
    for (final product in products) {
      final offStores = (product.stores ?? '')
          .split(',')
          .where((e) => e.trim().isNotEmpty)
          .toList();
      for (final shopName in shopsNames) {
        if (!offStores.contains(shopName)) {
          offStores.add(shopName);
        }
      }
      product.stores = offStores.join(',');
    }
  }

  Future<Result<None, GeneralError>> _saveProducts(
      Iterable<off.Product> products,
      Map<String, Map<String, String>> initialProductsData) async {
    for (final product in products) {
      final productData = product.toData();
      final initProductData = initialProductsData[product.barcode!] ?? const {};
      if (mapEquals(productData, initProductData)) {
        continue;
      }

      final offResult;
      try {
        offResult = await _off.saveProduct(_offUser(), product);
      } on IOException catch (e) {
        Log.w('OffGeoHelper._saveProducts 1, e', ex: e);
        return Err(GeneralError.NETWORK);
      }
      if (offResult.error != null) {
        return Err(GeneralError.OTHER);
      }
    }
    return Ok(None());
  }
}

off.User _offUser() =>
    const off.User(userId: OffUser.USERNAME, password: OffUser.PASSWORD);

extension on OpenStreetMapError {
  GeneralError convert() {
    switch (this) {
      case OpenStreetMapError.NETWORK:
        return GeneralError.NETWORK;
      case OpenStreetMapError.OTHER:
        return GeneralError.OTHER;
    }
  }
}
