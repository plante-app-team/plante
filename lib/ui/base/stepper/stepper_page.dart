import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

class StepperPage extends StatelessWidget {
  final Widget content;
  final Widget? bottomControls;
  final Key? key;

  StepperPage(this.content, this.bottomControls, {this.key});

  @override
  Widget build(BuildContext context) {
    return Column(key: key, verticalDirection: VerticalDirection.up, children: [
      if (bottomControls != null) bottomControls!,
      Expanded(child: content)
    ]);
  }
}
