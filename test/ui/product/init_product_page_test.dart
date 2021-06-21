import 'dart:io';

import 'package:built_collection/built_collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:plante/base/permissions_manager.dart';
import 'package:plante/base/result.dart';
import 'package:plante/location/location_controller.dart';
import 'package:plante/model/product.dart';
import 'package:plante/model/shop.dart';
import 'package:plante/model/user_params_controller.dart';
import 'package:plante/model/veg_status.dart';
import 'package:plante/model/veg_status_source.dart';
import 'package:plante/outside/backend/backend_shop.dart';
import 'package:plante/outside/map/osm_shop.dart';
import 'package:plante/outside/map/shops_manager.dart';
import 'package:plante/outside/map/shops_manager_types.dart';
import 'package:plante/outside/products/products_manager.dart';
import 'package:plante/outside/products/products_manager_error.dart';
import 'package:plante/ui/map/latest_camera_pos_storage.dart';
import 'package:plante/ui/map/map_page.dart';
import 'package:plante/ui/photos_taker.dart';
import 'package:plante/ui/product/init_product_page.dart';
import 'package:plante/l10n/strings.dart';

import '../../fake_shared_preferences.dart';
import '../../fake_user_params_controller.dart';
import '../../widget_tester_extension.dart';
import 'init_product_page_test.mocks.dart';

@GenerateMocks([ProductsManager, PhotosTaker, ShopsManager, LocationController,
                PermissionsManager])
