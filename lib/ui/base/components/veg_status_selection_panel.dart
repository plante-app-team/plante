import 'package:flutter/material.dart';
import 'package:plante/base/dialog_plante.dart';
import 'package:plante/l10n/strings.dart';
import 'package:plante/model/veg_status.dart';
import 'package:plante/ui/base/components/button_filled_plante.dart';
import 'package:plante/ui/base/components/check_button_plante.dart';
import 'package:plante/ui/base/components/info_button_plante.dart';
import 'package:plante/ui/base/text_styles.dart';

class VegStatusSelectionPanel extends StatelessWidget {
  final Key? keyPositive;
  final Key? keyNegative;
  final Key? keyUnknown;
  final String title;
  final VegStatus? vegStatus;
  final dynamic Function(VegStatus? value) onChanged;

  const VegStatusSelectionPanel(
      {Key? key,
      required this.title,
      required this.vegStatus,
      required this.onChanged,
      this.keyPositive,
      this.keyNegative,
      this.keyUnknown})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      SizedBox(
        width: double.infinity,
        child: Text(
          title,
          style: TextStyles.headline4,
          textAlign: TextAlign.left,
        ),
      ),
      const SizedBox(height: 8),
      Row(children: [
        Expanded(
            child: CheckButtonPlante(
          key: keyPositive,
          checked: vegStatus == VegStatus.positive,
          text: context.strings.veg_status_selection_panel_positive,
          onChanged: (value) {
            if (value == false) {
              // Let's act as a radio buttons set
              return;
            }
            onChanged.call(value ? VegStatus.positive : null);
          },
        )),
        const SizedBox(width: 14),
        Expanded(
            child: CheckButtonPlante(
          key: keyNegative,
          checked: vegStatus == VegStatus.negative,
          text: context.strings.veg_status_selection_panel_negative,
          onChanged: (value) {
            if (value == false) {
              // Let's act as a radio buttons set
              return;
            }
            onChanged.call(value ? VegStatus.negative : null);
          },
        )),
        const SizedBox(width: 14),
        Expanded(
            child: CheckButtonPlante(
          key: keyUnknown,
          checked: vegStatus == VegStatus.unknown,
          text: context.strings.veg_status_selection_panel_dunno,
          onChanged: (value) {
            if (value == false) {
              // Let's act as a radio buttons set
              return;
            }
            onChanged.call(value ? VegStatus.unknown : null);
          },
        )),
      ]),
    ]);
  }
}
