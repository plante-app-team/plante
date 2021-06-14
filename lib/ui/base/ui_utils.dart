import 'package:flutter/material.dart';
import 'package:plante/base/log.dart';
import 'package:plante/ui/base/components/button_filled_plante.dart';
import 'package:plante/ui/base/components/button_outlined_plante.dart';
import 'package:plante/ui/base/components/dialog_plante.dart';
import 'package:plante/ui/base/text_styles.dart';
import 'package:plante/l10n/strings.dart';

const DURATION_DEFAULT = Duration(milliseconds: 250);

ScaffoldFeatureController<SnackBar, SnackBarClosedReason> showSnackBar(
    String text, BuildContext context) {
  ScaffoldMessenger.of(context).removeCurrentSnackBar();
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

Future<bool?> showYesNoDialog<bool>(BuildContext context, String title,
    [VoidCallback? onYes]) async {
  return await showDialog<bool>(
    context: context,
    builder: (BuildContext context) {
      return DialogPlante(
          content: Text(title, style: TextStyles.headline1),
          actions: Row(children: [
            Expanded(
                child: ButtonOutlinedPlante.withText(
              context.strings.global_no,
              onPressed: () {
                Navigator.of(context).pop(false);
              },
            )),
            const SizedBox(width: 16),
            Expanded(
                child: ButtonFilledPlante.withText(
              context.strings.global_yes,
              onPressed: () {
                Navigator.of(context).pop(true);
                onYes?.call();
              },
            )),
          ]));
    },
  );
}
