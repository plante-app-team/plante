import 'package:plante/outside/off/off_cacher.dart';
import 'package:plante/outside/off/off_shop.dart';
import 'package:plante/outside/off/off_vegan_barcodes_storage.dart';
import 'package:test/test.dart';

void main() {
  late OffCacher offCacher;
  late OffVeganBarcodesStorage storage;

  setUp(() async {
    offCacher = OffCacher();
    storage = OffVeganBarcodesStorage(offCacher);
  });

  test('put barcodes, get barcodes', () async {
    final shop1 = OffShop((e) => e
      ..id = 'spar'
      ..name = 'Spar'
      ..productsCount = 3410
      ..country = 'ru');
    final shop2 = OffShop((e) => e
      ..id = '5ka'
      ..name = '5ka'
      ..productsCount = 431
      ..country = 'by');
    await storage.setBarcodesOfShop(shop1, ['123', '456']);
    await storage.setBarcodesOfShop(shop2, ['456', '567']);

    final result = await storage.getBarcodesAtShops([shop1, shop2]);
    expect(
        result,
        equals({
          shop1: ['123', '456'],
          shop2: ['456', '567'],
        }));
  });

  test('put barcodes, get barcodes from another instance with same OFF cacher',
      () async {
    final shop1 = OffShop((e) => e
      ..id = 'spar'
      ..name = 'Spar'
      ..productsCount = 3410
      ..country = 'ru');
    final shop2 = OffShop((e) => e
      ..id = '5ka'
      ..name = '5ka'
      ..productsCount = 431
      ..country = 'by');
    await storage.setBarcodesOfShop(shop1, ['123', '456']);
    await storage.setBarcodesOfShop(shop2, ['456', '567']);

    // Another instance
    storage = OffVeganBarcodesStorage(offCacher);

    final result = await storage.getBarcodesAtShops([shop1, shop2]);
    expect(
        result,
        equals({
          shop1: ['123', '456'],
          shop2: ['456', '567'],
        }));
  });

  test('outdated barcodes get deleted', () async {
    const maxLifetime = Duration(seconds: 4);
    storage = OffVeganBarcodesStorage(offCacher, maxLifetime);

    final shop = OffShop((e) => e
      ..id = 'spar'
      ..name = 'Spar'
      ..productsCount = 3410
      ..country = 'ru');
    await storage.setBarcodesOfShop(shop, ['456', '567']);
    var barcodes = await storage.getBarcodesAtShops([shop]);
    expect(barcodes[shop], isNotNull);

    await Future.delayed(maxLifetime + const Duration(seconds: 1));

    // Another instance
    storage = OffVeganBarcodesStorage(offCacher, maxLifetime);

    // No barcodes in the storage
    barcodes = await storage.getBarcodesAtShops([shop]);
    expect(barcodes[shop], isNull);

    // And the cacher has them deleted too
    final productsAtShop =
        await offCacher.getBarcodesAtShop(shop.country, shop.id);
    expect(productsAtShop, isNull);
  });

  test('no cache VS empty cache', () async {
    final shop = OffShop((e) => e
      ..id = 'spar'
      ..name = 'Spar'
      ..productsCount = 3410
      ..country = 'ru');

    // No cache yet
    var barcodes = await storage.getBarcodesAtShops([shop]);
    expect(barcodes[shop], isNull);

    // Empty cache
    await storage.setBarcodesOfShop(shop, const []);
    barcodes = await storage.getBarcodesAtShops([shop]);
    expect(barcodes[shop], isNotNull);
    expect(barcodes[shop], isEmpty);
  });
}
