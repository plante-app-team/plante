import 'package:flutter/material.dart';

class VegStatusWarning extends StatelessWidget {
  final Color color;
  final Widget text;
  const VegStatusWarning({Key? key, required this.color, required this.text})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Padding(
          padding:
              const EdgeInsets.only(left: 12, top: 8, right: 12, bottom: 8),
          child: text,
        ));
  }
}
