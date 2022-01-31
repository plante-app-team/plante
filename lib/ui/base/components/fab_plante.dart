import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:plante/ui/base/colors_plante.dart';

class FabPlante extends StatelessWidget {
  static const SIZE_DEFAULT = 44.0;
  final String? heroTag;
  final String svgAsset;
  final VoidCallback? onPressed;
  final double size;
  final double? elevation;
  final BoxShadow? shadow;

  static const VoidCallback _popOnClickFakeCallback = _noOp;

  const FabPlante(
      {Key? key,
      this.heroTag,
      required this.svgAsset,
      required this.onPressed,
      this.size = SIZE_DEFAULT,
      this.elevation,
      this.shadow})
      : super(key: key);

  const FabPlante.backBtnPopOnClick(
      {Key? key,
      this.heroTag,
      this.elevation,
      this.shadow,
      this.size = SIZE_DEFAULT})
      : onPressed = _popOnClickFakeCallback,
        svgAsset = 'assets/back_arrow.svg',
        super(key: key);

  const FabPlante.closeBtnPopOnClick(
      {Key? key,
      this.heroTag,
      this.elevation,
      this.shadow,
      this.size = SIZE_DEFAULT})
      : onPressed = _popOnClickFakeCallback,
        svgAsset = 'assets/cancel.svg',
        super(key: key);

  const FabPlante.menuBtn(
      {Key? key,
      required this.onPressed,
      this.heroTag,
      this.elevation,
      this.shadow,
      this.size = SIZE_DEFAULT})
      : svgAsset = 'assets/menu_ellipsis.svg',
        super(key: key);

  @override
  Widget build(BuildContext context) {
    if (elevation != null && shadow != null) {
      throw Exception('Both elevation and shadow must not be provided');
    }

    final VoidCallback? onPressedReally;
    if (onPressed == _popOnClickFakeCallback) {
      onPressedReally = () {
        Navigator.of(context).pop();
      };
    } else {
      onPressedReally = onPressed;
    }
    BoxDecoration? boxDecoration;
    if (shadow != null) {
      boxDecoration = BoxDecoration(
        color: Colors.transparent,
        borderRadius: const BorderRadius.all(
          Radius.circular(100),
        ),
        boxShadow: [shadow!],
      );
    }
    return SizedBox(
        width: size,
        height: size,
        child: Stack(children: [
          if (boxDecoration != null)
            Center(
                child: SizedBox(
                    width: size,
                    height: size,
                    child: Container(
                      decoration: boxDecoration,
                    ))),
          Center(
              child: FloatingActionButton(
                  heroTag: heroTag,
                  backgroundColor: Colors.white,
                  splashColor: ColorsPlante.greenLight,
                  onPressed: onPressedReally,
                  elevation: boxDecoration == null ? elevation : 0,
                  highlightElevation: boxDecoration == null ? null : 0,
                  child: SvgPicture.asset(svgAsset)))
        ]));
  }
}

void _noOp() {}
