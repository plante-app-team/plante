import 'package:plante/base/result.dart';
import 'package:plante/outside/map/osm_interactions_queue.dart';
import 'package:plante/outside/map/osm_nominatim.dart';
import 'package:plante/outside/map/osm_overpass.dart';
import 'package:test/test.dart';

import '../../z_fakes/fake_analytics.dart';
import '../../z_fakes/fake_http_client.dart';

class _FakeAlwaysInteractingOsmQueue implements OsmInteractionsQueue {
  @override
  Future<Result<R, E>> enqueue<R, E>(InteractionFn<R, E> interactionFn,
      {required OsmInteractionService service}) async {
    return await interactionFn.call();
  }

  @override
  bool isInteracting(OsmInteractionService service) => true;
}

class OpenStreetMapTestCommons {
  late FakeHttpClient http;
  late FakeAnalytics analytics;
  late OsmOverpass overpass;
  late OsmNominatim nominatim;

  Future<void> setUp() async {
    http = FakeHttpClient();
    analytics = FakeAnalytics();
    overpass = OsmOverpass(http, analytics, _FakeAlwaysInteractingOsmQueue());
    nominatim = OsmNominatim(http, _FakeAlwaysInteractingOsmQueue());
  }

  /// Second, third, ... Overpass URLs are queried when a query to the previous
  /// has failed in a specific case.
  /// All overpass URLs would be expected to be queried when there are a lot
  /// of such failures.
  void expectAllOverpassUrlsQueried() {
    final forcedOrdered = overpass.urls.values.toList();
    for (var index = 0; index < forcedOrdered.length; ++index) {
      expect(http.getRequestsMatching('.*${forcedOrdered[index]}.*').length,
          equals(1));
    }
  }

  /// Other than the first Overpass URL are queried only on specific errors
  /// of the first URL.
  /// So if such a specific failure did not occur, or no failure occurred
  /// at all, then only a single URL would be expected to be queried.
  void expectSingleOverpassUrlQueried() {
    final forcedOrdered = overpass.urls.values.toList();
    for (var index = 0; index < forcedOrdered.length; ++index) {
      final expectedCount = index == 0 ? 1 : 0;
      expect(http.getRequestsMatching('.*${forcedOrdered[index]}.*').length,
          equals(expectedCount));
    }
  }
}
