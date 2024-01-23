import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:plante/logging/log.dart';
import 'package:plante/model/shared_preferences_holder.dart';
import 'package:uuid/uuid.dart';

class DeviceInfoProvider {
  static const PREF_DEVICE_ID = 'DEVICE_INFO_PROVIDER_DEVICE_ID';
  final SharedPreferencesHolder _prefs;
  final _uuid = const Uuid();

  DeviceInfoProvider(this._prefs);

  Future<DeviceInfo> get() async {
    final deviceInfoPlugin = DeviceInfoPlugin();
    final deviceId = await _getDeviceID();
    if (Platform.isAndroid) {
      final build = await deviceInfoPlugin.androidInfo;
      return DeviceInfo(deviceId, build.model, build.version.toString());
    } else if (Platform.isIOS) {
      final data = await deviceInfoPlugin.iosInfo;
      return DeviceInfo(deviceId, data.name, data.systemVersion);
    } else {
      Log.w('DeviceInfo: platform not supported');
      return DeviceInfo('not supported', 'not supported', 'not supported');
    }
  }

  Future<String> _getDeviceID() async {
    final prefs = await _prefs.get();
    var deviceId = prefs.getString(PREF_DEVICE_ID);
    if (deviceId == null) {
      deviceId = _uuid.v4().toString();
      await prefs.setString(PREF_DEVICE_ID, deviceId);
    }
    return deviceId;
  }
}

class DeviceInfo {
  final String deviceID;
  final String deviceName;
  final String deviceVersion;
  DeviceInfo(this.deviceID, this.deviceName, this.deviceVersion);
}
