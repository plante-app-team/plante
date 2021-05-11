import 'package:flutter/material.dart';
import 'package:plante/l10n/strings.dart';
import 'package:plante/ui/base/text_styles.dart';

class HeaderPlante extends StatelessWidget {
  static const DEFAULT_ACTIONS_SIDE_PADDINGS = 24.0;
  final Widget? title;
  final Widget? leftAction;
  final Widget? rightAction;
  final double spacingBottom;
  final double leftActionPadding;
  final double rightActionPadding;
  const HeaderPlante(
      {Key? key,
      this.title,
      this.leftAction,
      this.rightAction,
      this.spacingBottom = 0,
      this.leftActionPadding = DEFAULT_ACTIONS_SIDE_PADDINGS,
      this.rightActionPadding = DEFAULT_ACTIONS_SIDE_PADDINGS})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Material(
        color: Colors.white,
        child: Container(
          width: double.infinity,
          height: 104 + spacingBottom,
          child: Column(children: [
            SizedBox(height: 28), // spacing
            Expanded(
                child: Stack(children: [
              Align(
                  alignment: Alignment.center,
                  child: title ?? _titleDefault(context)),
              Align(
                  alignment: Alignment.centerLeft,
                  child: Row(children: [
                    SizedBox(width: leftActionPadding),
                    if (leftAction != null) leftAction!
                  ])),
              Align(
                  alignment: Alignment.centerRight,
                  child: Row(textDirection: TextDirection.rtl, children: [
                    SizedBox(width: rightActionPadding),
                    if (rightAction != null) rightAction!
                  ])),
            ])),
            SizedBox(height: spacingBottom),
          ]),
        ));
  }

  Widget _titleDefault(BuildContext context) => Text(
        context.strings.global_app_name,
        style: TextStyles.branding,
      );
}
