import 'package:flutter/material.dart';

/// See class usage
class PseudoPopupMenuItem extends PopupMenuEntry {
  final _stateKey = GlobalKey();
  final Widget child;

  PseudoPopupMenuItem({required this.child});

  @override
  State<StatefulWidget> createState() => _PseudoPopupMenuItemState();

  @override
  double get height => throw UnimplementedError();

  @override
  bool represents(value) => true;
}

class _PseudoPopupMenuItemState extends State<PseudoPopupMenuItem> {
  @override
  Widget build(BuildContext context) =>
      Container(key: widget._stateKey, child: widget.child);
}
