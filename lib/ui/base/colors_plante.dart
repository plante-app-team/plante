import 'package:flutter/material.dart';

class ColorsPlante {
  static const int _primaryVal = 0xFF326243;
  static const Color primary = Color(_primaryVal);
  static const MaterialColor primaryMaterial =
      MaterialColor(_primaryVal, <int, Color>{
    50: Color(0xFFE9F6EE),
    100: Color(0xFFCAE8D5),
    200: Color(0xFFA8dABB),
    300: Color(0xFF86CCA1),
    400: Color(0xFF6CC18D),
    500: Color(0xFF54B679),
    600: Color(0xFF4CA66E),
    700: Color(0xFF439462),
    800: Color(0xFF3D8257),
    900: Color(_primaryVal),
  });
  static const Color primaryDisabled = Color.fromARGB(255, 132, 161, 142);
  static final Color splashColor = primaryMaterial.shade800;
  static const Color grey = Color(0xFF979A9C);
}
