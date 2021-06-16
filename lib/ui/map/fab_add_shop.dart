import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:plante/ui/base/colors_plante.dart';

class FabAddShop extends StatelessWidget {
  final VoidCallback? onPressed;
  const FabAddShop({Key? key, required this.onPressed}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      heroTag: 'plus_shop',
      onPressed: onPressed,
      backgroundColor: ColorsPlante.primary,
      splashColor: ColorsPlante.splashColor,
      child: SizedBox(
          width: 30,
          height: 30,
          child: SvgPicture.asset('assets/plus_shop.svg')),
    );
  }
}
