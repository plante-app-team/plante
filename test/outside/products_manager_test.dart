import 'package:built_collection/built_collection.dart';
import 'package:either_option/either_option.dart';
import 'package:openfoodfacts/model/OcrIngredientsResult.dart' as off;
import 'package:openfoodfacts/model/Product.dart' as off;
import 'package:openfoodfacts/openfoodfacts.dart' as off;

import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';
import 'package:untitled_vegan_app/model/product.dart';
import 'package:untitled_vegan_app/model/veg_status.dart';
import 'package:untitled_vegan_app/model/veg_status_source.dart';
import 'package:untitled_vegan_app/outside/backend/backend.dart';
import 'package:untitled_vegan_app/outside/backend/backend_product.dart';
import 'package:untitled_vegan_app/outside/off/off_api.dart';
import 'package:untitled_vegan_app/outside/products_manager.dart';

import 'products_manager_test.mocks.dart';

@GenerateMocks([OffApi, Backend])
void main() {
  late MockOffApi offApi;
  late MockBackend backend;
  late ProductsManager productsManager;

  setUp(() {
    offApi = MockOffApi();
    backend = MockBackend();
    productsManager = ProductsManager(offApi, backend);

    when(offApi.saveProduct(any, any)).thenAnswer((_) async => off.Status());
    when(offApi.getProduct(any)).thenAnswer((_) async =>
        off.ProductResult(product: off.Product()));
    when(offApi.addProductImage(any, any)).thenAnswer((_) async => off.Status());
    when(offApi.extractIngredients(any, any, any)).thenAnswer((_) async => off.OcrIngredientsResult());

    when(backend.createUpdateProduct(
        any,
        vegetarianStatus: anyNamed("vegetarianStatus"),
        veganStatus: anyNamed("veganStatus"))).thenAnswer((_) async => Left(None()));
    when(backend.requestProduct(any)).thenAnswer((invc) async =>
        BackendProduct((v) => v.barcode = invc.positionalArguments[0]));
  });

  test('get product when the product is on both OFF and backend', () async {
    final offProduct = off.Product.fromJson({
      "barcode": "123",
      "product_name": "name",
      "brands_tags": ["Brand name"],
      "categories_tags_translated": ["plant", "lemon"],
      "ingredients_text": "lemon, water",
      "image_front_url": "https://example.com/1.jpg",
      "image_ingredients_url": "https://example.com/2.jpg"
    });
    when(offApi.getProduct(any)).thenAnswer((_) async =>
        off.ProductResult(product: offProduct));

    final backendProduct = BackendProduct((v) => v
      ..barcode = "123"
      ..vegetarianStatus = VegStatus.positive.name
      ..vegetarianStatusSource = VegStatusSource.community.name
      ..veganStatus = VegStatus.negative.name
      ..veganStatusSource = VegStatusSource.moderator.name);
    when(backend.requestProduct(any)).thenAnswer((_) async => backendProduct);

    final product = await productsManager.getProduct("123", "ru");
    final expectedProduct = Product((v) => v
      ..barcode = "123"
      ..vegetarianStatus = VegStatus.positive
      ..vegetarianStatusSource = VegStatusSource.community
      ..veganStatus = VegStatus.negative
      ..veganStatusSource = VegStatusSource.moderator
      ..name = "name"
      ..brands.add("Brand name")
      ..categories.addAll(["plant", "lemon"])
      ..ingredients = "lemon, water"
      ..imageFront = Uri.parse("https://example.com/1.jpg")
      ..imageIngredients = Uri.parse("https://example.com/2.jpg"));
    expect(product, equals(expectedProduct));
  });

  test('get product when the product is on OFF only', () async {
    final offProduct = off.Product.fromJson({
      "barcode": "123",
      "product_name": "name",
      "brands_tags": ["Brand name"],
      "categories_tags_translated": ["plant", "lemon"],
      "ingredients_text": "lemon, water",
      "image_front_url": "https://example.com/1.jpg",
      "image_ingredients_url": "https://example.com/2.jpg"
    });
    when(offApi.getProduct(any)).thenAnswer((_) async =>
        off.ProductResult(product: offProduct));

    when(backend.requestProduct(any)).thenAnswer((_) async => null);

    final product = await productsManager.getProduct("123", "ru");
    final expectedProduct = Product((v) => v
      ..barcode = "123"
      ..vegetarianStatus = null
      ..vegetarianStatusSource = null
      ..veganStatus = null
      ..veganStatusSource = null
      ..name = "name"
      ..brands.add("Brand name")
      ..categories.addAll(["plant", "lemon"])
      ..ingredients = "lemon, water"
      ..imageFront = Uri.parse("https://example.com/1.jpg")
      ..imageIngredients = Uri.parse("https://example.com/2.jpg"));
    expect(product, equals(expectedProduct));
  });

  test('get product when the product is on backend only', () async {
    when(offApi.getProduct(any)).thenAnswer((_) async =>
        off.ProductResult(product: null));

    final backendProduct = BackendProduct((v) => v
      ..barcode = "123"
      ..vegetarianStatus = VegStatus.positive.name
      ..vegetarianStatusSource = VegStatusSource.community.name
      ..veganStatus = VegStatus.negative.name
      ..veganStatusSource = VegStatusSource.moderator.name);
    when(backend.requestProduct(any)).thenAnswer((_) async => backendProduct);

    final product = await productsManager.getProduct("123", "ru");
    expect(product, equals(null));
  });

  test('update product with both front and ingredients images', () async {
    final product = Product((v) => v
      ..barcode = "123"
      ..vegetarianStatus = VegStatus.positive
      ..vegetarianStatusSource = VegStatusSource.community
      ..veganStatus = VegStatus.negative
      ..veganStatusSource = VegStatusSource.moderator
      ..name = "name"
      ..brands.add("Brand name")
      ..categories.addAll(["plant", "lemon"])
      ..ingredients = "lemon, water"
      ..imageFront = Uri.file("/tmp/img1.jpg")
      ..imageIngredients = Uri.file("/tmp/img2.jpg"));

    verifyZeroInteractions(offApi);
    verifyZeroInteractions(backend);

    await productsManager.updateProduct(product, "ru");

    // Off Product
    final capturedOffProduct = verify(offApi.saveProduct(any, captureAny))
        .captured.first as off.Product;
    expect(capturedOffProduct.barcode, equals("123"));
    expect(capturedOffProduct.productName, equals("name"));
    expect(capturedOffProduct.brands, equals("Brand name"));
    expect(capturedOffProduct.categories, equals("plant, lemon"));
    expect(capturedOffProduct.ingredientsText, equals("lemon, water"));

    // Backend Product
    verify(backend.createUpdateProduct(
        "123",
        vegetarianStatus: VegStatus.positive,
        veganStatus: VegStatus.negative))
        .called(1);

    // Off image front
    final allImages = verify(offApi.addProductImage(any, captureAny)).captured;
    final capturedImage1 = allImages[0] as off.SendImage;
    expect(capturedImage1.imageField, equals(off.ImageField.FRONT));
    expect(capturedImage1.imageUri, equals(Uri.file("/tmp/img1.jpg")));
    expect(capturedImage1.barcode, equals("123"));
    expect(capturedImage1.lang, equals(off.OpenFoodFactsLanguage.RUSSIAN));

    // Off image ingredients
    final capturedImage2 = allImages[1] as off.SendImage;
    expect(capturedImage2.imageField, equals(off.ImageField.INGREDIENTS));
    expect(capturedImage2.imageUri, equals(Uri.file("/tmp/img2.jpg")));
    expect(capturedImage2.barcode, equals("123"));
    expect(capturedImage2.lang, equals(off.OpenFoodFactsLanguage.RUSSIAN));
  });

  test('update product without images', () async {
    final product = Product((v) => v
      ..barcode = "123"
      ..vegetarianStatus = VegStatus.positive
      ..vegetarianStatusSource = VegStatusSource.community
      ..veganStatus = VegStatus.negative
      ..veganStatusSource = VegStatusSource.moderator
      ..name = "name"
      ..brands.add("Brand name")
      ..categories.addAll(["plant", "lemon"])
      ..ingredients = "lemon, water");

    verifyZeroInteractions(offApi);
    verifyZeroInteractions(backend);

    await productsManager.updateProduct(product, "ru");

    // Off Product
    final capturedOffProduct = verify(offApi.saveProduct(any, captureAny))
        .captured.first as off.Product;
    expect(capturedOffProduct.barcode, equals("123"));
    expect(capturedOffProduct.productName, equals("name"));
    expect(capturedOffProduct.brands, equals("Brand name"));
    expect(capturedOffProduct.categories, equals("plant, lemon"));
    expect(capturedOffProduct.ingredientsText, equals("lemon, water"));

    // Backend Product
    verify(backend.createUpdateProduct(
        "123",
        vegetarianStatus: VegStatus.positive,
        veganStatus: VegStatus.negative))
        .called(1);

    verifyNever(offApi.addProductImage(any, captureAny));
  });

  test('update product with front image only', () async {
    final product = Product((v) => v
      ..barcode = "123"
      ..vegetarianStatus = VegStatus.positive
      ..vegetarianStatusSource = VegStatusSource.community
      ..veganStatus = VegStatus.negative
      ..veganStatusSource = VegStatusSource.moderator
      ..name = "name"
      ..brands.add("Brand name")
      ..categories.addAll(["plant", "lemon"])
      ..ingredients = "lemon, water"
      ..imageFront = Uri.file("/tmp/img1.jpg"));

    verifyZeroInteractions(offApi);
    verifyZeroInteractions(backend);

    await productsManager.updateProduct(product, "ru");

    // Off Product
    final capturedOffProduct = verify(offApi.saveProduct(any, captureAny))
        .captured.first as off.Product;
    expect(capturedOffProduct.barcode, equals("123"));
    expect(capturedOffProduct.productName, equals("name"));
    expect(capturedOffProduct.brands, equals("Brand name"));
    expect(capturedOffProduct.categories, equals("plant, lemon"));
    expect(capturedOffProduct.ingredientsText, equals("lemon, water"));

    // Backend Product
    verify(backend.createUpdateProduct(
        "123",
        vegetarianStatus: VegStatus.positive,
        veganStatus: VegStatus.negative))
        .called(1);

    // Off image front
    final allImages = verify(offApi.addProductImage(any, captureAny)).captured;
    final capturedImage = allImages[0] as off.SendImage;
    expect(capturedImage.imageField, equals(off.ImageField.FRONT));
    expect(capturedImage.imageUri, equals(Uri.file("/tmp/img1.jpg")));
    expect(capturedImage.barcode, equals("123"));
    expect(capturedImage.lang, equals(off.OpenFoodFactsLanguage.RUSSIAN));

    // Only 1 image
    expect(allImages.length, equals(1));
  });

  test('update product with ingredients image only', () async {
    final product = Product((v) => v
      ..barcode = "123"
      ..vegetarianStatus = VegStatus.positive
      ..vegetarianStatusSource = VegStatusSource.community
      ..veganStatus = VegStatus.negative
      ..veganStatusSource = VegStatusSource.moderator
      ..name = "name"
      ..brands.add("Brand name")
      ..categories.addAll(["plant", "lemon"])
      ..ingredients = "lemon, water"
      ..imageIngredients = Uri.file("/tmp/img2.jpg"));

    verifyZeroInteractions(offApi);
    verifyZeroInteractions(backend);

    await productsManager.updateProduct(product, "ru");

    // Off Product
    final capturedOffProduct = verify(offApi.saveProduct(any, captureAny))
        .captured.first as off.Product;
    expect(capturedOffProduct.barcode, equals("123"));
    expect(capturedOffProduct.productName, equals("name"));
    expect(capturedOffProduct.brands, equals("Brand name"));
    expect(capturedOffProduct.categories, equals("plant, lemon"));
    expect(capturedOffProduct.ingredientsText, equals("lemon, water"));

    // Backend Product
    verify(backend.createUpdateProduct(
        "123",
        vegetarianStatus: VegStatus.positive,
        veganStatus: VegStatus.negative))
        .called(1);

    // Off image ingredients
    final allImages = verify(offApi.addProductImage(any, captureAny)).captured;
    final capturedImage = allImages[0] as off.SendImage;
    expect(capturedImage.imageField, equals(off.ImageField.INGREDIENTS));
    expect(capturedImage.imageUri, equals(Uri.file("/tmp/img2.jpg")));
    expect(capturedImage.barcode, equals("123"));
    expect(capturedImage.lang, equals(off.OpenFoodFactsLanguage.RUSSIAN));

    // Only 1 image
    expect(allImages.length, equals(1));
  });

  test('ingredients extraction successful', () async {
    final product = Product((v) => v
      ..barcode = "123"
      ..name = "name"
      ..imageIngredients = Uri.file("/tmp/img2.jpg"));

    when(offApi.extractIngredients(any, any, any)).thenAnswer((_) async =>
        off.OcrIngredientsResult(
          status: 0,
          ingredientsTextFromImage: "lemon, water"));

    final result = await productsManager.updateProductAndExtractIngredients(product, "ru");
    expect(result!.ingredients, equals("lemon, water"));
  });

  test('ingredients extraction with product update fail', () async {
    when(offApi.extractIngredients(any, any, any)).thenAnswer((_) async =>
        off.OcrIngredientsResult(
            status: 0,
            ingredientsTextFromImage: "lemon, water"));

    when(offApi.saveProduct(any, any)).thenAnswer((_) async => off.Status(error: "oops"));

    final product = Product((v) => v
      ..barcode = "123"
      ..name = "name"
      ..imageIngredients = Uri.file("/tmp/img2.jpg"));

    final result = await productsManager.updateProductAndExtractIngredients(product, "ru");
    expect(result, isNull);
  });

  test('ingredients extraction fail', () async {
    final product = Product((v) => v
      ..barcode = "123"
      ..name = "name"
      ..imageIngredients = Uri.file("/tmp/img2.jpg"));

    when(offApi.extractIngredients(any, any, any)).thenAnswer((_) async =>
        off.OcrIngredientsResult(status: 1));

    final result = await productsManager.updateProductAndExtractIngredients(product, "ru");
    expect(result!.product, isNotNull);
    expect(result.ingredients, isNull);
  });
}
