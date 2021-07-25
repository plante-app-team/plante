import 'package:built_collection/built_collection.dart';
import 'package:openfoodfacts/utils/LanguageHelper.dart';
import 'package:openfoodfacts/openfoodfacts.dart' as off;
import 'package:plante/logging/analytics.dart';
import 'package:plante/logging/log.dart';
import 'package:plante/model/ingredient.dart';
import 'package:plante/model/lang_code.dart';
import 'package:plante/model/product.dart';
import 'package:plante/model/veg_status.dart';
import 'package:plante/model/veg_status_source.dart';
import 'package:plante/outside/backend/backend_product.dart';

class ProductsConverter {
  static final _notTranslatedRegex = RegExp(r'^\w\w:.*');
  final Analytics _analytics;
  final _productsCache = <String, Product>{};

  ProductsConverter(this._analytics);

  Product convert(off.Product offProduct, BackendProduct? backendProduct,
      List<LangCode> langsPrioritized) {
    var result = Product((v) => v
      ..langsPrioritized.addAll(langsPrioritized)
      ..barcode = offProduct.barcode
      ..vegetarianStatus =
          VegStatus.safeValueOf(backendProduct?.vegetarianStatus ?? '')
      ..vegetarianStatusSource = VegStatusSource.safeValueOf(
          backendProduct?.vegetarianStatusSource ?? '')
      ..veganStatus = VegStatus.safeValueOf(backendProduct?.veganStatus ?? '')
      ..veganStatusSource =
          VegStatusSource.safeValueOf(backendProduct?.veganStatusSource ?? '')
      ..moderatorVegetarianChoiceReasonId =
          backendProduct?.moderatorVegetarianChoiceReason
      ..moderatorVegetarianSourcesText =
          backendProduct?.moderatorVegetarianSourcesText
      ..moderatorVeganChoiceReasonId =
          backendProduct?.moderatorVeganChoiceReason
      ..moderatorVeganSourcesText = backendProduct?.moderatorVeganSourcesText
      ..nameLangs =
          _castOffLangs(offProduct.productNameInLanguages, _convertOffStr)
      ..brands.addAll(offProduct.brandsTags ?? [])
      ..ingredientsTextLangs =
          _castOffLangs(offProduct.ingredientsTextInLanguages, _convertOffStr)
      ..ingredientsAnalyzedLangs = _extractIngredientsAnalyzed(offProduct)
      ..imageFrontLangs = _extractImagesUris(offProduct, off.ImageField.FRONT,
          off.ImageSize.DISPLAY, langsPrioritized)
      ..imageFrontThumbLangs = _extractImagesUris(offProduct,
          off.ImageField.FRONT, off.ImageSize.SMALL, langsPrioritized)
      ..imageIngredientsLangs = _extractImagesUris(offProduct,
          off.ImageField.INGREDIENTS, off.ImageSize.DISPLAY, langsPrioritized));

    if (backendProduct?.vegetarianStatus != null) {
      final vegetarianStatus =
          VegStatus.safeValueOf(backendProduct?.vegetarianStatus ?? '');
      var vegetarianStatusSource = VegStatusSource.safeValueOf(
          backendProduct?.vegetarianStatusSource ?? '');
      if (vegetarianStatusSource == null && vegetarianStatus != null) {
        vegetarianStatusSource = VegStatusSource.community;
      }
      result = result.rebuild((v) => v
        ..vegetarianStatus = vegetarianStatus
        ..vegetarianStatusSource = vegetarianStatusSource);
    }
    if (backendProduct?.veganStatus != null) {
      final veganStatus =
          VegStatus.safeValueOf(backendProduct?.veganStatus ?? '');
      var veganStatusSource =
          VegStatusSource.safeValueOf(backendProduct?.veganStatusSource ?? '');
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
    _productsCache[offProduct.barcode!] = result;

    // Now filter out not translated values
    if (result.brands != null) {
      final brandsFiltered =
          result.brands!.where((e) => !_notTranslatedRegex.hasMatch(e));
      result = result.rebuild((v) => v.brands.replace(brandsFiltered));
    }
    return result;
  }

  MapBuilder<LangCode, T> _castOffLangs<T, O>(
      Map<off.OpenFoodFactsLanguage, O>? field, T? Function(O old) converter) {
    final result = MapBuilder<LangCode, T>();
    if (field == null) {
      return result;
    }
    for (final entry in field.entries) {
      final lang = LangCode.safeValueOf(entry.key.code);
      if (lang == null) {
        continue;
      }
      final convertedValue = converter.call(entry.value);
      if (convertedValue != null) {
        result[lang] = convertedValue;
      }
    }
    return result;
  }

  String? _convertOffStr(String offStr) {
    if (offStr.trim().isEmpty) {
      return null;
    }
    return offStr;
  }

  MapBuilder<LangCode, Uri> _extractImagesUris(off.Product offProduct,
      off.ImageField imageType, off.ImageSize size, List<LangCode> langs) {
    final result = MapBuilder<LangCode, Uri>();
    for (final lang in langs) {
      final image = _extractImageUri(offProduct, imageType, size, lang.name);
      if (image != null) {
        result[lang] = image;
      }
    }
    return result;
  }

  Uri? _extractImageUri(off.Product offProduct, off.ImageField imageType,
      off.ImageSize size, String langCode) {
    final images = offProduct.selectedImages;
    if (images == null) {
      return null;
    }
    final lang = off.LanguageHelper.fromJson(langCode);
    for (final image in images) {
      if (image.language != lang || image.url == null) {
        continue;
      }
      if (imageType == image.field && size == image.size) {
        return Uri.parse(image.url!);
      }
    }
    return null;
  }

  MapBuilder<LangCode, BuiltList<Ingredient>> _extractIngredientsAnalyzed(
      off.Product offProduct) {
    final offIngredients = offProduct.ingredients;
    final offIngredientsTextInLangs = offProduct.ingredientsTextInLanguages;
    final offIngredientsTags = offProduct.ingredientsTags;
    final offIngredientsTagsInLangs = offProduct.ingredientsTagsInLanguages;
    if (offIngredients == null ||
        offIngredientsTextInLangs == null ||
        offIngredientsTags == null ||
        offIngredientsTagsInLangs == null) {
      Log.w('One of the required OFF fields is null, offProduct: $offProduct');
      return MapBuilder();
    }

    // Build ingredients names translations
    final ingredientsIdsTranslations = <String, Map<LangCode, String>>{};
    final langs = <LangCode>{};
    for (var index = 0; index < offIngredientsTags.length; ++index) {
      final ingredientId = offIngredientsTags[index];
      if (ingredientsIdsTranslations[ingredientId] == null) {
        ingredientsIdsTranslations[ingredientId] = {};
      }
      for (final entry in offIngredientsTagsInLangs.entries) {
        final lang = LangCode.safeValueOf(entry.key.code);
        if (lang == null) {
          continue;
        }
        langs.add(lang);
        if (entry.value.length <= index) {
          _analytics.sendEvent('error_off_ingredients_tags_breaking_change');
          Log.w(
              'List in ingredientsTagsInLanguages is shorter than ingredientsTags');
          continue;
        }
        ingredientsIdsTranslations[ingredientId]![lang] = entry.value[index];
      }
    }

    final result = <LangCode, List<Ingredient>>{};
    for (final lang in langs) {
      if (result[lang] == null) {
        result[lang] = [];
      }
      for (final offIngredient in offIngredients) {
        final nameTranslation = ingredientsIdsTranslations[offIngredient.id]
                ?[lang] ??
            offIngredient.id ??
            '???';
        result[lang]!.add(Ingredient((e) => e
          ..name = nameTranslation
          ..vegetarianStatus = offIngredient.vegetarian.convert()
          ..veganStatus = offIngredient.vegan.convert()));
      }
    }

    final resultConverted = MapBuilder<LangCode, BuiltList<Ingredient>>();
    for (final entry in result.entries) {
      resultConverted[entry.key] = BuiltList.from(entry.value);
    }
    return resultConverted;
  }

  /// If returns null, should not send back
  off.Product? convertToSendBack(Product product) {
    final cachedProduct = _productsCache[product.barcode];
    if (cachedProduct != null) {
      final allBrands =
          _connectDifferentlyTranslated(cachedProduct.brands, product.brands);

      final productWithNotTranslatedFields =
          product.rebuild((v) => v..brands.replace(allBrands));
      final cachedProductNormalized = cachedProduct.rebuild(
          (v) => v..brands.replace(_sortedNotNull(cachedProduct.brands)));
      if (productWithNotTranslatedFields == cachedProductNormalized) {
        // Input product is same as it was when it was cached
        return null;
      } else {
        // Let's insert back the not translated fields before sending product to OFF.
        // If we won't do that, that would mean we are to erase existing values
        // from the OFF product which is not very nice.
        product = productWithNotTranslatedFields;
      }
    }

    final offProduct = off.Product(
        barcode: product.barcode,
        productNameInLanguages:
            _castToOffLangs(product.nameLangs, (e) => e! as String),
        brands: _joinAndMaybeAddLangCode(product.brands, null),
        ingredientsTextInLanguages:
            _castToOffLangs(product.ingredientsTextLangs, (e) => e! as String));

    if (cachedProduct == null) {
      // Product is being create for the first time
      offProduct.lang = off.LanguageHelper.fromJson(product.mainLang.name);
      offProduct.productName = product.name;
      offProduct.ingredientsText = product.ingredientsText;
    }

    return offProduct;
  }

  List<String> _connectDifferentlyTranslated(
      Iterable<String>? withNotTranslated, Iterable<String>? translatedOnly) {
    final notTranslated =
        withNotTranslated?.where(_notTranslatedRegex.hasMatch).toList() ?? [];
    final allStrings = (translatedOnly?.toList() ?? []) + notTranslated;
    allStrings.sort();
    return allStrings;
  }

  List<String> _sortedNotNull(Iterable<String>? input) {
    final result = input?.toList() ?? [];
    result.sort();
    return result;
  }

  String? _joinAndMaybeAddLangCode(Iterable<String>? strs, String? langCode) {
    if (strs != null && strs.isNotEmpty) {
      final langPrefix = langCode != null ? '$langCode:' : '';
      return strs
          .map((e) => _notTranslatedRegex.hasMatch(e) ? e : '$langPrefix$e')
          .join(', ');
    }
    return null;
  }

  Map<off.OpenFoodFactsLanguage, T> _castToOffLangs<T, O>(
      BuiltMap<LangCode, O> field, T Function(O old) converter) {
    final result = <off.OpenFoodFactsLanguage, T>{};
    for (final entry in field.entries) {
      final lang = off.LanguageHelper.fromJson(entry.key.name);
      if (lang == off.OpenFoodFactsLanguage.UNDEFINED) {
        Log.e("Couldn't convert a lang code into OFF lang: ${entry.key}");
        continue;
      }
      result[lang] = converter.call(entry.value);
    }
    return result;
  }
}

extension _OffIngSpecialPropertyStatusExt
    on off.IngredientSpecialPropertyStatus? {
  VegStatus? convert() {
    if (this == null) {
      return VegStatus.unknown;
    }
    switch (this) {
      case off.IngredientSpecialPropertyStatus.POSITIVE:
        return VegStatus.positive;
      case off.IngredientSpecialPropertyStatus.NEGATIVE:
        return VegStatus.negative;
      case off.IngredientSpecialPropertyStatus.MAYBE:
        return VegStatus.possible;
      case off.IngredientSpecialPropertyStatus.IGNORE:
        return null;
      default:
        throw StateError('Unhandled item: $this');
    }
  }
}
