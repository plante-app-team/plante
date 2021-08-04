import 'package:plante/lang/input_products_lang_storage.dart';
import 'package:plante/model/lang_code.dart';
import 'package:test/test.dart';

import '../fake_shared_preferences.dart';
import '../fake_user_langs_manager.dart';

void main() {
  late FakeSharedPreferences prefs;
  late InputProductsLangStorage inputProductsLangStorage;

  setUp(() async {
    prefs = FakeSharedPreferences();
  });

  Future<void> _putLangToPrefs(LangCode lang) async {
    await prefs.setString(
        InputProductsLangStorage.PREF_INPUT_PRODUCTS_LANG_CODE, lang.name);
  }

  test('initial lang in prefs', () async {
    await _putLangToPrefs(LangCode.ru);
    inputProductsLangStorage = InputProductsLangStorage(
        prefs.asHolder(), FakeUserLangsManager([LangCode.en, LangCode.ru]));
    await Future.delayed(const Duration(milliseconds: 1));

    expect(inputProductsLangStorage.selectedCode, equals(LangCode.ru));
  });

  test('initial lang in prefs but not in known to user languages', () async {
    await _putLangToPrefs(LangCode.de);
    inputProductsLangStorage = InputProductsLangStorage(
        prefs.asHolder(), FakeUserLangsManager([LangCode.en, LangCode.ru]));
    await Future.delayed(const Duration(milliseconds: 1));

    // User doesn't know German so it cannot be selected
    expect(inputProductsLangStorage.selectedCode, isNull);
  });

  test('no initial lang in prefs', () async {
    inputProductsLangStorage = InputProductsLangStorage(
        prefs.asHolder(), FakeUserLangsManager([LangCode.en]));
    await Future.delayed(const Duration(milliseconds: 1));

    expect(inputProductsLangStorage.selectedCode, equals(LangCode.en));
  });

  test('set new stored lang', () async {
    inputProductsLangStorage = InputProductsLangStorage(
        prefs.asHolder(), FakeUserLangsManager([LangCode.en]));
    await Future.delayed(const Duration(milliseconds: 1));

    inputProductsLangStorage.selectedCode = LangCode.nl;
    expect(inputProductsLangStorage.selectedCode, equals(LangCode.nl));
  });

  test('erase stored lang', () async {
    inputProductsLangStorage = InputProductsLangStorage(
        prefs.asHolder(), FakeUserLangsManager([LangCode.en]));
    await Future.delayed(const Duration(milliseconds: 1));

    inputProductsLangStorage.selectedCode = null;
    expect(inputProductsLangStorage.selectedCode, isNull);
  });

  test('selected language is auto-deselected when the user no longer knows it',
      () async {
    final userLangsManager = FakeUserLangsManager([LangCode.en, LangCode.ru]);
    inputProductsLangStorage =
        InputProductsLangStorage(prefs.asHolder(), userLangsManager);
    await Future.delayed(const Duration(milliseconds: 1));

    inputProductsLangStorage.selectedCode = LangCode.ru;
    expect(inputProductsLangStorage.selectedCode, equals(LangCode.ru));

    await userLangsManager.setManualUserLangs([LangCode.en]);
    expect(inputProductsLangStorage.selectedCode, isNull);
  });
}
