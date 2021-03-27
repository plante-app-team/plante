import 'dart:io';

import 'package:device_info/device_info.dart';
import 'package:flutter/services.dart';

class DeviceInfo {
  final String deviceID;
  final String deviceName;
  final String deviceVersion;
  DeviceInfo(this.deviceID, this.deviceName, this.deviceVersion);

  static Future<DeviceInfo> get() async {
    final deviceInfoPlugin = DeviceInfoPlugin();
    if (Platform.isAndroid) {
      var build = await deviceInfoPlugin.androidInfo;
      return DeviceInfo(
          build.androidId, build.model, build.version.toString());
    } else if (Platform.isIOS) {
      var data = await deviceInfoPlugin.iosInfo;
      return DeviceInfo(
          data.identifierForVendor, data.name, data.systemVersion);
    } else {
      // TODO(https://trello.com/c/XWAE5UVB/): log warning
      return DeviceInfo("not supported", "not supported", "not supported");
    }
  }
}
