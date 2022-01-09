import 'package:flutter/material.dart';
import 'package:plante/ui/base/colors_plante.dart';
import 'package:plante/ui/base/text_styles.dart';

class CheckButtonPlante extends StatelessWidget {
  final bool checked;
  final String text;
  final dynamic Function(bool value) onChanged;
  final bool? showBorder;

  const CheckButtonPlante(
      {Key? key,
      required this.checked,
      required this.text,
      required this.onChanged,
      this.showBorder})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final BorderSide border = showBorder != null && showBorder! && !checked
        ? const BorderSide(width: 1, color: Colors.grey)
        : const BorderSide(style: BorderStyle.none);
    return SizedBox(
        height: 43,
        child: OutlinedButton(
            style: ButtonStyle(
                side: MaterialStateProperty.all<BorderSide>(border),
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
                style: checked
                    ? TextStyles.checkButtonChecked
                    : TextStyles.checkButtonUnChecked)));
  }
}
