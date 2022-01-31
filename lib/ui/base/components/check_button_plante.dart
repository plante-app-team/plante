import 'package:flutter/material.dart';
import 'package:plante/ui/base/colors_plante.dart';
import 'package:plante/ui/base/text_styles.dart';

class CheckButtonPlante extends StatelessWidget {
  final bool checked;
  final String text;
  final double height;
  final Color colorChecked;
  final Color colorUnchecked;
  final dynamic Function(bool value) onChanged;
  final bool? showBorder;

  const CheckButtonPlante(
      {Key? key,
      required this.checked,
      required this.text,
      this.showBorder,
      this.height = 43,
      this.colorChecked = ColorsPlante.primary,
      this.colorUnchecked = ColorsPlante.lightGrey,
      required this.onChanged})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final BorderSide border = showBorder != null && showBorder! && !checked
        ? const BorderSide(width: 1, color: Colors.grey)
        : const BorderSide(style: BorderStyle.none);
    return SizedBox(
        height: height,
        child: OutlinedButton(
            style: ButtonStyle(
                side: MaterialStateProperty.all<BorderSide>(border),
                overlayColor: MaterialStateProperty.all(checked
                    ? ColorsPlante.splashColor
                    : ColorsPlante.primaryDisabled),
                backgroundColor: MaterialStateProperty.all(
                    checked ? colorChecked : colorUnchecked),
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
