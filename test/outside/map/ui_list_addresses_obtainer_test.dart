import 'dart:async';

import 'package:mockito/mockito.dart';
import 'package:plante/base/result.dart';
import 'package:plante/model/coord.dart';
import 'package:plante/model/shop.dart';
import 'package:plante/outside/backend/backend_shop.dart';
import 'package:plante/outside/map/address_obtainer.dart';
import 'package:plante/outside/map/osm_road.dart';
import 'package:plante/outside/map/osm_shop.dart';
import 'package:plante/outside/map/osm_short_address.dart';
import 'package:plante/outside/map/ui_list_addresses_obtainer.dart';
import 'package:test/test.dart';

import '../../common_mocks.mocks.dart';

void main() {
  late MockAddressObtainer wrappedAddressObtainer;

  final address = OsmShortAddress((e) => e.road = 'Broadway');

  setUp(() async {
    wrappedAddressObtainer = MockAddressObtainer();
    when(wrappedAddressObtainer.addressOfShop(any))
        .thenAnswer((_) async => Ok(address));
    when(wrappedAddressObtainer.shortAddressOfCoords(any))
        .thenAnswer((_) async => Ok(address));
  });

  test('addresses of shops', () async {
    final addressesObtainer =
        UiListAddressesObtainer<Shop>(wrappedAddressObtainer);
    final shops = [
      Shop((e) => e
        ..osmShop.replace(OsmShop((e) => e
          ..osmUID = '1:1'
          ..longitude = 10
          ..latitude = 10
          ..name = 'Spar'))
        ..backendShop.replace(BackendShop((e) => e
          ..osmUID = '1:1'
          ..productsCount = 1))),
    ];

    verifyZeroInteractions(wrappedAddressObtainer);
    addressesObtainer.onDisplayedEntitiesChanged(
        displayedEntities: shops, allEntitiesOrdered: shops);
    verify(wrappedAddressObtainer.addressOfShop(any));
    verifyNoMoreInteractions(wrappedAddressObtainer);

    expect(await addressesObtainer.requestAddressOf(shops[0]),
        equals(Ok(address)));
  });

  test('addresses of coords', () async {
    final addressesObtainer =
        UiListAddressesObtainer<Coord>(wrappedAddressObtainer);
    final coords = [
      Coord(lat: 10, lon: 10),
    ];

    verifyZeroInteractions(wrappedAddressObtainer);
    addressesObtainer.onDisplayedEntitiesChanged(
        displayedEntities: coords, allEntitiesOrdered: coords);
    verify(wrappedAddressObtainer.shortAddressOfCoords(any));
    verifyNoMoreInteractions(wrappedAddressObtainer);

    expect(await addressesObtainer.requestAddressOf(coords[0]),
        equals(Ok(address)));
  });

  test('addresses of another type', () async {
    var caught = false;
    try {
      UiListAddressesObtainer<OsmRoad>(wrappedAddressObtainer);
    } catch (e) {
      caught = true;
    }
    expect(caught, isTrue);
  });

  test('only addresses of displayed entities are requested', () async {
    final addressesObtainer =
        UiListAddressesObtainer<Coord>(wrappedAddressObtainer);
    final coords = [
      Coord(lat: 10, lon: 10),
      Coord(lat: 11, lon: 11),
      Coord(lat: 12, lon: 12),
      Coord(lat: 13, lon: 13),
    ];

    verifyZeroInteractions(wrappedAddressObtainer);

    addressesObtainer.onDisplayedEntitiesChanged(
        displayedEntities: [coords[1], coords[2]], allEntitiesOrdered: coords);
    await Future.delayed(const Duration(milliseconds: 10));

    verify(wrappedAddressObtainer.shortAddressOfCoords(coords[1]));
    verify(wrappedAddressObtainer.shortAddressOfCoords(coords[2]));
    verifyNoMoreInteractions(wrappedAddressObtainer);
  });

  test('displayed entities changed while a request is still in progress',
      () async {
    final completer = Completer<ShortAddressResult>();
    when(wrappedAddressObtainer.shortAddressOfCoords(any))
        .thenAnswer((_) async => completer.future);

    final addressesObtainer =
        UiListAddressesObtainer<Coord>(wrappedAddressObtainer);
    final coords = [
      Coord(lat: 10, lon: 10),
      Coord(lat: 11, lon: 11),
      Coord(lat: 12, lon: 12),
      Coord(lat: 13, lon: 13),
    ];

    // Displayed change 1
    addressesObtainer.onDisplayedEntitiesChanged(
        displayedEntities: [coords[0], coords[1]], allEntitiesOrdered: coords);
    await Future.delayed(const Duration(milliseconds: 10));
    // First request to OSM is expected to be sent,
    // but the second one is expected to be not sent, since they
    // are sent sequentially and [completer] is not completed yet.
    verify(wrappedAddressObtainer.shortAddressOfCoords(coords[0]));
    verifyNever(wrappedAddressObtainer.shortAddressOfCoords(coords[1]));

    // Displayed change 2
    addressesObtainer.onDisplayedEntitiesChanged(
        displayedEntities: [coords[2], coords[3]], allEntitiesOrdered: coords);
    await Future.delayed(const Duration(milliseconds: 10));
    // The completer is not completed yet - the OSM request for coords[0] is
    // expected to still be executing, other requests are expected to be
    // postponed.
    verifyNever(wrappedAddressObtainer.shortAddressOfCoords(coords[2]));
    verifyNever(wrappedAddressObtainer.shortAddressOfCoords(coords[3]));

    completer.complete(Ok(address));
    await Future.delayed(const Duration(milliseconds: 10));

    // coords[2] and coords[3] are displayed so they're expected to be
    // requested from OSM ...
    verify(wrappedAddressObtainer.shortAddressOfCoords(coords[2]));
    verify(wrappedAddressObtainer.shortAddressOfCoords(coords[3]));
    // ... but OSM request for coords[1] is expected to be canceled
    // because the list of displayed entities was changed.
    verifyNever(wrappedAddressObtainer.shortAddressOfCoords(coords[1]));
  });

  test(
      'displayed entities second change while first request is still in progress',
      () async {
    final completer = Completer<ShortAddressResult>();
    when(wrappedAddressObtainer.shortAddressOfCoords(any))
        .thenAnswer((_) async => completer.future);

    final addressesObtainer =
        UiListAddressesObtainer<Coord>(wrappedAddressObtainer);
    final coords = [
      Coord(lat: 10, lon: 10),
      Coord(lat: 11, lon: 11),
      Coord(lat: 12, lon: 12),
      Coord(lat: 13, lon: 13),
    ];

    // Displayed change 1
    addressesObtainer.onDisplayedEntitiesChanged(
        displayedEntities: [coords[0]], allEntitiesOrdered: coords);
    await Future.delayed(const Duration(milliseconds: 10));
    verify(wrappedAddressObtainer.shortAddressOfCoords(coords[0]));
    verifyNoMoreInteractions(wrappedAddressObtainer);

    // Displayed change 2
    addressesObtainer.onDisplayedEntitiesChanged(
        displayedEntities: [coords[1], coords[2]], allEntitiesOrdered: coords);
    await Future.delayed(const Duration(milliseconds: 10));
    // The completer is not completed yet - the OSM request for coords[0] is
    // expected to still be executing, other requests are expected to be
    // postponed.
    verifyNever(wrappedAddressObtainer.shortAddressOfCoords(coords[2]));
    verifyNever(wrappedAddressObtainer.shortAddressOfCoords(coords[3]));

    // Displayed change 3
    addressesObtainer.onDisplayedEntitiesChanged(
        displayedEntities: [coords[3]], allEntitiesOrdered: coords);
    await Future.delayed(const Duration(milliseconds: 10));

    completer.complete(Ok(address));
    await Future.delayed(const Duration(milliseconds: 10));

    // coords[3] is displayed so it's expected to be
    // requested from OSM ...
    verify(wrappedAddressObtainer.shortAddressOfCoords(coords[3]));
    // ... but OSM requests for coords[1] and coords[2] are expected
    // to be canceled because the list of displayed entities was changed.
    verifyNever(wrappedAddressObtainer.shortAddressOfCoords(coords[1]));
    verifyNever(wrappedAddressObtainer.shortAddressOfCoords(coords[2]));
  });
}
