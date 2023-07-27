import 'package:built_collection/built_collection.dart';
import 'package:openfoodfacts/openfoodfacts.dart' as off;
import 'package:openfoodfacts/utils/LanguageHelper.dart';
import 'package:plante/logging/analytics.dart';
import 'package:plante/logging/log.dart';
import 'package:plante/model/ingredient.dart';
import 'package:plante/model/lang_code.dart';
import 'package:plante/model/product.dart';
import 'package:plante/model/veg_status.dart';
import 'package:plante/model/veg_status_source.dart';
import 'package:plante/outside/backend/backend_product.dart';

class ProductsConverterAndCacher {
  static final _notTranslatedRegex = RegExp(r'^\w\w:.*');
  final Analytics _analytics;
  final _productsCache = <String, Product>{};

  ProductsConverterAndCacher(this._analytics);

  Product convertAndCache(off.Product offProduct,
      BackendProduct? backendProduct, List<LangCode> langsPrioritized) {
    var result = Product((v) => v
      ..langsPrioritized.addAll(langsPrioritized)
      ..barcode = offProduct.barcode
      ..veganStatus = VegStatus.safeValueOf(backendProduct?.veganStatus ?? '')
      ..veganStatusSource =
          VegStatusSource.safeValueOf(backendProduct?.veganStatusSource ?? '')
      ..moderatorVeganChoiceReasonsIds = ListBuilder(
          _parseModeratorVeganChoiceReasonsIDs(
              backendProduct?.moderatorVeganChoiceReasons))
      ..moderatorVeganSourcesText = backendProduct?.moderatorVeganSourcesText
      ..likesCount = backendProduct?.likesCount ?? 0
      ..likedByMe = backendProduct?.likedByMe ?? false
      ..brands.addAll(offProduct.brandsTags ?? const [])
      ..nameLangs =
          _castOffLangs(offProduct.productNameInLanguages, _convertOffStr)
      ..ingredientsTextLangs =
          _castOffLangs(offProduct.ingredientsTextInLanguages, _convertOffStr)
      ..imageFrontLangs = _extractImagesUris(
          offProduct, off.ImageField.FRONT, off.ImageSize.DISPLAY)
      ..imageFrontThumbLangs = _extractImagesUris(
          offProduct, off.ImageField.FRONT, off.ImageSize.SMALL)
      ..imageIngredientsLangs = _extractImagesUris(
          offProduct, off.ImageField.INGREDIENTS, off.ImageSize.DISPLAY)
      ..ingredientsAnalyzedLangs = _extractIngredientsAnalyzed(offProduct));

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
    if (result.veganStatus == null) {
      if (result.veganStatusAnalysis != null) {
        result = result.rebuild((v) => v
          ..veganStatus = result.veganStatusAnalysis
          ..veganStatusSource = VegStatusSource.open_food_facts);
      }
    }

    // First store the original product into cache
    _productsCache[offProduct.barcode!] = result;

    return _filterOutNotTranslatedValues(result);
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

  MapBuilder<LangCode, Uri> _extractImagesUris(
      off.Product offProduct, off.ImageField imageType, off.ImageSize size) {
    final result = MapBuilder<LangCode, Uri>();

    final images = offProduct.selectedImages;
    if (images == null) {
      return result;
    }
    for (final image in images) {
      final lang = LangCode.safeValueOf(image.language?.code ?? '');
      if (lang == null || image.url == null) {
        continue;
      }
      if (imageType == image.field && size == image.size) {
        result[lang] = Uri.parse(image.url!);
      }
    }

    return result;
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
          _analytics.sendEvent('failure_off_ingredients_tags_breaking_change');
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
          ..veganStatus = offIngredient.vegan.convert()));
      }
    }

    final resultConverted = MapBuilder<LangCode, BuiltList<Ingredient>>();
    for (final entry in result.entries) {
      resultConverted[entry.key] = BuiltList.from(entry.value);
    }
    return resultConverted;
  }

  Product _filterOutNotTranslatedValues(Product result) {
    if (result.brands != null) {
      final brandsFiltered =
          result.brands!.where((e) => !_notTranslatedRegex.hasMatch(e));
      result = result.rebuild((v) => v.brands.replace(brandsFiltered));
    }
    return result;
  }

  Product? getCached(String barcode) {
    final result = _productsCache[barcode];
    if (result == null) {
      return null;
    }
    return _filterOutNotTranslatedValues(result);
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
        productNameInLanguages: _castToOffLangs(product.nameLangs, (e) => e),
        brands: _joinAndMaybeAddLangCode(product.brands, null),
        ingredientsTextInLanguages:
            _castToOffLangs(product.ingredientsTextLangs, (e) => e));

    if (cachedProduct == null) {
      // Product is being create for the first time
      offProduct.lang = off.LanguageHelper.fromJson(product.mainLang.name);
      offProduct.productName = product.name;
      offProduct.ingredientsText = product.ingredientsText;
    }

    return offProduct;
  }

  List<int> _parseModeratorVeganChoiceReasonsIDs(String? str) {
    if (str == null) {
      return const [];
    }
    final idsStrs = str.split(',');
    final ids = <int>[];
    for (final idStr in idsStrs) {
      final id = int.tryParse(idStr);
      if (id == null) {
        Log.w('_parseModeratorVeganChoiceReasonsIDs: invalid IDs str: $str');
        continue;
      }
      ids.add(id);
    }
    return ids;
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
