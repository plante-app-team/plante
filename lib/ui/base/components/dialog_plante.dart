import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

class DialogPlante extends StatelessWidget {
  final Widget? title;
  final Widget content;
  final Widget? actions;
  final EdgeInsets contentPadding;
  final double? contentWidth;
  final double? contentHeight;

  const DialogPlante(
      {Key? key,
      this.title,
      required this.content,
      this.actions,
      this.contentPadding =
          const EdgeInsets.only(left: 24, right: 24, top: 12, bottom: 16),
      this.contentWidth,
      this.contentHeight})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Align(
        alignment: Alignment.bottomCenter,
        child: Container(
            margin: MediaQuery.of(context).viewInsets,
            padding: const EdgeInsets.only(bottom: 24, left: 16, right: 16),
            child: Material(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                elevation: 4,
                child: Padding(
                    padding: contentPadding,
                    child: Wrap(children: [
                      Column(children: [
                        if (title != null)
                          SizedBox(
                              width: contentWidth,
                              child: Column(children: [
                                title!,
                                const SizedBox(height: 16)
                              ])),
                        SizedBox(
                            width: contentWidth,
                            height: contentHeight,
                            child: content),
                        if (actions != null)
                          Column(children: [
                            const SizedBox(height: 16),
                            SizedBox(
                                width: contentWidth ?? double.infinity,
                                child: actions)
                          ])
                      ])
                    ])))));
  }
}
