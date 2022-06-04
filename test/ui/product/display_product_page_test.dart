import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:plante/base/coord_utils.dart';
import 'package:plante/base/result.dart';
import 'package:plante/l10n/strings.dart';
import 'package:plante/logging/analytics.dart';
import 'package:plante/model/coord.dart';
import 'package:plante/model/ingredient.dart';
import 'package:plante/model/lang_code.dart';
import 'package:plante/model/moderator_choice_reason.dart';
import 'package:plante/model/product.dart';
import 'package:plante/model/product_lang_slice.dart';
import 'package:plante/model/shop.dart';
import 'package:plante/model/user_params.dart';
import 'package:plante/model/user_params_controller.dart';
import 'package:plante/model/veg_status.dart';
import 'package:plante/model/veg_status_source.dart';
import 'package:plante/outside/backend/backend_shop.dart';
import 'package:plante/outside/backend/user_reports_maker.dart';
import 'package:plante/outside/map/osm/osm_shop.dart';
import 'package:plante/outside/map/osm/osm_uid.dart';
import 'package:plante/outside/map/shops_manager.dart';
import 'package:plante/products/products_manager.dart';
import 'package:plante/products/products_manager_error.dart';
import 'package:plante/products/viewed_products_storage.dart';
import 'package:plante/ui/map/latest_camera_pos_storage.dart';
import 'package:plante/ui/map/map_page/map_page.dart';
import 'package:plante/ui/product/display_product_page.dart';
import 'package:plante/ui/product/display_product_page_model.dart';
import 'package:plante/ui/product/init_product_page.dart';

import '../../common_finders_extension.dart';
import '../../common_mocks.mocks.dart';
import '../../test_di_registry.dart';
import '../../widget_tester_extension.dart';
import '../../z_fakes/fake_analytics.dart';
import '../../z_fakes/fake_shared_preferences.dart';
import '../../z_fakes/fake_shops_manager.dart';
import '../../z_fakes/fake_user_params_controller.dart';

const _DEFAULT_LANG = LangCode.en;

