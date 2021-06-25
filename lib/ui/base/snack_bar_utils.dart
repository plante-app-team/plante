import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:plante/ui/base/text_styles.dart';

enum SnackBarStyle {
  DEFAULT,
  MAP_ACTION_DONE,
}

ScaffoldFeatureController<SnackBar, SnackBarClosedReason> showSnackBar(
    String text, BuildContext context,
    [SnackBarStyle style = SnackBarStyle.DEFAULT]) {
  ScaffoldMessenger.of(context).removeCurrentSnackBar();

  final SnackBar snackBar;
  switch (style) {
    case SnackBarStyle.DEFAULT:
      snackBar = SnackBar(content: Text(text));
      break;
    case SnackBarStyle.MAP_ACTION_DONE:
      snackBar = SnackBar(
          elevation: 0,
          backgroundColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          content: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 38),
              child: SizedBox(
                height: 90,
                child: Material(
                  elevation: 20,
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  child: Center(
                    child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Wrap(
                            alignment: WrapAlignment.center,
                            crossAxisAlignment: WrapCrossAlignment.end,
                            children: [
                              SvgPicture.asset('assets/map_check_mark.svg'),
                              const SizedBox(width: 16),
                              Text(text, style: TextStyles.headline4Green)
                            ]
                        )
                    ),
                  ),
                ),
              )));
      break;
  }

  return ScaffoldMessenger.of(context).showSnackBar(snackBar);
}
