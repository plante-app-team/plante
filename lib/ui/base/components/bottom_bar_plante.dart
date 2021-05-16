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
        child: SizedBox(
          height: 86,
          child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: buttons()),
        ));
  }

  List<Widget> buttons() {
    final result = <Widget>[];
    for (var index = 0; index < svgIcons.length; ++index) {
      final button = Expanded(
          child: Padding(
              padding: const EdgeInsets.only(bottom: 7),
              child: IconButton(
                  key: iconsKeys?[index],
                  onPressed: () {
                    onIconClick.call(index);
                  },
                  icon: SvgPicture.asset(svgIcons[index],
                      color: index == selectedIcon
                          ? ColorsPlante.primary
                          : const Color(0xFF979A9C)))));
      result.add(button);
    }
    return result;
  }

  List<Widget> buttonsOld() {
    final result = <Widget>[];
    for (var index = 0; index < svgIcons.length; ++index) {
      result.add(IconButton(
          onPressed: () {
            onIconClick.call(index);
          },
          icon: SvgPicture.asset(svgIcons[index],
              color: index == selectedIcon
                  ? ColorsPlante.primary
                  : const Color(0xFF979A9C))));
    }
    return result;
  }
}