void main() {
  final cameraPos = Coord(lat: 10, lon: 20);

  late MockProductsManager productsManager;
  late MockUserReportsMaker userReportsMaker;
  late FakeShopsManager shopsManager;
  late FakeUserParamsController userParamsController;
  late ViewedProductsStorage viewedProductsStorage;
  late FakeAnalytics analytics;
  late LatestCameraPosStorage cameraPosStorage;

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
    analytics = FakeAnalytics();
    productsManager = MockProductsManager();
    userReportsMaker = MockUserReportsMaker();
    viewedProductsStorage = ViewedProductsStorage();
    shopsManager = FakeShopsManager();
    userParamsController = FakeUserParamsController();
    cameraPosStorage =
        LatestCameraPosStorage(FakeSharedPreferences().asHolder());

    await TestDiRegistry.register((registry) {
      registry.register<Analytics>(analytics);
      registry.register<ProductsManager>(productsManager);
      registry.register<UserReportsMaker>(userReportsMaker);
      registry.register<ViewedProductsStorage>(viewedProductsStorage);
      registry.register<ShopsManager>(shopsManager);
      registry.register<UserParamsController>(userParamsController);
      registry.register<LatestCameraPosStorage>(cameraPosStorage);
    });

    when(productsManager.createUpdateProduct(any)).thenAnswer(
        (invoc) async => Ok(invoc.positionalArguments[0] as Product));
    when(productsManager.updateProductAndExtractIngredients(any, any))
        .thenAnswer((_) async => Err(ProductsManagerError.OTHER));

    when(userReportsMaker.reportProduct(any, any))
        .thenAnswer((_) async => Ok(None()));

    await userParamsController.setUserParams(UserParams((v) => v
      ..backendClientToken = '123'
      ..backendId = '321'
      ..name = 'Bob'));

    await cameraPosStorage.set(cameraPos);
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
      ..veganStatus = VegStatus.negative
      ..veganStatusSource = VegStatusSource.moderator
      ..ingredientsText = 'Water, salt, sugar'
      ..ingredientsAnalyzed.addAll([
        Ingredient((v) => v
          ..name = 'ingredient1'
          ..veganStatus = VegStatus.positive),
        Ingredient((v) => v
          ..name = 'en:ingredient2'
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

    final row2 = ingredientsAnalysisTable.children[2];
    expect(ingredientsTableColumn(row2, 1), equals('ingredient2'));
    expect(ingredientsTableColumn(row2, 2),
        equals(context.strings.display_product_page_table_unknown));
  });

  testWidgets(
      'veg-statuses help button not displayed when sources are moderator',
      (WidgetTester tester) async {
    final product = ProductLangSlice((v) => v
      ..lang = _DEFAULT_LANG
      ..barcode = '123'
      ..name = 'My product'
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

    await tester.tap(find.byKey(const Key('vegan_positive_btn')));
    await tester.pumpAndSettle();
    await tester.tap(find.text(context.strings.global_done));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('help_with_veg_status_page')), findsNothing);
    expect(
        find.text(context
            .strings.display_product_page_click_to_help_with_veg_statuses),
        findsNothing);

    // Final veg status is changed and is from community
    expect(
        find.text(context.strings.veg_status_displayed_vegan), findsOneWidget);
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
      ..veganStatus = VegStatus.negative
      ..veganStatusSource = VegStatusSource.moderator
      ..ingredientsText = 'Water, salt, sugar').buildSingleLangProduct();

    final context = await tester.superPump(DisplayProductPage(product));

    await tester.tap(find.byKey(const Key('options_button')));
    await tester.pumpAndSettle();
    await tester
        .tap(find.text(context.strings.display_product_page_report_btn));
    await tester.pumpAndSettle();

    verifyNever(userReportsMaker.reportProduct(any, any));

    await tester.enterText(
        find.byKey(const Key('report_text')), 'Bad, bad product!');
    await tester.pumpAndSettle();
    await tester.tap(find.text(context.strings.global_send));
    await tester.pumpAndSettle();

    verify(userReportsMaker.reportProduct('123', 'Bad, bad product!'))
        .called(1);
  });

  testWidgets('copy barcode', (WidgetTester tester) async {
    final product = ProductLangSlice((v) => v
      ..lang = _DEFAULT_LANG
      ..barcode = '123'
      ..name = 'My product'
      ..veganStatus = VegStatus.negative
      ..veganStatusSource = VegStatusSource.moderator
      ..ingredientsText = 'Water, salt, sugar').buildSingleLangProduct();

    final context = await tester.superPump(DisplayProductPage(product));

    await tester.superTap(find.byKey(const Key('options_button')));
    await tester
        .superTap(find.text(context.strings.display_product_page_barcode_btn));

    await tester.superTap(find.text(context.strings.global_copy));

    // NOTE: we don't test the actual content of the clipboard - the
    // clipboard package doesn't really like tests.
  });

  testWidgets('viewed product is stored persistently',
      (WidgetTester tester) async {
    final product = ProductLangSlice((v) => v
      ..lang = _DEFAULT_LANG
      ..barcode = '123'
      ..name = 'My product'
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
      ..veganStatus = VegStatus.negative
      ..veganStatusSource = VegStatusSource.moderator
      ..ingredientsText = 'Water, salt, sugar'
      ..ingredientsAnalyzed.addAll([
        Ingredient((v) => v
          ..name = 'ingredient1'
          ..veganStatus = VegStatus.unknown),
        Ingredient((v) => v
          ..name = 'ingredient2'
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
      ..veganStatus = VegStatus.negative
      ..veganStatusSource = VegStatusSource.moderator
      ..ingredientsText = 'Water, salt, sugar'
      ..ingredientsAnalyzed.addAll([
        Ingredient((v) => v
          ..name = 'ingredient1'
          ..veganStatus = VegStatus.unknown),
        Ingredient((v) => v
          ..name = 'ingredient2'
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
      ..veganStatus = VegStatus.positive
      ..veganStatusSource = VegStatusSource.moderator
      ..ingredientsText = 'Water, salt, sugar'
      ..ingredientsAnalyzed.addAll([
        Ingredient((v) => v
          ..name = 'ingredient1'
          ..veganStatus = VegStatus.unknown),
        Ingredient((v) => v
          ..name = 'ingredient2'
          ..veganStatus = null),
      ])).buildSingleLangProduct();

    final context = await tester.superPump(DisplayProductPage(product));

    expect(find.byKey(const Key('veg_status_hint')), findsOneWidget);
    expect(
        find.richTextContaining(
            context.strings.display_product_page_veg_status_positive_warning),
        findsOneWidget);
  });

  testWidgets('veg status hint - negative', (WidgetTester tester) async {
    final product = ProductLangSlice((v) => v
      ..lang = _DEFAULT_LANG
      ..barcode = '123'
      ..name = 'My product'
      ..veganStatus = VegStatus.negative
      ..veganStatusSource = VegStatusSource.moderator
      ..ingredientsText = 'Water, salt, sugar'
      ..ingredientsAnalyzed.addAll([
        Ingredient((v) => v
          ..name = 'ingredient1'
          ..veganStatus = VegStatus.unknown),
        Ingredient((v) => v
          ..name = 'ingredient2'
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
      ..veganStatus = VegStatus.possible
      ..veganStatusSource = VegStatusSource.moderator
      ..ingredientsText = 'Water, salt, sugar'
      ..ingredientsAnalyzed.addAll([
        Ingredient((v) => v
          ..name = 'ru:ingredient1'
          ..veganStatus = VegStatus.unknown),
        Ingredient((v) => v
          ..name = 'ingredient2'
          ..veganStatus = null),
      ])).buildSingleLangProduct();

    final context = await tester.superPump(DisplayProductPage(product));

    expect(find.byKey(const Key('veg_status_hint')), findsOneWidget);
    expect(
        find.richTextContaining(context
            .strings.display_product_page_veg_status_possible_explanation),
        findsOneWidget);
  });

  testWidgets('veg status hint - unknown', (WidgetTester tester) async {
    final product = ProductLangSlice((v) => v
      ..lang = _DEFAULT_LANG
      ..barcode = '123'
      ..name = 'My product'
      ..veganStatus = VegStatus.unknown
      ..veganStatusSource = VegStatusSource.moderator
      ..ingredientsText = 'Water, salt, sugar'
      ..ingredientsAnalyzed.addAll([
        Ingredient((v) => v
          ..name = 'ingredient1'
          ..veganStatus = VegStatus.unknown),
        Ingredient((v) => v
          ..name = 'nl:ingredient2'
          ..veganStatus = null),
      ])).buildSingleLangProduct();

    final context = await tester.superPump(DisplayProductPage(product));

    expect(find.byKey(const Key('veg_status_hint')), findsOneWidget);
    expect(
        find.richTextContaining(context
            .strings.display_product_page_veg_status_unknown_explanation),
        findsOneWidget);
  });

  testWidgets('mark on map button', (WidgetTester tester) async {
    final product = ProductLangSlice((v) => v
      ..lang = _DEFAULT_LANG
      ..barcode = '123'
      ..name = 'My product'
      ..veganStatus = VegStatus.unknown
      ..veganStatusSource = VegStatusSource.moderator
      ..ingredientsText = 'Water, salt, sugar').buildSingleLangProduct();

    await tester.superPump(DisplayProductPage(product));

    expect(find.byType(MapPage), findsNothing);

    await tester.tap(find.byKey(const Key('mark_on_map')));
    await tester.pumpAndSettle();

    expect(find.byType(MapPage), findsOneWidget);
  });

  testWidgets('mark on map button non-vegan product',
      (WidgetTester tester) async {
    final product = ProductLangSlice((v) => v
      ..lang = _DEFAULT_LANG
      ..barcode = '123'
      ..name = 'My product'
      ..veganStatus = VegStatus.negative
      ..veganStatusSource = VegStatusSource.moderator
      ..ingredientsText = 'Water, salt, sugar').buildSingleLangProduct();

    final context = await tester.superPump(DisplayProductPage(product));

    expect(find.byType(MapPage), findsNothing);

    await tester.tap(find.byKey(const Key('mark_on_map')));
    await tester.pumpAndSettle();

    expect(find.byType(SnackBar), findsOneWidget);
    expect(
        find.text(
            context.strings.display_product_page_adding_non_vegan_product),
        findsOneWidget);
    expect(find.byType(MapPage), findsNothing);
  });

  testWidgets('ingredients text displayed when present',
      (WidgetTester tester) async {
    final product = ProductLangSlice((v) => v
      ..lang = _DEFAULT_LANG
      ..barcode = '123'
      ..name = 'My product'
      ..imageFront = Uri.file(File('./test/assets/img.jpg').absolute.path)
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
      ..veganStatus = VegStatus.negative
      ..veganStatusSource = VegStatusSource.moderator
      ..moderatorVeganChoiceReasonsIds.addAll([
        ModeratorChoiceReason.SOME_INGREDIENT_IS_NON_VEGAN.persistentId,
        ModeratorChoiceReason.TESTED_ON_ANIMALS.persistentId,
      ])
      ..moderatorVeganSourcesText = 'vegan source').buildSingleLangProduct();
    final vegan = UserParams((v) => v
      ..backendClientToken = '123'
      ..backendId = '321'
      ..name = 'Bob');
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
    expect(find.text(ModeratorChoiceReason.TESTED_ON_ANIMALS.localize(context)),
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
    expect(find.text(ModeratorChoiceReason.TESTED_ON_ANIMALS.localize(context)),
        findsOneWidget);
    expect(
        find.text(context
            .strings.display_product_page_moderator_comment_dialog_source),
        findsOneWidget);
    expect(find.text('vegan source'), findsOneWidget);
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
      ..veganStatus = VegStatus.negative
      ..veganStatusSource = VegStatusSource.moderator
      ..moderatorVeganChoiceReasonsIds
          .add(ModeratorChoiceReason.SOME_INGREDIENT_IS_NON_VEGAN.persistentId)
      ..moderatorVeganSourcesText = null).buildSingleLangProduct();
    final vegan = UserParams((v) => v
      ..backendClientToken = '123'
      ..backendId = '321'
      ..name = 'Bob');
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

  testWidgets(
      'vegan status moderator reasoning NOT shown on click '
      'when veg-source is not moderator', (WidgetTester tester) async {
    final product = ProductLangSlice((v) => v
          ..lang = _DEFAULT_LANG
          ..barcode = '123'
          ..name = 'My product'
          ..imageFront = Uri.file(File('./test/assets/img.jpg').absolute.path)
          ..imageIngredients =
              Uri.file(File('./test/assets/img.jpg').absolute.path)
          ..veganStatus = VegStatus.negative
          ..veganStatusSource = VegStatusSource.community
          ..moderatorVeganChoiceReasonsIds.add(
              ModeratorChoiceReason.SOME_INGREDIENT_IS_NON_VEGAN.persistentId))
        .buildSingleLangProduct();
    final vegan = UserParams((v) => v
      ..backendClientToken = '123'
      ..backendId = '321'
      ..name = 'Bob');
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
      'vegan status moderator reasoning NOT shown on click when it does not exist',
      (WidgetTester tester) async {
    final product = ProductLangSlice((v) => v
      ..lang = _DEFAULT_LANG
      ..barcode = '123'
      ..name = 'My product'
      ..imageFront = Uri.file(File('./test/assets/img.jpg').absolute.path)
      ..imageIngredients = Uri.file(File('./test/assets/img.jpg').absolute.path)
      ..veganStatus = VegStatus.negative
      ..veganStatusSource = VegStatusSource.moderator).buildSingleLangProduct();
    final vegan = UserParams((v) => v
      ..backendClientToken = '123'
      ..backendId = '321'
      ..name = 'Bob');
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
      'vegan status moderator reasoning displayed on product page when it should be',
      (WidgetTester tester) async {
    expect(
        ModeratorChoiceReason
            .NON_VEGAN_PRACTICES_BUT_HELPS_VEGANISM.printWarningOnProduct,
        isTrue);

    final product = ProductLangSlice((v) => v
      ..lang = _DEFAULT_LANG
      ..barcode = '123'
      ..name = 'My product'
      ..imageFront = Uri.file(File('./test/assets/img.jpg').absolute.path)
      ..imageIngredients = Uri.file(File('./test/assets/img.jpg').absolute.path)
      ..veganStatus = VegStatus.possible
      ..veganStatusSource = VegStatusSource.moderator
      ..moderatorVeganChoiceReasonsIds.add(ModeratorChoiceReason
          .NON_VEGAN_PRACTICES_BUT_HELPS_VEGANISM
          .persistentId)).buildSingleLangProduct();

    final context = await tester.superPump(DisplayProductPage(product));
    expect(
        find.richTextContaining(ModeratorChoiceReason
            .NON_VEGAN_PRACTICES_BUT_HELPS_VEGANISM
            .localize(context)),
        findsOneWidget);
  });

  testWidgets(
      'vegan status moderator reasoning NOT displayed on product page when it should',
      (WidgetTester tester) async {
    expect(
        ModeratorChoiceReason
            .SOME_INGREDIENT_IS_POSSIBLY_NON_VEGAN.printWarningOnProduct,
        isFalse);

    final product = ProductLangSlice((v) => v
      ..lang = _DEFAULT_LANG
      ..barcode = '123'
      ..name = 'My product'
      ..imageFront = Uri.file(File('./test/assets/img.jpg').absolute.path)
      ..imageIngredients = Uri.file(File('./test/assets/img.jpg').absolute.path)
      ..veganStatus = VegStatus.possible
      ..veganStatusSource = VegStatusSource.moderator
      ..moderatorVeganChoiceReasonsIds.add(ModeratorChoiceReason
          .SOME_INGREDIENT_IS_POSSIBLY_NON_VEGAN
          .persistentId)).buildSingleLangProduct();

    final context = await tester.superPump(DisplayProductPage(product));

    expect(
        find.richTextContaining(ModeratorChoiceReason
            .NON_VEGAN_PRACTICES_BUT_HELPS_VEGANISM
            .localize(context)),
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

  testWidgets('can show shops on map', (WidgetTester tester) async {
    final product = ProductLangSlice((v) => v
      ..lang = _DEFAULT_LANG
      ..barcode = '123'
      ..name = 'My product'
      ..imageFront = Uri.file(File('./test/assets/img.jpg').absolute.path)
      ..imageIngredients = Uri.file(File('./test/assets/img.jpg').absolute.path)
      ..veganStatus = VegStatus.possible
      ..veganStatusSource = VegStatusSource.moderator).buildSingleLangProduct();

    // Sold in aShop
    shopsManager.setBarcodesCacheFor(aShop, ['123']);

    final context = await tester.superPump(DisplayProductPage(product));

    expect(find.text(context.strings.display_product_page_show_where_sold_v2),
        findsOneWidget);

    expect(find.byType(MapPage), findsNothing);
    await tester.superTap(
        find.text(context.strings.display_product_page_show_where_sold_v2));
    expect(find.byType(MapPage), findsOneWidget);

    final mapPage = find.byType(MapPage).evaluate().first.widget as MapPage;
    expect(
        mapPage.requestedMode, equals(MapPageRequestedMode.DEMONSTRATE_SHOPS));
    expect(mapPage.initialSelectedShops, equals([aShop]));
  });

  testWidgets('cannot show shops on map when no shops have the product',
      (WidgetTester tester) async {
    final product = ProductLangSlice((v) => v
      ..lang = _DEFAULT_LANG
      ..barcode = '123'
      ..name = 'My product'
      ..imageFront = Uri.file(File('./test/assets/img.jpg').absolute.path)
      ..imageIngredients = Uri.file(File('./test/assets/img.jpg').absolute.path)
      ..veganStatus = VegStatus.possible
      ..veganStatusSource = VegStatusSource.moderator).buildSingleLangProduct();

    // NOT sold in aShop
    // shopsManager.setBarcodesCacheFor(aShop, ['123']);

    final context = await tester.superPump(DisplayProductPage(product));

    expect(find.text(context.strings.display_product_page_show_where_sold_v2),
        findsNothing);
  });

  testWidgets('when map is not fetched around camera, the page fetches it',
      (WidgetTester tester) async {
    expect(
        await shopsManager.osmShopsCacheExistFor(cameraPos.makeSquare(0.001)),
        isFalse);

    final product = ProductLangSlice((v) => v
      ..lang = _DEFAULT_LANG
      ..barcode = '123'
      ..name = 'My product'
      ..imageFront = Uri.file(File('./test/assets/img.jpg').absolute.path)
      ..imageIngredients = Uri.file(File('./test/assets/img.jpg').absolute.path)
      ..veganStatus = VegStatus.possible
      ..veganStatusSource = VegStatusSource.moderator).buildSingleLangProduct();

    expect(shopsManager.calls_fetchShop().length, equals(0));
    await tester.superPump(DisplayProductPage(product));
    expect(shopsManager.calls_fetchShop().length, equals(1));
  });

  testWidgets('when map IS fetched around camera, the page does not fetches it',
      (WidgetTester tester) async {
    final productsSquare = cameraPos
        .makeSquare(kmToGrad(DisplayProductsPageModel.PRODUCT_SHOPS_SIZE_KMS));
    await shopsManager.fetchShops(productsSquare);
    expect(await shopsManager.osmShopsCacheExistFor(productsSquare), isTrue);
    shopsManager.clear_verifiedCalls();

    final product = ProductLangSlice((v) => v
      ..lang = _DEFAULT_LANG
      ..barcode = '123'
      ..name = 'My product'
      ..imageFront = Uri.file(File('./test/assets/img.jpg').absolute.path)
      ..imageIngredients = Uri.file(File('./test/assets/img.jpg').absolute.path)
      ..veganStatus = VegStatus.possible
      ..veganStatusSource = VegStatusSource.moderator).buildSingleLangProduct();

    await tester.superPump(DisplayProductPage(product));
    expect(shopsManager.calls_fetchShop().length, equals(0));
  });
}
