import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

class DialogPlante extends StatelessWidget {
  final Widget? title;
  final Widget content;
  final Widget? actions;
  final EdgeInsets contentPadding;

  const DialogPlante(
      {Key? key,
      this.title,
      required this.content,
      this.actions,
      this.contentPadding = const EdgeInsets.all(24)})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Align(
        alignment: Alignment.bottomCenter,
        child: Container(
            margin: MediaQuery.of(context).viewInsets,
            padding: const EdgeInsets.only(bottom: 38, left: 16, right: 16),
            child: Material(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                elevation: 4,
                child: Padding(
                    padding: contentPadding,
                    child: Wrap(children: [
                      Column(children: [
                        if (title != null)
                          Column(
                              children: [title!, const SizedBox(height: 16)]),
                        content,
                        if (actions != null)
                          Column(children: [
                            const SizedBox(height: 16),
                            SizedBox(width: double.infinity, child: actions)
                          ])
                      ])
                    ])))));
  }
}
