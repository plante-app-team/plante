import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:plante/base/base.dart';
import 'package:plante/base/pair.dart';
import 'package:plante/ui/base/colors_plante.dart';
import 'package:plante/ui/base/text_styles.dart';
import 'package:plante/ui/base/ui_utils.dart';

class TimedHints extends StatefulWidget {
  final bool inProgress;
  final List<Pair<String, Duration>> hints;
  final bool enableInTests;

  const TimedHints(
      {Key? key,
      required this.inProgress,
      required this.hints,
      this.enableInTests = false})
      : super(key: key);

  @override
  State<TimedHints> createState() => isInTests() && !enableInTests
      ? _TimedHintsForTests()
      : _TimedHintsState();
}

class _TimedHintsForTests extends State<TimedHints> {
  @override
  Widget build(BuildContext context) {
    return const SizedBox();
  }
}

class _TimedHintsState extends State<TimedHints> {
  Timer _hintUpdateTimer = Timer(Duration.zero, () {});
  var _hintIndex = -1;

  List<Pair<String, Duration>> get _hints => widget.hints;

  @override
  void dispose() {
    _hintUpdateTimer.cancel();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    if (widget.inProgress) {
      _showNextHint();
    }
  }

  void _showNextHint() {
    setState(() {
      _hintIndex += 1;
    });
    if (_hintIndex >= _hints.length) {
      // fin
      return;
    }
    final duration = _hints[_hintIndex].second;
    _hintUpdateTimer.cancel();
    _hintUpdateTimer = Timer(duration, _showNextHint);
  }

  @override
  void didUpdateWidget(TimedHints oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.inProgress == true && widget.inProgress == false) {
      // Hints no longer change
      _hintUpdateTimer.cancel();
      return;
    }

    final restart = !oldWidget.inProgress && widget.inProgress;
    final newData =
        widget.inProgress && !listEquals(oldWidget.hints, widget.hints);
    if (restart || newData) {
      _hintIndex = -1;
      _showNextHint();
    }
  }

  @override
  Widget build(BuildContext context) {
    String? hintText;
    if (_hints.isNotEmpty) {
      final hintIndex = _hintIndex.clamp(0, _hints.length - 1);
      hintText = _hints[hintIndex].first;
    }
    Widget? hint;
    if (hintText != null && hintText.isNotEmpty) {
      hint = Container(
          key: Key('hint $hintText'),
          constraints: const BoxConstraints(maxWidth: 280),
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 10),
          alignment: Alignment.center,
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
              color: ColorsPlante.primary.withOpacity(0.60)),
          child: Text(hintText,
              style: TextStyles.progressbarHint, textAlign: TextAlign.center));
    }

    return AnimatedSwitcher(
        duration: DURATION_DEFAULT, child: hint ?? const SizedBox());
  }
}
