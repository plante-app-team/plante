import 'package:flutter/material.dart';
import 'package:plante/ui/base/ui_utils.dart';

class MapBottomHint extends StatefulWidget {
  final RichText? text;
  final EdgeInsets padding;
  const MapBottomHint(this.text,
      {Key? key,
      this.padding = const EdgeInsets.only(left: 24, right: 24, bottom: 8)})
      : super(key: key);

  @override
  _MapBottomHintState createState() => _MapBottomHintState();
}

class _MapBottomHintState extends State<MapBottomHint>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  RichText? _displayedText;
  bool get _shown => widget.text != null;
  AnimationStatusListener _animationStatusListener = (_) {};

  @override
  void initState() {
    super.initState();
    _animationController =
        AnimationController(vsync: this, duration: DURATION_DEFAULT);
    _animation = Tween<double>(begin: 0, end: 1).animate(_animationController);

    _displayedText = widget.text;
    _animationController.animateTo(_shown ? 1 : 0, duration: Duration.zero);
  }

  @override
  void didUpdateWidget(MapBottomHint oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.text != null) {
      _displayedText = widget.text;
    } else {
      // If text is null, we will play the hide animation.
      // We want to keep the old text during the animation
      // so that the widget won't flicker.
    }
    _animationController.animateTo(_shown ? 1 : 0, duration: DURATION_DEFAULT);

    _animationController.removeStatusListener(_animationStatusListener);
    _animationStatusListener = (status) {
      if (status == AnimationStatus.completed ||
          status == AnimationStatus.dismissed) {
        // Let's erase the text so that the tests would be
        // able to see that the hint is gone.
        if (widget.text == null) {
          setState(() {
            _displayedText = null;
          });
        }
      }
    };
    _animationController.addStatusListener(_animationStatusListener);
  }

  @override
  Widget build(BuildContext context) {
    final content = Padding(
        padding: widget.padding,
        child: Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          elevation: 2,
          child: Padding(
            padding:
                const EdgeInsets.only(left: 20, right: 20, top: 12, bottom: 13),
            child: _displayedText,
          ),
        ));

    return IgnorePointer(
        child: FadeTransition(
      opacity: _animation,
      child: SizeTransition(
        sizeFactor: _animation,
        child: content,
      ),
    ));
  }
}
