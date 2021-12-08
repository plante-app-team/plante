import 'package:plante/outside/map/extra_properties/map_extra_properties_cacher.dart';
import 'package:plante/outside/map/extra_properties/product_at_shop_extra_property.dart';
import 'package:plante/outside/map/extra_properties/product_at_shop_extra_property_type.dart';
import 'package:plante/outside/map/osm/osm_uid.dart';
import 'package:sqflite_common/sqlite_api.dart';

class FakeMapExtraPropertiesCacher implements MapExtraPropertiesCacher {
  final _map = <OsmUID, List<ProductAtShopExtraProperty>>{};

  @override
  Future<Database> get dbForTesting => throw UnimplementedError();

  @override
  Future<String> dbFilePath() {
    throw UnimplementedError();
  }

  @override
  Future<void> deleteDatabase() {
    throw UnimplementedError();
  }

  @override
  Future<void> setProductAtShopProperty(
      ProductAtShopExtraProperty property) async {
    await deleteProductAtShopProperty(
        property.type, property.osmUID, property.barcode);
    final list = _map[property.osmUID]!;
    if (property.intVal != null) {
      list.add(property);
    }
  }

  @override
  Future<void> deleteProductAtShopProperty(ProductAtShopExtraPropertyType type,
      OsmUID shopUID, String barcode) async {
    if (_map[shopUID] == null) {
      _map[shopUID] = [];
    }
    final list = _map[shopUID]!;
    list.removeWhere(
        (e) => e.osmUID == shopUID && e.type == type && e.barcode == barcode);
  }

  @override
  Future<List<ProductAtShopExtraProperty>>
      getAllProductsAtShopProperties() async {
    final result = <ProductAtShopExtraProperty>[];
    _map.values.forEach(result.addAll);
    return result;
  }

  @override
  Future<List<ProductAtShopExtraProperty>> getProductsAtShopProperties(
      OsmUID shopUID) async {
    return _map[shopUID] ?? const [];
  }
}
