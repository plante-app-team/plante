import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:plante/base/base.dart';
import 'package:plante/ui/base/components/circular_progress_indicator_plante.dart';
import 'package:plante/ui/base/ui_utils.dart';
import 'package:plante/ui/base/ui_value.dart';

/// Same as [CircularProgressIndicatorPlante], but at first is invisible and
/// is appearing with time out of nowhere
class AppearingCircularProgressIndicatorPlante extends ConsumerStatefulWidget {
  final Duration durationBeforeAppearing;
  final Duration appearingDuration;
  final double? value;
  const AppearingCircularProgressIndicatorPlante(
      {Key? key,
      this.value,
      required this.durationBeforeAppearing,
      this.appearingDuration = DURATION_DEFAULT})
      : super(key: key);

  @override
  _AppearingCircularProgressIndicatorPlanteState createState() =>
      _AppearingCircularProgressIndicatorPlanteState();
}

class _AppearingCircularProgressIndicatorPlanteState
    extends ConsumerState<AppearingCircularProgressIndicatorPlante> {
  late final _draw = UIValue(false, ref);
  var _firstBuildHappened = false;

  @override
  Widget build(BuildContext context) {
    if (isInTests()) {
      // Tests don't like the "await Future.delayed" calls
      return const SizedBox();
    }

    if (!_firstBuildHappened) {
      _firstBuildHappened = true;
      // An async function so that the [setValue] call would be performed
      // not inside the [build] function.
      () async {
        await Future.delayed(widget.durationBeforeAppearing);
        if (mounted) {
          _draw.setValue(true);
        }
      }.call();
    }
    return AnimatedOpacity(
      opacity: _draw.watch(ref) ? 1 : 0,
      duration: widget.appearingDuration,
      child: CircularProgressIndicator(value: widget.value),
    );
  }
}
