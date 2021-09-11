import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:plante/base/base.dart';
import 'package:plante/base/result.dart';
import 'package:plante/lang/location_based_user_langs_manager.dart';
import 'package:plante/lang/location_based_user_langs_storage.dart';
import 'package:plante/lang/countries_lang_codes_table.dart';
import 'package:plante/model/coord.dart';
import 'package:plante/model/lang_code.dart';
import 'package:plante/outside/map/open_street_map.dart';
import 'package:plante/outside/map/osm_address.dart';
import 'package:test/test.dart';

import '../common_mocks.mocks.dart';
import '../z_fakes/fake_analytics.dart';
import '../z_fakes/fake_shared_preferences.dart';
import 'location_based_user_langs_manager_test.mocks.dart';

@GenerateMocks([LocationBasedUserLangsStorage])
void main() {
  late CountriesLangCodesTable countriesLangCodesTable;
  late MockLocationController locationController;
  late MockAddressObtainer addressObtainer;
  late MockLocationBasedUserLangsStorage storage;
  late FakeAnalytics analytics;
  late LocationBasedUserLangsManager userLangsManager;

  setUp(() async {
    analytics = FakeAnalytics();
    countriesLangCodesTable = CountriesLangCodesTable(analytics);
    locationController = MockLocationController();
    addressObtainer = MockAddressObtainer();
    storage = MockLocationBasedUserLangsStorage();

    when(storage.userLangs()).thenAnswer((_) async => null);
    when(storage.setUserLangs(any)).thenAnswer((invc) async {
      final userLangs = invc.positionalArguments[0] as List<LangCode>;
      when(storage.userLangs()).thenAnswer((_) async => userLangs);
    });
  });

  Future<void> finishSetUp({
    required Coord? lastPos,
    required ResCallback<Result<OsmAddress, OpenStreetMapError>> addressResp,
  }) async {
    final initialLastPos = Coord(lat: 0, lon: 0);
    when(locationController.callWhenLastPositionKnown(any)).thenAnswer((invc) {
      final callback = invc.positionalArguments[0] as ArgCallback<Coord>;
      callback.call(initialLastPos);
    });

    when(locationController.lastKnownPosition())
        .thenAnswer((_) async => lastPos);
    when(addressObtainer.addressOfCoords(any))
        .thenAnswer((_) async => addressResp.call());

    userLangsManager = LocationBasedUserLangsManager(
      countriesLangCodesTable,
      locationController,
      addressObtainer,
      analytics,
      FakeSharedPreferences().asHolder(),
      storage: storage,
    );
    await userLangsManager.initFuture;
  }

  test('init with existing user langs', () async {
    final existingLangs = [LangCode.en];
    when(storage.userLangs()).thenAnswer((_) async => existingLangs);

    await finishSetUp(
      lastPos: null,
      addressResp: () => Err(OpenStreetMapError.OTHER),
    );

    expect(await userLangsManager.getUserLangs(), equals(existingLangs));
    verifyNever(storage.setUserLangs(any));
  });

  test('first init good scenario', () async {
    await finishSetUp(
      lastPos: Coord(lat: 2, lon: 1),
      addressResp: () => Ok(OsmAddress((e) => e.countryCode = 'be')),
    );

    final expectedUserLangs = [LangCode.nl, LangCode.fr, LangCode.de];
    expect(await userLangsManager.getUserLangs(), equals(expectedUserLangs));
    verify(storage.setUserLangs(expectedUserLangs));
  });

  test('first init without last known pos', () async {
    await finishSetUp(
      lastPos: null,
      addressResp: () => Ok(OsmAddress((e) => e.countryCode = 'be')),
    );

    expect(await userLangsManager.getUserLangs(), isNull);
    verifyNever(storage.setUserLangs(any));
  });

  test('first init without osm address (on osm error)', () async {
    await finishSetUp(
      lastPos: Coord(lat: 2, lon: 1),
      addressResp: () => Err(OpenStreetMapError.OTHER),
    );

    expect(await userLangsManager.getUserLangs(), isNull);
    verifyNever(storage.setUserLangs(any));
  });

  test('first init without osm country', () async {
    await finishSetUp(
      lastPos: Coord(lat: 2, lon: 1),
      addressResp: () => Ok(OsmAddress((e) => e.houseNumber = '10')),
    );

    expect(await userLangsManager.getUserLangs(), isNull);
    verifyNever(storage.setUserLangs(any));
  });

  test('first init without lang codes for country', () async {
    await finishSetUp(
      lastPos: Coord(lat: 2, lon: 1),
      addressResp: () => Ok(OsmAddress((e) => e.countryCode = 'invalid_code')),
    );

    expect(await userLangsManager.getUserLangs(), isNull);
    verifyNever(storage.setUserLangs(any));
  });

  test('first init does not finish until user last pos is available', () async {
    ArgCallback<Coord>? initialPosCallback;
    when(locationController.callWhenLastPositionKnown(any)).thenAnswer((invc) {
      initialPosCallback = invc.positionalArguments[0] as ArgCallback<Coord>;
    });

    when(addressObtainer.addressOfCoords(any))
        .thenAnswer((_) async => Ok(OsmAddress((e) => e.countryCode = 'be')));

    userLangsManager = LocationBasedUserLangsManager(
      countriesLangCodesTable,
      locationController,
      addressObtainer,
      FakeAnalytics(),
      FakeSharedPreferences().asHolder(),
      storage: storage,
    );

    var inited = false;
    unawaited(userLangsManager.initFuture.then((_) => inited = true));
    await Future.delayed(const Duration(milliseconds: 10));
    expect(inited, isFalse);

    final lastPos = Coord(lat: 2, lon: 1);
    when(locationController.lastKnownPosition())
        .thenAnswer((_) async => lastPos);
    initialPosCallback!.call(lastPos);
    await Future.delayed(const Duration(milliseconds: 10));
    expect(inited, isTrue);
  });

  test('analytics single-lang country', () async {
    expect(analytics.allEvents(), isEmpty);

    await finishSetUp(
      lastPos: Coord(lat: 2, lon: 1),
      addressResp: () => Ok(OsmAddress((e) => e.countryCode = 'ru')),
    );

    expect(analytics.wasEventSent('single_lang_country'), isTrue);
    expect(analytics.wasEventSent('multi_lang_country'), isFalse);
  });

  test('analytics multilingual country', () async {
    expect(analytics.allEvents(), isEmpty);

    await finishSetUp(
      lastPos: Coord(lat: 2, lon: 1),
      addressResp: () => Ok(OsmAddress((e) => e.countryCode = 'be')),
    );

    expect(analytics.wasEventSent('single_lang_country'), isFalse);
    expect(analytics.wasEventSent('multi_lang_country'), isTrue);
  });
}
