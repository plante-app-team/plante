import 'package:openfoodfacts/model/OcrIngredientsResult.dart' as off;
import 'package:openfoodfacts/openfoodfacts.dart' as off;
import 'package:plante/base/settings.dart';
import 'package:plante/outside/off/off_api.dart';

class FakeOffApi implements OffApi {
  final Settings _settings;
  final Map<String, off.Product> _fakeProducts = {};
  final Set<String> _triedOcrProducts = {};

  FakeOffApi(this._settings);

  @override
  Future<off.Status> addProductImage(off.User user, off.SendImage image) async {
    await Future<dynamic>.delayed(const Duration(seconds: 2));
    final newImage;
    if (image.imageField == off.ImageField.FRONT) {
      newImage = off.ProductImage(
          field: off.ImageField.FRONT,
          size: off.ImageSize.DISPLAY,
          url: 'https://en.wikipedia.org/static/apple-touch/wikipedia.png',
          language: off.OpenFoodFactsLanguage.RUSSIAN);
    } else if (image.imageField == off.ImageField.INGREDIENTS) {
      newImage = off.ProductImage(
          field: off.ImageField.INGREDIENTS,
          size: off.ImageSize.ORIGINAL,
          url: 'https://en.wikipedia.org/static/apple-touch/wikipedia.png',
          language: off.OpenFoodFactsLanguage.RUSSIAN);
    } else {
      throw Error();
    }
    _fakeProducts[image.barcode]!.images =
        (_fakeProducts[image.barcode]!.images ?? []) +
            [newImage as off.ProductImage];
    return off.Status(status: 0);
  }

  @override
  Future<off.OcrIngredientsResult> extractIngredients(
      off.User user, String barcode, off.OpenFoodFactsLanguage language) async {
    await Future.delayed(const Duration(seconds: 2));
    if (!_triedOcrProducts.contains(barcode)) {
      // First OCR attempt will always end with a failure
      _triedOcrProducts.add(barcode);
      return const off.OcrIngredientsResult(status: 1);
    }
    return const off.OcrIngredientsResult(
        status: 0, ingredientsTextFromImage: 'Cucumbers, salad, onion');
  }

  @override
  Future<off.ProductResult> getProduct(
      off.ProductQueryConfiguration configuration) async {
    await Future.delayed(const Duration(seconds: 2));
    if (_fakeProducts[configuration.barcode] != null) {
      return off.ProductResult(
          status: 1,
          barcode: configuration.barcode,
          product: _fakeProducts[configuration.barcode]);
    }

    if (await _settings.fakeOffApiProductNotFound()) {
      return off.ProductResult(
          status: 1, barcode: configuration.barcode, product: null);
    }
    final product = off.Product(
        barcode: '123',
        productNameTranslated: 'name',
        images: <off.ProductImage>[
          off.ProductImage(
              field: off.ImageField.FRONT,
              size: off.ImageSize.DISPLAY,
              url: 'https://en.wikipedia.org/static/apple-touch/wikipedia.png',
              language: off.OpenFoodFactsLanguage.RUSSIAN),
          off.ProductImage(
              field: off.ImageField.INGREDIENTS,
              size: off.ImageSize.ORIGINAL,
              url: 'https://en.wikipedia.org/static/apple-touch/wikipedia.png',
              language: off.OpenFoodFactsLanguage.RUSSIAN)
        ],
        ingredientsTextTranslated: 'lemon, water',
        ingredients: <off.Ingredient>[
          off.Ingredient(
              vegan: off.IngredientSpecialPropertyStatus.POSITIVE,
              vegetarian: off.IngredientSpecialPropertyStatus.POSITIVE,
              text: 'water'),
          off.Ingredient(
              vegan: off.IngredientSpecialPropertyStatus.POSITIVE,
              vegetarian: off.IngredientSpecialPropertyStatus.POSITIVE,
              text: 'lemon'),
        ]);
    return off.ProductResult(
        status: 1, barcode: configuration.barcode, product: product);
  }

  @override
  Future<off.Status> saveProduct(off.User user, off.Product product) async {
    await Future.delayed(const Duration(seconds: 2));
    _fakeProducts[product.barcode!] = product;
    return off.Status(status: 1);
  }
}
