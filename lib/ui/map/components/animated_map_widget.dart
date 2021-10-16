import 'package:flutter/material.dart';
import 'package:plante/ui/base/ui_utils.dart';

class AnimatedMapWidget extends StatefulWidget {
  final Widget child;
  const AnimatedMapWidget({Key? key, required this.child}) : super(key: key);

  @override
  _AnimatedMapWidgetState createState() => _AnimatedMapWidgetState();
}

class _AnimatedMapWidgetState extends State<AnimatedMapWidget> {
  @override
  Widget build(BuildContext context) {
    return AnimatedSize(
        duration: DURATION_DEFAULT,
        child:
            AnimatedSwitcher(duration: DURATION_DEFAULT, child: widget.child));
  }
}
