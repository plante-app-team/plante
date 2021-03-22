import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

class StepperPage extends StatelessWidget {
  final Widget content;
  final Widget? bottomControls;

  StepperPage(this.content, this.bottomControls);

  @override
  Widget build(BuildContext context) {
    return Column(
        verticalDirection: VerticalDirection.up,
        children: [
          if (bottomControls != null) bottomControls!,
          Expanded(child: content)
        ]);
  }
}
