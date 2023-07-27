import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:plante/ui/base/colors_plante.dart';
import 'package:plante/ui/base/components/button_base_plante.dart';
import 'package:plante/ui/base/text_styles.dart';

class ButtonIconTextPlante extends StatelessWidget {
  final double height;
  final SvgPicture icon;
  final String? text;
  final TextStyle? textStyle;
  final VoidCallback? onPressed;
  final VoidCallback? onDisabledPressed;

  const ButtonIconTextPlante(
      {Key? key,
      required this.icon,
      required this.text,
      required this.onPressed,
      this.onDisabledPressed,
      this.textStyle = TextStyles.searchBarHint,
      this.height = 32})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ButtonBasePlante(
      height: height,
      backgroundColorEnabled: ColorsPlante.lightGrey,
      backgroundColorDisabled: Colors.white,
      overlayColor: ColorsPlante.primaryDisabled,
      onPressed: onPressed,
      onDisabledPressed: onDisabledPressed,
      side: const BorderSide(color: Colors.transparent),
      child: Row(children: [
        icon,
        if (text != null)
          Row(children: [
            const SizedBox(width: 10),
            Text(text!, style: textStyle ?? TextStyles.normal),
          ])
      ]),
    );
  }
}
