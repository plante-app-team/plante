import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:plante/ui/base/colors_plante.dart';

class BottomBarPlante extends StatelessWidget {
  final List<String> svgIcons;
  final List<Key>? iconsKeys;
  final int selectedIcon;
  final dynamic Function(int clickedIcon) onIconClick;
  const BottomBarPlante(
      {Key? key,
      required this.svgIcons,
      required this.selectedIcon,
      required this.onIconClick,
      this.iconsKeys})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Material(
        color: Colors.white,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.5),
                spreadRadius: 5,
                blurRadius: 7,
                offset: const Offset(0, 3), // changes position of shadow
              ),
            ],
          ),
          child: SizedBox(
            height: 86,
            child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: buttons()),
          ),
        ));
  }

  List<Widget> buttons() {
    final result = <Widget>[];
    for (var index = 0; index < svgIcons.length; ++index) {
      final paddingLeft = index == 0 ? 12.25 : 0.0;
      final paddingRight = index == svgIcons.length - 1 ? 12.25 : 0.0;
      final button = Expanded(
          child: Padding(
              padding: EdgeInsets.only(
                  bottom: 7, left: paddingLeft, right: paddingRight),
              child: IconButton(
                  key: iconsKeys?[index],
                  onPressed: () {
                    onIconClick.call(index);
                  },
                  icon: SvgPicture.asset(svgIcons[index],
                      color: index == selectedIcon
                          ? ColorsPlante.primary
                          : ColorsPlante.grey))));
      result.add(button);
    }
    return result;
  }
}
