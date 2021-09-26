import 'package:flutter/material.dart';
import 'package:plante/ui/base/text_styles.dart';

class LicenceLabel extends StatelessWidget {
  final String label;
  final bool darkBox;

  const LicenceLabel({required this.label, required this.darkBox});

  @override
  Widget build(BuildContext context) {
    return Container(
        decoration: BoxDecoration(
            color: darkBox ? Colors.black45 : Colors.white70,
            borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(8), topLeft: Radius.circular(8))),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Text(
            label,
            style: darkBox ? TextStyles.licenceMarker : TextStyles.licenceMarkerLight,
          ),
        ));
  }
}
