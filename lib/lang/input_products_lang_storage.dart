import 'package:plante/model/lang_code.dart';
import 'package:plante/model/shared_preferences_holder.dart';
import 'package:plante/ui/base/lang_code_holder.dart';

const INPUT_PRODUCTS_LANG_CODE = 'INPUT_PRODUCTS_LANG_CODE';

class InputProductsLangStorage {
  final SharedPreferencesHolder _prefsHolder;
  final LangCodeHolder _langCodeHolder;
  LangCode? _langCode;

  InputProductsLangStorage(this._prefsHolder, this._langCodeHolder) {
    _initAsync();
  }

  void _initAsync() async {
    final prefs = await _prefsHolder.get();
    final strVal = prefs.getString(INPUT_PRODUCTS_LANG_CODE);
    if (strVal != null) {
      _langCode = LangCode.safeValueOf(strVal);
    } else {
      _langCodeHolder.callWhenInited((langCode) {
        _langCode = LangCode.safeValueOf(langCode);
      });
    }
  }

  LangCode? get selectedCode => _langCode;
  set selectedCode(LangCode? value) {
    _langCode = value;
    _setPref(value);
  }

  void _setPref(LangCode? value) async {
    final prefs = await _prefsHolder.get();
    if (value != null) {
      await prefs.setString(INPUT_PRODUCTS_LANG_CODE, value.name);
    } else {
      await prefs.remove(INPUT_PRODUCTS_LANG_CODE);
    }
  }
}
