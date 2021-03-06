import 'package:flutter/material.dart';
import 'package:plante/ui/base/colors_plante.dart';
import 'package:plante/ui/base/components/fab_plante.dart';
import 'package:plante/ui/base/text_styles.dart';
import 'package:plante/ui/base/ui_utils.dart';

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
      duration: DURATION_DEFAULT,
      width: size,
      height: size,
      decoration: BoxDecoration(
          color: color,
          border: Border.all(color: borderColor, width: 1),
          shape: BoxShape.circle),
      child: Center(
          child: Padding(
              padding: const EdgeInsets.only(left: 1),
              child: Text(text,
                  style: TextStyles.normal.copyWith(color: borderColor)))));

  final wrapper =
      SizedBox(width: 24, height: 24, child: Center(child: indicator));
  return wrapper;
}

Widget? defaultBackButtonMaker(Function() back) {
  return FabPlante(onPressed: back, svgAsset: 'assets/back_arrow.svg');
}
