import 'dart:async';

import 'package:plante/lang/location_based_user_langs_storage.dart';
import 'package:plante/lang/countries_lang_codes_table.dart';
import 'package:plante/location/location_controller.dart';
import 'package:plante/logging/analytics.dart';
import 'package:plante/logging/log.dart';
import 'package:plante/model/lang_code.dart';
import 'package:plante/model/shared_preferences_holder.dart';
import 'package:plante/outside/map/open_street_map.dart';

/// Please use UserLangsManager instead of this class.
class LocationBasedUserLangsManager {
  final CountriesLangCodesTable _langCodesTable;
  final LocationController _locationController;
  final OpenStreetMap _osm;
  final Analytics _analytics;
  final LocationBasedUserLangsStorage _storage;

  final _initCompleter = Completer<void>();
  Future<void> get initFuture => _initCompleter.future;

  LocationBasedUserLangsManager(this._langCodesTable, this._locationController,
      this._osm, this._analytics, SharedPreferencesHolder prefsHolder,
      {LocationBasedUserLangsStorage? storage})
      : _storage = storage ?? LocationBasedUserLangsStorage(prefsHolder) {
    _locationController.callWhenLastPositionKnown((_) async {
      try {
        await _tryFirstInit();
      } finally {
        _initCompleter.complete();
      }
    });
  }

  Future<void> _tryFirstInit() async {
    final userLangs = await _storage.userLangs();
    if (userLangs != null) {
      Log.i('User langs known as $userLangs');
      return;
    }

    // We deliberately don't request current position because it
    // requires the location permission and we want to be able to work
    // without it.
    final pos = await _locationController.lastKnownPosition();
    if (pos == null) {
      Log.w('Cannot determine user langs - no user position available');
      return;
    }

    final addressRes = await _osm.fetchAddress(pos.lat, pos.lon);
    if (addressRes.isErr) {
      Log.w('Cannot determine user langs - OSM error: $addressRes');
      return;
    }

    final address = addressRes.unwrap();
    final countryCode = address.countryCode;
    if (countryCode == null) {
      Log.w('Cannot determine user langs - no country code: $address');
      return;
    }

    final langs = _langCodesTable.countryCodeToLangCode(countryCode);
    if (langs == null) {
      Log.w(
          'Cannot determine user langs - no langs for country code: $countryCode');
      return;
    }

    if (langs.length == 1) {
      _analytics.sendEvent('single_lang_country');
    } else if (langs.length > 1) {
      _analytics.sendEvent('multi_lang_country', {'count': langs.length});
    }

    // Async check
    if (await _storage.userLangs() != null) {
      // Already inited by external code
      Log.w('AutoUserLangsManager._initAsync: Already inited by external code');
      return;
    }
    await _storage.setUserLangs(langs);
  }

  /// Non-empty list **is not guaranteed**.
  Future<List<LangCode>?> getUserLangs() async {
    return await _storage.userLangs();
  }
}
