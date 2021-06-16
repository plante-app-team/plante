import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:plante/ui/base/colors_plante.dart';

class FabMyLocation extends StatelessWidget {
  final VoidCallback? onPressed;
  const FabMyLocation({Key? key, required this.onPressed}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      heroTag: 'my_location',
      onPressed: onPressed,
      backgroundColor: Colors.white,
      splashColor: ColorsPlante.primaryDisabled,
      child: SizedBox(
          width: 30,
          height: 30,
          child: SvgPicture.asset('assets/my_location.svg')),
    );
  }
}
