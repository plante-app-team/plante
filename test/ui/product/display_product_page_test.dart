import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:untitled_vegan_app/model/ingredient.dart';
import 'package:untitled_vegan_app/model/product.dart';
import 'package:untitled_vegan_app/model/veg_status.dart';
import 'package:untitled_vegan_app/model/veg_status_source.dart';
import 'package:untitled_vegan_app/ui/product/display_product_page.dart';
import 'package:untitled_vegan_app/l10n/strings.dart';

import '../../widget_tester_extension.dart';

void main() {
  setUp(() {
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
}
