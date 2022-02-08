import 'dart:convert';

import 'package:built_collection/built_collection.dart';
import 'package:mockito/mockito.dart';
import 'package:openfoodfacts/openfoodfacts.dart' as off;
import 'package:plante/base/result.dart';
import 'package:plante/model/ingredient.dart';
import 'package:plante/model/lang_code.dart';
import 'package:plante/model/product.dart';
import 'package:plante/model/product_lang_slice.dart';
import 'package:plante/model/veg_status.dart';
import 'package:plante/model/veg_status_source.dart';
import 'package:plante/outside/backend/backend_error.dart';
import 'package:plante/outside/backend/backend_product.dart';
import 'package:plante/outside/products/products_manager.dart';
import 'package:test/test.dart';

import '../../common_mocks.mocks.dart';
import '../off/off_json_product_images_utils.dart';
import 'products_manager_tests_commons.dart';

void main() {
  late ProductsManagerTestCommons commons;
  late MockOffApi offApi;
  late MockBackend backend;
  late ProductsManager productsManager;

  setUp(() async {
    commons = await ProductsManagerTestCommons.create();
    offApi = commons.offApi;
    backend = commons.backend;
    productsManager = commons.productsManager;
  });

  void setUpOffProducts(List<off.Product> products) {
    commons.setUpOffProducts(products);
  }

  void setUpBackendProducts(
      Result<List<BackendProduct>, BackendError> productsRes) {
    commons.setUpBackendProducts(productsRes);
  }

  void ensureProductIsInOFF(Product product) {
    commons.ensureProductIsInOFF(product);
  }

  test('international OFF product fields are not used', () async {
    final offProduct = off.Product.fromJson({
      'code': '123',
      'product_name': 'name',
      'ingredients_text': 'lemon, water'
    });
    setUpOffProducts([offProduct]);

    setUpBackendProducts(Ok(const []));

    final productRes = await productsManager.getProduct('123', [LangCode.ru]);
    final product = productRes.unwrap();
    final expectedProduct = ProductLangSlice((v) => v
      ..lang = LangCode.ru
      ..barcode = '123'
      ..name = null
      ..brands.addAll([])
      ..ingredientsAnalyzed.addAll([])
      ..ingredientsText = null).productForTests();
    expect(product, equals(expectedProduct));
  });

  test('not translated OFF tags get and save behaviour', () async {
    final offProduct = off.Product.fromJson({
      'code': '123',
      'brands_tags': ['brand1', 'en:brand2'],
    });
    setUpOffProducts([offProduct]);

    setUpBackendProducts(Ok(const []));

    final productRes = await productsManager.getProduct('123', [LangCode.ru]);
    final product = productRes.unwrap();
    // We expect the 'en' values to be excluded
    final expectedInitialProduct = ProductLangSlice((v) => v
      ..lang = LangCode.ru
      ..barcode = '123'
      ..brands.addAll(['brand1'])
      ..ingredientsAnalyzed.addAll([])
      ..ingredientsText = null).productForTests();
    expect(product, equals(expectedInitialProduct));

    final updatedProduct = product!.rebuild((v) => v..brands.add('brand3'));
    await productsManager.createUpdateProduct(updatedProduct);

    final capturedOffProduct = verify(offApi.saveProduct(any, captureAny))
        .captured
        .first as off.Product;
    // We expected the 'en' value to be included back
    expect(capturedOffProduct.brands, equals('brand1, brand3, en:brand2'));
  });

  test('translated OFF tags order on re-save does not matter', () async {
    final offProduct1 = off.Product.fromJson({
      'code': '123',
      'brands_tags': ['brand1', 'en:brand2'],
    });
    setUpOffProducts([offProduct1]);
    setUpBackendProducts(Ok(const []));

    final productRes = await productsManager.getProduct('123', [LangCode.ru]);
    final product = productRes.unwrap();

    // Order 1
    await productsManager.createUpdateProduct(
        product!.rebuild((v) => v..brands.addAll(['brand3', 'brand4'])));
    var capturedOffProduct = verify(offApi.saveProduct(any, captureAny))
        .captured
        .first as off.Product;
    expect(
        capturedOffProduct.brands, equals('brand1, brand3, brand4, en:brand2'));

    // Order 2, still expected same brands and products
    await productsManager.createUpdateProduct(
        product.rebuild((v) => v..brands.addAll(['brand4', 'brand3'])));
    capturedOffProduct = verify(offApi.saveProduct(any, captureAny))
        .captured
        .first as off.Product;
    expect(
        capturedOffProduct.brands, equals('brand1, brand3, brand4, en:brand2'));
  });

  Future<void> getProductWithMultipleLangsTest(
      List<LangCode> langsPrioritized) async {
    final offProduct = off.Product.fromJson({
      'code': '123',
      'product_name_ru': 'name ru',
      'product_name_de': 'name de',
      'brands_tags': ['Brand name'],
      'ingredients': [
        {
          'vegan': 'maybe',
          'vegetarian': 'yes',
          'text': 'water',
          'id': 'en:water',
        }
      ],
      'ingredients_tags': ['en:water'],
      'ingredients_text_ru': 'voda',
      'ingredients_tags_ru': ['voda'],
      'ingredients_text_de': 'wasser',
      'ingredients_tags_de': ['wasser'],
      'selected_images': jsonDecode(offSelectedImagesRuDeJson),
    });
    setUpOffProducts([offProduct]);

    setUpBackendProducts(Ok(const []));

    final productRes =
        await productsManager.getProduct('123', langsPrioritized);
    final product = productRes.unwrap();
    final expectedProduct = Product((v) => v
      ..barcode = '123'
      ..veganStatus = VegStatus.possible
      ..veganStatusSource = VegStatusSource.open_food_facts
      ..langsPrioritized.addAll(langsPrioritized)
      ..nameLangs.addAll({LangCode.ru: 'name ru', LangCode.de: 'name de'})
      ..brands.add('Brand name')
      ..ingredientsTextLangs
          .addAll({LangCode.ru: 'voda', LangCode.de: 'wasser'})
      ..ingredientsAnalyzedLangs.addAll({
        LangCode.ru: BuiltList<Ingredient>([
          Ingredient((v) => v
            ..name = 'voda'
            ..veganStatus = VegStatus.possible)
        ]),
        LangCode.de: BuiltList<Ingredient>([
          Ingredient((v) => v
            ..name = 'wasser'
            ..veganStatus = VegStatus.possible)
        ]),
      })
      ..imageFrontLangs.addAll({
        LangCode.ru: Uri.parse(offExpectedImageFrontRu),
        LangCode.de: Uri.parse(offExpectedImageFrontDe),
      })
      ..imageFrontThumbLangs.addAll({
        LangCode.ru: Uri.parse(offExpectedImageFrontThumbRu),
        LangCode.de: Uri.parse(offExpectedImageFrontThumbDe),
      })
      ..imageIngredientsLangs.addAll({
        LangCode.ru: Uri.parse(offExpectedImageIngredientsRu),
        LangCode.de: Uri.parse(offExpectedImageIngredientsDe),
      }));
    expect(product, equals(expectedProduct));
  }

  test('get product with multiple langs', () async {
    await getProductWithMultipleLangsTest([LangCode.ru, LangCode.de]);
  });

  test('get product with multiple langs but only 1 lang is specified',
      () async {
    await getProductWithMultipleLangsTest([LangCode.ru]);
  });

  test('save product with multiple languages', () async {
    final product = Product((v) => v
      ..barcode = '123'
      ..veganStatus = VegStatus.possible
      ..veganStatusSource = VegStatusSource.open_food_facts
      ..langsPrioritized.addAll([LangCode.ru, LangCode.de])
      ..nameLangs.addAll({LangCode.ru: 'name ru', LangCode.de: 'name de'})
      ..brands.add('Brand name')
      ..ingredientsTextLangs
          .addAll({LangCode.ru: 'voda', LangCode.de: 'wasser'})
      ..imageFrontLangs.addAll({
        LangCode.ru: Uri.file('/tmp/img1_ru.jpg'),
        LangCode.de: Uri.file('/tmp/img1_de.jpg'),
      })
      ..imageIngredientsLangs.addAll({
        LangCode.ru: Uri.file('/tmp/img2_ru.jpg'),
        LangCode.de: Uri.file('/tmp/img2_de.jpg'),
      }));
    ensureProductIsInOFF(product);

    final result = await productsManager.createUpdateProduct(product);
    expect(result.isOk, isTrue);

    // Verify changed lang
    verify(backend.createUpdateProduct('123',
        veganStatus: VegStatus.possible,
        changedLangs: [LangCode.ru, LangCode.de]));

    // Off Product
    final capturedOffProduct = verify(offApi.saveProduct(any, captureAny))
        .captured
        .first as off.Product;
    expect(capturedOffProduct.barcode, equals('123'));
    expect(
        capturedOffProduct.productNameInLanguages,
        equals({
          off.OpenFoodFactsLanguage.RUSSIAN: 'name ru',
          off.OpenFoodFactsLanguage.GERMAN: 'name de',
        }));
    expect(capturedOffProduct.brands, equals('Brand name'));
    expect(
        capturedOffProduct.ingredientsTextInLanguages,
        equals({
          off.OpenFoodFactsLanguage.RUSSIAN: 'voda',
          off.OpenFoodFactsLanguage.GERMAN: 'wasser',
        }));

    // Off image front - RU
    final allImages = verify(offApi.addProductImage(any, captureAny)).captured;
    final capturedImage1 = allImages[0] as off.SendImage;
    expect(capturedImage1.imageField, equals(off.ImageField.FRONT));
    expect(capturedImage1.imageUri, equals(Uri.file('/tmp/img1_ru.jpg')));
    expect(capturedImage1.barcode, equals('123'));
    expect(capturedImage1.lang, equals(off.OpenFoodFactsLanguage.RUSSIAN));

    // Off image front - DE
    final capturedImage2 = allImages[1] as off.SendImage;
    expect(capturedImage2.imageField, equals(off.ImageField.FRONT));
    expect(capturedImage2.imageUri, equals(Uri.file('/tmp/img1_de.jpg')));
    expect(capturedImage2.barcode, equals('123'));
    expect(capturedImage2.lang, equals(off.OpenFoodFactsLanguage.GERMAN));

    // Off image ingredients - RU
    final capturedImage3 = allImages[2] as off.SendImage;
    expect(capturedImage3.imageField, equals(off.ImageField.INGREDIENTS));
    expect(capturedImage3.imageUri, equals(Uri.file('/tmp/img2_ru.jpg')));
    expect(capturedImage3.barcode, equals('123'));
    expect(capturedImage3.lang, equals(off.OpenFoodFactsLanguage.RUSSIAN));

    // Off image ingredients - DE
    final capturedImage4 = allImages[3] as off.SendImage;
    expect(capturedImage4.imageField, equals(off.ImageField.INGREDIENTS));
    expect(capturedImage4.imageUri, equals(Uri.file('/tmp/img2_de.jpg')));
    expect(capturedImage4.barcode, equals('123'));
    expect(capturedImage4.lang, equals(off.OpenFoodFactsLanguage.GERMAN));
  });

  test(
      'changed langs list when changing 1 and adding 1 lang for a multilingual product',
      () async {
    const barcode = '123321';
    final offProduct = off.Product.fromJson({
      'code': barcode,
      'product_name_ru': 'banan',
      'ingredients_text_ru': 'banan, kojura',
      'product_name_de': 'banane',
      'ingredients_text_de': 'banane, schälen',
      'selected_images': jsonDecode(offSelectedImagesRuDeJson),
    });
    setUpOffProducts([offProduct]);
    setUpBackendProducts(Ok(const []));

    final originalProductRes =
        await productsManager.getProduct(barcode, [LangCode.ru, LangCode.de]);
    final originalProduct = originalProductRes.unwrap()!;

    // RU is untouched
    final updatedProduct = originalProduct.rebuild((e) => e
      ..veganStatus = VegStatus.possible
      ..langsPrioritized.add(LangCode.en)
      ..nameLangs[LangCode.en] = 'banana'
      ..ingredientsTextLangs[LangCode.de] = 'banane');

    final result = await productsManager.createUpdateProduct(updatedProduct);
    expect(result.isOk, isTrue);

    // Verify changed langs
    verify(backend.createUpdateProduct(barcode,
        veganStatus: VegStatus.possible,
        changedLangs: [LangCode.de, LangCode.en]));
  });

  test('changed langs list when not changing any lang params', () async {
    const barcode = '123321';
    final offProduct = off.Product.fromJson({
      'code': barcode,
      'product_name_ru': 'banan',
      'ingredients_text_ru': 'banan, kojura',
      'product_name_de': 'banane',
      'ingredients_text_de': 'banane, schälen',
      'selected_images': jsonDecode(offSelectedImagesRuDeJson),
    });
    setUpOffProducts([offProduct]);
    setUpBackendProducts(Ok(const []));

    final originalProductRes =
        await productsManager.getProduct(barcode, [LangCode.ru, LangCode.de]);
    final originalProduct = originalProductRes.unwrap()!;

    // All langs are untouched
    final updatedProduct =
        originalProduct.rebuild((e) => e..veganStatus = VegStatus.possible);

    final result = await productsManager.createUpdateProduct(updatedProduct);
    expect(result.isOk, isTrue);

    // Verify not changed langs
    verify(backend.createUpdateProduct(barcode,
        veganStatus: VegStatus.possible, changedLangs: []));
  });
}
