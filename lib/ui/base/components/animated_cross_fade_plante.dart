import 'package:flutter/material.dart';
import 'package:plante/base/base.dart';
import 'package:plante/ui/base/ui_utils.dart';

class AnimatedCrossFadePlante extends StatelessWidget {
  final Widget firstChild;
  final Widget secondChild;
  final CrossFadeState crossFadeState;
  final Duration duration;

  const AnimatedCrossFadePlante(
      {Key? key,
      required this.firstChild,
      required this.secondChild,
      required this.crossFadeState,
      this.duration = DURATION_DEFAULT})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (isInTests()) {
      // It's hard in tests to detect which widgets
      // are in the tree but not displayed.
      // So in tests we just don't put into the tree not displayed widget.
      return crossFadeState == CrossFadeState.showFirst
          ? firstChild
          : secondChild;
    }
    return AnimatedCrossFade(
        firstChild: firstChild,
        secondChild: secondChild,
        crossFadeState: crossFadeState,
        duration: duration);
  }
}
