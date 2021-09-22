import 'package:flutter/material.dart';
import 'package:plante/ui/base/colors_plante.dart';
import 'package:plante/ui/base/components/button_base_plante.dart';
import 'package:plante/ui/base/text_styles.dart';

class ButtonFilledPlante extends StatelessWidget {
  final double? height;
  final Widget child;
  final TextStyle? textStyle;
  final VoidCallback? onPressed;
  final VoidCallback? onDisabledPressed;

  const ButtonFilledPlante(
      {Key? key,
      required this.child,
      required this.onPressed,
      this.onDisabledPressed,
      this.textStyle,
      this.height})
      : super(key: key);

  ButtonFilledPlante.withText(String text,
      {Key? key, required this.onPressed, this.onDisabledPressed, this.height, this.textStyle})
      : child = Text(text, style: textStyle ?? TextStyles.buttonFilled),
        super(key: key);

  @override
  Widget build(BuildContext context) {
    return ButtonBasePlante(
      height: height,
      backgroundColorEnabled: ColorsPlante.primary,
      backgroundColorDisabled: ColorsPlante.primaryDisabled,
      overlayColor: ColorsPlante.splashColor,
      onPressed: onPressed,
      onDisabledPressed: onDisabledPressed,
      child: child,
    );
  }
}
