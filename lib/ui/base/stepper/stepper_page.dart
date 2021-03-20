import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

class StepperPage extends StatelessWidget {
  final Widget _content;
  final Widget? _bottomControls;

  StepperPage(this._content, this._bottomControls);

  @override
  Widget build(BuildContext context) {
    return Column(
        verticalDirection: VerticalDirection.up,
        children: [
          if (_bottomControls != null) _bottomControls!,
          _content
        ]);
  }
}
