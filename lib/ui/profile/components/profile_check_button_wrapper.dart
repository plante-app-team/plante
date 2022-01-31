import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:plante/ui/base/components/check_button_plante.dart';

/// Wrapper for a nice looking shadow
class ProfileCheckButtonWrapper extends StatelessWidget {
  static const _HEIGHT = 34.0;
  final bool checked;
  final String text;
  final dynamic Function(bool value) onChanged;

  const ProfileCheckButtonWrapper(
      {Key? key,
      required this.checked,
      required this.text,
      required this.onChanged})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Expanded(
        child: Stack(children: [
      SizedBox(
          height: _HEIGHT,
          width: double.infinity,
          child: Container(
            decoration: const BoxDecoration(
              borderRadius: BorderRadius.all(
                Radius.circular(8),
              ),
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Color(0x29192123),
                  spreadRadius: 0,
                  blurRadius: 16,
                  offset: Offset(0, 4),
                ),
              ],
            ),
          )),
      SizedBox(
          width: double.infinity,
          child: CheckButtonPlante(
              height: _HEIGHT,
              checked: checked,
              colorUnchecked: Colors.white,
              text: text,
              onChanged: onChanged)),
    ]));
  }
}
