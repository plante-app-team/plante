import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
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
      ..ingredients = "Water, salt, sugar");

    final context = await tester.superPump(DisplayProductPage(product));

    expect(find.text(product.name!), findsOneWidget);
    expect(find.text(product.ingredients!), findsWidgets);

    expect(find.text(
            "${context.strings.display_product_page_whether_vegetarian}"
            "${context.strings.display_product_page_veg_status_possible}"),
        findsOneWidget);

    expect(find.text(
            "${context.strings.display_product_page_whether_vegan}"
            "${context.strings.display_product_page_veg_status_negative}"),
        findsOneWidget);

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
  });
}
