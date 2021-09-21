import 'package:flutter/widgets.dart';

class GradientSpinner extends StatefulWidget {
  const GradientSpinner({Key? key}) : super(key: key);

  @override
  _GradientSpinnerState createState() => _GradientSpinnerState();
}

class _GradientSpinnerState extends State<GradientSpinner>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _alignmentAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2000));
    _alignmentAnimation =
        Tween<double>(begin: -2.5, end: 2.5).animate(_animationController);

    _animationController.addListener(() {
      if (mounted) {
        setState(() {
          // Update!
        });
      }
    });
    _animationController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _animationController.reset();
        _animationController.forward();
      }
    });
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.stop();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final begin = -1.0 + _alignmentAnimation.value;
    final end = 1.0 + _alignmentAnimation.value;
    return Container(
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            gradient: LinearGradient(
              begin: Alignment(begin, 0),
              end: Alignment(end, 0),
              colors: const <Color>[
                Color(0xFFD6E8DC),
                Color(0xFFEBF0ED),
                Color(0xFFD6E8DC),
              ],
            )));
  }
}
