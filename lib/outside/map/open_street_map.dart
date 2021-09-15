import 'package:flutter/cupertino.dart';
import 'package:plante/base/result.dart';
import 'package:plante/logging/analytics.dart';
import 'package:plante/outside/http_client.dart';
import 'package:plante/outside/map/osm_interactions_queue.dart';
import 'package:plante/outside/map/osm_nominatim.dart';
import 'package:plante/outside/map/osm_overpass.dart';

enum OpenStreetMapError { NETWORK, OTHER }

class OpenStreetMap {
  late final OsmOverpass _overpass;
  late final OsmNominatim _nominatim;
  final _queue = OsmInteractionsQueue();

  OpenStreetMap(HttpClient http, Analytics analytics) {
    _overpass = OsmOverpass(http, analytics, _queue);
    _nominatim = OsmNominatim(http, _queue);
  }

  @visibleForTesting
  OpenStreetMap.forTesting({OsmOverpass? overpass, OsmNominatim? nominatim}) {
    if (overpass != null) {
      _overpass = overpass;
    }
    if (nominatim != null) {
      _nominatim = nominatim;
    }
  }

  Future<Result<R, E>> withOverpass<R, E>(
      Future<Result<R, E>> Function(OsmOverpass overpass) interaction) async {
    return await _queue.enqueue<R, E>(
        () async => await interaction.call(_overpass),
        service: OsmInteractionService.OVERPASS);
  }

  Future<Result<R, E>> withNominatim<R, E>(
      Future<Result<R, E>> Function(OsmNominatim nominatim) interaction) async {
    return await _queue.enqueue<R, E>(
        () async => await interaction.call(_nominatim),
        service: OsmInteractionService.NOMINATIM);
  }
}
