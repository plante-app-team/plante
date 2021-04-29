import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

const PRIVACY_POLICY_URL =
    "https://docs.google.com/document/d/1fSeiIwDZhcf8d1ad7H8R1YCoffVxaalSIZ35SGuXkec/edit?usp=sharing";

bool isInTests() {
  return Platform.environment.containsKey('FLUTTER_TEST');
}

void setSystemUIOverlayStyle() {
  SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
      statusBarColor: Colors.white,
      statusBarIconBrightness: Brightness.dark));
}

double degreesToRads(double deg) {
  return (deg * pi) / 180.0;
}
