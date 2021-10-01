import 'package:flutter/material.dart';
import 'package:plante/base/base.dart';
import 'package:plante/l10n/strings.dart';
import 'package:plante/model/veg_status.dart';
import 'package:plante/ui/base/components/button_filled_plante.dart';
import 'package:plante/ui/base/components/dialog_plante.dart';
import 'package:plante/ui/base/text_styles.dart';

class VegStatusesExplanationDialog extends StatelessWidget {
  final ArgResCallback<VegStatus?, String> vegStatusText;
  const VegStatusesExplanationDialog({Key? key, required this.vegStatusText})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final content = Table(
        children: [
          TableRow(
            children: <Widget>[
              Text(vegStatusText(VegStatus.positive)),
              const SizedBox(width: 16),
              Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text(
                      context.strings
                          .display_product_page_veg_status_positive_explanation,
                      style: TextStyles.normal)),
            ],
          ),
          TableRow(
            children: <Widget>[
              Text(vegStatusText(VegStatus.negative)),
              const SizedBox(width: 16),
              Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text(
                      context.strings
                          .display_product_page_veg_status_negative_explanation,
                      style: TextStyles.normal)),
            ],
          ),
          TableRow(
            children: <Widget>[
              Text(vegStatusText(VegStatus.unknown)),
              const SizedBox(width: 16),
              Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text(
                      context.strings
                          .display_product_page_veg_status_unknown_explanation,
                      style: TextStyles.normal)),
            ],
          ),
          TableRow(
            children: <Widget>[
              Text(vegStatusText(VegStatus.possible)),
              const SizedBox(width: 16),
              Text(
                  context.strings
                      .display_product_page_veg_status_possible_explanation,
                  style: TextStyles.normal),
            ],
          )
        ],
        border: TableBorder.all(color: Colors.transparent),
        columnWidths: const <int, TableColumnWidth>{
          0: IntrinsicColumnWidth(),
          1: IntrinsicColumnWidth(),
          2: FlexColumnWidth(1),
        });

    return DialogPlante(
      content: content,
      actions: ButtonFilledPlante.withText(
          context.strings.display_product_page_veg_status_explanations_ok,
          onPressed: () {
        Navigator.of(context).pop();
      }),
    );
  }
}
