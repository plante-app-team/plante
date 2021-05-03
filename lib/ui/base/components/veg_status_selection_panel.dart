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
  final Key? keyPossible;
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
      this.keyPossible,
      this.keyUnknown})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Row(children: [
        Text(
          title,
          style: TextStyles.headline4,
          textAlign: TextAlign.left,
        ),
        InfoButtonPlante(onTap: () {
          showVegStatusInfoDialog(context);
        })
      ]),
      SizedBox(height: 8),
      Row(children: [
        Expanded(
            child: CheckButtonPlante(
          key: keyPositive,
          checked: vegStatus == VegStatus.positive,
          text: context.strings.veg_status_selection_panel_positive,
          onChanged: (value) {
            onChanged.call(value ? VegStatus.positive : null);
          },
        )),
        SizedBox(width: 8),
        Expanded(
            child: CheckButtonPlante(
          key: keyNegative,
          checked: vegStatus == VegStatus.negative,
          text: context.strings.veg_status_selection_panel_negative,
          onChanged: (value) {
            onChanged.call(value ? VegStatus.negative : null);
          },
        )),
      ]),
      SizedBox(height: 18),
      Row(children: [
        Expanded(
            child: CheckButtonPlante(
          key: keyPossible,
          checked: vegStatus == VegStatus.possible,
          text: context.strings.veg_status_selection_panel_possible,
          onChanged: (value) {
            onChanged.call(value ? VegStatus.possible : null);
          },
        )),
        SizedBox(width: 8),
        Expanded(
            child: CheckButtonPlante(
          key: keyUnknown,
          checked: vegStatus == VegStatus.unknown,
          text: context.strings.veg_status_selection_panel_unknown,
          onChanged: (value) {
            onChanged.call(value ? VegStatus.unknown : null);
          },
        )),
      ])
    ]);
  }

  void showVegStatusInfoDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return DialogPlante(
            content: Text(
                context.strings.veg_status_selection_panel_explanation,
                style: TextStyles.normal),
            actions: ButtonFilledPlante.withText(
                context.strings.veg_status_selection_panel_explanation_ok,
                onPressed: () {
              Navigator.of(context).pop();
            }));
      },
    );
  }
}
