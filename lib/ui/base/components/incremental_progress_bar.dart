import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:plante/base/base.dart';
import 'package:plante/base/pair.dart';

class IncrementalProgressBar extends StatefulWidget {
  final bool inProgress;
  late final List<Pair<double, Duration>> progresses;
  final bool enableInTests;

  IncrementalProgressBar(
      {Key? key,
      required this.inProgress,
      required Map<double, Duration> progresses,
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
  State<IncrementalProgressBar> createState() => isInTests() && !enableInTests
      ? _ProgressBarStateForTests()
      : _IncrementalProgressBarState();
}

class _ProgressBarStateForTests extends State<IncrementalProgressBar> {
  @override
  Widget build(BuildContext context) {
    return const SizedBox();
  }
}

class _IncrementalProgressBarState extends State<IncrementalProgressBar>
    with SingleTickerProviderStateMixin {
  static const _PROGRESS_APPEARANCE_DURATION_MILLIS = 1000;
  var _progressIndex = -1;
  late final AnimationController _progressAnimationController;
  late final AnimationStatusListener _nextProgressAnimationStarter;
  late Animation<double> _progressAnimation;

  List<Pair<double, Duration>> get _progresses => widget.progresses;

  @override
  void dispose() {
    _progressAnimationController.dispose();
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
    }
  }

  @override
  void didUpdateWidget(IncrementalProgressBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.inProgress == true && widget.inProgress == false) {
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
    final newData = widget.inProgress == true ||
        !listEquals(oldWidget.progresses, widget.progresses);
    if (restart || newData) {
      _progressIndex = -1;
      _startNextProgressAnimation();
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

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
        duration:
            const Duration(milliseconds: _PROGRESS_APPEARANCE_DURATION_MILLIS),
        child: widget.inProgress ? _buildProgressBar() : const SizedBox());
  }

  Widget _buildProgressBar() {
    return AnimatedBuilder(
      animation: _progressAnimationController,
      builder: (v1, v2) => LinearProgressIndicator(
        value: _progressAnimation.value,
        minHeight: 4,
      ),
    );
  }
}
