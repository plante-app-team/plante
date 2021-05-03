import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_svg/svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:plante/base/result.dart';
import 'package:plante/model/ingredient.dart';
import 'package:plante/model/product.dart';
import 'package:plante/model/veg_status.dart';
import 'package:plante/model/veg_status_source.dart';
import 'package:plante/outside/backend/backend.dart';
import 'package:plante/outside/products/products_manager.dart';
import 'package:plante/outside/products/products_manager_error.dart';
import 'package:plante/ui/product/display_product_page.dart';
import 'package:plante/l10n/strings.dart';

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
            (invoc) async => Ok(invoc.positionalArguments[0]));
    when(productsManager.updateProductAndExtractIngredients(any, any))
        .thenAnswer((_) async => Err(ProductsManagerError.OTHER));
    GetIt.I.registerSingleton<ProductsManager>(productsManager);

    backend = MockBackend();
    when(backend.sendReport(any, any)).thenAnswer((_) async => Ok(None()));
    GetIt.I.registerSingleton<Backend>(backend);
  });

  /// See DisplayProductPage.ingredientsAnalysisTable
  Text ingredientsTableColumn1(TableRow row) {
    final box1 = row.children![1] as SizedBox;
    final center = box1.child as Center;
    final box2 = center.child as SizedBox;
    return box2.child as Text;
  }

  /// See DisplayProductPage.ingredientsAnalysisTable
  String ingredientsTableColumnSVG(TableRow row, int column) {
    if (column == 3) {
      column = 4;
    } else if (column == 2) {
      column = 2;
    } else {
      // See DisplayProductPage.ingredientsAnalysisTable
      throw Exception("Column $column is not expected to have SVG");
    }
    final box1 = row.children![column] as SizedBox;
    final center = box1.child as Center;
    final box2 = center.child as SizedBox;
    final box3 = box2.child as SizedBox;
    final svg = box3.child as SvgPicture;
    return (svg.pictureProvider as ExactAssetPicture).assetName;
  }

  testWidgets("product is displayed", (WidgetTester tester) async {
    final product = Product((v) => v
      ..barcode = "123"
      ..name = "My product"
      ..vegetarianStatus = VegStatus.possible
      ..vegetarianStatusSource = VegStatusSource.moderator
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
        "${context.strings.display_product_page_veg_status_possible}"));

    final veganStatus =
    find.byKey(Key("vegan_status")).evaluate().single.widget as Text;
    expect(veganStatus.data, equals(
            "${context.strings.display_product_page_veg_status_negative}"));

    final vegStatusSource =
    find.byKey(Key("veg_status_source")).evaluate().single.widget as Text;
    expect(vegStatusSource.data, equals(
            "${context.strings.display_product_page_veg_status_source_moderator}"));

    final ingredientsAnalysisTable =
    find.byKey(Key("ingredients_analysis_table")).evaluate().single.widget as Table;
    // 2 + header
    expect(ingredientsAnalysisTable.children.length, equals(3));

    final row1 = ingredientsAnalysisTable.children[1];
    expect(ingredientsTableColumn1(row1).data, equals(
        "ingredient1"
    ));
    expect(ingredientsTableColumnSVG(row1, 2), equals("assets/veg_status_positive.svg"));
    expect(ingredientsTableColumnSVG(row1, 3), equals("assets/veg_status_unknown.svg"));

    final row2 = ingredientsAnalysisTable.children[2];
    expect(ingredientsTableColumn1(row2).data, equals(
        "ingredient2"
    ));
    expect(ingredientsTableColumnSVG(row2, 2), equals("assets/veg_status_unknown.svg"));
    expect(ingredientsTableColumnSVG(row2, 3), equals("assets/veg_status_unknown.svg"));
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
      ..imageFront = Uri.file(File("./test/assets/img.jpg").absolute.path)
      ..vegetarianStatus = VegStatus.possible
      ..vegetarianStatusSource = VegStatusSource.open_food_facts
      ..veganStatus = VegStatus.negative
      ..veganStatusSource = VegStatusSource.open_food_facts
      ..imageIngredients = Uri.file(File("./test/assets/img.jpg").absolute.path)
      ..ingredientsText = "Water, salt, sugar");

    final context = await tester.superPump(DisplayProductPage(product));

    // Initial statuses are from OFF
    var vegetarianStatus =
      find.byKey(Key("vegetarian_status")).evaluate().single.widget as Text;
    expect(vegetarianStatus.data, equals(
            "${context.strings.display_product_page_veg_status_possible}"));
    var veganStatus =
      find.byKey(Key("vegan_status")).evaluate().single.widget as Text;
    expect(veganStatus.data, equals(
            "${context.strings.display_product_page_veg_status_negative}"));
    var vegStatusSource =
      find.byKey(Key("veg_status_source")).evaluate().single.widget as Text;
    expect(vegStatusSource.data, equals(
            "${context.strings.display_product_page_veg_status_source_off}"));

    // Help button initially exists and init_product_page doesn't
    expect(
      find.text(context.strings.display_product_page_click_to_help_with_veg_statuses),
      findsOneWidget);
    expect(
        find.byKey(Key("init_product_page")),
        findsNothing);

    await tester.tap(
        find.text(context.strings.display_product_page_click_to_help_with_veg_statuses));
    await tester.pumpAndSettle();

    expect(
        find.byKey(Key("init_product_page")),
        findsWidgets);

    await tester.tap(find.byKey(Key("vegetarian_unknown_btn")));
    await tester.pumpAndSettle();
    await tester.drag(find.byKey(Key('content')), Offset(0.0, -3000));
    await tester.pumpAndSettle();
    await tester.tap(find.text(context.strings.global_done));
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
            "${context.strings.display_product_page_veg_status_unknown}"));
    veganStatus =
      find.byKey(Key("vegan_status")).evaluate().single.widget as Text;
    expect(veganStatus.data, equals(
            "${context.strings.display_product_page_veg_status_negative}"));
    vegStatusSource =
      find.byKey(Key("veg_status_source")).evaluate().single.widget as Text;
    expect(vegStatusSource.data, equals(
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

    await tester.tap(find.text(context.strings.display_product_page_report_btn));
    await tester.pumpAndSettle();

    verifyNever(backend.sendReport("123", "Bad, bad product!"));

    await tester.enterText(find.byKey(Key("report_text")), "Bad, bad product!");
    await tester.pumpAndSettle();
    await tester.tap(find.text(context.strings.display_product_page_report_send));
    await tester.pumpAndSettle();

    verify(backend.sendReport("123", "Bad, bad product!")).called(1);
  });

  testWidgets("when vegan and vegetarian status sources differ, the worst one is used", (WidgetTester tester) async {
    final product = Product((v) => v
      ..barcode = "123"
      ..name = "My product"
      ..vegetarianStatus = VegStatus.possible
      ..vegetarianStatusSource = VegStatusSource.moderator
      ..veganStatus = VegStatus.negative
      ..veganStatusSource = VegStatusSource.community
      ..ingredientsText = "Water, salt, sugar",
      );

    final context = await tester.superPump(DisplayProductPage(product));

    final vegStatusSource =
    find.byKey(Key("veg_status_source")).evaluate().single.widget as Text;
    // Vegetarian status was determined by a moderator, but
    // vegan status was determined by community. Community is less reliable and
    // since only 1 status source is displayed, the less reliable should be
    // displayed.
    expect(vegStatusSource.data, equals(
        "${context.strings.display_product_page_veg_status_source_community}"));
  });
}
