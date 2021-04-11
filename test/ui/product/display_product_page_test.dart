import 'dart:io';

import 'package:either_option/either_option.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:untitled_vegan_app/model/ingredient.dart';
import 'package:untitled_vegan_app/model/product.dart';
import 'package:untitled_vegan_app/model/veg_status.dart';
import 'package:untitled_vegan_app/model/veg_status_source.dart';
import 'package:untitled_vegan_app/outside/backend/backend.dart';
import 'package:untitled_vegan_app/outside/products_manager.dart';
import 'package:untitled_vegan_app/ui/product/display_product_page.dart';
import 'package:untitled_vegan_app/l10n/strings.dart';

import '../../widget_tester_extension.dart';
import 'display_product_page_test.mocks.dart';

@GenerateMocks([ProductsManager, Backend])
void main() {
  late MockProductsManager productsManager;
  late MockBackend backend;

  setUp(() async {
    await GetIt.I.reset();

    productsManager = MockProductsManager();
    when(productsManager.createUpdateProduct(any, any)).thenAnswer(
            (invoc) async => invoc.positionalArguments[0]);
    when(productsManager.updateProductAndExtractIngredients(any, any)).thenAnswer((_) async => null);
    GetIt.I.registerSingleton<ProductsManager>(productsManager);

    backend = MockBackend();
    when(backend.sendReport(any, any)).thenAnswer((_) async => Left(None()));
    GetIt.I.registerSingleton<Backend>(backend);
  });

  testWidgets("product is displayed", (WidgetTester tester) async {
    final product = Product((v) => v
      ..barcode = "123"
      ..name = "My product"
      ..vegetarianStatus = VegStatus.possible
      ..vegetarianStatusSource = VegStatusSource.community
      ..veganStatus = VegStatus.negative
      ..veganStatusSource = VegStatusSource.moderator
      ..ingredientsText = "Water, salt, sugar"
      ..ingredientsAnalyzed.addAll([
        Ingredient((v) => v
          ..name = "ingredient1"
          ..vegetarianStatus = VegStatus.positive
          ..veganStatus = VegStatus.unknown),
        Ingredient((v) => v
          ..name = "ingredient2"
          ..vegetarianStatus = null
          ..veganStatus = null),
      ]));

    final context = await tester.superPump(DisplayProductPage(product));

    expect(find.text(product.name!), findsOneWidget);
    expect(find.text(product.ingredientsText!), findsWidgets);

    final vegetarianStatus =
    find.byKey(Key("vegetarian_status")).evaluate().single.widget as Text;
    expect(vegetarianStatus.data, equals(
        "${context.strings.display_product_page_whether_vegetarian}"
            "${context.strings.display_product_page_veg_status_possible}"));

    final veganStatus =
    find.byKey(Key("vegan_status")).evaluate().single.widget as Text;
    expect(veganStatus.data, equals(
        "${context.strings.display_product_page_whether_vegan}"
            "${context.strings.display_product_page_veg_status_negative}"));

    final vegetarianStatusSource =
    find.byKey(Key("vegetarian_status_source")).evaluate().single.widget as Text;
    expect(vegetarianStatusSource.data, equals(
        "${context.strings.display_product_page_veg_status_source}"
            "${context.strings.display_product_page_veg_status_source_community}"));

    final veganStatusSource =
    find.byKey(Key("vegan_status_source")).evaluate().single.widget as Text;
    expect(veganStatusSource.data, equals(
        "${context.strings.display_product_page_veg_status_source}"
            "${context.strings.display_product_page_veg_status_source_moderator}"));

    final ingredientsAnalysisTable =
    find.byKey(Key("ingredients_analysis_table")).evaluate().single.widget as Table;
    expect(ingredientsAnalysisTable.children.length, equals(2));

    final row1 = ingredientsAnalysisTable.children[0];
    expect((row1.children![0] as Text).data, equals(
        "ingredient1"
    ));
    expect((row1.children![1] as Text).data, equals(
        "${context.strings.display_product_page_whether_vegetarian}"
            "${context.strings.display_product_page_veg_status_positive}"));
    expect((row1.children![2] as Text).data, equals(
        "${context.strings.display_product_page_whether_vegan}"
            "${context.strings.display_product_page_veg_status_unknown}"));

    final row2 = ingredientsAnalysisTable.children[1];
    expect((row2.children![0] as Text).data, equals(
        "ingredient2"
    ));
    expect((row2.children![1] as Text).data, equals(
        "${context.strings.display_product_page_whether_vegetarian}-"));
    expect((row2.children![2] as Text).data, equals(
        "${context.strings.display_product_page_whether_vegan}-"));
  });

  testWidgets("veg-statuses help button not displayed when sources are not OFF", (WidgetTester tester) async {
    final product = Product((v) => v
      ..barcode = "123"
      ..name = "My product"
      ..vegetarianStatus = VegStatus.possible
      ..vegetarianStatusSource = VegStatusSource.community
      ..veganStatus = VegStatus.negative
      ..veganStatusSource = VegStatusSource.moderator
      ..ingredientsText = "Water, salt, sugar");

    final context = await tester.superPump(DisplayProductPage(product));

    expect(
        find.text(context.strings.display_product_page_help_with_veg_statuses),
        findsNothing);
  });

  testWidgets("veg-statuses help button behaviour", (WidgetTester tester) async {
    final product = Product((v) => v
      ..barcode = "123"
      ..name = "My product"
      ..vegetarianStatus = VegStatus.possible
      ..vegetarianStatusSource = VegStatusSource.open_food_facts
      ..veganStatus = VegStatus.negative
      ..veganStatusSource = VegStatusSource.open_food_facts
      ..ingredientsText = "Water, salt, sugar");

    final context = await tester.superPump(DisplayProductPage(product));

    // Initial statuses are from OFF
    var vegetarianStatus =
      find.byKey(Key("vegetarian_status")).evaluate().single.widget as Text;
    expect(vegetarianStatus.data, equals(
        "${context.strings.display_product_page_whether_vegetarian}"
            "${context.strings.display_product_page_veg_status_possible}"));
    var veganStatus =
      find.byKey(Key("vegan_status")).evaluate().single.widget as Text;
    expect(veganStatus.data, equals(
        "${context.strings.display_product_page_whether_vegan}"
            "${context.strings.display_product_page_veg_status_negative}"));
    var vegetarianStatusSource =
      find.byKey(Key("vegetarian_status_source")).evaluate().single.widget as Text;
    expect(vegetarianStatusSource.data, equals(
        "${context.strings.display_product_page_veg_status_source}"
            "${context.strings.display_product_page_veg_status_source_off}"));
    var veganStatusSource =
      find.byKey(Key("vegan_status_source")).evaluate().single.widget as Text;
    expect(veganStatusSource.data, equals(
        "${context.strings.display_product_page_veg_status_source}"
            "${context.strings.display_product_page_veg_status_source_off}"));

    // Help button initially exists and init_product_page doesn't
    expect(
      find.text(context.strings.display_product_page_help_with_veg_statuses),
      findsOneWidget);
    expect(
      find.byKey(Key("init_product_page")),
      findsNothing);

    await tester.tap(
        find.text(context.strings.display_product_page_help_with_veg_statuses));
    await tester.pumpAndSettle();

    expect(
        find.byKey(Key("init_product_page")),
        findsWidgets);
    expect(
        find.byKey(Key("page4")),
        findsWidgets);

    await tester.tap(find.descendant(
        of: find.byKey(Key("vegetarian_unknown")),
        matching: find.text(context.strings.init_product_page_not_sure)));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(Key("page4_next_btn")));
    await tester.pumpAndSettle();

    expect(
        find.byKey(Key("init_product_page")),
        findsNothing);
    expect(
        find.text(context.strings.display_product_page_help_with_veg_statuses),
        findsNothing);

    // Final veg statuses are changed and are from community
    vegetarianStatus =
      find.byKey(Key("vegetarian_status")).evaluate().single.widget as Text;
    expect(vegetarianStatus.data, equals(
        "${context.strings.display_product_page_whether_vegetarian}"
            "${context.strings.display_product_page_veg_status_unknown}"));
    veganStatus =
      find.byKey(Key("vegan_status")).evaluate().single.widget as Text;
    expect(veganStatus.data, equals(
        "${context.strings.display_product_page_whether_vegan}"
            "${context.strings.display_product_page_veg_status_unknown}"));
    vegetarianStatusSource =
      find.byKey(Key("vegetarian_status_source")).evaluate().single.widget as Text;
    expect(vegetarianStatusSource.data, equals(
        "${context.strings.display_product_page_veg_status_source}"
            "${context.strings.display_product_page_veg_status_source_community}"));
    veganStatusSource =
      find.byKey(Key("vegan_status_source")).evaluate().single.widget as Text;
    expect(veganStatusSource.data, equals(
        "${context.strings.display_product_page_veg_status_source}"
            "${context.strings.display_product_page_veg_status_source_community}"));
  });

  testWidgets("send report", (WidgetTester tester) async {
    final product = Product((v) => v
      ..barcode = "123"
      ..name = "My product"
      ..vegetarianStatus = VegStatus.possible
      ..vegetarianStatusSource = VegStatusSource.community
      ..veganStatus = VegStatus.negative
      ..veganStatusSource = VegStatusSource.moderator
      ..ingredientsText = "Water, salt, sugar");

    final context = await tester.superPump(DisplayProductPage(product));

    await tester.tap(find.text(context.strings.display_product_page_report));
    await tester.pumpAndSettle();

    verifyNever(backend.sendReport("123", "Bad, bad product!"));

    await tester.enterText(find.byKey(Key("report_text")), "Bad, bad product!");
    await tester.pumpAndSettle();
    await tester.tap(find.text(context.strings.display_product_page_report_send));
    await tester.pumpAndSettle();

    verify(backend.sendReport("123", "Bad, bad product!")).called(1);
  });
}