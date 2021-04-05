import 'package:openfoodfacts/openfoodfacts.dart' as off;

import 'package:untitled_vegan_app/model/product.dart';
import 'package:untitled_vegan_app/model/veg_status.dart';
import 'package:untitled_vegan_app/model/veg_status_source.dart';
import 'package:untitled_vegan_app/outside/backend/backend.dart';
import 'package:untitled_vegan_app/outside/off/off_api.dart';
import 'package:untitled_vegan_app/outside/off/off_user.dart';

class ProductsManager {
  static const _NEEDED_OFF_FIELDS = [
    off.ProductField.BARCODE,
    off.ProductField.NAME,
    off.ProductField.BRANDS,
    off.ProductField.BRANDS_TAGS,
    off.ProductField.CATEGORIES,
    off.ProductField.CATEGORIES_TAGS_TRANSLATED,
    off.ProductField.INGREDIENTS,
    off.ProductField.INGREDIENTS_TEXT,
    off.ProductField.IMAGE_FRONT_URL,
    off.ProductField.IMAGE_INGREDIENTS_URL,
  ];

  final OffApi _off;
  final Backend _backend;

  ProductsManager(this._off, this._backend);

  Future<Product?> getProduct(String barcodeRaw, String langCode) async {
    final configuration = off.ProductQueryConfiguration(
        barcodeRaw,
        lc: langCode,
        language: off.LanguageHelper.fromJson(langCode),
        fields: _NEEDED_OFF_FIELDS.toList());

    final offProductResult = await _off.getProduct(configuration);
    final offProduct = offProductResult.product;
    if (offProduct == null) {
      return null;
    }

    final barcode = offProduct.barcode!;
    final backendProduct = await _backend.requestProduct(barcode);

    return Product((v) => v
      ..barcode = barcode

      ..vegetarianStatus = VegStatus.safeValueOf(backendProduct?.vegetarianStatus ?? "")
      ..vegetarianStatusSource = VegStatusSource.safeValueOf(backendProduct?.vegetarianStatusSource ?? "")
      ..veganStatus = VegStatus.safeValueOf(backendProduct?.veganStatus ?? "")
      ..veganStatusSource = VegStatusSource.safeValueOf(backendProduct?.veganStatusSource ?? "")

      ..name = offProduct.productName
      ..brands.addAll(offProduct.brandsTags ?? [])
      ..categories.addAll(offProduct.categoriesTagsTranslated ?? [])
      ..ingredients = offProduct.ingredientsText
      ..imageFront = _extractUri(offProduct.imageFrontUrl)
      ..imageIngredients = _extractUri(offProduct.imageIngredientsUrl)
    );
  }

  Uri? _extractUri(String? uriStr) {
    if (uriStr == null) {
      return null;
    }
    return Uri.parse(uriStr);
  }

  /// Returns updated product if update was successful
  Future<Product?> updateProduct(Product product, String langCode) async {
    // OFF product

    final offProduct = off.Product(
      barcode: product.barcode,
      productName: product.name,
      brands: product.brands?.join(", "),
      categories: product.categories?.join(", "),
      ingredientsText: product.ingredients);
    final offResult = await _off.saveProduct(_offUser(), offProduct);
    if (offResult.error != null) {
      // TODO(https://trello.com/c/XWAE5UVB/): log warning
      return null;
    }

    // OFF front image

    if (product.isFrontImageFile()) {
      final image = off.SendImage(
        lang: off.LanguageHelper.fromJson(langCode),
        barcode: product.barcode,
        imageField: off.ImageField.FRONT,
        imageUri: product.imageFront!,
      );
      final status = await _off.addProductImage(_offUser(), image);
      if (status.error != null) {
        // TODO(https://trello.com/c/XWAE5UVB/): log warning
        return null;
      }
    }

    // OFF ingredients image

    if (product.isIngredientsImageFile()) {
      final image = off.SendImage(
        lang: off.LanguageHelper.fromJson(langCode),
        barcode: product.barcode,
        imageField: off.ImageField.INGREDIENTS,
        imageUri: product.imageIngredients!,
      );
      final status = await _off.addProductImage(_offUser(), image);
      if (status.error != null) {
        // TODO(https://trello.com/c/XWAE5UVB/): log warning
        return null;
      }
    }

    // Backend product

    final backendResult = await _backend.createUpdateProduct(
      product.barcode,
      vegetarianStatus: product.vegetarianStatus,
      veganStatus: product.veganStatus);
    if (backendResult.isRight) {
      // TODO(https://trello.com/c/XWAE5UVB/): log warning
      return null;
    }

    return getProduct(product.barcode, langCode);
  }

  Future<ProductWithOCRIngredients?> updateProductAndExtractIngredients(Product product, String langCode) async {
    final updatedProduct = await updateProduct(product, langCode);
    if (updatedProduct == null) {
      return null;
    }

    final offLang = off.LanguageHelper.fromJson(langCode);

    final response = await _off.extractIngredients(
        _offUser(), product.barcode, offLang);
    if (response.status == 0) {
      return ProductWithOCRIngredients(updatedProduct, response.ingredientsTextFromImage);
    } else {
      return ProductWithOCRIngredients(updatedProduct, null);
    }
  }

  off.User _offUser() => off.User(userId: OffUser.USERNAME, password: OffUser.PASSWORD);
}

class ProductWithOCRIngredients {
  Product product;
  String? ingredients;
  ProductWithOCRIngredients(this.product, this.ingredients);
}
