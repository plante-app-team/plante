import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plante/base/result.dart';
import 'package:plante/model/shop.dart';
import 'package:plante/outside/backend/backend_shop.dart';
import 'package:plante/outside/map/address_obtainer.dart';
import 'package:plante/outside/map/open_street_map.dart';
import 'package:plante/outside/map/osm_shop.dart';
import 'package:plante/outside/map/osm_short_address.dart';
import 'package:plante/ui/base/components/shop_address_widget.dart';
import 'package:plante/l10n/strings.dart';

import '../../../widget_tester_extension.dart';

void main() {
  String? getText() {
    final textWidget =
        find.byType(RichText).evaluate().first.widget as RichText;
    final text = textWidget.text.toPlainText();
    // Remove all invisible chars except for whitespaces
    return text.replaceAll(RegExp('[^A-Za-z0-9().,:;? ]'), '').trim();
  }

  testWidgets('good scenario with a shop without address',
      (WidgetTester tester) async {
    final addressCompleter = Completer<ShortAddressResult>();
    final address = OsmShortAddress((e) => e
      ..city = 'Nice city'
      ..road = 'Broadway'
      ..houseNumber = '4');
    final shopWithoutAddress = Shop((e) => e
      ..osmShop.replace(OsmShop((e) => e
        ..osmId = '1'
        ..longitude = 11
        ..latitude = 11
        ..name = 'Spar')));

    final context = await tester.superPump(
        ShopAddressWidget(shopWithoutAddress, addressCompleter.future));
    final expectedStr =
        '${context.strings.shop_address_widget_possible_address}'
        'Broadway, 4';

    expect(find.byKey(const Key('location_icon')), findsOneWidget);
    expect(find.byKey(const Key('address_placeholder')), findsOneWidget);
    expect(getText(), equals(''));

    addressCompleter.complete(Ok(address));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('location_icon')), findsOneWidget);
    expect(find.byKey(const Key('address_placeholder')), findsNothing);
    expect(getText(), equals(expectedStr));
  });

  testWidgets('good scenario with a shop with address',
      (WidgetTester tester) async {
    final address = OsmShortAddress((e) => e
      ..city = 'Nice city'
      ..road = 'Broadway'
      ..houseNumber = '4');
    final shopWithAddress = Shop((e) => e
      ..osmShop.replace(OsmShop((e) => e
        ..osmId = '1'
        ..longitude = 11
        ..latitude = 11
        ..name = 'Spar'
        ..city = address.city
        ..road = address.road
        ..houseNumber = address.houseNumber)));

    final context = await tester.superPump(
        ShopAddressWidget(shopWithAddress, Future.value(Ok(address))));

    // We expect a string without the 'possible' word because the address
    // is precise - it's a part of the shop.
    final notExpectedStr =
        '${context.strings.shop_address_widget_possible_address}'
        'Broadway, 4';
    const expectedStr = 'Broadway, 4';

    await tester.pumpAndSettle();
    expect(getText(), isNot(equals(notExpectedStr)));
    expect(getText(), equals(expectedStr));
  });

  testWidgets('partial address', (WidgetTester tester) async {
    final address = OsmShortAddress((e) => e..road = 'Broadway');

    final context = await tester
        .superPump(ShopAddressWidget(null, Future.value(Ok(address))));
    await tester.pumpAndSettle();

    final expectedStr =
        '${context.strings.shop_address_widget_possible_address}'
        'Broadway';
    expect(getText(), equals(expectedStr));
    expect(find.byKey(const Key('location_icon')), findsOneWidget);
    expect(find.byKey(const Key('address_placeholder')), findsNothing);
  });

  testWidgets('house number is not used without road',
      (WidgetTester tester) async {
    final address = OsmShortAddress((e) => e
      ..city = 'Nice city'
      ..road = null
      ..houseNumber = '4');

    final context = await tester
        .superPump(ShopAddressWidget(null, Future.value(Ok(address))));
    await tester.pumpAndSettle();

    final expectedStr =
        '${context.strings.shop_address_widget_possible_address}'
        'Nice city';
    expect(getText(), equals(expectedStr));
    expect(find.byKey(const Key('location_icon')), findsOneWidget);
    expect(find.byKey(const Key('address_placeholder')), findsNothing);
  });

  testWidgets('empty address', (WidgetTester tester) async {
    final address = OsmShortAddress((e) => e
      ..road = null
      ..city = null
      ..houseNumber = null);

    await tester.superPump(ShopAddressWidget(null, Future.value(Ok(address))));
    await tester.pumpAndSettle();

    expect(getText(), equals(''));
    expect(find.byKey(const Key('location_icon')), findsNothing);
    expect(find.byKey(const Key('address_placeholder')), findsNothing);
  });

  testWidgets('address error', (WidgetTester tester) async {
    await tester.superPump(
        ShopAddressWidget(null, Future.value(Err(OpenStreetMapError.OTHER))));
    await tester.pumpAndSettle();

    expect(getText(), equals(''));
    expect(find.byKey(const Key('location_icon')), findsNothing);
    expect(find.byKey(const Key('address_placeholder')), findsNothing);
  });
}
