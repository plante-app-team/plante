import 'dart:io';

import 'package:built_collection/built_collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mockito/mockito.dart';
import 'package:plante/base/permissions_manager.dart';
import 'package:plante/base/result.dart';
import 'package:plante/l10n/strings.dart';
import 'package:plante/lang/input_products_lang_storage.dart';
import 'package:plante/lang/user_langs_manager.dart';
import 'package:plante/location/user_location_manager.dart';
import 'package:plante/logging/analytics.dart';
import 'package:plante/model/lang_code.dart';
import 'package:plante/model/product.dart';
import 'package:plante/model/product_lang_slice.dart';
import 'package:plante/model/shared_preferences_holder.dart';
import 'package:plante/model/shop.dart';
import 'package:plante/model/user_params_controller.dart';
import 'package:plante/model/veg_status.dart';
import 'package:plante/model/veg_status_source.dart';
import 'package:plante/outside/backend/backend_shop.dart';
import 'package:plante/outside/backend/product_at_shop_source.dart';
import 'package:plante/outside/map/address_obtainer.dart';
import 'package:plante/outside/map/directions_manager.dart';
import 'package:plante/outside/map/osm/osm_shop.dart';
import 'package:plante/outside/map/osm/osm_short_address.dart';
import 'package:plante/outside/map/osm/osm_uid.dart';
import 'package:plante/outside/map/shops_manager.dart';
import 'package:plante/outside/map/shops_manager_types.dart';
import 'package:plante/outside/map/user_address/caching_user_address_pieces_obtainer.dart';
import 'package:plante/outside/products/products_manager.dart';
import 'package:plante/outside/products/products_manager_error.dart';
import 'package:plante/outside/products/suggestions/suggested_products_manager.dart';
import 'package:plante/ui/base/components/dropdown_plante.dart';
import 'package:plante/ui/map/latest_camera_pos_storage.dart';
import 'package:plante/ui/map/map_page/map_page.dart';
import 'package:plante/ui/map/map_page/map_page_testing_storage.dart';
import 'package:plante/ui/photos/photo_requester.dart';
import 'package:plante/ui/photos/photos_taker.dart';
import 'package:plante/ui/product/init_product_page.dart';
import 'package:plante/ui/product/init_product_page_model.dart';

import '../../common_mocks.mocks.dart';
import '../../widget_tester_extension.dart';
import '../../z_fakes/fake_analytics.dart';
import '../../z_fakes/fake_caching_user_address_pieces_obtainer.dart';
import '../../z_fakes/fake_input_products_lang_storage.dart';
import '../../z_fakes/fake_shared_preferences.dart';
import '../../z_fakes/fake_suggested_products_manager.dart';
import '../../z_fakes/fake_user_langs_manager.dart';
import '../../z_fakes/fake_user_params_controller.dart';

const _DEFAULT_TEST_LANG = LangCode.en;
const _NOT_DEFAULT_TEST_LANG = LangCode.ru;
const _USER_LANGS = [_DEFAULT_TEST_LANG, _NOT_DEFAULT_TEST_LANG];

