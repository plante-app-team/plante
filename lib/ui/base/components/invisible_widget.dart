import 'package:flutter/material.dart';
import 'package:plante/ui/base/components/visibility_detector_plante.dart';

/// Some Widgets use [VisibilityDetectorPlante], which
/// hates `const SizedBox()` because it's always invisible as of itself.
/// Such widgets can replace [SizedBox] with [InvisibleWidget] which is sort
/// of visible - it will be drawn, but, at the same time, it's transparent.
class InvisibleWidget extends StatelessWidget {
  const InvisibleWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 1, color: Colors.transparent);
  }
}
