import 'package:plante/lang/user_langs_manager.dart';
import 'package:plante/model/lang_code.dart';
import 'package:plante/model/shared_preferences_holder.dart';
import 'package:plante/model/user_langs.dart';

class InputProductsLangStorage implements UserLangsManagerObserver {
  static const PREF_INPUT_PRODUCTS_LANG_CODE = 'INPUT_PRODUCTS_LANG_CODE';
  final SharedPreferencesHolder _prefsHolder;
  final UserLangsManager _userLangsManager;
  LangCode? _langCode;

  InputProductsLangStorage(this._prefsHolder, this._userLangsManager) {
    _initAsync();
  }

  void _initAsync() async {
    final prefs = await _prefsHolder.get();
    final strVal = prefs.getString(PREF_INPUT_PRODUCTS_LANG_CODE);
    final userLangs = await _userLangsManager.getUserLangs();
    if (strVal != null) {
      _langCode = LangCode.safeValueOf(strVal);
      _deselectLangIfNotKnown(userLangs);
    } else {
      _langCode = userLangs.langs.first;
    }
    _userLangsManager.addObserver(this);
  }

  void _deselectLangIfNotKnown(UserLangs userLangs) {
    if (!userLangs.langs.contains(_langCode)) {
      _langCode = null;
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
      await prefs.setString(PREF_INPUT_PRODUCTS_LANG_CODE, value.name);
    } else {
      await prefs.remove(PREF_INPUT_PRODUCTS_LANG_CODE);
    }
  }

  @override
  void onUserLangsChange(UserLangs userLangs) {
    _deselectLangIfNotKnown(userLangs);
  }
}
