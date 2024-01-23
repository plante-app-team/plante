import 'package:flutter/widgets.dart';
import 'package:plante/base/base.dart';
import 'package:plante/ui/base/ui_value.dart';

/// WillPopScope is deprecated and PopScope is more complicated because it
/// requires a straight bool value to be passed to it, forcing it to be
/// [UIValue] and the child to be [consumer((argument) => null)]
class WillPopScopePlante extends StatelessWidget {
  final ResCallback<Future<bool>> onWillPop;
  final Widget child;

  const WillPopScopePlante(
      {super.key, required this.onWillPop, required this.child});

  @override
  Widget build(BuildContext context) {
    // ignore: deprecated_member_use
    return WillPopScope(onWillPop: onWillPop, child: child);
  }
}
