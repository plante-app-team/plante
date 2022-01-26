import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' as intl;
import 'package:plante/base/base.dart';
import 'package:plante/l10n/strings.dart';
import 'package:plante/ui/base/components/button_filled_plante.dart';
import 'package:plante/ui/base/components/button_outlined_plante.dart';
import 'package:plante/ui/base/components/button_text_plante.dart';
import 'package:plante/ui/base/components/dialog_plante.dart';
import 'package:plante/ui/base/text_styles.dart';

const DURATION_DEFAULT = Duration(milliseconds: 250);

Consumer consumer(ArgResCallback<WidgetRef, Widget> fn) {
  return Consumer(builder: (context, ref, _) => fn.call(ref));
}

Future<bool?> showYesNoDialog<bool>(BuildContext context, String title,
    [VoidCallback onYes = _noOp]) async {
  return await showDialog<bool>(
    context: context,
    builder: (BuildContext context) {
      return DialogPlante(
          key: const Key('yes_no_dialog'),
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
                onYes.call();
              },
            )),
          ]));
    },
  );
}

Future<bool?> showDoOrCancelDialog<bool>(
    BuildContext context, String title, String doWhat, VoidCallback onDo,
    {String? cancelWhat}) async {
  return await showDialog<bool>(
    context: context,
    builder: (BuildContext context) {
      return DialogPlante(
          key: const Key('do_or_cancel_dialog'),
          content: Text(title, style: TextStyles.headline3),
          actions: Column(children: [
            SizedBox(
                width: double.infinity,
                child: ButtonTextPlante(
                  cancelWhat ?? context.strings.global_cancel,
                  onPressed: () {
                    Navigator.of(context).pop(false);
                  },
                )),
            const SizedBox(height: 8),
            SizedBox(
                width: double.infinity,
                child: ButtonFilledPlante.withText(
                  doWhat,
                  onPressed: () {
                    Navigator.of(context).pop(true);
                    onDo.call();
                  },
                )),
          ]));
    },
  );
}

Future<bool?> showSystemDialog<bool>(
    BuildContext context, String content, String doWhat, VoidCallback onDo,
    {String? cancelWhat, String? title}) async {
  if (Platform.isAndroid) {
    return showDoOrCancelDialog(context, content, doWhat, onDo,
        cancelWhat: cancelWhat);
  } else {
    return _showIosDialog(context, title, content, doWhat, onDo,
        cancelWhat: cancelWhat);
  }
}

Future<bool?> _showIosDialog<bool>(BuildContext context, String? title,
    String content, String doWhat, VoidCallback onDo,
    {String? cancelWhat}) async {
  await showDialog<bool>(
    context: context,
    builder: (_) => CupertinoAlertDialog(
      title: Text(title ?? ''),
      content: Text(content),
      actions: [
        CupertinoButton(
            onPressed: () {
              Navigator.of(context).pop(true);
              onDo.call();
            },
            child: Text(doWhat)),
        CupertinoButton(
            onPressed: () {
              Navigator.of(context).pop(false);
            },
            child: Text(cancelWhat ?? context.strings.global_cancel))
      ],
    ),
  );
}

String secsSinceEpochToStr(int secs, BuildContext context) {
  return dateToStr(DateTime.fromMillisecondsSinceEpoch(secs * 1000), context);
}

String millisSinceEpochToStr(int millis, BuildContext context) {
  return dateToStr(DateTime.fromMillisecondsSinceEpoch(millis), context);
}

String dateToStr(DateTime date, BuildContext context) {
  return intl.DateFormat.yMMMMd(context.langCode).format(date);
}

void _noOp() {}
