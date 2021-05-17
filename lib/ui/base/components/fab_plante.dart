import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

class FabPlante extends StatelessWidget {
  final String? heroTag;
  final String svgAsset;
  final VoidCallback? onPressed;

  static final VoidCallback _popOnClickFakeCallback = () {};

  const FabPlante(
      {Key? key, this.heroTag, required this.svgAsset, required this.onPressed})
      : super(key: key);

  FabPlante.backBtnPopOnClick({Key? key, this.heroTag})
      : onPressed = _popOnClickFakeCallback,
        svgAsset = 'assets/back_arrow.svg',
        super(key: key);

  const FabPlante.menuBtn({Key? key, required this.onPressed, this.heroTag})
      : svgAsset = 'assets/menu_ellipsis.svg',
        super(key: key);

  @override
  Widget build(BuildContext context) {
    final VoidCallback? onPressedReally;
    if (onPressed == _popOnClickFakeCallback) {
      onPressedReally = () {
        Navigator.of(context).pop();
      };
    } else {
      onPressedReally = onPressed;
    }
    return SizedBox(
        width: 44,
        height: 44,
        child: FloatingActionButton(
          heroTag: heroTag,
          backgroundColor: Colors.white,
          onPressed: onPressedReally,
          child: SvgPicture.asset(svgAsset),
        ));
  }
}
