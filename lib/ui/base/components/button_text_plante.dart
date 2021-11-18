import 'package:flutter/material.dart';
import 'package:plante/ui/base/colors_plante.dart';
import 'package:plante/ui/base/components/button_base_plante.dart';
import 'package:plante/ui/base/text_styles.dart';

class ButtonTextPlante extends StatelessWidget {
  final double? height;
  late final Widget child;
  final VoidCallback? onPressed;
  final VoidCallback? onDisabledPressed;
  final Color? overlayColor;

  ButtonTextPlante(String text,
      {Key? key,
      required this.onPressed,
      TextStyle? enabledTextStyle,
      TextStyle? disabledTextStyle,
      this.onDisabledPressed,
      this.overlayColor,
      this.height})
      : super(key: key) {
    enabledTextStyle ??= TextStyles.buttonOutlinedEnabled;
    disabledTextStyle ??= TextStyles.buttonOutlinedDisabled;
    child = Text(text,
        style: onPressed != null ? enabledTextStyle : disabledTextStyle);
  }

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
