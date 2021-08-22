import 'package:flutter_test/flutter_test.dart';
import 'package:plante/model/lang_code.dart';
import 'package:plante/model/product.dart';
import 'package:plante/model/viewed_products_storage.dart';

void main() {
  late ViewedProductsStorage storage;

  setUp(() async {
    storage = ViewedProductsStorage(loadPersistentProducts: false);
    await storage.purgeForTesting();
  });

  tearDown(() async {
    storage.dispose();
  });

  test('add and obtain products', () async {
    final p1 = Product((e) => e.barcode = '123');
    final p2 = Product((e) => e.barcode = '321');
    final p3 = Product((e) => e.barcode = '222');
    storage.addProduct(p1);
    storage.addProduct(p2);
    storage.addProduct(p3);
    expect(storage.getProducts(), equals([p1, p2, p3]));
  });

  test('products have limit', () async {
    const productsNumber = 2 * ViewedProductsStorage.STORED_PRODUCTS_MAX;
    for (var i = 0; i < productsNumber; ++i) {
      storage.addProduct(Product((e) => e.barcode = '$i'));
    }

    final expectedProducts = <Product>[];
    for (var i = ViewedProductsStorage.STORED_PRODUCTS_MAX;
        i < productsNumber;
        ++i) {
      expectedProducts.add(Product((e) => e.barcode = '$i'));
    }

    expect(storage.getProducts(), equals(expectedProducts));
  });

  test('listen to products updates', () async {
    var updatesCount = 0;
    storage.updates().listen((_) {
      updatesCount += 1;
    });

    expect(updatesCount, equals(0));

    storage.addProduct(Product((e) => e.barcode = '1'));
    await Future.delayed(const Duration(microseconds: 1));
    expect(updatesCount, equals(1));

    storage.addProduct(Product((e) => e.barcode = '2'));
    await Future.delayed(const Duration(microseconds: 1));
    expect(updatesCount, equals(2));
  });

  test('persistent products storage', () async {
    final p1 = Product((e) => e.barcode = '123');
    final p2 = Product((e) => e.barcode = '321');
    final p3 = Product((e) => e.barcode = '222');
    storage.addProduct(p1);
    storage.addProduct(p2);
    storage.addProduct(p3);
    storage.dispose();

    final anotherStorage = ViewedProductsStorage(loadPersistentProducts: false);
    await anotherStorage.loadPersistentProductsForTesting();
    expect(anotherStorage.getProducts(), equals([p1, p2, p3]));
  });

  test('listen notification when persistent products first loaded', () async {
    storage.addProduct(Product((e) => e.barcode = '123'));
    storage.dispose();

    final anotherStorage = ViewedProductsStorage(loadPersistentProducts: false);
    var updatesCount = 0;
    anotherStorage.updates().listen((_) {
      updatesCount += 1;
    });
    expect(updatesCount, equals(0));
    await anotherStorage.loadPersistentProductsForTesting();
    await Future.delayed(const Duration(seconds: 1));
    expect(updatesCount, equals(1));
  });

  test('existing viewed product moved when is viewed again', () async {
    final p1 = Product((e) => e.barcode = '123');
    final p2 = Product((e) => e.barcode = '321');
    final p3 = Product((e) => e.barcode = '222');
    storage.addProduct(p1);
    storage.addProduct(p2);
    storage.addProduct(p3);
    expect(storage.getProducts(), equals([p1, p2, p3]));

    final p2Updated = p2.rebuild((e) => e.nameLangs[LangCode.en] = 'new name');
    storage.addProduct(p2Updated);
    expect(storage.getProducts(), equals([p1, p3, p2Updated]));
  });
}
