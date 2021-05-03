import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:plante/ui/base/colors_plante.dart';
import 'package:plante/ui/base/text_styles.dart';

class InputFieldMultilinePlante extends StatelessWidget {
  final Key? key;
  final String? label;
  final TextCapitalization textCapitalization;
  final TextEditingController? controller;
  final int? maxLines;

  InputFieldMultilinePlante(
      {this.key,
      this.label,
      this.textCapitalization = TextCapitalization.sentences,
      this.controller,
      this.maxLines});

  @override
  Widget build(BuildContext context) {
    return TextField(
      key: key,
      style: TextStyles.normal,
      textCapitalization: textCapitalization,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        contentPadding: EdgeInsets.only(left: 12, right: 12, top: 24),
        enabledBorder: OutlineInputBorder(
            gapPadding: 20,
            borderSide: BorderSide(color: ColorsPlante.primary),
            borderRadius: BorderRadius.zero),
        focusedBorder: OutlineInputBorder(
            gapPadding: 20,
            borderSide: BorderSide(color: ColorsPlante.primary, width: 2),
            borderRadius: BorderRadius.zero),
      ),
      controller: controller,
    );
  }
}
