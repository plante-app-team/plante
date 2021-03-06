import 'dart:io';

import 'package:device_info/device_info.dart';
import 'package:plante/logging/log.dart';

class DeviceInfo {
  final String deviceID;
  final String deviceName;
  final String deviceVersion;
  DeviceInfo(this.deviceID, this.deviceName, this.deviceVersion);

  static Future<DeviceInfo> get() async {
    final deviceInfoPlugin = DeviceInfoPlugin();
    if (Platform.isAndroid) {
      final build = await deviceInfoPlugin.androidInfo;
      return DeviceInfo(build.androidId, build.model, build.version.toString());
    } else if (Platform.isIOS) {
      final data = await deviceInfoPlugin.iosInfo;
      return DeviceInfo(
          data.identifierForVendor, data.name, data.systemVersion);
    } else {
      Log.w('DeviceInfo: platform not supported');
      return DeviceInfo('not supported', 'not supported', 'not supported');
    }
  }
}
