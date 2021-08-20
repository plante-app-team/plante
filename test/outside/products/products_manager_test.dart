import 'dart:convert';
import 'dart:io';

import 'package:built_collection/built_collection.dart';
import 'package:openfoodfacts/model/OcrIngredientsResult.dart' as off;
import 'package:openfoodfacts/model/Product.dart' as off;
import 'package:openfoodfacts/openfoodfacts.dart' as off;

import 'package:mockito/mockito.dart';
import 'package:plante/model/lang_code.dart';
import 'package:plante/model/product_lang_slice.dart';
import 'package:plante/outside/products/taken_products_images_storage.dart';
import 'package:test/test.dart';
import 'package:plante/base/result.dart';
import 'package:plante/model/ingredient.dart';
import 'package:plante/model/product.dart';
import 'package:plante/model/veg_status.dart';
import 'package:plante/model/veg_status_source.dart';
import 'package:plante/outside/backend/backend_error.dart';
import 'package:plante/outside/backend/backend_product.dart';
import 'package:plante/outside/products/products_manager.dart';
import 'package:plante/outside/products/products_manager_error.dart';

import '../../common_mocks.mocks.dart';
import '../../z_fakes/fake_analytics.dart';

void main() {
  const expectedImageFrontRu =
      'https://static.openfoodfacts.org/images/products/123/front_ru.16.400.jpg';
  const expectedImageFrontThumbRu =
      'https://static.openfoodfacts.org/images/products/123/front_ru.16.200.jpg';
  const expectedImageIngredientsRu =
      'https://static.openfoodfacts.org/images/products/123/ingredients_ru.19.full.jpg';
  const expectedImageFrontDe =
      'https://static.openfoodfacts.org/images/products/123/front_de.16.400.jpg';
  const expectedImageFrontThumbDe =
      'https://static.openfoodfacts.org/images/products/123/front_de.16.200.jpg';
  const expectedImageIngredientsDe =
      'https://static.openfoodfacts.org/images/products/123/ingredients_de.19.full.jpg';
  const selectedImagesRuDeJson = '''
    {
       "front":{
          "display":{
             "ru":"$expectedImageFrontRu",
             "de":"$expectedImageFrontDe"
          },
          "small":{
             "ru":"$expectedImageFrontThumbRu",
             "de":"$expectedImageFrontThumbDe"
          }
       },
       "ingredients":{
          "display":{
             "ru":"$expectedImageIngredientsRu",
             "de":"$expectedImageIngredientsDe"
          }
       }
    }
  ''';
  const selectedImagesRuJson = '''
    {
       "front":{
          "display":{
             "ru":"$expectedImageFrontRu"
          },
          "small":{
             "ru":"$expectedImageFrontThumbRu"
          }
       },
       "ingredients":{
          "display":{
             "ru":"$expectedImageIngredientsRu"
          }
       }
    }
  ''';

  late MockOffApi offApi;
  late MockBackend backend;
  late TakenProductsImagesStorage takenProductsImagesStorage;
  late ProductsManager productsManager;

  setUp(() async {
    offApi = MockOffApi();
    backend = MockBackend();
    takenProductsImagesStorage = TakenProductsImagesStorage(
        fileName: 'products_manager_test_taken_images.json');
    await takenProductsImagesStorage.clearForTesting();

    productsManager = ProductsManager(
        offApi, backend, takenProductsImagesStorage, FakeAnalytics());

    when(offApi.saveProduct(any, any)).thenAnswer((_) async => off.Status());
    when(offApi.getProduct(any)).thenAnswer(
        (_) async => off.ProductResult(product: off.Product(barcode: '123')));
    when(offApi.addProductImage(any, any))
        .thenAnswer((_) async => off.Status());
    when(offApi.extractIngredients(any, any, any))
        .thenAnswer((_) async => const off.OcrIngredientsResult());

    when(backend.createUpdateProduct(any,
            vegetarianStatus: anyNamed('vegetarianStatus'),
            veganStatus: anyNamed('veganStatus'),
            changedLangs: anyNamed('changedLangs')))
        .thenAnswer((_) async => Ok(None()));
    when(backend.requestProduct(any)).thenAnswer((invc) async => Ok(
        BackendProduct(
            (v) => v.barcode = invc.positionalArguments[0] as String)));
  });

  void ensureProductIsInOFF(Product product) {
    final offProduct = off.Product.fromJson({
      'code': product.barcode,
      'product_name_ru': product.name,
      'brands_tags': product.brands?.toList() ?? [],
      'ingredients_text_ru': product.ingredientsText,
    });
    when(offApi.getProduct(any))
        .thenAnswer((_) async => off.ProductResult(product: offProduct));
    when(backend.requestProduct(any)).thenAnswer((_) async => Ok(null));
  }

  test('get product when the product is on both OFF and backend', () async {
    final offProduct = off.Product.fromJson({
      'code': '123',
      'product_name_ru': 'name',
      'brands_tags': ['Brand name'],
      'ingredients_text_ru': 'lemon, water',
      'selected_images': jsonDecode(selectedImagesRuJson),
    });
    when(offApi.getProduct(any))
        .thenAnswer((_) async => off.ProductResult(product: offProduct));

    final backendProduct = BackendProduct((v) => v
      ..barcode = '123'
      ..vegetarianStatus = VegStatus.positive.name
      ..vegetarianStatusSource = VegStatusSource.community.name
      ..veganStatus = VegStatus.negative.name
      ..veganStatusSource = VegStatusSource.moderator.name);
    when(backend.requestProduct(any))
        .thenAnswer((_) async => Ok(backendProduct));

    final productRes = await productsManager.getProduct('123', [LangCode.ru]);
    final product = productRes.unwrap();
    final expectedProduct = ProductLangSlice((v) => v
          ..lang = LangCode.ru
          ..barcode = '123'
          ..vegetarianStatus = VegStatus.positive
          ..vegetarianStatusSource = VegStatusSource.community
          ..veganStatus = VegStatus.negative
          ..veganStatusSource = VegStatusSource.moderator
          ..name = 'name'
          ..brands.add('Brand name')
          ..ingredientsText = 'lemon, water'
          ..imageFront = Uri.parse(expectedImageFrontRu)
          ..imageFrontThumb = Uri.parse(expectedImageFrontThumbRu)
          ..imageIngredients = Uri.parse(expectedImageIngredientsRu))
        .productForTests();
    expect(product, equals(expectedProduct));
  });

  test('get product when the product is on OFF only', () async {
    final offProduct = off.Product.fromJson({
      'code': '123',
      'product_name_ru': 'name',
      'brands_tags': ['Brand name'],
      'ingredients_text_ru': 'lemon, water',
      'selected_images': jsonDecode(selectedImagesRuJson),
    });
    when(offApi.getProduct(any))
        .thenAnswer((_) async => off.ProductResult(product: offProduct));

    when(backend.requestProduct(any)).thenAnswer((_) async => Ok(null));

    final productRes = await productsManager.getProduct('123', [LangCode.ru]);
    final product = productRes.unwrap();
    final expectedProduct = ProductLangSlice((v) => v
          ..lang = LangCode.ru
          ..barcode = '123'
          ..vegetarianStatus = null
          ..vegetarianStatusSource = null
          ..veganStatus = null
          ..veganStatusSource = null
          ..name = 'name'
          ..brands.add('Brand name')
          ..ingredientsText = 'lemon, water'
          ..ingredientsAnalyzed.addAll([])
          ..imageFront = Uri.parse(expectedImageFrontRu)
          ..imageFrontThumb = Uri.parse(expectedImageFrontThumbRu)
          ..imageIngredients = Uri.parse(expectedImageIngredientsRu))
        .productForTests();
    expect(product, equals(expectedProduct));
  });

  test('get product when the product is on backend only', () async {
    when(offApi.getProduct(any))
        .thenAnswer((_) async => const off.ProductResult(product: null));

    final backendProduct = BackendProduct((v) => v
      ..barcode = '123'
      ..vegetarianStatus = VegStatus.positive.name
      ..vegetarianStatusSource = VegStatusSource.community.name
      ..veganStatus = VegStatus.negative.name
      ..veganStatusSource = VegStatusSource.moderator.name);
    when(backend.requestProduct(any))
        .thenAnswer((_) async => Ok(backendProduct));

    final productRes = await productsManager.getProduct('123', [LangCode.ru]);
    final product = productRes.unwrap();
    expect(product, equals(null));
  });

  test('get product when OFF throws network error', () async {
    when(offApi.getProduct(any))
        .thenAnswer((_) async => throw const SocketException(''));

    final productRes = await productsManager.getProduct('123', [LangCode.ru]);
    expect(productRes.unwrapErr(), equals(ProductsManagerError.NETWORK_ERROR));
  });

  test('get product when backend returns network error', () async {
    final offProduct = off.Product.fromJson({
      'code': '123',
      'product_name_ru': 'name',
      'brands_tags': ['Brand name'],
      'ingredients_text_ru': 'lemon, water',
      'selected_images': jsonDecode(selectedImagesRuJson),
    });
    when(offApi.getProduct(any))
        .thenAnswer((_) async => off.ProductResult(product: offProduct));

    when(backend.requestProduct(any)).thenAnswer(
        (_) async => Err(BackendErrorKind.NETWORK_ERROR.toErrorForTesting()));

    final productRes = await productsManager.getProduct('123', [LangCode.ru]);
    expect(productRes.unwrapErr(), equals(ProductsManagerError.NETWORK_ERROR));
  });

  test('update product with both front and ingredients images', () async {
    final product = ProductLangSlice((v) => v
      ..lang = LangCode.ru
      ..barcode = '123'
      ..vegetarianStatus = VegStatus.positive
      ..vegetarianStatusSource = VegStatusSource.community
      ..veganStatus = VegStatus.negative
      ..veganStatusSource = VegStatusSource.moderator
      ..name = 'name'
      ..brands.add('Brand name')
      ..ingredientsText = 'lemon, water'
      ..imageFront = Uri.file('/tmp/img1.jpg')
      ..imageIngredients = Uri.file('/tmp/img2.jpg')).productForTests();
    ensureProductIsInOFF(product);

    verifyZeroInteractions(offApi);
    verifyZeroInteractions(backend);

    await productsManager.createUpdateProduct(product);

    // Off Product
    final capturedOffProduct = verify(offApi.saveProduct(any, captureAny))
        .captured
        .first as off.Product;
    expect(capturedOffProduct.barcode, equals('123'));
    expect(capturedOffProduct.lang, isNull);
    expect(capturedOffProduct.productName, isNull);
    expect(capturedOffProduct.productNameInLanguages,
        equals({off.OpenFoodFactsLanguage.RUSSIAN: 'name'}));
    expect(capturedOffProduct.brands, equals('Brand name'));
    expect(capturedOffProduct.ingredientsText, isNull);
    expect(capturedOffProduct.ingredientsTextInLanguages,
        equals({off.OpenFoodFactsLanguage.RUSSIAN: 'lemon, water'}));

    // Backend Product
    verify(backend.createUpdateProduct('123',
            vegetarianStatus: VegStatus.positive,
            veganStatus: VegStatus.negative,
            changedLangs: anyNamed('changedLangs')))
        .called(1);

    // Off image front
    final allImages = verify(offApi.addProductImage(any, captureAny)).captured;
    final capturedImage1 = allImages[0] as off.SendImage;
    expect(capturedImage1.imageField, equals(off.ImageField.FRONT));
    expect(capturedImage1.imageUri, equals(Uri.file('/tmp/img1.jpg')));
    expect(capturedImage1.barcode, equals('123'));
    expect(capturedImage1.lang, equals(off.OpenFoodFactsLanguage.RUSSIAN));

    // Off image ingredients
    final capturedImage2 = allImages[1] as off.SendImage;
    expect(capturedImage2.imageField, equals(off.ImageField.INGREDIENTS));
    expect(capturedImage2.imageUri, equals(Uri.file('/tmp/img2.jpg')));
    expect(capturedImage2.barcode, equals('123'));
    expect(capturedImage2.lang, equals(off.OpenFoodFactsLanguage.RUSSIAN));
  });

  test('update product without images', () async {
    final product = ProductLangSlice((v) => v
      ..lang = LangCode.ru
      ..barcode = '123'
      ..vegetarianStatus = VegStatus.positive
      ..vegetarianStatusSource = VegStatusSource.community
      ..veganStatus = VegStatus.negative
      ..veganStatusSource = VegStatusSource.moderator
      ..name = 'name'
      ..brands.add('Brand name')
      ..ingredientsText = 'lemon, water').productForTests();
    ensureProductIsInOFF(product);

    verifyZeroInteractions(offApi);
    verifyZeroInteractions(backend);

    await productsManager.createUpdateProduct(product);

    // Off Product
    final capturedOffProduct = verify(offApi.saveProduct(any, captureAny))
        .captured
        .first as off.Product;
    expect(capturedOffProduct.barcode, equals('123'));
    expect(capturedOffProduct.lang, isNull);
    expect(capturedOffProduct.productName, isNull);
    expect(capturedOffProduct.productNameInLanguages,
        equals({off.OpenFoodFactsLanguage.RUSSIAN: 'name'}));
    expect(capturedOffProduct.brands, equals('Brand name'));
    expect(capturedOffProduct.ingredientsText, isNull);
    expect(capturedOffProduct.ingredientsTextInLanguages,
        equals({off.OpenFoodFactsLanguage.RUSSIAN: 'lemon, water'}));

    // Backend Product
    verify(backend.createUpdateProduct('123',
            vegetarianStatus: VegStatus.positive,
            veganStatus: VegStatus.negative,
            changedLangs: anyNamed('changedLangs')))
        .called(1);

    verifyNever(offApi.addProductImage(any, captureAny));
  });

  test('update product with front image only', () async {
    final product = ProductLangSlice((v) => v
      ..lang = LangCode.ru
      ..barcode = '123'
      ..vegetarianStatus = VegStatus.positive
      ..vegetarianStatusSource = VegStatusSource.community
      ..veganStatus = VegStatus.negative
      ..veganStatusSource = VegStatusSource.moderator
      ..name = 'name'
      ..brands.add('Brand name')
      ..ingredientsText = 'lemon, water'
      ..imageFront = Uri.file('/tmp/img1.jpg')).productForTests();
    ensureProductIsInOFF(product);

    verifyZeroInteractions(offApi);
    verifyZeroInteractions(backend);

    await productsManager.createUpdateProduct(product);

    // Off Product
    final capturedOffProduct = verify(offApi.saveProduct(any, captureAny))
        .captured
        .first as off.Product;
    expect(capturedOffProduct.barcode, equals('123'));
    expect(capturedOffProduct.lang, isNull);
    expect(capturedOffProduct.productName, isNull);
    expect(capturedOffProduct.productNameInLanguages,
        equals({off.OpenFoodFactsLanguage.RUSSIAN: 'name'}));
    expect(capturedOffProduct.brands, equals('Brand name'));
    expect(capturedOffProduct.ingredientsText, isNull);
    expect(capturedOffProduct.ingredientsTextInLanguages,
        equals({off.OpenFoodFactsLanguage.RUSSIAN: 'lemon, water'}));

    // Backend Product
    verify(backend.createUpdateProduct('123',
            vegetarianStatus: VegStatus.positive,
            veganStatus: VegStatus.negative,
            changedLangs: anyNamed('changedLangs')))
        .called(1);

    // Off image front
    final allImages = verify(offApi.addProductImage(any, captureAny)).captured;
    final capturedImage = allImages[0] as off.SendImage;
    expect(capturedImage.imageField, equals(off.ImageField.FRONT));
    expect(capturedImage.imageUri, equals(Uri.file('/tmp/img1.jpg')));
    expect(capturedImage.barcode, equals('123'));
    expect(capturedImage.lang, equals(off.OpenFoodFactsLanguage.RUSSIAN));

    // Only 1 image
    expect(allImages.length, equals(1));
  });

  test('update product with ingredients image only', () async {
    final product = ProductLangSlice((v) => v
      ..lang = LangCode.ru
      ..barcode = '123'
      ..vegetarianStatus = VegStatus.positive
      ..vegetarianStatusSource = VegStatusSource.community
      ..veganStatus = VegStatus.negative
      ..veganStatusSource = VegStatusSource.moderator
      ..name = 'name'
      ..brands.add('Brand name')
      ..ingredientsText = 'lemon, water'
      ..imageIngredients = Uri.file('/tmp/img2.jpg')).productForTests();
    ensureProductIsInOFF(product);

    verifyZeroInteractions(offApi);
    verifyZeroInteractions(backend);

    await productsManager.createUpdateProduct(product);

    // Off Product
    final capturedOffProduct = verify(offApi.saveProduct(any, captureAny))
        .captured
        .first as off.Product;
    expect(capturedOffProduct.barcode, equals('123'));
    expect(capturedOffProduct.lang, isNull);
    expect(capturedOffProduct.productName, isNull);
    expect(capturedOffProduct.productNameInLanguages,
        equals({off.OpenFoodFactsLanguage.RUSSIAN: 'name'}));
    expect(capturedOffProduct.brands, equals('Brand name'));
    expect(capturedOffProduct.ingredientsText, isNull);
    expect(capturedOffProduct.ingredientsTextInLanguages,
        equals({off.OpenFoodFactsLanguage.RUSSIAN: 'lemon, water'}));

    // Backend Product
    verify(backend.createUpdateProduct('123',
            vegetarianStatus: VegStatus.positive,
            veganStatus: VegStatus.negative,
            changedLangs: anyNamed('changedLangs')))
        .called(1);

    // Off image ingredients
    final allImages = verify(offApi.addProductImage(any, captureAny)).captured;
    final capturedImage = allImages[0] as off.SendImage;
    expect(capturedImage.imageField, equals(off.ImageField.INGREDIENTS));
    expect(capturedImage.imageUri, equals(Uri.file('/tmp/img2.jpg')));
    expect(capturedImage.barcode, equals('123'));
    expect(capturedImage.lang, equals(off.OpenFoodFactsLanguage.RUSSIAN));

    // Only 1 image
    expect(allImages.length, equals(1));
  });

  test('update product OFF throws network error at save call', () async {
    final product = ProductLangSlice((v) => v
      ..lang = LangCode.ru
      ..barcode = '123'
      ..vegetarianStatus = VegStatus.positive
      ..vegetarianStatusSource = VegStatusSource.community
      ..veganStatus = VegStatus.negative
      ..veganStatusSource = VegStatusSource.moderator
      ..name = 'name'
      ..brands.add('Brand name')
      ..ingredientsText = 'lemon, water'
      ..imageFront = Uri.file('/tmp/img1.jpg')
      ..imageIngredients = Uri.file('/tmp/img2.jpg')).productForTests();
    ensureProductIsInOFF(product);

    when(offApi.saveProduct(any, any))
        .thenAnswer((_) async => throw const SocketException(''));

    final result = await productsManager.createUpdateProduct(product);
    expect(result.unwrapErr(), equals(ProductsManagerError.NETWORK_ERROR));
  });

  test('update product OFF throws network error at image save call', () async {
    final product = ProductLangSlice((v) => v
      ..lang = LangCode.ru
      ..barcode = '123'
      ..vegetarianStatus = VegStatus.positive
      ..vegetarianStatusSource = VegStatusSource.community
      ..veganStatus = VegStatus.negative
      ..veganStatusSource = VegStatusSource.moderator
      ..name = 'name'
      ..brands.add('Brand name')
      ..ingredientsText = 'lemon, water'
      ..imageFront = Uri.file('/tmp/img1.jpg')
      ..imageIngredients = Uri.file('/tmp/img2.jpg')).productForTests();
    ensureProductIsInOFF(product);

    when(offApi.addProductImage(any, any))
        .thenAnswer((_) async => throw const SocketException(''));

    final result = await productsManager.createUpdateProduct(product);
    expect(result.unwrapErr(), equals(ProductsManagerError.NETWORK_ERROR));
  });

  test('update product network error in backend', () async {
    final product = ProductLangSlice((v) => v
      ..lang = LangCode.ru
      ..barcode = '123'
      ..vegetarianStatus = VegStatus.positive
      ..vegetarianStatusSource = VegStatusSource.community
      ..veganStatus = VegStatus.negative
      ..veganStatusSource = VegStatusSource.moderator
      ..name = 'name'
      ..brands.add('Brand name')
      ..ingredientsText = 'lemon, water'
      ..imageFront = Uri.file('/tmp/img1.jpg')
      ..imageIngredients = Uri.file('/tmp/img2.jpg')).productForTests();
    ensureProductIsInOFF(product);

    when(backend.createUpdateProduct(any,
            vegetarianStatus: anyNamed('vegetarianStatus'),
            veganStatus: anyNamed('veganStatus'),
            changedLangs: anyNamed('changedLangs')))
        .thenAnswer((_) async =>
            Err(BackendErrorKind.NETWORK_ERROR.toErrorForTesting()));

    final result = await productsManager.createUpdateProduct(product);
    expect(result.unwrapErr(), equals(ProductsManagerError.NETWORK_ERROR));
  });

  test('create product which does not exist in OFF yet', () async {
    final product = ProductLangSlice((v) => v
      ..lang = LangCode.ru
      ..barcode = '123'
      ..vegetarianStatus = VegStatus.positive
      ..vegetarianStatusSource = VegStatusSource.community
      ..veganStatus = VegStatus.negative
      ..veganStatusSource = VegStatusSource.moderator
      ..name = 'name'
      ..brands.add('Brand name')
      ..ingredientsText = 'lemon, water').productForTests();

    // Product is not in OFF yet
    when(offApi.getProduct(any))
        .thenAnswer((_) async => const off.ProductResult(product: null));

    verifyZeroInteractions(offApi);
    verifyZeroInteractions(backend);

    await productsManager.createUpdateProduct(product);

    // Off Product
    // NOTE that [productName], [ingredientsText] ARE NOT nulls,
    // unlike when an existing product is updated.
    final capturedOffProduct = verify(offApi.saveProduct(any, captureAny))
        .captured
        .first as off.Product;
    expect(capturedOffProduct.barcode, equals('123'));
    expect(capturedOffProduct.lang, off.OpenFoodFactsLanguage.RUSSIAN);
    expect(capturedOffProduct.productName, equals('name'));
    expect(capturedOffProduct.productNameInLanguages,
        equals({off.OpenFoodFactsLanguage.RUSSIAN: 'name'}));
    expect(capturedOffProduct.brands, equals('Brand name'));
    expect(capturedOffProduct.ingredientsText, equals('lemon, water'));
    expect(capturedOffProduct.ingredientsTextInLanguages,
        equals({off.OpenFoodFactsLanguage.RUSSIAN: 'lemon, water'}));

    // Backend Product
    verify(backend.createUpdateProduct('123',
            vegetarianStatus: VegStatus.positive,
            veganStatus: VegStatus.negative,
            changedLangs: anyNamed('changedLangs')))
        .called(1);

    verifyNever(offApi.addProductImage(any, captureAny));
  });

  test('ingredients extraction successful', () async {
    final product = ProductLangSlice((v) => v
      ..lang = LangCode.ru
      ..barcode = '123'
      ..name = 'name'
      ..imageIngredients = Uri.file('/tmp/img2.jpg')).productForTests();

    when(offApi.extractIngredients(any, any, any)).thenAnswer((_) async =>
        const off.OcrIngredientsResult(
            status: 0, ingredientsTextFromImage: 'lemon, water'));

    final result = await productsManager.updateProductAndExtractIngredients(
        product, LangCode.ru);
    expect(result.unwrap().ingredients, equals('lemon, water'));
  });

  test('ingredients extraction with product update fail', () async {
    when(offApi.extractIngredients(any, any, any)).thenAnswer((_) async =>
        const off.OcrIngredientsResult(
            status: 0, ingredientsTextFromImage: 'lemon, water'));

    when(offApi.saveProduct(any, any))
        .thenAnswer((_) async => off.Status(error: 'oops'));

    final product = ProductLangSlice((v) => v
      ..lang = LangCode.ru
      ..barcode = '123'
      ..name = 'name'
      ..imageIngredients = Uri.file('/tmp/img2.jpg')).productForTests();

    final result = await productsManager.updateProductAndExtractIngredients(
        product, LangCode.ru);
    expect(result.isErr, isTrue);
  });

  test('ingredients extraction fail', () async {
    final product = ProductLangSlice((v) => v
      ..lang = LangCode.ru
      ..barcode = '123'
      ..name = 'name'
      ..imageIngredients = Uri.file('/tmp/img2.jpg')).productForTests();

    when(offApi.extractIngredients(any, any, any))
        .thenAnswer((_) async => const off.OcrIngredientsResult(status: 1));

    final result = await productsManager.updateProductAndExtractIngredients(
        product, LangCode.ru);
    expect(result.unwrap().product, isNotNull);
    expect(result.unwrap().ingredients, isNull);
  });

  test('ingredients extraction network error', () async {
    final product = ProductLangSlice((v) => v
      ..lang = LangCode.ru
      ..barcode = '123'
      ..name = 'name'
      ..imageIngredients = Uri.file('/tmp/img2.jpg')).productForTests();

    when(offApi.extractIngredients(any, any, any))
        .thenAnswer((_) async => throw const SocketException(''));

    final result = await productsManager.updateProductAndExtractIngredients(
        product, LangCode.ru);
    expect(result.unwrapErr(), equals(ProductsManagerError.NETWORK_ERROR));
  });

  test('barcode from off is used', () async {
    const badBarcode = '0000000000123';
    const goodBarcode = '123';
    when(offApi.getProduct(any)).thenAnswer((_) async => off.ProductResult(
        product: off.Product.fromJson(
            {'code': goodBarcode, 'product_name_ru': 'name'})));

    final productRes =
        await productsManager.getProduct(badBarcode, [LangCode.ru]);
    final product = productRes.unwrap();

    // Verify received product
    expect(product!.barcode, equals(goodBarcode));
    // Verify good barcode is asked from the backed
    verify(backend.requestProduct(goodBarcode)).called(1);
  });

  test('brands are not sent when they are empty', () async {
    final product = ProductLangSlice((v) => v
      ..lang = LangCode.ru
      ..barcode = '123'
      ..brands.addAll([])).productForTests();

    await productsManager.createUpdateProduct(product);
    verifyNever(offApi.saveProduct(any, any));
  });

  test('international OFF product fields are not used', () async {
    final offProduct = off.Product.fromJson({
      'code': '123',
      'product_name': 'name',
      'ingredients_text': 'lemon, water'
    });
    when(offApi.getProduct(any))
        .thenAnswer((_) async => off.ProductResult(product: offProduct));

    when(backend.requestProduct(any)).thenAnswer((_) async => Ok(null));

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
    when(offApi.getProduct(any))
        .thenAnswer((_) async => off.ProductResult(product: offProduct));

    when(backend.requestProduct(any)).thenAnswer((_) async => Ok(null));

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
    when(offApi.getProduct(any))
        .thenAnswer((_) async => off.ProductResult(product: offProduct1));
    when(backend.requestProduct(any)).thenAnswer((_) async => Ok(null));

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

  test('unchanged product is not sent to OFF or backend on re-save', () async {
    final offProduct = off.Product.fromJson({
      'code': '123',
      'brands_tags': ['brand1', 'en:brand2'],
    });
    when(offApi.getProduct(any))
        .thenAnswer((_) async => off.ProductResult(product: offProduct));

    when(backend.requestProduct(any)).thenAnswer((_) async => Ok(null));

    final productRes = await productsManager.getProduct('123', [LangCode.ru]);
    final product = productRes.unwrap();

    // Send the product back without changing it
    await productsManager.createUpdateProduct(product!);

    // Ensure the product was not sent anywhere because it's not changed
    verifyNever(offApi.saveProduct(any, captureAny));
    verifyNever(backend.createUpdateProduct(any));
  });

  test('product considered unchanged when prioritized langs are different',
      () async {
    final offProduct = off.Product.fromJson({
      'code': '123',
      'brands_tags': ['brand1', 'en:brand2'],
    });
    when(offApi.getProduct(any))
        .thenAnswer((_) async => off.ProductResult(product: offProduct));
    when(backend.requestProduct(any)).thenAnswer((_) async => Ok(null));

    final productRes =
        await productsManager.getProduct('123', [LangCode.de, LangCode.ru]);
    var product = productRes.unwrap()!;

    // Change langs priority
    expect(product.langsPrioritized, equals([LangCode.de, LangCode.ru]));
    product = product
        .rebuild((e) => e.langsPrioritized.replace([LangCode.ru, LangCode.de]));
    expect(product.langsPrioritized, equals([LangCode.ru, LangCode.de]));

    // Send the product back
    await productsManager.createUpdateProduct(product);

    // Ensure the product was not sent anywhere because only langs priorities
    // are changed
    verifyNever(offApi.saveProduct(any, captureAny));
    verifyNever(backend.createUpdateProduct(any));
  });

  test('product considered unchanged when OFF tags field are reordered',
      () async {
    final offProduct = off.Product.fromJson({
      'code': '123',
      'brands_tags': ['brand1', 'brand2'],
    });
    when(offApi.getProduct(any))
        .thenAnswer((_) async => off.ProductResult(product: offProduct));

    when(backend.requestProduct(any)).thenAnswer((_) async => Ok(null));

    final productRes = await productsManager.getProduct('123', [LangCode.ru]);
    final product = productRes.unwrap();
    expect(product!.brands!.length, equals(2));

    // Send the product back with reordered tags
    final productReordered =
        product.rebuild((v) => v..brands.replace(product.brands!.reversed));
    await productsManager.createUpdateProduct(productReordered);

    // Ensure the product was not sent anywhere because it's actually same
    verifyNever(offApi.saveProduct(any, captureAny));
    verifyNever(backend.createUpdateProduct(any));
  });

  test('off ingredients analysis parsing', () async {
    final offProduct = off.Product.fromJson({
      'code': '123',
      'ingredients_text_ru': 'voda',
      'ingredients': [
        {
          'vegan': 'maybe',
          'vegetarian': 'yes',
          'text': 'water',
          'id': 'en:water',
        }
      ],
      'ingredients_tags': ['en:water'],
      'ingredients_tags_ru': ['voda'],
    });
    when(offApi.getProduct(any))
        .thenAnswer((_) async => off.ProductResult(product: offProduct));

    final productRes = await productsManager.getProduct('123', [LangCode.ru]);
    final product = productRes.unwrap();
    expect(
        product!.ingredientsAnalyzed,
        equals(BuiltList<Ingredient>([
          Ingredient((v) => v
            ..name = 'voda'
            ..vegetarianStatus = VegStatus.positive
            ..veganStatus = VegStatus.possible)
        ])));
  });

  test('off multiple ingredients analysis parsing order 1', () async {
    final offProduct = off.Product.fromJson({
      'code': '123',
      'ingredients_text_ru': 'voda',
      'ingredients': [
        {
          'vegan': 'maybe',
          'vegetarian': 'yes',
          'text': 'water',
          'id': 'en:water',
        },
        {
          'vegan': 'maybe',
          'vegetarian': 'no',
          'text': 'salt',
          'id': 'en:salt',
        },
      ],
      'ingredients_tags': ['en:water', 'en:salt'],
      'ingredients_tags_ru': ['voda', 'sol'],
    });
    when(offApi.getProduct(any))
        .thenAnswer((_) async => off.ProductResult(product: offProduct));

    final productRes = await productsManager.getProduct('123', [LangCode.ru]);
    final product = productRes.unwrap();
    expect(
        product!.ingredientsAnalyzed,
        equals(BuiltList<Ingredient>([
          Ingredient((v) => v
            ..name = 'voda'
            ..vegetarianStatus = VegStatus.positive
            ..veganStatus = VegStatus.possible),
          Ingredient((v) => v
            ..name = 'sol'
            ..vegetarianStatus = VegStatus.negative
            ..veganStatus = VegStatus.possible)
        ])));
  });

  test('off multiple ingredients analysis parsing order 2', () async {
    final offProduct = off.Product.fromJson({
      'code': '123',
      'ingredients_text_ru': 'voda',
      'ingredients': [
        {
          'vegan': 'maybe',
          'vegetarian': 'no',
          'text': 'salt',
          'id': 'en:salt',
        },
        {
          'vegan': 'maybe',
          'vegetarian': 'yes',
          'text': 'water',
          'id': 'en:water',
        },
      ],
      'ingredients_tags': ['en:water', 'en:salt'],
      'ingredients_tags_ru': ['voda', 'sol'],
    });
    when(offApi.getProduct(any))
        .thenAnswer((_) async => off.ProductResult(product: offProduct));

    final productRes = await productsManager.getProduct('123', [LangCode.ru]);
    final product = productRes.unwrap();
    expect(
        product!.ingredientsAnalyzed,
        equals(BuiltList<Ingredient>([
          Ingredient((v) => v
            ..name = 'sol'
            ..vegetarianStatus = VegStatus.negative
            ..veganStatus = VegStatus.possible),
          Ingredient((v) => v
            ..name = 'voda'
            ..vegetarianStatus = VegStatus.positive
            ..veganStatus = VegStatus.possible),
        ])));
  });

  test(
      'off ingredients analysis is not used when ingredients text is not provided',
      () async {
    final offProduct = off.Product.fromJson({
      'code': '123',
      // 'ingredients_text_ru': null, // NOTE: no text
      'ingredients': [
        {
          'vegan': 'maybe',
          'vegetarian': 'yes',
          'text': 'water',
          'id': 'en:water',
        }
      ],
      'ingredients_tags': ['en:water'],
      'ingredients_tags_ru': ['voda'],
    });
    when(offApi.getProduct(any))
        .thenAnswer((_) async => off.ProductResult(product: offProduct));

    final productRes = await productsManager.getProduct('123', [LangCode.ru]);
    final product = productRes.unwrap();
    expect(product!.ingredientsAnalyzed, isNull);
  });

  test(
      'if vegetarian status exists both on backend and OFF then '
      'from backend is used', () async {
    final offProduct = off.Product.fromJson({
      'code': '123',
      'ingredients_text_ru': 'water',
      'ingredients': [
        {
          'vegan': 'maybe',
          'vegetarian': 'yes',
          'text': 'water',
          'id': 'en:water',
        }
      ],
      'ingredients_tags': ['en:water'],
      'ingredients_tags_ru': ['voda'],
    });
    when(offApi.getProduct(any))
        .thenAnswer((_) async => off.ProductResult(product: offProduct));

    final backendProduct = BackendProduct((v) => v
      ..barcode = '123'
      ..vegetarianStatus = VegStatus.unknown.name
      ..vegetarianStatusSource = VegStatusSource.community.name);
    when(backend.requestProduct(any))
        .thenAnswer((_) async => Ok(backendProduct));

    final productRes = await productsManager.getProduct('123', [LangCode.ru]);
    final product = productRes.unwrap();
    expect(product!.vegetarianStatus, equals(VegStatus.unknown));
    expect(product.vegetarianStatusSource, equals(VegStatusSource.community));
    expect(product.veganStatus, equals(VegStatus.possible));
    expect(product.veganStatusSource, equals(VegStatusSource.open_food_facts));
  });

  test(
      'if vegan status exists both on backend and OFF then '
      'from backend is used', () async {
    final offProduct = off.Product.fromJson({
      'code': '123',
      'ingredients_text_ru': 'water',
      'ingredients': [
        {
          'vegan': 'maybe',
          'vegetarian': 'yes',
          'text': 'water',
          'id': 'en:water',
        }
      ],
      'ingredients_tags': ['en:water'],
      'ingredients_tags_ru': ['voda'],
    });
    when(offApi.getProduct(any))
        .thenAnswer((_) async => off.ProductResult(product: offProduct));

    final backendProduct = BackendProduct((v) => v
      ..barcode = '123'
      ..veganStatus = VegStatus.negative.name
      ..veganStatusSource = VegStatusSource.moderator.name);
    when(backend.requestProduct(any))
        .thenAnswer((_) async => Ok(backendProduct));

    final productRes = await productsManager.getProduct('123', [LangCode.ru]);
    final product = productRes.unwrap();
    expect(product!.vegetarianStatus, equals(VegStatus.positive));
    expect(product.vegetarianStatusSource,
        equals(VegStatusSource.open_food_facts));
    expect(product.veganStatus, equals(VegStatus.negative));
    expect(product.veganStatusSource, equals(VegStatusSource.moderator));
  });

  test('invalid veg statuses from server are treated as community', () async {
    final offProduct = off.Product.fromJson({'code': '123'});
    when(offApi.getProduct(any))
        .thenAnswer((_) async => off.ProductResult(product: offProduct));

    final backendProduct = BackendProduct((v) => v
      ..barcode = '123'
      ..vegetarianStatus = VegStatus.negative.name
      ..vegetarianStatusSource = '${VegStatusSource.moderator.name}woop'
      ..veganStatus = VegStatus.negative.name
      ..veganStatusSource = '${VegStatusSource.moderator.name}woop');
    when(backend.requestProduct(any))
        .thenAnswer((_) async => Ok(backendProduct));

    final productRes = await productsManager.getProduct('123', [LangCode.ru]);
    final product = productRes.unwrap();
    expect(product!.vegetarianStatus, equals(VegStatus.negative));
    expect(product.vegetarianStatusSource, equals(VegStatusSource.community));
    expect(product.veganStatus, equals(VegStatus.negative));
    expect(product.veganStatusSource, equals(VegStatusSource.community));
  });

  test('invalid veg statuses from server are treated as if they do not exist',
      () async {
    final offProduct = off.Product.fromJson({'code': '123'});
    when(offApi.getProduct(any))
        .thenAnswer((_) async => off.ProductResult(product: offProduct));

    final backendProduct = BackendProduct((v) => v
      ..barcode = '123'
      ..vegetarianStatus = '${VegStatus.negative.name}woop'
      ..vegetarianStatusSource = VegStatusSource.moderator.name
      ..veganStatus = '${VegStatus.negative.name}woop'
      ..veganStatusSource = VegStatusSource.moderator.name);
    when(backend.requestProduct(any))
        .thenAnswer((_) async => Ok(backendProduct));

    final productRes = await productsManager.getProduct('123', [LangCode.ru]);
    final product = productRes.unwrap();
    expect(product!.vegetarianStatus, isNull);
    expect(product.veganStatus, isNull);
  });

  test('invalid veg statuses from server are treated as if they do not exist',
      () async {
    final offProduct = off.Product.fromJson({'code': '123'});
    when(offApi.getProduct(any))
        .thenAnswer((_) async => off.ProductResult(product: offProduct));

    final backendProduct = BackendProduct((v) => v
      ..barcode = '123'
      ..vegetarianStatus = '${VegStatus.negative.name}woop'
      ..vegetarianStatusSource = VegStatusSource.moderator.name
      ..veganStatus = '${VegStatus.negative.name}woop'
      ..veganStatusSource = VegStatusSource.moderator.name);
    when(backend.requestProduct(any))
        .thenAnswer((_) async => Ok(backendProduct));

    final productRes = await productsManager.getProduct('123', [LangCode.ru]);
    final product = productRes.unwrap();
    expect(product!.vegetarianStatus, isNull);
    expect(product.veganStatus, isNull);
  });

  test('if backend veg statuses parsing failed then analysis is used',
      () async {
    final offProduct = off.Product.fromJson({
      'code': '123',
      'ingredients_text_ru': 'water',
      'ingredients': [
        {
          'vegan': 'maybe',
          'vegetarian': 'yes',
          'text': 'water',
          'id': 'en:water',
        }
      ],
      'ingredients_tags': ['en:water'],
      'ingredients_tags_ru': ['voda'],
    });
    when(offApi.getProduct(any))
        .thenAnswer((_) async => off.ProductResult(product: offProduct));

    final backendProduct = BackendProduct((v) => v
      ..barcode = '123'
      ..vegetarianStatus = '${VegStatus.negative.name}woop'
      ..vegetarianStatusSource = VegStatusSource.moderator.name
      ..veganStatus = '${VegStatus.negative.name}woop'
      ..veganStatusSource = VegStatusSource.moderator.name);
    when(backend.requestProduct(any))
        .thenAnswer((_) async => Ok(backendProduct));

    final productRes = await productsManager.getProduct('123', [LangCode.ru]);
    final product = productRes.unwrap();
    expect(product!.vegetarianStatus, VegStatus.positive);
    expect(product.vegetarianStatusSource, VegStatusSource.open_food_facts);
    expect(product.veganStatus, VegStatus.possible);
    expect(product.veganStatusSource, VegStatusSource.open_food_facts);
  });

  test('product is requested from OFF before it\'s saved so it would be cached',
      () async {
    final product = ProductLangSlice((v) => v
      ..lang = LangCode.ru
      ..barcode = '123'
      ..vegetarianStatus = VegStatus.positive
      ..vegetarianStatusSource = VegStatusSource.community
      ..veganStatus = VegStatus.negative
      ..veganStatusSource = VegStatusSource.moderator
      ..name = 'name'
      ..ingredientsText = 'lemon, water').productForTests();

    verifyNever(offApi.getProduct(any));
    final saveResult = await productsManager.createUpdateProduct(product);
    verify(offApi.getProduct(any));

    expect(saveResult.isOk, isTrue);
  });

  test('product saving aborts if product request failed', () async {
    final product = ProductLangSlice((v) => v
      ..lang = LangCode.ru
      ..barcode = '123'
      ..vegetarianStatus = VegStatus.positive
      ..vegetarianStatusSource = VegStatusSource.community
      ..veganStatus = VegStatus.negative
      ..veganStatusSource = VegStatusSource.moderator
      ..name = 'name'
      ..ingredientsText = 'lemon, water').productForTests();

    when(offApi.getProduct(any))
        .thenAnswer((_) async => const off.ProductResult(status: 123));

    verifyNever(offApi.getProduct(any));
    final saveResult = await productsManager.createUpdateProduct(product);
    verify(offApi.getProduct(any));

    expect(saveResult.isErr, isTrue);
  });

  test('inflate backend product', () async {
    final offProduct = off.Product.fromJson({
      'code': '123',
      'product_name_ru': 'name',
      'brands_tags': ['Brand name'],
      'ingredients_text_ru': 'lemon, water',
      'selected_images': jsonDecode(selectedImagesRuJson),
    });
    when(offApi.getProduct(any))
        .thenAnswer((_) async => off.ProductResult(product: offProduct));

    final backendProduct = BackendProduct((v) => v
      ..barcode = '123'
      ..vegetarianStatus = VegStatus.positive.name
      ..vegetarianStatusSource = VegStatusSource.community.name
      ..veganStatus = VegStatus.negative.name
      ..veganStatusSource = VegStatusSource.moderator.name);
    final productRes =
        await productsManager.inflate(backendProduct, [LangCode.ru]);
    final product = productRes.unwrap();

    final expectedProduct = ProductLangSlice((v) => v
          ..lang = LangCode.ru
          ..barcode = '123'
          ..vegetarianStatus = VegStatus.positive
          ..vegetarianStatusSource = VegStatusSource.community
          ..veganStatus = VegStatus.negative
          ..veganStatusSource = VegStatusSource.moderator
          ..name = 'name'
          ..brands.add('Brand name')
          ..ingredientsText = 'lemon, water'
          ..ingredientsAnalyzed.addAll([])
          ..imageFront = Uri.parse(expectedImageFrontRu)
          ..imageFrontThumb = Uri.parse(expectedImageFrontThumbRu)
          ..imageIngredients = Uri.parse(expectedImageIngredientsRu))
        .productForTests();
    expect(product, equals(expectedProduct));

    // We expect the backend to not be touched since
    // we already have a backend product.
    verifyNever(backend.requestProduct(any));
  });

  test(
      'front image is not uploaded again if ingredients image upload fails on first save attempt',
      () async {
    final product = ProductLangSlice((v) => v
      ..lang = LangCode.ru
      ..barcode = '123'
      ..vegetarianStatus = VegStatus.positive
      ..vegetarianStatusSource = VegStatusSource.community
      ..veganStatus = VegStatus.negative
      ..veganStatusSource = VegStatusSource.moderator
      ..name = 'name'
      ..brands.add('Brand name')
      ..ingredientsText = 'lemon, water'
      ..imageFront = Uri.file('/tmp/img1.jpg')
      ..imageIngredients = Uri.file('/tmp/img2.jpg')).productForTests();
    ensureProductIsInOFF(product);

    final imageUploadsAttempts = <off.ImageField>[];
    var failIngredientsImageUploading = true;
    when(offApi.addProductImage(any, any)).thenAnswer((invc) async {
      final image = invc.positionalArguments[1] as off.SendImage;
      imageUploadsAttempts.add(image.imageField);
      if (image.imageField == off.ImageField.INGREDIENTS) {
        if (failIngredientsImageUploading) {
          return off.Status(
              status: 'bad bad bad', error: 'bad image, very bad!');
        } else {
          return off.Status();
        }
      } else {
        // ok
        return off.Status();
      }
    });

    expect(imageUploadsAttempts.length, equals(0));

    var result = await productsManager.createUpdateProduct(product);
    expect(result.isErr, isTrue);

    // Expect the Front image to be uploaded,
    // the Ingredients image to be not uploaded.
    expect(imageUploadsAttempts.length, equals(2));
    expect(imageUploadsAttempts[0], equals(off.ImageField.FRONT));
    expect(imageUploadsAttempts[1], equals(off.ImageField.INGREDIENTS));
    // Expect the product was not sent to backend because one of
    // images savings has failed.
    verifyNever(backend.createUpdateProduct(any));

    // Second attempt
    imageUploadsAttempts.clear();
    failIngredientsImageUploading = false;

    result = await productsManager.createUpdateProduct(product);
    expect(result.isErr, isFalse);

    // Expect the Front image to be NOT uploaded - it was uploaded already.
    // Expect the Ingredients image to be uploaded this time -
    // the first attempt has failed.
    expect(imageUploadsAttempts, equals([off.ImageField.INGREDIENTS]));
    // Expect the product WAS sent to backend because now all images are uploaded.
    verify(backend.createUpdateProduct('123',
        vegetarianStatus: VegStatus.positive,
        veganStatus: VegStatus.negative,
        changedLangs: anyNamed('changedLangs')));
  });

  test('OFF "images" field is ignored', () async {
    // This JSON was used in the tests as the images source before
    // https://trello.com/c/YkrvnTDZ/
    const imagesJson = '''
    {
     "front_ru":{
        "rev":"16",
        "sizes":{
           "400":{
              "h":400,
              "w":289
           },
           "200":{
              "h":100,
              "w":75
           }
        },
        "imgid":"1"
     },
     "ingredients_ru":{
        "sizes":{
           "full":{
              "w":216,
              "h":400
           }
        },
        "rev":"19",
        "imgid":"2"
     }
    }
    ''';
    final offProduct = off.Product.fromJson({
      'code': '123',
      'product_name_ru': 'name',
      'ingredients_text_ru': 'lemon, water',
      'images': jsonDecode(imagesJson),
    });
    off.ProductHelper.createImageUrls(offProduct);
    when(offApi.getProduct(any))
        .thenAnswer((_) async => off.ProductResult(product: offProduct));

    when(backend.requestProduct(any)).thenAnswer((_) async => Ok(null));

    final productRes = await productsManager.getProduct('123', [LangCode.ru]);
    final product = productRes.unwrap();
    // No images expected
    final expectedProduct = ProductLangSlice((v) => v
      ..lang = LangCode.ru
      ..barcode = '123'
      ..vegetarianStatus = null
      ..vegetarianStatusSource = null
      ..veganStatus = null
      ..veganStatusSource = null
      ..name = 'name'
      ..ingredientsText = 'lemon, water'
      ..ingredientsAnalyzed.addAll([])
      ..brands.addAll([])
      ..imageFront = null
      ..imageFrontThumb = null
      ..imageIngredients = null).productForTests();
    expect(product, equals(expectedProduct));
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
      'selected_images': jsonDecode(selectedImagesRuDeJson),
    });
    when(offApi.getProduct(any))
        .thenAnswer((_) async => off.ProductResult(product: offProduct));

    when(backend.requestProduct(any)).thenAnswer((_) async => Ok(null));

    final productRes =
        await productsManager.getProduct('123', langsPrioritized);
    final product = productRes.unwrap();
    final expectedProduct = Product((v) => v
      ..barcode = '123'
      ..vegetarianStatus = VegStatus.positive
      ..vegetarianStatusSource = VegStatusSource.open_food_facts
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
            ..vegetarianStatus = VegStatus.positive
            ..veganStatus = VegStatus.possible)
        ]),
        LangCode.de: BuiltList<Ingredient>([
          Ingredient((v) => v
            ..name = 'wasser'
            ..vegetarianStatus = VegStatus.positive
            ..veganStatus = VegStatus.possible)
        ]),
      })
      ..imageFrontLangs.addAll({
        LangCode.ru: Uri.parse(expectedImageFrontRu),
        LangCode.de: Uri.parse(expectedImageFrontDe),
      })
      ..imageFrontThumbLangs.addAll({
        LangCode.ru: Uri.parse(expectedImageFrontThumbRu),
        LangCode.de: Uri.parse(expectedImageFrontThumbDe),
      })
      ..imageIngredientsLangs.addAll({
        LangCode.ru: Uri.parse(expectedImageIngredientsRu),
        LangCode.de: Uri.parse(expectedImageIngredientsDe),
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
      ..vegetarianStatus = VegStatus.positive
      ..vegetarianStatusSource = VegStatusSource.open_food_facts
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
        vegetarianStatus: VegStatus.positive,
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
      'selected_images': jsonDecode(selectedImagesRuDeJson),
    });
    when(offApi.getProduct(any))
        .thenAnswer((_) async => off.ProductResult(product: offProduct));
    when(backend.requestProduct(any)).thenAnswer((_) async => Ok(null));

    final originalProductRes =
        await productsManager.getProduct(barcode, [LangCode.ru, LangCode.de]);
    final originalProduct = originalProductRes.unwrap()!;

    // RU is untouched
    final updatedProduct = originalProduct.rebuild((e) => e
      ..vegetarianStatus = VegStatus.positive
      ..veganStatus = VegStatus.possible
      ..langsPrioritized.add(LangCode.en)
      ..nameLangs[LangCode.en] = 'banana'
      ..ingredientsTextLangs[LangCode.de] = 'banane');

    final result = await productsManager.createUpdateProduct(updatedProduct);
    expect(result.isOk, isTrue);

    // Verify changed langs
    verify(backend.createUpdateProduct(barcode,
        vegetarianStatus: VegStatus.positive,
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
      'selected_images': jsonDecode(selectedImagesRuDeJson),
    });
    when(offApi.getProduct(any))
        .thenAnswer((_) async => off.ProductResult(product: offProduct));
    when(backend.requestProduct(any)).thenAnswer((_) async => Ok(null));

    final originalProductRes =
        await productsManager.getProduct(barcode, [LangCode.ru, LangCode.de]);
    final originalProduct = originalProductRes.unwrap()!;

    // All langs are untouched
    final updatedProduct = originalProduct.rebuild((e) => e
      ..vegetarianStatus = VegStatus.positive
      ..veganStatus = VegStatus.possible);

    final result = await productsManager.createUpdateProduct(updatedProduct);
    expect(result.isOk, isTrue);

    // Verify not changed langs
    verify(backend.createUpdateProduct(barcode,
        vegetarianStatus: VegStatus.positive,
        veganStatus: VegStatus.possible,
        changedLangs: []));
  });
}
