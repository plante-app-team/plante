import 'package:flutter/material.dart';
import 'package:plante/ui/base/colors_plante.dart';

class HeadlineBorderedPlante extends StatelessWidget {
  static final _foregroundPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2
    ..color = ColorsPlante.mainTextBlack;
  final String data;
  const HeadlineBorderedPlante(this.data, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(children: <Widget>[
      Text(data,
          style: TextStyle(
            fontFamily: 'Montserrat',
            fontWeight: FontWeight.w700,
            fontSize: 24,
            foreground: _foregroundPaint,
          )),
      Text(data,
          style: const TextStyle(
              fontFamily: 'Montserrat',
              fontWeight: FontWeight.w700,
              fontSize: 24,
              color: Colors.white)),
    ]);
  }
}
