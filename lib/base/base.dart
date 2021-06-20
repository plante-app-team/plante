import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get_it/get_it.dart';
import 'package:plante/model/user_params_controller.dart';

const PRIVACY_POLICY_URL =
    'https://docs.google.com/document/d/1fSeiIwDZhcf8d1ad7H8R1YCoffVxaalSIZ35SGuXkec/edit?usp=sharing';

typedef ArgCallback<T> = void Function(T argument);
typedef ResCallback<T> = T Function();

final _random = Random();

int randInt(int min, int max) {
  return min + _random.nextInt(max - min);
}

bool isInTests() {
  return Platform.environment.containsKey('FLUTTER_TEST');
}

bool enableNewestFeatures() {
  final userParamsController = GetIt.I.get<UserParamsController>();
  final user = userParamsController.cachedUserParams;
  final isDev = user != null && user.userGroup != null && user.userGroup! > 1;
  return kDebugMode || isDev;
}

void setSystemUIOverlayStyle() {
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
      statusBarColor: Colors.white,
      statusBarIconBrightness: Brightness.dark));
}

double degreesToRads(double deg) {
  return (deg * pi) / 180.0;
}

/// Used to disable warnings about not awaited futures
void unawaited<T>(Future<T> future) {
  // Nothing to do
}
