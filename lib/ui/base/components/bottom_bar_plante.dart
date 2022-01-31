import 'package:flutter/material.dart';

class BottomBarPlante extends StatelessWidget {
  final List<Widget> children;
  const BottomBarPlante({Key? key, required this.children}) : super(key: key);

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
                offset: const Offset(0, 3),
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
    for (var index = 0; index < children.length; ++index) {
      final paddingLeft = index == 0 ? 12.25 : 0.0;
      final paddingRight = index == children.length - 1 ? 12.25 : 0.0;
      final button = Expanded(
          child: Padding(
              padding: EdgeInsets.only(
                  bottom: 7, left: paddingLeft, right: paddingRight),
              child: children[index]));
      result.add(button);
    }
    return result;
  }
}
