import 'package:plante/base/coord_utils.dart';
import 'package:plante/base/pair.dart';
import 'package:plante/model/coord.dart';
import 'package:plante/outside/map/osm/osm_address.dart';
import 'package:plante/outside/map/user_address/distinct_address_type_obtainer.dart';
import 'package:plante/outside/map/user_address/distinct_address_type_storage.dart';
import 'package:test/test.dart';

import '../../../z_fakes/fake_address_obtainer.dart';
import '../../../z_fakes/fake_shared_preferences.dart';

void main() {
  final initialCoord = Coord(lat: 1, lon: 1);
  final initialAddress = OsmAddress((e) => e.countryCode = 'ru');
  const maxToleratedDistance = 10;
  late FakeSharedPreferences prefs;
  late DistinctAddressTypeStorage storage;
  late FakeAddressObtainer addressObtainer;
  late DistinctAddressTypeObtainer obtainer;

  Coord? currentCoord;
  final currentAddress = OsmAddress((e) => e.countryCode = 'be');

  var coordRequestsCount = 0;

  setUp(() async {
    prefs = FakeSharedPreferences();
    storage = DistinctAddressTypeStorage(prefs.asHolder(), 'persistent_name');
    addressObtainer = FakeAddressObtainer();

    await storage.updateLastAddress(initialCoord, initialAddress);
    currentCoord = Coord(
      lat: initialCoord.lat + kmToGrad(maxToleratedDistance + 1),
      lon: initialCoord.lon + kmToGrad(maxToleratedDistance + 1),
    );
    addressObtainer.setDefaultResponse(currentAddress);
    coordRequestsCount = 0;

    obtainer = DistinctAddressTypeObtainer(
      'persistent_name',
      storage,
      addressObtainer,
      () async {
        coordRequestsCount += 1;
        return currentCoord;
      },
      maxToleratedDistance,
    );
  });

  test('good scenario', () async {
    // Initial address is stored in the storage initially
    expect(await storage.lastAddress(),
        equals(Pair(initialCoord, initialAddress)));

    // Let's obtain current address
    expect(await obtainer.obtainAddress(), equals(currentAddress));

    // Current address is now stored in the storage
    expect(await storage.lastAddress(),
        equals(Pair(currentCoord!, currentAddress)));
  });

  test('last address returned if current location unavailable', () async {
    currentCoord = null;

    // Current address cannot be obtained without current location
    expect(await obtainer.obtainAddress(), equals(initialAddress));

    // Initial address is still in the storage
    expect(await storage.lastAddress(),
        equals(Pair(initialCoord, initialAddress)));
  });

  test('last address returned if current location is within tolerated radius',
      () async {
    currentCoord = Coord(
      lat: initialCoord.lat + kmToGrad(maxToleratedDistance / 2),
      lon: initialCoord.lon + kmToGrad(maxToleratedDistance / 2),
    );

    // Current address should not be obtained if coordinate is
    // within tolerated radius
    expect(await obtainer.obtainAddress(), equals(initialAddress));

    // Initial address is still in the storage
    expect(await storage.lastAddress(),
        equals(Pair(initialCoord, initialAddress)));
  });

  test('last address returned if current address cannot be obtained', () async {
    addressObtainer.setDefaultResponse(null);

    // Current address cannot be obtained if.. it cannot be obtained
    expect(await obtainer.obtainAddress(), equals(initialAddress));

    // Initial address is still in the storage
    expect(await storage.lastAddress(),
        equals(Pair(initialCoord, initialAddress)));
  });

  test('2 consequent immediate calls cause 1 fn call', () async {
    expect(coordRequestsCount, equals(0));

    final future1 = obtainer.obtainAddress();
    final future2 = obtainer.obtainAddress();
    final results = await Future.wait([future1, future2]);

    expect(coordRequestsCount, equals(1));

    expect(results[0], equals(currentAddress));
    expect(results[1], equals(currentAddress));
  });
}
