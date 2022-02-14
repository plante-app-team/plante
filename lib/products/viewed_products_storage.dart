import 'package:plante/products/products_group_persistent_storage_base.dart';

/// Storage of products the user has viewed - scanned the barcode of, opened
/// from the Shop Page, etc.
/// See [ProductsGroupPersistentStorageBase].
class ViewedProductsStorage extends ProductsGroupPersistentStorageBase {
  static const _STORED_PRODUCTS_MAX = 20;
  static const _FILE_NAME = 'viewed_products_storage.json';

  ViewedProductsStorage()
      : super(
            storageFileName: _FILE_NAME,
            storedProductsMax: _STORED_PRODUCTS_MAX);
}
