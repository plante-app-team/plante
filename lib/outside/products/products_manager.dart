import 'dart:io';

import 'package:openfoodfacts/model/OcrIngredientsResult.dart' as off;
import 'package:openfoodfacts/openfoodfacts.dart' as off;
import 'package:plante/base/base.dart';
import 'package:plante/logging/analytics.dart';
import 'package:plante/logging/log.dart';
import 'package:plante/base/result.dart';
import 'package:plante/model/lang_code.dart';
import 'package:plante/model/product.dart';
import 'package:plante/outside/backend/backend.dart';
import 'package:plante/outside/backend/backend_error.dart';
import 'package:plante/outside/backend/backend_product.dart';
import 'package:plante/outside/off/off_api.dart';
import 'package:plante/outside/off/off_user.dart';
import 'package:plante/outside/products/products_converter.dart';
import 'package:plante/outside/products/products_manager_error.dart';
import 'package:plante/outside/products/taken_products_images_storage.dart';

class ProductWithOCRIngredients {
  Product product;
  String? ingredients;
  ProductWithOCRIngredients(this.product, this.ingredients);
}

class ProductsManager {
  static const _NEEDED_OFF_FIELDS = [
    off.ProductField.BARCODE,
    off.ProductField.NAME,
    off.ProductField.NAME_IN_LANGUAGES,
    off.ProductField.BRANDS_TAGS,
    off.ProductField.CATEGORIES_TAGS,
    off.ProductField.CATEGORIES_TAGS_IN_LANGUAGES,
    off.ProductField.INGREDIENTS,
    off.ProductField.INGREDIENTS_TAGS,
    off.ProductField.INGREDIENTS_TAGS_IN_LANGUAGES,
    off.ProductField.INGREDIENTS_TEXT,
    off.ProductField.INGREDIENTS_TEXT_IN_LANGUAGES,
    off.ProductField.SELECTED_IMAGE,
  ];

  final OffApi _off;
  final Backend _backend;
  final TakenProductsImagesStorage _takenProductsImagesTable;
  final ProductsConverterAndCacher _productsConverter;

  ProductsManager(this._off, this._backend, this._takenProductsImagesTable,
      Analytics analytics)
      : _productsConverter = ProductsConverterAndCacher(analytics);

  Future<Result<Product?, ProductsManagerError>> getProduct(
      String barcodeRaw, List<LangCode> langsPrioritized) async {
    return _getProduct(
        barcodeRaw: barcodeRaw, langsPrioritized: langsPrioritized);
  }

  Future<Result<Product?, ProductsManagerError>> inflate(
      BackendProduct backendProduct, List<LangCode> langsPrioritized) async {
    return _getProduct(
        backendProduct: backendProduct, langsPrioritized: langsPrioritized);
  }

  Future<Result<Product?, ProductsManagerError>> _getProduct(
      {String? barcodeRaw,
      BackendProduct? backendProduct,
      required List<LangCode> langsPrioritized}) async {
    if (barcodeRaw == null && backendProduct == null) {
      Log.e('Invalid getProduct implementation');
    }
    barcodeRaw ??= backendProduct!.barcode;

    final offLangs = langsPrioritized
        .map((e) => off.LanguageHelper.fromJson(e.name))
        .toList();
    final configuration = off.ProductQueryConfiguration(barcodeRaw,
        languages: offLangs, fields: _NEEDED_OFF_FIELDS.toList());

    final off.ProductResult offProductResult;
    try {
      offProductResult = await _off.getProduct(configuration);
    } on IOException catch (e) {
      Log.w('Network error in ProductsManager.getProduct', ex: e);
      return Err(ProductsManagerError.NETWORK_ERROR);
    }
    final offProduct = offProductResult.product;
    if (offProduct == null) {
      return Ok(null);
    }

    final barcode = offProduct.barcode!;
    if (backendProduct == null) {
      final backendProductResult = await _backend.requestProduct(barcode);
      if (backendProductResult.isErr) {
        return _convertBackendError(backendProductResult);
      }
      backendProduct = backendProductResult.unwrap();
    }

    final result = _productsConverter.convertAndCache(
        offProduct, backendProduct, langsPrioritized);
    return Ok(result);
  }

  /// Returns updated product if update was successful
  Future<Result<Product, ProductsManagerError>> createUpdateProduct(
      Product product) async {
    // Ensure the product is in our cache if it exists in OFF
    final getResult =
        await getProduct(product.barcode, product.langsPrioritized.toList());
    if (getResult.isErr) {
      return Err(getResult.unwrapErr());
    }

    // OFF

    final offProduct = _productsConverter.convertToSendBack(product);
    if (offProduct == null) {
      return Ok(product);
    }

    final offResult;
    try {
      offResult = await _off.saveProduct(_offUser(), offProduct);
    } on IOException catch (e) {
      Log.w('ProductsManager.createUpdateProduct 1, e', ex: e);
      return Err(ProductsManagerError.NETWORK_ERROR);
    }
    if (offResult.error != null) {
      return Err(ProductsManagerError.OTHER);
    }

    var imgUploadRes = await _uploadImages(product, ProductImageType.FRONT);
    if (imgUploadRes.isErr) {
      return Err(imgUploadRes.unwrapErr());
    }
    imgUploadRes = await _uploadImages(product, ProductImageType.INGREDIENTS);
    if (imgUploadRes.isErr) {
      return Err(imgUploadRes.unwrapErr());
    }

    // Backend

    final originalProduct = getResult.unwrap();
    final changedLangs = _langsDiff(
        product, _productsConverter.getCached(originalProduct?.barcode ?? ''));

    final backendResult = await _backend.createUpdateProduct(product.barcode,
        vegetarianStatus: product.vegetarianStatus,
        veganStatus: product.veganStatus,
        changedLangs: changedLangs);
    if (backendResult.isErr) {
      return _convertBackendError(backendResult);
    }

    final result =
        await getProduct(product.barcode, product.langsPrioritized.toList());
    if (result.isErr) {
      return Err(result.unwrapErr());
    } else if (result.unwrap() == null) {
      Log.w("Product was saved but couldn't be obtained back");
      return Err(ProductsManagerError.OTHER);
    } else {
      return Ok(result.unwrap()!);
    }
  }

