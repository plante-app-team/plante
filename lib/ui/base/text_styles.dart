import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:plante/ui/base/colors_plante.dart';

class TextStyles {
  static const TextStyle normal =
      TextStyle(fontFamily: 'OpenSans', fontSize: 14, color: Color(0xFF263238));

  static const TextStyle normalWhite =
      TextStyle(fontFamily: 'OpenSans', fontSize: 14, color: Color(0xFFFFFFFF));

  static const TextStyle normalBold = TextStyle(
      fontFamily: 'OpenSans',
      fontSize: 14,
      fontWeight: FontWeight.bold,
      color: Color(0xFF1E2030));

  static const TextStyle normalColored = TextStyle(
      fontFamily: 'OpenSans', fontSize: 14, color: ColorsPlante.primary);

  static const TextStyle normalSmall =
      TextStyle(fontFamily: 'OpenSans', fontSize: 12, color: Color(0xFF192123));

  static const TextStyle hint =
      TextStyle(fontFamily: 'OpenSans', fontSize: 12, color: Color(0xFF979A9C));

  static const TextStyle smallBoldGreen = TextStyle(
      fontFamily: 'OpenSans',
      fontSize: 12,
      fontWeight: FontWeight.bold,
      color: ColorsPlante.primary);

  static const TextStyle headline1 = TextStyle(
      fontFamily: 'Montserrat',
      fontWeight: FontWeight.bold,
      fontSize: 24,
      color: Color(0xFF192123));

  static const TextStyle headline1White = TextStyle(
      fontFamily: 'Montserrat',
      fontWeight: FontWeight.bold,
      fontSize: 24,
      color: Color(0xFFFFFFFF));

  static const TextStyle headline3 =
      TextStyle(fontFamily: 'OpenSans', fontSize: 16, color: Color(0xFF192123));

  static const TextStyle headline4 = TextStyle(
      fontFamily: 'Montserrat',
      fontWeight: FontWeight.bold,
      fontSize: 14,
      color: Color(0xFF192123));

  static const TextStyle input =
      TextStyle(fontFamily: 'OpenSans', fontSize: 18, color: Color(0xFF192123));

  static const TextStyle inputLabel = normalSmall;

  static const TextStyle buttonFilled = TextStyle(
      fontFamily: 'Montserrat',
      fontWeight: FontWeight.bold,
      fontSize: 16,
      color: Colors.white);

  static const TextStyle buttonOutlinedEnabled = TextStyle(
      fontFamily: 'Montserrat',
      fontWeight: FontWeight.bold,
      fontSize: 16,
      color: ColorsPlante.primary);

  static const TextStyle buttonOutlinedDisabled = TextStyle(
      fontFamily: 'Montserrat',
      fontWeight: FontWeight.bold,
      fontSize: 16,
      color: ColorsPlante.primaryDisabled);

  static const TextStyle branding = TextStyle(
      fontFamily: 'Poppins',
      fontWeight: FontWeight.w500,
      fontSize: 24,
      color: ColorsPlante.primary);
}
