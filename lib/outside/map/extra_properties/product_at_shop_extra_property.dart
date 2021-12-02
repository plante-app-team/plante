import 'package:built_value/built_value.dart';
import 'package:plante/base/date_time_extensions.dart';
import 'package:plante/outside/map/extra_properties/product_at_shop_extra_property_type.dart';
import 'package:plante/outside/map/osm/osm_uid.dart';

part 'product_at_shop_extra_property.g.dart';

abstract class ProductAtShopExtraProperty
    implements
        Built<ProductAtShopExtraProperty, ProductAtShopExtraPropertyBuilder> {
  int? get intVal;
  String get barcode;
  int get typeCode;
  int get whenSetSecsSinceEpoch;
  OsmUID get osmUID;

  ProductAtShopExtraPropertyType get type =>
      createProductAtShopExtraPropertyTypeFromCode(typeCode);

  DateTime get whenSet {
    return dateTimeFromSecondsSinceEpoch(whenSetSecsSinceEpoch);
  }

  factory ProductAtShopExtraProperty(
          [void Function(ProductAtShopExtraPropertyBuilder) updates]) =
      _$ProductAtShopExtraProperty;
  ProductAtShopExtraProperty._();

  factory ProductAtShopExtraProperty.create(
          {required ProductAtShopExtraPropertyType type,
          required DateTime whenSet,
          required String barcode,
          required OsmUID osmUID,
          required int? intVal}) =>
      ProductAtShopExtraProperty((e) => e
        ..typeCode = type.persistentCode
        ..whenSetSecsSinceEpoch = whenSet.secondsSinceEpoch
        ..barcode = barcode
        ..osmUID = osmUID
        ..intVal = intVal);
}
