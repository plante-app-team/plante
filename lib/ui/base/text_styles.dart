import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:get_it/get_it.dart';
import 'package:plante/ui/base/colors_plante.dart';
import 'package:plante/ui/base/safe_font_environment_detector.dart';

class TextStyles {
  static const _MARKER_FONT_SIZE = 15.0;
  TextStyles._();

  static const TextStyle normal =
      TextStyle(fontFamily: 'OpenSans', fontSize: 14, color: Color(0xFF263238));

  static const TextStyle normalWhite =
      TextStyle(fontFamily: 'OpenSans', fontSize: 14, color: Color(0xFFFFFFFF));

  static const TextStyle checkButtonUnChecked = TextStyle(
      fontFamily: 'OpenSans',
      fontSize: 14,
      color: ColorsPlante.primary,
      fontWeight: FontWeight.bold);

  static const TextStyle checkButtonChecked = TextStyle(
      fontFamily: 'OpenSans',
      fontSize: 14,
      color: Colors.white,
      fontWeight: FontWeight.bold);

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

  static const TextStyle smallBoldWhite = TextStyle(
      fontFamily: 'OpenSans',
      fontSize: 12,
      fontWeight: FontWeight.bold,
      color: Colors.white);

  static const TextStyle smallBoldBlack = TextStyle(
      fontFamily: 'OpenSans',
      fontSize: 12,
      fontWeight: FontWeight.bold,
      color: ColorsPlante.mainTextBlack);

  static const TextStyle url = TextStyle(
      fontFamily: 'OpenSans',
      fontSize: 14,
      fontWeight: FontWeight.bold,
      color: ColorsPlante.primary,
      decoration: TextDecoration.underline);

  static const TextStyle pageTitle =
      TextStyle(fontFamily: 'OpenSans', fontSize: 16, color: ColorsPlante.grey);

  static TextStyle headline1 = TextStyle(
      fontFamily: montserrat,
      fontWeight: FontWeight.bold,
      fontSize: 24,
      color: const Color(0xFF192123));

  static TextStyle headline2 = TextStyle(
      fontFamily: montserrat,
      fontWeight: FontWeight.bold,
      fontSize: 16,
      color: ColorsPlante.mainTextBlack);

  static TextStyle headline1White = TextStyle(
      fontFamily: montserrat,
      fontWeight: FontWeight.bold,
      fontSize: 24,
      color: const Color(0xFFFFFFFF));

  static const TextStyle headline3 = TextStyle(
      fontFamily: 'OpenSans', fontSize: 16, color: ColorsPlante.mainTextBlack);

  static TextStyle headline4 = TextStyle(
      fontFamily: montserrat,
      fontWeight: FontWeight.bold,
      fontSize: 14,
      color: const Color(0xFF192123));

  static TextStyle headline4Green = TextStyle(
      fontFamily: montserrat,
      fontWeight: FontWeight.bold,
      fontSize: 14,
      color: ColorsPlante.primary);

  static TextStyle tag = TextStyle(
      fontFamily: montserrat,
      fontWeight: FontWeight.bold,
      fontSize: 12,
      color: ColorsPlante.mainTextBlack);

  static const TextStyle input = TextStyle(
      fontFamily: 'OpenSans', fontSize: 18, color: ColorsPlante.mainTextBlack);
  static const TextStyle inputHint =
      TextStyle(fontFamily: 'OpenSans', fontSize: 18, color: ColorsPlante.grey);

  static const TextStyle inputLabel = normalSmall;

  static TextStyle buttonFilled = TextStyle(
      fontFamily: montserrat,
      fontWeight: FontWeight.bold,
      fontSize: 16,
      color: Colors.white);

  static TextStyle buttonFilledSmall = TextStyle(
      fontFamily: montserrat,
      fontWeight: FontWeight.bold,
      fontSize: 14,
      color: Colors.white);

  static TextStyle buttonOutlinedEnabled = TextStyle(
      fontFamily: montserrat,
      fontWeight: FontWeight.bold,
      fontSize: 16,
      color: ColorsPlante.primary);

  static TextStyle buttonOutlinedDisabled = TextStyle(
      fontFamily: montserrat,
      fontWeight: FontWeight.bold,
      fontSize: 16,
      color: ColorsPlante.primaryDisabled);

  /// WARNING: DO NOT USE THIS STYLE FOR ANYTHING OTHER THAN
  /// THE NOT-TRANSLATED BRANDING TEXTS.
  /// Poppins look bad in several languages (e.g. Greek).
  static const TextStyle branding = TextStyle(
      fontFamily: 'Poppins',
      fontWeight: FontWeight.w500,
      fontSize: 24,
      color: ColorsPlante.primary);

  static TextStyle markerFilled = TextStyle(
      fontFamily: montserrat,
      fontWeight: FontWeight.bold,
      fontSize: _MARKER_FONT_SIZE,
      color: ColorsPlante.primary);

  static TextStyle markerSuggestion = TextStyle(
      fontFamily: montserrat,
      fontWeight: FontWeight.bold,
      fontSize: _MARKER_FONT_SIZE,
      color: const Color(0xFF255B55));

  static TextStyle markerAccented = TextStyle(
      fontFamily: montserrat,
      fontWeight: FontWeight.bold,
      fontSize: _MARKER_FONT_SIZE,
      color: ColorsPlante.red);

  static TextStyle markerEmpty = TextStyle(
      fontFamily: montserrat,
      fontWeight: FontWeight.bold,
      fontSize: _MARKER_FONT_SIZE,
      color: ColorsPlante.grey);

  static TextStyle licenceMarker = TextStyle(
      fontFamily: montserrat,
      fontWeight: FontWeight.bold,
      fontSize: 9,
      color: Colors.white70);

  static TextStyle licenceMarkerLight = TextStyle(
      fontFamily: montserrat,
      fontWeight: FontWeight.bold,
      fontSize: 9,
      color: ColorsPlante.grey);

  static const TextStyle langName =
      TextStyle(fontFamily: 'OpenSans', fontSize: 14, color: Color(0xFF192123));

  static const TextStyle searchBarText =
      TextStyle(fontFamily: 'OpenSans', fontSize: 14, color: Color(0xFF192123));

  static const TextStyle searchBarHint =
      TextStyle(fontFamily: 'OpenSans', fontSize: 14, color: Colors.grey);

  static const TextStyle progressbarHint = TextStyle(
      fontFamily: 'OpenSans',
      fontSize: 14,
      color: Colors.white,
      fontWeight: FontWeight.bold);

  static const TextStyle searchResultDistance = TextStyle(
      fontFamily: 'OpenSans',
      fontSize: 12,
      color: ColorsPlante.grey,
      fontWeight: FontWeight.bold);

  static String get montserrat {
    if (_useSafeFont()) {
      return 'OpenSans';
    }
    return 'Montserrat';
  }

  static bool _useSafeFont() {
    if (!GetIt.I.isRegistered<SafeFontEnvironmentDetector>()) {
      return false;
    }
    final safeFontDetector = GetIt.I.get<SafeFontEnvironmentDetector>();
    return safeFontDetector.shouldUseSafeFont();
  }
}
