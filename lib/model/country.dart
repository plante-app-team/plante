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

  ///Bosnia and Herzegovina
  static const Country ba = _$ba;

  ///Barbados
  static const Country bb = _$bb;

  ///Bangladesh
  static const Country bd = _$bd;

  ///Belgium
  static const Country be = _$be;

  ///Burkina Faso
  static const Country bf = _$bf;

  ///Bulgaria
  static const Country bg = _$bg;

  ///Bahrain
  static const Country bh = _$bh;

  ///Burundi
  static const Country bi = _$bi;

  ///Benin
  static const Country bj = _$bj;

  ///Saint Barthelemy
  static const Country bl = _$bl;

  ///Bermuda
  static const Country bm = _$bm;

  ///Brunei
  static const Country bn = _$bn;

  ///Bolivia
  static const Country bo = _$bo;

  ///Caribbean Netherlands
  static const Country bq = _$bq;

  ///Brazil
  static const Country br = _$br;

  ///The Bahamas
  static const Country bs = _$bs;

  ///Bhutan
  static const Country bt = _$bt;

  ///Bouvet Island
  static const Country bv = _$bv;

  ///Botswana
  static const Country bw = _$bw;

  ///Belarus
  static const Country by = _$by;

  ///Belize
  static const Country bz = _$bz;

  ///Canada
  static const Country ca = _$ca;

  ///Cocos Islands
  static const Country cc = _$cc;

  ///Congo-Kinshasa
  static const Country cd = _$cd;

  ///Central African Republic
  static const Country cf = _$cf;

  ///Republic of the Congo
  static const Country cg = _$cg;

  ///Suisse
  static const Country ch = _$ch;

  ///Ivory Coast
  static const Country ci = _$ci;

  ///Cook Islands
  static const Country ck = _$ck;

  ///Chili
  static const Country cl = _$cl;

  ///Cameroon
  static const Country cm = _$cm;

  ///China
  static const Country cn = _$cn;

  ///Colombia
  static const Country co = _$co;

  ///Costa Rica
  static const Country cr = _$cr;

  ///Cuba
  static const Country cu = _$cu;

  ///Cape Verde
  static const Country cv = _$cv;

  ///Curacao
  static const Country cw = _$cw;

  ///Christmas Island
  static const Country cx = _$cx;

  ///Cyprus
  static const Country cy = _$cy;

  ///Czech Republic
  static const Country cz = _$cz;

  ///Germany
  static const Country de = _$de;

  ///Djibouti
  static const Country dj = _$dj;

  ///Denmark
  static const Country dk = _$dk;

  ///Dominica
  static const Country dm = _$dm;

  ///Dominican Republic
  //TODO find a way to use do
  //static const Country do = _$do;

  ///Algeria
  static const Country dz = _$dz;

  ///Netherlands
  static const Country nl = _$nl;

  ///France
  static const Country fr = _$fr;

  ///Luxembourg
  static const Country lu = _$lu;

  ///Russia
  static const Country ru = _$ru;

  const Country._(String name) : super(name);

  static BuiltSet<Country> get values => _$values;
  static Country valueOf(String name) => _$valueOf(name);
  static Serializer<Country> get serializer => _$countrySerializer;
  static Country? safeValueOf(String name) {
    if (name.trim().isEmpty) {
      return null;
    }
    try {
      return valueOf(name);
    } on ArgumentError catch (e) {
      if (name.isNotEmpty) {
        Log.w('Country unknown name: $name', ex: e);
      }
      return null;
    }
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
      case ba:
        return context.strings.country_ba;
      case bb:
        return context.strings.country_bb;
      case bd:
        return context.strings.country_bd;
      case be:
        return context.strings.country_be;
      case bf:
        return context.strings.country_bf;
      case bg:
        return context.strings.country_bg;
      case bh:
        return context.strings.country_bh;
      case bi:
        return context.strings.country_bi;
      case bj:
        return context.strings.country_bj;
      case bl:
        return context.strings.country_bl;
      case bm:
        return context.strings.country_bm;
      case bn:
        return context.strings.country_bn;
      case bo:
        return context.strings.country_bo;
      case bq:
        return context.strings.country_bq;
      case br:
        return context.strings.country_br;
      case bs:
        return context.strings.country_bs;
      case bt:
        return context.strings.country_bt;
      case bv:
        return context.strings.country_bv;
      case bw:
        return context.strings.country_bw;
      case by:
        return context.strings.country_by;
      case bz:
        return context.strings.country_bz;
      case ca:
        return context.strings.country_ca;
      case cc:
        return context.strings.country_cc;
      case cd:
        return context.strings.country_cd;
      case cf:
        return context.strings.country_cf;
      case cg:
        return context.strings.country_cg;
      case ch:
        return context.strings.country_ch;
      case ci:
        return context.strings.country_ci;
      case ck:
        return context.strings.country_ck;
      case cl:
        return context.strings.country_cl;
      case cm:
        return context.strings.country_cm;
      case cn:
        return context.strings.country_cn;
      case co:
        return context.strings.country_co;
      case cr:
        return context.strings.country_cr;
      case cu:
        return context.strings.country_cu;
      case cv:
        return context.strings.country_cv;
      case cw:
        return context.strings.country_cw;
      case cx:
        return context.strings.country_cx;
      case cy:
        return context.strings.country_cy;
      case cz:
        return context.strings.country_cz;
      case de:
        return context.strings.country_de;
      case dj:
        return context.strings.country_dj;
      case dk:
        return context.strings.country_dk;
      case dm:
        return context.strings.country_dm;
        // case dom:
        //return context.strings.country_do;
      case dz:
        return context.strings.country_dz;
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
