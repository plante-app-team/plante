import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mockito/mockito.dart';
import 'package:plante/base/base.dart';
import 'package:plante/base/coord_utils.dart';
import 'package:plante/base/result.dart';
import 'package:plante/l10n/strings.dart';
import 'package:plante/logging/analytics.dart';
import 'package:plante/model/coord.dart';
import 'package:plante/model/shop.dart';
import 'package:plante/model/shop_type.dart';
import 'package:plante/outside/map/address_obtainer.dart';
import 'package:plante/outside/map/osm/osm_address.dart';
import 'package:plante/outside/map/osm/osm_shop.dart';
import 'package:plante/outside/map/osm/osm_uid.dart';
import 'package:plante/outside/map/shops_manager.dart';
import 'package:plante/ui/map/shop_creation/create_shop_page.dart';
import 'package:plante/ui/map/shop_creation/pick_existing_shop_page.dart';
import 'package:plante/ui/map/shop_creation/shops_creation_manager.dart';

import '../../../common_mocks.mocks.dart';
import '../../../widget_tester_extension.dart';
import '../../../z_fakes/fake_analytics.dart';
import '../../../z_fakes/fake_shops_manager.dart';

void main() {
  late FakeAnalytics analytics;
  late FakeShopsManager shopsManager;
  late MockAddressObtainer addressObtainer;
  late ShopsCreationManager shopsCreationManager;

  final readyAddress = OsmAddress((e) => e..road = 'Broadway');

  final maxDistance =
      kmToGrad(ShopsCreationManager.EXISTING_SHOPS_SEARCH_RADIUS_KMS);
  final coordBetweenExistingShops = Coord(lat: 10, lon: 10);
  final existingShops = [
    Shop((e) => e
      ..osmShop.replace(OsmShop((e) => e
        ..osmUID = OsmUID.parse('1:1')
        ..longitude = coordBetweenExistingShops.lon + maxDistance / 10
        ..latitude = coordBetweenExistingShops.lat + maxDistance / 10
        ..name = 'Spar'))),
    Shop((e) => e
      ..osmShop.replace(OsmShop((e) => e
        ..osmUID = OsmUID.parse('1:2')
        ..longitude = coordBetweenExistingShops.lon - maxDistance / 10
        ..latitude = coordBetweenExistingShops.lat - maxDistance / 10
        ..name = 'Kroger'))),
  ];

  setUp(() async {
    await GetIt.I.reset();

    analytics = FakeAnalytics();
    GetIt.I.registerSingleton<Analytics>(analytics);
    shopsManager = FakeShopsManager();
    shopsManager.setShopsLoader(
        (bounds) => existingShops.where((shop) => bounds.contains(shop.coord)));
    GetIt.I.registerSingleton<ShopsManager>(shopsManager);
    addressObtainer = MockAddressObtainer();
    GetIt.I.registerSingleton<AddressObtainer>(addressObtainer);

    shopsCreationManager = ShopsCreationManager(shopsManager);

    when(addressObtainer.addressOfCoords(any))
        .thenAnswer((_) async => Ok(readyAddress));
    when(addressObtainer.shortAddressOfCoords(any))
        .thenAnswer((_) async => Ok(readyAddress.toShort()));
    when(addressObtainer.addressOfShop(any))
        .thenAnswer((_) async => Ok(readyAddress.toShort()));
  });

  testWidgets('no other shops nearby', (WidgetTester tester) async {
    final context = await tester.superPump(Container());

    // Far away from our 2 existing shops
    unawaited(shopsCreationManager.startShopCreation(
        Coord(
          lat: coordBetweenExistingShops.lat + maxDistance * 10,
          lon: coordBetweenExistingShops.lon + maxDistance * 10,
        ),
        context));
    await tester.pumpAndSettle();

    expect(find.byType(PickExistingShopPage), findsNothing);
    expect(find.byType(CreateShopPage), findsOneWidget);
  });

  testWidgets('other shops nearby', (WidgetTester tester) async {
    final context = await tester.superPump(Container());

    // Between our 2 existing shops
    unawaited(shopsCreationManager.startShopCreation(
        coordBetweenExistingShops, context));
    await tester.pumpAndSettle();

    expect(find.byType(PickExistingShopPage), findsOneWidget);
    expect(find.byType(CreateShopPage), findsNothing);
  });

  testWidgets('existing shop is picked', (WidgetTester tester) async {
    final context = await tester.superPump(Container());

    // Between our 2 existing shops
    final result = shopsCreationManager.startShopCreation(
        coordBetweenExistingShops, context);
    await tester.pumpAndSettle();

    expect(find.byType(PickExistingShopPage), findsOneWidget);
    await tester.superTap(find.text(existingShops[1].name));
    expect(find.byType(PickExistingShopPage), findsNothing);

    expect((await result).unwrap(), equals(existingShops[1]));
  });

  testWidgets('new shop creation when no other shops nearby exist',
      (WidgetTester tester) async {
    final context = await tester.superPump(Container());

    // Far away from our 2 existing shops
    final result = shopsCreationManager.startShopCreation(
        Coord(
          lat: coordBetweenExistingShops.lat + maxDistance * 10,
          lon: coordBetweenExistingShops.lon + maxDistance * 10,
        ),
        context);
    await tester.pumpAndSettle();

    expect(find.byType(CreateShopPage), findsOneWidget);

    await tester.superEnterText(
        find.byKey(const Key('new_shop_name_input')), 'new shop');
    await tester.superTap(find.byKey(const Key('shop_type_dropdown')));
    await tester.superTapDropDownItem(ShopType.bakery.localize(context));
    await tester.superTap(find.text(context.strings.global_done));

    final resultShop = (await result).unwrap();
    expect(resultShop!.name, equals('new shop'));
  });

  testWidgets('new shop creation when other shops nearby exist',
      (WidgetTester tester) async {
    final context = await tester.superPump(Container());

    // Nearby to our 2 existing shops
    final result = shopsCreationManager.startShopCreation(
        coordBetweenExistingShops, context);
    await tester.pumpAndSettle();

    expect(find.byType(CreateShopPage), findsNothing);
    expect(find.byType(PickExistingShopPage), findsOneWidget);
    await tester.superTap(
        find.text(context.strings.pick_existing_shop_page_create_shop_button));
    expect(find.byType(CreateShopPage), findsOneWidget);
    expect(find.byType(PickExistingShopPage), findsNothing);

    await tester.superEnterText(
        find.byKey(const Key('new_shop_name_input')), 'new shop');
    await tester.superTap(find.byKey(const Key('shop_type_dropdown')));
    await tester.superTapDropDownItem(ShopType.bakery.localize(context));
    await tester.superTap(find.text(context.strings.global_done));

    final resultShop = (await result).unwrap();
    expect(resultShop!.name, equals('new shop'));
  });

  testWidgets('existing shop picking is canceled', (WidgetTester tester) async {
    final context = await tester.superPump(Container());

    // Nearby to our 2 existing shops
    final result = shopsCreationManager.startShopCreation(
        coordBetweenExistingShops, context);
    await tester.pumpAndSettle();

    expect(find.byType(PickExistingShopPage), findsOneWidget);
    await tester.superTap(find.byKey(const Key('cancel')));
    expect(find.byType(PickExistingShopPage), findsNothing);

    expect((await result).unwrap(), isNull);
  });

  testWidgets(
      'creation of a new shop is canceled, when nearby of existing shops',
      (WidgetTester tester) async {
    final context = await tester.superPump(Container());

    // Nearby to our 2 existing shops
    final result = shopsCreationManager.startShopCreation(
        coordBetweenExistingShops, context);
    await tester.pumpAndSettle();

    expect(find.byType(PickExistingShopPage), findsOneWidget);
    expect(find.byType(CreateShopPage), findsNothing);

    await tester.superTap(
        find.text(context.strings.pick_existing_shop_page_create_shop_button));

    expect(find.byType(PickExistingShopPage), findsNothing);
    expect(find.byType(CreateShopPage), findsOneWidget);

    await tester.superTap(find.byKey(const Key('cancel')));

    expect(find.byType(PickExistingShopPage), findsNothing);
    expect(find.byType(PickExistingShopPage), findsNothing);

    expect((await result).unwrap(), isNull);
  });

  testWidgets(
      'creation of a new shop is canceled, when no nearby existing shops',
      (WidgetTester tester) async {
    final context = await tester.superPump(Container());

    // No nearby existing shops
    final result = shopsCreationManager.startShopCreation(
        Coord(
          lat: coordBetweenExistingShops.lat + maxDistance * 10,
          lon: coordBetweenExistingShops.lon + maxDistance * 10,
        ),
        context);
    await tester.pumpAndSettle();

    expect(find.byType(PickExistingShopPage), findsNothing);
    expect(find.byType(CreateShopPage), findsOneWidget);

    await tester.superTap(find.byKey(const Key('cancel')));

    expect(find.byType(PickExistingShopPage), findsNothing);
    expect(find.byType(PickExistingShopPage), findsNothing);

    expect((await result).unwrap(), isNull);
  });

  testWidgets(
      'the closer existing shops to a target coord the higher it is in the list',
      (WidgetTester tester) async {
    final context = await tester.superPump(Container());

    // Order 1
    unawaited(shopsCreationManager.startShopCreation(
        existingShops[0].coord, context));
    await tester.pumpAndSettle();
    var center1 = tester.getCenter(find.text(existingShops[0].name));
    var center2 = tester.getCenter(find.text(existingShops[1].name));
    expect(center1.dy, lessThan(center2.dy));

    await tester.superTap(find.byKey(const Key('cancel')));

    // Order 2
    unawaited(shopsCreationManager.startShopCreation(
        existingShops[1].coord, context));
    await tester.pumpAndSettle();
    center1 = tester.getCenter(find.text(existingShops[1].name));
    center2 = tester.getCenter(find.text(existingShops[0].name));
    expect(center1.dy, lessThan(center2.dy));
  });
}
