import 'package:plante/base/result.dart';
import 'package:plante/outside/map/osm/open_street_map.dart';
import 'package:plante/outside/map/osm/osm_search_result.dart';

class OsmSearcher {
  final OpenStreetMap _osm;

  OsmSearcher(this._osm);

  Future<Result<OsmSearchResult, OpenStreetMapError>> search(
      String country, String city, String query) async {
    return _osm.withNominatim(
        (nominatim) async => await nominatim.search(country, city, query));
  }
}
