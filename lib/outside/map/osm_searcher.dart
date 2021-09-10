import 'package:plante/base/result.dart';
import 'package:plante/outside/map/open_street_map.dart';
import 'package:plante/outside/map/osm_interactions_queue.dart';
import 'package:plante/outside/map/osm_search_result.dart';

class OsmSearcher implements OpenStreetMapReceiver {
  late final OpenStreetMap _osm;
  final OsmInteractionsQueue _osmQueue;

  OsmSearcher(OpenStreetMapHolder osmHolder, this._osmQueue) {
    _osm = osmHolder.getOsm(whoAsks: this);
  }

  Future<Result<OsmSearchResult, OpenStreetMapError>> search(
      String country, String city, String query) async {
    return _osmQueue.enqueue(() async => _osm.search(country, city, query));
  }
}
