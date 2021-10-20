import 'dart:io';

import 'package:mockito/mockito.dart';
import 'package:openfoodfacts/model/Product.dart' as off;
import 'package:openfoodfacts/openfoodfacts.dart' as off;
import 'package:plante/base/result.dart';
import 'package:plante/model/lang_code.dart';
import 'package:plante/model/product.dart';
import 'package:plante/model/product_lang_slice.dart';
import 'package:plante/model/veg_status.dart';
import 'package:plante/model/veg_status_source.dart';
import 'package:plante/outside/backend/backend_error.dart';
import 'package:plante/outside/backend/backend_product.dart';
import 'package:plante/outside/products/products_manager.dart';
import 'package:plante/outside/products/products_manager_error.dart';
import 'package:test/test.dart';

import '../../common_mocks.mocks.dart';
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

  void ensureProductIsInOFF(Product product) {
    commons.ensureProductIsInOFF(product);
  }

  void setUpBackendProducts(
      Result<List<BackendProduct>, BackendError> productsRes) {
    commons.setUpBackendProducts(productsRes);
  }

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
    setUpOffProducts(const []);

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

  test('brands are not sent when they are empty', () async {
    final product = ProductLangSlice((v) => v
      ..lang = LangCode.ru
      ..barcode = '123'
      ..brands.addAll([])).productForTests();

    await productsManager.createUpdateProduct(product);
    verifyNever(offApi.saveProduct(any, any));
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

    verifyNever(offApi.getProductList(any));
    final saveResult = await productsManager.createUpdateProduct(product);
    verify(offApi.getProductList(any));

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

    setUpOffProducts(const []);

    verifyNever(offApi.getProductList(any));
    final saveResult = await productsManager.createUpdateProduct(product);
    verify(offApi.getProductList(any));

    expect(saveResult.isErr, isTrue);
  });

  test('unchanged product is not sent to OFF or backend on re-save', () async {
    final offProduct = off.Product.fromJson({
      'code': '123',
      'brands_tags': ['brand1', 'en:brand2'],
    });
    setUpOffProducts([offProduct]);

    setUpBackendProducts(Ok(const []));

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
    setUpOffProducts([offProduct]);
    setUpBackendProducts(Ok(const []));

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
    setUpOffProducts([offProduct]);

    setUpBackendProducts(Ok(const []));

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
}