void main() {
  late MockPhotosTaker photosTaker;
  late MockProductsManager productsManager;
  late MockShopsManager shopsManager;
  late MockUserLocationManager userLocationManager;
  late MockPermissionsManager permissionsManager;
  late FakeAnalytics analytics;
  late MockAddressObtainer addressObtainer;
  late FakeInputProductsLangStorage inputProductsLangStorage;

  final aShop = Shop((e) => e
    ..osmShop.replace(OsmShop((e) => e
      ..osmUID = OsmUID.parse('1:1')
      ..longitude = 11
      ..latitude = 11
      ..name = 'Spar'))
    ..backendShop.replace(BackendShop((e) => e
      ..osmUID = OsmUID.parse('1:1')
      ..productsCount = 2)));

  setUp(() async {
    await GetIt.I.reset();
    analytics = FakeAnalytics();
    GetIt.I.registerSingleton<Analytics>(analytics);

    photosTaker = MockPhotosTaker();
    when(photosTaker.takeAndCropPhoto(any, any, any,
            minSize: anyNamed('minSize')))
        .thenAnswer(
            (_) async => Uri.file(File('./test/assets/img.jpg').absolute.path));
    when(photosTaker.cropPhoto(any, any, any, minSize: anyNamed('minSize')))
        .thenAnswer(
            (_) async => Uri.file(File('./test/assets/img.jpg').absolute.path));
    when(photosTaker.retrieveLostPhoto(any))
        .thenAnswer((realInvocation) async => null);
    GetIt.I.registerSingleton<PhotosTaker>(photosTaker);

    productsManager = MockProductsManager();
    when(productsManager.createUpdateProduct(any)).thenAnswer((invoc) async {
      return Ok(invoc.positionalArguments[0] as Product);
    });
    when(productsManager.updateProductAndExtractIngredients(any, any))
        .thenAnswer((_) async => Err(ProductsManagerError.OTHER));
    GetIt.I.registerSingleton<ProductsManager>(productsManager);

    shopsManager = MockShopsManager();
    GetIt.I.registerSingleton<ShopsManager>(shopsManager);
    when(shopsManager.putProductToShops(any, any, any))
        .thenAnswer((_) async => Ok(None()));

    GetIt.I.registerSingleton<UserParamsController>(FakeUserParamsController());

    userLocationManager = MockUserLocationManager();
    when(userLocationManager.lastKnownPositionInstant()).thenReturn(null);
    when(userLocationManager.lastKnownPosition()).thenAnswer((_) async => null);
    GetIt.I.registerSingleton<UserLocationManager>(userLocationManager);

    permissionsManager = MockPermissionsManager();
    when(permissionsManager.status(any))
        .thenAnswer((_) async => PermissionState.granted);
    when(permissionsManager.openAppSettings()).thenAnswer((_) async => true);
    GetIt.I.registerSingleton<PermissionsManager>(permissionsManager);

    GetIt.I.registerSingleton<LatestCameraPosStorage>(
        LatestCameraPosStorage(FakeSharedPreferences().asHolder()));

    addressObtainer = MockAddressObtainer();
    when(addressObtainer.addressOfShop(any))
        .thenAnswer((_) async => Ok(OsmShortAddress.empty));
    GetIt.I.registerSingleton<AddressObtainer>(addressObtainer);

    inputProductsLangStorage =
        FakeInputProductsLangStorage.fromCode(_DEFAULT_TEST_LANG);
    GetIt.I
        .registerSingleton<InputProductsLangStorage>(inputProductsLangStorage);

    GetIt.I
        .registerSingleton<UserLangsManager>(FakeUserLangsManager(_USER_LANGS));

    final directionsManager = MockDirectionsManager();
    when(directionsManager.areDirectionsAvailable())
        .thenAnswer((_) async => false);
    GetIt.I.registerSingleton<DirectionsManager>(directionsManager);

    GetIt.I.registerSingleton<SuggestedProductsManager>(
        FakeSuggestedProductsManager());
    final userAddressObtainer = FakeCachingUserAddressPiecesObtainer();
    GetIt.I.registerSingleton<CachingUserAddressPiecesObtainer>(
        userAddressObtainer);
    GetIt.I.registerSingleton<SharedPreferencesHolder>(
        FakeSharedPreferences().asHolder());
  });

  Future<void> scrollToBottom(WidgetTester tester) async {
    await tester.drag(find.byKey(const Key('content')), const Offset(0, -3000));
    await tester.pumpAndSettle();
  }

  Future<void> switchLang(WidgetTester tester, LangCode lang) async {
    final dropdown = find
        .byKey(const Key('product_lang'))
        .evaluate()
        .first
        .widget as DropdownPlante<LangCode?>;
    dropdown.onChanged!.call(lang);
    await tester.pumpAndSettle();
  }

  Future<bool> generalTest(WidgetTester tester,
      {Product? initialProduct,
      Product? expectedProductResult,
      String? nameInput = 'Lemon drink',
      String? brandInput = 'Nice brand',
      bool takeImageFront = true,
      bool takeImageIngredients = true,
      String? ingredientsTextOverride,
      VegStatus? veganStatusInput = VegStatus.positive,
      List<Shop>? selectShops,
      List<Shop> initialShops = const [],
      List<Shop> shopsToCancel = const [],
      int requiredManualOcrAttempts = 0,
      int ocrSuccessfulAttemptNumber = 1,
      LangCode selectLang = _DEFAULT_TEST_LANG,
      bool selectLangAtStart = true}) async {
    var ocrAttempts = 0;
    when(productsManager.updateProductAndExtractIngredients(any, any))
        .thenAnswer((invoc) async {
      ocrAttempts += 1;
      if (ocrAttempts < ocrSuccessfulAttemptNumber) {
        return Err(ProductsManagerError.OTHER);
      }
      return Ok(ProductWithOCRIngredients(
          invoc.positionalArguments[0] as Product, 'water, lemon'));
    });

    verifyZeroInteractions(productsManager);

    bool done = false;
    final callback = () {
      done = true;
    };

    initialProduct ??= Product((v) => v
      ..barcode = '123'
      ..langsPrioritized.add(selectLang));

    final widget = InitProductPage(initialProduct,
        doneCallback: callback, initialShops: initialShops);

    final cacheDir = await widget.cacheDir();
    if (cacheDir.existsSync()) {
      cacheDir.deleteSync();
    }
    expect(cacheDir.existsSync(), isFalse);

    final context = await tester.superPump(widget);

    // Cache dir is always expected to be created
    await tester.pumpAndSettle();
    expect(cacheDir.existsSync(), isTrue);

    final selectLangFn = () async {
      if (selectLang != _DEFAULT_TEST_LANG) {
        await switchLang(tester, selectLang);
      }
    };
    if (selectLangAtStart) {
      await selectLangFn.call();
    }

    if (takeImageFront) {
      verifyNever(photosTaker.takeAndCropPhoto(any, any, any,
          minSize: anyNamed('minSize')));
      await tester.tap(find.byKey(const Key('front_photo')));
      verify(photosTaker.takeAndCropPhoto(any, any, PhotoRequester.PRODUCT_INIT,
              minSize: anyNamed('minSize')))
          .called(1);
      await tester.pumpAndSettle();
    }

    if (nameInput != null) {
      await tester.enterText(find.byKey(const Key('name')), nameInput);
      await tester.pumpAndSettle();
    }

    if (brandInput != null) {
      await tester.enterText(find.byKey(const Key('brand')), brandInput);
      await tester.pumpAndSettle();
    }

    await scrollToBottom(tester);

    if (selectShops != null) {
      expect(find.byType(MapPage), findsNothing);

      await tester.tap(find.byKey(const Key('shops_btn')));
      await tester.pumpAndSettle();

      expect(find.byType(MapPage), findsOneWidget);

      final mapPage = find.byType(MapPage).evaluate().first.widget as MapPage;
      mapPage.finishForTesting(
          selectShops.isNotEmpty ? selectShops + initialShops : null);
      await tester.pumpAndSettle();
    }

    if (shopsToCancel.isNotEmpty) {
      for (final shopToCancel in shopsToCancel) {
        final key = Key('shop_label_${shopToCancel.osmUID}');
        final label = find.byKey(key);
        final cancel = find.descendant(
            of: label,
            matching: find.byKey(const Key('label_cancelable_cancel')));
        await tester.tap(cancel);
        await tester.pumpAndSettle();
      }
    }

    if (takeImageIngredients) {
      verifyNever(photosTaker.takeAndCropPhoto(any, any, any,
          minSize: anyNamed('minSize')));
      expect(ocrAttempts, equals(0));
      await tester.tap(find.byKey(const Key('ingredients_photo')));
      await tester.pumpAndSettle();
      expect(ocrAttempts, greaterThanOrEqualTo(1));
      expect(ocrAttempts,
          lessThanOrEqualTo(InitProductPageModel.OCR_RETRIES_COUNT));
      verify(photosTaker.takeAndCropPhoto(any, any, PhotoRequester.PRODUCT_INIT,
              minSize: anyNamed('minSize')))
          .called(1);

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
      if (ocrSuccessfulAttemptNumber <= ocrAttempts) {
        expect(analytics.wasEventSent('ocr_success'), isTrue);
      } else {
        expect(analytics.wasEventSent('ocr_success'), isFalse);
      }
      if (ocrSuccessfulAttemptNumber == 1) {
        expect(analytics.wasEventSent('ocr_fail_final'), isFalse);
        expect(analytics.wasEventSent('ocr_fail_will_retry'), isFalse);
      } else {
        expect(analytics.wasEventSent('ocr_fail_final'), isTrue);
        expect(analytics.wasEventSent('ocr_fail_will_retry'), isTrue);
      }
    } else {
      expect(analytics.wasEventSent('ocr_success'), isFalse);
      expect(analytics.wasEventSent('ocr_fail_final'), isFalse);
      expect(analytics.wasEventSent('ocr_fail_will_retry'), isFalse);
    }

    if (ingredientsTextOverride != null) {
      await tester.enterText(
          find.byKey(const Key('ingredients_text')), ingredientsTextOverride);
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
          throw Exception(
              'Not supported by VegStatusSelectionPanel, a test is broken');
        default:
          throw Error();
      }
      await tester.pumpAndSettle();
    }

    if (!selectLangAtStart) {
      await selectLangFn.call();
    }

    expect(done, isFalse);
    verifyNever(productsManager.createUpdateProduct(any));
    await tester.tap(find.byKey(const Key('done_btn')));
    await tester.pumpAndSettle();
    if (expectedProductResult != null) {
      final finalProduct =
          verify(productsManager.createUpdateProduct(captureAny))
              .captured
              .first;
      expect(finalProduct, equals(expectedProductResult));
    } else {
      verifyNever(productsManager.createUpdateProduct(any));
    }

    final expectedShops = <Shop>[];
    expectedShops.addAll(initialShops);
    if (selectShops != null) {
      expectedShops.addAll(selectShops);
    }
    expectedShops.removeWhere((shop) => shopsToCancel.contains(shop));
    if (expectedProductResult != null && expectedShops.isNotEmpty) {
      final captured = verify(shopsManager.putProductToShops(
              expectedProductResult, captureAny, captureAny))
          .captured;
      final sentShops = captured[0] as List<Shop>;
      final source = captured[1] as ProductAtShopSource;

      expect(expectedShops.toSet(), equals(sentShops.toSet()));
      expect(source, equals(ProductAtShopSource.MANUAL));
    } else {
      verifyNever(shopsManager.putProductToShops(any, any, any));
    }

    // If done, cache dir must be deleted
    expect(cacheDir.existsSync(), equals(!done));

    if (done) {
      expect(analytics.sentEventParams('product_save_success'),
          equals({'barcode': expectedProductResult!.barcode}));
      expect(analytics.wasEventSent('product_save_failure'), isFalse);
      expect(analytics.wasEventSent('product_save_shops_failure'), isFalse);
      expect(inputProductsLangStorage.selectedCode, equals(selectLang));
    } else {
      expect(analytics.wasEventSent('product_save_success'), isFalse);
      expect(inputProductsLangStorage.selectedCode, equals(_DEFAULT_TEST_LANG));
    }

    return done;
  }

  /// PLEASE ENSURE THIS TEST IS ALMOST IDENTICAL TO THE
  /// 'good flow with changing the lang in the end' TEST
  testWidgets('good flow', (WidgetTester tester) async {
    final expectedProduct = ProductLangSlice((v) => v
      ..lang = _NOT_DEFAULT_TEST_LANG
      ..barcode = '123'
      ..name = 'Lemon drink'
      ..brands = ListBuilder<String>(['Nice brand'])
      ..imageFront = Uri.file(File('./test/assets/img.jpg').absolute.path)
      ..imageIngredients = Uri.file(File('./test/assets/img.jpg').absolute.path)
      ..ingredientsText = 'water, lemon'
      ..veganStatus = VegStatus.positive
      ..veganStatusSource = VegStatusSource.community).productForTests();

    final done = await generalTest(
      tester,
      expectedProductResult: expectedProduct,
      nameInput: expectedProduct.name,
      brandInput: expectedProduct.brands!.join(', '),
      takeImageFront: expectedProduct.imageFront != null,
      takeImageIngredients: expectedProduct.imageIngredients != null,
      veganStatusInput: expectedProduct.veganStatus,
      selectShops: [aShop],
      selectLang: _NOT_DEFAULT_TEST_LANG,
    );

    expect(done, isTrue);
  });

  /// PLEASE ENSURE THIS TEST IS ALMOST IDENTICAL TO THE 'good flow' TEST
  testWidgets('good flow with changing the lang in the end',
      (WidgetTester tester) async {
    final expectedProduct = ProductLangSlice((v) => v
      ..lang = _NOT_DEFAULT_TEST_LANG
      ..barcode = '123'
      ..name = 'Lemon drink'
      ..brands = ListBuilder<String>(['Nice brand'])
      ..imageFront = Uri.file(File('./test/assets/img.jpg').absolute.path)
      ..imageIngredients = Uri.file(File('./test/assets/img.jpg').absolute.path)
      ..ingredientsText = 'water, lemon'
      ..veganStatus = VegStatus.positive
      ..veganStatusSource = VegStatusSource.community).productForTests();

    final done = await generalTest(
      tester,
      expectedProductResult: expectedProduct,
      nameInput: expectedProduct.name,
      brandInput: expectedProduct.brands!.join(', '),
      takeImageFront: expectedProduct.imageFront != null,
      takeImageIngredients: expectedProduct.imageIngredients != null,
      veganStatusInput: expectedProduct.veganStatus,
      selectShops: [aShop],
      selectLang: _NOT_DEFAULT_TEST_LANG,
      // Let's change the lang in the end - this would ensure
      // that langs changing doesn't erase any user data.
      selectLangAtStart: false,
    );

    expect(done, isTrue);
  });

  void uiInputElementPresenceGeneralTest(WidgetTester tester,
      {required String filledElementKey,
      required ProductLangSlice initialProduct,
      bool expectedInitiallyDisplayed = false,
      bool expectedDisplayedAfterLangChange = true}) async {
    await tester
        .superPump(InitProductPage(initialProduct.buildSingleLangProduct()));

    final allKeys = [
      'front_photo_group',
      'name_group',
      'brand_group',
      'ingredients_group',
      'vegan_status_group',
    ];

    for (final key in allKeys) {
      if (key == filledElementKey) {
        if (expectedInitiallyDisplayed) {
          expect(find.byKey(Key(key)), findsWidgets);
        } else {
          expect(find.byKey(Key(key)), findsNothing);
        }
      } else {
        expect(find.byKey(Key(key)), findsWidgets);
      }
    }

    // Select another lang
    await switchLang(tester, _NOT_DEFAULT_TEST_LANG);

    // After the language change all element are expected to be shown
    // (if expectedDisplayedAfterLangChange == true)
    // because they're all not filled in the new target language
    for (final key in allKeys) {
      if (key == filledElementKey) {
        if (expectedDisplayedAfterLangChange) {
          expect(find.byKey(Key(key)), findsWidgets);
        } else {
          expect(find.byKey(Key(key)), findsNothing);
        }
      } else {
        expect(find.byKey(Key(key)), findsWidgets);
      }
    }
  }

  testWidgets('front photo not presence', (WidgetTester tester) async {
    uiInputElementPresenceGeneralTest(tester,
        filledElementKey: 'front_photo_group',
        initialProduct: ProductLangSlice((v) => v
          ..lang = _DEFAULT_TEST_LANG
          ..barcode = '123'
          ..imageFront =
              Uri.file(File('./test/assets/img.jpg').absolute.path)));
  });

  testWidgets('name input field presence', (WidgetTester tester) async {
    uiInputElementPresenceGeneralTest(tester,
        filledElementKey: 'name_group',
        initialProduct: ProductLangSlice((v) => v
          ..lang = _DEFAULT_TEST_LANG
          ..barcode = '123'
          ..name = 'Hello there'));
  });

  testWidgets('brand input field presence', (WidgetTester tester) async {
    uiInputElementPresenceGeneralTest(tester,
        filledElementKey: 'brand_group',
        expectedDisplayedAfterLangChange: false,
        initialProduct: ProductLangSlice((v) => v
          ..lang = _DEFAULT_TEST_LANG
          ..barcode = '123'
          ..brands = ListBuilder<String>(['Cool brand'])));
  });

  testWidgets('ingredients group presence', (WidgetTester tester) async {
    uiInputElementPresenceGeneralTest(tester,
        filledElementKey: 'ingredients_group',
        initialProduct: ProductLangSlice((v) => v
          ..lang = _DEFAULT_TEST_LANG
          ..barcode = '123'
          ..imageIngredients =
              Uri.file(File('./test/assets/img.jpg').absolute.path)
          ..ingredientsText = 'Tomato'));
  });

  testWidgets(
      'ingredients group present when product has no ingredients image but has text',
      (WidgetTester tester) async {
    uiInputElementPresenceGeneralTest(tester,
        filledElementKey: 'ingredients_group',
        expectedInitiallyDisplayed: true,
        initialProduct: ProductLangSlice((v) => v
          ..lang = _DEFAULT_TEST_LANG
          ..barcode = '123'
          ..ingredientsText = 'Tomato'));
  });

  testWidgets(
      'ingredients group present when product has no ingredients text but has image',
      (WidgetTester tester) async {
    uiInputElementPresenceGeneralTest(tester,
        filledElementKey: 'ingredients_group',
        expectedInitiallyDisplayed: true,
        initialProduct: ProductLangSlice((v) => v
          ..lang = _DEFAULT_TEST_LANG
          ..barcode = '123'
          ..imageIngredients =
              Uri.file(File('./test/assets/img.jpg').absolute.path)));
  });

  testWidgets('vegan group presence when product has data',
      (WidgetTester tester) async {
    uiInputElementPresenceGeneralTest(tester,
        filledElementKey: 'vegan_status_group',
        expectedDisplayedAfterLangChange: false,
        initialProduct: ProductLangSlice((v) => v
          ..lang = _DEFAULT_TEST_LANG
          ..barcode = '123'
          ..veganStatus = VegStatus.positive
          ..veganStatusSource = VegStatusSource.community));
  });

  testWidgets('vegan group present when product has vegan data from OFF',
      (WidgetTester tester) async {
    uiInputElementPresenceGeneralTest(tester,
        filledElementKey: 'vegan_status_group',
        expectedInitiallyDisplayed: true,
        initialProduct: ProductLangSlice((v) => v
          ..lang = _DEFAULT_TEST_LANG
          ..barcode = '123'
          ..veganStatus = VegStatus.positive
          ..veganStatusSource = VegStatusSource.open_food_facts));
  });

  testWidgets('vegan group present when product has vegan data without source',
      (WidgetTester tester) async {
    uiInputElementPresenceGeneralTest(tester,
        filledElementKey: 'vegan_status_group',
        expectedInitiallyDisplayed: true,
        initialProduct: ProductLangSlice((v) => v
          ..lang = _DEFAULT_TEST_LANG
          ..barcode = '123'
          ..veganStatus = VegStatus.positive));
  });

  testWidgets('cannot save product without name', (WidgetTester tester) async {
    final done =
        await generalTest(tester, nameInput: null, expectedProductResult: null);
    expect(done, isFalse);
  });

  testWidgets('can save product without brand', (WidgetTester tester) async {
    final expectedProduct = ProductLangSlice((v) => v
      ..lang = _DEFAULT_TEST_LANG
      ..barcode = '123'
      ..name = 'Lemon drink'
      ..brands = null
      ..imageFront = Uri.file(File('./test/assets/img.jpg').absolute.path)
      ..imageIngredients = Uri.file(File('./test/assets/img.jpg').absolute.path)
      ..ingredientsText = 'water, lemon'
      ..veganStatus = VegStatus.positive
      ..veganStatusSource = VegStatusSource.community).productForTests();

    final done = await generalTest(
      tester,
      expectedProductResult: expectedProduct,
      nameInput: expectedProduct.name,
      brandInput: null,
      takeImageFront: expectedProduct.imageFront != null,
      takeImageIngredients: expectedProduct.imageIngredients != null,
      veganStatusInput: expectedProduct.veganStatus,
    );

    expect(done, isTrue);
  });

  testWidgets('cannot save product without front image',
      (WidgetTester tester) async {
    final done = await generalTest(tester,
        takeImageFront: false, expectedProductResult: null);
    expect(done, isFalse);
  });

  testWidgets('cannot save product without ingredients image',
      (WidgetTester tester) async {
    final done = await generalTest(tester,
        takeImageIngredients: false, expectedProductResult: null);
    expect(done, isFalse);
  });

  testWidgets('can save product without ingredients text',
      (WidgetTester tester) async {
    final expectedProduct = ProductLangSlice((v) => v
      ..lang = _DEFAULT_TEST_LANG
      ..barcode = '123'
      ..name = 'Lemon drink'
      ..brands = ListBuilder<String>(['Nice brand'])
      ..imageFront = Uri.file(File('./test/assets/img.jpg').absolute.path)
      ..imageIngredients = Uri.file(File('./test/assets/img.jpg').absolute.path)
      ..ingredientsText = '' // Empty!
      ..veganStatus = VegStatus.positive
      ..veganStatusSource = VegStatusSource.community).productForTests();

    final done = await generalTest(tester,
        expectedProductResult: expectedProduct,
        nameInput: expectedProduct.name,
        brandInput: expectedProduct.brands!.join(', '),
        takeImageFront: expectedProduct.imageFront != null,
        takeImageIngredients: true,
        ingredientsTextOverride: '',
        veganStatusInput: expectedProduct.veganStatus,
        selectShops: [aShop]);

    expect(done, isTrue);
  });

  testWidgets('cannot save product without vegan status',
      (WidgetTester tester) async {
    final done = await generalTest(tester,
        veganStatusInput: null, expectedProductResult: null);
    expect(done, isFalse);
  });

  testWidgets('no shops selected when map opened', (WidgetTester tester) async {
    final expectedProduct = ProductLangSlice((v) => v
      ..lang = _DEFAULT_TEST_LANG
      ..barcode = '123'
      ..name = 'Lemon drink'
      ..brands = ListBuilder<String>(['Nice brand'])
      ..imageFront = Uri.file(File('./test/assets/img.jpg').absolute.path)
      ..imageIngredients = Uri.file(File('./test/assets/img.jpg').absolute.path)
      ..ingredientsText = 'water, lemon'
      ..veganStatus = VegStatus.positive
      ..veganStatusSource = VegStatusSource.community).productForTests();

    final done = await generalTest(tester,
        expectedProductResult: expectedProduct,
        nameInput: expectedProduct.name,
        brandInput: expectedProduct.brands!.join(', '),
        takeImageFront: expectedProduct.imageFront != null,
        takeImageIngredients: expectedProduct.imageIngredients != null,
        veganStatusInput: expectedProduct.veganStatus,
        selectShops: [] // No shop
        );

    expect(done, isTrue);
  });

  testWidgets(
      'shops sending to server finishes with error but all other things are ok',
      (WidgetTester tester) async {
    final perfectlyGoodExpectedProduct = ProductLangSlice((v) => v
      ..lang = _DEFAULT_TEST_LANG
      ..barcode = '123'
      ..name = 'Lemon drink'
      ..brands = ListBuilder<String>(['Nice brand'])
      ..imageFront = Uri.file(File('./test/assets/img.jpg').absolute.path)
      ..imageIngredients = Uri.file(File('./test/assets/img.jpg').absolute.path)
      ..ingredientsText = 'water, lemon'
      ..veganStatus = VegStatus.positive
      ..veganStatusSource = VegStatusSource.community).productForTests();

    when(shopsManager.putProductToShops(any, any, any))
        .thenAnswer((_) async => Err(ShopsManagerError.OTHER));

    final done = await generalTest(tester,
        expectedProductResult: perfectlyGoodExpectedProduct,
        nameInput: perfectlyGoodExpectedProduct.name,
        brandInput: perfectlyGoodExpectedProduct.brands!.join(', '),
        takeImageFront: perfectlyGoodExpectedProduct.imageFront != null,
        takeImageIngredients:
            perfectlyGoodExpectedProduct.imageIngredients != null,
        veganStatusInput: perfectlyGoodExpectedProduct.veganStatus,
        selectShops: [aShop]);

    // Even though perfectlyGoodExpectedProduct expected to be stored,
    // page is expected to be not finished, because of shops sending error
    expect(done, isFalse);
    expect(analytics.sentEventParams('product_save_shops_failure'),
        equals({'barcode': perfectlyGoodExpectedProduct.barcode}));
  });

  testWidgets(
      'product saving to server finishes with error but all other things are ok',
      (WidgetTester tester) async {
    final perfectlyGoodExpectedProduct = ProductLangSlice((v) => v
      ..lang = _DEFAULT_TEST_LANG
      ..barcode = '123'
      ..name = 'Lemon drink'
      ..brands = ListBuilder<String>(['Nice brand'])
      ..imageFront = Uri.file(File('./test/assets/img.jpg').absolute.path)
      ..imageIngredients = Uri.file(File('./test/assets/img.jpg').absolute.path)
      ..ingredientsText = 'water, lemon'
      ..veganStatus = VegStatus.positive
      ..veganStatusSource = VegStatusSource.community).productForTests();

    when(productsManager.createUpdateProduct(any)).thenAnswer((_) async {
      return Err(ProductsManagerError.OTHER);
    });

    final done = await generalTest(
      tester,
      expectedProductResult: perfectlyGoodExpectedProduct,
      nameInput: perfectlyGoodExpectedProduct.name,
      brandInput: perfectlyGoodExpectedProduct.brands!.join(', '),
      takeImageFront: perfectlyGoodExpectedProduct.imageFront != null,
      takeImageIngredients:
          perfectlyGoodExpectedProduct.imageIngredients != null,
      veganStatusInput: perfectlyGoodExpectedProduct.veganStatus,
    );

    // Even though perfectlyGoodExpectedProduct expected to be stored,
    // page is expected to be not finished, because of product saving error
    expect(done, isFalse);
    expect(analytics.sentEventParams('product_save_failure'),
        equals({'barcode': perfectlyGoodExpectedProduct.barcode}));
  });

  testWidgets('ocr fail and manual ingredients input',
      (WidgetTester tester) async {
    final perfectlyGoodExpectedProduct = ProductLangSlice((v) => v
      ..lang = _DEFAULT_TEST_LANG
      ..barcode = '123'
      ..name = 'Lemon drink'
      ..brands = ListBuilder<String>(['Nice brand'])
      ..imageFront = Uri.file(File('./test/assets/img.jpg').absolute.path)
      ..imageIngredients = Uri.file(File('./test/assets/img.jpg').absolute.path)
      ..ingredientsText = 'water, lemon'
      ..veganStatus = VegStatus.positive
      ..veganStatusSource = VegStatusSource.community).productForTests();

    final done = await generalTest(tester,
        expectedProductResult: perfectlyGoodExpectedProduct,
        nameInput: perfectlyGoodExpectedProduct.name,
        brandInput: perfectlyGoodExpectedProduct.brands!.join(', '),
        takeImageFront: perfectlyGoodExpectedProduct.imageFront != null,
        takeImageIngredients:
            perfectlyGoodExpectedProduct.imageIngredients != null,
        veganStatusInput: perfectlyGoodExpectedProduct.veganStatus,
        // 2 OCRs attempts will fail (first (auto) and the manual)
        // Note that we multiply the value by InitProductPageModel.OCR_RETRIES_COUNT,
        // because the page auto-retries OCR without user actions.
        ocrSuccessfulAttemptNumber: 3 * InitProductPageModel.OCR_RETRIES_COUNT,
        requiredManualOcrAttempts:
            1, // We'll try to perform restart OCR only once
        ingredientsTextOverride:
            'water, lemon' // But will write ingredients manually
        );

    expect(done, isTrue);
  });

  testWidgets('ocr fail and successful retry', (WidgetTester tester) async {
    final perfectlyGoodExpectedProduct = ProductLangSlice((v) => v
      ..lang = _DEFAULT_TEST_LANG
      ..barcode = '123'
      ..name = 'Lemon drink'
      ..brands = ListBuilder<String>(['Nice brand'])
      ..imageFront = Uri.file(File('./test/assets/img.jpg').absolute.path)
      ..imageIngredients = Uri.file(File('./test/assets/img.jpg').absolute.path)
      ..ingredientsText = 'water, lemon'
      ..veganStatus = VegStatus.positive
      ..veganStatusSource = VegStatusSource.community).productForTests();

    final done = await generalTest(tester,
        expectedProductResult: perfectlyGoodExpectedProduct,
        nameInput: perfectlyGoodExpectedProduct.name,
        brandInput: perfectlyGoodExpectedProduct.brands!.join(', '),
        takeImageFront: perfectlyGoodExpectedProduct.imageFront != null,
        takeImageIngredients:
            perfectlyGoodExpectedProduct.imageIngredients != null,
        veganStatusInput: perfectlyGoodExpectedProduct.veganStatus,
        // 2 OCRs attempts will fail (first (auto) and the first manual).
        // Note that we multiply the value by InitProductPageModel.OCR_RETRIES_COUNT,
        // because the page auto-retries OCR without user actions.
        ocrSuccessfulAttemptNumber: 3 * InitProductPageModel.OCR_RETRIES_COUNT,
        requiredManualOcrAttempts: 2, // We'll try to perform a second OCR!
        ingredientsTextOverride: null // And will NOT write ingredients manually
        );

    expect(done, isTrue);
  });

  testWidgets('opened with initial shops', (WidgetTester tester) async {
    final product = ProductLangSlice((v) => v
      ..lang = _DEFAULT_TEST_LANG
      ..barcode = '123'
      ..name = 'Lemon drink'
      ..brands = ListBuilder<String>(['Nice brand'])
      ..imageFront = Uri.file(File('./test/assets/img.jpg').absolute.path)
      ..imageIngredients = Uri.file(File('./test/assets/img.jpg').absolute.path)
      ..ingredientsText = 'water, lemon'
      ..veganStatus = VegStatus.positive
      ..veganStatusSource = VegStatusSource.community).productForTests();

    final done = await generalTest(tester,
        expectedProductResult: product,
        nameInput: product.name,
        brandInput: product.brands!.join(', '),
        takeImageFront: product.imageFront != null,
        takeImageIngredients: product.imageIngredients != null,
        veganStatusInput: product.veganStatus,
        initialShops: [aShop]);

    expect(done, isTrue);
  });

  testWidgets('add non-vegan product to map', (WidgetTester tester) async {
    final widget = InitProductPage(Product((v) => v
      ..barcode = '123'
      ..langsPrioritized.add(_DEFAULT_TEST_LANG)
      ..veganStatus = VegStatus.negative));
    final context = await tester.superPump(widget);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('shops_btn')));
    await tester.pumpAndSettle();

    expect(find.byType(SnackBar), findsOneWidget);
    expect(
        find.text(context.strings.init_product_page_adding_non_vegan_product),
        findsOneWidget);
    expect(find.byType(MapPage), findsNothing);
  });

  testWidgets('add vegan product to map', (WidgetTester tester) async {
    final widget = InitProductPage(Product((v) => v
      ..barcode = '123'
      ..langsPrioritized.add(_DEFAULT_TEST_LANG)
      ..veganStatus = VegStatus.positive));
    await tester.superPump(widget);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('shops_btn')));
    await tester.pumpAndSettle();

    expect(find.byType(MapPage), findsOneWidget);
  });

  testWidgets('opened with initial shops, then select shops',
      (WidgetTester tester) async {
    final product = ProductLangSlice((v) => v
      ..lang = _DEFAULT_TEST_LANG
      ..barcode = '123'
      ..name = 'Lemon drink'
      ..brands = ListBuilder<String>(['Nice brand'])
      ..imageFront = Uri.file(File('./test/assets/img.jpg').absolute.path)
      ..imageIngredients = Uri.file(File('./test/assets/img.jpg').absolute.path)
      ..ingredientsText = 'water, lemon'
      ..veganStatus = VegStatus.positive
      ..veganStatusSource = VegStatusSource.community).productForTests();

    final shops = [
      Shop((e) => e
        ..osmShop.replace(OsmShop((e) => e
          ..osmUID = OsmUID.parse('1:1')
          ..longitude = 11
          ..latitude = 11
          ..name = 'Spar'))
        ..backendShop.replace(BackendShop((e) => e
          ..osmUID = OsmUID.parse('1:1')
          ..productsCount = 2))),
      Shop((e) => e
        ..osmShop.replace(OsmShop((e) => e
          ..osmUID = OsmUID.parse('1:2')
          ..longitude = 11
          ..latitude = 11
          ..name = 'Spar'))
        ..backendShop.replace(BackendShop((e) => e
          ..osmUID = OsmUID.parse('1:2')
          ..productsCount = 2))),
    ];

    final done = await generalTest(
      tester,
      expectedProductResult: product,
      nameInput: product.name,
      brandInput: product.brands!.join(', '),
      takeImageFront: product.imageFront != null,
      takeImageIngredients: product.imageIngredients != null,
      veganStatusInput: product.veganStatus,
      initialShops: [shops[0]],
      selectShops: [shops[1]],
    );

    expect(done, isTrue);
  });

  testWidgets('cancel initial and selected shops', (WidgetTester tester) async {
    final product = ProductLangSlice((v) => v
      ..lang = _DEFAULT_TEST_LANG
      ..barcode = '123'
      ..name = 'Lemon drink'
      ..brands = ListBuilder<String>(['Nice brand'])
      ..imageFront = Uri.file(File('./test/assets/img.jpg').absolute.path)
      ..imageIngredients = Uri.file(File('./test/assets/img.jpg').absolute.path)
      ..ingredientsText = 'water, lemon'
      ..veganStatus = VegStatus.positive
      ..veganStatusSource = VegStatusSource.community).productForTests();

    final shops = [
      Shop((e) => e
        ..osmShop.replace(OsmShop((e) => e
          ..osmUID = OsmUID.parse('1:1')
          ..longitude = 11
          ..latitude = 11
          ..name = 'Spar'))
        ..backendShop.replace(BackendShop((e) => e
          ..osmUID = OsmUID.parse('1:1')
          ..productsCount = 2))),
      Shop((e) => e
        ..osmShop.replace(OsmShop((e) => e
          ..osmUID = OsmUID.parse('1:2')
          ..longitude = 11
          ..latitude = 11
          ..name = 'Spar'))
        ..backendShop.replace(BackendShop((e) => e
          ..osmUID = OsmUID.parse('1:2')
          ..productsCount = 2))),
      Shop((e) => e
        ..osmShop.replace(OsmShop((e) => e
          ..osmUID = OsmUID.parse('1:3')
          ..longitude = 11
          ..latitude = 11
          ..name = 'Spar'))
        ..backendShop.replace(BackendShop((e) => e
          ..osmUID = OsmUID.parse('1:3')
          ..productsCount = 2))),
      Shop((e) => e
        ..osmShop.replace(OsmShop((e) => e
          ..osmUID = OsmUID.parse('1:4')
          ..longitude = 11
          ..latitude = 11
          ..name = 'Spar'))
        ..backendShop.replace(BackendShop((e) => e
          ..osmUID = OsmUID.parse('1:4')
          ..productsCount = 2))),
    ];

    final done = await generalTest(
      tester,
      expectedProductResult: product,
      nameInput: product.name,
      brandInput: product.brands!.join(', '),
      takeImageFront: product.imageFront != null,
      takeImageIngredients: product.imageIngredients != null,
      veganStatusInput: product.veganStatus,
      initialShops: [shops[0], shops[1]],
      selectShops: [shops[2], shops[3]],
      shopsToCancel: [shops[1], shops[3]],
    );

    expect(done, isTrue);
  });

  testWidgets('product update does not erase existing veg statuses',
      (WidgetTester tester) async {
    final initialProduct = ProductLangSlice((v) => v
      ..lang = _NOT_DEFAULT_TEST_LANG
      ..barcode = '123'
      ..veganStatus = VegStatus.negative
      ..veganStatusSource = VegStatusSource.moderator).productForTests();

    final expectedProduct = ProductLangSlice((v) => v
      ..lang = _NOT_DEFAULT_TEST_LANG
      ..barcode = '123'
      ..name = 'Lemon drink'
      ..brands = ListBuilder<String>(['Nice brand'])
      ..imageFront = Uri.file(File('./test/assets/img.jpg').absolute.path)
      ..imageIngredients = Uri.file(File('./test/assets/img.jpg').absolute.path)
      ..ingredientsText = 'water, lemon'
      // Veg statuses and sources are expected to be same as
      // in the initial product
      ..veganStatus = initialProduct.veganStatus
      ..veganStatusSource = initialProduct.veganStatusSource).productForTests();

    final done = await generalTest(
      tester,
      initialProduct: initialProduct,
      expectedProductResult: expectedProduct,
      nameInput: expectedProduct.name,
      brandInput: expectedProduct.brands!.join(', '),
      takeImageFront: expectedProduct.imageFront != null,
      takeImageIngredients: expectedProduct.imageIngredients != null,
      veganStatusInput: null,
      selectLang: _NOT_DEFAULT_TEST_LANG,
    );

    expect(done, isTrue);
  });

  testWidgets('finish taking front photo when restoring',
      (WidgetTester tester) async {
    when(productsManager.updateProductAndExtractIngredients(any, any))
        .thenAnswer((invoc) async => Ok(ProductWithOCRIngredients(
            invoc.positionalArguments[0] as Product, 'water, lemon')));

    // Lost photo exists!
    when(photosTaker.retrieveLostPhoto(PhotoRequester.PRODUCT_INIT))
        .thenAnswer((_) async => Ok(Uri.parse('./test/assets/img.jpg')));

    verifyNever(
        photosTaker.cropPhoto(any, any, any, minSize: anyNamed('minSize')));

    final widget = InitProductPage(
        ProductLangSlice((v) => v
          ..lang = _DEFAULT_TEST_LANG
          ..barcode = '123').productForTests(),
        photoBeingTakenForTests: ProductImageType.FRONT);
    await tester.superPump(widget);

    // Lost photo cropping expected to be started
    verify(photosTaker.cropPhoto(any, any, any, minSize: anyNamed('minSize')));

    // Now let's fill the product and ensure it's filled enough to be saved
    // The front photo is not taken by us as we expect it to be restored.
    await tester.enterText(find.byKey(const Key('name')), 'hello there');
    await tester.pumpAndSettle();

    await scrollToBottom(tester);
    await tester.tap(find.byKey(const Key('ingredients_photo')));
    await tester.pumpAndSettle();

    await scrollToBottom(tester);
    await tester.tap(find.byKey(const Key('vegan_positive_btn')));
    await tester.pumpAndSettle();

    verifyNever(productsManager.createUpdateProduct(any));
    await tester.tap(find.byKey(const Key('done_btn')));
    await tester.pumpAndSettle();
    verify(productsManager.createUpdateProduct(captureAny));
  });

  testWidgets('finish taking ingredients photo when restoring',
      (WidgetTester tester) async {
    when(productsManager.updateProductAndExtractIngredients(any, any))
        .thenAnswer((invoc) async => Ok(ProductWithOCRIngredients(
            invoc.positionalArguments[0] as Product, 'water, lemon')));

    // Lost photo exists!
    when(photosTaker.retrieveLostPhoto(PhotoRequester.PRODUCT_INIT))
        .thenAnswer((_) async => Ok(Uri.parse('./test/assets/img.jpg')));

    verifyNever(
        photosTaker.cropPhoto(any, any, any, minSize: anyNamed('minSize')));
    verifyNever(productsManager.updateProductAndExtractIngredients(any, any));

    final widget = InitProductPage(
        Product((v) => v
          ..barcode = '123'
          ..langsPrioritized.add(_DEFAULT_TEST_LANG)),
        photoBeingTakenForTests: ProductImageType.INGREDIENTS);
    await tester.superPump(widget);

    // Lost photo cropping expected to be started
    verify(photosTaker.cropPhoto(any, any, any, minSize: anyNamed('minSize')));
    // Because the lost photo is an ingredients photo -
    // OCR is expected to be performed.
    verify(productsManager.updateProductAndExtractIngredients(any, any));

    // Now let's fill the product and ensure it's filled enough to be saved
    // The ingredients photo is not taken by us as we expect it to be restored.
    await tester.enterText(find.byKey(const Key('name')), 'hello there');
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('front_photo')));
    await tester.pumpAndSettle();

    await scrollToBottom(tester);
    await tester.tap(find.byKey(const Key('vegan_positive_btn')));
    await tester.pumpAndSettle();

    verifyNever(productsManager.createUpdateProduct(any));
    await tester.tap(find.byKey(const Key('done_btn')));
    await tester.pumpAndSettle();
    verify(productsManager.createUpdateProduct(captureAny));
  });

  Future<void> takePhotoWhenNoPermissionTest(
      WidgetTester tester, dynamic Function() takePhotoAction) async {
    when(permissionsManager.status(any))
        .thenAnswer((_) async => PermissionState.denied);
    when(permissionsManager.request(any)).thenAnswer((_) async {
      when(permissionsManager.status(any))
          .thenAnswer((_) async => PermissionState.granted);
      return PermissionState.granted;
    });

    final widget = InitProductPage(Product((v) => v
      ..barcode = '123'
      ..langsPrioritized.add(_DEFAULT_TEST_LANG)));
    await tester.superPump(widget);
    await tester.pumpAndSettle();

    verifyNever(permissionsManager.request(any));
    verifyNever(photosTaker.takeAndCropPhoto(any, any, any,
        minSize: anyNamed('minSize')));

    await takePhotoAction.call();

    verify(permissionsManager.request(PermissionKind.CAMERA));
    verify(photosTaker.takeAndCropPhoto(any, any, PhotoRequester.PRODUCT_INIT,
        minSize: anyNamed('minSize')));
  }

  Future<void> takePhotoWhenNoPermissionThenPermissionDeniedAgainTest(
      WidgetTester tester, dynamic Function() takePhotoAction) async {
    when(permissionsManager.status(any))
        .thenAnswer((_) async => PermissionState.denied);
    var requestsCount = 0;
    when(permissionsManager.request(any)).thenAnswer((_) async {
      requestsCount += 1;
      if (requestsCount <= 1) {
        return PermissionState.denied;
      }
      when(permissionsManager.status(any))
          .thenAnswer((_) async => PermissionState.granted);
      return PermissionState.granted;
    });

    final widget = InitProductPage(Product((v) => v
      ..barcode = '123'
      ..langsPrioritized.add(_DEFAULT_TEST_LANG)));
    await tester.superPump(widget);
    await tester.pumpAndSettle();

    verifyNever(permissionsManager.request(any));
    verifyNever(photosTaker.takeAndCropPhoto(any, any, any,
        minSize: anyNamed('minSize')));

    // First attempt with a deny
    await takePhotoAction.call();

    verify(permissionsManager.request(PermissionKind.CAMERA));
    verifyNever(photosTaker.takeAndCropPhoto(any, any, any,
        minSize: anyNamed('minSize')));

    // Second attempt with permission successfully granted
    await takePhotoAction.call();

    verify(permissionsManager.request(PermissionKind.CAMERA));
    verify(photosTaker.takeAndCropPhoto(any, any, PhotoRequester.PRODUCT_INIT,
        minSize: anyNamed('minSize')));
  }

  Future<void> takePhotoWhenNoPermissionPermanentlyTest(
      WidgetTester tester, dynamic Function() takePhotoAction) async {
    when(permissionsManager.status(any))
        .thenAnswer((_) async => PermissionState.denied);
    when(permissionsManager.request(any))
        .thenAnswer((_) async => PermissionState.permanentlyDenied);

    final widget = InitProductPage(Product((v) => v
      ..barcode = '123'
      ..langsPrioritized.add(_DEFAULT_TEST_LANG)));
    final context = await tester.superPump(widget);
    await tester.pumpAndSettle();

    verifyNever(permissionsManager.request(any));
    verifyNever(permissionsManager.openAppSettings());
    verifyNever(photosTaker.takeAndCropPhoto(any, any, any,
        minSize: anyNamed('minSize')));
    expect(
        find.text(context
            .strings.init_product_page_camera_permission_reasoning_settings),
        findsNothing);

    await takePhotoAction.call();

    verify(permissionsManager.request(any));
    verifyNever(permissionsManager.openAppSettings());
    verifyNever(photosTaker.takeAndCropPhoto(any, any, any,
        minSize: anyNamed('minSize')));
    expect(
        find.text(context
            .strings.init_product_page_camera_permission_reasoning_settings),
        findsOneWidget);

    await tester.tap(find.text(context.strings.global_open_app_settings));
    await tester.pumpAndSettle();

    verifyNever(permissionsManager.request(any));
    verify(permissionsManager.openAppSettings());
    verifyNever(photosTaker.takeAndCropPhoto(any, any, any,
        minSize: anyNamed('minSize')));
  }

  testWidgets('take front photo when no permission',
      (WidgetTester tester) async {
    await takePhotoWhenNoPermissionTest(tester, () async {
      await tester.tap(find.byKey(const Key('front_photo')));
      await tester.pumpAndSettle();
    });
  });

  testWidgets('take front photo when no permission, permission denied again',
      (WidgetTester tester) async {
    await takePhotoWhenNoPermissionThenPermissionDeniedAgainTest(tester,
        () async {
      await tester.tap(find.byKey(const Key('front_photo')));
      await tester.pumpAndSettle();
    });
  });

  testWidgets('take front photo when no permission permanently',
      (WidgetTester tester) async {
    await takePhotoWhenNoPermissionPermanentlyTest(tester, () async {
      await tester.tap(find.byKey(const Key('front_photo')));
      await tester.pumpAndSettle();
    });
  });

  testWidgets('take ingredients photo when no permission',
      (WidgetTester tester) async {
    await takePhotoWhenNoPermissionTest(tester, () async {
      await scrollToBottom(tester);
      await tester.tap(find.byKey(const Key('ingredients_photo')));
      await tester.pumpAndSettle();
    });
  });

  testWidgets(
      'take ingredients photo when no permission, permission denied again',
      (WidgetTester tester) async {
    await takePhotoWhenNoPermissionThenPermissionDeniedAgainTest(tester,
        () async {
      await scrollToBottom(tester);
      await tester.tap(find.byKey(const Key('ingredients_photo')));
      await tester.pumpAndSettle();
    });
  });

  testWidgets('take ingredients photo when no permission permanently',
      (WidgetTester tester) async {
    await takePhotoWhenNoPermissionPermanentlyTest(tester, () async {
      await scrollToBottom(tester);
      await tester.tap(find.byKey(const Key('ingredients_photo')));
      await tester.pumpAndSettle();
    });
  });

  testWidgets(
      'input language change does not immediately affect InputProductsLangStorage',
      (WidgetTester tester) async {
    final widget = InitProductPage(Product((v) => v
      ..barcode = '123'
      ..langsPrioritized.add(_DEFAULT_TEST_LANG)));
    await tester.superPump(widget);
    await tester.pumpAndSettle();

    // Select another lang
    final dropdown = find
        .byKey(const Key('product_lang'))
        .evaluate()
        .first
        .widget as DropdownPlante<LangCode?>;
    dropdown.onChanged!.call(_NOT_DEFAULT_TEST_LANG);
    await tester.pumpAndSettle();

    // Verify the input lang is not changed yet
    expect(inputProductsLangStorage.selectedCode, equals(_DEFAULT_TEST_LANG));
  });

  testWidgets('Only languages known to the user are offered',
      (WidgetTester tester) async {
    final context = await tester
        .superPump(InitProductPage(Product((v) => v.barcode = '123')));

    await tester.tap(find.byKey(const Key('product_lang')));
    await tester.pumpAndSettle();

    for (final langCode in LangCode.values) {
      if (_USER_LANGS.contains(langCode)) {
        expect(find.text(langCode.localize(context)), findsWidgets);
      } else {
        expect(find.text(langCode.localize(context)), findsNothing);
      }
    }
  });

  testWidgets('No crashes when no selected language',
      (WidgetTester tester) async {
    inputProductsLangStorage.selectedCode = null;
    await tester.superPump(InitProductPage(Product((v) => v.barcode = '123')));
    await tester.pumpAndSettle();
    expect(find.byType(InitProductPage), findsOneWidget);
  });
}
