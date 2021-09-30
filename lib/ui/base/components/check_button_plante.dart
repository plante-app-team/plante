import 'package:flutter/material.dart';
import 'package:plante/ui/base/colors_plante.dart';
import 'package:plante/ui/base/text_styles.dart';

class CheckButtonPlante extends StatelessWidget {
  final bool checked;
  final String text;
  final dynamic Function(bool value) onChanged;

  const CheckButtonPlante(
      {Key? key,
      required this.checked,
      required this.text,
      required this.onChanged})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
        height: 43,
        child: OutlinedButton(
            style: ButtonStyle(
                side: MaterialStateProperty.all<BorderSide>(
                    const BorderSide(style: BorderStyle.none)),
                overlayColor: MaterialStateProperty.all(checked
                    ? ColorsPlante.splashColor
                    : ColorsPlante.primaryDisabled),
                backgroundColor: MaterialStateProperty.all(
                    checked ? ColorsPlante.primary : ColorsPlante.lightGrey),
                shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                    RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)))),
            onPressed: () {
              onChanged.call(!checked);
            },
            child: Text(text,
                style: checked ? TextStyles.normalWhite : TextStyles.normal)));
  }
}
