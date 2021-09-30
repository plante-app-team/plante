import 'package:flutter/widgets.dart';

enum FadingEdgeDirection {
  LEFT_TO_RIGHT,
  TOP_TO_BOTTOM,
  RIGHT_TO_LEFT,
  BOTTOM_TO_TOP,
}

class FadingEdgePlante extends StatelessWidget {
  final FadingEdgeDirection direction;
  final double size;
  final Color color;
  const FadingEdgePlante(
      {Key? key,
      required this.direction,
      required this.size,
      required this.color})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final Alignment begin;
    final Alignment end;
    switch (direction) {
      case FadingEdgeDirection.LEFT_TO_RIGHT:
        begin = Alignment.centerLeft;
        end = Alignment.centerRight;
        break;
      case FadingEdgeDirection.TOP_TO_BOTTOM:
        begin = Alignment.topCenter;
        end = Alignment.bottomCenter;
        break;
      case FadingEdgeDirection.RIGHT_TO_LEFT:
        begin = Alignment.centerRight;
        end = Alignment.centerLeft;
        break;
      case FadingEdgeDirection.BOTTOM_TO_TOP:
        begin = Alignment.bottomCenter;
        end = Alignment.topCenter;
        break;
    }

    return Align(
        alignment: begin,
        child: IgnorePointer(
            child: Container(
                height: size,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: begin,
                    end: end,
                    colors: <Color>[color, const Color(0x00ffffff)],
                  ),
                ))));
  }
}
