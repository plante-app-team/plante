import 'dart:io';

import 'package:either_option/either_option.dart';
import 'package:openfoodfacts/openfoodfacts.dart' as off;
import 'package:untitled_vegan_app/base/log.dart';
import 'package:untitled_vegan_app/model/ingredient.dart';

import 'package:untitled_vegan_app/base/either_extension.dart';
import 'package:untitled_vegan_app/model/product.dart';
import 'package:untitled_vegan_app/model/veg_status.dart';
import 'package:untitled_vegan_app/model/veg_status_source.dart';
import 'package:untitled_vegan_app/outside/backend/backend.dart';
import 'package:untitled_vegan_app/outside/backend/backend_error.dart';
import 'package:untitled_vegan_app/outside/off/off_api.dart';
import 'package:untitled_vegan_app/outside/off/off_user.dart';
import 'package:untitled_vegan_app/outside/products/products_manager_error.dart';


class ProductWithOCRIngredients {
  Product product;
  String? ingredients;
  ProductWithOCRIngredients(this.product, this.ingredients);
}

class ProductsManager {
  static const _NEEDED_OFF_FIELDS = [
    off.ProductField.BARCODE,
    off.ProductField.NAME,
    off.ProductField.NAME_TRANSLATED,
    off.ProductField.BRANDS_TAGS,
    off.ProductField.CATEGORIES_TAGS,
    off.ProductField.CATEGORIES_TAGS_TRANSLATED,
    off.ProductField.INGREDIENTS,
    off.ProductField.INGREDIENTS_TEXT,
    off.ProductField.INGREDIENTS_TEXT_TRANSLATED,
    off.ProductField.IMAGES,
  ];
  static final _notTranslatedRegex = RegExp(r"^\w\w:.*");

  final OffApi _off;
  final Backend _backend;
  final _productsCache = <String, Product>{};

  ProductsManager(this._off, this._backend);

  Future<Either<Product?, ProductsManagerError>> getProduct(String barcodeRaw, String langCode) async {
    final configuration = off.ProductQueryConfiguration(
        barcodeRaw,
        lc: langCode,
        language: off.LanguageHelper.fromJson(langCode),
        fields: _NEEDED_OFF_FIELDS.toList());

    final offProductResult;
    try {
      offProductResult = await _off.getProduct(configuration);
    } on IOException catch (e) {
      Log.w("Network error in ProductsManager.getProduct", ex: e);
      return Right(ProductsManagerError.NETWORK_ERROR);
    }
    final offProduct = offProductResult.product;
    if (offProduct == null) {
      return Left(null);
    }

    final barcode = offProduct.barcode!;
    final backendProductResult = await _backend.requestProduct(barcode);
    if (backendProductResult.isRight) {
      return _convertBackendError(backendProductResult);
    }
    final backendProduct = backendProductResult.requireLeft();

    var result = Product((v) => v
      ..barcode = barcode

      ..vegetarianStatus = VegStatus.safeValueOf(backendProduct?.vegetarianStatus ?? "")
      ..vegetarianStatusSource = VegStatusSource.safeValueOf(backendProduct?.vegetarianStatusSource ?? "")
      ..veganStatus = VegStatus.safeValueOf(backendProduct?.veganStatus ?? "")
      ..veganStatusSource = VegStatusSource.safeValueOf(backendProduct?.veganStatusSource ?? "")

      ..name = offProduct.productNameTranslated
      ..brands.addAll(offProduct.brandsTags ?? [])
      ..categories.addAll(offProduct.categoriesTagsTranslated ?? [])
      ..ingredientsText = offProduct.ingredientsTextTranslated
      ..ingredientsAnalyzed.addAll(_extractIngredientsAnalyzed(offProduct))
      ..imageFront = _extractImageUri(offProduct, ProductImageType.FRONT, langCode)
      ..imageIngredients = _extractImageUri(offProduct, ProductImageType.INGREDIENTS, langCode)
    );

    if (backendProduct?.vegetarianStatus != null) {
      final vegetarianStatus = VegStatus.safeValueOf(backendProduct?.vegetarianStatus ?? "");
      var vegetarianStatusSource = VegStatusSource.safeValueOf(backendProduct?.vegetarianStatusSource ?? "");
      if (vegetarianStatusSource == null && vegetarianStatus != null) {
        vegetarianStatusSource = VegStatusSource.community;
      }
      result = result.rebuild((v) => v
        ..vegetarianStatus = vegetarianStatus
        ..vegetarianStatusSource = vegetarianStatusSource);
    }
    if (backendProduct?.veganStatus != null) {
      final veganStatus = VegStatus.safeValueOf(backendProduct?.veganStatus ?? "");
      var veganStatusSource = VegStatusSource.safeValueOf(backendProduct?.veganStatusSource ?? "");
      if (veganStatusSource == null && veganStatus != null) {
        veganStatusSource = VegStatusSource.community;
      }
      result = result.rebuild((v) => v
        ..veganStatus = veganStatus
        ..veganStatusSource = veganStatusSource);
    }

    // NOTE: server veg-status parsing could fail (and server could have no veg-status).
    if (result.vegetarianStatus == null) {
      if (result.vegetarianStatusAnalysis != null) {
        result = result.rebuild((v) => v
          ..vegetarianStatus = result.vegetarianStatusAnalysis
          ..vegetarianStatusSource = VegStatusSource.open_food_facts);
      }
    }
    if (result.veganStatus == null) {
      if (result.veganStatusAnalysis != null) {
        result = result.rebuild((v) => v
          ..veganStatus = result.veganStatusAnalysis
          ..veganStatusSource = VegStatusSource.open_food_facts);
      }
    }

    // First store the original product into cache
    _productsCache[barcode] = result;

    // Now filter out not translated values
    final brandsFiltered = result.brands!.where((e) => !_notTranslatedRegex.hasMatch(e));
    result = result.rebuild((v) => v.brands.replace(brandsFiltered));

    final categoriesFiltered = result.categories!.where((e) => !_notTranslatedRegex.hasMatch(e));
    result = result.rebuild((v) => v.categories.replace(categoriesFiltered));

    return Left(result);
  }

