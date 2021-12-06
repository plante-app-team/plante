import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:plante/lang/countries_lang_codes_table.dart';
import 'package:plante/lang/sys_lang_code_holder.dart';
import 'package:plante/lang/user_langs_manager.dart';
import 'package:plante/location/user_location_manager.dart';
import 'package:plante/logging/log.dart';
import 'package:plante/model/shared_preferences_holder.dart';
import 'package:plante/model/user_langs.dart';
import 'package:plante/outside/map/address_obtainer.dart';
import 'package:plante/ui/base/text_styles.dart';

const PREF_LAST_LOCATION_LANGS =
    'SafeFontEnvironmentDetector_LAST_LOCATION_LANGS';

/// Detects an environment in which [TextStyles] should use a safe font
/// rather than a nice-looking font.
class SafeFontEnvironmentDetector implements UserLangsManagerObserver {
  static const UNSAFE_LANG_CODES = {
    'el', // Greek
  };

  final SysLangCodeHolder _sysLangCodeHolder;
  final UserLangsManager _locationLangsManager;
  final UserLocationManager _userLocationManager;
  final SharedPreferencesHolder _prefsHolder;
  final AddressObtainer _addressObtainer;
  final CountriesLangCodesTable _countriesLangsTable;

  List<String>? _lastUserLangs;
  List<String>? _lastLocationLangCodes;

  final _initCompleter = Completer<void>();
  @visibleForTesting
  Future<void> get initFuture => _initCompleter.future;

  SafeFontEnvironmentDetector(
      this._sysLangCodeHolder,
      this._locationLangsManager,
      this._userLocationManager,
      this._prefsHolder,
      this._addressObtainer,
      this._countriesLangsTable) {
    _locationLangsManager.addObserver(this);
    _initAsync();
  }

  void _initAsync() async {
    final userLangs = await _locationLangsManager.getUserLangs();
    _lastUserLangs = userLangs.langs.map((e) => e.name).toList();

    final prefs = await _prefsHolder.get();
    _lastLocationLangCodes = prefs.getStringList(PREF_LAST_LOCATION_LANGS);

    final locationLangCodes = await _obtainLocalLangCodes();
    if (locationLangCodes != null) {
      _lastLocationLangCodes = locationLangCodes;
      await prefs.setStringList(PREF_LAST_LOCATION_LANGS, locationLangCodes);
    }

    _initCompleter.complete();
  }

  Future<List<String>?> _obtainLocalLangCodes() async {
    final lastKnownPos = await _userLocationManager.lastKnownPosition();
    if (lastKnownPos == null) {
      Log.w('SafeFontEnvironmentDetector could not obtain last pos');
      return null;
    }

    final addressRes = await _addressObtainer.addressOfCoords(lastKnownPos);
    if (addressRes.isErr) {
      Log.w('SafeFontEnvironmentDetector could not obtain address of user pos');
      return null;
    }

    final address = addressRes.unwrap();
    final countryCode = address.countryCode; // TODO: this
    if (countryCode == null) {
      Log.w('SafeFontEnvironmentDetector could not obtain country of user pos');
      return null;
    }
    final langs = _countriesLangsTable.countryCodeToLangCode(countryCode);
    return langs?.map((e) => e.name).toList();
  }

  @override
  void onUserLangsChange(UserLangs userLangs) {
    _lastUserLangs = userLangs.langs.map((e) => e.name).toList();
  }

  bool shouldUseSafeFont() {
    // If UI is in the unsafe lang, then we 100% should show a safe font.
    final sysLang = _sysLangCodeHolder.langCodeNullable;
    final sysLangs = sysLang != null ? [sysLang] : const [];
    if (sysLangs.any((code) => UNSAFE_LANG_CODES.contains(code))) {
      return true;
    }
    // If any of user's lang is unsafe, there's a big probability of
    // user seeing texts in the known to them language.
    final userLangs = _lastUserLangs ?? const [];
    if (userLangs.any((code) => UNSAFE_LANG_CODES.contains(code))) {
      return true;
    }
    // When user is in a country where an unsafe lang is spoken,
    // they're very likely to see products and shops with names
    // in that unsafe lang.
    final localLangs = _lastLocationLangCodes ?? const [];
    if (localLangs.any((code) => UNSAFE_LANG_CODES.contains(code))) {
      return true;
    }
    return false;
  }
}
