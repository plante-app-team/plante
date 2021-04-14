import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:untitled_vegan_app/base/result.dart';
import 'package:untitled_vegan_app/model/product.dart';
import 'package:untitled_vegan_app/model/veg_status.dart';
import 'package:untitled_vegan_app/model/veg_status_source.dart';
import 'package:untitled_vegan_app/outside/products/products_manager.dart';
import 'package:untitled_vegan_app/outside/products/products_manager_error.dart';
import 'package:untitled_vegan_app/ui/photos_taker.dart';
import 'package:untitled_vegan_app/ui/product/init_product_page.dart';
import 'package:untitled_vegan_app/l10n/strings.dart';

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
        Uri.file(File("./test/assets/img.jpg").absolute.path));
    GetIt.I.registerSingleton<PhotosTaker>(photosTaker);

    productsManager = MockProductsManager();
    when(productsManager.createUpdateProduct(any, any)).thenAnswer(
            (invoc) async => Ok(invoc.positionalArguments[0]));
    when(productsManager.updateProductAndExtractIngredients(any, any))
        .thenAnswer((_) async => Err(ProductsManagerError.OTHER));
    GetIt.I.registerSingleton<ProductsManager>(productsManager);
  });

  testWidgets("good flow", (WidgetTester tester) async {
    when(productsManager.updateProductAndExtractIngredients(any, any)).thenAnswer(
            (invoc) async => Ok(ProductWithOCRIngredients(
                invoc.positionalArguments[0],
                "water, lemon")));

    verifyZeroInteractions(productsManager);

    bool done = false;
    final callback = () {
      done = true;
    };
    final context = await tester.superPump(InitProductPage(
        Product((v) => v.barcode = "123"),
        doneCallback: callback));
    await tester.enterText(
        find.byKey(Key("name")),
        'Lemon drink');
    await tester.pumpAndSettle();

    verifyNever(productsManager.createUpdateProduct(any, any));
    await tester.tap(
        find.byKey(Key("page1_next_btn")));
    await tester.pumpAndSettle();
    verify(productsManager.createUpdateProduct(any, any)).called(1);

    verifyNever(photosTaker.takeAndCropPhoto(any));
    await tester.tap(
        find.byKey(Key("take_photo_icon")));
    verify(photosTaker.takeAndCropPhoto(any)).called(1);
    await tester.pumpAndSettle();

    verifyNever(productsManager.createUpdateProduct(any, any));
    await tester.tap(
        find.byKey(Key("page2_next_btn")));
    await tester.pumpAndSettle();
    verify(productsManager.createUpdateProduct(any, any)).called(1);

    verifyNever(photosTaker.takeAndCropPhoto(any));
    await tester.tap(
        find.byKey(Key("take_photo_icon")));
    verify(photosTaker.takeAndCropPhoto(any)).called(1);
    await tester.pumpAndSettle();

    expect(find.text("water, lemon"), findsNothing);
    await tester.tap(
        find.text(context.strings.init_product_page_ingredients_ocr));
    await tester.pumpAndSettle();
    expect(find.text("water, lemon"), findsOneWidget);

    verifyNever(productsManager.createUpdateProduct(any, any));
    await tester.tap(
        find.byKey(Key("page3_next_btn")));
    await tester.pumpAndSettle();
    verify(productsManager.createUpdateProduct(any, any)).called(1);

    await tester.tap(find.text(context.strings.init_product_page_possibly).first);
    await tester.tap(find.text(context.strings.init_product_page_possibly).last);
    await tester.pumpAndSettle();

    expect(done, isFalse);
    verifyNever(productsManager.createUpdateProduct(any, any));
    await tester.tap(
        find.byKey(Key("page4_next_btn")));
    await tester.pumpAndSettle();
    final finalProduct = verify(productsManager.createUpdateProduct(captureAny, any)).captured.first;
    expect(done, isTrue);

    final expectedProduct = Product((v) => v
      ..barcode = "123"
      ..name = "Lemon drink"
      ..imageFront = Uri.file(File("./test/assets/img.jpg").absolute.path)
      ..imageIngredients = Uri.file(File("./test/assets/img.jpg").absolute.path)
      ..ingredientsText = "water, lemon"
      ..vegetarianStatus = VegStatus.possible
      ..vegetarianStatusSource = VegStatusSource.community
      ..veganStatus = VegStatus.possible
      ..veganStatusSource = VegStatusSource.community);
    expect(finalProduct, equals(expectedProduct));
  });

  testWidgets("page 1 is skipped when product has data", (WidgetTester tester) async {
    final initialProduct = Product((v) => v
      ..barcode = "123"
      ..name = "Hello there");
    await tester.superPump(InitProductPage(initialProduct));

    expect(find.byKey(Key("page1")), findsNothing);
    expect(find.byKey(Key("page2")), findsWidgets);
  });

  testWidgets("page 2 is skipped when product has data", (WidgetTester tester) async {
    final initialProduct = Product((v) => v
      ..barcode = "123"
      ..name = "Hello there"
      ..imageFront = Uri.file(File("./test/assets/img.jpg").absolute.path));
    await tester.superPump(InitProductPage(initialProduct));

    expect(find.byKey(Key("page1")), findsNothing);
    expect(find.byKey(Key("page2")), findsNothing);
    expect(find.byKey(Key("page3")), findsWidgets);
  });

  testWidgets("page 3 is skipped when product has data", (WidgetTester tester) async {
    final initialProduct = Product((v) => v
      ..barcode = "123"
      ..name = "Hello there"
      ..imageFront = Uri.file(File("./test/assets/img.jpg").absolute.path)
      ..imageIngredients = Uri.file(File("./test/assets/img.jpg").absolute.path)
      ..ingredientsText = "water");
    await tester.superPump(InitProductPage(initialProduct));

    expect(find.byKey(Key("page1")), findsNothing);
    expect(find.byKey(Key("page2")), findsNothing);
    expect(find.byKey(Key("page3")), findsNothing);
    expect(find.byKey(Key("page4")), findsWidgets);
  });

  testWidgets("page 4 is skipped when product has data", (WidgetTester tester) async {
    // Product has everything except for name
    final initialProduct = Product((v) => v
      ..barcode = "123"
      ..imageFront = Uri.file(File("./test/assets/img.jpg").absolute.path)
      ..imageIngredients = Uri.file(File("./test/assets/img.jpg").absolute.path)
      ..ingredientsText = "water"
      ..vegetarianStatus = VegStatus.possible
      ..veganStatus = VegStatus.possible);
    bool done = false;
    final callback = () {
      done = true;
    };
    await tester.superPump(InitProductPage(initialProduct, doneCallback: callback));

    // At start at page1
    expect(find.byKey(Key("page1")), findsWidgets);
    expect(find.byKey(Key("page2")), findsNothing);
    expect(find.byKey(Key("page3")), findsNothing);
    expect(find.byKey(Key("page4")), findsNothing);

    await tester.enterText(
        find.byKey(Key("name")),
        'Lemon drink');
    await tester.pumpAndSettle();

    expect(done, isFalse);

    await tester.tap(
        find.byKey(Key("page1_next_btn")));
    await tester.pumpAndSettle();

    // Done after page1
    expect(done, isTrue);
  });

  testWidgets("page 4 is NOT skipped when veg statuses filled by OFF", (WidgetTester tester) async {
    // Product has everything except for name, veg-statuses source is OFF
    final initialProduct = Product((v) => v
      ..barcode = "123"
      ..imageFront = Uri.file(File("./test/assets/img.jpg").absolute.path)
      ..imageIngredients = Uri.file(File("./test/assets/img.jpg").absolute.path)
      ..ingredientsText = "water"
      ..vegetarianStatus = VegStatus.possible
      ..vegetarianStatusSource = VegStatusSource.open_food_facts
      ..veganStatus = VegStatus.possible
      ..veganStatusSource = VegStatusSource.open_food_facts);
    await tester.superPump(InitProductPage(initialProduct));

    // At start at page1
    expect(find.byKey(Key("page1")), findsWidgets);
    expect(find.byKey(Key("page2")), findsNothing);
    expect(find.byKey(Key("page3")), findsNothing);
    expect(find.byKey(Key("page4")), findsNothing);

    await tester.enterText(
        find.byKey(Key("name")),
        'Lemon drink');
    await tester.pumpAndSettle();
    await tester.tap(
        find.byKey(Key("page1_next_btn")));
    await tester.pumpAndSettle();

    // At page 4
    expect(find.byKey(Key("page1")), findsNothing);
    expect(find.byKey(Key("page2")), findsNothing);
    expect(find.byKey(Key("page3")), findsNothing);
    expect(find.byKey(Key("page4")), findsWidgets);
  });

  testWidgets("can't leave page 1 without product name", (WidgetTester tester) async {
    await tester.superPump(InitProductPage(
        Product((v) => v.barcode = "123")));

    await tester.tap(
        find.byKey(Key("page1_next_btn")));
    await tester.pumpAndSettle();

    // Still at page 1
    expect(find.byKey(Key("page1")), findsWidgets);
    expect(find.byKey(Key("page2")), findsNothing);
  });

  testWidgets("can't leave page 2 without front photo", (WidgetTester tester) async {
    final initialProduct = Product((v) => v
      ..barcode = "123"
      ..name = "Hello there");
    await tester.superPump(InitProductPage(initialProduct));

    await tester.tap(
        find.byKey(Key("page2_next_btn")));
    await tester.pumpAndSettle();

    // Still at page 2
    expect(find.byKey(Key("page2")), findsWidgets);
    expect(find.byKey(Key("page3")), findsNothing);
  });

  testWidgets("can't leave page 3 without both ingredients photo and text", (WidgetTester tester) async {
    final initialProduct = Product((v) => v
      ..barcode = "123"
      ..name = "Hello there"
      ..imageFront = Uri.file(File("./test/assets/img.jpg").absolute.path));
    await tester.superPump(InitProductPage(initialProduct));

    await tester.tap(
        find.byKey(Key("page3_next_btn")));
    await tester.pumpAndSettle();

    // Still at page 3
    expect(find.byKey(Key("page3")), findsWidgets);
    expect(find.byKey(Key("page4")), findsNothing);

    await tester.tap(
        find.byKey(Key("take_photo_icon")));
    await tester.pumpAndSettle();
    await tester.tap(
        find.byKey(Key("page3_next_btn")));
    await tester.pumpAndSettle();

    // Still at page 3!
    expect(find.byKey(Key("page3")), findsWidgets);
    expect(find.byKey(Key("page4")), findsNothing);

    await tester.enterText(find.byKey(Key("ingredients")), "water");
    await tester.pumpAndSettle();

    await tester.tap(
        find.byKey(Key("page3_next_btn")));
    await tester.pumpAndSettle();

    // Only now at page 4
    expect(find.byKey(Key("page3")), findsNothing);
    expect(find.byKey(Key("page4")), findsWidgets);
  });

  testWidgets("can't leave page 4 without veg-status data", (WidgetTester tester) async {
    final initialProduct = Product((v) => v
      ..barcode = "123"
      ..name = "Hello there"
      ..imageFront = Uri.file(File("./test/assets/img.jpg").absolute.path)
      ..imageIngredients = Uri.file(File("./test/assets/img.jpg").absolute.path)
      ..ingredientsText = "water");
    bool done = false;
    final callback = () {
      done = true;
    };
    final context = await tester.superPump(InitProductPage(
        initialProduct, doneCallback: callback));

    await tester.tap(
        find.byKey(Key("page4_next_btn")));
    await tester.pumpAndSettle();

    // Not done yet
    expect(done, isFalse);

    await tester.tap(find.text(context.strings.init_product_page_definitely_yes).first);
    await tester.pumpAndSettle();
    await tester.tap(
        find.byKey(Key("page4_next_btn")));
    await tester.pumpAndSettle();

    // Not done yet
    expect(done, isFalse);

    await tester.tap(find.text(context.strings.init_product_page_definitely_yes).last);
    await tester.pumpAndSettle();
    await tester.tap(
        find.byKey(Key("page4_next_btn")));
    await tester.pumpAndSettle();

    // Now done
    expect(done, isTrue);
  });

  testWidgets("cannot write ingredients text without ingredients photo", (WidgetTester tester) async {
    final initialProduct = Product((v) => v
      ..barcode = "123"
      ..name = "Hello there"
      ..imageFront = Uri.file(File("./test/assets/img.jpg").absolute.path));
    await tester.superPump(InitProductPage(initialProduct));

    // If there's no photo, then there's no ingredients TextField
    expect(find.byKey(Key("ingredients")), findsNothing);

    await tester.tap(
        find.byKey(Key("take_photo_icon")));
    await tester.pumpAndSettle();

    // And now that there are photos ingredients text can be written
    expect(find.byKey(Key("ingredients")), findsWidgets);
  });

  testWidgets("brand and categories are filled when product has them", (WidgetTester tester) async {
    final initialProduct = Product((v) => v
      ..barcode = "123"
      ..brands.addAll(["brand1", "brand2"])
      ..categories.addAll(["category1", "category2"]));
    await tester.superPump(InitProductPage(initialProduct));

    expect(find.text("brand1, brand2"), findsOneWidget);
    expect(find.text("category1, category2"), findsOneWidget);
  });

  testWidgets("veg statuses radio buttons not selected when "
      "statuses filled by OFF", (WidgetTester tester) async {
    // Product has everything except for name, veg-statuses source is OFF
    final initialProduct = Product((v) => v
      ..name = "name"
      ..barcode = "123"
      ..imageFront = Uri.file(File("./test/assets/img.jpg").absolute.path)
      ..imageIngredients = Uri.file(File("./test/assets/img.jpg").absolute.path)
      ..ingredientsText = "water"
      ..vegetarianStatus = VegStatus.possible
      ..vegetarianStatusSource = VegStatusSource.open_food_facts
      ..veganStatus = VegStatus.possible
      ..veganStatusSource = VegStatusSource.open_food_facts);
    await tester.superPump(InitProductPage(initialProduct));

    // At page 4
    expect(find.byKey(Key("page1")), findsNothing);
    expect(find.byKey(Key("page2")), findsNothing);
    expect(find.byKey(Key("page3")), findsNothing);
    expect(find.byKey(Key("page4")), findsWidgets);

    final buttons = find.byType(Radio).evaluate().map((e) => e.widget as Radio);
    expect(
        buttons.where((button) => button.groupValue != null).isEmpty,
        isTrue);
  });

  testWidgets("required pages shown even when product already has page's data",
          (WidgetTester tester) async {
    // Product already has name
    final initialProduct = Product((v) => v
      ..barcode = "123"
      ..name = "Hello there");
    await tester.superPump(
        InitProductPage(initialProduct, requiredPages: [InitProductSubpage.PAGE1]));

    expect(find.byKey(Key("page1")), findsWidgets);
    expect(find.byKey(Key("page2")), findsNothing);
    expect(find.byKey(Key("page3")), findsNothing);
    expect(find.byKey(Key("page4")), findsNothing);
  });

  testWidgets("only required pages shown even when product doesn't have data of other pages",
          (WidgetTester tester) async {
        // Product doesn't have a name
        final initialProduct = Product((v) => v
          ..barcode = "123");
        await tester.superPump(
            InitProductPage(initialProduct, requiredPages: [InitProductSubpage.PAGE2]));

        expect(find.byKey(Key("page1")), findsNothing);
        expect(find.byKey(Key("page2")), findsWidgets);
        expect(find.byKey(Key("page3")), findsNothing);
        expect(find.byKey(Key("page4")), findsNothing);
      });
}
