import 'package:flutter/material.dart';

class PseudoPopupMenuItem extends PopupMenuEntry {
  final Widget child;

  const PseudoPopupMenuItem({required this.child});

  @override
  State<StatefulWidget> createState() => _PseudoPopupMenuItemState();

  @override
  double get height => throw UnimplementedError();

  @override
  bool represents(value) => true;
}

class _PseudoPopupMenuItemState extends State<PseudoPopupMenuItem> {
  @override
  Widget build(BuildContext context) => widget.child;
}
