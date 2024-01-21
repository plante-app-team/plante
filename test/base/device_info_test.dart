
import 'package:plante/base/device_info.dart';
import 'package:test/test.dart';

import '../z_fakes/fake_shared_preferences.dart';

void main() {
  late FakeSharedPreferences prefs;
  late DeviceInfoProvider deviceInfoProvider;

  setUp(() async {
    prefs = FakeSharedPreferences();
    deviceInfoProvider = DeviceInfoProvider(prefs.asHolder());
  });

  test('device ID is stable', () async {
    var deviceInfo = await deviceInfoProvider.get();
    final deviceId1 = deviceInfo.deviceID;
    deviceInfo = await deviceInfoProvider.get();
    final deviceId2 = deviceInfo.deviceID;
    expect(deviceId1, equals(deviceId2));
  });

  test('device ID is stable among multiple instances', () async {
    var deviceInfo = await deviceInfoProvider.get();
    final deviceId1 = deviceInfo.deviceID;

    deviceInfoProvider = DeviceInfoProvider(prefs.asHolder());
    deviceInfo = await deviceInfoProvider.get();
    final deviceId2 = deviceInfo.deviceID;
    expect(deviceId1, equals(deviceId2));
  });
}
