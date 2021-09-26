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

  static const TextStyle normalSmall = TextStyle(
      fontFamily: 'OpenSans', fontSize: 12, color: ColorsPlante.mainTextBlack);

  static const TextStyle hint =
      TextStyle(fontFamily: 'OpenSans', fontSize: 12, color: ColorsPlante.grey);

  static const TextStyle hintWhite =
      TextStyle(fontFamily: 'OpenSans', fontSize: 12, color: Colors.white);

  static const TextStyle smallBoldGreen = TextStyle(
      fontFamily: 'OpenSans',
      fontSize: 12,
      fontWeight: FontWeight.bold,
      color: ColorsPlante.primary);

  static const TextStyle url = TextStyle(
      fontFamily: 'OpenSans',
      fontSize: 14,
      fontWeight: FontWeight.bold,
      color: ColorsPlante.primary,
      decoration: TextDecoration.underline);

  static const TextStyle headline1 = TextStyle(
      fontFamily: 'Montserrat',
      fontWeight: FontWeight.bold,
      fontSize: 24,
      color: Color(0xFF192123));

  static const TextStyle headline2 = TextStyle(
      fontFamily: 'Montserrat',
      fontWeight: FontWeight.bold,
      fontSize: 16,
      color: ColorsPlante.mainTextBlack);

  static const TextStyle headline1White = TextStyle(
      fontFamily: 'Montserrat',
      fontWeight: FontWeight.bold,
      fontSize: 24,
      color: Color(0xFFFFFFFF));

  static const TextStyle headline3 = TextStyle(
      fontFamily: 'OpenSans', fontSize: 16, color: ColorsPlante.mainTextBlack);

  static const TextStyle headline4 = TextStyle(
      fontFamily: 'Montserrat',
      fontWeight: FontWeight.bold,
      fontSize: 14,
      color: Color(0xFF192123));

  static const TextStyle headline4Green = TextStyle(
      fontFamily: 'Montserrat',
      fontWeight: FontWeight.bold,
      fontSize: 14,
      color: ColorsPlante.primary);

  static const TextStyle tag = TextStyle(
      fontFamily: 'Montserrat',
      fontWeight: FontWeight.bold,
      fontSize: 12,
      color: ColorsPlante.mainTextBlack);

  static const TextStyle input = TextStyle(
      fontFamily: 'OpenSans', fontSize: 18, color: ColorsPlante.mainTextBlack);
  static const TextStyle inputHint =
      TextStyle(fontFamily: 'OpenSans', fontSize: 18, color: ColorsPlante.grey);

  static const TextStyle inputLabel = normalSmall;

  static const TextStyle buttonFilled = TextStyle(
      fontFamily: 'Montserrat',
      fontWeight: FontWeight.bold,
      fontSize: 16,
      color: Colors.white);

  static const TextStyle buttonFilledSmall = TextStyle(
      fontFamily: 'Montserrat',
      fontWeight: FontWeight.bold,
      fontSize: 14,
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

  static const TextStyle markerFilled = TextStyle(
      fontFamily: 'Montserrat',
      fontWeight: FontWeight.bold,
      fontSize: 17,
      color: ColorsPlante.primary);

  static const TextStyle markerAccented = TextStyle(
      fontFamily: 'Montserrat',
      fontWeight: FontWeight.bold,
      fontSize: 17,
      color: Color(0xFFF02222));

  static const TextStyle markerEmpty = TextStyle(
      fontFamily: 'Montserrat',
      fontWeight: FontWeight.bold,
      fontSize: 17,
      color: ColorsPlante.grey);

  static const TextStyle licenceMarker = TextStyle(
      fontFamily: 'Montserrat',
      fontWeight: FontWeight.bold,
      fontSize: 9,
      color: Colors.white70);

  static const TextStyle licenceMarkerLight = TextStyle(
      fontFamily: 'Montserrat',
      fontWeight: FontWeight.bold,
      fontSize: 9,
      color: ColorsPlante.grey);


  static const TextStyle langName =
      TextStyle(fontFamily: 'OpenSans', fontSize: 14, color: Color(0xFF192123));

  static const TextStyle searchBarText =
      TextStyle(fontFamily: 'OpenSans', fontSize: 14, color: Color(0xFF192123));
  static const TextStyle searchBarHint =
      TextStyle(fontFamily: 'OpenSans', fontSize: 14, color: ColorsPlante.grey);
  static const TextStyle searchResultDistance = TextStyle(
      fontFamily: 'OpenSans',
      fontSize: 12,
      color: ColorsPlante.grey,
      fontWeight: FontWeight.bold);
}
