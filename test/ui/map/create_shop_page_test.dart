import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:plante/base/base.dart';
import 'package:plante/base/result.dart';
import 'package:plante/logging/analytics.dart';
import 'package:plante/model/shop.dart';
import 'package:plante/model/shop_type.dart';
import 'package:plante/outside/backend/backend_shop.dart';
import 'package:plante/outside/map/address_obtainer.dart';
import 'package:plante/outside/map/osm_address.dart';
import 'package:plante/outside/map/osm_shop.dart';
import 'package:plante/outside/map/shops_manager.dart';
import 'package:plante/ui/map/create_shop_page.dart';
import 'package:plante/l10n/strings.dart';

import '../../fake_analytics.dart';
import '../../widget_tester_extension.dart';
import 'create_shop_page_test.mocks.dart';

@GenerateMocks([ShopsManager, AddressObtainer])
void main() {
  late MockShopsManager shopsManager;
  late MockAddressObtainer addressObtainer;

  final FutureAddress readyAddress = Future.value(Ok(OsmAddress((e) => e
    ..road = 'Broadway'
  )));
  const coords = Point(1.2, 3.4);

  setUp(() async {
    await GetIt.I.reset();

    GetIt.I.registerSingleton<Analytics>(FakeAnalytics());

    shopsManager = MockShopsManager();
    GetIt.I.registerSingleton<ShopsManager>(shopsManager);
    addressObtainer = MockAddressObtainer();
    GetIt.I.registerSingleton<AddressObtainer>(addressObtainer);

    when(shopsManager.createShop(
        name: anyNamed('name'),
        coords: anyNamed('coords'),
        type: anyNamed('type'))).thenAnswer((invc) async {
      final name = invc.namedArguments[const Symbol('name')] as String;
      final coords = invc.namedArguments[const Symbol('coords')] as Point<double>;
      final id = randInt(100, 500);
      return Ok(Shop((e) => e
        ..osmShop.replace(OsmShop((e) => e
          ..osmId = id.toString()
          ..longitude = coords.x
          ..latitude = coords.y
          ..name = name))
        ..backendShop.replace(BackendShop((e) => e
          ..osmId = id.toString()
          ..productsCount = 0))));
    });
    when(addressObtainer.addressOfCoords(any)).thenAnswer(
            (_) async => readyAddress);
  });

  Future<void> createShopTestImpl(WidgetTester tester, {String? shopName, ShopType? shopType}) async {
    final context = await tester.superPump(const CreateShopPage(shopCoords: coords));

    if (shopName != null) {
      await tester.enterText(
          find.byKey(const Key('new_shop_name_input')),
          shopName);
      await tester.pumpAndSettle();
    }

    if (shopType != null) {
      await tester.tap(find.byKey(const Key('shop_type_dropdown')));
      await tester.pumpAndSettle();
      await tester.tapDropDownItem(shopType.localize(context));
      await tester.pumpAndSettle();
    }

    await tester.tap(find.text(context.strings.global_done));
    await tester.pumpAndSettle();
  }

  testWidgets('create shop', (WidgetTester tester) async {
    verifyNever(shopsManager.createShop(
        name: anyNamed('name'),
        coords: anyNamed('coords'),
        type: anyNamed('type')));

    await createShopTestImpl(tester, shopName: 'new shop', shopType: ShopType.deli);

    // Shop is created
    verify(shopsManager.createShop(
        name: 'new shop',
        coords: coords,
        type: ShopType.deli));
  });

  testWidgets('cannot create shop when shop name is not set', (WidgetTester tester) async {
    await createShopTestImpl(tester,
        shopName: null,
        shopType: ShopType.deli);

    verifyNever(shopsManager.createShop(
        name: anyNamed('name'),
        coords: anyNamed('coords'),
        type: anyNamed('type')));
  });

  testWidgets('cannot create shop when shop type is not set', (WidgetTester tester) async {
    await createShopTestImpl(tester,
        shopName: 'shop name',
        shopType: null);

    verifyNever(shopsManager.createShop(
        name: anyNamed('name'),
        coords: anyNamed('coords'),
        type: anyNamed('type')));
  });
}
