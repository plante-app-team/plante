import 'package:flutter/material.dart';
import 'package:plante/ui/base/colors_plante.dart';
import 'package:plante/ui/base/text_styles.dart';

class ButtonFilledPlante extends StatelessWidget {
  final Key? key;
  final Widget child;
  final VoidCallback? onPressed;

  ButtonFilledPlante({this.key, required this.child, required this.onPressed})
      : super(key: key);

  ButtonFilledPlante.withText(String text, {this.key, required this.onPressed})
      : child = Text(text, style: TextStyles.buttonFilled),
        super(key: key);

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
