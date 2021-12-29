import 'package:plante/base/result.dart';
import 'package:plante/outside/map/osm/open_street_map.dart';
import 'package:plante/outside/map/osm/osm_address.dart';
import 'package:plante/outside/map/osm/osm_nominatim.dart';
import 'package:plante/outside/map/osm/osm_search_result.dart';
import 'package:test/test.dart';

import '../../../z_fakes/fake_mobile_app_config_manager.dart';

void main() {
  late _FakeOsmNominatim osmNominatim;
  late FakeMobileAppConfigManager mobileAppConfigManager;
  late OpenStreetMap osm;

  setUp(() async {
    osmNominatim = _FakeOsmNominatim();
    mobileAppConfigManager = FakeMobileAppConfigManager();
    osm = OpenStreetMap.forTesting(
        nominatim: osmNominatim, configManager: mobileAppConfigManager);
  });

  test('nominatim can be disabled', () async {
    expect(osmNominatim.callsCount, equals(0));
    await osm.withNominatim((nominatim) => nominatim.search('', '', ''));
    expect(osmNominatim.callsCount, equals(1));
    await osm.withNominatim((nominatim) => nominatim.fetchAddress(123, 123));
    expect(osmNominatim.callsCount, equals(2));

    // After we disable Nominatim, calls count doesn't change
    mobileAppConfigManager.setNominatimEnabled(false);
    await osm.withNominatim((nominatim) => nominatim.search('', '', ''));
    expect(osmNominatim.callsCount, equals(2));
    await osm.withNominatim((nominatim) => nominatim.fetchAddress(123, 123));
    expect(osmNominatim.callsCount, equals(2));

    // But when we enable it back, calls come back too
    mobileAppConfigManager.setNominatimEnabled(true);
    await osm.withNominatim((nominatim) => nominatim.search('', '', ''));
    expect(osmNominatim.callsCount, equals(3));
    await osm.withNominatim((nominatim) => nominatim.fetchAddress(123, 123));
    expect(osmNominatim.callsCount, equals(4));
  });
}

class _FakeOsmNominatim implements OsmNominatim {
  var callsCount = 0;

  @override
  Future<Result<OsmAddress, OpenStreetMapError>> fetchAddress(
      double lat, double lon,
      {String? langCode}) async {
    callsCount += 1;
    return Err(OpenStreetMapError.OTHER);
  }

  @override
  Future<Result<OsmSearchResult, OpenStreetMapError>> search(
      String country, String city, String query) async {
    callsCount += 1;
    return Err(OpenStreetMapError.OTHER);
  }
}
