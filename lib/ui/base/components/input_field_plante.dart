import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:plante/ui/base/colors_plante.dart';
import 'package:plante/ui/base/text_styles.dart';

class InputFieldPlante extends StatelessWidget {
  final Key? key;
  final String? label;
  final TextCapitalization textCapitalization;
  final TextEditingController? controller;

  InputFieldPlante(
      {this.key,
      this.label,
      this.textCapitalization = TextCapitalization.sentences,
      this.controller});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
        height: 46,
        child: TextField(
          textCapitalization: textCapitalization,
          key: key,
          style: TextStyles.input,
          decoration: InputDecoration(
            labelText: label,
            labelStyle: TextStyles.inputLabel,
            contentPadding: EdgeInsets.only(left: 22),
            enabledBorder: OutlineInputBorder(
              gapPadding: 2,
              borderSide: BorderSide(color: Color.fromARGB(255, 28, 32, 44)),
              borderRadius: BorderRadius.all(Radius.circular(30)),
            ),
            focusedBorder: OutlineInputBorder(
              gapPadding: 2,
              borderSide: BorderSide(color: ColorsPlante.primary, width: 2),
              borderRadius: BorderRadius.all(Radius.circular(30)),
            ),
          ),
          controller: controller,
        ));
  }
}
