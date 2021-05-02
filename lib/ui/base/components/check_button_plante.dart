import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:plante/ui/base/colors_plante.dart';

class CheckButtonPlante extends StatelessWidget {
  final bool checked;
  final String text;
  final dynamic Function(bool value) onChanged;

  const CheckButtonPlante(
      {Key? key,
      required this.checked,
      required this.text,
      required this.onChanged})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
        height: 43,
        child: OutlinedButton(
            child: Text(text,
                style: checked
                    ? GoogleFonts.exo2(color: Colors.white, fontSize: 14)
                    : GoogleFonts.exo2(color: Color(0xFF263238), fontSize: 14)),
            style: ButtonStyle(
                side: MaterialStateProperty.all<BorderSide>(
                    BorderSide(style: BorderStyle.none)),
                overlayColor: MaterialStateProperty.all(checked
                    ? ColorsPlante.primaryMaterial.shade800
                    : ColorsPlante.primaryDisabled),
                backgroundColor: MaterialStateProperty.all(
                    checked ? ColorsPlante.primary : Color(0xFFEBEFEC)),
                shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                    RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30)))),
            onPressed: () {
              onChanged.call(!checked);
            }));
  }
}
