import 'package:plante/l10n/strings.dart';
import 'package:plante/logging/log.dart';
import 'package:plante/model/country.dart';
import 'package:plante/model/country_code.dart';

class CountryTable {
  static Country? getCountry(String? iso2Code) {
    Country? result;
    if (iso2Code != null) {
      result = countryTable[iso2Code];
      if (result == null) {
        Log.w('CountryTable.dart: No country found for code $iso2Code');
      }
    }
    return result;
  }
}

Map<String, Country> countryTable = {
  CountryCode.BELGIUM: Country(
      iso2Code: CountryCode.BELGIUM,
      localize: (context) => context.strings.country_be,
      languages: const ['nl', 'fr', 'de'],
      showOffProducts: true),
  CountryCode.FRANCE: Country(
      iso2Code: CountryCode.FRANCE,
      localize: (context) => context.strings.country_fr,
      languages: const ['fr'],
      showOffProducts: true),
  CountryCode.GERMANY: Country(
      iso2Code: CountryCode.GERMANY,
      localize: (context) => context.strings.country_de,
      languages: const ['de'],
      showOffProducts: true),
  CountryCode.NETHERLANDS: Country(
      iso2Code: CountryCode.NETHERLANDS,
      localize: (context) => context.strings.country_nl,
      languages: const ['nl'],
      showOffProducts: true),
  CountryCode.LUXEMBOURG: Country(
      iso2Code: CountryCode.LUXEMBOURG,
      localize: (context) => context.strings.country_lu,
      languages: const ['lb', 'fr', 'de'],
      showOffProducts: true),
  CountryCode.DENMARK: Country(
      iso2Code: CountryCode.DENMARK,
      localize: (context) => context.strings.country_dk,
      languages: const ['da'],
      showOffProducts: true),
  CountryCode.GREAT_BRITAIN: Country(
      iso2Code: CountryCode.GREAT_BRITAIN,
      localize: (context) => context.strings.country_gb,
      languages: const ['en', 'ga', 'cy', 'gd', 'kw'],
      showOffProducts:
          false), //disabled OFF uses UK for in their url, need fix for this
  CountryCode.GREECE: Country(
      iso2Code: CountryCode.GREECE,
      localize: (context) => context.strings.country_gr,
      languages: const ['el'],
      showOffProducts: true),
  CountryCode.ITALY: Country(
      iso2Code: CountryCode.ITALY,
      localize: (context) => context.strings.country_it,
      languages: const ['it', 'de', 'fr'],
      showOffProducts: true),
  CountryCode.NORWAY: Country(
      iso2Code: CountryCode.NORWAY,
      localize: (context) => context.strings.country_no,
      languages: const ['nb', 'nn', 'no', 'se'],
      showOffProducts: true),
  CountryCode.POLAND: Country(
      iso2Code: CountryCode.POLAND,
      localize: (context) => context.strings.country_pl,
      languages: const ['pl'],
      showOffProducts: true),
  CountryCode.PORTUGAL: Country(
      iso2Code: CountryCode.PORTUGAL,
      localize: (context) => context.strings.country_pt,
      languages: const ['pt'],
      showOffProducts: true),
  CountryCode.SPAIN: Country(
      iso2Code: CountryCode.SPAIN,
      localize: (context) => context.strings.country_es,
      languages: const ['ast', 'ca', 'es', 'eu', 'gl'],
      showOffProducts: true),
  CountryCode.SWEDEN: Country(
      iso2Code: CountryCode.SWEDEN,
      localize: (context) => context.strings.country_se,
      languages: const ['sv'],
      showOffProducts: true),
};
