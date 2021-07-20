import 'dart:convert';
import 'dart:math';

import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:plante/base/base.dart';
import 'package:plante/base/result.dart';
import 'package:plante/lang/_user_langs_storage.dart';
import 'package:plante/lang/countries_lang_codes_table.dart';
import 'package:plante/lang/sys_lang_code_holder.dart';
import 'package:plante/lang/user_langs_manager.dart';
import 'package:plante/model/lang_code.dart';
import 'package:plante/model/user_langs.dart';
import 'package:plante/outside/map/open_street_map.dart';
import 'package:plante/outside/map/osm_address.dart';
import 'package:test/test.dart';

import '../common_mocks.mocks.dart';
import '../fake_analytics.dart';
import '../fake_shared_preferences.dart';
import 'user_langs_manager_test.mocks.dart';

@GenerateMocks([UserLangsStorage])
void main() {
  late SysLangCodeHolder sysLangCodeHolder;
  late CountriesLangCodesTable countriesLangCodesTable;
  late MockLocationController locationController;
  late MockOpenStreetMap osm;
  late MockUserLangsStorage storage;
  late UserLangsManager userLangsManager;

  setUp(() async {
    sysLangCodeHolder = SysLangCodeHolder();
    countriesLangCodesTable = CountriesLangCodesTable(FakeAnalytics());
    locationController = MockLocationController();
    osm = MockOpenStreetMap();
    storage = MockUserLangsStorage();

    when(storage.userLangs()).thenAnswer((_) async => null);
    when(storage.setUserLangs(any)).thenAnswer((invc) async {
      final userLangs = invc.positionalArguments[0] as UserLangs;
      when(storage.userLangs()).thenAnswer((_) async => userLangs);
    });
  });

  Future<void> finishSetUp({
    required Point<double>? lastPos,
    required ResCallback<Result<OsmAddress, OpenStreetMapError>> addressResp,
    required String sysLangCode,
  }) async {
    const initialLastPos = Point<double>(0, 0);
    when(locationController.callWhenLastPositionKnown(any)).thenAnswer((invc) {
      final callback = invc.positionalArguments[0] as ArgCallback<Point<double>>;
      callback.call(initialLastPos);
    });

    when(locationController.lastKnownPosition()).thenAnswer((_) async => lastPos);
    when(osm.fetchAddress(any, any)).thenAnswer((_) async => addressResp.call());
    sysLangCodeHolder.langCode = sysLangCode;

    userLangsManager = UserLangsManager(
      sysLangCodeHolder,
      countriesLangCodesTable,
      locationController,
      osm,
      FakeSharedPreferences().asHolder(),
      storage: storage,
    );
    await userLangsManager.firstInitFutureForTesting;
  }

  test('init with existing user langs', () async {
    final existingLangs = UserLangs((e) => e
      ..codes.addAll([LangCode.en])
      ..auto = false);
    when(storage.userLangs()).thenAnswer((_) async => existingLangs);

    await finishSetUp(
      lastPos: null,
      addressResp: () => Err(OpenStreetMapError.OTHER),
      sysLangCode: 'en',
    );

    expect(await userLangsManager.getUserLangs(), equals(existingLangs));
    verifyNever(storage.setUserLangs(any));
  });

  test('first init good scenario', () async {
    await finishSetUp(
        lastPos: const Point<double>(1, 2),
      addressResp: () => Ok(OsmAddress((e) => e.countryCode = 'be')),
      sysLangCode: 'en',
    );

    final expectedUserLangs = UserLangs((e) => e
      ..codes.addAll([LangCode.en, LangCode.nl, LangCode.fr, LangCode.de])
      ..auto = true);
    expect(await userLangsManager.getUserLangs(), equals(expectedUserLangs));
    verify(storage.setUserLangs(expectedUserLangs));
  });

  test('first init without last known pos', () async {
    await finishSetUp(
      lastPos: null,
      addressResp: () => Ok(OsmAddress((e) => e.countryCode = 'be')),
      sysLangCode: 'en',
    );

    final expectedUserLangs = UserLangs((e) => e
      ..codes.addAll([LangCode.en])
      ..auto = true);
    expect(await userLangsManager.getUserLangs(), equals(expectedUserLangs));
    verifyNever(storage.setUserLangs(any));
  });

  test('first init without osm address (on osm error)', () async {
    await finishSetUp(
      lastPos: const Point<double>(1, 2),
      addressResp: () => Err(OpenStreetMapError.OTHER),
      sysLangCode: 'en',
    );

    final expectedUserLangs = UserLangs((e) => e
      ..codes.addAll([LangCode.en])
      ..auto = true);
    expect(await userLangsManager.getUserLangs(), equals(expectedUserLangs));
    verifyNever(storage.setUserLangs(any));
  });

  test('first init without osm country', () async {
    await finishSetUp(
      lastPos: const Point<double>(1, 2),
      addressResp: () => Ok(OsmAddress((e) => e.houseNumber = '10')),
      sysLangCode: 'en',
    );

    final expectedUserLangs = UserLangs((e) => e
      ..codes.addAll([LangCode.en])
      ..auto = true);
    expect(await userLangsManager.getUserLangs(), equals(expectedUserLangs));
    verifyNever(storage.setUserLangs(any));
  });

  test('first init without lang codes for country', () async {
    await finishSetUp(
      lastPos: const Point<double>(1, 2),
      addressResp: () => Ok(OsmAddress((e) => e.countryCode = 'invalid_code')),
      sysLangCode: 'en',
    );

    final expectedUserLangs = UserLangs((e) => e
      ..codes.addAll([LangCode.en])
      ..auto = true);
    expect(await userLangsManager.getUserLangs(), equals(expectedUserLangs));
    verifyNever(storage.setUserLangs(any));
  });

  test('first init without system lang', () async {
    await finishSetUp(
      lastPos: const Point<double>(1, 2),
      addressResp: () => Ok(OsmAddress((e) => e.countryCode = 'be')),
      sysLangCode: 'invalid_sys_lang',
    );

    final expectedUserLangs = UserLangs((e) => e
      ..codes.addAll([LangCode.nl, LangCode.fr, LangCode.de])
      ..auto = true);
    expect(await userLangsManager.getUserLangs(), equals(expectedUserLangs));
    verify(storage.setUserLangs(expectedUserLangs));
  });

  test('set and get manual user langs', () async {
    await finishSetUp(
      lastPos: const Point<double>(1, 2),
      addressResp: () => Ok(OsmAddress((e) => e.countryCode = 'be')),
      sysLangCode: 'en',
    );

    clearInteractions(storage);

    await userLangsManager.setManualUserLangs({LangCode.ru, LangCode.be});

    final expectedStoredUserLangs = UserLangs((e) => e
      ..codes.addAll([LangCode.ru, LangCode.be])
      ..auto = false);
    verify(storage.setUserLangs(expectedStoredUserLangs));

    final expectedUserLangs = UserLangs((e) => e
      ..codes.addAll([LangCode.en, LangCode.ru, LangCode.be])
      ..auto = false);
    expect(await userLangsManager.getUserLangs(), equals(expectedUserLangs));
  });

  test('system lang is always of highest priority even when storage has it last', () async {
    final existingLangs = UserLangs((e) => e
      ..codes.addAll([LangCode.ru, LangCode.en])
      ..auto = false);
    when(storage.userLangs()).thenAnswer((_) async => existingLangs);

    await finishSetUp(
      lastPos: null,
      addressResp: () => Err(OpenStreetMapError.OTHER),
      sysLangCode: 'en',
    );

    final expectedLangs = UserLangs((e) => e
      ..codes.addAll([LangCode.en, LangCode.ru])
      ..auto = false);

    expect(expectedLangs, equals(isNot(existingLangs)));
    expect(await userLangsManager.getUserLangs(), equals(expectedLangs));
  });

  test('getUserLangs behavior when init was unsuccessful and no system lang available', () async {
    await finishSetUp(
      lastPos: null,
      addressResp: () => Err(OpenStreetMapError.OTHER),
      sysLangCode: 'invalid_sys_lang',
    );

    // EN is the default language used when everything else went wrong
    final expectedUserLangs = UserLangs((e) => e
      ..codes.addAll([LangCode.en])
      ..auto = true);
    expect(await userLangsManager.getUserLangs(), equals(expectedUserLangs));
    verifyNever(storage.setUserLangs(expectedUserLangs));
  });

  test('first init does not finish until user last pos and system lang are available', () async {
    ArgCallback<Point<double>>? initialPosCallback;
    when(locationController.callWhenLastPositionKnown(any)).thenAnswer((invc) {
      initialPosCallback = invc.positionalArguments[0] as ArgCallback<Point<double>>;
    });

    when(osm.fetchAddress(any, any)).thenAnswer(
            (_) async => Ok(OsmAddress((e) => e.countryCode = 'be')));

    userLangsManager = UserLangsManager(
      sysLangCodeHolder,
      countriesLangCodesTable,
      locationController,
      osm,
      FakeSharedPreferences().asHolder(),
      storage: storage,
    );

    var inited = false;
    unawaited(userLangsManager.firstInitFutureForTesting.then((_) => inited = true));
    await Future.delayed(const Duration(milliseconds: 10));
    expect(inited, isFalse);

    const lastPos = Point<double>(1, 2);
    when(locationController.lastKnownPosition()).thenAnswer((_) async => lastPos);
    initialPosCallback!.call(lastPos);
    await Future.delayed(const Duration(milliseconds: 10));
    expect(inited, isFalse);

    sysLangCodeHolder.langCode = 'en';
    await Future.delayed(const Duration(milliseconds: 10));
    expect(inited, isTrue);
  });
}
