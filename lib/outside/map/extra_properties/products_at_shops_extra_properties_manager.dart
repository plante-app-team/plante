import 'dart:async';

import 'package:plante/base/base.dart';
import 'package:plante/outside/map/extra_properties/barcode_property.dart';
import 'package:plante/outside/map/extra_properties/map_extra_properties_cacher.dart';
import 'package:plante/outside/map/extra_properties/product_at_shop_extra_property.dart';
import 'package:plante/outside/map/extra_properties/product_at_shop_extra_property_type.dart';
import 'package:plante/outside/map/osm/osm_uid.dart';

class ProductsAtShopsExtraPropertiesManager {
  final MapExtraPropertiesCacher _cacher;

  final _localCache =
      Completer<Map<OsmUID, List<ProductAtShopExtraProperty>>>();

  ProductsAtShopsExtraPropertiesManager(this._cacher) {
    _initAsync();
  }

  Future<void> _initAsync() async {
    final Map<OsmUID, List<ProductAtShopExtraProperty>> result = {};
    final allProperties = await _cacher.getAllProductsAtShopProperties();
    final now = DateTime.now();
    for (final property in allProperties) {
      if (now.difference(property.whenSet) > property.type.lifetime) {
        await _cacher.deleteProductAtShopProperty(
            property.type, property.osmUID, property.barcode);
      } else {
        result.addProperty(property);
      }
    }
    _localCache.complete(result);
  }

  Future<void> setProperty(ProductAtShopExtraPropertyType type, OsmUID shopUID,
      String barcode, int? value) async {
    final localCache = await _localCache.future;
    final property = ProductAtShopExtraProperty.create(
        type: type,
        whenSet: DateTime.now(),
        barcode: barcode,
        osmUID: shopUID,
        intVal: value);
    if (value != null) {
      localCache.addProperty(property);
    } else {
      localCache.removeProperty(property);
    }
    await _cacher.setProductAtShopProperty(property);
  }

  Future<int?> getProperty(ProductAtShopExtraPropertyType type, OsmUID shopUID,
      String barcode) async {
    final localCache = await _localCache.future;
    final properties = localCache[shopUID]?.where(
        (e) => e.osmUID == shopUID && e.barcode == barcode && e.type == type);
    if (properties == null || properties.isEmpty) {
      return null;
    } else {
      return properties.first.intVal;
    }
  }

  Future<Map<OsmUID, List<BarcodeProperty<int>>>> getProperties(
      ProductAtShopExtraPropertyType type, Iterable<OsmUID> shopsUIDs) async {
    return await _getPropertiesImpl(type, shopsUIDs, (val) => val);
  }

  Future<Map<OsmUID, List<BarcodeProperty<T>>>> _getPropertiesImpl<T>(
      ProductAtShopExtraPropertyType type,
      Iterable<OsmUID> shopsUIDs,
      ArgResCallback<int, T> convertor) async {
    final localCache = await _localCache.future;

    final Map<OsmUID, List<BarcodeProperty<T>>> result = {};
    for (final shopUID in shopsUIDs) {
      final properties = localCache[shopUID]
              ?.where((e) => e.osmUID == shopUID && e.type == type) ??
          const [];
      final shopProperties = properties
          .where((e) => e.intVal != null)
          .map((e) => BarcodeProperty(e.barcode, convertor.call(e.intVal!)))
          .toList();
      if (shopProperties.isNotEmpty) {
        result[shopUID] = shopProperties;
      }
    }
    return result;
  }

  Future<Map<OsmUID, Set<String>>> getBarcodesWithValue(
      ProductAtShopExtraPropertyType type,
      int value,
      Iterable<OsmUID> shopsUIDs) async {
    return await _getBarcodesWithPropertiesValueImpl(
      type,
      value,
      shopsUIDs,
      (e) => e,
    );
  }

  Future<Map<OsmUID, Set<String>>> _getBarcodesWithPropertiesValueImpl<T>(
      ProductAtShopExtraPropertyType type,
      T value,
      Iterable<OsmUID> shopsUIDs,
      ArgResCallback<int, T> convertor) async {
    final propertiesAtShops =
        await _getPropertiesImpl(type, shopsUIDs, (val) => val);
    final result = <OsmUID, Set<String>>{};
    for (final propertiesAtShop in propertiesAtShops.entries) {
      final barcodes = propertiesAtShop.value
          .where((e) => convertor.call(e.val) == value)
          .map((e) => e.barcode)
          .toSet();
      if (barcodes.isNotEmpty) {
        result[propertiesAtShop.key] = barcodes;
      }
    }
    return result;
  }

  Future<void> setBoolProperty(ProductAtShopExtraPropertyType type,
      OsmUID shopUID, String barcode, bool? value) async {
    int? intVal;
    if (value != null) {
      intVal = value ? 1 : 0;
    }
    await setProperty(type, shopUID, barcode, intVal);
  }

  Future<bool?> getBoolProperty(
      ProductAtShopExtraPropertyType type, OsmUID shopUID, String barcode,
      {bool? defaultVal}) async {
    return _intValToBool(await getProperty(type, shopUID, barcode), defaultVal);
  }

  bool? _intValToBool(int? val, [bool? defaultVal]) {
    if (val == null) {
      return defaultVal;
    }
    return val != 0 ? true : false;
  }

  Future<Map<OsmUID, List<BarcodeProperty<bool>>>> getBoolProperties(
      ProductAtShopExtraPropertyType type, Iterable<OsmUID> shopsUIDs) async {
    return await _getPropertiesImpl(
        type, shopsUIDs, (val) => val != 0 ? true : false);
  }

  Future<Map<OsmUID, Set<String>>> getBarcodesWithBoolValue(
      ProductAtShopExtraPropertyType type,
      bool value,
      Iterable<OsmUID> shopsUIDs) async {
    return await _getBarcodesWithPropertiesValueImpl(
      type,
      value,
      shopsUIDs,
      (val) => val != 0 ? true : false,
    );
  }
}

extension _MyMapListExt on Map<OsmUID, List<ProductAtShopExtraProperty>> {
  void addProperty(ProductAtShopExtraProperty property) {
    if (!containsKey(property.osmUID)) {
      this[property.osmUID] = <ProductAtShopExtraProperty>[];
    }
    this[property.osmUID]!.add(property);
  }

  void removeProperty(ProductAtShopExtraProperty property) {
    final list = this[property.osmUID];
    if (list != null) {
      list.removeWhere((e) =>
          e.osmUID == property.osmUID &&
          e.type == property.type &&
          e.barcode == property.barcode);
    }
  }
}
