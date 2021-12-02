import 'package:plante/model/shop.dart';
import 'package:plante/outside/map/extra_properties/map_extra_properties_cacher.dart';
import 'package:plante/outside/map/extra_properties/product_at_shop_extra_property_type.dart';
import 'package:plante/outside/map/extra_properties/products_at_shops_extra_properties_manager.dart';
import 'package:plante/outside/map/osm/osm_shop.dart';
import 'package:plante/outside/map/osm/osm_uid.dart';
import 'package:plante/outside/off/off_shop.dart';
import 'package:plante/outside/products/suggested_products_manager.dart';
import 'package:test/test.dart';

import '../../z_fakes/fake_off_shops_manager.dart';

void main() {
  late FakeOffShopsManager offShopsManager;
  late ProductsAtShopsExtraPropertiesManager productsExtraProperties;

  late SuggestedProductsManager suggestedProductsManager;

  setUp(() async {
    offShopsManager = FakeOffShopsManager();
    productsExtraProperties =
        ProductsAtShopsExtraPropertiesManager(MapExtraPropertiesCacher());
    suggestedProductsManager =
        SuggestedProductsManager(offShopsManager, productsExtraProperties);
  });

  test('getSuggestedProductsFor', () async {
    final offShops = [
      OffShop((e) => e
        ..id = 'spar'
        ..name = 'Spar'
        ..productsCount = 2
        ..country = 'ru'),
      OffShop((e) => e
        ..id = 'auchan'
        ..name = 'Auchan'
        ..productsCount = 2
        ..country = 'ru'),
      OffShop((e) => e
        ..id = 'groceries'
        ..name = 'Groceries'
        ..productsCount = 2
        ..country = 'ru'),
    ];
    final allSuggestions = {
      offShops[0]: ['123'],
      offShops[1]: [
        '124',
        '125',
      ],
      offShops[2]: [
        '126',
        '127',
        '128',
      ],
    };
    offShopsManager.setSuggestedBarcodes(allSuggestions);

    final shops = [
      Shop((e) => e
        ..osmShop.replace(OsmShop((e) => e
          ..osmUID = OsmUID.parse('1:1')
          ..longitude = 10
          ..latitude = 10
          ..name = 'Spar'))),
      Shop((e) => e
        ..osmShop.replace(OsmShop((e) => e
          ..osmUID = OsmUID.parse('1:2')
          ..longitude = 10
          ..latitude = 10
          ..name = 'Auchan'))),
    ];

    var suggestionsRes =
        await suggestedProductsManager.getSuggestedBarcodesFor([shops[0]]);
    var suggestions = suggestionsRes.unwrap();
    expect(suggestions, equals({shops[0].osmUID: allSuggestions[offShops[0]]}));

    suggestionsRes =
        await suggestedProductsManager.getSuggestedBarcodesFor(shops);
    suggestions = suggestionsRes.unwrap();
    expect(
        suggestions,
        equals({
          shops[0].osmUID: allSuggestions[offShops[0]],
          shops[1].osmUID: allSuggestions[offShops[1]],
        }));
  });

  test('getSuggestedProductsFor - bad suggestions are not suggested', () async {
    final offShops = [
      OffShop((e) => e
        ..id = 'spar'
        ..name = 'Spar'
        ..productsCount = 2
        ..country = 'ru'),
    ];
    final allSuggestions = {
      offShops[0]: ['123', '124', '125'],
    };
    offShopsManager.setSuggestedBarcodes(allSuggestions);

    final shops = [
      Shop((e) => e
        ..osmShop.replace(OsmShop((e) => e
          ..osmUID = OsmUID.parse('1:1')
          ..longitude = 10
          ..latitude = 10
          ..name = 'Spar'))),
    ];

    // '123' is a good suggestion
    await productsExtraProperties.setBoolProperty(
        ProductAtShopExtraPropertyType.BAD_SUGGESTION,
        shops[0].osmUID,
        '123',
        false);
    // '124' is a bad suggestion
    await productsExtraProperties.setBoolProperty(
        ProductAtShopExtraPropertyType.BAD_SUGGESTION,
        shops[0].osmUID,
        '124',
        true);
    // property for '125' has a different type
    await productsExtraProperties.setBoolProperty(
        ProductAtShopExtraPropertyType.VOTE_RECEIVED_NEGATIVE,
        shops[0].osmUID,
        '125',
        true);

    final suggestionsRes =
        await suggestedProductsManager.getSuggestedBarcodesFor(shops);
    final suggestions = suggestionsRes.unwrap();
    expect(
        suggestions,
        equals({
          shops[0].osmUID: ['123', '125']
        }));
  });
}
