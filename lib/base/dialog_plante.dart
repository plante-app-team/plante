import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

class DialogPlante extends StatelessWidget {
  final Widget? title;
  final Widget content;
  final Widget? actions;

  const DialogPlante(
      {Key? key, this.title, required this.content, this.actions})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Align(
        alignment: Alignment.bottomCenter,
        child: Container(
            margin: MediaQuery.of(context).viewInsets,
            padding: EdgeInsets.only(bottom: 16),
            child: Material(
                color: Colors.white,
                child: Padding(
                    padding: EdgeInsets.only(
                        left: 24, top: 24, right: 24, bottom: 16),
                    child: Wrap(children: [
                      Column(children: [
                        if (title != null)
                          Column(children: [title!, SizedBox(height: 16)]),
                        content,
                        if (actions != null)
                          Column(children: [
                            SizedBox(height: 16),
                            SizedBox(width: double.infinity, child: actions)
                          ])
                      ])
                    ])))));
  }
}
