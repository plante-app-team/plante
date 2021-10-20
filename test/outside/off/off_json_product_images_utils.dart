import 'dart:convert';

String createOffImageUrlFront(String countryCode) {
  return 'https://static.openfoodfacts.org/images/products/123/front_$countryCode.16.400.jpg';
}

String createOffImageUrlThumb(String countryCode) {
  return 'https://static.openfoodfacts.org/images/products/123/front_$countryCode.16.200.jpg';
}

String createOffImageUrlIngredients(String countryCode) {
  return 'https://static.openfoodfacts.org/images/products/123/ingredients_$countryCode.19.full.jpg';
}

String createOffSelectedImagesJson(List<String> countryCodes) {
  final fronts = {
    for (final code in countryCodes) code: createOffImageUrlFront(code)
  };
  final thumbs = {
    for (final code in countryCodes) code: createOffImageUrlThumb(code)
  };
  final ingredients = {
    for (final code in countryCodes) code: createOffImageUrlIngredients(code)
  };
  return '''
    {
       "front":{
          "display": ${jsonEncode(fronts)},
          "small":${jsonEncode(thumbs)}
       },
       "ingredients":{
          "display":${jsonEncode(ingredients)}
       }
    }
  ''';
}

final offExpectedImageFrontRu = createOffImageUrlFront('ru');
final offExpectedImageFrontThumbRu = createOffImageUrlThumb('ru');
final offExpectedImageIngredientsRu = createOffImageUrlIngredients('ru');

final offExpectedImageFrontDe = createOffImageUrlFront('de');
final offExpectedImageFrontThumbDe = createOffImageUrlThumb('de');
final offExpectedImageIngredientsDe = createOffImageUrlIngredients('de');

final offSelectedImagesRuDeJson = createOffSelectedImagesJson(['ru', 'de']);
final offSelectedImagesRuJson = createOffSelectedImagesJson(['ru']);