  Uri? _extractImageUri(off.Product offProduct, ProductImageType imageType, String langCode) {
    final images = offProduct.images;
    if (images == null) {
      return null;
    }
    final lang = off.LanguageHelper.fromJson(langCode);
    for (final image in images) {
      if (image.language != lang
          || image.url == null) {
        continue;
      }
      if (imageType == ProductImageType.FRONT
          && image.size != off.ImageSize.DISPLAY) {
        continue;
      }
      if (imageType == ProductImageType.INGREDIENTS
          && image.size != off.ImageSize.ORIGINAL) {
        continue;
      }

      if (image.field == off.ImageField.FRONT
          && imageType == ProductImageType.FRONT) {
        return Uri.parse(image.url!);
      }
      if (image.field == off.ImageField.INGREDIENTS
          && imageType == ProductImageType.INGREDIENTS) {
        return Uri.parse(image.url!);
      }
    }
    return null;
  }

  Iterable<Ingredient> _extractIngredientsAnalyzed(off.Product offProduct) {
    if (offProduct.ingredientsTextTranslated == null) {
      // If ingredients text is not translated then analysis is done
      // for some international ingredients and most likely is not
      // translated.
      return [];
    }
    final offIngredients = offProduct.ingredients;
    if (offIngredients == null) {
      return [];
    }
    return offIngredients.map((ingr) => ingr.convert());
  }

