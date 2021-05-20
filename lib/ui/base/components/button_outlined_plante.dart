import 'package:flutter/material.dart';
import 'package:plante/ui/base/colors_plante.dart';
import 'package:plante/ui/base/components/button_base_plante.dart';
import 'package:plante/ui/base/text_styles.dart';

class ButtonOutlinedPlante extends StatelessWidget {
  final double? height;
  final Widget child;
  final VoidCallback? onPressed;

  const ButtonOutlinedPlante(
      {Key? key, required this.child, required this.onPressed, this.height})
      : super(key: key);

  ButtonOutlinedPlante.withText(String text,
      {Key? key, this.onPressed, this.height})
      : child = Text(text,
            style: onPressed != null
                ? TextStyles.buttonOutlinedEnabled
                : TextStyles.buttonOutlinedDisabled),
        super(key: key);

  @override
  Widget build(BuildContext context) {
    return ButtonBasePlante(
      height: height,
      backgroundColorEnabled: Colors.transparent,
      backgroundColorDisabled: Colors.transparent,
      overlayColor: ColorsPlante.primaryDisabled,
      side: BorderSide(
          width: 1,
          color: onPressed != null
              ? ColorsPlante.primary
              : ColorsPlante.primaryDisabled),
      onPressed: onPressed,
      child: child,
    );
  }
}
