import 'package:flutter/material.dart';
import 'package:plante/ui/base/colors_plante.dart';
import 'package:plante/ui/base/text_styles.dart';

class ButtonFilledSmallPlante extends StatelessWidget {
  final double? width;
  final double? height;
  final VoidCallback? onPressed;
  final VoidCallback? onDisabledPressed;

  final Widget? label;
  final Widget? icon;

  final Color color;
  final Color colorDisabled;
  final Color splashColor;
  final EdgeInsets? paddings;
  final double? spaceBetweenTextAndIcon;
  final BorderSide? side;

  const ButtonFilledSmallPlante._({
    Key? key,
    this.width,
    this.height,
    required this.onPressed,
    this.onDisabledPressed,
    this.label,
    required this.icon,
    required this.color,
    required this.colorDisabled,
    required this.splashColor,
    this.paddings,
    this.spaceBetweenTextAndIcon,
    this.side,
  }) : super(key: key);

  ButtonFilledSmallPlante.green({
    Key? key,
    double? width,
    double? height,
    VoidCallback? onPressed,
    VoidCallback? onDisabledPressed,
    String? text,
    Widget? icon,
    EdgeInsets? paddings,
    double? spaceBetweenTextAndIcon,
  }) : this._(
            key: key,
            onPressed: onPressed,
            label: text != null
                ? Text(text, style: TextStyles.smallBoldWhite)
                : null,
            onDisabledPressed: onDisabledPressed,
            width: width,
            height: height,
            icon: icon,
            color: ColorsPlante.primary,
            colorDisabled: ColorsPlante.primaryDisabled,
            splashColor: ColorsPlante.splashColor,
            paddings: paddings,
            spaceBetweenTextAndIcon: spaceBetweenTextAndIcon);

  ButtonFilledSmallPlante.lightGreen(
      {Key? key,
      double? width,
      double? height,
      VoidCallback? onPressed,
      VoidCallback? onDisabledPressed,
      String? text,
      Widget? icon,
      EdgeInsets? paddings,
      double? spaceBetweenTextAndIcon})
      : this._(
            key: key,
            onPressed: onPressed,
            label: text != null
                ? Text(text, style: TextStyles.smallBoldGreen)
                : null,
            onDisabledPressed: onDisabledPressed,
            width: width,
            height: height,
            side: const BorderSide(width: 0, color: Colors.transparent),
            icon: icon,
            color: ColorsPlante.greenLight,
            colorDisabled: ColorsPlante.grey,
            splashColor: ColorsPlante.primaryDisabled,
            paddings: paddings,
            spaceBetweenTextAndIcon: spaceBetweenTextAndIcon);

  @override
  Widget build(BuildContext context) {
    return InkWell(
        overlayColor: MaterialStateProperty.all(Colors.transparent),
        highlightColor: Colors.transparent,
        onTap: onPressed != null ? null : onDisabledPressed,
        child: SizedBox(
            width: width,
            height: height ?? 32,
            child: OutlinedButton(
                style: ButtonStyle(
                    padding: MaterialStateProperty.all(
                        paddings ?? const EdgeInsets.only(left: 10, right: 10)),
                    overlayColor: MaterialStateProperty.all(splashColor),
                    backgroundColor: MaterialStateProperty.all(
                        onPressed != null ? color : colorDisabled),
                    shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                        RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8))),
                    side: side != null
                        ? MaterialStateProperty.all<BorderSide>(side!)
                        : null),
                onPressed: onPressed,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (label != null) Flexible(child: label!),
                    if (label != null && icon != null)
                      SizedBox(width: spaceBetweenTextAndIcon ?? 2),
                    if (icon != null) icon!
                  ],
                ))));
  }
}
