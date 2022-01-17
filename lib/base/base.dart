import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get_it/get_it.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:plante/base/settings.dart';
import 'package:plante/lang/sys_lang_code_holder.dart';
import 'package:plante/logging/log.dart';

const _PRIVACY_POLICY_URL_RU =
    'https://docs.google.com/document/d/1fSeiIwDZhcf8d1ad7H8R1YCoffVxaalSIZ35SGuXkec/edit?usp=sharing';
const _PRIVACY_POLICY_URL_EN =
    'https://docs.google.com/document/d/1vSWRLKTEsvpVDY8hh8eVH5-Ec7QVpW_6h0s8y03E5y8/edit?usp=sharing';

typedef ArgCallback<T> = void Function(T argument);
typedef ResCallback<T> = T Function();
typedef ArgResCallback<A, R> = R Function(A argument);

final _random = Random();

int randInt(int min, int max) {
  return min + _random.nextInt(max - min);
}

bool isInTests() {
  try {
    return Platform.environment.containsKey('FLUTTER_TEST');
  } catch (e) {
    return false;
  }
}

Future<bool> enableNewestFeatures() async =>
    isInTests() || await GetIt.I.get<Settings>().enableNewestFeatures();

void setSystemUIOverlayStyle() {
  if (Platform.isAndroid) {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
        statusBarColor: Colors.white,
        statusBarIconBrightness: Brightness.dark));
  }
}

double degreesToRads(double deg) {
  return (deg * pi) / 180.0;
}

/// Used to disable warnings about not awaited futures
void unawaited<T>(Future<T>? future) {
  // Nothing to do
}

Future<Directory> getAppDir() async {
  if (isInTests()) {
    return Directory('/tmp/');
  }
  return await getApplicationDocumentsDirectory();
}

Future<Directory> getAppTempDir() async {
  if (isInTests()) {
    return Directory('/tmp/');
  }
  return await getTemporaryDirectory();
}

Future<PackageInfo> getPackageInfo() async {
  if (isInTests()) {
    return PackageInfo(
      appName: 'Plante tests',
      packageName: 'Plante tests',
      version: 'Plante tests',
      buildNumber: 'Plante tests',
    );
  }
  return await PackageInfo.fromPlatform();
}

String operatingSystem() {
  if (kIsWeb) {
    return 'web';
  }
  return Platform.operatingSystem;
}

String privacyPolicyUrl(SysLangCodeHolder langCodeHolder) {
  if (langCodeHolder.langCodeNullable == 'ru') {
    return _PRIVACY_POLICY_URL_RU;
  } else {
    return _PRIVACY_POLICY_URL_EN;
  }
}

Future<String> userAgent() async {
  final packageInfo = await getPackageInfo();
  return 'User-Agent: ${packageInfo.appName} / ${packageInfo.version} '
      '${operatingSystem()}, plante.application@gmail.com';
}

Map<String, dynamic>? jsonDecodeSafe(String str) {
  try {
    return jsonDecode(str) as Map<String, dynamic>?;
  } on FormatException catch (e) {
    Log.w("Couldn't decode safe: %str", ex: e);
    return null;
  }
}
