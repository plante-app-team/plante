import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';
import 'package:flutter/material.dart';
import 'package:plante/l10n/strings.dart';
import 'package:plante/logging/log.dart';

part 'lang_code.g.dart';

class LangCode extends EnumClass {
  static const LangCode ar = _$ar;
  static const LangCode be = _$be;
  static const LangCode bg = _$bg;
  static const LangCode ca = _$ca;
  static const LangCode cs = _$cs;
  static const LangCode da = _$da;
  static const LangCode de = _$de;
  static const LangCode el = _$el;
  static const LangCode en = _$en;
  static const LangCode es = _$es;
  static const LangCode fi = _$fi;
  static const LangCode fr = _$fr;
  static const LangCode hi = _$hi;
  static const LangCode hr = _$hr;
  static const LangCode hu = _$hu;
  static const LangCode in_ = _$in;
  static const LangCode it = _$it;
  static const LangCode iw = _$iw;
  static const LangCode ja = _$ja;
  static const LangCode ko = _$ko;
  static const LangCode kk = _$kk;
  static const LangCode lt = _$lt;
  static const LangCode lv = _$lv;
  static const LangCode nb = _$nb;
  static const LangCode nl = _$nl;
  static const LangCode pl = _$pl;
  static const LangCode pt = _$pt;
  static const LangCode ro = _$ro;
  static const LangCode ru = _$ru;
  static const LangCode sk = _$sk;
  static const LangCode sl = _$sl;
  static const LangCode sr = _$sr;
  static const LangCode sv = _$sv;
  static const LangCode th = _$th;
  static const LangCode tl = _$tl;
  static const LangCode tr = _$tr;
  static const LangCode uk = _$uk;
  static const LangCode vi = _$vi;
  static const LangCode zh = _$zh;

  const LangCode._(String name) : super(name);

  static BuiltSet<LangCode> get values => _$values;
  static LangCode valueOf(String name) => _$valueOf(name);
  static Serializer<LangCode> get serializer => _$langCodeSerializer;

  static LangCode? safeValueOf(String name) {
    if (name.trim().isEmpty) {
      return null;
    }
    try {
      return valueOf(name);
    } on ArgumentError {
      if (name.isNotEmpty) {
        Log.w('LangCode unknown name: $name');
      }
      return null;
    }
  }

  static List<LangCode?> get valuesWithNull {
    final result = <LangCode?>[];
    result.add(null);
    result.addAll(values);
    return result;
  }

  static List<LangCode?> valuesWithNullForUI(BuildContext context) {
    final result = <LangCode?>[];
    result.addAll(valuesForUI(context));
    result.insert(0, null);
    return result;
  }

  static List<LangCode> valuesForUI(BuildContext context) {
    final result = <LangCode>[];
    result.addAll(values);
    result.sort(
        (lhs, rhs) => lhs.localize(context).compareTo(rhs.localize(context)));
    return result;
  }

  String localize(BuildContext context) {
    switch (this) {
      case ar:
        return context.strings.lang_ar;
      case be:
        return context.strings.lang_be;
      case bg:
        return context.strings.lang_bg;
      case ca:
        return context.strings.lang_ca;
      case cs:
        return context.strings.lang_cs;
      case da:
        return context.strings.lang_da;
      case de:
        return context.strings.lang_de;
      case el:
        return context.strings.lang_el;
      case en:
        return context.strings.lang_en;
      case es:
        return context.strings.lang_es;
      case fi:
        return context.strings.lang_fi;
      case fr:
        return context.strings.lang_fr;
      case hi:
        return context.strings.lang_hi;
      case hr:
        return context.strings.lang_hr;
      case hu:
        return context.strings.lang_hu;
      case in_:
        return context.strings.lang_in;
      case it:
        return context.strings.lang_it;
      case iw:
        return context.strings.lang_iw;
      case ja:
        return context.strings.lang_ja;
      case kk:
        return context.strings.lang_kk;
      case ko:
        return context.strings.lang_ko;
      case lt:
        return context.strings.lang_lt;
      case lv:
        return context.strings.lang_lv;
      case nb:
        return context.strings.lang_nb;
      case nl:
        return context.strings.lang_nl;
      case pl:
        return context.strings.lang_pl;
      case pt:
        return context.strings.lang_pt;
      case ro:
        return context.strings.lang_ro;
      case ru:
        return context.strings.lang_ru;
      case sk:
        return context.strings.lang_sk;
      case sl:
        return context.strings.lang_sl;
      case sr:
        return context.strings.lang_sr;
      case sv:
        return context.strings.lang_sv;
      case th:
        return context.strings.lang_th;
      case tl:
        return context.strings.lang_tl;
      case tr:
        return context.strings.lang_tr;
      case uk:
        return context.strings.lang_uk;
      case vi:
        return context.strings.lang_vi;
      case zh:
        return context.strings.lang_zh;
      default:
        throw UnimplementedError('Unknown lang code: $this');
    }
  }
}
