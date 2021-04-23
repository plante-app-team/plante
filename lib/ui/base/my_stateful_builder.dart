import 'package:flutter/widgets.dart';

/// Same as [StatefulBuilder], but also notifies of dispose.
/// Please see documentation for [StatefulBuilder]
class MyStatefulBuilder extends StatefulWidget {
  const MyStatefulBuilder({
    Key? key,
    required this.builder,
    this.disposer,
  }) : super(key: key);

  final StatefulWidgetBuilder builder;
  final Function()? disposer;

  @override
  _MyStatefulBuilderState createState() => _MyStatefulBuilderState();
}

class _MyStatefulBuilderState extends State<MyStatefulBuilder> {
  @override
  Widget build(BuildContext context) => widget.builder(context, setState);
  @override
  void dispose() {
    widget.disposer?.call();
    super.dispose();
  }
}
