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

    var result = Product((v) => v
      ..barcode = barcode

      ..vegetarianStatus = VegStatus.safeValueOf(backendProduct?.vegetarianStatus ?? "")
      ..vegetarianStatusSource = VegStatusSource.safeValueOf(backendProduct?.vegetarianStatusSource ?? "")
      ..veganStatus = VegStatus.safeValueOf(backendProduct?.veganStatus ?? "")
      ..veganStatusSource = VegStatusSource.safeValueOf(backendProduct?.veganStatusSource ?? "")

      ..name = offProduct.productNameTranslated
      ..brands.addAll(offProduct.brandsTags ?? [])
      ..categories.addAll(offProduct.categoriesTagsTranslated ?? [])
      ..ingredients = offProduct.ingredientsTextTranslated
      ..imageFront = _extractImageUri(offProduct, ProductImageType.FRONT, langCode)
      ..imageIngredients = _extractImageUri(offProduct, ProductImageType.INGREDIENTS, langCode)
    );

    // First store the original product into cache
    _productsCache[barcode] = result;

    // Now filter out not translated values
    final brandsFiltered = result.brands!.where((e) => !_notTranslatedRegex.hasMatch(e));
    result = result.rebuild((v) => v.brands.replace(brandsFiltered));

    final categoriesFiltered = result.categories!.where((e) => !_notTranslatedRegex.hasMatch(e));
    result = result.rebuild((v) => v.categories.replace(categoriesFiltered));

    return result;
  }

  Uri? _extractImageUri(off.Product offProduct, ProductImageType imageType, String langCode) {
    final images = offProduct.images;
    if (images == null) {
      return null;
    }
    final lang = off.LanguageHelper.fromJson(langCode);
    for (final image in images) {
      if (image.language != lang
          || image.size != off.ImageSize.DISPLAY
          || image.url == null) {
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

  /// Returns updated product if update was successful
  Future<Product?> createUpdateProduct(Product product, String langCode) async {
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
        return product;
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
        ingredientsTextTranslated: product.ingredients);
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

  String? _join(Iterable<String>? strs, String? langCode) {
    if (strs != null && strs.isNotEmpty) {
      final langPrefix = langCode != null ? "$langCode:" : "";
      return strs.map((e) =>
        _notTranslatedRegex.hasMatch(e) ? e : "$langPrefix$e")
        .join(", ");
    }
    return null;
  }

  Future<ProductWithOCRIngredients?> updateProductAndExtractIngredients(Product product, String langCode) async {
    final updatedProduct = await createUpdateProduct(product, langCode);
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
