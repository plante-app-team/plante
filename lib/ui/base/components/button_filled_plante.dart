import 'package:flutter/material.dart';
import 'package:plante/ui/base/colors_plante.dart';
import 'package:plante/ui/base/text_styles.dart';

class ButtonFilledPlante extends StatelessWidget {
  final Widget child;
  final VoidCallback? onPressed;

  ButtonFilledPlante({required this.child, required this.onPressed});

  ButtonFilledPlante.withText(String text, {required this.onPressed})
      : child = Text(text, style: TextStyles.buttonFilled);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
        height: 46,
        child: OutlinedButton(
            child: child,
            style: ButtonStyle(
                overlayColor: MaterialStateProperty.all(
                    ColorsPlante.primaryMaterial.shade800),
                backgroundColor: MaterialStateProperty.all(onPressed != null
                    ? ColorsPlante.primary
                    : ColorsPlante.primaryDisabled),
                shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                    RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30)))),
            onPressed: onPressed));
  }
}
