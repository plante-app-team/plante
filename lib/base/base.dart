import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

bool isInTests() {
  return Platform.environment.containsKey('FLUTTER_TEST');
}

void setSystemUIOverlayStyle() {
  SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
      statusBarColor: Colors.white,
      statusBarIconBrightness: Brightness.dark
  ));
}
