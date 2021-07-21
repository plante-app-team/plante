import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:plante/lang/_user_langs_storage.dart';
import 'package:plante/lang/countries_lang_codes_table.dart';
import 'package:plante/lang/sys_lang_code_holder.dart';
import 'package:plante/location/location_controller.dart';
import 'package:plante/logging/log.dart';
import 'package:plante/model/lang_code.dart';
import 'package:plante/model/user_langs.dart';
import 'package:plante/model/shared_preferences_holder.dart';
import 'package:plante/outside/map/open_street_map.dart';

class UserLangsManager {
  final SysLangCodeHolder _sysLangCodeHolder;
  final CountriesLangCodesTable _langCodesTable;
  final LocationController _locationController;
  final OpenStreetMap _osm;
  final UserLangsStorage _storage;

  final _firstInitCompleterForTesting = Completer<void>();

  @visibleForTesting
  Future<void> get firstInitFutureForTesting =>
      _firstInitCompleterForTesting.future;

  UserLangsManager(this._sysLangCodeHolder, this._langCodesTable,
      this._locationController, this._osm, SharedPreferencesHolder prefsHolder,
      {UserLangsStorage? storage})
      : _storage = storage ?? UserLangsStorage(prefsHolder) {
    _locationController.callWhenLastPositionKnown((_) {
      _sysLangCodeHolder.callWhenInited((_) async {
        try {
          await _tryFirstInit();
        } finally {
          _firstInitCompleterForTesting.complete();
        }
      });
    });
  }

  Future<void> _tryFirstInit() async {
    var userLangs = await _storage.userLangs();
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

    final addressRes = await _osm.fetchAddress(pos.y, pos.x);
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

    final sysLangCode = LangCode.safeValueOf(_sysLangCodeHolder.langCode);
    if (sysLangCode == null) {
      Log.w(
          'UserLangsManager._initAsync: sys lang is not parsed: $sysLangCode');
    }
    if (sysLangCode != null) {
      langs.remove(sysLangCode);
      langs.insert(0, sysLangCode);
    }

    userLangs = UserLangs((e) => e
      ..auto = true
      ..sysLang = sysLangCode ?? LangCode.en
      ..langs.addAll(langs));
    // Async check
    if (await _storage.userLangs() != null) {
      // Already inited by external code
      Log.w('UserLangsManager._initAsync: Already inited by external code');
      return;
    }
    await _storage.setUserLangs(userLangs);
  }

  Future<UserLangs> getUserLangs() async {
    final sysLangCode = LangCode.safeValueOf(_sysLangCodeHolder.langCode);

    var userLangs = await _storage.userLangs();
    if (userLangs != null) {
      if (sysLangCode != null && !userLangs.langs.contains(sysLangCode)) {
        final codes = userLangs.langs.toList();
        codes.insert(0, sysLangCode);
        userLangs = userLangs.rebuild((e) => e.langs.replace(codes));
      }
      return userLangs;
    }

    Log.w(
        'UserLangsManager.getUserLangs: called when no user params available');
    final LangCode code;
    if (sysLangCode != null) {
      code = sysLangCode;
    } else {
      Log.w(
          'UserLangsManager.getUserLangs: sys lang is not parsed: $sysLangCode');
      code = LangCode.en;
    }
    return UserLangs((e) => e
      ..langs.add(code)
      ..sysLang = code
      ..auto = true);
  }

  Future<void> setManualUserLangs(List<LangCode> userLangs) async {
    final sysLangCode =
        LangCode.safeValueOf(_sysLangCodeHolder.langCode) ?? LangCode.en;
    await _storage.setUserLangs(UserLangs((e) => e
      ..auto = false
      ..langs.addAll(userLangs)
      ..sysLang = sysLangCode));
  }
}
