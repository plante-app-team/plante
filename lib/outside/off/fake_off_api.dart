import 'package:flutter/cupertino.dart';
import 'package:openfoodfacts/model/OcrIngredientsResult.dart' as off;
import 'package:openfoodfacts/openfoodfacts.dart' as off;
import 'package:plante/base/base.dart';
import 'package:plante/base/settings.dart';
import 'package:plante/outside/http_client.dart';
import 'package:plante/outside/off/off_api.dart';
import 'package:plante/outside/off/off_shop.dart';

class FakeOffApi implements OffApi {
  final Settings _settings;
  final HttpClient _httpClient;
  final Map<String, off.Product> _fakeProducts = {};
  final Set<String> _triedOcrProducts = {};

  FakeOffApi(this._settings,this._httpClient);

  @override
  @visibleForTesting
  HttpClient get httpClient {
    return _httpClient;
  }

  @override
  Future<off.Status> addProductImage(off.User user, off.SendImage image) async {
    await _delay();
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

  Future<void> _delay() async {
    if (await _settings.testingBackendsQuickAnswers()) {
      await Future.delayed(const Duration(milliseconds: 2));
    } else {
      await Future.delayed(const Duration(seconds: 2));
    }
  }

  @override
  Future<off.OcrIngredientsResult> extractIngredients(
      off.User user, String barcode, off.OpenFoodFactsLanguage language) async {
    await _delay();
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
    await _delay();
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
    final product =
        off.Product(barcode: configuration.barcode, productNameInLanguages: {
      for (var l in configuration.languages!) l: _generateName()
    }, selectedImages: <off.ProductImage>[
      off.ProductImage(
          field: off.ImageField.FRONT,
          size: off.ImageSize.DISPLAY,
          url: 'https://en.wikipedia.org/static/apple-touch/wikipedia.png',
          language: off.OpenFoodFactsLanguage.RUSSIAN),
      off.ProductImage(
          field: off.ImageField.INGREDIENTS,
          size: off.ImageSize.DISPLAY,
          url: 'https://en.wikipedia.org/static/apple-touch/wikipedia.png',
          language: off.OpenFoodFactsLanguage.RUSSIAN)
    ], ingredientsTextInLanguages: {
      for (var l in configuration.languages!) l: 'lemon, water'
    }, ingredients: <off.Ingredient>[
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
    await _delay();
    _fakeProducts[product.barcode!] = product;
    return off.Status(status: 1);
  }

  @override
  Future<List<OffShop>> getShopsForLocation(
      String countryIso) async {
    //TODO implement
    return [];
  }

  @override
  Future<off.SearchResult> getVeganProductsForShop(
      String countryIso, String shop, int page) async {
    //TODO implement
    return const off.SearchResult();
  }
}

String _generateName() {
  final cookingType = _FAKE_COOKING_TYPE[randInt(0, _FAKE_COOKING_TYPE.length)];
  final name = _FAKE_NAMES[randInt(0, _FAKE_NAMES.length)];
  return '$cookingType $name';
}

const _FAKE_COOKING_TYPE = [
  'Fried',
  'Boiled',
  'Dried',
  'Toasted',
  'Fresh',
  'Organic',
  'Delicious',
];

const _FAKE_NAMES = [
  'bananas',
  'apples',
  'strawberries',
  'grapes',
  'oranges',
  'Watermelon',
  'Lemons',
  'avocados',
  'peaches',
  'blueberries',
  'pineapple',
  'cantaloupe',
  'cherries',
  'pears',
  'limes',
  'mangoes',
  'raspberries',
  'blackberries',
  'plums',
  'Nectarines',
  'Vegetables',
  'potatoes',
  'tomatoes',
  'onions',
  'carrots',
  'broccoli',
  'bell peppers',
  'lettuce',
  'cucumbers',
  'celery',
  'salad mix',
  'corn',
  'garlic',
  'mushrooms',
  'cabbage',
  'spinach',
  'sweet potatoes',
  'green beans',
  'cauliflower',
  'green onions',
  'asparagus',
];
