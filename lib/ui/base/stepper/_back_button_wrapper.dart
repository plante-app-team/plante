import 'package:flutter/material.dart';
import 'package:plante/base/base.dart';

class BackButtonWrapperController {
  bool _shown = false;
  Function(bool)? _setButtonShown;
  void setButtonShown(bool shown) {
    _shown = shown;
    _setButtonShown?.call(_shown);
  }
}

class BackButtonWrapper extends StatefulWidget {
  final Widget backButton;
  final BackButtonWrapperController controller;

  const BackButtonWrapper(this.backButton, this.controller, {Key? key})
      : super(key: key);

  @override
  _BackButtonWrapperState createState() => _BackButtonWrapperState();
}

class _BackButtonWrapperState extends State<BackButtonWrapper> {
  @override
  void initState() {
    super.initState();
    widget.controller._setButtonShown = (shown) {
      if (!mounted) {
        return;
      }
      setState(() {
        // Update!
      });
    };
  }

  @override
  Widget build(BuildContext context) {
    if (isInTests()) {
      // AnimatedCrossFade always have both widgets created which is not ok for testing
      return widget.controller._shown ? widget.backButton : SizedBox.shrink();
    }
    return AnimatedCrossFade(
        firstChild: widget.backButton,
        secondChild: SizedBox.shrink(),
        crossFadeState: widget.controller._shown
            ? CrossFadeState.showFirst
            : CrossFadeState.showSecond,
        duration: Duration(milliseconds: 250));
  }
}