  /// Returns updated product if update was successful
  Future<Either<Product, ProductsManagerError>> createUpdateProduct(Product product, String langCode) async {
    final cachedProduct = _productsCache[product.barcode];
    if (cachedProduct != null) {
      final allBrands = _connectDifferentlyTranslated(
          cachedProduct.brands, product.brands);
      final allCategories = _connectDifferentlyTranslated(
          cachedProduct.categories, product.categories);

      final productWithNotTranslatedFields = product.rebuild((v) => v
        ..brands.replace(allBrands)
        ..categories.replace(allCategories));
      final cachedProductNormalized = cachedProduct.rebuild((v) => v
        ..brands.replace(_sortedNotNull(cachedProduct.brands))
        ..categories.replace(_sortedNotNull(cachedProduct.categories)));
      if (productWithNotTranslatedFields == cachedProductNormalized) {
        // Input product is same as it was when it was cached
        return Left(product);
      } else {
        // Let's insert back the not translated fields before sending product to OFF.
        // If we won't do that, that would mean we are to erase existing values
        // from the OFF product which is not very nice.
        product = productWithNotTranslatedFields;
      }
    }

    // OFF product

    final offProduct = off.Product(
        lang: off.LanguageHelper.fromJson(langCode),
        barcode: product.barcode,
        productNameTranslated: product.name,
        brands: _join(product.brands, null),
        categories: _join(product.categories, langCode),
        ingredientsTextTranslated: product.ingredientsText);
    final offResult;
    try {
      offResult = await _off.saveProduct(_offUser(), offProduct);
    } on IOException catch(e) {
      Log.w("ProductsManager.createUpdateProduct 1, e", ex: e);
      return Right(ProductsManagerError.NETWORK_ERROR);
    }
    if (offResult.error != null) {
      return Right(ProductsManagerError.OTHER);
    }

    // OFF front image

    if (product.isFrontImageFile()) {
      final image = off.SendImage(
        lang: off.LanguageHelper.fromJson(langCode),
        barcode: product.barcode,
        imageField: off.ImageField.FRONT,
        imageUri: product.imageFront!,
      );
      final status;
      try {
        status = await _off.addProductImage(_offUser(), image);
      } on IOException catch(e) {
        Log.w("ProductsManager.createUpdateProduct 2, e", ex: e);
        return Right(ProductsManagerError.NETWORK_ERROR);
      }
      if (status.error != null) {
        return Right(ProductsManagerError.OTHER);
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
      final status;
      try {
        status = await _off.addProductImage(_offUser(), image);
      } on IOException catch(e) {
        Log.w("ProductsManager.createUpdateProduct 3, e", ex: e);
        return Right(ProductsManagerError.NETWORK_ERROR);
      }
      if (status.error != null) {
        return Right(ProductsManagerError.OTHER);
      }
    }

    // Backend product

    final backendResult = await _backend.createUpdateProduct(
        product.barcode,
        vegetarianStatus: product.vegetarianStatus,
        veganStatus: product.veganStatus);
    if (backendResult.isRight) {
      return _convertBackendError(backendResult);
    }

    final result = await getProduct(product.barcode, langCode);
    if (result.isRight) {
      return Right(result.requireRight());
    } else if (result.requireLeft() == null) {
      Log.w("Product was saved but couldn't be obtained back");
      return Right(ProductsManagerError.OTHER);
    } else {
      return Left(result.requireLeft()!);
    }
  }

  List<String> _connectDifferentlyTranslated(
      Iterable<String>? withNotTranslated, Iterable<String>? translatedOnly) {
    final notTranslated = withNotTranslated?.where(
            (e) => _notTranslatedRegex.hasMatch(e))
        .toList() ?? [];
    final allStrings = (translatedOnly?.toList() ?? []) + notTranslated;
    allStrings.sort();
    return allStrings;
  }

  List<String> _sortedNotNull(Iterable<String>? input) {
    final result = input?.toList() ?? [];
    result.sort();
    return result;
  }

  String? _join(Iterable<String>? strs, String? langCode) {
    if (strs != null && strs.isNotEmpty) {
      final langPrefix = langCode != null ? "$langCode:" : "";
      return strs.map((e) =>
        _notTranslatedRegex.hasMatch(e) ? e : "$langPrefix$e")
        .join(", ");
    }
    return null;
  }

  Future<Either<ProductWithOCRIngredients, ProductsManagerError>>
      updateProductAndExtractIngredients(Product product, String langCode) async {
    final productUpdateResult = await createUpdateProduct(product, langCode);
    if (productUpdateResult.isRight) {
      return Right(productUpdateResult.requireRight());
    }
    final updatedProduct = productUpdateResult.requireLeft();

    final offLang = off.LanguageHelper.fromJson(langCode);

    final response;
    try {
      response = await _off.extractIngredients(_offUser(), product.barcode, offLang);
    } on IOException catch(e) {
      Log.w("ProductsManager.updateProductAndExtractIngredients, e", ex: e);
      return Right(ProductsManagerError.NETWORK_ERROR);
    }
    if (response.status == 0) {
      return Left(ProductWithOCRIngredients(updatedProduct, response.ingredientsTextFromImage));
    } else {
      return Left(ProductWithOCRIngredients(updatedProduct, null));
    }
  }

  off.User _offUser() => off.User(userId: OffUser.USERNAME, password: OffUser.PASSWORD);
}

extension _OffIngredientExtension on off.Ingredient {
  Ingredient convert() => Ingredient((v) => v
    ..name = text
    ..vegetarianStatus = _convertVegStatus(vegetarian)
    ..veganStatus = _convertVegStatus(vegan));

  VegStatus? _convertVegStatus(off.IngredientSpecialPropertyStatus? offVegStatus) {
    if (offVegStatus == null) {
      return VegStatus.unknown;
    }
    switch (offVegStatus) {
      case off.IngredientSpecialPropertyStatus.POSITIVE:
        return VegStatus.positive;
      case off.IngredientSpecialPropertyStatus.NEGATIVE:
        return VegStatus.negative;
      case off.IngredientSpecialPropertyStatus.MAYBE:
        return VegStatus.possible;
      case off.IngredientSpecialPropertyStatus.IGNORE:
        return null;
      default:
        throw StateError("Unhandled item: $offVegStatus");
    }
  }
}

Either<T1, ProductsManagerError> _convertBackendError<T1, T2>(
    Either<T2, BackendError> backendResult) {
  if (backendResult.requireRight().errorKind == BackendErrorKind.NETWORK_ERROR) {
    return Right(ProductsManagerError.NETWORK_ERROR);
  } else {
    return Right(ProductsManagerError.OTHER);
  }
}
