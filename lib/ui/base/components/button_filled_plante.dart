import 'package:flutter/material.dart';
import 'package:plante/ui/base/colors_plante.dart';
import 'package:plante/ui/base/text_styles.dart';

class ButtonFilledPlante extends StatelessWidget {
  final Widget child;
  final VoidCallback? onPressed;

  const ButtonFilledPlante(
      {Key? key, required this.child, required this.onPressed})
      : super(key: key);

  ButtonFilledPlante.withText(String text, {Key? key, required this.onPressed})
      : child = Text(text, style: TextStyles.buttonFilled),
        super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
        height: 46,
        child: OutlinedButton(
            style: ButtonStyle(
                padding: MaterialStateProperty.all(
                    const EdgeInsets.only(left: 24, right: 24)),
                overlayColor:
                    MaterialStateProperty.all(ColorsPlante.splashColor),
                backgroundColor: MaterialStateProperty.all(onPressed != null
                    ? ColorsPlante.primary
                    : ColorsPlante.primaryDisabled),
                shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                    RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30)))),
            onPressed: onPressed,
            child: child));
  }
}
