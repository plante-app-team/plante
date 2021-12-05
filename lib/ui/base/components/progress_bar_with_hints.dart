import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:plante/base/base.dart';
import 'package:plante/base/pair.dart';
import 'package:plante/ui/base/text_styles.dart';
import 'package:plante/ui/base/ui_utils.dart';

class ProgressBarWithHints extends StatefulWidget {
  final bool inProgress;
  late final List<Pair<double, Duration>> progresses;
  late final List<Pair<String, Duration>> hints;
  final bool enableInTests;

  ProgressBarWithHints(
      {Key? key,
      required this.inProgress,
      required Map<double, Duration> progresses,
      required this.hints,
      this.enableInTests = false})
      : super(key: key) {
    this.progresses =
        progresses.entries.map((e) => Pair(e.key, e.value)).toList();
    this.progresses.sort((lhs, rhs) => lhs.first.compareTo(rhs.first));

    if (this.progresses.isEmpty) {
      throw ArgumentError('Empty progresses are not supported');
    }
    if ((1 - this.progresses.last.first) > 0.0001) {
      throw ArgumentError('Last progress must equal to 1: $progresses');
    }
  }

  @override
  State<ProgressBarWithHints> createState() => isInTests() && !enableInTests
      ? _ProgressBarWithHintsStateForTests()
      : _ProgressBarWithHintsState();
}

class _ProgressBarWithHintsStateForTests extends State<ProgressBarWithHints> {
  @override
  Widget build(BuildContext context) {
    return const SizedBox();
  }
}

class _ProgressBarWithHintsState extends State<ProgressBarWithHints>
    with SingleTickerProviderStateMixin {
  static const _PROGRESS_APPEARANCE_DURATION_MILLIS = 1000;
  var _progressIndex = -1;
  var _hintIndex = -1;
  late final AnimationController _progressAnimationController;
  late final AnimationStatusListener _nextProgressAnimationStarter;
  late Animation<double> _progressAnimation;
  Timer _hintUpdateTimer = Timer(Duration.zero, () {});

  List<Pair<double, Duration>> get _progresses => widget.progresses;
  List<Pair<String, Duration>> get _hints => widget.hints;

  @override
  void dispose() {
    _progressAnimationController.dispose();
    _hintUpdateTimer.cancel();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _progressAnimationController = AnimationController(vsync: this);
    _nextProgressAnimationStarter = (status) {
      if (status == AnimationStatus.completed) {
        _startNextProgressAnimation();
      }
    };
    if (widget.inProgress) {
      _startNextProgressAnimation();
      _showNextHint();
    }
  }

  @override
  void didUpdateWidget(ProgressBarWithHints oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.inProgress == true && widget.inProgress == false) {
      // Hints no longer change
      _hintUpdateTimer.cancel();
      // Automatic progress animation changes no longer active
      _progressAnimationController
          .removeStatusListener(_nextProgressAnimationStarter);

      // Quickly animate to 100%, before the progress bar is hidden
      const durationMax = _PROGRESS_APPEARANCE_DURATION_MILLIS;
      final duration =
          durationMax - (durationMax * _progressAnimation.value).toInt();
      _animateProgressBar(
          from: _progressAnimation.value,
          to: 1,
          duration: Duration(milliseconds: duration),
          curve: Curves.easeInCirc);
      return;
    }

    final restart = oldWidget.inProgress == false && widget.inProgress == true;
    final newData = widget.inProgress == true &&
            !listEquals(oldWidget.hints, widget.hints) ||
        !listEquals(oldWidget.progresses, widget.progresses);
    if (restart || newData) {
      _progressIndex = -1;
      _hintIndex = -1;
      _startNextProgressAnimation();
      _showNextHint();
    }
  }

  void _animateProgressBar(
      {required double from,
      required double to,
      required Duration duration,
      Curve curve = Curves.linear}) {
    _progressAnimation = Tween<double>(begin: from, end: to).animate(
        CurvedAnimation(parent: _progressAnimationController, curve: curve));
    _progressAnimationController.duration = duration;
    _progressAnimationController.reset();
    _progressAnimationController.forward();
  }

  void _startNextProgressAnimation() {
    _progressIndex += 1; // NOTE: no call to setState
    if (_progressIndex >= _progresses.length) {
      // fin
      return;
    }

    final double prevProgress;
    if (_progressIndex == 0) {
      prevProgress = 0.0;
      _progressAnimationController
          .addStatusListener(_nextProgressAnimationStarter);
    } else {
      prevProgress = _progressAnimation.value;
    }
    final value = _progresses[_progressIndex];

    _animateProgressBar(
      from: prevProgress,
      to: value.first,
      duration: value.second,
    );
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
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
        duration:
            const Duration(milliseconds: _PROGRESS_APPEARANCE_DURATION_MILLIS),
        child: widget.inProgress ? _buildProgressBar() : null);
  }

  Widget _buildProgressBar() {
    String? hintText;
    if (_hints.isNotEmpty) {
      final hintIndex = _hintIndex.clamp(0, _hints.length - 1);
      hintText = _hints[hintIndex].first;
    }
    Widget? hint;
    if (hintText != null && hintText.isNotEmpty) {
      hint = Container(
          key: Key('hint $hintText'),
          padding: const EdgeInsets.only(left: 4, right: 4),
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4), color: Colors.white),
          child: Text(hintText,
              style: TextStyles.searchBarHint, textAlign: TextAlign.center));
    }
    return Column(children: [
      AnimatedBuilder(
        animation: _progressAnimationController,
        builder: (v1, v2) =>
            LinearProgressIndicator(value: _progressAnimation.value),
      ),
      AnimatedSwitcher(
          duration: isInTests() ? Duration.zero : DURATION_DEFAULT,
          child: hint ?? const SizedBox()),
    ]);
  }
}
