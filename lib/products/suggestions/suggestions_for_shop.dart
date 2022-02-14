import 'package:plante/outside/map/osm/osm_uid.dart';
import 'package:plante/products/suggestions/suggestion_type.dart';

class SuggestionsForShop {
  final OsmUID osmUID;
  final SuggestionType type;
  final List<String> barcodes;
  SuggestionsForShop(this.osmUID, this.type, this.barcodes);
}
