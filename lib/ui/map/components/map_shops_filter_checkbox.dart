import 'package:flutter/material.dart';
import 'package:plante/base/base.dart';
import 'package:plante/ui/base/components/checkbox_plante.dart';
import 'package:plante/ui/base/text_styles.dart';

class MapShopsFilterCheckbox extends StatelessWidget {
  final String text;
  final bool value;
  final Color markerColor;
  final ArgCallback<bool> onChanged;

  const MapShopsFilterCheckbox(
      {Key? key,
      required this.text,
      required this.value,
      required this.markerColor,
      required this.onChanged})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        onChanged.call(!value);
      },
      child: Row(children: [
        const SizedBox(width: 12),
        CheckboxPlante(
            value: value,
            onChanged: (value) {
              onChanged(value ?? false);
            }),
        Flexible(
            child: RichText(
          text: TextSpan(
            style: TextStyles.headline4,
            children: [
              TextSpan(text: text),
              WidgetSpan(
                  child: Padding(
                      padding: const EdgeInsets.only(left: 6, bottom: 4),
                      child: Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: markerColor,
                          shape: BoxShape.circle,
                        ),
                      ))),
            ],
          ),
        )),
        const SizedBox(width: 16),
      ]),
    );
  }
}
