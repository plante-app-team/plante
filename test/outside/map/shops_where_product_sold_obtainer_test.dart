import 'package:plante/model/coord.dart';
import 'package:plante/model/product_lang_slice.dart';
import 'package:plante/model/shop.dart';
import 'package:plante/outside/backend/backend_shop.dart';
import 'package:plante/outside/backend/product_at_shop_source.dart';
import 'package:plante/outside/map/osm/osm_element_type.dart';
import 'package:plante/outside/map/osm/osm_shop.dart';
import 'package:plante/outside/map/osm/osm_uid.dart';
import 'package:plante/outside/map/shops_where_product_sold_obtainer.dart';
import 'package:test/test.dart';

import '../../z_fakes/fake_latest_camera_pos_storage.dart';
import '../../z_fakes/fake_shops_manager.dart';

void main() {
  final center = Coord(lat: 10, lon: 20);
  final shop = Shop((e) => e
    ..osmShop.replace(OsmShop((e) => e
      ..osmUID = const OsmUID(OsmElementType.NODE, 'id')
      ..longitude = center.lon
      ..latitude = center.lat
      ..name = 'Shop'))
    ..backendShop.replace(BackendShop((e) => e
      ..osmUID = const OsmUID(OsmElementType.NODE, 'id')
      ..productsCount = 1)));
  final product = ProductLangSlice((e) => e
    ..barcode = '123456'
    ..name = 'Product').productForTests();

  late FakeShopsManager shopsManager;
  late FakeLatestCameraPosStorage latestCameraPosStorage;
  late ShopsWhereProductSoldObtainer shopsWhereProductSoldObtainer;

  setUp(() async {
    shopsManager = FakeShopsManager();
    latestCameraPosStorage = FakeLatestCameraPosStorage();
    await latestCameraPosStorage.set(center);
    shopsWhereProductSoldObtainer =
        ShopsWhereProductSoldObtainer(shopsManager, latestCameraPosStorage);

    shopsManager.addPreloadedArea_testing(center.makeSquare(10), [shop]);
    await shopsManager.putProductToShops(
        product, [shop], ProductAtShopSource.MANUAL);
  });

  test('normal scenario', () async {
    final result = await shopsWhereProductSoldObtainer
        .fetchShopsWhereSold(product.barcode);
    expect(result.unwrap(), equals({shop.osmUID: shop}));
  });

  test('no known camera pos', () async {
    await latestCameraPosStorage.set(null);

    final result = await shopsWhereProductSoldObtainer
        .fetchShopsWhereSold(product.barcode);
    expect(result.unwrap(), equals(const {}));
  });

  test('behaviour when shops are preloaded', () async {
    await shopsWhereProductSoldObtainer.fetchShopsWhereSold(product.barcode);
    shopsManager.verify_fetchShops_called(times: 0);
  });

  test('when shops are not preloaded', () async {
    await shopsManager.clearCache();
    await shopsWhereProductSoldObtainer.fetchShopsWhereSold(product.barcode);
    shopsManager.verify_fetchShops_called(times: 1);
  });
}
