import 'dart:async';

import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:plante/base/base.dart';
import 'package:plante/base/result.dart';
import 'package:plante/lang/location_based_user_langs_manager.dart';
import 'package:plante/lang/manual_user_langs_manager.dart';
import 'package:plante/lang/sys_lang_code_holder.dart';
import 'package:plante/lang/user_langs_manager.dart';
import 'package:plante/lang/user_langs_manager_error.dart';
import 'package:plante/model/lang_code.dart';
import 'package:plante/model/user_langs.dart';
import 'package:test/test.dart';
import 'package:trotter/trotter.dart';

import '../common_mocks.mocks.dart';
import 'user_langs_manager_test.mocks.dart';

@GenerateMocks([LocationBasedUserLangsManager, ManualUserLangsManager])
void main() {
  late MockLocationBasedUserLangsManager locationBasedUserLangsManager;
  late MockManualUserLangsManager manualUserLangsManager;
  late SysLangCodeHolder sysLangCodeHolder;
  late UserLangsManager userLangsManager;

  setUp(() async {
    locationBasedUserLangsManager = MockLocationBasedUserLangsManager();
    manualUserLangsManager = MockManualUserLangsManager();
    sysLangCodeHolder = SysLangCodeHolder();
  });

  Future<void> finishSetUp({
    required List<LangCode>? locationBasedLangs,
    required List<LangCode>? manualLangs,
    required String sysLangStr,
  }) async {
    when(locationBasedUserLangsManager.getUserLangs())
        .thenAnswer((_) async => locationBasedLangs);
    when(locationBasedUserLangsManager.initFuture)
        .thenAnswer((_) => Future.value());

    when(manualUserLangsManager.getUserLangs())
        .thenAnswer((_) async => manualLangs);
    when(manualUserLangsManager.initFuture).thenAnswer((_) => Future.value());

    sysLangCodeHolder.langCode = sysLangStr;

    userLangsManager = UserLangsManager.forTests(sysLangCodeHolder,
        locationBasedUserLangsManager, manualUserLangsManager);
    await userLangsManager.initFuture;
  }

  test('perfect scenario', () async {
    await finishSetUp(
      locationBasedLangs: [LangCode.en, LangCode.nl],
      manualLangs: [LangCode.en, LangCode.nl],
      sysLangStr: LangCode.en.name,
    );

    final expectedStoredUserLangs = UserLangs((e) => e
      ..langs.addAll([LangCode.en, LangCode.nl])
      ..sysLang = LangCode.en
      ..auto = false);
    expect(
        await userLangsManager.getUserLangs(), equals(expectedStoredUserLangs));
  });

  test('manual and location-based langs differ', () async {
    await finishSetUp(
      locationBasedLangs: [LangCode.en, LangCode.nl],
      manualLangs: [LangCode.en, LangCode.ru],
      sysLangStr: LangCode.en.name,
    );

    final expectedStoredUserLangs = UserLangs((e) => e
      ..langs.addAll([LangCode.en, LangCode.ru])
      ..sysLang = LangCode.en
      ..auto = false);
    expect(
        await userLangsManager.getUserLangs(), equals(expectedStoredUserLangs));
  });

  test('system lang is differs from others', () async {
    await finishSetUp(
      locationBasedLangs: [LangCode.en, LangCode.nl],
      manualLangs: [LangCode.en, LangCode.nl],
      sysLangStr: LangCode.be.name,
    );

    final expectedStoredUserLangs = UserLangs((e) => e
      ..langs.addAll([LangCode.be, LangCode.en, LangCode.nl])
      ..sysLang = LangCode.be
      ..auto = false);
    expect(
        await userLangsManager.getUserLangs(), equals(expectedStoredUserLangs));
  });

  test('system lang is invalid', () async {
    await finishSetUp(
      locationBasedLangs: [LangCode.en, LangCode.nl],
      manualLangs: [LangCode.en, LangCode.nl],
      sysLangStr: 'invalid lang code',
    );

    final expectedStoredUserLangs = UserLangs((e) => e
      ..langs.addAll([LangCode.en, LangCode.nl])
      ..sysLang = null
      ..auto = false);
    expect(
        await userLangsManager.getUserLangs(), equals(expectedStoredUserLangs));
  });

  test('no location-based langs', () async {
    await finishSetUp(
      locationBasedLangs: null,
      manualLangs: [LangCode.en, LangCode.nl],
      sysLangStr: LangCode.en.name,
    );

    final expectedStoredUserLangs = UserLangs((e) => e
      ..langs.addAll([LangCode.en, LangCode.nl])
      ..sysLang = LangCode.en
      ..auto = false);
    expect(
        await userLangsManager.getUserLangs(), equals(expectedStoredUserLangs));
  });

  test('no manual langs', () async {
    await finishSetUp(
      locationBasedLangs: [LangCode.en, LangCode.nl],
      manualLangs: null,
      sysLangStr: LangCode.en.name,
    );

    final expectedStoredUserLangs = UserLangs((e) => e
      ..langs.addAll([LangCode.en, LangCode.nl])
      ..sysLang = LangCode.en
      ..auto = false);
    expect(
        await userLangsManager.getUserLangs(), equals(expectedStoredUserLangs));
  });

  test('no location-based and manual langs', () async {
    await finishSetUp(
      locationBasedLangs: null,
      manualLangs: null,
      sysLangStr: LangCode.en.name,
    );

    final expectedStoredUserLangs = UserLangs((e) => e
      ..langs.addAll([LangCode.en])
      ..sysLang = LangCode.en
      ..auto = false);
    expect(
        await userLangsManager.getUserLangs(), equals(expectedStoredUserLangs));
  });

  test('no valid langs available', () async {
    await finishSetUp(
      locationBasedLangs: null,
      manualLangs: null,
      sysLangStr: 'invalid lang',
    );

    // English is the default lang
    final expectedStoredUserLangs = UserLangs((e) => e
      ..langs.addAll([LangCode.en])
      ..sysLang = null
      ..auto = false);
    expect(
        await userLangsManager.getUserLangs(), equals(expectedStoredUserLangs));
  });

  test('init does not finish until all lang sources are available', () async {
    late Completer<List<LangCode>> locationBasedLangs;
    late Completer<List<LangCode>> manualLangs;

    final clearState = () {
      sysLangCodeHolder = SysLangCodeHolder();

      locationBasedLangs = Completer<List<LangCode>>();
      when(locationBasedUserLangsManager.getUserLangs())
          .thenAnswer((_) => locationBasedLangs.future);
      when(locationBasedUserLangsManager.initFuture)
          .thenAnswer((_) => locationBasedLangs.future);

      manualLangs = Completer<List<LangCode>>();
      when(manualUserLangsManager.getUserLangs())
          .thenAnswer((_) => manualLangs.future);
      when(manualUserLangsManager.initFuture)
          .thenAnswer((_) => manualLangs.future);

      userLangsManager = UserLangsManager.forTests(sysLangCodeHolder,
          locationBasedUserLangsManager, manualUserLangsManager);
    };

    final locationBasedLangsInitFinish = () {
      locationBasedLangs.complete([LangCode.en]);
    };
    final manualLangsInitFinish = () {
      manualLangs.complete([LangCode.en]);
    };
    final sysLangInitFinish = () {
      sysLangCodeHolder.langCode = 'en';
    };

    final initializers = [
      locationBasedLangsInitFinish,
      manualLangsInitFinish,
      sysLangInitFinish
    ];
    final initializersCombos = Combinations(initializers.length, initializers);
    for (final combo in initializersCombos()) {
      clearState.call();
      var inited = false;
      unawaited(userLangsManager.getUserLangs().then((_) => inited = true));

      for (var index = 0; index < combo.length - 1; ++index) {
        combo[index].call();
        await Future.delayed(const Duration(milliseconds: 10));
      }
      expect(inited, isFalse);

      combo.last.call();
      await Future.delayed(const Duration(milliseconds: 10));
      expect(inited, isTrue);
    }
  });

  test('set and get manual user langs', () async {
    await finishSetUp(
      locationBasedLangs: [LangCode.en, LangCode.nl],
      manualLangs: [LangCode.en, LangCode.nl],
      sysLangStr: LangCode.en.name,
    );

    when(manualUserLangsManager.setUserLangs(any)).thenAnswer((invc) async {
      final langs = invc.positionalArguments[0] as List<LangCode>;
      when(manualUserLangsManager.getUserLangs())
          .thenAnswer((_) async => langs);
      return Ok(None());
    });
    when(manualUserLangsManager.initFuture).thenAnswer((_) => Future.value());

    await userLangsManager.setManualUserLangs([LangCode.ru, LangCode.be]);
    final expectedStoredUserLangs = UserLangs((e) => e
      ..langs.addAll([LangCode.en, LangCode.ru, LangCode.be])
      ..sysLang = LangCode.en
      ..auto = false);
    expect(
        await userLangsManager.getUserLangs(), equals(expectedStoredUserLangs));
  });

  test('system lang will have manual position when present there', () async {
    await finishSetUp(
      locationBasedLangs: null,
      manualLangs: [LangCode.nl, LangCode.en],
      sysLangStr: LangCode.en.name,
    );

    final expectedStoredUserLangs = UserLangs((e) => e
      ..langs.addAll([LangCode.nl, LangCode.en])
      ..sysLang = LangCode.en
      ..auto = false);
    expect(
        await userLangsManager.getUserLangs(), equals(expectedStoredUserLangs));
  });

  test('system lang will have location-based position when present there',
      () async {
    await finishSetUp(
      locationBasedLangs: [LangCode.nl, LangCode.en],
      manualLangs: null,
      sysLangStr: LangCode.en.name,
    );

    final expectedStoredUserLangs = UserLangs((e) => e
      ..langs.addAll([LangCode.nl, LangCode.en])
      ..sysLang = LangCode.en
      ..auto = false);
    expect(
        await userLangsManager.getUserLangs(), equals(expectedStoredUserLangs));
  });

  test('observer user langs change notifications', () async {
    await finishSetUp(
      locationBasedLangs: [LangCode.en, LangCode.nl],
      manualLangs: [LangCode.en, LangCode.nl],
      sysLangStr: LangCode.en.name,
    );

    final observer = MockUserLangsManagerObserver();
    userLangsManager.addObserver(observer);
    verifyZeroInteractions(observer);

    // Ok scenario
    when(manualUserLangsManager.setUserLangs(any)).thenAnswer((invc) async {
      final langs = invc.positionalArguments[0] as List<LangCode>;
      when(manualUserLangsManager.getUserLangs())
          .thenAnswer((_) async => langs);
      return Ok(None());
    });
    await userLangsManager.setManualUserLangs([LangCode.en, LangCode.be]);
    verify(observer.onUserLangsChange(UserLangs((e) => e
      ..langs.addAll([LangCode.en, LangCode.be])
      ..sysLang = LangCode.en
      ..auto = false)));

    clearInteractions(observer);

    // Error scenario
    when(manualUserLangsManager.setUserLangs(any)).thenAnswer((invc) async {
      return Err(UserLangsManagerError.NETWORK);
    });
    await userLangsManager.setManualUserLangs([LangCode.de, LangCode.en]);
    verifyZeroInteractions(observer);
  });
}
