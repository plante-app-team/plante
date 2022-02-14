import 'package:plante/products/products_group_persistent_storage_base.dart';

/// Storage for products which the user has contributed - products they've
/// added to the app, to the map, etc.
/// See [ProductsGroupPersistentStorageBase].
class ContributedByUserProductsStorage
    extends ProductsGroupPersistentStorageBase {
  static const _STORED_PRODUCTS_MAX = 20;
  static const _FILE_NAME = 'contributed_products_storage.json';

  ContributedByUserProductsStorage()
      : super(
            storageFileName: _FILE_NAME,
            storedProductsMax: _STORED_PRODUCTS_MAX);
}
