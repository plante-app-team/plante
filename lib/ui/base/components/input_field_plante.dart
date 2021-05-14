import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:plante/ui/base/colors_plante.dart';
import 'package:plante/ui/base/text_styles.dart';

class InputFieldPlante extends StatelessWidget {
  final String? label;
  final String? hint;
  final TextCapitalization textCapitalization;
  final TextEditingController? controller;

  const InputFieldPlante(
      {Key? key,
      this.label,
      this.hint,
      this.textCapitalization = TextCapitalization.sentences,
      this.controller})
      : super(key: key);

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
            hintText: hint,
            contentPadding: const EdgeInsets.only(left: 22, right: 22),
            enabledBorder: const OutlineInputBorder(
              gapPadding: 2,
              borderSide: BorderSide(color: Color.fromARGB(255, 28, 32, 44)),
              borderRadius: BorderRadius.all(Radius.circular(30)),
            ),
            focusedBorder: const OutlineInputBorder(
              gapPadding: 2,
              borderSide: BorderSide(color: ColorsPlante.primary, width: 2),
              borderRadius: BorderRadius.all(Radius.circular(30)),
            ),
          ),
          controller: controller,
        ));
  }
}
