import 'package:plante/l10n/strings.dart';
import 'package:plante/logging/log.dart';
import 'package:plante/model/country.dart';
import 'package:plante/model/country_code.dart';

class CountryTable {
  static Country? getCountry(String? iso2Code) {
    Country? result;
    if (iso2Code != null) {
      result = _table[iso2Code];
      if (result == null) {
        Log.w('CountryTable.dart: No country found for code $iso2Code');
      }
    }
    return result;
  }

  static final Map<String, Country> _table = {
    CountryCode.BELGIUM: Country(
        iso2Code: CountryCode.BELGIUM,
        localize: (context) => context.strings.country_be,
        languages: const ['nl', 'fr', 'de']),
    CountryCode.FRANCE: Country(
        iso2Code: CountryCode.FRANCE,
        localize: (context) => context.strings.country_fr,
        languages: const ['fr']),
    CountryCode.GERMANY: Country(
        iso2Code: CountryCode.GERMANY,
        localize: (context) => context.strings.country_de,
        languages: const ['de']),
    CountryCode.NETHERLANDS: Country(
        iso2Code: CountryCode.NETHERLANDS,
        localize: (context) => context.strings.country_nl,
        languages: const ['nl']),
    CountryCode.LUXEMBOURG: Country(
        iso2Code: CountryCode.LUXEMBOURG,
        localize: (context) => context.strings.country_lu,
        languages: const ['lb', 'fr', 'de']),
    CountryCode.DENMARK: Country(
        iso2Code: CountryCode.DENMARK,
        localize: (context) => context.strings.country_dk,
        languages: const ['da']),
    CountryCode.GREAT_BRITAIN: Country(
        iso2Code: CountryCode.GREAT_BRITAIN,
        localize: (context) => context.strings.country_gb,
        languages: const ['en', 'ga', 'cy', 'gd', 'kw']),
    CountryCode.GREECE: Country(
        iso2Code: CountryCode.GREECE,
        localize: (context) => context.strings.country_gr,
        languages: const ['el']),
    CountryCode.ITALY: Country(
        iso2Code: CountryCode.ITALY,
        localize: (context) => context.strings.country_it,
        languages: const ['it', 'de', 'fr']),
    CountryCode.NORWAY: Country(
        iso2Code: CountryCode.NORWAY,
        localize: (context) => context.strings.country_no,
        languages: const ['nb', 'nn', 'no', 'se']),
    CountryCode.POLAND: Country(
        iso2Code: CountryCode.POLAND,
        localize: (context) => context.strings.country_pl,
        languages: const ['pl']),
    CountryCode.PORTUGAL: Country(
        iso2Code: CountryCode.PORTUGAL,
        localize: (context) => context.strings.country_pt,
        languages: const ['pt']),
    CountryCode.SPAIN: Country(
        iso2Code: CountryCode.SPAIN,
        localize: (context) => context.strings.country_es,
        languages: const ['ast', 'ca', 'es', 'eu', 'gl']),
    CountryCode.SWEDEN: Country(
        iso2Code: CountryCode.SWEDEN,
        localize: (context) => context.strings.country_se,
        languages: const ['sv']),
  };
}
