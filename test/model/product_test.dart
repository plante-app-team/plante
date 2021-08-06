import 'package:plante/model/lang_code.dart';
import 'package:plante/model/product_lang_slice.dart';
import 'package:test/test.dart';
import 'package:plante/model/ingredient.dart';
import 'package:plante/model/product.dart';
import 'package:plante/model/veg_status.dart';

void main() {
  setUp(() {});

  test('veg statuses when analysis not available', () async {
    final productWithNull = ProductLangSlice((v) => v
      ..barcode = '123'
      ..ingredientsAnalyzed = null).productForTests();
    expect(productWithNull.vegetarianStatusAnalysis, isNull);
    expect(productWithNull.veganStatusAnalysis, isNull);

    final productWithEmptyAnalysis = ProductLangSlice((v) => v
      ..barcode = '123'
      ..ingredientsAnalyzed.addAll([])).productForTests();
    expect(productWithEmptyAnalysis.vegetarianStatusAnalysis, isNull);
    expect(productWithEmptyAnalysis.veganStatusAnalysis, isNull);
  });

  test('vegetarian status positive', () async {
    final productWithNull = ProductLangSlice((v) => v
      ..barcode = '123'
      ..ingredientsAnalyzed.addAll([
        Ingredient((v) => v
          ..name = 'ingr1'
          ..vegetarianStatus = VegStatus.positive),
        Ingredient((v) => v
          ..name = 'ingr2'
          ..vegetarianStatus = VegStatus.positive),
        Ingredient((v) => v
          ..name = 'ingr2'
          ..vegetarianStatus = VegStatus.positive)
      ])).productForTests();
    expect(productWithNull.vegetarianStatusAnalysis, VegStatus.positive);
    // Expected positive, because all vegan statuses are null -> vegan statuses
    // are not applicable.
    expect(productWithNull.veganStatusAnalysis, VegStatus.positive);
  });

  test('vegetarian status possible', () async {
    final productWithNull = ProductLangSlice((v) => v
      ..barcode = '123'
      ..ingredientsAnalyzed.addAll([
        Ingredient((v) => v
          ..name = 'ingr1'
          ..vegetarianStatus = VegStatus.possible),
        Ingredient((v) => v
          ..name = 'ingr2'
          ..vegetarianStatus = VegStatus.positive),
        Ingredient((v) => v
          ..name = 'ingr2'
          ..vegetarianStatus = VegStatus.positive)
      ])).productForTests();
    expect(productWithNull.vegetarianStatusAnalysis, VegStatus.possible);
    // Expected positive, because all vegan statuses are null -> vegan statuses
    // are not applicable.
    expect(productWithNull.veganStatusAnalysis, VegStatus.positive);
  });

  test('vegetarian status unknown', () async {
    final productWithNull = ProductLangSlice((v) => v
      ..barcode = '123'
      ..ingredientsAnalyzed.addAll([
        Ingredient((v) => v
          ..name = 'ingr1'
          ..vegetarianStatus = VegStatus.possible),
        Ingredient((v) => v
          ..name = 'ingr2'
          ..vegetarianStatus = VegStatus.unknown),
        Ingredient((v) => v
          ..name = 'ingr2'
          ..vegetarianStatus = VegStatus.positive)
      ])).productForTests();
    expect(productWithNull.vegetarianStatusAnalysis, VegStatus.unknown);
    // Expected positive, because all vegan statuses are null -> vegan statuses
    // are not applicable.
    expect(productWithNull.veganStatusAnalysis, VegStatus.positive);
  });

  test('vegetarian status negative', () async {
    final productWithNull = ProductLangSlice((v) => v
      ..barcode = '123'
      ..ingredientsAnalyzed.addAll([
        Ingredient((v) => v
          ..name = 'ingr1'
          ..vegetarianStatus = VegStatus.negative),
        Ingredient((v) => v
          ..name = 'ingr2'
          ..vegetarianStatus = VegStatus.unknown),
        Ingredient((v) => v
          ..name = 'ingr2'
          ..vegetarianStatus = VegStatus.positive)
      ])).productForTests();
    expect(productWithNull.vegetarianStatusAnalysis, VegStatus.negative);
    // Expected positive, because all vegan statuses are null -> vegan statuses
    // are not applicable.
    expect(productWithNull.veganStatusAnalysis, VegStatus.positive);
  });

  test('vegan status positive', () async {
    final productWithNull = ProductLangSlice((v) => v
      ..barcode = '123'
      ..ingredientsAnalyzed.addAll([
        Ingredient((v) => v
          ..name = 'ingr1'
          ..veganStatus = VegStatus.positive),
        Ingredient((v) => v
          ..name = 'ingr2'
          ..veganStatus = VegStatus.positive),
        Ingredient((v) => v
          ..name = 'ingr2'
          ..veganStatus = VegStatus.positive)
      ])).productForTests();
    expect(productWithNull.veganStatusAnalysis, VegStatus.positive);
    // Expected positive, because all vegetarian statuses are null ->
    // vegetarian statuses are not applicable.
    expect(productWithNull.vegetarianStatusAnalysis, VegStatus.positive);
  });

  test('vegan status possible', () async {
    final productWithNull = ProductLangSlice((v) => v
      ..barcode = '123'
      ..ingredientsAnalyzed.addAll([
        Ingredient((v) => v
          ..name = 'ingr1'
          ..veganStatus = VegStatus.positive),
        Ingredient((v) => v
          ..name = 'ingr2'
          ..veganStatus = VegStatus.possible),
        Ingredient((v) => v
          ..name = 'ingr2'
          ..veganStatus = VegStatus.positive)
      ])).productForTests();
    expect(productWithNull.veganStatusAnalysis, VegStatus.possible);
    // Expected positive, because all vegetarian statuses are null ->
    // vegetarian statuses are not applicable.
    expect(productWithNull.vegetarianStatusAnalysis, VegStatus.positive);
  });

  test('vegan status unknown', () async {
    final productWithNull = ProductLangSlice((v) => v
      ..barcode = '123'
      ..ingredientsAnalyzed.addAll([
        Ingredient((v) => v
          ..name = 'ingr1'
          ..veganStatus = VegStatus.positive),
        Ingredient((v) => v
          ..name = 'ingr2'
          ..veganStatus = VegStatus.possible),
        Ingredient((v) => v
          ..name = 'ingr2'
          ..veganStatus = VegStatus.unknown)
      ])).productForTests();
    expect(productWithNull.veganStatusAnalysis, VegStatus.unknown);
    // Expected positive, because all vegetarian statuses are null ->
    // vegetarian statuses are not applicable.
    expect(productWithNull.vegetarianStatusAnalysis, VegStatus.positive);
  });

  test('vegan status negative', () async {
    final productWithNull = ProductLangSlice((v) => v
      ..barcode = '123'
      ..ingredientsAnalyzed.addAll([
        Ingredient((v) => v
          ..name = 'ingr1'
          ..veganStatus = VegStatus.negative),
        Ingredient((v) => v
          ..name = 'ingr2'
          ..veganStatus = VegStatus.possible),
        Ingredient((v) => v
          ..name = 'ingr2'
          ..veganStatus = VegStatus.unknown)
      ])).productForTests();
    expect(productWithNull.veganStatusAnalysis, VegStatus.negative);
    // Expected positive, because all vegetarian statuses are null ->
    // vegetarian statuses are not applicable.
    expect(productWithNull.vegetarianStatusAnalysis, VegStatus.positive);
  });

  test('lang-fields when values of langsPrioritized field are available',
      () async {
    var product = Product((e) => e
      ..barcode = '123'
      ..langsPrioritized.addAll([LangCode.ru, LangCode.en])
      ..nameLangs.addAll({
        LangCode.en: 'Pancakes',
        LangCode.ru: 'Blinchiki',
      })
      ..ingredientsTextLangs.addAll({
        LangCode.en: 'Dough',
        LangCode.ru: 'Testo',
      })
      ..imageFrontLangs.addAll({
        LangCode.en: Uri.parse('/tmp/f1_front'),
        LangCode.ru: Uri.parse('/tmp/f2_front'),
      })
      ..imageFrontThumbLangs.addAll({
        LangCode.en: Uri.parse('/tmp/f1_front_thumb'),
        LangCode.ru: Uri.parse('/tmp/f2_front_thumb'),
      })
      ..imageIngredientsLangs.addAll({
        LangCode.en: Uri.parse('/tmp/f1_ingredients'),
        LangCode.ru: Uri.parse('/tmp/f2_ingredients'),
      }));

    expect(product.name, equals('Blinchiki'));
    expect(product.ingredientsText, equals('Testo'));
    expect(product.imageFront.toString(), equals('/tmp/f2_front'));
    expect(product.imageFrontThumb.toString(), equals('/tmp/f2_front_thumb'));
    expect(product.imageIngredients.toString(), equals('/tmp/f2_ingredients'));
    expect(product.firstImageUri(ProductImageType.FRONT).toString(),
        equals('/tmp/f2_front'));
    expect(product.firstImageUri(ProductImageType.FRONT_THUMB).toString(),
        equals('/tmp/f2_front_thumb'));
    expect(product.firstImageUri(ProductImageType.INGREDIENTS).toString(),
        equals('/tmp/f2_ingredients'));

    product = product
        .rebuild((e) => e.langsPrioritized.replace([LangCode.en, LangCode.ru]));
    expect(product.name, equals('Pancakes'));
    expect(product.ingredientsText, equals('Dough'));
    expect(product.imageFront.toString(), equals('/tmp/f1_front'));
    expect(product.imageFrontThumb.toString(), equals('/tmp/f1_front_thumb'));
    expect(product.imageIngredients.toString(), equals('/tmp/f1_ingredients'));
    expect(product.firstImageUri(ProductImageType.FRONT).toString(),
        equals('/tmp/f1_front'));
    expect(product.firstImageUri(ProductImageType.FRONT_THUMB).toString(),
        equals('/tmp/f1_front_thumb'));
    expect(product.firstImageUri(ProductImageType.INGREDIENTS).toString(),
        equals('/tmp/f1_ingredients'));
  });

  test('lang-fields when values of langsPrioritized field are NOT available',
      () async {
    final product = Product((e) => e
      ..barcode = '123'
      ..langsPrioritized.addAll([LangCode.de, LangCode.nl])
      ..nameLangs.addAll({
        LangCode.en: 'Pancakes',
      })
      ..ingredientsTextLangs.addAll({
        LangCode.en: 'Dough',
      })
      ..imageFrontLangs.addAll({
        LangCode.en: Uri.parse('/tmp/f1_front'),
      })
      ..imageFrontThumbLangs.addAll({
        LangCode.en: Uri.parse('/tmp/f1_front_thumb'),
      })
      ..imageIngredientsLangs.addAll({
        LangCode.en: Uri.parse('/tmp/f1_ingredients'),
      }));

    expect(product.name, equals('Pancakes'));
    expect(product.ingredientsText, equals('Dough'));
    expect(product.imageFront.toString(), equals('/tmp/f1_front'));
    expect(product.imageFrontThumb.toString(), equals('/tmp/f1_front_thumb'));
    expect(product.imageIngredients.toString(), equals('/tmp/f1_ingredients'));
    expect(product.firstImageUri(ProductImageType.FRONT).toString(),
        equals('/tmp/f1_front'));
    expect(product.firstImageUri(ProductImageType.FRONT_THUMB).toString(),
        equals('/tmp/f1_front_thumb'));
    expect(product.firstImageUri(ProductImageType.INGREDIENTS).toString(),
        equals('/tmp/f1_ingredients'));
  });

  test('text lang-fields when with empty values', () async {
    var product = Product((e) => e
      ..barcode = '123'
      ..langsPrioritized.addAll([LangCode.ru, LangCode.en])
      ..nameLangs.addAll({
        LangCode.en: 'Pancakes',
        LangCode.ru: ' ',
      })
      ..ingredientsTextLangs.addAll({
        LangCode.en: 'Dough',
        LangCode.ru: ' ',
      }));

    // RU is of the topmost priority, but RU values are empty
    // so they are not used
    expect(product.name, equals('Pancakes'));
    expect(product.ingredientsText, equals('Dough'));

    // Let's verify the RU value would've been used if they were non-null.
    product = product.rebuild((e) => e
      ..nameLangs[LangCode.ru] = 'Blinchiki'
      ..ingredientsTextLangs[LangCode.ru] = 'Testo');
    expect(product.name, equals('Blinchiki'));
    expect(product.ingredientsText, equals('Testo'));
  });
}
