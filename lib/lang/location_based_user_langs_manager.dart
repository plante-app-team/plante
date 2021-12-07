import 'dart:async';

import 'package:plante/lang/countries_lang_codes_table.dart';
import 'package:plante/lang/location_based_user_langs_storage.dart';
import 'package:plante/location/user_location_manager.dart';
import 'package:plante/logging/analytics.dart';
import 'package:plante/logging/log.dart';
import 'package:plante/model/lang_code.dart';
import 'package:plante/model/shared_preferences_holder.dart';
import 'package:plante/outside/map/user_address/caching_user_address_pieces_obtainer.dart';

/// Please use UserLangsManager instead of this class.
class LocationBasedUserLangsManager {
  final CountriesLangCodesTable _langCodesTable;
  final Analytics _analytics;
  final LocationBasedUserLangsStorage _storage;
  final CachingUserAddressPiecesObtainer _userAddressObtainer;

  final _initCompleter = Completer<void>();
  Future<void> get initFuture => _initCompleter.future;

  LocationBasedUserLangsManager(
      this._langCodesTable,
      UserLocationManager userLocationManager,
      this._analytics,
      this._userAddressObtainer,
      SharedPreferencesHolder prefsHolder,
      {LocationBasedUserLangsStorage? storage})
      : _storage = storage ?? LocationBasedUserLangsStorage(prefsHolder) {
    userLocationManager.callWhenLastPositionKnown((_) async {
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
      Log.i('LocationBasedUserLangsManager: User langs known as $userLangs');
      return;
    }

    final countryCode = await _userAddressObtainer.getUserLocationCountryCode();
    if (countryCode == null) {
      Log.w('LocationBasedUserLangsManager: Cannot determine user langs - '
          'no country code');
      return;
    }

    final langs = _langCodesTable.countryCodeToLangCode(countryCode);
    if (langs == null) {
      Log.w('LocationBasedUserLangsManager: Cannot determine user langs - '
          'no langs for country code: $countryCode');
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
      Log.w('LocationBasedUserLangsManager: Already inited by external code');
      return;
    }
    await _storage.setUserLangs(langs);
  }

  /// Non-empty list **is not guaranteed**.
  Future<List<LangCode>?> getUserLangs() async {
    return await _storage.userLangs();
  }
}
