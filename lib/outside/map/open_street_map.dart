import 'package:flutter/cupertino.dart';
import 'package:plante/base/result.dart';
import 'package:plante/logging/analytics.dart';
import 'package:plante/outside/backend/mobile_app_config_manager.dart';
import 'package:plante/outside/http_client.dart';
import 'package:plante/outside/map/osm_address.dart';
import 'package:plante/outside/map/osm_interactions_queue.dart';
import 'package:plante/outside/map/osm_nominatim.dart';
import 'package:plante/outside/map/osm_overpass.dart';
import 'package:plante/outside/map/osm_search_result.dart';

enum OpenStreetMapError { NETWORK, OTHER }

class OpenStreetMap {
  late final OsmOverpass _overpass;
  late final OsmNominatim _nominatim;
  final _queue = OsmInteractionsQueue();
  final MobileAppConfigManager _mobileAppConfigManager;

  OpenStreetMap(
      HttpClient http, Analytics analytics, this._mobileAppConfigManager) {
    _overpass = OsmOverpass(http, analytics, _queue);
    _nominatim = OsmNominatim(http, _queue);
  }

  @visibleForTesting
  OpenStreetMap.forTesting(
      {OsmOverpass? overpass,
      OsmNominatim? nominatim,
      required MobileAppConfigManager configManager})
      : _mobileAppConfigManager = configManager {
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
    final nominatim =
        await _isNominatimEnabled() ? _nominatim : _DisabledOsmNominatim();
    return await _queue.enqueue<R, E>(
        () async => await interaction.call(nominatim),
        service: OsmInteractionService.NOMINATIM);
  }

  Future<bool> _isNominatimEnabled() async {
    final config = await _mobileAppConfigManager.getConfig();
    return config?.nominatimEnabled ?? true;
  }
}

class _DisabledOsmNominatim implements OsmNominatim {
  static _DisabledOsmNominatim instance = _DisabledOsmNominatim._();

  factory _DisabledOsmNominatim() => instance;
  _DisabledOsmNominatim._();

  @override
  Future<Result<OsmAddress, OpenStreetMapError>> fetchAddress(
      double lat, double lon) async {
    return Err(OpenStreetMapError.OTHER);
  }

  @override
  Future<Result<OsmSearchResult, OpenStreetMapError>> search(
      String country, String city, String query) async {
    return Err(OpenStreetMapError.OTHER);
  }
}
