import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:google_fonts/google_fonts.dart';

class TextStyles {
  static TextStyle get normal =>
      GoogleFonts.exo2(color: Color.fromARGB(255, 38, 50, 56), fontSize: 14);

  static TextStyle get headline1 => GoogleFonts.exo2(
      color: Color.fromARGB(255, 25, 33, 35),
      fontSize: 24,
      fontWeight: FontWeight.bold);

  static TextStyle get headline2 =>
      GoogleFonts.exo2(color: Color.fromARGB(255, 25, 33, 35), fontSize: 18);

  static TextStyle get input =>
      GoogleFonts.exo2(color: Color.fromARGB(255, 25, 33, 35), fontSize: 18);

  static TextStyle get inputLabel =>
      GoogleFonts.exo2(color: Colors.black, fontSize: 16);

  static TextStyle get buttonFilled => GoogleFonts.exo2(
      color: Color.fromARGB(255, 255, 255, 255),
      fontSize: 18,
      fontWeight: FontWeight.bold);
}
