import 'dart:convert';

import 'package:built_collection/built_collection.dart';
import 'package:either_option/either_option.dart';
import 'package:openfoodfacts/model/OcrIngredientsResult.dart' as off;
import 'package:openfoodfacts/model/Product.dart' as off;
import 'package:openfoodfacts/openfoodfacts.dart' as off;

import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';
import 'package:untitled_vegan_app/model/ingredient.dart';
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
  final imagesJson = """
  {
   "front_ru":{
      "rev":"16",
      "sizes":{
         "400":{
            "h":400,
            "w":289
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
  """;
  final expectedImageFront = "https://static.openfoodfacts.org/images/products/123/front_ru.16.400.jpg";
  final expectedImageIngredients = "https://static.openfoodfacts.org/images/products/123/ingredients_ru.19.full.jpg";

  late MockOffApi offApi;
  late MockBackend backend;
  late ProductsManager productsManager;

  setUp(() {
    offApi = MockOffApi();
    backend = MockBackend();
    productsManager = ProductsManager(offApi, backend);

    when(offApi.saveProduct(any, any)).thenAnswer((_) async => off.Status());
    when(offApi.getProduct(any)).thenAnswer((_) async =>
        off.ProductResult(product: off.Product(barcode: "123")));
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
      "code": "123",
      "product_name_ru": "name",
      "brands_tags": ["Brand name"],
      "categories_tags_translated": ["plant", "lemon"],
      "ingredients_text_ru": "lemon, water",
      "images": jsonDecode(imagesJson),
    });
    off.ProductHelper.createImageUrls(offProduct);
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
      ..ingredientsText = "lemon, water"
      ..ingredientsAnalyzed.addAll([])
      ..imageFront = Uri.parse(expectedImageFront)
      ..imageIngredients = Uri.parse(expectedImageIngredients));
    expect(product, equals(expectedProduct));
  });

  test('get product when the product is on OFF only', () async {
    final offProduct = off.Product.fromJson({
      "code": "123",
      "product_name_ru": "name",
      "brands_tags": ["Brand name"],
      "categories_tags_translated": ["plant", "lemon"],
      "ingredients_text_ru": "lemon, water",
      "images": jsonDecode(imagesJson),
    });
    off.ProductHelper.createImageUrls(offProduct);
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
      ..ingredientsText = "lemon, water"
      ..ingredientsAnalyzed.addAll([])
      ..imageFront = Uri.parse(expectedImageFront)
      ..imageIngredients = Uri.parse(expectedImageIngredients));
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
      ..ingredientsText = "lemon, water"
      ..imageFront = Uri.file("/tmp/img1.jpg")
      ..imageIngredients = Uri.file("/tmp/img2.jpg"));

    verifyZeroInteractions(offApi);
    verifyZeroInteractions(backend);

    await productsManager.createUpdateProduct(product, "ru");

    // Off Product
    final capturedOffProduct = verify(offApi.saveProduct(any, captureAny))
        .captured.first as off.Product;
    expect(capturedOffProduct.barcode, equals("123"));
    expect(capturedOffProduct.productName, isNull);
    expect(capturedOffProduct.productNameTranslated, equals("name"));
    expect(capturedOffProduct.brands, equals("Brand name"));
    expect(capturedOffProduct.categories, equals("ru:plant, ru:lemon"));
    expect(capturedOffProduct.ingredientsText, isNull);
    expect(capturedOffProduct.ingredientsTextTranslated, equals("lemon, water"));

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
      ..ingredientsText = "lemon, water");

    verifyZeroInteractions(offApi);
    verifyZeroInteractions(backend);

    await productsManager.createUpdateProduct(product, "ru");

    // Off Product
    final capturedOffProduct = verify(offApi.saveProduct(any, captureAny))
        .captured.first as off.Product;
    expect(capturedOffProduct.barcode, equals("123"));
    expect(capturedOffProduct.productName, isNull);
    expect(capturedOffProduct.productNameTranslated, equals("name"));
    expect(capturedOffProduct.brands, equals("Brand name"));
    expect(capturedOffProduct.categories, equals("ru:plant, ru:lemon"));
    expect(capturedOffProduct.ingredientsText, isNull);
    expect(capturedOffProduct.ingredientsTextTranslated, equals("lemon, water"));

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
      ..ingredientsText = "lemon, water"
      ..imageFront = Uri.file("/tmp/img1.jpg"));

    verifyZeroInteractions(offApi);
    verifyZeroInteractions(backend);

    await productsManager.createUpdateProduct(product, "ru");

    // Off Product
    final capturedOffProduct = verify(offApi.saveProduct(any, captureAny))
        .captured.first as off.Product;
    expect(capturedOffProduct.barcode, equals("123"));
    expect(capturedOffProduct.productName, isNull);
    expect(capturedOffProduct.productNameTranslated, equals("name"));
    expect(capturedOffProduct.brands, equals("Brand name"));
    expect(capturedOffProduct.categories, equals("ru:plant, ru:lemon"));
    expect(capturedOffProduct.ingredientsText, isNull);
    expect(capturedOffProduct.ingredientsTextTranslated, equals("lemon, water"));

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
      ..ingredientsText = "lemon, water"
      ..imageIngredients = Uri.file("/tmp/img2.jpg"));

    verifyZeroInteractions(offApi);
    verifyZeroInteractions(backend);

    await productsManager.createUpdateProduct(product, "ru");

    // Off Product
    final capturedOffProduct = verify(offApi.saveProduct(any, captureAny))
        .captured.first as off.Product;
    expect(capturedOffProduct.barcode, equals("123"));
    expect(capturedOffProduct.productName, isNull);
    expect(capturedOffProduct.productNameTranslated, equals("name"));
    expect(capturedOffProduct.brands, equals("Brand name"));
    expect(capturedOffProduct.categories, equals("ru:plant, ru:lemon"));
    expect(capturedOffProduct.ingredientsText, isNull);
    expect(capturedOffProduct.ingredientsTextTranslated, equals("lemon, water"));

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

  test('barcode from off is used', () async {
    final badBarcode = "0000000000123";
    final goodBarcode = "123";
    when(offApi.getProduct(any)).thenAnswer((_) async =>
        off.ProductResult(product: off.Product.fromJson({
          "code": goodBarcode,
          "product_name_ru": "name"
        })));

    final product = await productsManager.getProduct(badBarcode, "ru");

    // Verify received product
    expect(product!.barcode, equals(goodBarcode));
    // Verify good barcode is asked from the backed
    verify(backend.requestProduct(goodBarcode)).called(1);
  });

  test('brands and categories are not sent when they are empty', () async {
    final product = Product((v) => v
      ..barcode = "123"
      ..brands.addAll([])
      ..categories.addAll([]));

    await productsManager.createUpdateProduct(product, "ru");
    final capturedOffProduct = verify(offApi.saveProduct(any, captureAny))
        .captured.first as off.Product;
    expect(capturedOffProduct.brands, isNull);
    expect(capturedOffProduct.categories, isNull);
  });

  test('international OFF product fields are not used', () async {
    final offProduct = off.Product.fromJson({
      "code": "123",
      "product_name": "name",
      "categories_tags": ["plant", "lemon"],
      "ingredients_text": "lemon, water"
    });
    when(offApi.getProduct(any)).thenAnswer((_) async =>
        off.ProductResult(product: offProduct));

    when(backend.requestProduct(any)).thenAnswer((_) async => null);

    final product = await productsManager.getProduct("123", "ru");
    final expectedProduct = Product((v) => v
      ..barcode = "123"
      ..name = null
      ..brands.addAll([])
      ..categories.addAll([])
      ..ingredientsAnalyzed.addAll([])
      ..ingredientsText = null);
    expect(product, equals(expectedProduct));
  });

  test('not translated OFF tags get and save behaviour', () async {
    final offProduct = off.Product.fromJson({
      "code": "123",
      "brands_tags": ["brand1", "en:brand2"],
      "categories_tags_ru": ["category1", "en:category2"],
    });
    when(offApi.getProduct(any)).thenAnswer((_) async =>
        off.ProductResult(product: offProduct));

    when(backend.requestProduct(any)).thenAnswer((_) async => null);

    final product = await productsManager.getProduct("123", "ru");
    // We expect the 'en' values to be excluded
    final expectedInitialProduct = Product((v) => v
      ..barcode = "123"
      ..brands.addAll(["brand1"])
      ..categories.addAll(["category1"])
      ..ingredientsAnalyzed.addAll([])
      ..ingredientsText = null);
    expect(product, equals(expectedInitialProduct));

    final updatedProduct = product!.rebuild((v) => v
      ..brands.add("brand3")
      ..categories.add("category3"));
    productsManager.createUpdateProduct(updatedProduct, "ru");

    final capturedOffProduct = verify(offApi.saveProduct(any, captureAny))
        .captured.first as off.Product;
    // We expected the 'en' value to be included back
    expect(capturedOffProduct.brands, equals("brand1, brand3, en:brand2"));
    expect(capturedOffProduct.categories, equals("ru:category1, ru:category3, en:category2"));
  });

  test('translated OFF tags order on re-save does not matter', () async {
    final offProduct1 = off.Product.fromJson({
      "code": "123",
      "brands_tags": ["brand1", "en:brand2"],
      "categories_tags_ru": ["category1", "en:category2"],
    });
    when(offApi.getProduct(any)).thenAnswer((_) async =>
        off.ProductResult(product: offProduct1));
    when(backend.requestProduct(any)).thenAnswer((_) async => null);

    final product = await productsManager.getProduct("123", "ru");

    // Order 1
    productsManager.createUpdateProduct(
        product!.rebuild((v) => v
          ..brands.addAll(["brand3", "brand4"])
          ..categories.addAll(["category3", "category4"])),
        "ru");
    var capturedOffProduct = verify(offApi.saveProduct(any, captureAny))
        .captured.first as off.Product;
    expect(capturedOffProduct.brands, equals("brand1, brand3, brand4, en:brand2"));
    expect(capturedOffProduct.categories, equals("ru:category1, ru:category3, ru:category4, en:category2"));

    // Order 2, still expected same brands and products
    productsManager.createUpdateProduct(
        product.rebuild((v) => v
          ..brands.addAll(["brand4", "brand3"])
          ..categories.addAll(["category4", "category3"])),
        "ru");
    capturedOffProduct = verify(offApi.saveProduct(any, captureAny))
        .captured.first as off.Product;
    expect(capturedOffProduct.brands, equals("brand1, brand3, brand4, en:brand2"));
    expect(capturedOffProduct.categories, equals("ru:category1, ru:category3, ru:category4, en:category2"));
  });

  test('unchanged product is not sent to OFF or backend on re-save', () async {
    final offProduct = off.Product.fromJson({
      "code": "123",
      "brands_tags": ["brand1", "en:brand2"],
      "categories_tags_ru": ["category1", "en:category2"],
    });
    when(offApi.getProduct(any)).thenAnswer((_) async =>
        off.ProductResult(product: offProduct));

    when(backend.requestProduct(any)).thenAnswer((_) async => null);

    final product = await productsManager.getProduct("123", "ru");

    // Send the product back without changing it
    productsManager.createUpdateProduct(product!, "ru");

    // Ensure the product was not sent anywhere because it's not changed
    verifyNever(offApi.saveProduct(any, captureAny));
    verifyNever(backend.createUpdateProduct(any));
  });

  test('product considered unchanged even on OFF tags field reordering', () async {
    final offProduct = off.Product.fromJson({
      "code": "123",
      "brands_tags": ["brand1", "brand2"],
      "categories_tags_ru": ["category1", "category2"],
    });
    when(offApi.getProduct(any)).thenAnswer((_) async =>
        off.ProductResult(product: offProduct));

    when(backend.requestProduct(any)).thenAnswer((_) async => null);

    final product = await productsManager.getProduct("123", "ru");
    expect(product!.brands!.length, equals(2));
    expect(product.categories!.length, equals(2));

    // Send the product back with reordered tags
    final productReordered = product.rebuild((v) => v
      ..brands.replace(product.brands!.reversed)
      ..categories.replace(product.categories!.reversed));
    productsManager.createUpdateProduct(productReordered, "ru");

    // Ensure the product was not sent anywhere because it's actually same
    verifyNever(offApi.saveProduct(any, captureAny));
    verifyNever(backend.createUpdateProduct(any));
  });

  test('off ingredients analysis parsing', () async {
    final offProduct = off.Product.fromJson({
      "code": "123",
      "ingredients_text_ru": "water",
      "ingredients": [
        {
          "vegan": "maybe",
          "vegetarian": "yes",
          "text": "water"
        }
      ]
    });
    off.ProductHelper.createImageUrls(offProduct);
    when(offApi.getProduct(any)).thenAnswer((_) async =>
        off.ProductResult(product: offProduct));

    final product = await productsManager.getProduct("123", "ru");
    expect(product!.ingredientsAnalyzed, equals(BuiltList<Ingredient>([Ingredient((v) => v
      ..name = "water"
      ..vegetarianStatus = VegStatus.positive
      ..veganStatus = VegStatus.possible)])));
  });

  test('off ingredients analysis is not used when ingredients text is not provided', () async {
    final offProduct = off.Product.fromJson({
      "code": "123",
      "ingredients_text_ru": null,
      "ingredients": [
        {
          "vegan": "maybe",
          "vegetarian": "yes",
          "text": "water"
        }
      ]
    });
    off.ProductHelper.createImageUrls(offProduct);
    when(offApi.getProduct(any)).thenAnswer((_) async =>
        off.ProductResult(product: offProduct));

    final product = await productsManager.getProduct("123", "ru");
    expect(product!.ingredientsAnalyzed, BuiltList<Ingredient>());
  });

  test('if vegetarian status exists both on backend and OFF then '
      'from backend is used', () async {
    final offProduct = off.Product.fromJson({
      "code": "123",
      "ingredients_text_ru": "water",
      "ingredients": [
        {
          "vegan": "maybe",
          "vegetarian": "yes",
          "text": "water"
        }
      ]
    });
    off.ProductHelper.createImageUrls(offProduct);
    when(offApi.getProduct(any)).thenAnswer((_) async =>
        off.ProductResult(product: offProduct));

    final backendProduct = BackendProduct((v) => v
      ..barcode = "123"
      ..vegetarianStatus = VegStatus.unknown.name
      ..vegetarianStatusSource = VegStatusSource.community.name);
    when(backend.requestProduct(any)).thenAnswer((_) async => backendProduct);

    final product = await productsManager.getProduct("123", "ru");
    expect(product!.vegetarianStatus, equals(VegStatus.unknown));
    expect(product.vegetarianStatusSource, equals(VegStatusSource.community));
    expect(product.veganStatus, equals(VegStatus.possible));
    expect(product.veganStatusSource, equals(VegStatusSource.open_food_facts));
  });

  test('if vegan status exists both on backend and OFF then '
      'from backend is used', () async {
    final offProduct = off.Product.fromJson({
      "code": "123",
      "ingredients_text_ru": "water",
      "ingredients": [
        {
          "vegan": "maybe",
          "vegetarian": "yes",
          "text": "water"
        }
      ]
    });
    off.ProductHelper.createImageUrls(offProduct);
    when(offApi.getProduct(any)).thenAnswer((_) async =>
        off.ProductResult(product: offProduct));

    final backendProduct = BackendProduct((v) => v
      ..barcode = "123"
      ..veganStatus = VegStatus.negative.name
      ..veganStatusSource = VegStatusSource.moderator.name);
    when(backend.requestProduct(any)).thenAnswer((_) async => backendProduct);

    final product = await productsManager.getProduct("123", "ru");
    expect(product!.vegetarianStatus, equals(VegStatus.positive));
    expect(product.vegetarianStatusSource, equals(VegStatusSource.open_food_facts));
    expect(product.veganStatus, equals(VegStatus.negative));
    expect(product.veganStatusSource, equals(VegStatusSource.moderator));
  });

  test('invalid veg statuses from server are treated as community', () async {
    final offProduct = off.Product.fromJson({"code": "123"});
    off.ProductHelper.createImageUrls(offProduct);
    when(offApi.getProduct(any)).thenAnswer((_) async =>
        off.ProductResult(product: offProduct));

    final backendProduct = BackendProduct((v) => v
      ..barcode = "123"
      ..vegetarianStatus = VegStatus.negative.name
      ..vegetarianStatusSource = VegStatusSource.moderator.name + "woop"
      ..veganStatus = VegStatus.negative.name
      ..veganStatusSource = VegStatusSource.moderator.name + "woop");
    when(backend.requestProduct(any)).thenAnswer((_) async => backendProduct);

    final product = await productsManager.getProduct("123", "ru");
    expect(product!.vegetarianStatus, equals(VegStatus.negative));
    expect(product.vegetarianStatusSource, equals(VegStatusSource.community));
    expect(product.veganStatus, equals(VegStatus.negative));
    expect(product.veganStatusSource, equals(VegStatusSource.community));
  });

  test('invalid veg statuses from server are treated as if they do not exist', () async {
    final offProduct = off.Product.fromJson({"code": "123"});
    off.ProductHelper.createImageUrls(offProduct);
    when(offApi.getProduct(any)).thenAnswer((_) async =>
        off.ProductResult(product: offProduct));

    final backendProduct = BackendProduct((v) => v
      ..barcode = "123"
      ..vegetarianStatus = VegStatus.negative.name + "woop"
      ..vegetarianStatusSource = VegStatusSource.moderator.name
      ..veganStatus = VegStatus.negative.name + "woop"
      ..veganStatusSource = VegStatusSource.moderator.name);
    when(backend.requestProduct(any)).thenAnswer((_) async => backendProduct);

    final product = await productsManager.getProduct("123", "ru");
    expect(product!.vegetarianStatus, isNull);
    expect(product.veganStatus, isNull);
  });

  test('invalid veg statuses from server are treated as if they do not exist', () async {
    final offProduct = off.Product.fromJson({"code": "123"});
    off.ProductHelper.createImageUrls(offProduct);
    when(offApi.getProduct(any)).thenAnswer((_) async =>
        off.ProductResult(product: offProduct));

    final backendProduct = BackendProduct((v) => v
      ..barcode = "123"
      ..vegetarianStatus = VegStatus.negative.name + "woop"
      ..vegetarianStatusSource = VegStatusSource.moderator.name
      ..veganStatus = VegStatus.negative.name + "woop"
      ..veganStatusSource = VegStatusSource.moderator.name);
    when(backend.requestProduct(any)).thenAnswer((_) async => backendProduct);

    final product = await productsManager.getProduct("123", "ru");
    expect(product!.vegetarianStatus, isNull);
    expect(product.veganStatus, isNull);
  });

  test('if backend veg statuses parsing failed then analysis is used', () async {
    final offProduct = off.Product.fromJson({
      "code": "123",
      "ingredients_text_ru": "water",
      "ingredients": [
        {
          "vegan": "maybe",
          "vegetarian": "yes",
          "text": "water"
        }
      ]
    });
    off.ProductHelper.createImageUrls(offProduct);
    when(offApi.getProduct(any)).thenAnswer((_) async =>
        off.ProductResult(product: offProduct));

    final backendProduct = BackendProduct((v) => v
      ..barcode = "123"
      ..vegetarianStatus = VegStatus.negative.name + "woop"
      ..vegetarianStatusSource = VegStatusSource.moderator.name
      ..veganStatus = VegStatus.negative.name + "woop"
      ..veganStatusSource = VegStatusSource.moderator.name);
    when(backend.requestProduct(any)).thenAnswer((_) async => backendProduct);

    final product = await productsManager.getProduct("123", "ru");
    expect(product!.vegetarianStatus, VegStatus.positive);
    expect(product.vegetarianStatusSource, VegStatusSource.open_food_facts);
    expect(product.veganStatus, VegStatus.possible);
    expect(product.veganStatusSource, VegStatusSource.open_food_facts);
  });
}
