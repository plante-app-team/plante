import 'package:flutter/material.dart';
import 'package:plante/ui/base/colors_plante.dart';
import 'package:plante/ui/base/ui_utils.dart';

class BarcodeSpinner extends StatefulWidget {
  const BarcodeSpinner({Key? key}) : super(key: key);

  @override
  _BarcodeSpinnerState createState() => _BarcodeSpinnerState();
}

class _BarcodeSpinnerState extends State<BarcodeSpinner>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _paddingAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _paddingAnimation =
        Tween<double>(begin: 5, end: 12).animate(_animationController);

    _animationController.addListener(() {
      if (mounted) {
        setState(() {
          // Update!
        });
      }
    });
    _animationController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _animationController.reverse();
      } else if (status == AnimationStatus.dismissed) {
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
    return SizedBox(
      width: 36,
      height: 29,
      child: Stack(children: [
        Center(
            child: Container(
          width: 30,
          height: 29,
          decoration: BoxDecoration(
            border: Border.all(
              width: 2,
              color: const Color(0xFFC2D0C7),
            ),
            borderRadius: const BorderRadius.all(Radius.circular(4)),
          ),
        )),
        Padding(
          padding: EdgeInsets.only(top: _paddingAnimation.value, bottom: 5),
          child: Container(
              width: 36,
              height: 12,
              color: Colors.white,
              child: const Divider(
                height: 2,
                thickness: 2,
                color: ColorsPlante.primary,
              )),
        )
      ]),
    );
  }
}
