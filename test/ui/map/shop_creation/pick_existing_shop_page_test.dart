import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:plante/base/result.dart';
import 'package:plante/l10n/strings.dart';
import 'package:plante/model/shop.dart';
import 'package:plante/outside/map/address_obtainer.dart';
import 'package:plante/outside/map/osm/osm_address.dart';
import 'package:plante/outside/map/osm/osm_shop.dart';
import 'package:plante/outside/map/osm/osm_uid.dart';
import 'package:plante/outside/map/shops_manager.dart';
import 'package:plante/ui/map/shop_creation/pick_existing_shop_page.dart';

import '../../../common_mocks.mocks.dart';
import '../../../test_di_registry.dart';
import '../../../widget_tester_extension.dart';

void main() {
  late MockShopsManager shopsManager;
  late MockAddressObtainer addressObtainer;

  final readyAddress = OsmAddress((e) => e..road = 'Broadway');
  final existingShops = [
    Shop((e) => e
      ..osmShop.replace(OsmShop((e) => e
        ..osmUID = OsmUID.parse('1:1')
        ..longitude = 11
        ..latitude = 11
        ..name = 'Spar'))),
    Shop((e) => e
      ..osmShop.replace(OsmShop((e) => e
        ..osmUID = OsmUID.parse('1:2')
        ..longitude = 11
        ..latitude = 11
        ..name = 'Kroger'))),
  ];

  setUp(() async {
    shopsManager = MockShopsManager();
    addressObtainer = MockAddressObtainer();

    await TestDiRegistry.register((r) {
      r.register<ShopsManager>(shopsManager);
      r.register<AddressObtainer>(addressObtainer);
    });

    when(addressObtainer.addressOfCoords(any))
        .thenAnswer((_) async => Ok(readyAddress));
    when(addressObtainer.shortAddressOfCoords(any))
        .thenAnswer((_) async => Ok(readyAddress.toShort()));
    when(addressObtainer.addressOfShop(any))
        .thenAnswer((_) async => Ok(readyAddress.toShort()));
  });

  testWidgets('existing shop is picked', (WidgetTester tester) async {
    final navigatorObserver = MockNavigatorObserver();

    await tester.superPump(PickExistingShopPage(existingShops),
        navigatorObserver: navigatorObserver);

    await tester.superTap(find.text(existingShops[0].name));

    final capturedRoute = verify(navigatorObserver.didPop(captureAny, any))
        .captured
        .first as Route<dynamic>;
    final pageResult =
        await capturedRoute.popped as PickExistingShopResultShopPicked;
    expect(pageResult.shop, equals(existingShops[0]));
  });

  testWidgets('new shop creation is started', (WidgetTester tester) async {
    final navigatorObserver = MockNavigatorObserver();

    final context = await tester.superPump(PickExistingShopPage(existingShops),
        navigatorObserver: navigatorObserver);

    await tester.superTap(
        find.text(context.strings.pick_existing_shop_page_create_shop_button));

    final capturedRoute = verify(navigatorObserver.didPop(captureAny, any))
        .captured
        .first as Route<dynamic>;
    final pageResult = await capturedRoute.popped;
    expect(pageResult is PickExistingShopResultNewShopWanted, isTrue,
        reason: pageResult.runtimeType.toString());
  });

  testWidgets('page is canceled', (WidgetTester tester) async {
    final navigatorObserver = MockNavigatorObserver();

    await tester.superPump(PickExistingShopPage(existingShops),
        navigatorObserver: navigatorObserver);

    await tester.superTap(find.byKey(const Key('cancel')));

    final capturedRoute = verify(navigatorObserver.didPop(captureAny, any))
        .captured
        .first as Route<dynamic>;
    final pageResult = await capturedRoute.popped;
    expect(pageResult, isNull);
  });

  testWidgets('shops are displayed in the order they are received',
      (WidgetTester tester) async {
    // Order 1
    await tester.superPump(
        PickExistingShopPage(existingShops, key: const Key('page1')));
    var center1 = tester.getCenter(find.text(existingShops[0].name));
    var center2 = tester.getCenter(find.text(existingShops[1].name));
    expect(center1.dy, lessThan(center2.dy));

    // Order 2
    await tester.superPump(PickExistingShopPage(existingShops.reversed.toList(),
        key: const Key('page2')));
    center1 = tester.getCenter(find.text(existingShops[1].name));
    center2 = tester.getCenter(find.text(existingShops[0].name));
    expect(center1.dy, lessThan(center2.dy));
  });
}
