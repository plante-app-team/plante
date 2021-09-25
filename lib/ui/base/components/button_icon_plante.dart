import 'package:flutter/material.dart';
import 'package:plante/ui/base/colors_plante.dart';
import 'package:plante/ui/base/text_styles.dart';

class ButtonIconPlante extends StatelessWidget {
  final double? height;
  final Widget label;
  final VoidCallback? onPressed;
  final VoidCallback? onDisabledPressed;
  final BorderSide? side;
  final TextStyle? textStyle;
  final Icon icon;

  ButtonIconPlante(String text,
      {Key? key,
      required this.onPressed,
      this.onDisabledPressed,
      this.height,
      this.side,
      this.textStyle,
      required this.icon})
      : label = Text(text, style: textStyle ?? TextStyles.buttonFilled),
        super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
        overlayColor: MaterialStateProperty.all(Colors.transparent),
        highlightColor: Colors.transparent,
        onTap: onPressed != null ? null : onDisabledPressed,
        child: SizedBox(
            height: height ?? 46,
            child: OutlinedButton(
                style: ButtonStyle(
                    padding: MaterialStateProperty.all(
                        const EdgeInsets.only(left: 10, right: 10)),
                    overlayColor:
                        MaterialStateProperty.all(ColorsPlante.splashColor),
                    backgroundColor: MaterialStateProperty.all(onPressed != null
                        ? ColorsPlante.primary
                        : ColorsPlante.primaryDisabled),
                    shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                        RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8))),
                    side: side != null
                        ? MaterialStateProperty.all<BorderSide>(side!)
                        : null),
                onPressed: onPressed,
                child: Row(mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [Flexible(child: label), icon],
                ))));
  }
}
