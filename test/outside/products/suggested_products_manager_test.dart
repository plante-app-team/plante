import 'package:plante/model/lang_code.dart';
import 'package:plante/model/product_lang_slice.dart';
import 'package:plante/model/shop.dart';
import 'package:plante/outside/map/osm_shop.dart';
import 'package:plante/outside/map/osm_uid.dart';
import 'package:plante/outside/off/off_shop.dart';
import 'package:plante/outside/products/suggested_products_manager.dart';
import 'package:test/test.dart';

import '../../z_fakes/fake_off_shops_manager.dart';
import '../../z_fakes/fake_user_langs_manager.dart';

void main() {
  late FakeOffShopsManager offShopsManager;
  late FakeUserLangsManager userLangsManager;

  late SuggestedProductsManager suggestedProductsManager;

  setUp(() async {
    userLangsManager = FakeUserLangsManager([LangCode.be]);
    offShopsManager = FakeOffShopsManager();
    suggestedProductsManager =
        SuggestedProductsManager(offShopsManager, userLangsManager);
  });

  test('getSuggestedProductsFor', () async {
    final offShops = [
      OffShop((e) => e
        ..id = 'spar'
        ..name = 'Spar'
        ..productsCount = 2),
      OffShop((e) => e
        ..id = 'auchan'
        ..name = 'Auchan'
        ..productsCount = 2),
      OffShop((e) => e
        ..id = 'groceries'
        ..name = 'Groceries'
        ..productsCount = 2),
    ];
    final allSuggestions = {
      offShops[0]: [
        ProductLangSlice((v) => v.barcode = '123').productForTests(),
      ],
      offShops[1]: [
        ProductLangSlice((v) => v.barcode = '124').productForTests(),
        ProductLangSlice((v) => v.barcode = '125').productForTests(),
      ],
      offShops[2]: [
        ProductLangSlice((v) => v.barcode = '126').productForTests(),
        ProductLangSlice((v) => v.barcode = '127').productForTests(),
        ProductLangSlice((v) => v.barcode = '128').productForTests(),
      ],
    };
    offShopsManager.setSuggestedProducts(allSuggestions);

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
        await suggestedProductsManager.getSuggestedProductsFor([shops[0]]);
    var suggestions = suggestionsRes.unwrap();
    expect(suggestions, equals({shops[0].osmUID: allSuggestions[offShops[0]]}));

    suggestionsRes =
        await suggestedProductsManager.getSuggestedProductsFor(shops);
    suggestions = suggestionsRes.unwrap();
    expect(
        suggestions,
        equals({
          shops[0].osmUID: allSuggestions[offShops[0]],
          shops[1].osmUID: allSuggestions[offShops[1]],
        }));
  });
}
