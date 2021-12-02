import 'package:plante/outside/map/extra_properties/map_extra_properties_cacher.dart';
import 'package:plante/outside/map/extra_properties/product_at_shop_extra_property.dart';
import 'package:plante/outside/map/extra_properties/product_at_shop_extra_property_type.dart';
import 'package:plante/outside/map/osm/osm_uid.dart';
import 'package:test/test.dart';

void main() {
  final now = DateTime(1993, 7, 20);
  final shopUID1 = OsmUID.parse('1:123');
  final shopUID2 = OsmUID.parse('1:1234');
  late MapExtraPropertiesCacher cacher;

  setUp(() async {
    cacher = MapExtraPropertiesCacher();
    await cacher.dbForTesting;
  });

  test('cached products at shops: store, update, delete', () async {
    // Verify empty at first
    var extractedProperties =
        await cacher.getProductsAtShopProperties(shopUID1);
    expect(extractedProperties, isEmpty);

    // Create
    final properties = [
      ProductAtShopExtraProperty.create(
          type: ProductAtShopExtraPropertyType.BAD_SUGGESTION,
          whenSet: now,
          barcode: '123',
          osmUID: shopUID1,
          intVal: 10),
      ProductAtShopExtraProperty.create(
          type: ProductAtShopExtraPropertyType.VOTE_RECEIVED_NEGATIVE,
          whenSet: now,
          barcode: '321',
          osmUID: shopUID1,
          intVal: 0),
    ];
    for (final property in properties) {
      await cacher.setProductAtShopProperty(property);
    }

    // Read
    extractedProperties = await cacher.getProductsAtShopProperties(shopUID1);
    expect(extractedProperties, equals(properties));
    extractedProperties = await cacher.getProductsAtShopProperties(shopUID2);
    expect(extractedProperties, isEmpty);

    // Update
    final updatedProperties = properties.toList();
    updatedProperties[1] = properties[1].rebuild((e) => e.intVal = 100);
    expect(updatedProperties, isNot(equals(properties)));
    await cacher.setProductAtShopProperty(updatedProperties[1]);

    extractedProperties = await cacher.getProductsAtShopProperties(shopUID1);
    expect(extractedProperties, isNot(equals(properties)));
    expect(extractedProperties, equals(updatedProperties));

    // Delete
    await cacher.deleteProductAtShopProperty(updatedProperties[0].type,
        updatedProperties[0].osmUID, updatedProperties[0].barcode);
    extractedProperties = await cacher.getProductsAtShopProperties(shopUID1);
    expect(extractedProperties, equals([updatedProperties[1]]));
    await cacher.deleteProductAtShopProperty(updatedProperties[1].type,
        updatedProperties[1].osmUID, updatedProperties[1].barcode);
    extractedProperties = await cacher.getProductsAtShopProperties(shopUID1);
    expect(extractedProperties, isEmpty);
  });

  test('cached products at shops: reload', () async {
    // Create
    final properties = [
      ProductAtShopExtraProperty.create(
          type: ProductAtShopExtraPropertyType.BAD_SUGGESTION,
          whenSet: now,
          barcode: '123',
          osmUID: shopUID1,
          intVal: 10),
      ProductAtShopExtraProperty.create(
          type: ProductAtShopExtraPropertyType.VOTE_RECEIVED_NEGATIVE,
          whenSet: now,
          barcode: '321',
          osmUID: shopUID1,
          intVal: 0),
    ];
    for (final property in properties) {
      await cacher.setProductAtShopProperty(property);
    }

    // Read
    var extractedProperties =
        await cacher.getProductsAtShopProperties(shopUID1);
    expect(extractedProperties, equals(properties));

    // Reload
    // Create a second cacher with same DB,
    final cacher2 = MapExtraPropertiesCacher.withDb(await cacher.dbForTesting);
    extractedProperties = await cacher2.getProductsAtShopProperties(shopUID1);
    expect(extractedProperties, equals(properties));
  });

  test('cached products at shops: properties of same type overwrite each other',
      () async {
    var extractedProperties =
        await cacher.getProductsAtShopProperties(shopUID1);
    expect(extractedProperties, isEmpty);

    final property1 = ProductAtShopExtraProperty.create(
        type: ProductAtShopExtraPropertyType.BAD_SUGGESTION,
        whenSet: now,
        barcode: '123',
        osmUID: shopUID1,
        intVal: 10);
    final property1Different =
        property1.rebuild((e) => e.intVal = e.intVal! + 1);
    expect(property1Different, isNot(equals(property1)));

    // Property set
    await cacher.setProductAtShopProperty(property1);
    extractedProperties = await cacher.getProductsAtShopProperties(shopUID1);
    expect(extractedProperties, equals([property1]));

    // Property overwritten
    await cacher.setProductAtShopProperty(property1Different);
    extractedProperties = await cacher.getProductsAtShopProperties(shopUID1);
    expect(extractedProperties, equals([property1Different]));

    // Property of a different type
    final property2 = ProductAtShopExtraProperty.create(
        type: ProductAtShopExtraPropertyType.VOTE_RECEIVED_NEGATIVE,
        whenSet: now,
        barcode: '123',
        osmUID: shopUID1,
        intVal: 0);
    await cacher.setProductAtShopProperty(property2);
    extractedProperties = await cacher.getProductsAtShopProperties(shopUID1);
    expect(extractedProperties, equals([property1Different, property2]));
  });

  test(
      'cached products at shops: different shops properties do not affect each other',
      () async {
    final property1 = ProductAtShopExtraProperty.create(
        type: ProductAtShopExtraPropertyType.BAD_SUGGESTION,
        whenSet: now,
        barcode: '123',
        osmUID: shopUID1,
        intVal: 10);
    final property2 = property1.rebuild((e) => e
      ..intVal = e.intVal! + 1
      ..osmUID = shopUID2);
    // Property are different
    expect(property2, isNot(equals(property1)));
    // But type and barcode are same
    expect(property2.type, equals(property1.type));
    expect(property2.barcode, equals(property1.barcode));

    await cacher.setProductAtShopProperty(property1);
    await cacher.setProductAtShopProperty(property2);

    var extractedProperties =
        await cacher.getProductsAtShopProperties(shopUID1);
    expect(extractedProperties, equals([property1]));
    extractedProperties = await cacher.getProductsAtShopProperties(shopUID2);
    expect(extractedProperties, equals([property2]));
  });

  test(
      'cached products at shops: different barcodes properties do not affect each other',
      () async {
    final property1 = ProductAtShopExtraProperty.create(
        type: ProductAtShopExtraPropertyType.BAD_SUGGESTION,
        whenSet: now,
        barcode: '123',
        osmUID: shopUID1,
        intVal: 10);
    final property2 = property1.rebuild((e) => e
      ..intVal = e.intVal! + 1
      ..barcode = '${e.barcode}4');
    // Property are different
    expect(property2, isNot(equals(property1)));
    // But type and shop are same
    expect(property2.type, equals(property1.type));
    expect(property2.osmUID, equals(property1.osmUID));

    await cacher.setProductAtShopProperty(property1);
    await cacher.setProductAtShopProperty(property2);

    final extractedProperties =
        await cacher.getProductsAtShopProperties(shopUID1);
    expect(extractedProperties, equals([property1, property2]));
  });

  test('cached products at shops: setting null value removes the property',
      () async {
    final property1 = ProductAtShopExtraProperty.create(
        type: ProductAtShopExtraPropertyType.BAD_SUGGESTION,
        whenSet: now,
        barcode: '123',
        osmUID: shopUID1,
        intVal: 10);
    await cacher.setProductAtShopProperty(property1);

    var extractedProperties =
        await cacher.getProductsAtShopProperties(shopUID1);
    expect(extractedProperties, equals([property1]));

    final propertyUpdated = property1.rebuild((e) => e.intVal = null);
    await cacher.setProductAtShopProperty(propertyUpdated);

    extractedProperties = await cacher.getProductsAtShopProperties(shopUID1);
    expect(extractedProperties, equals([]));
  });

  test('cached products at shops: request all shops', () async {
    final property1 = ProductAtShopExtraProperty.create(
        type: ProductAtShopExtraPropertyType.BAD_SUGGESTION,
        whenSet: now,
        barcode: '123',
        osmUID: shopUID1,
        intVal: 10);
    final property2 = property1.rebuild((e) => e
      ..intVal = e.intVal! + 1
      ..barcode = '${e.barcode}4');

    await cacher.setProductAtShopProperty(property1);
    await cacher.setProductAtShopProperty(property2);

    final extractedProperties = await cacher.getAllProductsAtShopProperties();
    expect(extractedProperties, equals([property1, property2]));
  });
}
