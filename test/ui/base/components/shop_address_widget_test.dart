import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plante/base/result.dart';
import 'package:plante/outside/map/address_obtainer.dart';
import 'package:plante/base/base.dart';
import 'package:plante/outside/map/open_street_map.dart';
import 'package:plante/outside/map/osm_address.dart';
import 'package:plante/ui/base/components/shop_address_widget.dart';
import 'package:plante/ui/base/components/visibility_detector_plante.dart';
import 'package:plante/l10n/strings.dart';

import '../../../fake_app_lifecycle_watcher.dart';
import '../../../widget_tester_extension.dart';

void main() {
  String? getText() {
    final textWidget = find.byType(RichText).evaluate().first.widget as RichText;
    final text = textWidget.text.toPlainText();
    // Remove all invisible chars except for whitespaces
    return text.replaceAll(RegExp('[^A-Za-z0-9().,:;? ]'), '').trim();
  }

  testWidgets('good scenario', (WidgetTester tester) async {
    final addressCompleter = Completer<AddressResult>();
    final address = OsmAddress((e) => e
      ..neighbourhood = 'Nice neighbourhood' // Expected to be not used
      ..road = 'Broadway'
      ..cityDistrict = 'Nice district'
      ..houseNumber = '4'
    );

    final context = await tester.superPump(ShopAddressWidget(addressCompleter.future));
    final expectedStr = '${context.strings.shop_address_widget_possible_address}'
        'Nice district, Broadway, 4';

    expect(find.byKey(const Key('location_icon')), findsOneWidget);
    expect(find.byKey(const Key('address_placeholder')), findsOneWidget);
    expect(getText(), equals(''));

    addressCompleter.complete(Ok(address));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('location_icon')), findsOneWidget);
    expect(find.byKey(const Key('address_placeholder')), findsNothing);
    expect(getText(), equals(expectedStr));
  });

  testWidgets('partial address', (WidgetTester tester) async {
    final address = OsmAddress((e) => e
      ..road = 'Broadway'
      ..cityDistrict = null
      ..houseNumber = '4'
    );

    final context = await tester.superPump(
        ShopAddressWidget(Future.value(Ok(address))));
    await tester.pumpAndSettle();

    final expectedStr = '${context.strings.shop_address_widget_possible_address}'
        'Broadway, 4';
    expect(getText(), equals(expectedStr));
    expect(find.byKey(const Key('location_icon')), findsOneWidget);
    expect(find.byKey(const Key('address_placeholder')), findsNothing);
  });

  testWidgets('house number is not used without road', (WidgetTester tester) async {
    final address = OsmAddress((e) => e
      ..road = null
      ..cityDistrict = 'Nice district'
      ..houseNumber = '4'
    );

    final context = await tester.superPump(
        ShopAddressWidget(Future.value(Ok(address))));
    await tester.pumpAndSettle();

    final expectedStr = '${context.strings.shop_address_widget_possible_address}'
        'Nice district';
    expect(getText(), equals(expectedStr));
    expect(find.byKey(const Key('location_icon')), findsOneWidget);
    expect(find.byKey(const Key('address_placeholder')), findsNothing);
  });

  testWidgets('empty address', (WidgetTester tester) async {
    final address = OsmAddress((e) => e
      ..road = null
      ..cityDistrict = null
      ..houseNumber = null
    );

    await tester.superPump(
        ShopAddressWidget(Future.value(Ok(address))));
    await tester.pumpAndSettle();

    expect(getText(), equals(''));
    expect(find.byKey(const Key('location_icon')), findsNothing);
    expect(find.byKey(const Key('address_placeholder')), findsNothing);
  });

  testWidgets('address error', (WidgetTester tester) async {
    await tester.superPump(
        ShopAddressWidget(Future.value(Err(OpenStreetMapError.OTHER))));
    await tester.pumpAndSettle();

    expect(getText(), equals(''));
    expect(find.byKey(const Key('location_icon')), findsNothing);
    expect(find.byKey(const Key('address_placeholder')), findsNothing);
  });
}