  List<LangCode> _langsDiff(Product? lhs, Product? rhs) {
    if (lhs == null && rhs != null) {
      return rhs.langsPrioritized.toList();
    } else if (lhs != null && rhs == null) {
      return lhs.langsPrioritized.toList();
    } else if (lhs == null && rhs == null) {
      return [];
    }
    final langs = <LangCode>{};
    langs.addAll(lhs!.langsPrioritized);
    langs.addAll(rhs!.langsPrioritized);
    final diff = <LangCode>{};
    for (final lang in langs) {
      if (lhs.nameLangs[lang] != rhs.nameLangs[lang]) {
        diff.add(lang);
      }
      if (lhs.ingredientsTextLangs[lang] != rhs.ingredientsTextLangs[lang]) {
        diff.add(lang);
      }
      if (lhs.imageFrontLangs[lang] != rhs.imageFrontLangs[lang]) {
        diff.add(lang);
      }
      if (lhs.imageFrontThumbLangs[lang] != rhs.imageFrontThumbLangs[lang]) {
        diff.add(lang);
      }
      if (lhs.imageIngredientsLangs[lang] != rhs.imageIngredientsLangs[lang]) {
        diff.add(lang);
      }
    }
    return diff.toList();
  }

  Future<Result<None, ProductsManagerError>> _uploadImages(
      Product product, ProductImageType imageType) async {
    for (final lang in product.langsPrioritized) {
      final res = await _uploadImage(product, imageType, lang);
      if (res.isErr) {
        return res;
      }
    }
    return Ok(None());
  }

  Future<Result<None, ProductsManagerError>> _uploadImage(
      Product product, ProductImageType imageType, LangCode lang) async {
    if (!product.isImageFile(imageType, lang)) {
      return Ok(None());
    }
    final uri = product.imageUri(imageType, lang)!;
    final alreadyUploaded = await _takenProductsImagesTable.contains(uri);
    if (alreadyUploaded) {
      return Ok(None());
    }

    final off.ImageField offImageType;
    switch (imageType) {
      case ProductImageType.FRONT_THUMB:
        Log.e('Uploading thumbs is not supported');
        return Ok(None());
      case ProductImageType.FRONT:
        offImageType = off.ImageField.FRONT;
        break;
      case ProductImageType.INGREDIENTS:
        offImageType = off.ImageField.INGREDIENTS;
        break;
    }

    final image = off.SendImage(
      lang: off.LanguageHelper.fromJson(lang.name),
      barcode: product.barcode,
      imageField: offImageType,
      imageUri: uri,
    );
    final status;
    try {
      status = await _off.addProductImage(_offUser(), image);
    } on IOException catch (e) {
      Log.w('ProductsManager.createUpdateProduct $imageType $uri', ex: e);
      return Err(ProductsManagerError.NETWORK_ERROR);
    }
    if (status.error != null) {
      return Err(ProductsManagerError.OTHER);
    }
    unawaited(_takenProductsImagesTable.store(uri));
    return Ok(None());
  }

  Future<Result<ProductWithOCRIngredients, ProductsManagerError>>
      updateProductAndExtractIngredients(
          Product product, LangCode ingredientsLangCode) async {
    final productUpdateResult = await createUpdateProduct(product);
    if (productUpdateResult.isErr) {
      return Err(productUpdateResult.unwrapErr());
    }
    final updatedProduct = productUpdateResult.unwrap();

    final offLang = off.LanguageHelper.fromJson(ingredientsLangCode.name);

    final off.OcrIngredientsResult response;
    try {
      response =
          await _off.extractIngredients(_offUser(), product.barcode, offLang);
    } on IOException catch (e) {
      Log.w('ProductsManager.updateProductAndExtractIngredients, e', ex: e);
      return Err(ProductsManagerError.NETWORK_ERROR);
    }
    if (response.status == 0) {
      return Ok(ProductWithOCRIngredients(
          updatedProduct, response.ingredientsTextFromImage));
    } else {
      return Ok(ProductWithOCRIngredients(updatedProduct, null));
    }
  }

  off.User _offUser() =>
      const off.User(userId: OffUser.USERNAME, password: OffUser.PASSWORD);
}

Result<T1, ProductsManagerError> _convertBackendError<T1, T2>(
    Result<T2, BackendError> backendResult) {
  if (backendResult.unwrapErr().errorKind == BackendErrorKind.NETWORK_ERROR) {
    return Err(ProductsManagerError.NETWORK_ERROR);
  } else {
    return Err(ProductsManagerError.OTHER);
  }
}
