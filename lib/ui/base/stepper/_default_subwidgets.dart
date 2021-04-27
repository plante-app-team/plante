import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:plante/ui/base/colors_plante.dart';

import 'functions.dart';

Widget defaultDividerMaker(
    int leftPage, int rightPage, bool leftFinished, bool rightFinished) {
  return Container(
      width: 37,
      height: 1,
      color: rightFinished
          ? ColorsPlante.primary
          : Color.fromARGB(255, 215, 215, 215));
}

Widget defaultIndicatorMaker(int page, PageIndicatorState pageState) {
  final borderColor = pageState == PageIndicatorState.NOT_REACHED
      ? Color.fromARGB(255, 215, 215, 215)
      : ColorsPlante.primary;

  final size = pageState == PageIndicatorState.PASSED ? 14.0 : 24.0;

  final color = pageState == PageIndicatorState.PASSED
      ? ColorsPlante.primary
      : Colors.transparent;

  final text = (page + 1).toString();

  final indicator = AnimatedContainer(
      duration: Duration(milliseconds: 250),
      width: size,
      height: size,
      child: Center(
          child: Text(text,
              style: GoogleFonts.exo2(color: borderColor, fontSize: 14))),
      decoration: BoxDecoration(
          color: color,
          border: Border.all(color: borderColor, width: 1),
          shape: BoxShape.circle));

  final wrapper =
      Container(width: 24, height: 24, child: Center(child: indicator));
  return wrapper;
}

Widget? defaultBackButtonMaker(Function() back) {
  return InkWell(
      key: Key("default_stepper_back_button"),
      child: SvgPicture.asset("assets/stepper_back.svg"),
      onTap: back);
}
