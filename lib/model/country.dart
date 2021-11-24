import 'package:flutter/material.dart';
import 'package:plante/l10n/strings.dart';
import 'package:plante/logging/log.dart';

@immutable
class Country {
  static const ANDORRA = 'ad';
  static const UNITED_ARAB_EMIRATES = 'ae';
  static const AFGHANISTAN = 'af';
  static const ANTIGUA_AND_BARBUDA = 'ag';
  static const BELGIUM = 'be';
  static const NETHERLANDS = 'nl';
  static const FRANCE = 'fr';
  static const GERMANY = 'de';
  static const RUSSIA = 'ru';

// List of countries we load the products from OFF linked to a store
  static const enabledCountryCodes = [BELGIUM, NETHERLANDS, GERMANY, FRANCE];

  static bool isEnabledCountry (String isoCode) {
    return enabledCountryCodes.contains(isoCode);
  }

  static dynamic getTranslation(BuildContext context, String isoCode) {
    switch (isoCode) {
      case ANDORRA:
        return context.strings.country_ad;
      case BELGIUM:
        return context.strings.country_be;
      default:
        Log.e('no translation found for country code $isoCode in country.dart');
        return '';
    }
  }
}
