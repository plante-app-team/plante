import 'dart:convert';

import 'package:plante/base/base.dart';
import 'package:plante/lang/_user_langs_storage.dart';
import 'package:plante/model/lang_code.dart';
import 'package:plante/model/user_langs.dart';
import 'package:test/test.dart';

import '../fake_shared_preferences.dart';

void main() {
  late FakeSharedPreferences prefs;

  setUp(() async {
    prefs = FakeSharedPreferences();
  });

  test('load with good user langs', () async {
    final langs = UserLangs((e) => e
      ..auto = false
      ..sysLang = LangCode.en
      ..langs.addAll([LangCode.be, LangCode.en]));
    await prefs.setString(
        UserLangsStorage.PREF_USER_LANGS,
        jsonEncode(langs.toJson()));

    final userLangsStorage = UserLangsStorage(prefs.asHolder());
    UserLangs? obtainedParams;
    unawaited(userLangsStorage.userLangs().then((value) {
      obtainedParams = value;
    }));

    expect(obtainedParams, isNull);
    // Wait for init finish
    await userLangsStorage.userLangs();
    expect(obtainedParams, equals(langs));
  });

  test('load without user langs', () async {
    await prefs.remove(UserLangsStorage.PREF_USER_LANGS);

    final userLangsStorage = UserLangsStorage(prefs.asHolder());
    bool receivedEmptyLangs = false;
    unawaited(userLangsStorage.userLangs().then((value) {
      receivedEmptyLangs = value == null;
    }));

    expect(receivedEmptyLangs, isFalse);
    // Wait for init finish
    await userLangsStorage.userLangs();
    expect(receivedEmptyLangs, isTrue);
  });

  test('load with bad user langs', () async {
    await prefs.setString(
        UserLangsStorage.PREF_USER_LANGS,
        'that is not a json');

    final userLangsStorage = UserLangsStorage(prefs.asHolder());
    bool receivedEmptyLangs = false;
    unawaited(userLangsStorage.userLangs().then((value) {
      receivedEmptyLangs = value == null;
    }));

    expect(receivedEmptyLangs, isFalse);
    // Wait for init finish
    await userLangsStorage.userLangs();
    expect(receivedEmptyLangs, isTrue);
  });

  test('set user langs', () async {
    final userLangsStorage = UserLangsStorage(prefs.asHolder());
    await userLangsStorage.userLangs(); // Wait for init finish

    expect(prefs.getKeys(), equals(<String>{}));
    final langs = UserLangs((e) => e
      ..auto = false
      ..sysLang = LangCode.en
      ..langs.addAll([LangCode.be, LangCode.en]));
    await userLangsStorage.setUserLangs(langs);
    expect(prefs.getKeys(), equals({UserLangsStorage.PREF_USER_LANGS}));

    final userLangsStorage2 = UserLangsStorage(prefs.asHolder());
    expect(await userLangsStorage2.userLangs(), equals(langs));

    await userLangsStorage2.setUserLangs(null);
    expect(prefs.getKeys(), equals(<String>{}));

    final userLangsStorage3 = UserLangsStorage(prefs.asHolder());
    expect(await userLangsStorage3.userLangs(), isNull);
  });
}
