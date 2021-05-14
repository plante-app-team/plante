import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

class BackButtonPlante extends StatelessWidget {
  final VoidCallback? onPressed;

  static final VoidCallback _popOnClickFakeCallback = () {};

  const BackButtonPlante({Key? key, this.onPressed}) : super(key: key);

  BackButtonPlante.popOnClick({Key? key})
      : onPressed = _popOnClickFakeCallback,
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
          backgroundColor: Colors.white,
          onPressed: onPressedReally,
          child: SvgPicture.asset('assets/back_arrow.svg'),
        ));
  }
}
