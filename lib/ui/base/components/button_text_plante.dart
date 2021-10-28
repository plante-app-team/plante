import 'package:flutter/material.dart';
import 'package:plante/ui/base/colors_plante.dart';
import 'package:plante/ui/base/components/button_base_plante.dart';
import 'package:plante/ui/base/text_styles.dart';

class ButtonTextPlante extends StatelessWidget {
  final double? height;
  final Widget child;
  final VoidCallback? onPressed;
  final VoidCallback? onDisabledPressed;
  final Color? overlayColor;

  ButtonTextPlante(String text,
      {Key? key,
      required this.onPressed,
      TextStyle enabledTextStyle = TextStyles.buttonOutlinedEnabled,
      TextStyle disabledTextStyle = TextStyles.buttonOutlinedDisabled,
      this.onDisabledPressed,
      this.overlayColor,
      this.height})
      : child = Text(text,
            style: onPressed != null ? enabledTextStyle : disabledTextStyle),
        super(key: key);

  @override
  Widget build(BuildContext context) {
    return ButtonBasePlante(
      height: height,
      backgroundColorEnabled: Colors.transparent,
      backgroundColorDisabled: Colors.transparent,
      overlayColor: overlayColor ?? ColorsPlante.primaryMaterial.shade700,
      onPressed: onPressed,
      onDisabledPressed: onDisabledPressed,
      side: const BorderSide(width: 0, color: Colors.transparent),
      child: child,
    );
  }
}
