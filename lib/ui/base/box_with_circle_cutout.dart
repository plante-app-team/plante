import 'package:flutter/widgets.dart';
import 'package:plante/base/base.dart';

class BoxWithCircleCutout extends StatelessWidget {
  final double width;
  final double height;
  final double cutoutPadding;
  final Color color;
  final EdgeInsets? padding;

  BoxWithCircleCutout(
      {Key? key,
      required this.width,
      required this.height,
      this.cutoutPadding = 0,
      required this.color,
      this.padding})
      : super(key: key);

  @override
  Widget build(BuildContext context) => ClipPath(
        child: Container(
          width: width,
          height: height,
          color: color,
        ),
        clipper: _Clipper((width < height ? width : height) - cutoutPadding),
      );
}

class _Clipper extends CustomClipper<Path> {
  final double circleSize;

  _Clipper(this.circleSize);

  @override
  Path getClip(Size size) {
    final path = Path();
    final rircleRect = Rect.fromCenter(
        center: Offset(size.width / 2, size.height / 2),
        width: circleSize,
        height: circleSize);

    path.arcTo(rircleRect, degreesToRads(0), degreesToRads(180), true);
    path.lineTo(0, size.height / 2);
    path.lineTo(0, size.height);
    path.lineTo(size.width, size.height);
    path.lineTo(size.width, size.height / 2);

    path.arcTo(rircleRect, degreesToRads(180), degreesToRads(180), true);
    path.lineTo(size.width, size.height / 2);
    path.lineTo(size.width, -1);
    path.lineTo(0, -1);
    path.lineTo(0, size.height / 2);

    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
