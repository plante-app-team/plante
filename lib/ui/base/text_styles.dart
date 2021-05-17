import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:google_fonts/google_fonts.dart';
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
      fontWeight: FontWeight.w700,
      fontSize: 24,
      color: Color(0xFF192123));

  static const TextStyle headline1White = TextStyle(
      fontFamily: 'Montserrat',
      fontWeight: FontWeight.w700,
      fontSize: 24,
      color: Color(0xFFFFFFFF));

  static TextStyle get headline2 =>
      GoogleFonts.exo2(color: const Color(0xFF192123), fontSize: 18);

  static const TextStyle headline3 =
      TextStyle(fontFamily: 'OpenSans', fontSize: 16, color: Color(0xFF192123));

  static const TextStyle headline4 = TextStyle(
      fontFamily: 'Montserrat',
      fontWeight: FontWeight.bold,
      fontSize: 14,
      color: Color(0xFF192123));

  static TextStyle get input =>
      GoogleFonts.exo2(color: const Color(0xFF192123), fontSize: 18);

  static TextStyle get inputLabel =>
      GoogleFonts.exo2(color: Colors.black, fontSize: 16);

  static const TextStyle buttonFilled = TextStyle(
      fontFamily: 'Montserrat',
      fontWeight: FontWeight.w700,
      fontSize: 16,
      color: Colors.white);

  static TextStyle get buttonOutlinedEnabled => GoogleFonts.exo2(
      color: ColorsPlante.primary, fontSize: 18, fontWeight: FontWeight.bold);

  static TextStyle get buttonOutlinedDisabled => GoogleFonts.exo2(
      color: ColorsPlante.primaryDisabled,
      fontSize: 18,
      fontWeight: FontWeight.bold);

  static const TextStyle branding = TextStyle(
      fontFamily: 'Poppins',
      fontWeight: FontWeight.w500,
      fontSize: 24,
      color: ColorsPlante.primary);
}
