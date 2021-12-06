import 'package:geolocator/geolocator.dart';
import 'package:mockito/mockito.dart';
import 'package:plante/base/permissions_manager.dart';
import 'package:plante/location/user_location_manager.dart';
import 'package:plante/model/coord.dart';
import 'package:test/test.dart';

import '../common_mocks.mocks.dart';
import '../z_fakes/fake_shared_preferences.dart';

void main() {
  late MockIpLocationProvider ipLocationProvider;
  late MockPermissionsManager permissionsManager;
  late MockGeolocatorWrapper geolocatorWrapper;
  late FakeSharedPreferences fakeSharedPreferences;

  late UserLocationManager locationManager;

  setUp(() async {
    ipLocationProvider = MockIpLocationProvider();
    permissionsManager = MockPermissionsManager();
    geolocatorWrapper = MockGeolocatorWrapper();
    fakeSharedPreferences = FakeSharedPreferences();

    when(permissionsManager.status(any))
        .thenAnswer((_) async => PermissionState.granted);
  });

  void init() async {
    locationManager = UserLocationManager(ipLocationProvider,
        permissionsManager, fakeSharedPreferences.asHolder(),
        geolocatorWrapper: geolocatorWrapper);
  }

  test('init with current location available', () async {
    final currentPos = Coord(lon: 10, lat: 20);
    when(geolocatorWrapper.getLastKnownPosition())
        .thenAnswer((_) async => null);
    when(geolocatorWrapper.getCurrentPosition())
        .thenAnswer((_) async => currentPos);

    verifyNever(geolocatorWrapper.getCurrentPosition());

    init();
    Coord? receivedPosition;
    locationManager.callWhenLastPositionKnown((position) {
      receivedPosition = position;
    });

    await Future.delayed(const Duration(milliseconds: 10));

    // Current pos is expected to be obtained
    verify(geolocatorWrapper.getCurrentPosition());

    // All other location sources are not expected to be queried
    verifyNever(geolocatorWrapper.getLastKnownPosition());
    expect(fakeSharedPreferences.getCallsCount, equals(0));
    verifyZeroInteractions(ipLocationProvider);

    // The location is expected to be given to the passed callback
    expect(receivedPosition, equals(currentPos));

    // The location is expected to be stored into shared prefs
    expect(fakeSharedPreferences.get(PREF_LAST_KNOWN_POS), isNotNull);
  });

  test('init with last known location when all of above are not available',
      () async {
    final lastKnownPos = Coord(lon: 10, lat: 20);
    when(geolocatorWrapper.getLastKnownPosition())
        .thenAnswer((_) async => lastKnownPos);
    when(geolocatorWrapper.getCurrentPosition()).thenAnswer((_) async => null);

    verifyNever(geolocatorWrapper.getLastKnownPosition());

    init();
    Coord? receivedPosition;
    locationManager.callWhenLastPositionKnown((position) {
      receivedPosition = position;
    });

    await Future.delayed(const Duration(milliseconds: 10));

    // Current pos is expected to be tried
    verify(geolocatorWrapper.getCurrentPosition());
    // Last known pos is expected to be obtained
    verify(geolocatorWrapper.getLastKnownPosition());

    // All other location sources are not expected to be queried
    expect(fakeSharedPreferences.getCallsCount, equals(0));
    verifyZeroInteractions(ipLocationProvider);

    // The location is expected to be given to the passed callback
    expect(receivedPosition, equals(lastKnownPos));

    // The location is expected to be stored into shared prefs
    expect(fakeSharedPreferences.get(PREF_LAST_KNOWN_POS), isNotNull);
  });

  test('init with IP location when all of above are not available', () async {
    when(geolocatorWrapper.getLastKnownPosition())
        .thenAnswer((_) async => null);
    when(geolocatorWrapper.getCurrentPosition()).thenAnswer((_) async => null);

    final ipPos = Coord(lon: 10, lat: 20);
    when(ipLocationProvider.positionByIP()).thenAnswer((_) async => ipPos);

    init();
    Coord? receivedPosition;
    locationManager.callWhenLastPositionKnown((position) {
      receivedPosition = position;
    });

    await Future.delayed(const Duration(milliseconds: 10));

    // Current pos is expected to be tried
    verify(geolocatorWrapper.getCurrentPosition());
    // Last known pos is expected to be tried
    verify(geolocatorWrapper.getLastKnownPosition());
    // IP location is expected to be obtained
    verify(ipLocationProvider.positionByIP());

    // All other location sources are not expected to be queried
    expect(fakeSharedPreferences.getCallsCount, equals(0));

    // The location is expected to be given to the passed callback
    expect(receivedPosition, equals(ipPos));

    // The location is expected to be stored into shared prefs
    expect(fakeSharedPreferences.get(PREF_LAST_KNOWN_POS), isNotNull);
  });

  test('init with prefs location when all of above are not available',
      () async {
    when(geolocatorWrapper.getLastKnownPosition())
        .thenAnswer((_) async => null);
    when(geolocatorWrapper.getCurrentPosition()).thenAnswer((_) async => null);
    when(ipLocationProvider.positionByIP()).thenAnswer((_) async => null);

    final lastKnownPos = Coord(lon: 10, lat: 20);
    await UserLocationManager.updateLastKnownPrefsPositionForTesting(
        lastKnownPos, fakeSharedPreferences.asHolder());

    init();
    Coord? receivedPosition;
    locationManager.callWhenLastPositionKnown((position) {
      receivedPosition = position;
    });

    await Future.delayed(const Duration(milliseconds: 10));

    // Current pos is expected to be tried
    verify(geolocatorWrapper.getCurrentPosition());
    // Last known pos is expected to be tried
    verify(geolocatorWrapper.getLastKnownPosition());
    // IP location is expected to be tried
    verify(ipLocationProvider.positionByIP());
    // Last known Prefs pos is expected to be obtained
    expect(fakeSharedPreferences.getCallsCount, equals(1));

    // The location is expected to be given to the passed callback
    expect(receivedPosition, equals(lastKnownPos));

    // The location is expected to be stored into shared prefs
    expect(fakeSharedPreferences.get(PREF_LAST_KNOWN_POS), isNotNull);
  });

  test('lastKnownPosition good scenario', () async {
    final initialPos = Coord(lon: 10, lat: 10);
    await UserLocationManager.updateLastKnownPrefsPositionForTesting(
        initialPos, fakeSharedPreferences.asHolder());
    when(geolocatorWrapper.getLastKnownPosition())
        .thenAnswer((_) async => null);
    when(geolocatorWrapper.getCurrentPosition()).thenAnswer((_) async => null);
    when(ipLocationProvider.positionByIP()).thenAnswer((_) async => null);
    final initialPref = fakeSharedPreferences.get(PREF_LAST_KNOWN_POS);

    init();
    await Future.delayed(const Duration(milliseconds: 10));

    final newPos = Coord(lon: 10, lat: 20);
    when(geolocatorWrapper.getLastKnownPosition())
        .thenAnswer((_) async => newPos);

    // Expecting the new position to be returned
    final result = await locationManager.lastKnownPosition();
    expect(result, equals(newPos));

    // Expecting the new position to be stored in prefs
    final finalPref = fakeSharedPreferences.get(PREF_LAST_KNOWN_POS);
    expect(finalPref, isNot(equals(initialPref)));
  });

  test('lastKnownPosition can work without permission', () async {
    final initialPos = Coord(lon: 10, lat: 10);
    await UserLocationManager.updateLastKnownPrefsPositionForTesting(
        initialPos, fakeSharedPreferences.asHolder());
    when(geolocatorWrapper.getLastKnownPosition())
        .thenAnswer((_) async => null);
    when(geolocatorWrapper.getCurrentPosition()).thenAnswer((_) async => null);
    when(ipLocationProvider.positionByIP()).thenAnswer((_) async => null);
    final initialPref = fakeSharedPreferences.get(PREF_LAST_KNOWN_POS);

    when(permissionsManager.status(any))
        .thenAnswer((_) async => PermissionState.denied);

    init();
    await Future.delayed(const Duration(milliseconds: 10));

    // Expecting the initial position to be returned
    final result = await locationManager.lastKnownPosition();
    expect(result, equals(initialPos));

    // Expecting the initial position to still be stored in prefs
    final finalPref = fakeSharedPreferences.get(PREF_LAST_KNOWN_POS);
    expect(finalPref, equals(initialPref));
  });

  test('lastKnownPosition on exception', () async {
    final initialPos = Coord(lon: 10, lat: 10);
    await UserLocationManager.updateLastKnownPrefsPositionForTesting(
        initialPos, fakeSharedPreferences.asHolder());
    when(geolocatorWrapper.getLastKnownPosition())
        .thenAnswer((_) async => null);
    when(geolocatorWrapper.getCurrentPosition()).thenAnswer((_) async => null);
    when(ipLocationProvider.positionByIP()).thenAnswer((_) async => null);
    final initialPref = fakeSharedPreferences.get(PREF_LAST_KNOWN_POS);

    init();
    await Future.delayed(const Duration(milliseconds: 10));

    when(geolocatorWrapper.getLastKnownPosition())
        .thenAnswer((_) async => throw const PermissionDeniedException(''));

    // Expecting the initial position to be returned
    final result = await locationManager.lastKnownPosition();
    expect(result, equals(initialPos));

    // Expecting the initial position to still be stored in prefs
    final finalPref = fakeSharedPreferences.get(PREF_LAST_KNOWN_POS);
    expect(finalPref, equals(initialPref));
  });

  test('currentPosition good scenario', () async {
    final initialPos = Coord(lon: 10, lat: 10);
    await UserLocationManager.updateLastKnownPrefsPositionForTesting(
        initialPos, fakeSharedPreferences.asHolder());
    when(geolocatorWrapper.getLastKnownPosition())
        .thenAnswer((_) async => null);
    when(geolocatorWrapper.getCurrentPosition()).thenAnswer((_) async => null);
    when(ipLocationProvider.positionByIP()).thenAnswer((_) async => null);
    final initialPref = fakeSharedPreferences.get(PREF_LAST_KNOWN_POS);

    init();
    await Future.delayed(const Duration(milliseconds: 10));

    final newPos = Coord(lon: 10, lat: 20);
    when(geolocatorWrapper.getCurrentPosition())
        .thenAnswer((_) async => newPos);

    // Expecting the new position to be returned
    final result = await locationManager.currentPosition();
    expect(result, equals(newPos));

    // Expecting the new position to be stored in prefs
    final finalPref = fakeSharedPreferences.get(PREF_LAST_KNOWN_POS);
    expect(finalPref, isNot(equals(initialPref)));
  });

  test('currentPosition cannot work without permission', () async {
    final initialPos = Coord(lon: 10, lat: 10);
    await UserLocationManager.updateLastKnownPrefsPositionForTesting(
        initialPos, fakeSharedPreferences.asHolder());
    when(geolocatorWrapper.getLastKnownPosition())
        .thenAnswer((_) async => null);
    when(geolocatorWrapper.getCurrentPosition()).thenAnswer((_) async => null);
    when(ipLocationProvider.positionByIP()).thenAnswer((_) async => null);
    final initialPref = fakeSharedPreferences.get(PREF_LAST_KNOWN_POS);

    when(permissionsManager.status(any))
        .thenAnswer((_) async => PermissionState.denied);

    init();
    await Future.delayed(const Duration(milliseconds: 10));

    // Expecting null to be returned even though there's the initial position
    final result = await locationManager.currentPosition();
    expect(result, isNull);

    // Expecting the initial position to still be stored in prefs
    final finalPref = fakeSharedPreferences.get(PREF_LAST_KNOWN_POS);
    expect(finalPref, equals(initialPref));
  });

  test('currentPosition on exception', () async {
    final initialPos = Coord(lon: 10, lat: 10);
    await UserLocationManager.updateLastKnownPrefsPositionForTesting(
        initialPos, fakeSharedPreferences.asHolder());
    when(geolocatorWrapper.getLastKnownPosition())
        .thenAnswer((_) async => null);
    when(geolocatorWrapper.getCurrentPosition()).thenAnswer((_) async => null);
    when(ipLocationProvider.positionByIP()).thenAnswer((_) async => null);
    final initialPref = fakeSharedPreferences.get(PREF_LAST_KNOWN_POS);

    init();
    await Future.delayed(const Duration(milliseconds: 10));

    when(geolocatorWrapper.getCurrentPosition())
        .thenAnswer((_) async => throw const PermissionDeniedException(''));

    // Expecting null to be returned even though there's the initial position
    final result = await locationManager.currentPosition();
    expect(result, isNull);

    // Expecting the initial position to still be stored in prefs
    final finalPref = fakeSharedPreferences.get(PREF_LAST_KNOWN_POS);
    expect(finalPref, equals(initialPref));
  });

  test(
      'callWhenLastPositionKnown gives position right away if the controller is initialized',
      () async {
    final currentPos = Coord(lon: 10, lat: 20);
    when(geolocatorWrapper.getLastKnownPosition())
        .thenAnswer((_) async => null);
    when(geolocatorWrapper.getCurrentPosition())
        .thenAnswer((_) async => currentPos);

    verifyNever(geolocatorWrapper.getCurrentPosition());

    init();
    await Future.delayed(const Duration(milliseconds: 10));

    Coord? receivedPosition;
    locationManager.callWhenLastPositionKnown((position) {
      receivedPosition = position;
    });
    expect(receivedPosition, equals(currentPos));
  });
}
