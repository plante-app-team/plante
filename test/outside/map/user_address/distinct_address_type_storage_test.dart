import 'package:plante/base/pair.dart';
import 'package:plante/model/coord.dart';
import 'package:plante/outside/map/osm/osm_address.dart';
import 'package:plante/outside/map/user_address/distinct_address_type_storage.dart';
import 'package:test/test.dart';

import '../../../z_fakes/fake_shared_preferences.dart';

void main() {
  late FakeSharedPreferences prefs;
  late DistinctAddressTypeStorage storage;

  setUp(() async {
    prefs = FakeSharedPreferences();
    storage = DistinctAddressTypeStorage(prefs.asHolder(), 'persistent_name');
  });

  test('can set and get', () async {
    var storedVal = await storage.lastAddress();
    expect(storedVal, isNull);

    await storage.updateLastAddress(
        Coord(lat: 1, lon: 2), OsmAddress((e) => e.countryCode = 'gb'));

    storedVal = await storage.lastAddress();
    expect(
        storedVal,
        equals(Pair(
            Coord(lat: 1, lon: 2), OsmAddress((e) => e.countryCode = 'gb'))));

    // New instance
    storage = DistinctAddressTypeStorage(prefs.asHolder(), 'persistent_name');
    expect(await storage.lastAddress(), equals(storedVal));
  });
}
