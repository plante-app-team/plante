import 'package:flutter/material.dart';
import 'package:plante/ui/base/ui_utils.dart';

class AnimatedModeWidget extends StatefulWidget {
  final Widget child;
  const AnimatedModeWidget({Key? key, required this.child}) : super(key: key);

  @override
  _AnimatedModeWidgetState createState() => _AnimatedModeWidgetState();
}

class _AnimatedModeWidgetState extends State<AnimatedModeWidget>
    with SingleTickerProviderStateMixin {
  @override
  Widget build(BuildContext context) {
    return AnimatedSize(
        vsync: this,
        duration: DURATION_DEFAULT,
        child:
            AnimatedSwitcher(duration: DURATION_DEFAULT, child: widget.child));
  }
}
