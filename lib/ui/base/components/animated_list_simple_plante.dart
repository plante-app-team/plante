import 'package:diffutil_dart/diffutil.dart';
import 'package:flutter/material.dart';

/// Note: the class is buggy. Sometimes widgets added/removed from the middle
/// are not animated.
class AnimatedListSimplePlante extends StatefulWidget {
  final List<Widget> children;
  final EdgeInsets padding;
  final bool shrinkWrap;
  final ScrollPhysics? physics;
  const AnimatedListSimplePlante(
      {Key? key,
      required this.children,
      this.physics,
      this.shrinkWrap = false,
      this.padding = EdgeInsets.zero})
      : super(key: key);

  @override
  _AnimatedListSimplePlanteState createState() =>
      _AnimatedListSimplePlanteState();
}

class _AnimatedListSimplePlanteState extends State<AnimatedListSimplePlante> {
  final _listKey = GlobalKey<AnimatedListState>();

  @override
  void didUpdateWidget(AnimatedListSimplePlante oldWidget) {
    super.didUpdateWidget(oldWidget);

    final diffResult = calculateListDiff<Widget>(
        oldWidget.children, widget.children,
        equalityChecker: (Widget o1, Widget o2) =>
            oldWidget.padding == widget.padding && o1.key == o2.key,
        detectMoves: false);
    final listState = _listKey.currentState!;
    for (final update in diffResult.getUpdates(batch: false)) {
      update.when(
        insert: (pos, count) {
          for (var index = pos; index < pos + count; ++index) {
            listState.insertItem(index);
          }
        },
        remove: (pos, count) {
          for (var index = pos + count - 1; pos <= index; --index) {
            listState.removeItem(
                index,
                (context, animation) =>
                    _wrapChild(oldWidget.children[index], animation));
          }
        },
        change: (pos, payload) {/* nothing to do */},
        move: (from, to) => throw Exception(
            'detectMoves: false was passed, moves not expected'),
      );
    }
  }

  Widget _wrapChild(Widget child, Animation<double> animation) {
    return FadeTransition(
      opacity: animation,
      child: SizeTransition(
        sizeFactor: animation,
        child: Padding(
            padding: EdgeInsets.only(
                left: widget.padding.left, right: widget.padding.right),
            child: child),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
        padding: EdgeInsets.only(
            top: widget.padding.top, bottom: widget.padding.bottom),
        child: ScrollConfiguration(
            behavior: _ScrollBehavior(),
            child: AnimatedList(
                key: _listKey,
                physics: widget.physics,
                shrinkWrap: widget.shrinkWrap,
                initialItemCount: widget.children.length,
                itemBuilder: (context, index, animation) {
                  return _wrapChild(widget.children[index], animation);
                })));
  }
}

class _ScrollBehavior extends ScrollBehavior {
  @override
  Widget buildOverscrollIndicator(
      BuildContext context, Widget child, ScrollableDetails scrollableDetails) {
    return child;
  }
}
