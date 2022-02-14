import 'package:flutter_test/flutter_test.dart';
import 'package:plante/base/base.dart';
import 'package:plante/model/lang_code.dart';
import 'package:plante/model/product.dart';
import 'package:plante/model/product_lang_slice.dart';
import 'package:plante/products/products_group_persistent_storage_base.dart';

const _STORED_PRODUCTS_MAX = 20;

void main() {
  late ProductsGroupPersistentStorage storage;

  setUp(() async {
    storage = ProductsGroupPersistentStorage(
        storageFileName: '${randInt(0, 9999999)}');
    await storage.inited;
    await storage.purgeForTesting();
  });

  tearDown(() async {
    await storage.dispose();
  });

  test('add and obtain products', () async {
    final p1 = Product((e) => e.barcode = '123');
    final p2 = Product((e) => e.barcode = '321');
    final p3 = Product((e) => e.barcode = '222');
    await storage.addProduct(p1);
    await storage.addProduct(p2);
    await storage.addProduct(p3);
    expect(storage.getProducts(), equals([p1, p2, p3]));
  });

  test('products have limit', () async {
    const productsNumber = 2 * _STORED_PRODUCTS_MAX;
    for (var i = 0; i < productsNumber; ++i) {
      await storage.addProduct(Product((e) => e.barcode = '$i'));
    }

    final expectedProducts = <Product>[];
    for (var i = _STORED_PRODUCTS_MAX; i < productsNumber; ++i) {
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

    await storage.addProduct(Product((e) => e.barcode = '1'));
    await Future.delayed(const Duration(microseconds: 1));
    expect(updatesCount, equals(1));

    await storage.addProduct(Product((e) => e.barcode = '2'));
    await Future.delayed(const Duration(microseconds: 1));
    expect(updatesCount, equals(2));
  });

  test('persistent products storage', () async {
    final storageFileName = '${randInt(0, 9999999)}';
    final storage =
        ProductsGroupPersistentStorage(storageFileName: storageFileName);
    await storage.inited;
    final p1 = Product((e) => e.barcode = '123');
    final p2 = Product((e) => e.barcode = '321');
    final p3 = Product((e) => e.barcode = '222');
    await storage.addProduct(p1);
    await storage.addProduct(p2);
    await storage.addProduct(p3);
    await storage.dispose();

    final anotherStorage =
        ProductsGroupPersistentStorage(storageFileName: storageFileName);
    await anotherStorage.inited;
    expect(anotherStorage.getProducts(), equals([p1, p2, p3]));
  });

  test('listen notification when persistent products first loaded', () async {
    final storageFileName = '${randInt(0, 9999999)}';
    final storage =
        ProductsGroupPersistentStorage(storageFileName: storageFileName);
    await storage.inited;

    await storage.addProduct(Product((e) => e.barcode = '123'));
    await storage.dispose();

    final anotherStorage =
        ProductsGroupPersistentStorage(storageFileName: storageFileName);
    var updatesCount = 0;
    anotherStorage.updates().listen((_) {
      updatesCount += 1;
    });
    expect(updatesCount, equals(0));
    await storage.inited;
    await Future.delayed(const Duration(seconds: 1));
    expect(updatesCount, equals(1));
  });

  test('existing product moved when is added again', () async {
    final p1 = Product((e) => e.barcode = '123');
    final p2 = Product((e) => e.barcode = '321');
    final p3 = Product((e) => e.barcode = '222');
    await storage.addProduct(p1);
    await storage.addProduct(p2);
    await storage.addProduct(p3);
    expect(storage.getProducts(), equals([p1, p2, p3]));

    final p2Updated = p2.rebuild((e) => e.nameLangs[LangCode.en] = 'new name');
    await storage.addProduct(p2Updated);
    expect(storage.getProducts(), equals([p1, p3, p2Updated]));
  });

  test('2 storage do not mess with each other', () async {
    // Storage 1 creation and filling
    final storageFileName1 = '${randInt(0, 9999999)}';
    var storage1 =
        ProductsGroupPersistentStorage(storageFileName: storageFileName1);
    await storage1.inited;
    final p1 = Product((e) => e.barcode = '123');
    final p2 = Product((e) => e.barcode = '321');
    await storage1.addProduct(p1);
    await storage1.addProduct(p2);
    expect(storage1.getProducts(), equals([p1, p2]));

    // Storage 2 creation
    final storageFileName2 = '${storageFileName1}123';
    final storage2 =
        ProductsGroupPersistentStorage(storageFileName: storageFileName2);
    await storage2.inited;
    // Ensure it doesn't have products of the first storage
    expect(storage2.getProducts(), isEmpty);

    // Add a product to Storage 2
    final p3 = Product((e) => e.barcode = '222');
    await storage2.addProduct(p3);
    expect(storage2.getProducts(), equals([p3]));

    // Ensure Storage 1 does not have files of Storage 2
    expect(storage1.getProducts(), equals([p1, p2]));

    // Reload Storage 1from the FS
    storage1 =
        ProductsGroupPersistentStorage(storageFileName: storageFileName1);
    await storage1.inited;
    // Ensure it has same products as before
    expect(storage1.getProducts(), equals([p1, p2]));
  });

  test('set products', () async {
    expect(storage.getProducts(), isEmpty);

    final p1 = Product((e) => e.barcode = '123');
    final p2 = Product((e) => e.barcode = '321');
    final p3 = Product((e) => e.barcode = '222');

    await storage.setProducts([p1, p2, p3]);
    expect(storage.getProducts(), equals([p1, p2, p3]));

    // Let's reload from the FS
    storage = ProductsGroupPersistentStorage(
        storageFileName: storage.storageFileName);
    await storage.inited;
    expect(storage.getProducts(), equals([p1, p2, p3]));
  });

  test('set products where duplicates are present', () async {
    final p1 = ProductLangSlice((e) => e
      ..barcode = '123'
      ..name = 'original').productForTests();
    final p2 = Product((e) => e.barcode = '321');
    final p1duplicate = ProductLangSlice((e) => e
      ..barcode = '123'
      ..name = 'duplicate').productForTests();

    await storage.setProducts([p1, p2, p1duplicate]);
    expect(storage.getProducts(), equals([p2, p1duplicate]));

    // Let's reload from the FS
    storage = ProductsGroupPersistentStorage(
        storageFileName: storage.storageFileName);
    await storage.inited;
    expect(storage.getProducts(), equals([p2, p1duplicate]));
  });
}

class ProductsGroupPersistentStorage
    extends ProductsGroupPersistentStorageBase {
  ProductsGroupPersistentStorage({required String storageFileName})
      : super(
          storageFileName: storageFileName,
          storedProductsMax: _STORED_PRODUCTS_MAX,
          beingTested: true,
        );
}
