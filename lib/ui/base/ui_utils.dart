import 'package:flutter/material.dart';
import 'package:plante/base/log.dart';

ScaffoldFeatureController<SnackBar, SnackBarClosedReason> showSnackBar(
    String text, BuildContext context) {
  return ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(text)));
}

Future<T?> showMenuPlante<T>(
    {required GlobalKey target,
    required BuildContext context,
    required List<T> values,
    required List<Widget> children}) async {
  assert(values.length == children.length);

  final box = target.currentContext?.findRenderObject() as RenderBox?;
  if (box == null) {
    Log.e('showMenuPlante is called when no render box is available');
    return null;
  }
  final position = box.localToGlobal(Offset.zero);

  final items = <PopupMenuItem<T>>[];
  for (var index = 0; index < values.length; ++index) {
    items.add(PopupMenuItem<T>(
      value: values[index],
      child: children[index],
    ));
  }

  return await showMenu(
    context: context,
    position: RelativeRect.fromLTRB(position.dx - box.size.width,
        position.dy + box.size.height, position.dx, position.dy),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    items: items,
  );
}
