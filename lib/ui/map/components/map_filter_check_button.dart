import 'package:flutter/material.dart';
import 'package:plante/ui/base/components/check_button_plante.dart';
import 'package:plante/ui/base/text_styles.dart';

class MapFilterCheckButton extends StatelessWidget {
  static const HEIGHT = 8.0;
  final bool checked;
  final String text;
  final dynamic Function(bool value) onChanged;
  const MapFilterCheckButton(
      {Key? key,
      required this.checked,
      required this.text,
      required this.onChanged})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CheckButtonPlante(
        height: HEIGHT,
        checked: checked,
        text: text,
        textStyleChecked: TextStyles.checkButtonChecked.copyWith(fontSize: 12),
        textStyleUnChecked:
            TextStyles.checkButtonUnChecked.copyWith(fontSize: 12),
        onChanged: onChanged,
        showBorder: !checked,
        shadow: const BoxShadow(
          color: Color(0x19212329),
          blurRadius: 8,
          offset: Offset(0, 4),
        ));
  }
}
