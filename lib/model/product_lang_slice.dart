import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';
import 'package:plante/base/base.dart';
import 'package:plante/base/build_value_helper.dart';
import 'package:plante/logging/log.dart';
import 'package:plante/model/ingredient.dart';
import 'package:plante/model/lang_code.dart';
import 'package:plante/model/product.dart';
import 'package:plante/model/veg_status.dart';
import 'package:plante/model/veg_status_source.dart';

part 'product_lang_slice.g.dart';

/// Slice of a [Product] object for a specific language.
abstract class ProductLangSlice
    implements Built<ProductLangSlice, ProductLangSliceBuilder> {
  static final ProductLangSlice empty = ProductLangSlice((e) => e
    ..barcode = ''
    ..lang = LangCode.en);

  LangCode? get lang;
  String get barcode;
  VegStatus? get veganStatus;
  VegStatusSource? get veganStatusSource;

  int? get moderatorVeganChoiceReasonId;
  String? get moderatorVeganSourcesText;

  BuiltList<String>? get brands;
  String? get name;
  String? get ingredientsText;
  BuiltList<Ingredient> get ingredientsAnalyzed;
  Uri? get imageFront;
  Uri? get imageFrontThumb;
  Uri? get imageIngredients;

  factory ProductLangSlice([void Function(ProductLangSliceBuilder) updates]) =
      _$ProductLangSlice;
  ProductLangSlice._();
  static Serializer<ProductLangSlice> get serializer =>
      _$productLangSliceSerializer;

  static ProductLangSlice? fromJson(Map<dynamic, dynamic> json) {
    return BuildValueHelper.jsonSerializers.deserializeWith(serializer, json);
  }

  Map<String, dynamic> toJson() {
    return BuildValueHelper.jsonSerializers.serializeWith(serializer, this)!
        as Map<String, dynamic>;
  }

  factory ProductLangSlice.from(Product product, LangCode lang) {
    return ProductLangSlice((e) => e
      ..lang = lang
      ..barcode = product.barcode
      ..veganStatus = product.veganStatus
      ..veganStatusSource = product.veganStatusSource
      ..moderatorVeganChoiceReasonId = product.moderatorVeganChoiceReasonId
      ..moderatorVeganSourcesText = product.moderatorVeganSourcesText
      ..brands = product.brands?.toBuilder()
      ..name = product.nameLangs[lang]
      ..ingredientsText = product.ingredientsTextLangs[lang]
      ..ingredientsAnalyzed =
          product.ingredientsAnalyzedLangs[lang]?.toBuilder()
      ..imageFront = product.imageFrontLangs[lang]
      ..imageFrontThumb = product.imageFrontThumbLangs[lang]
      ..imageIngredients = product.imageIngredientsLangs[lang]);
  }

  /// Please use this functions with great care - most of the products must
  /// be multilingual and erasing their langs might break everything.
  Product buildSingleLangProduct() {
    final lang = this.lang!;

    return Product((e) => e
      ..langsPrioritized.add(lang)
      ..barcode = barcode
      ..veganStatus = veganStatus
      ..veganStatusSource = veganStatusSource
      ..moderatorVeganChoiceReasonId = moderatorVeganChoiceReasonId
      ..moderatorVeganSourcesText = moderatorVeganSourcesText
      ..brands = brands != null ? ListBuilder(brands!) : null
      ..nameLangs.addAll(_valToMap(name, lang))
      ..ingredientsTextLangs.addAll(_valToMap(ingredientsText, lang))
      ..ingredientsAnalyzedLangs.addAll(_valToMap(ingredientsAnalyzed, lang))
      ..imageFrontLangs.addAll(_valToMap(imageFront, lang))
      ..imageFrontThumbLangs.addAll(_valToMap(imageFrontThumb, lang))
      ..imageIngredientsLangs.addAll(_valToMap(imageIngredients, lang)));
  }

  Product productForTests() {
    if (!isInTests()) {
      throw Exception('Only supported for tests');
    }
    final ProductLangSlice convertedVal;
    if (lang != null) {
      convertedVal = this;
    } else {
      convertedVal = rebuild((e) => e.lang = LangCode.en);
    }
    return convertedVal.buildSingleLangProduct();
  }

  ProductLangSlice rebuildWithImage(ProductImageType imageType, Uri? uri) {
    return buildSingleLangProduct()
        .rebuildWithImage(imageType, uri, lang!)
        .sliceFor(lang!);
  }
}

extension ProductExtensionForSlice on Product {
  /// Rebuilds the product with data from the provided slice.
  ///
  /// Note that [barcode] **is not** updated and
  /// the function will throw if barcodes don't match.
  ///
  /// All not multilingual fields of the [Product] will be overwritten with
  /// data from [slice].
  /// All specific lang data of the [Product] will be overwritten with
  /// data from [slice].
  Product updateWith(ProductLangSlice slice) {
    final lang = slice.lang;
    if (lang == null) {
      Log.e('ProductExtensionForSlice.updateWith called without a lang. '
          'slice: $slice');
      return this;
    }
    if (slice.barcode != barcode) {
      Log.e('ProductExtensionForSlice.updateWith barcodes are different. '
          'slice: $slice, this: $this');
      return this;
    }
    var result = this;
    if (!langsPrioritized.contains(lang)) {
      result = result.rebuild((e) => e.langsPrioritized.add(lang));
    }
    return result.rebuild((e) => e
      ..veganStatus = slice.veganStatus
      ..veganStatusSource = slice.veganStatusSource
      ..moderatorVeganChoiceReasonId = slice.moderatorVeganChoiceReasonId
      ..moderatorVeganSourcesText = slice.moderatorVeganSourcesText
      ..brands = slice.brands != null ? ListBuilder(slice.brands!) : null
      ..nameLangs = _updateMapBuilder(e.nameLangs, slice.name, lang)
      ..ingredientsTextLangs =
          _updateMapBuilder(e.ingredientsTextLangs, slice.ingredientsText, lang)
      ..ingredientsAnalyzedLangs = _updateMapBuilder(
          e.ingredientsAnalyzedLangs, slice.ingredientsAnalyzed, lang)
      ..imageFrontLangs =
          _updateMapBuilder(e.imageFrontLangs, slice.imageFront, lang)
      ..imageFrontThumbLangs =
          _updateMapBuilder(e.imageFrontThumbLangs, slice.imageFrontThumb, lang)
      ..imageIngredientsLangs = _updateMapBuilder(
          e.imageIngredientsLangs, slice.imageIngredients, lang));
  }

  ProductLangSlice sliceFor(LangCode lang) {
    return ProductLangSlice.from(this, lang);
  }
}

Map<LangCode, T> _valToMap<T>(T? val, LangCode lang) {
  if (val == null || (val is Iterable && val.isEmpty)) {
    return {};
  } else {
    return {lang: val};
  }
}

MapBuilder<LangCode, T> _updateMapBuilder<T>(
    MapBuilder<LangCode, T> builder, T? val, LangCode code) {
  final result = MapBuilder<LangCode, T>(builder.build());
  if (val == null || (val is Iterable && val.isEmpty)) {
    result.remove(code);
  } else {
    result[code] = val;
  }
  return result;
}
