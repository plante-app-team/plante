import 'package:plante/lang/input_products_lang_storage.dart';
import 'package:plante/model/lang_code.dart';
import 'package:test/test.dart';

import '../common_mocks.dart';
import '../fake_shared_preferences.dart';

void main() {
  late FakeSharedPreferences prefs;
  late InputProductsLangStorage inputProductsLangStorage;

  setUp(() async {
    prefs = FakeSharedPreferences();
  });

  test('initial lang in prefs', () async {
    await prefs.setString(
        InputProductsLangStorage.PREF_INPUT_PRODUCTS_LANG_CODE,
        LangCode.ru.name);
    inputProductsLangStorage = InputProductsLangStorage(
        prefs.asHolder(), mockUserLangsManagerWith([LangCode.en]));
    await Future.delayed(const Duration(milliseconds: 1));

    expect(inputProductsLangStorage.selectedCode, equals(LangCode.ru));
  });

  test('no initial lang in prefs', () async {
    inputProductsLangStorage = InputProductsLangStorage(
        prefs.asHolder(), mockUserLangsManagerWith([LangCode.en]));
    await Future.delayed(const Duration(milliseconds: 1));

    expect(inputProductsLangStorage.selectedCode, equals(LangCode.en));
  });

  test('set new stored lang', () async {
    inputProductsLangStorage = InputProductsLangStorage(
        prefs.asHolder(), mockUserLangsManagerWith([LangCode.en]));
    await Future.delayed(const Duration(milliseconds: 1));

    inputProductsLangStorage.selectedCode = LangCode.nl;
    expect(inputProductsLangStorage.selectedCode, equals(LangCode.nl));
  });

  test('erase stored lang', () async {
    inputProductsLangStorage = InputProductsLangStorage(
        prefs.asHolder(), mockUserLangsManagerWith([LangCode.en]));
    await Future.delayed(const Duration(milliseconds: 1));

    inputProductsLangStorage.selectedCode = null;
    expect(inputProductsLangStorage.selectedCode, isNull);
  });
}