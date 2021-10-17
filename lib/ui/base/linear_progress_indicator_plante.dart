import 'package:flutter/material.dart';
import 'package:plante/base/base.dart';

class LinearProgressIndicatorPlante extends StatelessWidget {
  const LinearProgressIndicatorPlante({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (isInTests()) {
      // Tests hate widgets which have endless animations - pumpAndSettle
      // hangs when such widgets are present.
      // So in tests we don't create [LinearProgressIndicator].
      return const SizedBox();
    }
    return const LinearProgressIndicator();
  }
}
