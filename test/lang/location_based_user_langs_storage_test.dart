import 'dart:convert';

import 'package:plante/base/base.dart';
import 'package:plante/lang/location_based_user_langs_storage.dart';
import 'package:plante/model/lang_code.dart';
import 'package:test/test.dart';

import '../fake_shared_preferences.dart';

void main() {
  late FakeSharedPreferences prefs;

  setUp(() async {
    prefs = FakeSharedPreferences();
  });

  test('load with good user langs', () async {
    final langs = [LangCode.be, LangCode.en];
    await prefs.setString(
        LocationBasedUserLangsStorage.PREF_LOCATION_BASED_USER_LANGS,
        jsonEncode(langs.map((e) => e.name).toList()));

    final userLangsStorage = LocationBasedUserLangsStorage(prefs.asHolder());
    List<LangCode>? obtainedParams;
    unawaited(userLangsStorage.userLangs().then((value) {
      obtainedParams = value;
    }));

    expect(obtainedParams, isNull);
    // Wait for init finish
    await userLangsStorage.userLangs();
    expect(obtainedParams, equals(langs));
  });

  test('load without user langs', () async {
    await prefs
        .remove(LocationBasedUserLangsStorage.PREF_LOCATION_BASED_USER_LANGS);

    final userLangsStorage = LocationBasedUserLangsStorage(prefs.asHolder());
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
        LocationBasedUserLangsStorage.PREF_LOCATION_BASED_USER_LANGS,
        'that is not a json');

    final userLangsStorage = LocationBasedUserLangsStorage(prefs.asHolder());
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
    final userLangsStorage = LocationBasedUserLangsStorage(prefs.asHolder());
    await userLangsStorage.userLangs(); // Wait for init finish

    expect(prefs.getKeys(), equals(<String>{}));
    final langs = [LangCode.be, LangCode.en];
    await userLangsStorage.setUserLangs(langs);
    expect(prefs.getKeys(),
        equals({LocationBasedUserLangsStorage.PREF_LOCATION_BASED_USER_LANGS}));

    final userLangsStorage2 = LocationBasedUserLangsStorage(prefs.asHolder());
    expect(await userLangsStorage2.userLangs(), equals(langs));

    await userLangsStorage2.setUserLangs(null);
    expect(prefs.getKeys(), equals(<String>{}));

    final userLangsStorage3 = LocationBasedUserLangsStorage(prefs.asHolder());
    expect(await userLangsStorage3.userLangs(), isNull);
  });
}