void main() {
  late MockPhotosTaker photosTaker;
  late MockProductsManager productsManager;
  late MockShopsManager shopsManager;
  late MockLocationController locationController;

  final aShop = Shop((e) => e
    ..osmShop.replace(OsmShop((e) => e
      ..osmId = '1'
      ..longitude = 11
      ..latitude = 11
      ..name = 'Spar'))
    ..backendShop.replace(BackendShop((e) => e
      ..osmId = '1'
      ..productsCount = 2)));

  setUp(() async {
    await GetIt.I.reset();

    photosTaker = MockPhotosTaker();
    when(photosTaker.takeAndCropPhoto(any, any)).thenAnswer((_) async =>
        Uri.file(File('./test/assets/img.jpg').absolute.path));
    when(photosTaker.cropPhoto(any, any, any)).thenAnswer((_) async =>
        Uri.file(File('./test/assets/img.jpg').absolute.path));
    when(photosTaker.retrieveLostPhoto()).thenAnswer((realInvocation) async => null);
    GetIt.I.registerSingleton<PhotosTaker>(photosTaker);

    productsManager = MockProductsManager();
    when(productsManager.createUpdateProduct(any, any)).thenAnswer(
            (invoc) async => Ok(invoc.positionalArguments[0] as Product));
    when(productsManager.updateProductAndExtractIngredients(any, any))
        .thenAnswer((_) async => Err(ProductsManagerError.OTHER));
    GetIt.I.registerSingleton<ProductsManager>(productsManager);

    shopsManager = MockShopsManager();
    GetIt.I.registerSingleton<ShopsManager>(shopsManager);
    when(shopsManager.putProductToShops(any, any)).thenAnswer((_) async => Ok(None()));

    GetIt.I.registerSingleton<UserParamsController>(FakeUserParamsController());

    locationController = MockLocationController();
    when(locationController.lastKnownPositionInstant()).thenReturn(null);
    when(locationController.lastKnownPosition()).thenAnswer((_) async => null);
    GetIt.I.registerSingleton<LocationController>(locationController);

    GetIt.I.registerSingleton<PermissionsManager>(MockPermissionsManager());

    GetIt.I.registerSingleton<LatestCameraPosStorage>(
        LatestCameraPosStorage(FakeSharedPreferences().asHolder()));
  });

  Future<void> scrollToBottom(WidgetTester tester) async {
    await tester.drag(find.byKey(const Key('content')), const Offset(0, -3000));
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
        VegStatus? veganStatusInput = VegStatus.positive,
        VegStatus? vegetarianStatusInput = VegStatus.positive,
        List<Shop>? selectedShops,
        List<Shop> initialShops = const [],
        List<Shop> shopsToCancel = const [],
        int requiredManualOcrAttempts = 0,
        int ocrSuccessfulAttemptNumber = 1}) async {
    var ocrAttempts = 0;
    when(productsManager.updateProductAndExtractIngredients(any, any)).thenAnswer(
            (invoc) async {
              ocrAttempts += 1;
              if (ocrAttempts < ocrSuccessfulAttemptNumber) {
                return Err(ProductsManagerError.OTHER);
              }
              return Ok(ProductWithOCRIngredients(
                invoc.positionalArguments[0] as Product,
                'water, lemon'));
            });

    verifyZeroInteractions(productsManager);

    bool done = false;
    final callback = () {
      done = true;
    };

    final widget = InitProductPage(
        Product((v) => v.barcode = '123'),
        doneCallback: callback,
        initialShops: initialShops);

    final cacheDir = await widget.cacheDir();
    if (cacheDir.existsSync()) {
      cacheDir.deleteSync();
    }
    expect(cacheDir.existsSync(), isFalse);

    final context = await tester.superPump(widget);

    // Cache dir is always expected to be created
    await tester.pumpAndSettle();
    expect(cacheDir.existsSync(), isTrue);

    if (takeImageFront) {
      verifyNever(photosTaker.takeAndCropPhoto(any, any));
      await tester.tap(
          find.byKey(const Key('front_photo')));
      verify(photosTaker.takeAndCropPhoto(any, any)).called(1);
      await tester.pumpAndSettle();
    }

    if (nameInput != null) {
      await tester.enterText(
          find.byKey(const Key('name')),
          nameInput);
      await tester.pumpAndSettle();
    }

    if (brandInput != null) {
      await tester.enterText(
          find.byKey(const Key('brand')),
          brandInput);
      await tester.pumpAndSettle();
    }

    if (categoriesInput != null) {
      await tester.enterText(
          find.byKey(const Key('categories')),
          categoriesInput);
      await tester.pumpAndSettle();
    }

    if (selectedShops != null) {
      expect(find.byType(MapPage), findsNothing);

      await tester.tap(
          find.byKey(const Key('shops_btn')));
      await tester.pumpAndSettle();

      expect(find.byType(MapPage), findsOneWidget);

      final mapPage = find.byType(MapPage).evaluate().first.widget as MapPage;
      mapPage.finishForTesting(
          selectedShops.isNotEmpty ?
          selectedShops + initialShops :
          null);
      await tester.pumpAndSettle();
    }

    await scrollToBottom(tester);

    if (shopsToCancel.isNotEmpty) {
      for (final shopToCancel in shopsToCancel) {
        final key = Key('shop_label_${shopToCancel.osmId}');
        final label = find.byKey(key);
        final cancel = find.descendant(
            of: label,
            matching: find.byKey(const Key('label_cancelable_cancel')));
        await tester.tap(cancel);
        await tester.pumpAndSettle();
      }
    }

    if (takeImageIngredients) {
      verifyNever(photosTaker.takeAndCropPhoto(any, any));
      expect(ocrAttempts, equals(0));
      await tester.tap(find.byKey(const Key('ingredients_photo')));
      await tester.pumpAndSettle();
      expect(ocrAttempts, equals(1));
      verify(photosTaker.takeAndCropPhoto(any, any)).called(1);

      var performedManualOcrAttempts = 0;
      while (true) {
        if (ocrAttempts < ocrSuccessfulAttemptNumber) {
          expect(find.text(context.strings.init_product_page_ocr_error_descr),
              findsOneWidget);
          expect(find.text('water, lemon'), findsNothing);
        } else {
          expect(find.text(context.strings.init_product_page_ocr_error_descr),
              findsNothing);
          expect(find.text('water, lemon'), findsOneWidget);
        }
        if (performedManualOcrAttempts < requiredManualOcrAttempts) {
          await tester.tap(find.byKey(const Key('ocr_try_again')));
          await tester.pumpAndSettle();
          performedManualOcrAttempts += 1;
        } else {
          break;
        }
      }
    }

    if (ingredientsTextOverride != null) {
      await tester.enterText(
          find.byKey(const Key('ingredients_text')),
          ingredientsTextOverride);
      await tester.pumpAndSettle();
    }

    await scrollToBottom(tester);

    if (veganStatusInput != null) {
      switch (veganStatusInput) {
        case VegStatus.positive:
          await tester.tap(find.byKey(const Key('vegan_positive_btn')));
          break;
        case VegStatus.negative:
          await tester.tap(find.byKey(const Key('vegan_negative_btn')));
          break;
        case VegStatus.unknown:
          await tester.tap(find.byKey(const Key('vegan_unknown_btn')));
          break;
        case VegStatus.possible:
          throw Exception('Not supported by VegStatusSelectionPanel, a test is broken');
        default:
          throw Error();
      }
      await tester.pumpAndSettle();
    }
    if (vegetarianStatusInput != null) {
      switch (vegetarianStatusInput) {
        case VegStatus.positive:
          await tester.tap(find.byKey(const Key('vegetarian_positive_btn')));
          break;
        case VegStatus.negative:
          await tester.tap(find.byKey(const Key('vegetarian_negative_btn')));
          break;
        case VegStatus.unknown:
          await tester.tap(find.byKey(const Key('vegetarian_unknown_btn')));
          break;
        case VegStatus.possible:
          throw Exception('Not supported by VegStatusSelectionPanel, a test is broken');
        default:
          throw Error();
      }
      await tester.pumpAndSettle();
    }

    expect(done, isFalse);
    verifyNever(productsManager.createUpdateProduct(any, any));
    await tester.tap(find.byKey(const Key('done_btn')));
    await tester.pumpAndSettle();
    if (expectedProductResult != null) {
      final finalProduct = verify(
          productsManager.createUpdateProduct(captureAny, any)).captured.first;
      expect(finalProduct, equals(expectedProductResult));
    } else {
      verifyNever(productsManager.createUpdateProduct(captureAny, any));
    }

    final expectedShops = <Shop>[];
    expectedShops.addAll(initialShops);
    if (selectedShops != null) {
      expectedShops.addAll(selectedShops);
    }
    expectedShops.removeWhere((shop) => shopsToCancel.contains(shop));
    if (expectedProductResult != null && expectedShops.isNotEmpty) {
      final sentShops =
        verify(shopsManager.putProductToShops(expectedProductResult, captureAny))
            .captured.first as List<Shop>;
      expect(expectedShops.toSet(), equals(sentShops.toSet()));
    } else {
      verifyNever(shopsManager.putProductToShops(any, any));
    }

    // If done, cache dir must be deleted
    expect(cacheDir.existsSync(), equals(!done));

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
      ..vegetarianStatus = VegStatus.positive
      ..vegetarianStatusSource = VegStatusSource.community
      ..veganStatus = VegStatus.positive
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
      vegetarianStatusInput: expectedProduct.vegetarianStatus,
      selectedShops: [aShop]
    );

    expect(done, isTrue);
  });

  testWidgets('front photo not present when product has data', (WidgetTester tester) async {
    final initialProduct = Product((v) => v
      ..barcode = '123'
      ..imageFront = Uri.file(File('./test/assets/img.jpg').absolute.path));
    await tester.superPump(InitProductPage(initialProduct));

    expect(find.byKey(const Key('front_photo_group')), findsNothing);
    expect(find.byKey(const Key('name_group')), findsWidgets);
    expect(find.byKey(const Key('brand_group')), findsWidgets);
    expect(find.byKey(const Key('categories_group')), findsWidgets);
    expect(find.byKey(const Key('ingredients_group')), findsWidgets);
    expect(find.byKey(const Key('vegan_status_group')), findsWidgets);
    expect(find.byKey(const Key('vegetarian_status_group')), findsWidgets);
  });

  testWidgets('name input field not present when product has data', (WidgetTester tester) async {
    final initialProduct = Product((v) => v
      ..barcode = '123'
      ..name = 'Hello there');
    await tester.superPump(InitProductPage(initialProduct));

    expect(find.byKey(const Key('front_photo_group')), findsWidgets);
    expect(find.byKey(const Key('name_group')), findsNothing);
    expect(find.byKey(const Key('brand_group')), findsWidgets);
    expect(find.byKey(const Key('categories_group')), findsWidgets);
    expect(find.byKey(const Key('ingredients_group')), findsWidgets);
    expect(find.byKey(const Key('vegan_status_group')), findsWidgets);
    expect(find.byKey(const Key('vegetarian_status_group')), findsWidgets);
  });

  testWidgets('brand input field not present when product has data', (WidgetTester tester) async {
    final initialProduct = Product((v) => v
      ..barcode = '123'
      ..brands = ListBuilder<String>(['Cool brand']));
    await tester.superPump(InitProductPage(initialProduct));

    expect(find.byKey(const Key('front_photo_group')), findsWidgets);
    expect(find.byKey(const Key('name_group')), findsWidgets);
    expect(find.byKey(const Key('brand_group')), findsNothing);
    expect(find.byKey(const Key('categories_group')), findsWidgets);
    expect(find.byKey(const Key('ingredients_group')), findsWidgets);
    expect(find.byKey(const Key('vegan_status_group')), findsWidgets);
    expect(find.byKey(const Key('vegetarian_status_group')), findsWidgets);
  });

  testWidgets('categories input field not present when product has data', (WidgetTester tester) async {
    final initialProduct = Product((v) => v
      ..barcode = '123'
      ..categories = ListBuilder<String>(['Cool category']));
    await tester.superPump(InitProductPage(initialProduct));

    expect(find.byKey(const Key('front_photo_group')), findsWidgets);
    expect(find.byKey(const Key('name_group')), findsWidgets);
    expect(find.byKey(const Key('brand_group')), findsWidgets);
    expect(find.byKey(const Key('categories_group')), findsNothing);
    expect(find.byKey(const Key('ingredients_group')), findsWidgets);
    expect(find.byKey(const Key('vegan_status_group')), findsWidgets);
    expect(find.byKey(const Key('vegetarian_status_group')), findsWidgets);
  });

  testWidgets('ingredients group not present when product has data', (WidgetTester tester) async {
    final initialProduct = Product((v) => v
      ..barcode = '123'
      ..imageIngredients = Uri.file(File('./test/assets/img.jpg').absolute.path)
      ..ingredientsText = 'Tomato');
    await tester.superPump(InitProductPage(initialProduct));

    expect(find.byKey(const Key('front_photo_group')), findsWidgets);
    expect(find.byKey(const Key('name_group')), findsWidgets);
    expect(find.byKey(const Key('brand_group')), findsWidgets);
    expect(find.byKey(const Key('categories_group')), findsWidgets);
    expect(find.byKey(const Key('ingredients_group')), findsNothing);
    expect(find.byKey(const Key('vegan_status_group')), findsWidgets);
    expect(find.byKey(const Key('vegetarian_status_group')), findsWidgets);
  });

  testWidgets('ingredients group present when product has no ingredients image but has text', (WidgetTester tester) async {
    final initialProduct = Product((v) => v
      ..barcode = '123'
      ..ingredientsText = 'Tomato');
    await tester.superPump(InitProductPage(initialProduct));

    expect(find.byKey(const Key('front_photo_group')), findsWidgets);
    expect(find.byKey(const Key('name_group')), findsWidgets);
    expect(find.byKey(const Key('brand_group')), findsWidgets);
    expect(find.byKey(const Key('categories_group')), findsWidgets);
    expect(find.byKey(const Key('ingredients_group')), findsWidgets);
    expect(find.byKey(const Key('vegan_status_group')), findsWidgets);
    expect(find.byKey(const Key('vegetarian_status_group')), findsWidgets);
  });

  testWidgets('ingredients group present when product has no ingredients text but has image', (WidgetTester tester) async {
    final initialProduct = Product((v) => v
      ..barcode = '123'
      ..imageIngredients = Uri.file(File('./test/assets/img.jpg').absolute.path));
    await tester.superPump(InitProductPage(initialProduct));

    expect(find.byKey(const Key('front_photo_group')), findsWidgets);
    expect(find.byKey(const Key('name_group')), findsWidgets);
    expect(find.byKey(const Key('brand_group')), findsWidgets);
    expect(find.byKey(const Key('categories_group')), findsWidgets);
    expect(find.byKey(const Key('ingredients_group')), findsWidgets);
    expect(find.byKey(const Key('vegan_status_group')), findsWidgets);
    expect(find.byKey(const Key('vegetarian_status_group')), findsWidgets);
  });

  testWidgets('vegan group not present when product has data', (WidgetTester tester) async {
    final initialProduct = Product((v) => v
      ..barcode = '123'
      ..veganStatus = VegStatus.positive
      ..veganStatusSource = VegStatusSource.community);
    await tester.superPump(InitProductPage(initialProduct));

    expect(find.byKey(const Key('front_photo_group')), findsWidgets);
    expect(find.byKey(const Key('name_group')), findsWidgets);
    expect(find.byKey(const Key('brand_group')), findsWidgets);
    expect(find.byKey(const Key('categories_group')), findsWidgets);
    expect(find.byKey(const Key('ingredients_group')), findsWidgets);
    expect(find.byKey(const Key('vegan_status_group')), findsNothing);
    expect(find.byKey(const Key('vegetarian_status_group')), findsWidgets);
  });

  testWidgets('vegan group present when product has vegan data from OFF', (WidgetTester tester) async {
    final initialProduct = Product((v) => v
      ..barcode = '123'
      ..veganStatus = VegStatus.positive
      ..veganStatusSource = VegStatusSource.open_food_facts);
    await tester.superPump(InitProductPage(initialProduct));

    expect(find.byKey(const Key('front_photo_group')), findsWidgets);
    expect(find.byKey(const Key('name_group')), findsWidgets);
    expect(find.byKey(const Key('brand_group')), findsWidgets);
    expect(find.byKey(const Key('categories_group')), findsWidgets);
    expect(find.byKey(const Key('ingredients_group')), findsWidgets);
    expect(find.byKey(const Key('vegan_status_group')), findsWidgets);
    expect(find.byKey(const Key('vegetarian_status_group')), findsWidgets);
  });

  testWidgets('vegan group present when product has vegan data without source', (WidgetTester tester) async {
    final initialProduct = Product((v) => v
      ..barcode = '123'
      ..veganStatus = VegStatus.positive);
    await tester.superPump(InitProductPage(initialProduct));

    expect(find.byKey(const Key('front_photo_group')), findsWidgets);
    expect(find.byKey(const Key('name_group')), findsWidgets);
    expect(find.byKey(const Key('brand_group')), findsWidgets);
    expect(find.byKey(const Key('categories_group')), findsWidgets);
    expect(find.byKey(const Key('ingredients_group')), findsWidgets);
    expect(find.byKey(const Key('vegan_status_group')), findsWidgets);
    expect(find.byKey(const Key('vegetarian_status_group')), findsWidgets);
  });

  testWidgets('vegetarian group not present when product has data', (WidgetTester tester) async {
    final initialProduct = Product((v) => v
      ..barcode = '123'
      ..vegetarianStatus = VegStatus.positive
      ..vegetarianStatusSource = VegStatusSource.community);
    await tester.superPump(InitProductPage(initialProduct));

    expect(find.byKey(const Key('front_photo_group')), findsWidgets);
    expect(find.byKey(const Key('name_group')), findsWidgets);
    expect(find.byKey(const Key('brand_group')), findsWidgets);
    expect(find.byKey(const Key('categories_group')), findsWidgets);
    expect(find.byKey(const Key('ingredients_group')), findsWidgets);
    expect(find.byKey(const Key('vegan_status_group')), findsWidgets);
    expect(find.byKey(const Key('vegetarian_status_group')), findsNothing);
  });

  testWidgets('vegetarian group present when product has vegetarian data from OFF', (WidgetTester tester) async {
    final initialProduct = Product((v) => v
      ..barcode = '123'
      ..vegetarianStatus = VegStatus.positive
      ..vegetarianStatusSource = VegStatusSource.open_food_facts);
    await tester.superPump(InitProductPage(initialProduct));

    expect(find.byKey(const Key('front_photo_group')), findsWidgets);
    expect(find.byKey(const Key('name_group')), findsWidgets);
    expect(find.byKey(const Key('brand_group')), findsWidgets);
    expect(find.byKey(const Key('categories_group')), findsWidgets);
    expect(find.byKey(const Key('ingredients_group')), findsWidgets);
    expect(find.byKey(const Key('vegan_status_group')), findsWidgets);
    expect(find.byKey(const Key('vegetarian_status_group')), findsWidgets);
  });

  testWidgets('vegetarian group present when product has vegetarian data without source', (WidgetTester tester) async {
    final initialProduct = Product((v) => v
      ..barcode = '123'
      ..vegetarianStatus = VegStatus.positive);
    await tester.superPump(InitProductPage(initialProduct));

    expect(find.byKey(const Key('front_photo_group')), findsWidgets);
    expect(find.byKey(const Key('name_group')), findsWidgets);
    expect(find.byKey(const Key('brand_group')), findsWidgets);
    expect(find.byKey(const Key('categories_group')), findsWidgets);
    expect(find.byKey(const Key('ingredients_group')), findsWidgets);
    expect(find.byKey(const Key('vegan_status_group')), findsWidgets);
    expect(find.byKey(const Key('vegetarian_status_group')), findsWidgets);
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
      ..vegetarianStatus = VegStatus.positive
      ..vegetarianStatusSource = VegStatusSource.community
      ..veganStatus = VegStatus.positive
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
      ..vegetarianStatus = VegStatus.positive
      ..vegetarianStatusSource = VegStatusSource.community
      ..veganStatus = VegStatus.positive
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

  testWidgets('can save product without ingredients text', (WidgetTester tester) async {
    final expectedProduct = Product((v) => v
      ..barcode = '123'
      ..name = 'Lemon drink'
      ..brands = ListBuilder<String>(['Nice brand'])
      ..categories = ListBuilder<String>(['Nice', 'category'])
      ..imageFront = Uri.file(File('./test/assets/img.jpg').absolute.path)
      ..imageIngredients = Uri.file(File('./test/assets/img.jpg').absolute.path)
      ..ingredientsText = '' // Empty!
      ..vegetarianStatus = VegStatus.positive
      ..vegetarianStatusSource = VegStatusSource.community
      ..veganStatus = VegStatus.positive
      ..veganStatusSource = VegStatusSource.community);

    final done = await generalTest(
        tester,
        expectedProductResult: expectedProduct,
        nameInput: expectedProduct.name,
        brandInput: expectedProduct.brands!.join(', '),
        categoriesInput: expectedProduct.categories!.join(', '),
        takeImageFront: expectedProduct.imageFront != null,
        takeImageIngredients: true,
        ingredientsTextOverride: '',
        veganStatusInput: expectedProduct.veganStatus,
        vegetarianStatusInput: expectedProduct.vegetarianStatus,
        selectedShops: [aShop]
    );

    expect(done, isTrue);
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
    final done = await generalTest(tester, veganStatusInput: VegStatus.unknown, vegetarianStatusInput: null, expectedProductResult: null);
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

  testWidgets('no shops selected when map opened', (WidgetTester tester) async {
    final expectedProduct = Product((v) => v
      ..barcode = '123'
      ..name = 'Lemon drink'
      ..brands = ListBuilder<String>(['Nice brand'])
      ..categories = ListBuilder<String>(['Nice', 'category'])
      ..imageFront = Uri.file(File('./test/assets/img.jpg').absolute.path)
      ..imageIngredients = Uri.file(File('./test/assets/img.jpg').absolute.path)
      ..ingredientsText = 'water, lemon'
      ..vegetarianStatus = VegStatus.positive
      ..vegetarianStatusSource = VegStatusSource.community
      ..veganStatus = VegStatus.positive
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
        vegetarianStatusInput: expectedProduct.vegetarianStatus,
        selectedShops: [] // No shop
    );

    expect(done, isTrue);
  });

  testWidgets('shops sending to server finishes with error but all other things are ok', (WidgetTester tester) async {
    final perfectlyGoodExpectedProduct = Product((v) => v
      ..barcode = '123'
      ..name = 'Lemon drink'
      ..brands = ListBuilder<String>(['Nice brand'])
      ..categories = ListBuilder<String>(['Nice', 'category'])
      ..imageFront = Uri.file(File('./test/assets/img.jpg').absolute.path)
      ..imageIngredients = Uri.file(File('./test/assets/img.jpg').absolute.path)
      ..ingredientsText = 'water, lemon'
      ..vegetarianStatus = VegStatus.positive
      ..vegetarianStatusSource = VegStatusSource.community
      ..veganStatus = VegStatus.positive
      ..veganStatusSource = VegStatusSource.community);

    when(shopsManager.putProductToShops(any, any)).thenAnswer((_) async => Err(ShopsManagerError.OTHER));

    final done = await generalTest(
        tester,
        expectedProductResult: perfectlyGoodExpectedProduct,
        nameInput: perfectlyGoodExpectedProduct.name,
        brandInput: perfectlyGoodExpectedProduct.brands!.join(', '),
        categoriesInput: perfectlyGoodExpectedProduct.categories!.join(', '),
        takeImageFront: perfectlyGoodExpectedProduct.imageFront != null,
        takeImageIngredients: perfectlyGoodExpectedProduct.imageIngredients != null,
        veganStatusInput: perfectlyGoodExpectedProduct.veganStatus,
        vegetarianStatusInput: perfectlyGoodExpectedProduct.vegetarianStatus,
        selectedShops: [aShop]
    );

    // Even though perfectlyGoodExpectedProduct expected to be stored,
    // page is expected to be not finished, because of shops sending error
    expect(done, isFalse);
  });

  testWidgets('ocr fail and manual ingredients input', (WidgetTester tester) async {
    final perfectlyGoodExpectedProduct = Product((v) => v
      ..barcode = '123'
      ..name = 'Lemon drink'
      ..brands = ListBuilder<String>(['Nice brand'])
      ..categories = ListBuilder<String>(['Nice', 'category'])
      ..imageFront = Uri.file(File('./test/assets/img.jpg').absolute.path)
      ..imageIngredients = Uri.file(File('./test/assets/img.jpg').absolute.path)
      ..ingredientsText = 'water, lemon'
      ..vegetarianStatus = VegStatus.positive
      ..vegetarianStatusSource = VegStatusSource.community
      ..veganStatus = VegStatus.positive
      ..veganStatusSource = VegStatusSource.community);

    final done = await generalTest(
        tester,
        expectedProductResult: perfectlyGoodExpectedProduct,
        nameInput: perfectlyGoodExpectedProduct.name,
        brandInput: perfectlyGoodExpectedProduct.brands!.join(', '),
        categoriesInput: perfectlyGoodExpectedProduct.categories!.join(', '),
        takeImageFront: perfectlyGoodExpectedProduct.imageFront != null,
        takeImageIngredients: perfectlyGoodExpectedProduct.imageIngredients != null,
        veganStatusInput: perfectlyGoodExpectedProduct.veganStatus,
        vegetarianStatusInput: perfectlyGoodExpectedProduct.vegetarianStatus,
        ocrSuccessfulAttemptNumber: 3, // 2 OCRs attempts will fail (first (auto) and the manual)
        requiredManualOcrAttempts: 1, // We'll try to perform restart OCR only once
        ingredientsTextOverride: 'water, lemon' // But will write ingredients manually
    );

    expect(done, isTrue);
  });

  testWidgets('ocr fail and successful retry', (WidgetTester tester) async {
    final perfectlyGoodExpectedProduct = Product((v) => v
      ..barcode = '123'
      ..name = 'Lemon drink'
      ..brands = ListBuilder<String>(['Nice brand'])
      ..categories = ListBuilder<String>(['Nice', 'category'])
      ..imageFront = Uri.file(File('./test/assets/img.jpg').absolute.path)
      ..imageIngredients = Uri.file(File('./test/assets/img.jpg').absolute.path)
      ..ingredientsText = 'water, lemon'
      ..vegetarianStatus = VegStatus.positive
      ..vegetarianStatusSource = VegStatusSource.community
      ..veganStatus = VegStatus.positive
      ..veganStatusSource = VegStatusSource.community);

    final done = await generalTest(
        tester,
        expectedProductResult: perfectlyGoodExpectedProduct,
        nameInput: perfectlyGoodExpectedProduct.name,
        brandInput: perfectlyGoodExpectedProduct.brands!.join(', '),
        categoriesInput: perfectlyGoodExpectedProduct.categories!.join(', '),
        takeImageFront: perfectlyGoodExpectedProduct.imageFront != null,
        takeImageIngredients: perfectlyGoodExpectedProduct.imageIngredients != null,
        veganStatusInput: perfectlyGoodExpectedProduct.veganStatus,
        vegetarianStatusInput: perfectlyGoodExpectedProduct.vegetarianStatus,
        ocrSuccessfulAttemptNumber: 3, // 2 OCRs attempts will fail (first (auto) and the first manual)
        requiredManualOcrAttempts: 2, // We'll try to perform a second OCR!
        ingredientsTextOverride: null // And will NOT write ingredients manually
    );

    expect(done, isTrue);
  });

  testWidgets('opened with initial shops', (WidgetTester tester) async {
    final product = Product((v) => v
      ..barcode = '123'
      ..name = 'Lemon drink'
      ..brands = ListBuilder<String>(['Nice brand'])
      ..categories = ListBuilder<String>(['Nice', 'category'])
      ..imageFront = Uri.file(File('./test/assets/img.jpg').absolute.path)
      ..imageIngredients = Uri.file(File('./test/assets/img.jpg').absolute.path)
      ..ingredientsText = 'water, lemon'
      ..vegetarianStatus = VegStatus.positive
      ..vegetarianStatusSource = VegStatusSource.community
      ..veganStatus = VegStatus.positive
      ..veganStatusSource = VegStatusSource.community);

    final done = await generalTest(
        tester,
        expectedProductResult: product,
        nameInput: product.name,
        brandInput: product.brands!.join(', '),
        categoriesInput: product.categories!.join(', '),
        takeImageFront: product.imageFront != null,
        takeImageIngredients: product.imageIngredients != null,
        veganStatusInput: product.veganStatus,
        vegetarianStatusInput: product.vegetarianStatus,
        initialShops: [aShop]
    );

    expect(done, isTrue);
  });

  testWidgets('opened with initial shops, then select shops', (WidgetTester tester) async {
    final product = Product((v) => v
      ..barcode = '123'
      ..name = 'Lemon drink'
      ..brands = ListBuilder<String>(['Nice brand'])
      ..categories = ListBuilder<String>(['Nice', 'category'])
      ..imageFront = Uri.file(File('./test/assets/img.jpg').absolute.path)
      ..imageIngredients = Uri.file(File('./test/assets/img.jpg').absolute.path)
      ..ingredientsText = 'water, lemon'
      ..vegetarianStatus = VegStatus.positive
      ..vegetarianStatusSource = VegStatusSource.community
      ..veganStatus = VegStatus.positive
      ..veganStatusSource = VegStatusSource.community);

    final shops = [
      Shop((e) => e
        ..osmShop.replace(OsmShop((e) => e
          ..osmId = '1'
          ..longitude = 11
          ..latitude = 11
          ..name = 'Spar'))
        ..backendShop.replace(BackendShop((e) => e
          ..osmId = '1'
          ..productsCount = 2))),
      Shop((e) => e
        ..osmShop.replace(OsmShop((e) => e
          ..osmId = '2'
          ..longitude = 11
          ..latitude = 11
          ..name = 'Spar'))
        ..backendShop.replace(BackendShop((e) => e
          ..osmId = '2'
          ..productsCount = 2))),
    ];

    final done = await generalTest(
        tester,
        expectedProductResult: product,
        nameInput: product.name,
        brandInput: product.brands!.join(', '),
        categoriesInput: product.categories!.join(', '),
        takeImageFront: product.imageFront != null,
        takeImageIngredients: product.imageIngredients != null,
        veganStatusInput: product.veganStatus,
        vegetarianStatusInput: product.vegetarianStatus,
        initialShops: [shops[0]],
        selectedShops: [shops[1]],
    );

    expect(done, isTrue);
  });

  testWidgets('cancel initial and selected shops', (WidgetTester tester) async {
    final product = Product((v) => v
      ..barcode = '123'
      ..name = 'Lemon drink'
      ..brands = ListBuilder<String>(['Nice brand'])
      ..categories = ListBuilder<String>(['Nice', 'category'])
      ..imageFront = Uri.file(File('./test/assets/img.jpg').absolute.path)
      ..imageIngredients = Uri.file(File('./test/assets/img.jpg').absolute.path)
      ..ingredientsText = 'water, lemon'
      ..vegetarianStatus = VegStatus.positive
      ..vegetarianStatusSource = VegStatusSource.community
      ..veganStatus = VegStatus.positive
      ..veganStatusSource = VegStatusSource.community);

    final shops = [
      Shop((e) => e
        ..osmShop.replace(OsmShop((e) => e
          ..osmId = '1'
          ..longitude = 11
          ..latitude = 11
          ..name = 'Spar'))
        ..backendShop.replace(BackendShop((e) => e
          ..osmId = '1'
          ..productsCount = 2))),
      Shop((e) => e
        ..osmShop.replace(OsmShop((e) => e
          ..osmId = '2'
          ..longitude = 11
          ..latitude = 11
          ..name = 'Spar'))
        ..backendShop.replace(BackendShop((e) => e
          ..osmId = '2'
          ..productsCount = 2))),
      Shop((e) => e
        ..osmShop.replace(OsmShop((e) => e
          ..osmId = '3'
          ..longitude = 11
          ..latitude = 11
          ..name = 'Spar'))
        ..backendShop.replace(BackendShop((e) => e
          ..osmId = '3'
          ..productsCount = 2))),
      Shop((e) => e
        ..osmShop.replace(OsmShop((e) => e
          ..osmId = '4'
          ..longitude = 11
          ..latitude = 11
          ..name = 'Spar'))
        ..backendShop.replace(BackendShop((e) => e
          ..osmId = '4'
          ..productsCount = 2))),
    ];

    final done = await generalTest(
        tester,
        expectedProductResult: product,
        nameInput: product.name,
        brandInput: product.brands!.join(', '),
        categoriesInput: product.categories!.join(', '),
        takeImageFront: product.imageFront != null,
        takeImageIngredients: product.imageIngredients != null,
        veganStatusInput: product.veganStatus,
        vegetarianStatusInput: product.vegetarianStatus,
        initialShops: [shops[0], shops[1]],
        selectedShops: [shops[2], shops[3]],
        shopsToCancel: [shops[1], shops[3]],
    );

    expect(done, isTrue);
  });

  testWidgets('finish taking front photo when restoring', (WidgetTester tester) async {
    when(productsManager.updateProductAndExtractIngredients(any, any)).thenAnswer(
            (invoc) async => Ok(ProductWithOCRIngredients(
            invoc.positionalArguments[0] as Product,
            'water, lemon')));

    // Lost photo exists!
    when(photosTaker.retrieveLostPhoto()).thenAnswer(
            (_) async => Ok(Uri.parse('./test/assets/img.jpg')));

    verifyNever(photosTaker.cropPhoto(any, any, any));

    final widget = InitProductPage(
        Product((v) => v.barcode = '123'),
        photoBeingTakenForTests: ProductImageType.FRONT);
    await tester.superPump(widget);

    // Lost photo cropping expected to be started
    verify(photosTaker.cropPhoto(any, any, any));

    // Now let's fill the product and ensure it's filled enough to be saved
    // The front photo is not taken by us as we expect it to be restored.
    await tester.enterText(
        find.byKey(const Key('name')),
        'hello there');
    await tester.pumpAndSettle();

    await scrollToBottom(tester);
    await tester.tap(find.byKey(const Key('ingredients_photo')));
    await tester.pumpAndSettle();

    await scrollToBottom(tester);
    await tester.tap(find.byKey(const Key('vegan_positive_btn')));
    await tester.pumpAndSettle();

    verifyNever(productsManager.createUpdateProduct(any, any));
    await tester.tap(find.byKey(const Key('done_btn')));
    await tester.pumpAndSettle();
    verify(productsManager.createUpdateProduct(captureAny, any));
  });

  testWidgets('finish taking ingredients photo when restoring', (WidgetTester tester) async {
    when(productsManager.updateProductAndExtractIngredients(any, any)).thenAnswer(
            (invoc) async => Ok(ProductWithOCRIngredients(
            invoc.positionalArguments[0] as Product,
            'water, lemon')));

    // Lost photo exists!
    when(photosTaker.retrieveLostPhoto()).thenAnswer(
            (_) async => Ok(Uri.parse('./test/assets/img.jpg')));

    verifyNever(photosTaker.cropPhoto(any, any, any));
    verifyNever(productsManager.updateProductAndExtractIngredients(any));

    final widget = InitProductPage(
        Product((v) => v.barcode = '123'),
        photoBeingTakenForTests: ProductImageType.INGREDIENTS);
    await tester.superPump(widget);

    // Lost photo cropping expected to be started
    verify(photosTaker.cropPhoto(any, any, any));
    // Because the lost photo is an ingredients photo -
    // OCR is expected to be performed.
    verify(productsManager.updateProductAndExtractIngredients(any));

    // Now let's fill the product and ensure it's filled enough to be saved
    // The ingredients photo is not taken by us as we expect it to be restored.
    await tester.enterText(
        find.byKey(const Key('name')),
        'hello there');
    await tester.pumpAndSettle();

    await tester.tap(
        find.byKey(const Key('front_photo')));
    await tester.pumpAndSettle();

    await scrollToBottom(tester);
    await tester.tap(find.byKey(const Key('vegan_positive_btn')));
    await tester.pumpAndSettle();

    verifyNever(productsManager.createUpdateProduct(any, any));
    await tester.tap(find.byKey(const Key('done_btn')));
    await tester.pumpAndSettle();
    verify(productsManager.createUpdateProduct(captureAny, any));
  });
}
