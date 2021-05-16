import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:plante/ui/base/colors_plante.dart';
import 'package:plante/ui/base/text_styles.dart';

class InputFieldMultilinePlante extends StatelessWidget {
  final String? label;
  final TextCapitalization textCapitalization;
  final TextEditingController? controller;
  final int? maxLines;

  const InputFieldMultilinePlante(
      {Key? key,
      this.label,
      this.textCapitalization = TextCapitalization.sentences,
      this.controller,
      this.maxLines})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TextField(
      key: key,
      style: TextStyles.normal,
      textCapitalization: textCapitalization,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        contentPadding: const EdgeInsets.only(left: 12, right: 12, top: 24),
        enabledBorder: const OutlineInputBorder(
            gapPadding: 20,
            borderSide: BorderSide(color: Color(0xFF979A9C)),
            borderRadius: BorderRadius.all(Radius.circular(8))),
        focusedBorder: const OutlineInputBorder(
            gapPadding: 20,
            borderSide: BorderSide(color: ColorsPlante.primary, width: 2),
            borderRadius: BorderRadius.all(Radius.circular(8))),
      ),
      controller: controller,
    );
  }
}
