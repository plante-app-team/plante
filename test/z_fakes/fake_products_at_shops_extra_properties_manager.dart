import 'package:plante/base/base.dart';
import 'package:plante/outside/map/extra_properties/barcode_property.dart';
import 'package:plante/outside/map/extra_properties/product_at_shop_extra_property.dart';
import 'package:plante/outside/map/extra_properties/product_at_shop_extra_property_type.dart';
import 'package:plante/outside/map/extra_properties/products_at_shops_extra_properties_manager.dart';
import 'package:plante/outside/map/osm/osm_uid.dart';

import 'fake_map_extra_properties_cacher.dart';

/// This class is a stupid reimplementation of [ProductsAtShopsExtraPropertiesManager],
/// which should've been used in tests instead... but widget tests
/// are terrible at real async code, and [ProductsAtShopsExtraPropertiesManager] relies
/// on real async code, which break the tests.
class FakeProductsAtShopsExtraPropertiesManager
    implements ProductsAtShopsExtraPropertiesManager {
  final _cacher = FakeMapExtraPropertiesCacher();

  @override
  Future<Map<OsmUID, Set<String>>> getBarcodesWithBoolValue(
      ProductAtShopExtraPropertyType type,
      bool value,
      Iterable<OsmUID> shopsUIDs) async {
    return getBarcodesWithValue(type, value ? 1 : 0, shopsUIDs);
  }

  @override
  Future<Map<OsmUID, Set<String>>> getBarcodesWithValue(
      ProductAtShopExtraPropertyType type,
      int value,
      Iterable<OsmUID> shopsUIDs) async {
    final properties = await getProperties(type, shopsUIDs);
    final result = <OsmUID, Set<String>>{};
    for (final entry in properties.entries) {
      result[entry.key] = entry.value
          .where((e) => e.val == value)
          .map((e) => e.barcode)
          .toSet();
    }
    return result;
  }

  @override
  Future<Map<OsmUID, List<BarcodeProperty<bool>>>> getBoolProperties(
      ProductAtShopExtraPropertyType type, Iterable<OsmUID> shopsUIDs) async {
    final properties = await getProperties(type, shopsUIDs);
    final convert = (List<BarcodeProperty<int>> list) {
      return list
          .map((e) => BarcodeProperty<bool>(e.barcode, e.val != 0))
          .toList();
    };
    return properties.convertValues(convert);
  }

  @override
  Future<bool?> getBoolProperty(
      ProductAtShopExtraPropertyType type, OsmUID shopUID, String barcode,
      {bool? defaultVal}) async {
    final property = await getProperty(type, shopUID, barcode);
    if (property != null) {
      return property != 0 ? true : false;
    }
    return defaultVal;
  }

  @override
  Future<Map<OsmUID, List<BarcodeProperty<int>>>> getProperties(
      ProductAtShopExtraPropertyType type, Iterable<OsmUID> shopsUIDs) async {
    final all = await _cacher.getAllProductsAtShopProperties();
    final result = <OsmUID, List<BarcodeProperty<int>>>{};
    for (final property in all) {
      if (!shopsUIDs.contains(property.osmUID)) {
        continue;
      }
      if (property.type != type) {
        continue;
      }
      if (result[property.osmUID] == null) {
        result[property.osmUID] = [];
      }
      result[property.osmUID]!
          .add(BarcodeProperty(property.barcode, property.intVal!));
    }
    return result;
  }

  @override
  Future<int?> getProperty(ProductAtShopExtraPropertyType type, OsmUID shopUID,
      String barcode) async {
    final properties = await getProperties(type, [shopUID]);
    final shopProperties = properties[shopUID] ?? const [];
    final barcodeProperties = shopProperties.where((e) => e.barcode == barcode);
    return barcodeProperties.isNotEmpty ? barcodeProperties.first.val : null;
  }

  @override
  Future<void> setBoolProperty(ProductAtShopExtraPropertyType type,
      OsmUID shopUID, String barcode, bool? value) async {
    int? intVal;
    if (value != null) {
      intVal = value ? 1 : 0;
    }
    await setProperty(type, shopUID, barcode, intVal);
  }

  @override
  Future<void> setProperty(ProductAtShopExtraPropertyType type, OsmUID shopUID,
      String barcode, int? value) async {
    await _cacher.setProductAtShopProperty(ProductAtShopExtraProperty.create(
        type: type,
        whenSet: DateTime.now(),
        barcode: barcode,
        osmUID: shopUID,
        intVal: value));
  }
}

extension _MyExtOnMap<T> on Map<OsmUID, T> {
  Map<OsmUID, T2> convertValues<T2>(ArgResCallback<T, T2> converter) {
    final result = <OsmUID, T2>{};
    for (final entry in entries) {
      result[entry.key] = converter.call(entry.value);
    }
    return result;
  }
}
