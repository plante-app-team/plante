import 'dart:io';

import 'package:built_collection/built_collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:plante/base/result.dart';
import 'package:plante/model/product.dart';
import 'package:plante/model/veg_status.dart';
import 'package:plante/model/veg_status_source.dart';
import 'package:plante/outside/products/products_manager.dart';
import 'package:plante/outside/products/products_manager_error.dart';
import 'package:plante/ui/photos_taker.dart';
import 'package:plante/ui/product/init_product_page.dart';

import '../../widget_tester_extension.dart';
import 'init_product_page_test.mocks.dart';

@GenerateMocks([ProductsManager, PhotosTaker])
void main() {
  late MockPhotosTaker photosTaker;
  late MockProductsManager productsManager;

  setUp(() async {
    await GetIt.I.reset();

    photosTaker = MockPhotosTaker();
    when(photosTaker.takeAndCropPhoto(any)).thenAnswer((_) async =>
        Uri.file(File('./test/assets/img.jpg').absolute.path));
    GetIt.I.registerSingleton<PhotosTaker>(photosTaker);

    productsManager = MockProductsManager();
    when(productsManager.createUpdateProduct(any, any)).thenAnswer(
            (invoc) async => Ok(invoc.positionalArguments[0] as Product));
    when(productsManager.updateProductAndExtractIngredients(any, any))
        .thenAnswer((_) async => Err(ProductsManagerError.OTHER));
    GetIt.I.registerSingleton<ProductsManager>(productsManager);
  });

  Future<void> scrollToBottom(WidgetTester tester) async {
    await tester.drag(find.byKey(Key('content')), Offset(0, -3000));
    await tester.pumpAndSettle();
  }

  Future<bool> generalTest(
      WidgetTester tester,
      {Product? expectedProductResult,
        String? nameInput = 'Lemon drink',
        String? brandInput = 'Nice brand',
        String? categoriesInput = 'Nice, category',
        bool takeImageFront = true,
        bool takeImageIngredients = true,
        String? ingredientsTextOverride,
        VegStatus? veganStatusInput = VegStatus.possible,
        VegStatus? vegetarianStatusInput = VegStatus.possible}) async {
    when(productsManager.updateProductAndExtractIngredients(any, any)).thenAnswer(
            (invoc) async => Ok(ProductWithOCRIngredients(
            invoc.positionalArguments[0] as Product,
            'water, lemon')));

    verifyZeroInteractions(productsManager);

    bool done = false;
    final callback = () {
      done = true;
    };
    await tester.superPump(InitProductPage(
        Product((v) => v.barcode = '123'),
        doneCallback: callback));

    if (nameInput != null) {
      await tester.enterText(
          find.byKey(Key('name')),
          nameInput);
      await tester.pumpAndSettle();
    }

    if (brandInput != null) {
      await tester.enterText(
          find.byKey(Key('brand')),
          brandInput);
      await tester.pumpAndSettle();
    }

    if (categoriesInput != null) {
      await tester.enterText(
          find.byKey(Key('categories')),
          categoriesInput);
      await tester.pumpAndSettle();
    }

    if (takeImageFront) {
      verifyNever(photosTaker.takeAndCropPhoto(any));
      await tester.tap(
          find.byKey(Key('front_photo')));
      verify(photosTaker.takeAndCropPhoto(any)).called(1);
      await tester.pumpAndSettle();
    }

    if (takeImageIngredients) {
      expect(find.text('water, lemon'), findsNothing);
      verifyNever(photosTaker.takeAndCropPhoto(any));
      await tester.tap(
          find.byKey(Key('ingredients_photo')));
      await tester.pumpAndSettle();
      expect(find.text('water, lemon'), findsOneWidget);
      verify(photosTaker.takeAndCropPhoto(any)).called(1);
    }

    if (ingredientsTextOverride != null) {
      await tester.enterText(
          find.byKey(Key('ingredients_text')),
          ingredientsTextOverride);
      await tester.pumpAndSettle();
    }

    await scrollToBottom(tester);

    if (veganStatusInput != null) {
      switch (veganStatusInput) {
        case VegStatus.positive:
          await tester.tap(find.byKey(Key('vegan_positive_btn')));
          break;
        case VegStatus.negative:
          await tester.tap(find.byKey(Key('vegan_negative_btn')));
          break;
        case VegStatus.possible:
          await tester.tap(find.byKey(Key('vegan_possible_btn')));
          break;
        case VegStatus.unknown:
          await tester.tap(find.byKey(Key('vegan_unknown_btn')));
          break;
        default:
          throw Error();
      }
      await tester.pumpAndSettle();
    }
    if (vegetarianStatusInput != null) {
      switch (vegetarianStatusInput) {
        case VegStatus.positive:
          await tester.tap(find.byKey(Key('vegetarian_positive_btn')));
          break;
        case VegStatus.negative:
          await tester.tap(find.byKey(Key('vegetarian_negative_btn')));
          break;
        case VegStatus.possible:
          await tester.tap(find.byKey(Key('vegetarian_possible_btn')));
          break;
        case VegStatus.unknown:
          await tester.tap(find.byKey(Key('vegetarian_unknown_btn')));
          break;
        default:
          throw Error();
      }
      await tester.pumpAndSettle();
    }

    expect(done, isFalse);
    verifyNever(productsManager.createUpdateProduct(any, any));
    await tester.tap(find.byKey(Key('done_btn')));
    await tester.pumpAndSettle();
    if (expectedProductResult != null) {
      final finalProduct = verify(
          productsManager.createUpdateProduct(captureAny, any)).captured.first;
      expect(finalProduct, equals(expectedProductResult));
    } else {
      verifyNever(productsManager.createUpdateProduct(captureAny, any));
    }

    return done;
  }

  testWidgets('good flow', (WidgetTester tester) async {
    final expectedProduct = Product((v) => v
      ..barcode = '123'
      ..name = 'Lemon drink'
      ..brands = ListBuilder<String>(['Nice brand'])
      ..categories = ListBuilder<String>(['Nice', 'category'])
      ..imageFront = Uri.file(File('./test/assets/img.jpg').absolute.path)
      ..imageIngredients = Uri.file(File('./test/assets/img.jpg').absolute.path)
      ..ingredientsText = 'water, lemon'
      ..vegetarianStatus = VegStatus.possible
      ..vegetarianStatusSource = VegStatusSource.community
      ..veganStatus = VegStatus.possible
      ..veganStatusSource = VegStatusSource.community);

    final done = await generalTest(
        tester,
        expectedProductResult: expectedProduct,
      nameInput: expectedProduct.name,
      brandInput: expectedProduct.brands!.join(', '),
      categoriesInput: expectedProduct.categories!.join(', '),
      takeImageFront: expectedProduct.imageFront != null,
      takeImageIngredients: expectedProduct.imageIngredients != null,
      veganStatusInput: expectedProduct.veganStatus,
      vegetarianStatusInput: expectedProduct.vegetarianStatus
    );

    expect(done, isTrue);
  });

  testWidgets('front photo not present when product has data', (WidgetTester tester) async {
    final initialProduct = Product((v) => v
      ..barcode = '123'
      ..imageFront = Uri.file(File('./test/assets/img.jpg').absolute.path));
    await tester.superPump(InitProductPage(initialProduct));

    expect(find.byKey(Key('front_photo_group')), findsNothing);
    expect(find.byKey(Key('name_group')), findsWidgets);
    expect(find.byKey(Key('brand_group')), findsWidgets);
    expect(find.byKey(Key('categories_group')), findsWidgets);
    expect(find.byKey(Key('ingredients_group')), findsWidgets);
    expect(find.byKey(Key('vegan_status_group')), findsWidgets);
    expect(find.byKey(Key('vegetarian_status_group')), findsWidgets);
  });

  testWidgets('name input field not present when product has data', (WidgetTester tester) async {
    final initialProduct = Product((v) => v
      ..barcode = '123'
      ..name = 'Hello there');
    await tester.superPump(InitProductPage(initialProduct));

    expect(find.byKey(Key('front_photo_group')), findsWidgets);
    expect(find.byKey(Key('name_group')), findsNothing);
    expect(find.byKey(Key('brand_group')), findsWidgets);
    expect(find.byKey(Key('categories_group')), findsWidgets);
    expect(find.byKey(Key('ingredients_group')), findsWidgets);
    expect(find.byKey(Key('vegan_status_group')), findsWidgets);
    expect(find.byKey(Key('vegetarian_status_group')), findsWidgets);
  });

  testWidgets('brand input field not present when product has data', (WidgetTester tester) async {
    final initialProduct = Product((v) => v
      ..barcode = '123'
      ..brands = ListBuilder<String>(['Cool brand']));
    await tester.superPump(InitProductPage(initialProduct));

    expect(find.byKey(Key('front_photo_group')), findsWidgets);
    expect(find.byKey(Key('name_group')), findsWidgets);
    expect(find.byKey(Key('brand_group')), findsNothing);
    expect(find.byKey(Key('categories_group')), findsWidgets);
    expect(find.byKey(Key('ingredients_group')), findsWidgets);
    expect(find.byKey(Key('vegan_status_group')), findsWidgets);
    expect(find.byKey(Key('vegetarian_status_group')), findsWidgets);
  });

  testWidgets('categories input field not present when product has data', (WidgetTester tester) async {
    final initialProduct = Product((v) => v
      ..barcode = '123'
      ..categories = ListBuilder<String>(['Cool category']));
    await tester.superPump(InitProductPage(initialProduct));

    expect(find.byKey(Key('front_photo_group')), findsWidgets);
    expect(find.byKey(Key('name_group')), findsWidgets);
    expect(find.byKey(Key('brand_group')), findsWidgets);
    expect(find.byKey(Key('categories_group')), findsNothing);
    expect(find.byKey(Key('ingredients_group')), findsWidgets);
    expect(find.byKey(Key('vegan_status_group')), findsWidgets);
    expect(find.byKey(Key('vegetarian_status_group')), findsWidgets);
  });

  testWidgets('ingredients group not present when product has data', (WidgetTester tester) async {
    final initialProduct = Product((v) => v
      ..barcode = '123'
      ..imageIngredients = Uri.file(File('./test/assets/img.jpg').absolute.path)
      ..ingredientsText = 'Tomato');
    await tester.superPump(InitProductPage(initialProduct));

    expect(find.byKey(Key('front_photo_group')), findsWidgets);
    expect(find.byKey(Key('name_group')), findsWidgets);
    expect(find.byKey(Key('brand_group')), findsWidgets);
    expect(find.byKey(Key('categories_group')), findsWidgets);
    expect(find.byKey(Key('ingredients_group')), findsNothing);
    expect(find.byKey(Key('vegan_status_group')), findsWidgets);
    expect(find.byKey(Key('vegetarian_status_group')), findsWidgets);
  });

  testWidgets('ingredients group present when product has no ingredients image but has text', (WidgetTester tester) async {
    final initialProduct = Product((v) => v
      ..barcode = '123'
      ..ingredientsText = 'Tomato');
    await tester.superPump(InitProductPage(initialProduct));

    expect(find.byKey(Key('front_photo_group')), findsWidgets);
    expect(find.byKey(Key('name_group')), findsWidgets);
    expect(find.byKey(Key('brand_group')), findsWidgets);
    expect(find.byKey(Key('categories_group')), findsWidgets);
    expect(find.byKey(Key('ingredients_group')), findsWidgets);
    expect(find.byKey(Key('vegan_status_group')), findsWidgets);
    expect(find.byKey(Key('vegetarian_status_group')), findsWidgets);
  });

  testWidgets('ingredients group present when product has no ingredients text but has image', (WidgetTester tester) async {
    final initialProduct = Product((v) => v
      ..barcode = '123'
      ..imageIngredients = Uri.file(File('./test/assets/img.jpg').absolute.path));
    await tester.superPump(InitProductPage(initialProduct));

    expect(find.byKey(Key('front_photo_group')), findsWidgets);
    expect(find.byKey(Key('name_group')), findsWidgets);
    expect(find.byKey(Key('brand_group')), findsWidgets);
    expect(find.byKey(Key('categories_group')), findsWidgets);
    expect(find.byKey(Key('ingredients_group')), findsWidgets);
    expect(find.byKey(Key('vegan_status_group')), findsWidgets);
    expect(find.byKey(Key('vegetarian_status_group')), findsWidgets);
  });

  testWidgets('vegan group not present when product has data', (WidgetTester tester) async {
    final initialProduct = Product((v) => v
      ..barcode = '123'
      ..veganStatus = VegStatus.positive
      ..veganStatusSource = VegStatusSource.community);
    await tester.superPump(InitProductPage(initialProduct));

    expect(find.byKey(Key('front_photo_group')), findsWidgets);
    expect(find.byKey(Key('name_group')), findsWidgets);
    expect(find.byKey(Key('brand_group')), findsWidgets);
    expect(find.byKey(Key('categories_group')), findsWidgets);
    expect(find.byKey(Key('ingredients_group')), findsWidgets);
    expect(find.byKey(Key('vegan_status_group')), findsNothing);
    expect(find.byKey(Key('vegetarian_status_group')), findsWidgets);
  });

  testWidgets('vegan group present when product has vegan data from OFF', (WidgetTester tester) async {
    final initialProduct = Product((v) => v
      ..barcode = '123'
      ..veganStatus = VegStatus.positive
      ..veganStatusSource = VegStatusSource.open_food_facts);
    await tester.superPump(InitProductPage(initialProduct));

    expect(find.byKey(Key('front_photo_group')), findsWidgets);
    expect(find.byKey(Key('name_group')), findsWidgets);
    expect(find.byKey(Key('brand_group')), findsWidgets);
    expect(find.byKey(Key('categories_group')), findsWidgets);
    expect(find.byKey(Key('ingredients_group')), findsWidgets);
    expect(find.byKey(Key('vegan_status_group')), findsWidgets);
    expect(find.byKey(Key('vegetarian_status_group')), findsWidgets);
  });

  testWidgets('vegan group present when product has vegan data without source', (WidgetTester tester) async {
    final initialProduct = Product((v) => v
      ..barcode = '123'
      ..veganStatus = VegStatus.positive);
    await tester.superPump(InitProductPage(initialProduct));

    expect(find.byKey(Key('front_photo_group')), findsWidgets);
    expect(find.byKey(Key('name_group')), findsWidgets);
    expect(find.byKey(Key('brand_group')), findsWidgets);
    expect(find.byKey(Key('categories_group')), findsWidgets);
    expect(find.byKey(Key('ingredients_group')), findsWidgets);
    expect(find.byKey(Key('vegan_status_group')), findsWidgets);
    expect(find.byKey(Key('vegetarian_status_group')), findsWidgets);
  });

  testWidgets('vegetarian group not present when product has data', (WidgetTester tester) async {
    final initialProduct = Product((v) => v
      ..barcode = '123'
      ..vegetarianStatus = VegStatus.positive
      ..vegetarianStatusSource = VegStatusSource.community);
    await tester.superPump(InitProductPage(initialProduct));

    expect(find.byKey(Key('front_photo_group')), findsWidgets);
    expect(find.byKey(Key('name_group')), findsWidgets);
    expect(find.byKey(Key('brand_group')), findsWidgets);
    expect(find.byKey(Key('categories_group')), findsWidgets);
    expect(find.byKey(Key('ingredients_group')), findsWidgets);
    expect(find.byKey(Key('vegan_status_group')), findsWidgets);
    expect(find.byKey(Key('vegetarian_status_group')), findsNothing);
  });

  testWidgets('vegetarian group present when product has vegetarian data from OFF', (WidgetTester tester) async {
    final initialProduct = Product((v) => v
      ..barcode = '123'
      ..vegetarianStatus = VegStatus.positive
      ..vegetarianStatusSource = VegStatusSource.open_food_facts);
    await tester.superPump(InitProductPage(initialProduct));

    expect(find.byKey(Key('front_photo_group')), findsWidgets);
    expect(find.byKey(Key('name_group')), findsWidgets);
    expect(find.byKey(Key('brand_group')), findsWidgets);
    expect(find.byKey(Key('categories_group')), findsWidgets);
    expect(find.byKey(Key('ingredients_group')), findsWidgets);
    expect(find.byKey(Key('vegan_status_group')), findsWidgets);
    expect(find.byKey(Key('vegetarian_status_group')), findsWidgets);
  });

  testWidgets('vegetarian group present when product has vegetarian data without source', (WidgetTester tester) async {
    final initialProduct = Product((v) => v
      ..barcode = '123'
      ..vegetarianStatus = VegStatus.positive);
    await tester.superPump(InitProductPage(initialProduct));

    expect(find.byKey(Key('front_photo_group')), findsWidgets);
    expect(find.byKey(Key('name_group')), findsWidgets);
    expect(find.byKey(Key('brand_group')), findsWidgets);
    expect(find.byKey(Key('categories_group')), findsWidgets);
    expect(find.byKey(Key('ingredients_group')), findsWidgets);
    expect(find.byKey(Key('vegan_status_group')), findsWidgets);
    expect(find.byKey(Key('vegetarian_status_group')), findsWidgets);
  });

  testWidgets('cannot save product without name', (WidgetTester tester) async {
    final done = await generalTest(tester, nameInput: null, expectedProductResult: null);
    expect(done, isFalse);
  });

  testWidgets('can save product without brand', (WidgetTester tester) async {
    final expectedProduct = Product((v) => v
      ..barcode = '123'
      ..name = 'Lemon drink'
      ..brands = null
      ..categories = ListBuilder<String>(['Nice', 'category'])
      ..imageFront = Uri.file(File('./test/assets/img.jpg').absolute.path)
      ..imageIngredients = Uri.file(File('./test/assets/img.jpg').absolute.path)
      ..ingredientsText = 'water, lemon'
      ..vegetarianStatus = VegStatus.possible
      ..vegetarianStatusSource = VegStatusSource.community
      ..veganStatus = VegStatus.possible
      ..veganStatusSource = VegStatusSource.community);

    final done = await generalTest(
        tester,
        expectedProductResult: expectedProduct,
        nameInput: expectedProduct.name,
        brandInput: null,
        categoriesInput: expectedProduct.categories!.join(', '),
        takeImageFront: expectedProduct.imageFront != null,
        takeImageIngredients: expectedProduct.imageIngredients != null,
        veganStatusInput: expectedProduct.veganStatus,
        vegetarianStatusInput: expectedProduct.vegetarianStatus
    );

    expect(done, isTrue);
  });

  testWidgets('can save product without categories', (WidgetTester tester) async {
    final expectedProduct = Product((v) => v
      ..barcode = '123'
      ..name = 'Lemon drink'
      ..brands = ListBuilder<String>(['Nice brand'])
      ..categories = null
      ..imageFront = Uri.file(File('./test/assets/img.jpg').absolute.path)
      ..imageIngredients = Uri.file(File('./test/assets/img.jpg').absolute.path)
      ..ingredientsText = 'water, lemon'
      ..vegetarianStatus = VegStatus.possible
      ..vegetarianStatusSource = VegStatusSource.community
      ..veganStatus = VegStatus.possible
      ..veganStatusSource = VegStatusSource.community);

    final done = await generalTest(
        tester,
        expectedProductResult: expectedProduct,
        nameInput: expectedProduct.name,
        brandInput: expectedProduct.brands!.join(', '),
        categoriesInput: null,
        takeImageFront: expectedProduct.imageFront != null,
        takeImageIngredients: expectedProduct.imageIngredients != null,
        veganStatusInput: expectedProduct.veganStatus,
        vegetarianStatusInput: expectedProduct.vegetarianStatus
    );

    expect(done, isTrue);
  });

  testWidgets('cannot save product without front image', (WidgetTester tester) async {
    final done = await generalTest(tester, takeImageFront: false, expectedProductResult: null);
    expect(done, isFalse);
  });

  testWidgets('cannot save product without ingredients image', (WidgetTester tester) async {
    final done = await generalTest(tester, takeImageIngredients: false, expectedProductResult: null);
    expect(done, isFalse);
  });

  testWidgets('cannot save product without ingredients text', (WidgetTester tester) async {
    final done = await generalTest(tester, ingredientsTextOverride: '', expectedProductResult: null);
    expect(done, isFalse);
  });

  testWidgets('cannot save product without vegan status', (WidgetTester tester) async {
    final done = await generalTest(
        tester,
        vegetarianStatusInput: VegStatus.positive,
        veganStatusInput: null,
        expectedProductResult: null);
    expect(done, isFalse);
  });

  testWidgets('cannot save product without vegetarian status', (WidgetTester tester) async {
    final done = await generalTest(tester, vegetarianStatusInput: null, expectedProductResult: null);
    expect(done, isFalse);
  });

  testWidgets('vegan positive makes vegetarian positive', (WidgetTester tester) async {
    final expectedProduct = Product((v) => v
      ..barcode = '123'
      ..name = 'Lemon drink'
      ..imageFront = Uri.file(File('./test/assets/img.jpg').absolute.path)
      ..imageIngredients = Uri.file(File('./test/assets/img.jpg').absolute.path)
      ..ingredientsText = 'water, lemon'
      ..veganStatus = VegStatus.positive
      ..veganStatusSource = VegStatusSource.community
      ..vegetarianStatus = VegStatus.positive // !!!!!!
      ..vegetarianStatusSource = VegStatusSource.community
      );

    final done = await generalTest(
        tester,
        brandInput: null,
        categoriesInput: null,
        expectedProductResult: expectedProduct,
        nameInput: expectedProduct.name,
        takeImageFront: expectedProduct.imageFront != null,
        takeImageIngredients: expectedProduct.imageIngredients != null,
        veganStatusInput: VegStatus.positive,
        vegetarianStatusInput: null // !!!!!!
    );

    expect(done, isTrue);
  });

  testWidgets('vegetarian negative makes vegan negative', (WidgetTester tester) async {
    final expectedProduct = Product((v) => v
      ..barcode = '123'
      ..name = 'Lemon drink'
      ..imageFront = Uri.file(File('./test/assets/img.jpg').absolute.path)
      ..imageIngredients = Uri.file(File('./test/assets/img.jpg').absolute.path)
      ..ingredientsText = 'water, lemon'
      ..vegetarianStatus = VegStatus.negative
      ..vegetarianStatusSource = VegStatusSource.community
      ..veganStatus = VegStatus.negative // !!!!!!
      ..veganStatusSource = VegStatusSource.community
    );

    final done = await generalTest(
        tester,
        brandInput: null,
        categoriesInput: null,
        expectedProductResult: expectedProduct,
        nameInput: expectedProduct.name,
        takeImageFront: expectedProduct.imageFront != null,
        takeImageIngredients: expectedProduct.imageIngredients != null,
        veganStatusInput: null, // !!!!!!
        vegetarianStatusInput: VegStatus.negative
    );

    expect(done, isTrue);
  });

  testWidgets('vegetarian possible makes vegan possible if it was positive', (WidgetTester tester) async {
    final expectedProduct = Product((v) => v
      ..barcode = '123'
      ..name = 'Lemon drink'
      ..imageFront = Uri.file(File('./test/assets/img.jpg').absolute.path)
      ..imageIngredients = Uri.file(File('./test/assets/img.jpg').absolute.path)
      ..ingredientsText = 'water, lemon'
      ..vegetarianStatus = VegStatus.possible
      ..vegetarianStatusSource = VegStatusSource.community
      ..veganStatus = VegStatus.possible // !!!!!!
      ..veganStatusSource = VegStatusSource.community
    );

    final done = await generalTest(
        tester,
        brandInput: null,
        categoriesInput: null,
        expectedProductResult: expectedProduct,
        nameInput: expectedProduct.name,
        takeImageFront: expectedProduct.imageFront != null,
        takeImageIngredients: expectedProduct.imageIngredients != null,
        veganStatusInput: VegStatus.positive, // !!!!!! positive input
        vegetarianStatusInput: VegStatus.possible
    );

    expect(done, isTrue);
  });

  testWidgets("vegetarian possible doesn't change vegan if was negative", (WidgetTester tester) async {
    final expectedProduct = Product((v) => v
      ..barcode = '123'
      ..name = 'Lemon drink'
      ..imageFront = Uri.file(File('./test/assets/img.jpg').absolute.path)
      ..imageIngredients = Uri.file(File('./test/assets/img.jpg').absolute.path)
      ..ingredientsText = 'water, lemon'
      ..vegetarianStatus = VegStatus.possible
      ..vegetarianStatusSource = VegStatusSource.community
      ..veganStatus = VegStatus.negative // !!!!!!
      ..veganStatusSource = VegStatusSource.community
    );

    final done = await generalTest(
        tester,
        brandInput: null,
        categoriesInput: null,
        expectedProductResult: expectedProduct,
        nameInput: expectedProduct.name,
        takeImageFront: expectedProduct.imageFront != null,
        takeImageIngredients: expectedProduct.imageIngredients != null,
        veganStatusInput: VegStatus.negative, // !!!!!! negative input
        vegetarianStatusInput: VegStatus.possible
    );

    expect(done, isTrue);
  });

  testWidgets("vegetarian possible doesn't change vegan if was unknown", (WidgetTester tester) async {
    final expectedProduct = Product((v) => v
      ..barcode = '123'
      ..name = 'Lemon drink'
      ..imageFront = Uri.file(File('./test/assets/img.jpg').absolute.path)
      ..imageIngredients = Uri.file(File('./test/assets/img.jpg').absolute.path)
      ..ingredientsText = 'water, lemon'
      ..vegetarianStatus = VegStatus.possible
      ..vegetarianStatusSource = VegStatusSource.community
      ..veganStatus = VegStatus.unknown // !!!!!!
      ..veganStatusSource = VegStatusSource.community
    );

    final done = await generalTest(
        tester,
        brandInput: null,
        categoriesInput: null,
        expectedProductResult: expectedProduct,
        nameInput: expectedProduct.name,
        takeImageFront: expectedProduct.imageFront != null,
        takeImageIngredients: expectedProduct.imageIngredients != null,
        veganStatusInput: VegStatus.unknown, // !!!!!! negative input
        vegetarianStatusInput: VegStatus.possible
    );

    expect(done, isTrue);
  });

  testWidgets('vegetarian unknown makes vegan unknown if it was positive', (WidgetTester tester) async {
    final expectedProduct = Product((v) => v
      ..barcode = '123'
      ..name = 'Lemon drink'
      ..imageFront = Uri.file(File('./test/assets/img.jpg').absolute.path)
      ..imageIngredients = Uri.file(File('./test/assets/img.jpg').absolute.path)
      ..ingredientsText = 'water, lemon'
      ..vegetarianStatus = VegStatus.unknown
      ..vegetarianStatusSource = VegStatusSource.community
      ..veganStatus = VegStatus.unknown // !!!!!!
      ..veganStatusSource = VegStatusSource.community
    );

    final done = await generalTest(
        tester,
        brandInput: null,
        categoriesInput: null,
        expectedProductResult: expectedProduct,
        nameInput: expectedProduct.name,
        takeImageFront: expectedProduct.imageFront != null,
        takeImageIngredients: expectedProduct.imageIngredients != null,
        veganStatusInput: VegStatus.positive, // !!!!!! positive input
        vegetarianStatusInput: VegStatus.unknown
    );

    expect(done, isTrue);
  });

  testWidgets('vegetarian unknown makes vegan unknown if it was possible', (WidgetTester tester) async {
    final expectedProduct = Product((v) => v
      ..barcode = '123'
      ..name = 'Lemon drink'
      ..imageFront = Uri.file(File('./test/assets/img.jpg').absolute.path)
      ..imageIngredients = Uri.file(File('./test/assets/img.jpg').absolute.path)
      ..ingredientsText = 'water, lemon'
      ..vegetarianStatus = VegStatus.unknown
      ..vegetarianStatusSource = VegStatusSource.community
      ..veganStatus = VegStatus.unknown // !!!!!!
      ..veganStatusSource = VegStatusSource.community
    );

    final done = await generalTest(
        tester,
        brandInput: null,
        categoriesInput: null,
        expectedProductResult: expectedProduct,
        nameInput: expectedProduct.name,
        takeImageFront: expectedProduct.imageFront != null,
        takeImageIngredients: expectedProduct.imageIngredients != null,
        veganStatusInput: VegStatus.possible, // !!!!!! positive input
        vegetarianStatusInput: VegStatus.unknown
    );

    expect(done, isTrue);
  });

  testWidgets("vegetarian unknown doesn't change vegan if was negative", (WidgetTester tester) async {
    final expectedProduct = Product((v) => v
      ..barcode = '123'
      ..name = 'Lemon drink'
      ..imageFront = Uri.file(File('./test/assets/img.jpg').absolute.path)
      ..imageIngredients = Uri.file(File('./test/assets/img.jpg').absolute.path)
      ..ingredientsText = 'water, lemon'
      ..vegetarianStatus = VegStatus.unknown
      ..vegetarianStatusSource = VegStatusSource.community
      ..veganStatus = VegStatus.negative // !!!!!!
      ..veganStatusSource = VegStatusSource.community
    );

    final done = await generalTest(
        tester,
        brandInput: null,
        categoriesInput: null,
        expectedProductResult: expectedProduct,
        nameInput: expectedProduct.name,
        takeImageFront: expectedProduct.imageFront != null,
        takeImageIngredients: expectedProduct.imageIngredients != null,
        veganStatusInput: VegStatus.negative, // !!!!!! negative input
        vegetarianStatusInput: VegStatus.unknown
    );

    expect(done, isTrue);
  });
}
