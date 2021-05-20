import 'package:flutter/material.dart';

class ButtonBasePlante extends StatelessWidget {
  final double? height;
  final Widget child;
  final VoidCallback? onPressed;
  final VoidCallback? onDisabledPressed;
  final Color overlayColor;
  final Color backgroundColorEnabled;
  final Color backgroundColorDisabled;
  final BorderSide? side;

  const ButtonBasePlante(
      {Key? key,
      this.height,
      required this.child,
      required this.onPressed,
      this.onDisabledPressed,
      required this.overlayColor,
      required this.backgroundColorEnabled,
      required this.backgroundColorDisabled,
      this.side})
      : super(key: key);

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
                        const EdgeInsets.only(left: 24, right: 24)),
                    overlayColor: MaterialStateProperty.all(overlayColor),
                    backgroundColor: MaterialStateProperty.all(onPressed != null
                        ? backgroundColorEnabled
                        : backgroundColorDisabled),
                    shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                        RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30))),
                    side: side != null
                        ? MaterialStateProperty.all<BorderSide>(side!)
                        : null),
                onPressed: onPressed,
                child: child)));
  }
}
