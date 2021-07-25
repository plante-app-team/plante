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
}
