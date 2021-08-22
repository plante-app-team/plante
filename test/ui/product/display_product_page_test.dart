import 'dart:io';

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
import 'package:plante/location/location_controller.dart';
import 'package:plante/logging/analytics.dart';
import 'package:plante/model/ingredient.dart';
import 'package:plante/model/lang_code.dart';
import 'package:plante/model/moderator_choice_reason.dart';
import 'package:plante/model/product.dart';
import 'package:plante/model/product_lang_slice.dart';
import 'package:plante/model/user_params.dart';
import 'package:plante/model/user_params_controller.dart';
import 'package:plante/model/veg_status.dart';
import 'package:plante/model/veg_status_source.dart';
import 'package:plante/model/viewed_products_storage.dart';
import 'package:plante/outside/backend/backend.dart';
import 'package:plante/outside/map/address_obtainer.dart';
import 'package:plante/outside/map/shops_manager.dart';
import 'package:plante/outside/products/products_manager.dart';
import 'package:plante/outside/products/products_manager_error.dart';
import 'package:plante/ui/map/latest_camera_pos_storage.dart';
import 'package:plante/ui/map/map_page.dart';
import 'package:plante/ui/photos_taker.dart';
import 'package:plante/ui/product/display_product_page.dart';
import 'package:plante/ui/product/init_product_page.dart';

import '../../common_mocks.mocks.dart';
import '../../widget_tester_extension.dart';
import '../../z_fakes/fake_analytics.dart';
import '../../z_fakes/fake_input_products_lang_storage.dart';
import '../../z_fakes/fake_shared_preferences.dart';
import '../../z_fakes/fake_user_langs_manager.dart';
import '../../z_fakes/fake_user_params_controller.dart';

const _DEFAULT_LANG = LangCode.en;

