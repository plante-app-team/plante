import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';
import 'package:flutter/material.dart';
import 'package:plante/l10n/strings.dart';
import 'package:plante/logging/log.dart';

part 'country.g.dart';

class Country extends EnumClass {
  ///Andorra
  static const Country ad = _$ad;

  ///United Arab Emirates
  static const Country ae = _$ae;

  ///Afghanistan
  static const Country af = _$af;

  ///Antigua and Barbuda
  static const Country ag = _$ag;

  ///Belgium
  static const Country be = _$be;

  ///Netherlands
  static const Country nl = _$nl;

  ///France
  static const Country fr = _$fr;

  ///Germany
  static const Country de = _$de;

  ///Luxembourg
  static const Country lu = _$lu;

  ///Russia
  static const Country ru = _$ru;

  const Country._(String name) : super(name);

  static BuiltSet<Country> get values => _$values;
  static Country valueOf(String name) => _$valueOf(name);
  static Serializer<Country> get serializer => _$countrySerializer;

// List of countries we load the products from OFF linked to a store
  static const enabledCountryCodes = [be, nl, de, fr, lu];

  static bool isEnabledCountry(String isoCode) {
    return enabledCountryCodes.contains(valueOf(isoCode));
  }

  String? localize(BuildContext context) {
    switch (this) {
      case ad:
        return context.strings.country_ad;
      case ae:
        return context.strings.country_ae;
      case af:
        return context.strings.country_af;
      case ag:
        return context.strings.country_ag;
      case be:
        return context.strings.country_be;
      case fr:
        return context.strings.country_fr;
      case nl:
        return context.strings.country_nl;
      case lu:
        return context.strings.country_lu;
      case ru:
        return context.strings.country_ru;
      default:
        Log.w('no translation found for country code $this in country.dart');
        return null;
    }
  }
}
