import 'dart:async';

import 'package:plante/lang/countries_lang_codes_table.dart';
import 'package:plante/lang/sys_lang_code_holder.dart';
import 'package:plante/model/coord.dart';
import 'package:plante/model/lang_code.dart';
import 'package:plante/outside/map/osm/osm_address.dart';
import 'package:plante/ui/base/safe_font_environment_detector.dart';
import 'package:test/test.dart';

import '../../z_fakes/fake_address_obtainer.dart';
import '../../z_fakes/fake_analytics.dart';
import '../../z_fakes/fake_shared_preferences.dart';
import '../../z_fakes/fake_user_langs_manager.dart';
import '../../z_fakes/fake_user_location_manager.dart';

void main() {
  final unsafeLang =
      LangCode.valueOf(SafeFontEnvironmentDetector.UNSAFE_LANG_CODES.first);

  late SysLangCodeHolder sysLangCodeHolder;
  late FakeUserLangsManager userLangsManager;
  late FakeUserLocationManager userLocationManager;
  late FakeSharedPreferences prefs;
  late FakeAddressObtainer addressObtainer;
  late CountriesLangCodesTable countriesLangsTable;

  late SafeFontEnvironmentDetector safeFontEnvDetector;

  setUp(() async {
    sysLangCodeHolder = SysLangCodeHolder();
    userLangsManager = FakeUserLangsManager([LangCode.en]);
    userLocationManager = FakeUserLocationManager();
    prefs = FakeSharedPreferences();
    addressObtainer = FakeAddressObtainer();
    countriesLangsTable = CountriesLangCodesTable(FakeAnalytics());
  });

  Future<void> init({
    LangCode? sysLang,
    List<LangCode>? userLangs,
    String? userCountry,
  }) async {
    if (sysLang != null) {
      sysLangCodeHolder.langCode = sysLang.name;
    }
    if (userLangs != null) {
      await userLangsManager.setManualUserLangs(userLangs);
    }
    if (userCountry != null) {
      userLocationManager.setCurrentPosition(Coord(lat: 1, lon: 1));
      addressObtainer
          .setResponse(OsmAddress((e) => e.countryCode = userCountry));
    } else {
      userLocationManager.setCurrentPosition(null);
      addressObtainer.setResponse(null);
    }

    safeFontEnvDetector = SafeFontEnvironmentDetector(
      sysLangCodeHolder,
      userLangsManager,
      userLocationManager,
      prefs.asHolder(),
      addressObtainer,
      countriesLangsTable,
    );
    await safeFontEnvDetector.initFuture;
  }

  test('by default (no specific init) non-safe fonts are allowed', () async {
    await init();
    expect(safeFontEnvDetector.shouldUseSafeFont(), isFalse);
  });

  test('safe font is used for unsafe system langs', () async {
    await init(
      sysLang: unsafeLang,
    );
    expect(safeFontEnvDetector.shouldUseSafeFont(), isTrue);
  });

  test('safe font is used for known to user unsafe langs', () async {
    await init(
      userLangs: [unsafeLang],
    );
    expect(safeFontEnvDetector.shouldUseSafeFont(), isTrue);
  });

  test('safe font is used for unsafe countries', () async {
    await init(
      userCountry: 'gr', // Greek is unsafe
    );
    expect(safeFontEnvDetector.shouldUseSafeFont(), isTrue);
  });

  test('safe font is not used for safe countries', () async {
    await init(
      userCountry: 'uk', // England is safe
    );
    expect(safeFontEnvDetector.shouldUseSafeFont(), isFalse);
  });

  test('listens to user langs changes', () async {
    await init(
      userLangs: [LangCode.en],
    );
    expect(safeFontEnvDetector.shouldUseSafeFont(), isFalse);

    await userLangsManager.setManualUserLangs([unsafeLang]);
    expect(safeFontEnvDetector.shouldUseSafeFont(), isTrue);

    await userLangsManager.setManualUserLangs([LangCode.en]);
    expect(safeFontEnvDetector.shouldUseSafeFont(), isFalse);
  });

  test('location lang codes are kept persistently', () async {
    await init(
      userCountry: 'uk', // England is safe
    );
    final detector1 = safeFontEnvDetector;
    expect(safeFontEnvDetector.shouldUseSafeFont(), isFalse);

    // This time no country will be detected,
    // but we expect old country langs to be stored.
    await init();
    final detector2 = safeFontEnvDetector;
    expect(detector2, isNot(equals(detector1))); // Different instances
    // Still can use unsafe fonts
    expect(safeFontEnvDetector.shouldUseSafeFont(), isFalse);

    // This time an unsafe country will be detected
    await init(
      userCountry: 'gr', // Greek is unsafe
    );
    final detector3 = safeFontEnvDetector;
    expect(detector3, isNot(equals(detector2))); // Different instances
    // Greek is not safe
    expect(safeFontEnvDetector.shouldUseSafeFont(), isTrue);

    // This time no country will be detected,
    // but we expect Greece to me memorized.
    await init();
    final detector4 = safeFontEnvDetector;
    expect(detector4, isNot(equals(detector3))); // Different instances
    // Greek is not safe
    expect(safeFontEnvDetector.shouldUseSafeFont(), isTrue);
  });

  test('safe system lang when not inited yet', () async {
    // System lang safe
    sysLangCodeHolder.langCode = LangCode.en.name;
    // User lang unsafe
    await userLangsManager.setManualUserLangs([unsafeLang]);

    safeFontEnvDetector = SafeFontEnvironmentDetector(
      sysLangCodeHolder,
      userLangsManager,
      userLocationManager,
      prefs.asHolder(),
      addressObtainer,
      countriesLangsTable,
    );
    expect(safeFontEnvDetector.shouldUseSafeFont(), isFalse);
    await safeFontEnvDetector.initFuture;
    expect(safeFontEnvDetector.shouldUseSafeFont(), isTrue);
  });

  test('unsafe system lang when not inited yet', () async {
    // System lang unsafe
    sysLangCodeHolder.langCode = unsafeLang.name;
    // User lang safe
    await userLangsManager.setManualUserLangs([LangCode.en]);

    safeFontEnvDetector = SafeFontEnvironmentDetector(
      sysLangCodeHolder,
      userLangsManager,
      userLocationManager,
      prefs.asHolder(),
      addressObtainer,
      countriesLangsTable,
    );
    expect(safeFontEnvDetector.shouldUseSafeFont(), isTrue);
    await safeFontEnvDetector.initFuture;
    expect(safeFontEnvDetector.shouldUseSafeFont(), isTrue);
  });
}
