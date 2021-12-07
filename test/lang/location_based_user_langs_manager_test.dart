import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:plante/base/base.dart';
import 'package:plante/lang/countries_lang_codes_table.dart';
import 'package:plante/lang/location_based_user_langs_manager.dart';
import 'package:plante/lang/location_based_user_langs_storage.dart';
import 'package:plante/model/coord.dart';
import 'package:plante/model/country_code.dart';
import 'package:plante/model/lang_code.dart';
import 'package:plante/outside/map/user_address/user_address_piece.dart';
import 'package:plante/outside/map/user_address/user_address_type.dart';
import 'package:test/test.dart';

import '../common_mocks.mocks.dart';
import '../z_fakes/fake_analytics.dart';
import '../z_fakes/fake_caching_user_address_pieces_obtainer.dart';
import '../z_fakes/fake_shared_preferences.dart';
import 'location_based_user_langs_manager_test.mocks.dart';

@GenerateMocks([LocationBasedUserLangsStorage])
void main() {
  late CountriesLangCodesTable countriesLangCodesTable;
  late MockUserLocationManager userLocationManager;
  late FakeCachingUserAddressPiecesObtainer addressObtainer;
  late MockLocationBasedUserLangsStorage storage;
  late FakeAnalytics analytics;
  late LocationBasedUserLangsManager userLangsManager;

  setUp(() async {
    analytics = FakeAnalytics();
    countriesLangCodesTable = CountriesLangCodesTable(analytics);
    userLocationManager = MockUserLocationManager();
    addressObtainer = FakeCachingUserAddressPiecesObtainer();
    storage = MockLocationBasedUserLangsStorage();

    when(storage.userLangs()).thenAnswer((_) async => null);
    when(storage.setUserLangs(any)).thenAnswer((invc) async {
      final userLangs = invc.positionalArguments[0] as List<LangCode>;
      when(storage.userLangs()).thenAnswer((_) async => userLangs);
    });
  });

  Future<void> finishSetUp({
    required Coord? lastPos,
    required String? countryCode,
    bool withInitialLastPos = true,
    Duration? initWaitTimeout,
  }) async {
    if (withInitialLastPos) {
      final initialLastPos = Coord(lat: 0, lon: 0);
      when(userLocationManager.callWhenLastPositionKnown(any))
          .thenAnswer((invc) {
        final callback = invc.positionalArguments[0] as ArgCallback<Coord>;
        callback.call(initialLastPos);
      });
    } else {
      when(userLocationManager.callWhenLastPositionKnown(any)).thenAnswer((_) {
        // Nothing
      });
    }

    when(userLocationManager.lastKnownPosition())
        .thenAnswer((_) async => lastPos);
    addressObtainer.setResultFor(UserAddressType.USER_LOCATION,
        UserAddressPiece.COUNTRY_CODE, countryCode);

    userLangsManager = LocationBasedUserLangsManager(
      countriesLangCodesTable,
      userLocationManager,
      analytics,
      addressObtainer,
      FakeSharedPreferences().asHolder(),
      storage: storage,
    );
    if (initWaitTimeout != null) {
      await userLangsManager.initFuture
          .timeout(initWaitTimeout, onTimeout: () {});
    } else {
      await userLangsManager.initFuture;
    }
  }

  test('init with existing user langs', () async {
    final existingLangs = [LangCode.en];
    when(storage.userLangs()).thenAnswer((_) async => existingLangs);

    await finishSetUp(
      lastPos: null,
      countryCode: null,
    );

    expect(await userLangsManager.getUserLangs(), equals(existingLangs));
    verifyNever(storage.setUserLangs(any));
  });

  test('first init good scenario', () async {
    await finishSetUp(
      lastPos: Coord(lat: 2, lon: 1),
      countryCode: CountryCode.BELGIUM,
    );

    final expectedUserLangs = [LangCode.nl, LangCode.fr, LangCode.de];
    expect(await userLangsManager.getUserLangs(), equals(expectedUserLangs));
    verify(storage.setUserLangs(expectedUserLangs));
  });

  test('first init without last known pos', () async {
    await finishSetUp(
      withInitialLastPos: false,
      initWaitTimeout: const Duration(milliseconds: 250),
      lastPos: null,
      countryCode: CountryCode.BELGIUM,
    );

    expect(await userLangsManager.getUserLangs(), isNull);
    verifyNever(storage.setUserLangs(any));
  });

  test('first init without country code', () async {
    await finishSetUp(
      lastPos: Coord(lat: 2, lon: 1),
      countryCode: null,
    );

    expect(await userLangsManager.getUserLangs(), isNull);
    verifyNever(storage.setUserLangs(any));
  });

  test('first init without lang codes for country', () async {
    await finishSetUp(
      lastPos: Coord(lat: 2, lon: 1),
      countryCode: 'invalid_code',
    );

    expect(await userLangsManager.getUserLangs(), isNull);
    verifyNever(storage.setUserLangs(any));
  });

  test('first init does not finish until user last pos is available', () async {
    ArgCallback<Coord>? initialPosCallback;
    when(userLocationManager.callWhenLastPositionKnown(any)).thenAnswer((invc) {
      initialPosCallback = invc.positionalArguments[0] as ArgCallback<Coord>;
    });

    addressObtainer.setResultFor(UserAddressType.USER_LOCATION,
        UserAddressPiece.COUNTRY_CODE, CountryCode.BELGIUM);

    userLangsManager = LocationBasedUserLangsManager(
      countriesLangCodesTable,
      userLocationManager,
      FakeAnalytics(),
      addressObtainer,
      FakeSharedPreferences().asHolder(),
      storage: storage,
    );

    var inited = false;
    unawaited(userLangsManager.initFuture.then((_) => inited = true));
    await Future.delayed(const Duration(milliseconds: 10));
    expect(inited, isFalse);

    final lastPos = Coord(lat: 2, lon: 1);
    when(userLocationManager.lastKnownPosition())
        .thenAnswer((_) async => lastPos);
    initialPosCallback!.call(lastPos);
    await Future.delayed(const Duration(milliseconds: 10));
    expect(inited, isTrue);
  });

  test('analytics single-lang country', () async {
    expect(analytics.allEvents(), isEmpty);

    await finishSetUp(
      lastPos: Coord(lat: 2, lon: 1),
      countryCode: CountryCode.RUSSIA,
    );

    expect(analytics.wasEventSent('single_lang_country'), isTrue);
    expect(analytics.wasEventSent('multi_lang_country'), isFalse);
  });

  test('analytics multilingual country', () async {
    expect(analytics.allEvents(), isEmpty);

    await finishSetUp(
      lastPos: Coord(lat: 2, lon: 1),
      countryCode: CountryCode.BELGIUM,
    );

    expect(analytics.wasEventSent('single_lang_country'), isFalse);
    expect(analytics.wasEventSent('multi_lang_country'), isTrue);
  });
}
