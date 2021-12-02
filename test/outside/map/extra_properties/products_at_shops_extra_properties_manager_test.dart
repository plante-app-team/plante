import 'package:plante/outside/map/extra_properties/barcode_property.dart';
import 'package:plante/outside/map/extra_properties/map_extra_properties_cacher.dart';
import 'package:plante/outside/map/extra_properties/product_at_shop_extra_property_type.dart';
import 'package:plante/outside/map/extra_properties/products_at_shops_extra_properties_manager.dart';
import 'package:plante/outside/map/osm/osm_uid.dart';
import 'package:test/test.dart';

void main() {
  final shopUID1 = OsmUID.parse('1:123');
  final shopUID2 = OsmUID.parse('1:124');
  late MapExtraPropertiesCacher cacher;
  late ProductsAtShopsExtraPropertiesManager manager;

  setUp(() async {
    cacher = MapExtraPropertiesCacher();
    manager = ProductsAtShopsExtraPropertiesManager(cacher);
  });

  test('can set and get properties', () async {
    var property = await manager.getProperty(
        ProductAtShopExtraPropertyType.BAD_SUGGESTION, shopUID1, '123');
    expect(property, isNull);

    await manager.setProperty(
        ProductAtShopExtraPropertyType.BAD_SUGGESTION, shopUID1, '123', 321);

    property = await manager.getProperty(
        ProductAtShopExtraPropertyType.BAD_SUGGESTION, shopUID1, '123');
    expect(property, equals(321));

    // Another type
    property = await manager.getProperty(
        ProductAtShopExtraPropertyType.VOTE_RECEIVED_NEGATIVE, shopUID1, '123');
    expect(property, isNull);
  });

  test('can get all properties for a shop', () async {
    await manager.setProperty(
        ProductAtShopExtraPropertyType.BAD_SUGGESTION, shopUID1, '1', 3);
    await manager.setProperty(
        ProductAtShopExtraPropertyType.BAD_SUGGESTION, shopUID1, '2', 2);
    await manager.setProperty(
        ProductAtShopExtraPropertyType.BAD_SUGGESTION, shopUID1, '3', 1);
    // Another type
    await manager.setProperty(
        ProductAtShopExtraPropertyType.VOTE_RECEIVED_NEGATIVE,
        shopUID1,
        '123',
        123);

    final allProperties = await manager.getProperties(
        ProductAtShopExtraPropertyType.BAD_SUGGESTION, [shopUID1]);
    final expected = {
      BarcodeProperty('1', 3),
      BarcodeProperty('2', 2),
      BarcodeProperty('3', 1)
    };
    expect(allProperties[shopUID1]?.toSet(), equals(expected));
  });

  test('can remove properties', () async {
    // Set
    await manager.setProperty(
        ProductAtShopExtraPropertyType.BAD_SUGGESTION, shopUID1, '123', 321);

    // Check
    var property = await manager.getProperty(
        ProductAtShopExtraPropertyType.BAD_SUGGESTION, shopUID1, '123');
    expect(property, equals(321));
    var allProperties = await manager.getProperties(
        ProductAtShopExtraPropertyType.BAD_SUGGESTION, [shopUID1]);
    expect(allProperties[shopUID1], equals([BarcodeProperty('123', 321)]));

    // Remove
    await manager.setProperty(
        ProductAtShopExtraPropertyType.BAD_SUGGESTION, shopUID1, '123', null);

    // Check 2
    property = await manager.getProperty(
        ProductAtShopExtraPropertyType.BAD_SUGGESTION, shopUID1, '123');
    expect(property, isNull);
    allProperties = await manager.getProperties(
        ProductAtShopExtraPropertyType.BAD_SUGGESTION, [shopUID1]);
    expect(allProperties, isEmpty);
  });

  test('properties with certain value request', () async {
    await manager.setProperty(
        ProductAtShopExtraPropertyType.BAD_SUGGESTION, shopUID1, '1', 1);
    await manager.setProperty(
        ProductAtShopExtraPropertyType.BAD_SUGGESTION, shopUID1, '2', 2);
    await manager.setProperty(
        ProductAtShopExtraPropertyType.BAD_SUGGESTION, shopUID1, '3', 1);
    await manager.setProperty(
        ProductAtShopExtraPropertyType.BAD_SUGGESTION, shopUID2, '123', 1);

    var result = await manager.getBarcodesWithValue(
        ProductAtShopExtraPropertyType.BAD_SUGGESTION, 1, [shopUID1, shopUID2]);
    expect(
        result,
        equals({
          shopUID1: {'1', '3'},
          shopUID2: {'123'},
        }));

    result = await manager.getBarcodesWithValue(
        ProductAtShopExtraPropertyType.BAD_SUGGESTION, 2, [shopUID1, shopUID2]);
    expect(
        result,
        equals({
          shopUID1: {'2'},
        }));
  });

  test('can set and get bool properties', () async {
    var property = await manager.getBoolProperty(
        ProductAtShopExtraPropertyType.BAD_SUGGESTION, shopUID1, '123');
    expect(property, isNull);

    await manager.setBoolProperty(
        ProductAtShopExtraPropertyType.BAD_SUGGESTION, shopUID1, '123', true);

    property = await manager.getBoolProperty(
        ProductAtShopExtraPropertyType.BAD_SUGGESTION, shopUID1, '123');
    expect(property, equals(true));

    // Another type
    property = await manager.getBoolProperty(
        ProductAtShopExtraPropertyType.VOTE_RECEIVED_NEGATIVE, shopUID1, '123');
    expect(property, isNull);
  });

  test('can get all bool properties for a shop', () async {
    await manager.setBoolProperty(
        ProductAtShopExtraPropertyType.BAD_SUGGESTION, shopUID1, '1', true);
    await manager.setBoolProperty(
        ProductAtShopExtraPropertyType.BAD_SUGGESTION, shopUID1, '2', false);
    await manager.setBoolProperty(
        ProductAtShopExtraPropertyType.BAD_SUGGESTION, shopUID1, '3', true);
    // Another type
    await manager.setBoolProperty(
        ProductAtShopExtraPropertyType.VOTE_RECEIVED_NEGATIVE,
        shopUID1,
        '123',
        true);

    final allProperties = await manager.getBoolProperties(
        ProductAtShopExtraPropertyType.BAD_SUGGESTION, [shopUID1]);
    final expected = {
      BarcodeProperty('1', true),
      BarcodeProperty('2', false),
      BarcodeProperty('3', true)
    };
    expect(allProperties[shopUID1]?.toSet(), equals(expected));
  });

  test('can remove bool properties', () async {
    // Set
    await manager.setBoolProperty(
        ProductAtShopExtraPropertyType.BAD_SUGGESTION, shopUID1, '123', true);

    // Check
    var property = await manager.getBoolProperty(
        ProductAtShopExtraPropertyType.BAD_SUGGESTION, shopUID1, '123');
    expect(property, equals(true));
    var allProperties = await manager.getBoolProperties(
        ProductAtShopExtraPropertyType.BAD_SUGGESTION, [shopUID1]);
    expect(allProperties[shopUID1], equals([BarcodeProperty('123', true)]));

    // Remove
    await manager.setBoolProperty(
        ProductAtShopExtraPropertyType.BAD_SUGGESTION, shopUID1, '123', null);

    // Check 2
    property = await manager.getBoolProperty(
        ProductAtShopExtraPropertyType.BAD_SUGGESTION, shopUID1, '123');
    expect(property, isNull);
    allProperties = await manager.getBoolProperties(
        ProductAtShopExtraPropertyType.BAD_SUGGESTION, [shopUID1]);
    expect(allProperties, isEmpty);
  });

  test('bool properties default values', () async {
    var property = await manager.getBoolProperty(
        ProductAtShopExtraPropertyType.BAD_SUGGESTION, shopUID1, '123');
    expect(property, isNull);

    property = await manager.getBoolProperty(
        ProductAtShopExtraPropertyType.BAD_SUGGESTION, shopUID1, '123',
        defaultVal: false);
    expect(property, equals(false));
  });

  test('bool properties with certain value request', () async {
    await manager.setBoolProperty(
        ProductAtShopExtraPropertyType.BAD_SUGGESTION, shopUID1, '1', true);
    await manager.setBoolProperty(
        ProductAtShopExtraPropertyType.BAD_SUGGESTION, shopUID1, '2', false);
    await manager.setBoolProperty(
        ProductAtShopExtraPropertyType.BAD_SUGGESTION, shopUID1, '3', true);
    await manager.setBoolProperty(
        ProductAtShopExtraPropertyType.BAD_SUGGESTION, shopUID2, '123', true);

    var result = await manager.getBarcodesWithBoolValue(
        ProductAtShopExtraPropertyType.BAD_SUGGESTION,
        true,
        [shopUID1, shopUID2]);
    expect(
        result,
        equals({
          shopUID1: {'1', '3'},
          shopUID2: {'123'},
        }));

    result = await manager.getBarcodesWithBoolValue(
        ProductAtShopExtraPropertyType.BAD_SUGGESTION,
        false,
        [shopUID1, shopUID2]);
    expect(
        result,
        equals({
          shopUID1: {'2'},
        }));
  });

  test('properties outlive 1 instance', () async {
    await manager.setProperty(
        ProductAtShopExtraPropertyType.BAD_SUGGESTION, shopUID1, '123', 321);
    var property = await manager.getProperty(
        ProductAtShopExtraPropertyType.BAD_SUGGESTION, shopUID1, '123');
    expect(property, equals(321));

    manager = ProductsAtShopsExtraPropertiesManager(cacher);

    property = await manager.getProperty(
        ProductAtShopExtraPropertyType.BAD_SUGGESTION, shopUID1, '123');
    expect(property, equals(321));
  });

  test('outdated properties are automatically deleted', () async {
    // Set
    await manager.setProperty(
        ProductAtShopExtraPropertyType.BAD_SUGGESTION, shopUID1, '123', 321);
    await manager.setProperty(
        ProductAtShopExtraPropertyType.FOR_TESTS, shopUID1, '123', 321);

    // Initial check
    var property = await manager.getProperty(
        ProductAtShopExtraPropertyType.BAD_SUGGESTION, shopUID1, '123');
    expect(property, equals(321));
    property = await manager.getProperty(
        ProductAtShopExtraPropertyType.FOR_TESTS, shopUID1, '123');
    expect(property, equals(321));

    // Outlive a property
    await Future.delayed(ProductAtShopExtraPropertyType.FOR_TESTS.lifetime +
        const Duration(seconds: 1));
    manager = ProductsAtShopsExtraPropertiesManager(cacher);

    // Second check
    property = await manager.getProperty(
        ProductAtShopExtraPropertyType.BAD_SUGGESTION, shopUID1, '123');
    expect(property, equals(321));
    property = await manager.getProperty(
        ProductAtShopExtraPropertyType.FOR_TESTS, shopUID1, '123');
    expect(property, isNull);
  });
}
