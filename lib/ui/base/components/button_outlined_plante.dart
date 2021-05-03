import 'package:flutter/material.dart';
import 'package:plante/ui/base/colors_plante.dart';
import 'package:plante/ui/base/text_styles.dart';

class ButtonOutlinedPlante extends StatelessWidget {
  final Widget child;
  final VoidCallback? onPressed;

  ButtonOutlinedPlante({Key? key, required this.child, required this.onPressed})
      : super(key: key);

  ButtonOutlinedPlante.withText(String text,
      {Key? key, required VoidCallback? onPressed})
      : child = Text(text,
            style: onPressed != null
                ? TextStyles.buttonOutlinedEnabled
                : TextStyles.buttonOutlinedDisabled),
        onPressed = onPressed,
        super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
        height: 46,
        child: OutlinedButton(
            child: child,
            style: ButtonStyle(
                backgroundColor: MaterialStateProperty.all(Colors.transparent),
                overlayColor:
                    MaterialStateProperty.all(ColorsPlante.primaryDisabled),
                side: MaterialStateProperty.all<BorderSide>(BorderSide(
                    width: 1,
                    color: onPressed != null
                        ? ColorsPlante.primary
                        : ColorsPlante.primaryDisabled)),
                shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                    RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30)))),
            onPressed: onPressed));
  }
}