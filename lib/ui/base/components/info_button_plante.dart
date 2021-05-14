import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

class InfoButtonPlante extends StatelessWidget {
  final void Function() onTap;

  const InfoButtonPlante({Key? key, required this.onTap}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
        width: 34,
        height: 34,
        child: InkWell(
            onTap: onTap,
            child: Center(
                child: Wrap(
                    children: [SvgPicture.asset('assets/info_icon.svg')]))));
  }
}
