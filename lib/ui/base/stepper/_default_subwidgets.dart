import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:plante/ui/base/colors_plante.dart';
import 'package:plante/ui/base/components/back_button_plante.dart';

// ignore: always_use_package_imports
import 'functions.dart';

Widget defaultDividerMaker(
    int leftPage, int rightPage, bool leftFinished, bool rightFinished) {
  return Container(
      width: 37,
      height: 1,
      color: rightFinished
          ? ColorsPlante.primary
          : const Color.fromARGB(255, 215, 215, 215));
}

Widget defaultIndicatorMaker(int page, PageIndicatorState pageState) {
  final borderColor = pageState == PageIndicatorState.NOT_REACHED
      ? const Color.fromARGB(255, 215, 215, 215)
      : ColorsPlante.primary;

  final size = pageState == PageIndicatorState.PASSED ? 14.0 : 24.0;

  final color = pageState == PageIndicatorState.PASSED
      ? ColorsPlante.primary
      : Colors.transparent;

  final text = (page + 1).toString();

  final indicator = AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      width: size,
      height: size,
      decoration: BoxDecoration(
          color: color,
          border: Border.all(color: borderColor, width: 1),
          shape: BoxShape.circle),
      child: Center(
          child: Text(text,
              style: GoogleFonts.exo2(color: borderColor, fontSize: 14))));

  final wrapper =
      SizedBox(width: 24, height: 24, child: Center(child: indicator));
  return wrapper;
}

Widget? defaultBackButtonMaker(Function() back) {
  return BackButtonPlante(onPressed: back);
}
