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

  ///Anguilla
  static const Country ai = _$ai;

  ///Albania
  static const Country al = _$al;

  ///Armenia
  static const Country am = _$am;

  ///Angola
  static const Country ao = _$ao;

  ///Antarctica
  static const Country aq = _$aq;

  ///Argentina
  static const Country ar = _$ar;

  ///American Samoa
  static const Country as = _$as;

  ///Austria
  static const Country at = _$at;

  ///Australia
  static const Country au = _$au;

  ///Aruba
  static const Country aw = _$aw;

  ///Aland Islands
  static const Country ax = _$ax;

  ///Azerbaijan
  static const Country az = _$az;

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
      case ai:
        return context.strings.country_ai;
      case al:
        return context.strings.country_al;
      case am:
        return context.strings.country_am;
      case ao:
        return context.strings.country_ao;
      case aq:
        return context.strings.country_aq;
      case ar:
        return context.strings.country_ar;
      case as:
        return context.strings.country_as;
      case at:
        return context.strings.country_at;
      case au:
        return context.strings.country_au;
      case aw:
        return context.strings.country_aw;
      case ax:
        return context.strings.country_ax;
      case az:
        return context.strings.country_az;
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
      case de:
        return context.strings.country_de;
      default:
        Log.w('no translation found for country code $this in country.dart');
        return null;
    }
  }
}