void main() {
  late MockProductsManager productsManager;
  late MockBackend backend;
  late MockLocationController locationController;
  late MockShopsManager shopsManager;
  late FakeUserParamsController userParamsController;
  late ViewedProductsStorage viewedProductsStorage;
  late FakeAnalytics analytics;
  late MockAddressObtainer addressObtainer;

  setUp(() async {
    await GetIt.I.reset();
    analytics = FakeAnalytics();
    GetIt.I.registerSingleton<Analytics>(analytics);

    productsManager = MockProductsManager();
    when(productsManager.createUpdateProduct(any)).thenAnswer(
        (invoc) async => Ok(invoc.positionalArguments[0] as Product));
    when(productsManager.updateProductAndExtractIngredients(any, any))
        .thenAnswer((_) async => Err(ProductsManagerError.OTHER));
    GetIt.I.registerSingleton<ProductsManager>(productsManager);

    backend = MockBackend();
    when(backend.sendReport(any, any)).thenAnswer((_) async => Ok(None()));
    GetIt.I.registerSingleton<Backend>(backend);

    GetIt.I.registerSingleton<LatestCameraPosStorage>(
        LatestCameraPosStorage(FakeSharedPreferences().asHolder()));
    GetIt.I.registerSingleton<InputProductsLangStorage>(
        FakeInputProductsLangStorage.fromCode(LangCode.en));

    userParamsController = FakeUserParamsController();
    final user = UserParams((v) => v
      ..backendClientToken = '123'
      ..backendId = '321'
      ..name = 'Bob'
      ..eatsEggs = false
      ..eatsMilk = false
      ..eatsHoney = false);
    await userParamsController.setUserParams(user);
    GetIt.I.registerSingleton<UserParamsController>(userParamsController);

    viewedProductsStorage =
        ViewedProductsStorage(loadPersistentProducts: false);
    GetIt.I.registerSingleton<ViewedProductsStorage>(viewedProductsStorage);

    locationController = MockLocationController();
    when(locationController.lastKnownPositionInstant()).thenReturn(null);
    when(locationController.lastKnownPosition()).thenAnswer((_) async => null);
    GetIt.I.registerSingleton<LocationController>(locationController);

    shopsManager = MockShopsManager();
    GetIt.I.registerSingleton<ShopsManager>(shopsManager);

    final photosTaker = MockPhotosTaker();
    GetIt.I.registerSingleton<PhotosTaker>(photosTaker);
    when(photosTaker.retrieveLostPhoto())
        .thenAnswer((realInvocation) async => null);

    GetIt.I.registerSingleton<PermissionsManager>(MockPermissionsManager());

    addressObtainer = MockAddressObtainer();
    GetIt.I.registerSingleton<AddressObtainer>(addressObtainer);

    GetIt.I.registerSingleton<UserLangsManager>(
        FakeUserLangsManager([LangCode.en]));
  });

  /// See DisplayProductPage.ingredientsAnalysisTable
  String ingredientsTableColumn(TableRow row, int column) {
    if (column == 3) {
      column = 4;
    } else if (column == 2) {
      column = 2;
    } else if (column == 1) {
      // Already ok
    } else {
      // See DisplayProductPage.ingredientsAnalysisTable
      throw Exception('Column $column is not expected to have SVG');
    }

    final box1 = row.children![column] as SizedBox;
    final center = box1.child! as Center;
    final box2 = center.child! as SizedBox;
    return (box2.child! as Text).data!;
  }

  testWidgets('product is displayed', (WidgetTester tester) async {
    final product = ProductLangSlice((v) => v
      ..lang = _DEFAULT_LANG
      ..barcode = '123'
      ..name = 'My product'
      ..vegetarianStatus = VegStatus.possible
      ..vegetarianStatusSource = VegStatusSource.moderator
      ..veganStatus = VegStatus.negative
      ..veganStatusSource = VegStatusSource.moderator
      ..ingredientsText = 'Water, salt, sugar'
      ..ingredientsAnalyzed.addAll([
        Ingredient((v) => v
          ..name = 'ingredient1'
          ..vegetarianStatus = VegStatus.positive
          ..veganStatus = VegStatus.unknown),
        Ingredient((v) => v
          ..name = 'ingredient2'
          ..vegetarianStatus = null
          ..veganStatus = null),
      ])).buildSingleLangProduct();

    final context = await tester.superPump(DisplayProductPage(product));

    expect(find.text(product.name!), findsOneWidget);
    expect(find.text(product.ingredientsText!), findsWidgets);

    expect(find.text(context.strings.veg_status_displayed_not_vegan),
        findsOneWidget);
    expect(
        find.text(
            context.strings.veg_status_displayed_veg_status_source_moderator),
        findsOneWidget);

    final ingredientsAnalysisTable = find
        .byKey(const Key('ingredients_analysis_table'))
        .evaluate()
        .first
        .widget as Table;
    // 2 + header
    expect(ingredientsAnalysisTable.children.length, equals(3));

    final row1 = ingredientsAnalysisTable.children[1];
    expect(ingredientsTableColumn(row1, 1), equals('ingredient1'));
    expect(ingredientsTableColumn(row1, 2),
        equals(context.strings.display_product_page_table_positive));
    expect(ingredientsTableColumn(row1, 3),
        equals(context.strings.display_product_page_table_unknown));

    final row2 = ingredientsAnalysisTable.children[2];
    expect(ingredientsTableColumn(row2, 1), equals('ingredient2'));
    expect(ingredientsTableColumn(row2, 2),
        equals(context.strings.display_product_page_table_unknown));
    expect(ingredientsTableColumn(row2, 3),
        equals(context.strings.display_product_page_table_unknown));
  });

  testWidgets('same product for vegan and vegetarian',
      (WidgetTester tester) async {
    final product = ProductLangSlice((v) => v
      ..lang = _DEFAULT_LANG
      ..barcode = '123'
      ..name = 'My product'
      ..vegetarianStatus = VegStatus.unknown
      ..vegetarianStatusSource = VegStatusSource.open_food_facts
      ..veganStatus = VegStatus.negative
      ..veganStatusSource = VegStatusSource.community
      ..ingredientsText = 'Water, salt, sugar').buildSingleLangProduct();

    final vegan = UserParams((v) => v
      ..backendClientToken = '123'
      ..backendId = '321'
      ..name = 'Bob'
      ..eatsEggs = false
      ..eatsMilk = false
      ..eatsHoney = false);
    await userParamsController.setUserParams(vegan);
    var context = await tester
        .superPump(DisplayProductPage(product, key: const Key('page1')));
    expect(find.text(context.strings.veg_status_displayed_not_vegan),
        findsOneWidget);
    expect(
        find.text(
            context.strings.veg_status_displayed_veg_status_source_community),
        findsOneWidget);
    expect(
        find.text(
            context.strings.veg_status_displayed_vegetarian_status_unknown),
        findsNothing);
    expect(
        find.text(context.strings.veg_status_displayed_veg_status_source_off),
        findsNothing);

    final vegetarian = vegan.rebuild((v) => v.eatsMilk = true);
    await userParamsController.setUserParams(vegetarian);
    context = await tester
        .superPump(DisplayProductPage(product, key: const Key('page2')));
    expect(find.text(context.strings.veg_status_displayed_not_vegan),
        findsNothing);
    expect(
        find.text(
            context.strings.veg_status_displayed_veg_status_source_community),
        findsNothing);
    expect(
        find.text(
            context.strings.veg_status_displayed_vegetarian_status_unknown),
        findsOneWidget);
    expect(
        find.text(context.strings.veg_status_displayed_veg_status_source_off),
        findsOneWidget);
  });

  testWidgets('veg-statuses help button not displayed when sources are moderator',
      (WidgetTester tester) async {
    final product = ProductLangSlice((v) => v
      ..lang = _DEFAULT_LANG
      ..barcode = '123'
      ..name = 'My product'
      ..vegetarianStatus = VegStatus.possible
      ..vegetarianStatusSource = VegStatusSource.moderator
      ..veganStatus = VegStatus.negative
      ..veganStatusSource = VegStatusSource.moderator
      ..ingredientsText = 'Water, salt, sugar').buildSingleLangProduct();

    final context = await tester.superPump(DisplayProductPage(product));

    expect(
        find.text(context
            .strings.display_product_page_click_to_help_with_veg_statuses),
        findsNothing);
  });

  testWidgets('veg-statuses help button behaviour',
      (WidgetTester tester) async {
    final product = ProductLangSlice((v) => v
      ..lang = _DEFAULT_LANG
      ..barcode = '123'
      ..name = 'My product'
      ..imageFront = Uri.file(File('./test/assets/img.jpg').absolute.path)
      ..vegetarianStatus = VegStatus.possible
      ..vegetarianStatusSource = VegStatusSource.open_food_facts
      ..veganStatus = VegStatus.negative
      ..veganStatusSource = VegStatusSource.open_food_facts
      ..imageIngredients = Uri.file(File('./test/assets/img.jpg').absolute.path)
      ..ingredientsText = 'Water, salt, sugar').buildSingleLangProduct();

    final context = await tester.superPump(DisplayProductPage(product));

    // Initial status is from OFF
    expect(find.text(context.strings.veg_status_displayed_not_vegan),
        findsOneWidget);
    expect(
        find.text(context.strings.veg_status_displayed_veg_status_source_off),
        findsOneWidget);

    // Help button initially exists and help_with_veg_status_page doesn't
    expect(
        find.text(context
            .strings.display_product_page_click_to_help_with_veg_statuses),
        findsOneWidget);
    expect(find.byKey(const Key('help_with_veg_status_page')), findsNothing);

    await tester.tap(find.text(
        context.strings.display_product_page_click_to_help_with_veg_statuses));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('help_with_veg_status_page')), findsWidgets);

    await tester.tap(find.byKey(const Key('vegan_unknown_btn')));
    await tester.pumpAndSettle();
    await tester.tap(find.text(context.strings.global_done));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('help_with_veg_status_page')), findsNothing);
    expect(
        find.text(context
            .strings.display_product_page_click_to_help_with_veg_statuses), findsOneWidget);

    // Final veg status is changed and is from community
    expect(find.text(context.strings.veg_status_displayed_vegan_status_unknown),
        findsOneWidget);
    expect(
        find.text(
            context.strings.veg_status_displayed_veg_status_source_community),
        findsOneWidget);
  });

  testWidgets('send report', (WidgetTester tester) async {
    final product = ProductLangSlice((v) => v
      ..lang = _DEFAULT_LANG
      ..barcode = '123'
      ..name = 'My product'
      ..vegetarianStatus = VegStatus.possible
      ..vegetarianStatusSource = VegStatusSource.community
      ..veganStatus = VegStatus.negative
      ..veganStatusSource = VegStatusSource.moderator
      ..ingredientsText = 'Water, salt, sugar').buildSingleLangProduct();

    final context = await tester.superPump(DisplayProductPage(product));

    await tester.tap(find.byKey(const Key('options_button')));
    await tester.pumpAndSettle();
    await tester
        .tap(find.text(context.strings.display_product_page_report_btn));
    await tester.pumpAndSettle();

    verifyNever(backend.sendReport('123', 'Bad, bad product!'));

    await tester.enterText(
        find.byKey(const Key('report_text')), 'Bad, bad product!');
    await tester.pumpAndSettle();
    await tester.tap(find.text(context.strings.product_report_dialog_send));
    await tester.pumpAndSettle();

    verify(backend.sendReport('123', 'Bad, bad product!')).called(1);
  });

  testWidgets('viewed product is stored persistently',
      (WidgetTester tester) async {
    final product = ProductLangSlice((v) => v
      ..lang = _DEFAULT_LANG
      ..barcode = '123'
      ..name = 'My product'
      ..vegetarianStatus = VegStatus.possible
      ..vegetarianStatusSource = VegStatusSource.community
      ..veganStatus = VegStatus.negative
      ..veganStatusSource = VegStatusSource.moderator
      ..ingredientsText = 'Water, salt, sugar').buildSingleLangProduct();

    expect(viewedProductsStorage.getProducts(), equals([]));
    await tester.superPump(DisplayProductPage(product));
    expect(viewedProductsStorage.getProducts(), equals([product]));
  });

  testWidgets('click on photo opens photo screen', (WidgetTester tester) async {
    final product = ProductLangSlice((v) => v
      ..lang = _DEFAULT_LANG
      ..barcode = '123'
      ..name = 'My product'
      ..vegetarianStatus = VegStatus.possible
      ..vegetarianStatusSource = VegStatusSource.moderator
      ..veganStatus = VegStatus.negative
      ..veganStatusSource = VegStatusSource.moderator
      ..ingredientsText = 'Water, salt, sugar'
      ..ingredientsAnalyzed.addAll([
        Ingredient((v) => v
          ..name = 'ingredient1'
          ..vegetarianStatus = VegStatus.positive
          ..veganStatus = VegStatus.unknown),
        Ingredient((v) => v
          ..name = 'ingredient2'
          ..vegetarianStatus = null
          ..veganStatus = null),
      ])).buildSingleLangProduct();

    await tester.superPump(DisplayProductPage(product));

    expect(find.byKey(const Key('product_front_image_page')), findsNothing);
    expect(
        find.byKey(const Key('product_ingredients_image_page')), findsNothing);

    await tester.tap(find.byKey(const Key('product_header')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('product_front_image_page')), findsOneWidget);
    expect(
        find.byKey(const Key('product_ingredients_image_page')), findsNothing);
  });

  testWidgets('click on ingredients opens photo screen',
      (WidgetTester tester) async {
    final product = ProductLangSlice((v) => v
      ..lang = _DEFAULT_LANG
      ..barcode = '123'
      ..name = 'My product'
      ..vegetarianStatus = VegStatus.possible
      ..vegetarianStatusSource = VegStatusSource.moderator
      ..veganStatus = VegStatus.negative
      ..veganStatusSource = VegStatusSource.moderator
      ..ingredientsText = 'Water, salt, sugar'
      ..ingredientsAnalyzed.addAll([
        Ingredient((v) => v
          ..name = 'ingredient1'
          ..vegetarianStatus = VegStatus.positive
          ..veganStatus = VegStatus.unknown),
        Ingredient((v) => v
          ..name = 'ingredient2'
          ..vegetarianStatus = null
          ..veganStatus = null),
      ])).buildSingleLangProduct();

    final context = await tester.superPump(DisplayProductPage(product));

    expect(find.byKey(const Key('product_front_image_page')), findsNothing);
    expect(
        find.byKey(const Key('product_ingredients_image_page')), findsNothing);

    await tester
        .tap(find.text(context.strings.display_product_page_ingredients));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('product_front_image_page')), findsNothing);
    expect(find.byKey(const Key('product_ingredients_image_page')),
        findsOneWidget);
  });

  testWidgets('veg status hint - positive', (WidgetTester tester) async {
    final product = ProductLangSlice((v) => v
      ..lang = _DEFAULT_LANG
      ..barcode = '123'
      ..name = 'My product'
      ..vegetarianStatus = VegStatus.positive
      ..vegetarianStatusSource = VegStatusSource.moderator
      ..veganStatus = VegStatus.positive
      ..veganStatusSource = VegStatusSource.moderator
      ..ingredientsText = 'Water, salt, sugar'
      ..ingredientsAnalyzed.addAll([
        Ingredient((v) => v
          ..name = 'ingredient1'
          ..vegetarianStatus = VegStatus.positive
          ..veganStatus = VegStatus.unknown),
        Ingredient((v) => v
          ..name = 'ingredient2'
          ..vegetarianStatus = null
          ..veganStatus = null),
      ])).buildSingleLangProduct();

    final context = await tester.superPump(DisplayProductPage(product));

    expect(find.byKey(const Key('veg_status_hint')), findsOneWidget);
    expect(
        find.text(
            context.strings.display_product_page_veg_status_positive_warning),
        findsOneWidget);
  });

  testWidgets('veg status hint - negative', (WidgetTester tester) async {
    final product = ProductLangSlice((v) => v
      ..lang = _DEFAULT_LANG
      ..barcode = '123'
      ..name = 'My product'
      ..vegetarianStatus = VegStatus.negative
      ..vegetarianStatusSource = VegStatusSource.moderator
      ..veganStatus = VegStatus.negative
      ..veganStatusSource = VegStatusSource.moderator
      ..ingredientsText = 'Water, salt, sugar'
      ..ingredientsAnalyzed.addAll([
        Ingredient((v) => v
          ..name = 'ingredient1'
          ..vegetarianStatus = VegStatus.positive
          ..veganStatus = VegStatus.unknown),
        Ingredient((v) => v
          ..name = 'ingredient2'
          ..vegetarianStatus = null
          ..veganStatus = null),
      ])).buildSingleLangProduct();

    await tester.superPump(DisplayProductPage(product));

    expect(find.byKey(const Key('veg_status_hint')), findsNothing);
  });

  testWidgets('veg status hint - possible', (WidgetTester tester) async {
    final product = ProductLangSlice((v) => v
      ..lang = _DEFAULT_LANG
      ..barcode = '123'
      ..name = 'My product'
      ..vegetarianStatus = VegStatus.possible
      ..vegetarianStatusSource = VegStatusSource.moderator
      ..veganStatus = VegStatus.possible
      ..veganStatusSource = VegStatusSource.moderator
      ..ingredientsText = 'Water, salt, sugar'
      ..ingredientsAnalyzed.addAll([
        Ingredient((v) => v
          ..name = 'ingredient1'
          ..vegetarianStatus = VegStatus.positive
          ..veganStatus = VegStatus.unknown),
        Ingredient((v) => v
          ..name = 'ingredient2'
          ..vegetarianStatus = null
          ..veganStatus = null),
      ])).buildSingleLangProduct();

    final context = await tester.superPump(DisplayProductPage(product));

    expect(find.byKey(const Key('veg_status_hint')), findsOneWidget);
    expect(
        find.text(context
            .strings.display_product_page_veg_status_possible_explanation),
        findsOneWidget);
  });

  testWidgets('veg status hint - unknown', (WidgetTester tester) async {
    final product = ProductLangSlice((v) => v
      ..lang = _DEFAULT_LANG
      ..barcode = '123'
      ..name = 'My product'
      ..vegetarianStatus = VegStatus.unknown
      ..vegetarianStatusSource = VegStatusSource.moderator
      ..veganStatus = VegStatus.unknown
      ..veganStatusSource = VegStatusSource.moderator
      ..ingredientsText = 'Water, salt, sugar'
      ..ingredientsAnalyzed.addAll([
        Ingredient((v) => v
          ..name = 'ingredient1'
          ..vegetarianStatus = VegStatus.positive
          ..veganStatus = VegStatus.unknown),
        Ingredient((v) => v
          ..name = 'ingredient2'
          ..vegetarianStatus = null
          ..veganStatus = null),
      ])).buildSingleLangProduct();

    final context = await tester.superPump(DisplayProductPage(product));

    expect(find.byKey(const Key('veg_status_hint')), findsOneWidget);
    expect(
        find.text(context
            .strings.display_product_page_veg_status_unknown_explanation),
        findsOneWidget);
  });

  testWidgets('mark on map button', (WidgetTester tester) async {
    final product = ProductLangSlice((v) => v
      ..lang = _DEFAULT_LANG
      ..barcode = '123'
      ..name = 'My product'
      ..vegetarianStatus = VegStatus.unknown
      ..vegetarianStatusSource = VegStatusSource.moderator
      ..veganStatus = VegStatus.unknown
      ..veganStatusSource = VegStatusSource.moderator
      ..ingredientsText = 'Water, salt, sugar').buildSingleLangProduct();

    await tester.superPump(DisplayProductPage(product));

    expect(find.byType(MapPage), findsNothing);

    await tester.tap(find.byKey(const Key('mark_on_map')));
    await tester.pumpAndSettle();

    expect(find.byType(MapPage), findsOneWidget);
  });

  testWidgets('ingredients text displayed when present',
      (WidgetTester tester) async {
    final product = ProductLangSlice((v) => v
      ..lang = _DEFAULT_LANG
      ..barcode = '123'
      ..name = 'My product'
      ..imageFront = Uri.file(File('./test/assets/img.jpg').absolute.path)
      ..vegetarianStatus = VegStatus.possible
      ..vegetarianStatusSource = VegStatusSource.open_food_facts
      ..veganStatus = VegStatus.negative
      ..veganStatusSource = VegStatusSource.open_food_facts
      ..imageIngredients = Uri.file(File('./test/assets/img.jpg').absolute.path)
      ..ingredientsText = 'Water, salt, sugar').buildSingleLangProduct();

    await tester.superPump(DisplayProductPage(product));
    expect(find.byKey(const Key('product_ingredients_text')), findsOneWidget);
    expect(find.text('Water, salt, sugar'), findsOneWidget);
    expect(find.byKey(const Key('product_ingredients_photo')), findsNothing);
  });

  testWidgets('ingredients photo displayed when there is no ingredients text',
      (WidgetTester tester) async {
    final product = ProductLangSlice((v) => v
      ..lang = _DEFAULT_LANG
      ..barcode = '123'
      ..name = 'My product'
      ..imageFront = Uri.file(File('./test/assets/img.jpg').absolute.path)
      ..vegetarianStatus = VegStatus.possible
      ..vegetarianStatusSource = VegStatusSource.open_food_facts
      ..veganStatus = VegStatus.negative
      ..veganStatusSource = VegStatusSource.open_food_facts
      ..imageIngredients = Uri.file(File('./test/assets/img.jpg').absolute.path)
      ..ingredientsText = null).buildSingleLangProduct();

    await tester.superPump(DisplayProductPage(product));
    expect(find.byKey(const Key('product_ingredients_text')), findsNothing);
    expect(find.text('Water, salt, sugar'), findsNothing);
    expect(find.byKey(const Key('product_ingredients_photo')), findsOneWidget);
  });

  testWidgets('click on ingredients photo opens photo screen',
      (WidgetTester tester) async {
    final product = ProductLangSlice((v) => v
      ..lang = _DEFAULT_LANG
      ..barcode = '123'
      ..name = 'My product'
      ..imageFront = Uri.file(File('./test/assets/img.jpg').absolute.path)
      ..vegetarianStatus = VegStatus.possible
      ..vegetarianStatusSource = VegStatusSource.open_food_facts
      ..veganStatus = VegStatus.negative
      ..veganStatusSource = VegStatusSource.open_food_facts
      ..imageIngredients = Uri.file(File('./test/assets/img.jpg').absolute.path)
      ..ingredientsText = null).buildSingleLangProduct();

    await tester.superPump(DisplayProductPage(product));
    expect(find.byKey(const Key('product_ingredients_text')), findsNothing);
    expect(find.text('Water, salt, sugar'), findsNothing);
    expect(find.byKey(const Key('product_ingredients_photo')), findsOneWidget);

    expect(find.byKey(const Key('product_front_image_page')), findsNothing);
    expect(
        find.byKey(const Key('product_ingredients_image_page')), findsNothing);

    await tester.tap(find.byKey(const Key('product_ingredients_photo')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('product_front_image_page')), findsNothing);
    expect(find.byKey(const Key('product_ingredients_image_page')),
        findsOneWidget);
  });

  testWidgets('veg-statuses help button analytics',
      (WidgetTester tester) async {
    final product = ProductLangSlice((v) => v
      ..lang = _DEFAULT_LANG
      ..barcode = '123'
      ..name = 'My product'
      ..imageFront = Uri.file(File('./test/assets/img.jpg').absolute.path)
      ..vegetarianStatus = VegStatus.possible
      ..vegetarianStatusSource = VegStatusSource.open_food_facts
      ..veganStatus = VegStatus.negative
      ..veganStatusSource = VegStatusSource.open_food_facts
      ..imageIngredients = Uri.file(File('./test/assets/img.jpg').absolute.path)
      ..ingredientsText = 'Water, salt, sugar').buildSingleLangProduct();

    final context = await tester.superPump(DisplayProductPage(product));

    analytics.clearEvents();

    await tester.tap(find.text(
        context.strings.display_product_page_click_to_help_with_veg_statuses));
    await tester.pumpAndSettle();

    expect(analytics.allEvents().length, equals(1));
    expect(analytics.wasEventSent('help_with_vegan_statuses_started'), isTrue);
  });

  testWidgets('vegan status moderator reasoning and sources are shown on click',
      (WidgetTester tester) async {
    final product = ProductLangSlice((v) => v
      ..lang = _DEFAULT_LANG
      ..barcode = '123'
      ..name = 'My product'
      ..imageFront = Uri.file(File('./test/assets/img.jpg').absolute.path)
      ..imageIngredients = Uri.file(File('./test/assets/img.jpg').absolute.path)
      ..vegetarianStatus = VegStatus.negative
      ..vegetarianStatusSource = VegStatusSource.moderator
      ..veganStatus = VegStatus.negative
      ..veganStatusSource = VegStatusSource.moderator
      ..moderatorVegetarianChoiceReasonId =
          ModeratorChoiceReason.SOME_INGREDIENT_IS_NON_VEGETARIAN.persistentId
      ..moderatorVegetarianSourcesText = 'vegetarian source'
      ..moderatorVeganChoiceReasonId =
          ModeratorChoiceReason.SOME_INGREDIENT_IS_NON_VEGAN.persistentId
      ..moderatorVeganSourcesText = 'vegan source').buildSingleLangProduct();
    final vegan = UserParams((v) => v
      ..backendClientToken = '123'
      ..backendId = '321'
      ..name = 'Bob'
      ..eatsEggs = false
      ..eatsMilk = false
      ..eatsHoney = false);
    await userParamsController.setUserParams(vegan);

    final context = await tester.superPump(DisplayProductPage(product));

    expect(
        find.text(context
            .strings.display_product_page_moderator_comment_dialog_title),
        findsNothing);
    expect(
        find.text(ModeratorChoiceReason.SOME_INGREDIENT_IS_NON_VEGAN
            .localize(context)),
        findsNothing);
    expect(
        find.text(context
            .strings.display_product_page_moderator_comment_dialog_source),
        findsNothing);
    expect(find.text('vegan source'), findsNothing);
    expect(analytics.wasEventSent('moderator_comment_dialog_shown'), isFalse);

    await tester.tap(find.text(context.strings.veg_status_displayed_not_vegan));
    await tester.pumpAndSettle();

    expect(
        find.text(context
            .strings.display_product_page_moderator_comment_dialog_title),
        findsOneWidget);
    expect(
        find.text(ModeratorChoiceReason.SOME_INGREDIENT_IS_NON_VEGAN
            .localize(context)),
        findsOneWidget);
    expect(
        find.text(context
            .strings.display_product_page_moderator_comment_dialog_source),
        findsOneWidget);
    expect(find.text('vegan source'), findsOneWidget);
    expect(analytics.wasEventSent('moderator_comment_dialog_shown'), isTrue);
  });

  testWidgets(
      'vegetarian status moderator reasoning and sources are shown on click',
      (WidgetTester tester) async {
    final product = ProductLangSlice((v) => v
      ..lang = _DEFAULT_LANG
      ..barcode = '123'
      ..name = 'My product'
      ..imageFront = Uri.file(File('./test/assets/img.jpg').absolute.path)
      ..imageIngredients = Uri.file(File('./test/assets/img.jpg').absolute.path)
      ..vegetarianStatus = VegStatus.negative
      ..vegetarianStatusSource = VegStatusSource.moderator
      ..veganStatus = VegStatus.negative
      ..veganStatusSource = VegStatusSource.moderator
      ..moderatorVegetarianChoiceReasonId =
          ModeratorChoiceReason.SOME_INGREDIENT_IS_NON_VEGETARIAN.persistentId
      ..moderatorVegetarianSourcesText = 'vegetarian source'
      ..moderatorVeganChoiceReasonId =
          ModeratorChoiceReason.SOME_INGREDIENT_IS_NON_VEGAN.persistentId
      ..moderatorVeganSourcesText = 'vegan source').buildSingleLangProduct();
    final vegetarian = UserParams((v) => v
      ..backendClientToken = '123'
      ..backendId = '321'
      ..name = 'Bob'
      ..eatsEggs = true
      ..eatsMilk = true
      ..eatsHoney = true);
    await userParamsController.setUserParams(vegetarian);

    final context = await tester.superPump(DisplayProductPage(product));

    expect(
        find.text(context
            .strings.display_product_page_moderator_comment_dialog_title),
        findsNothing);
    expect(
        find.text(ModeratorChoiceReason.SOME_INGREDIENT_IS_NON_VEGETARIAN
            .localize(context)),
        findsNothing);
    expect(
        find.text(context
            .strings.display_product_page_moderator_comment_dialog_source),
        findsNothing);
    expect(find.text('vegetarian source'), findsNothing);
    expect(analytics.wasEventSent('moderator_comment_dialog_shown'), isFalse);

    await tester
        .tap(find.text(context.strings.veg_status_displayed_not_vegetarian));
    await tester.pumpAndSettle();

    expect(
        find.text(context
            .strings.display_product_page_moderator_comment_dialog_title),
        findsOneWidget);
    expect(
        find.text(ModeratorChoiceReason.SOME_INGREDIENT_IS_NON_VEGETARIAN
            .localize(context)),
        findsOneWidget);
    expect(
        find.text(context
            .strings.display_product_page_moderator_comment_dialog_source),
        findsOneWidget);
    expect(find.text('vegetarian source'), findsOneWidget);
    expect(analytics.wasEventSent('moderator_comment_dialog_shown'), isTrue);
  });

  testWidgets('vegan status moderator reasoning without sources',
      (WidgetTester tester) async {
    final product = ProductLangSlice((v) => v
      ..lang = _DEFAULT_LANG
      ..barcode = '123'
      ..name = 'My product'
      ..imageFront = Uri.file(File('./test/assets/img.jpg').absolute.path)
      ..imageIngredients = Uri.file(File('./test/assets/img.jpg').absolute.path)
      ..vegetarianStatus = VegStatus.negative
      ..vegetarianStatusSource = VegStatusSource.moderator
      ..veganStatus = VegStatus.negative
      ..veganStatusSource = VegStatusSource.moderator
      ..moderatorVegetarianChoiceReasonId =
          ModeratorChoiceReason.SOME_INGREDIENT_IS_NON_VEGETARIAN.persistentId
      ..moderatorVegetarianSourcesText = 'vegetarian source'
      ..moderatorVeganChoiceReasonId =
          ModeratorChoiceReason.SOME_INGREDIENT_IS_NON_VEGAN.persistentId
      ..moderatorVeganSourcesText = null).buildSingleLangProduct();
    final vegan = UserParams((v) => v
      ..backendClientToken = '123'
      ..backendId = '321'
      ..name = 'Bob'
      ..eatsEggs = false
      ..eatsMilk = false
      ..eatsHoney = false);
    await userParamsController.setUserParams(vegan);

    final context = await tester.superPump(DisplayProductPage(product));

    expect(
        find.text(context
            .strings.display_product_page_moderator_comment_dialog_title),
        findsNothing);
    expect(
        find.text(context
            .strings.display_product_page_moderator_comment_dialog_source),
        findsNothing);

    await tester.tap(find.text(context.strings.veg_status_displayed_not_vegan));
    await tester.pumpAndSettle();

    expect(
        find.text(context
            .strings.display_product_page_moderator_comment_dialog_title),
        findsOneWidget);
    expect(
        find.text(context
            .strings.display_product_page_moderator_comment_dialog_source),
        findsNothing);
  });

  testWidgets('vegetarian status moderator reasoning without sources',
      (WidgetTester tester) async {
    final product = ProductLangSlice((v) => v
      ..lang = _DEFAULT_LANG
      ..barcode = '123'
      ..name = 'My product'
      ..imageFront = Uri.file(File('./test/assets/img.jpg').absolute.path)
      ..imageIngredients = Uri.file(File('./test/assets/img.jpg').absolute.path)
      ..vegetarianStatus = VegStatus.negative
      ..vegetarianStatusSource = VegStatusSource.moderator
      ..veganStatus = VegStatus.negative
      ..veganStatusSource = VegStatusSource.moderator
      ..moderatorVegetarianChoiceReasonId =
          ModeratorChoiceReason.SOME_INGREDIENT_IS_NON_VEGETARIAN.persistentId
      ..moderatorVegetarianSourcesText = null
      ..moderatorVeganChoiceReasonId =
          ModeratorChoiceReason.SOME_INGREDIENT_IS_NON_VEGAN.persistentId
      ..moderatorVeganSourcesText = 'vegan source').buildSingleLangProduct();
    final vegetarian = UserParams((v) => v
      ..backendClientToken = '123'
      ..backendId = '321'
      ..name = 'Bob'
      ..eatsEggs = true
      ..eatsMilk = true
      ..eatsHoney = true);
    await userParamsController.setUserParams(vegetarian);

    final context = await tester.superPump(DisplayProductPage(product));

    expect(
        find.text(context
            .strings.display_product_page_moderator_comment_dialog_title),
        findsNothing);
    expect(
        find.text(context
            .strings.display_product_page_moderator_comment_dialog_source),
        findsNothing);

    await tester
        .tap(find.text(context.strings.veg_status_displayed_not_vegetarian));
    await tester.pumpAndSettle();

    expect(
        find.text(context
            .strings.display_product_page_moderator_comment_dialog_title),
        findsOneWidget);
    expect(
        find.text(context
            .strings.display_product_page_moderator_comment_dialog_source),
        findsNothing);
  });

  testWidgets(
      'vegan status moderator reasoning NOT shown on click '
      'when veg-source is not moderator', (WidgetTester tester) async {
    final product = ProductLangSlice((v) => v
      ..lang = _DEFAULT_LANG
      ..barcode = '123'
      ..name = 'My product'
      ..imageFront = Uri.file(File('./test/assets/img.jpg').absolute.path)
      ..imageIngredients = Uri.file(File('./test/assets/img.jpg').absolute.path)
      ..vegetarianStatus = VegStatus.negative
      ..vegetarianStatusSource = VegStatusSource.community
      ..veganStatus = VegStatus.negative
      ..veganStatusSource = VegStatusSource.community
      ..moderatorVegetarianChoiceReasonId =
          ModeratorChoiceReason.SOME_INGREDIENT_IS_NON_VEGETARIAN.persistentId
      ..moderatorVeganChoiceReasonId = ModeratorChoiceReason
          .SOME_INGREDIENT_IS_NON_VEGAN.persistentId).buildSingleLangProduct();
    final vegan = UserParams((v) => v
      ..backendClientToken = '123'
      ..backendId = '321'
      ..name = 'Bob'
      ..eatsEggs = false
      ..eatsMilk = false
      ..eatsHoney = false);
    await userParamsController.setUserParams(vegan);

    final context = await tester.superPump(DisplayProductPage(product));

    await tester.tap(find.text(context.strings.veg_status_displayed_not_vegan));
    await tester.pumpAndSettle();

    expect(
        find.text(context
            .strings.display_product_page_moderator_comment_dialog_title),
        findsNothing);
  });

  testWidgets(
      'vegetarian status moderator reasoning NOT shown on click when veg-source is not moderator',
      (WidgetTester tester) async {
    final product = ProductLangSlice((v) => v
      ..lang = _DEFAULT_LANG
      ..barcode = '123'
      ..name = 'My product'
      ..imageFront = Uri.file(File('./test/assets/img.jpg').absolute.path)
      ..imageIngredients = Uri.file(File('./test/assets/img.jpg').absolute.path)
      ..vegetarianStatus = VegStatus.negative
      ..vegetarianStatusSource = VegStatusSource.community
      ..veganStatus = VegStatus.negative
      ..veganStatusSource = VegStatusSource.community
      ..moderatorVegetarianChoiceReasonId =
          ModeratorChoiceReason.SOME_INGREDIENT_IS_NON_VEGETARIAN.persistentId
      ..moderatorVeganChoiceReasonId = ModeratorChoiceReason
          .SOME_INGREDIENT_IS_NON_VEGAN.persistentId).buildSingleLangProduct();
    final vegetarian = UserParams((v) => v
      ..backendClientToken = '123'
      ..backendId = '321'
      ..name = 'Bob'
      ..eatsEggs = true
      ..eatsMilk = true
      ..eatsHoney = true);
    await userParamsController.setUserParams(vegetarian);

    final context = await tester.superPump(DisplayProductPage(product));

    await tester
        .tap(find.text(context.strings.veg_status_displayed_not_vegetarian));
    await tester.pumpAndSettle();

    expect(
        find.text(context
            .strings.display_product_page_moderator_comment_dialog_title),
        findsNothing);
  });

  testWidgets(
      'vegan status moderator reasoning NOT shown on click when it does not exist',
      (WidgetTester tester) async {
    final product = ProductLangSlice((v) => v
      ..lang = _DEFAULT_LANG
      ..barcode = '123'
      ..name = 'My product'
      ..imageFront = Uri.file(File('./test/assets/img.jpg').absolute.path)
      ..imageIngredients = Uri.file(File('./test/assets/img.jpg').absolute.path)
      ..vegetarianStatus = VegStatus.negative
      ..vegetarianStatusSource = VegStatusSource.moderator
      ..veganStatus = VegStatus.negative
      ..veganStatusSource = VegStatusSource.moderator
      ..moderatorVegetarianChoiceReasonId = ModeratorChoiceReason
          .SOME_INGREDIENT_IS_NON_VEGAN.persistentId).buildSingleLangProduct();
    final vegan = UserParams((v) => v
      ..backendClientToken = '123'
      ..backendId = '321'
      ..name = 'Bob'
      ..eatsEggs = false
      ..eatsMilk = false
      ..eatsHoney = false);
    await userParamsController.setUserParams(vegan);

    final context = await tester.superPump(DisplayProductPage(product));

    await tester.tap(find.text(context.strings.veg_status_displayed_not_vegan));
    await tester.pumpAndSettle();

    expect(
        find.text(context
            .strings.display_product_page_moderator_comment_dialog_title),
        findsNothing);
  });

  Future<void> knownLanguagesTest(WidgetTester tester,
      {required LangCode productLang,
      required bool expectedFullyFilled}) async {
    final buildProductWith = (LangCode lang) {
      return ProductLangSlice((v) => v
            ..lang = lang
            ..barcode = '123'
            ..name = 'My product'
            ..imageFront = Uri.file(File('./test/assets/img.jpg').absolute.path)
            ..imageIngredients =
                Uri.file(File('./test/assets/img.jpg').absolute.path)
            ..vegetarianStatus = VegStatus.negative
            ..vegetarianStatusSource = VegStatusSource.moderator
            ..veganStatus = VegStatus.negative
            ..veganStatusSource = VegStatusSource.moderator)
          .buildSingleLangProduct();
    };

    final product = buildProductWith.call(productLang);
    final context = await tester.superPump(DisplayProductPage(product));
    await tester.pumpAndSettle();

    if (expectedFullyFilled) {
      expect(
          find.text(context.strings.display_product_page_no_info_in_your_langs),
          findsNothing);
      expect(analytics.wasEventSent('product_displayed_in_user_lang'), isTrue);
      expect(
          analytics.wasEventSent('product_displayed_in_foreign_lang'), isFalse);
      expect(
          analytics
              .wasEventSent('display_product_page_clicked_add_info_in_lang'),
          isFalse);
    } else {
      expect(
          find.text(context.strings.display_product_page_no_info_in_your_langs),
          findsOneWidget);
      expect(analytics.wasEventSent('product_displayed_in_user_lang'), isFalse);
      expect(
          analytics.wasEventSent('product_displayed_in_foreign_lang'), isTrue);
      expect(
          analytics
              .wasEventSent('display_product_page_clicked_add_info_in_lang'),
          isFalse);

      expect(find.byType(InitProductPage), findsNothing);
      await tester.tap(find
          .text(context.strings.display_product_page_add_info_in_your_langs));
      await tester.pumpAndSettle();
      expect(find.byType(InitProductPage), findsOneWidget);
      expect(analytics.wasEventSent('product_displayed_in_user_lang'), isFalse);
      expect(
          analytics.wasEventSent('product_displayed_in_foreign_lang'), isTrue);
      expect(
          analytics
              .wasEventSent('display_product_page_clicked_add_info_in_lang'),
          isTrue);
    }
  }

  testWidgets('product with all known to user langs',
      (WidgetTester tester) async {
    await knownLanguagesTest(tester,
        productLang: _DEFAULT_LANG, expectedFullyFilled: true);
  });

  testWidgets('product without all known to user langs',
      (WidgetTester tester) async {
    expect(_DEFAULT_LANG, isNot(equals(LangCode.nl)));
    await knownLanguagesTest(tester,
        productLang: LangCode.nl, expectedFullyFilled: false);
  });
}
