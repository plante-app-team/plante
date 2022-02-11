import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:plante/base/settings.dart';
import 'package:plante/l10n/strings.dart';
import 'package:plante/model/country_code.dart';
import 'package:plante/outside/map/user_address/caching_user_address_pieces_obtainer.dart';

class DisplayedDistanceUnitsManager {
  static const MILES_COUNTRIES = {
    CountryCode.UNITED_KINGDOM,
    CountryCode.GREAT_BRITAIN,
    CountryCode.USA,
  };

  final CachingUserAddressPiecesObtainer _userAddressObtainer;
  final Settings _settings;

  final _fullyInited = Completer<void>();

  var _useMiles = false;

  Future<void> get fullyInited => _fullyInited.future;

  DisplayedDistanceUnitsManager(this._userAddressObtainer, this._settings) {
    _settings.addObserver(
        _SettingsObserver(onSettingsChanged: _updatePreferredDistanceUnit));
    _initAsync();
  }

  void _initAsync() async {
    await _updatePreferredDistanceUnit();
    _fullyInited.complete();
  }

  Future<void> _updatePreferredDistanceUnit() async {
    final useMilesSetting = await _settings.distanceInMiles();
    if (useMilesSetting != null) {
      _useMiles = useMilesSetting;
    } else {
      final userCountry =
          await _userAddressObtainer.getUserLocationCountryCode();
      _useMiles = MILES_COUNTRIES.contains(userCountry);
    }
  }

  String metersToStr(double meters, BuildContext context) {
    // If preferred distance unit has changed it will update for
    // the next [metersToStr] call.
    unawaited(_updatePreferredDistanceUnit());

    if (_useMiles) {
      return _milesStr(meters, context);
    } else {
      return _kmStr(meters, context);
    }
  }

  String _milesStr(double meters, BuildContext context) {
    final miles = meters * 0.000621371;
    if (miles < 0.1) {
      final feet = meters * 3.28084;
      return '${feet.round()} ${context.strings.global_feet}';
    } else {
      return '${miles.toStringAsFixed(1)} ${context.strings.global_miles}';
    }
  }

  String _kmStr(double meters, BuildContext context) {
    if (meters < 1000) {
      return '${meters.round()} ${context.strings.global_meters}';
    } else {
      final distanceKms = meters / 1000;
      return '${distanceKms.toStringAsFixed(1)} ${context.strings.global_kilometers}';
    }
  }
}

class _SettingsObserver implements SettingsObserver {
  final VoidCallback onSettingsChanged;
  _SettingsObserver({required this.onSettingsChanged});
  @override
  void onSettingsChange() => onSettingsChanged.call();
}
