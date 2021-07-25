import 'package:built_collection/built_collection.dart';
import 'package:plante/model/lang_code.dart';
import 'package:plante/model/product_lang_slice.dart';
import 'package:plante/model/veg_status_source.dart';
import 'package:test/test.dart';
import 'package:plante/model/ingredient.dart';
import 'package:plante/model/product.dart';
import 'package:plante/model/veg_status.dart';

void main() {
  setUp(() {
  });

  test('update product with a slice', () async {
    // A HUUGE product
    final initProduct = Product((v) => v
      ..barcode = '123'
      ..vegetarianStatus = VegStatus.positive
      ..vegetarianStatusSource = VegStatusSource.open_food_facts
      ..veganStatus = VegStatus.possible
      ..veganStatusSource = VegStatusSource.open_food_facts
      ..langsPrioritized.addAll([LangCode.ru, LangCode.de])
      ..nameLangs.addAll({LangCode.ru: 'name ru', LangCode.de: 'name de'})
      ..brands.add('Brand name')
      ..ingredientsTextLangs.addAll({LangCode.ru: 'voda', LangCode.de: 'wasser'})
      ..ingredientsAnalyzedLangs.addAll({
        LangCode.ru: BuiltList<Ingredient>([Ingredient((v) => v
          ..name = 'voda'
          ..vegetarianStatus = VegStatus.positive
          ..veganStatus = VegStatus.possible)]),
        LangCode.de: BuiltList<Ingredient>([Ingredient((v) => v
          ..name = 'wasser'
          ..vegetarianStatus = VegStatus.positive
          ..veganStatus = VegStatus.possible)]),
      })
      ..imageFrontLangs.addAll({
        LangCode.ru: Uri.file('/tmp/file1.jpg'),
        LangCode.de: Uri.file('/tmp/file1.jpg'),
      })
      ..imageFrontThumbLangs.addAll({
        LangCode.ru: Uri.file('/tmp/file1.jpg'),
        LangCode.de: Uri.file('/tmp/file1.jpg'),
      })
      ..imageIngredientsLangs.addAll({
        LangCode.ru: Uri.file('/tmp/file1.jpg'),
        LangCode.de: Uri.file('/tmp/file1.jpg'),
      }));

    // Make a Russian slice then change a couple of things
    var slice1 = initProduct.sliceFor(LangCode.ru);
    slice1 = slice1.rebuild((e) => e
      ..vegetarianStatus = VegStatus.negative
      ..vegetarianStatusSource = VegStatusSource.community
      ..veganStatus = VegStatus.negative
      ..veganStatusSource = VegStatusSource.community
      ..name = 'name2 ru'
      ..brands.replace(['Brand name 2'])
      ..ingredientsText = 'voda 2'
      ..ingredientsAnalyzed.replace([Ingredient((v) => v
        ..name = 'voda2'
        ..vegetarianStatus = VegStatus.positive
        ..veganStatus = VegStatus.possible)])
      ..imageFront = Uri.file('/tmp/file2.jpg')
      ..imageFrontThumb = Uri.file('/tmp/file2.jpg')
      ..imageIngredients = Uri.file('/tmp/file2.jpg')
    );

    // Make a German slice then change a couple of things
    var slice2 = initProduct.sliceFor(LangCode.de);
    slice2 = slice2.rebuild((e) => e
      ..vegetarianStatus = VegStatus.positive
      ..vegetarianStatusSource = VegStatusSource.moderator
      ..veganStatus = VegStatus.positive
      ..veganStatusSource = VegStatusSource.moderator
      ..name = 'name2 de'
      ..ingredientsText = null
      ..ingredientsAnalyzed.replace([Ingredient((v) => v
        ..name = 'super wasser'
        ..vegetarianStatus = VegStatus.positive
        ..veganStatus = VegStatus.possible)])
      ..imageFront = Uri.file('/tmp/file3.jpg')
      ..imageFrontThumb = null
    );

    // Create a new Netherlands slice
    final slice3 = ProductLangSlice((e) => e
      ..barcode = '123'
      ..lang = LangCode.nl
      ..vegetarianStatus = VegStatus.positive
      ..vegetarianStatusSource = VegStatusSource.moderator
      ..veganStatus = VegStatus.negative
      ..veganStatusSource = VegStatusSource.moderator
      ..brands.add('Super brand NL')
      ..name = 'nl name'
      ..imageIngredients = Uri.file('/tmp/file4.jpg'));

    // Apply all the slices!
    final finalProduct = initProduct.updateWith(slice1).updateWith(slice2).updateWith(slice3);

    final expectedFinalProduct = Product((v) => v
      ..barcode = '123'
      // Veg statuses expected to be of the last slice
      ..vegetarianStatus = VegStatus.positive
      ..vegetarianStatusSource = VegStatusSource.moderator
      ..veganStatus = VegStatus.negative
      ..veganStatusSource = VegStatusSource.moderator
      // Brands expected to be of the last slice
      ..brands.add('Super brand NL')
      // A new lang is expected to be added
      ..langsPrioritized.addAll([LangCode.ru, LangCode.de, LangCode.nl])
      // Multilingual fields expected to be updated
      ..nameLangs.addAll({
        LangCode.ru: 'name2 ru',
        LangCode.de: 'name2 de',
        LangCode.nl: 'nl name'})
      ..ingredientsTextLangs.addAll({LangCode.ru: 'voda 2'})
      ..ingredientsAnalyzedLangs.addAll({
        LangCode.ru: BuiltList<Ingredient>([Ingredient((v) => v
          ..name = 'voda2'
          ..vegetarianStatus = VegStatus.positive
          ..veganStatus = VegStatus.possible)]),
        LangCode.de: BuiltList<Ingredient>([Ingredient((v) => v
          ..name = 'super wasser'
          ..vegetarianStatus = VegStatus.positive
          ..veganStatus = VegStatus.possible)]),
      })
      ..imageFrontLangs.addAll({
        LangCode.ru: Uri.file('/tmp/file2.jpg'),
        LangCode.de: Uri.file('/tmp/file3.jpg'),
      })
      ..imageFrontThumbLangs.addAll({
        LangCode.ru: Uri.file('/tmp/file2.jpg'),
      })
      ..imageIngredientsLangs.addAll({
        LangCode.ru: Uri.file('/tmp/file2.jpg'),
        LangCode.de: Uri.file('/tmp/file1.jpg'),
        LangCode.nl: Uri.file('/tmp/file4.jpg'),
      }));

    expect(finalProduct, equals(expectedFinalProduct));
  });
}
