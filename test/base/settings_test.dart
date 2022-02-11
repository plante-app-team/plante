import 'package:plante/base/settings.dart';
import 'package:test/test.dart';

import '../z_fakes/fake_shared_preferences.dart';

void main() {
  late FakeSharedPreferences prefs;
  late Settings settings;

  setUp(() async {
    prefs = FakeSharedPreferences();
    settings = Settings(prefs.asHolder());
  });

  test('observers are notified', () async {
    final observer = _SettingsObserver();
    settings.addObserver(observer);

    expect(observer.notificationsCount, equals(0));

    await settings
        .setEnableNewestFeatures(!(await settings.enableNewestFeatures()));
    expect(observer.notificationsCount, equals(1));

    await settings
        .setDistanceInMiles(!(await settings.distanceInMiles() ?? false));
    expect(observer.notificationsCount, equals(2));

    await settings.setEnableRadiusProductsSuggestions(
        !(await settings.enableRadiusProductsSuggestions()));
    expect(observer.notificationsCount, equals(3));

    await settings.setEnableOFFProductsSuggestions(
        !(await settings.enableOFFProductsSuggestions()));
    expect(observer.notificationsCount, equals(4));
  });

  test('"distance in miles" setting caches its value for quick access',
      () async {
    expect(prefs.getCallsCount, equals(0));

    // First get should cache value
    expect(await settings.distanceInMiles(), isNull);
    expect(prefs.getCallsCount, equals(1));
    expect(await settings.distanceInMiles(), isNull);
    expect(prefs.getCallsCount, equals(1));

    // Even when the value is changed, prefs are expected
    // to be modified, not queried
    await settings.setDistanceInMiles(true);
    expect(await settings.distanceInMiles(), isTrue);
    expect(prefs.getCallsCount, equals(1));
    await settings.setDistanceInMiles(false);
    expect(await settings.distanceInMiles(), isFalse);
    expect(prefs.getCallsCount, equals(1));

    // New Settings instance without cache!
    settings = Settings(prefs.asHolder());

    // We expect the persistent value to keep being the same
    expect(await settings.distanceInMiles(), isFalse);
    // And we expect the preferences to be queried
    expect(prefs.getCallsCount, equals(2));
    // ...but preferences should be queried only once
    expect(await settings.distanceInMiles(), isFalse);
    expect(prefs.getCallsCount, equals(2));
  });
}

class _SettingsObserver implements SettingsObserver {
  var notificationsCount = 0;
  @override
  void onSettingsChange() => notificationsCount += 1;
}
