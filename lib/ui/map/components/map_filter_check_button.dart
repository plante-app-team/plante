import 'package:flutter/material.dart';
import 'package:plante/ui/base/components/check_button_plante.dart';
import 'package:plante/ui/base/text_styles.dart';

class MapFilterCheckButton extends StatelessWidget {
  static const _VERTICAL_PADDING = 24.0;
  static const _BUTTON_HEIGHT = 32.0;
  static const TOTAL_HEIGHT = _VERTICAL_PADDING + _BUTTON_HEIGHT;
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
    return Padding(
        padding: const EdgeInsets.only(
            top: _VERTICAL_PADDING / 2, bottom: _VERTICAL_PADDING / 2),
        child: CheckButtonPlante(
            height: _BUTTON_HEIGHT,
            checked: checked,
            text: text,
            textStyleChecked:
                TextStyles.checkButtonChecked.copyWith(fontSize: 12),
            textStyleUnChecked:
                TextStyles.checkButtonUnChecked.copyWith(fontSize: 12),
            onChanged: onChanged,
            showBorder: !checked,
            shadow: const BoxShadow(
              color: Color(0x19212329),
              blurRadius: 8,
              offset: Offset(0, 4),
            )));
  }
}
