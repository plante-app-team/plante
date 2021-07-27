import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:plante/base/base.dart';
import 'package:plante/model/lang_code.dart';
import 'package:plante/ui/base/text_styles.dart';

enum LangListItemAnimationState {
  NONE,
  BEING_ADDED,
  BEING_REMOVED,
}

class LangListItem extends StatefulWidget {
  /// Language use to display a language name
  final LangCode lang;

  final Color backgroundColor;

  /// Whether the language is selected (a checkbox is checked)
  final bool selected;

  /// Called when user attempts to change the [selected] value
  final ArgCallback<bool>? selectedChangeCallback;

  /// Index of this item in the list it's being displayed in.
  /// The property is used because ReorderableListView
  /// ([ReorderableDragStartListener] to be precise)
  /// requires an index to be provided.
  final int index;

  /// Whether the item should allow to be drag-and-dropped (to be precies,
  /// whether [ReorderableDragStartListener] should be used).
  final bool reorderable;

  /// A small text hint.
  final String? hint;

  /// This field allows for the declarative way to start
  /// a remove/add animation.
  /// The [LangListItem] widget should at first be created with
  /// [animationState] value to be set to [LangListItemAnimationState.NONE],
  /// then after a user action (most likely when the user selected or deselected
  /// the item) this [LangListItem] widget should receive a different
  /// [animationState] value. Since [LangListItem] is stateful, it will receive
  /// the updated animation state in `didUpdateWidget` and
  /// will start the animation.
  final LangListItemAnimationState animationState;

  /// Called after an add animation specified by [animationState] is finished.
  final VoidCallback? onAddAnimationEnd;

  /// Called after a remove animation specified by [animationState] is finished.
  final VoidCallback? onRemoveAnimationEnd;

  /// Ticker used for item's animation.
  final TickerProvider animationTickerProvider;

  const LangListItem(
      {Key? key,
      required this.lang,
      this.backgroundColor = Colors.white,
      required this.index,
      required this.selected,
      required this.selectedChangeCallback,
      required this.reorderable,
      this.hint,
      this.animationState = LangListItemAnimationState.NONE,
      this.onAddAnimationEnd,
      this.onRemoveAnimationEnd,
      required this.animationTickerProvider})
      : super(key: key);

  @override
  _LangListItemState createState() => _LangListItemState();
}

class _LangListItemState extends State<LangListItem> {
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
        vsync: widget.animationTickerProvider,
        duration: const Duration(milliseconds: 500));
    _animation = Tween<double>(begin: 0, end: 1).animate(_animationController);

    _animationController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onAddAnimationEnd?.call();
      } else if (status == AnimationStatus.dismissed) {
        widget.onRemoveAnimationEnd?.call();
      }
    });

    _maybeStartAnimation();
  }

  @override
  void didUpdateWidget(LangListItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.animationState != oldWidget.animationState) {
      _maybeStartAnimation();
    }
  }

  void _maybeStartAnimation() {
    if (widget.animationState == LangListItemAnimationState.BEING_ADDED) {
      _animationController.forward(from: 0);
    } else if (widget.animationState ==
        LangListItemAnimationState.BEING_REMOVED) {
      _animationController.reverse(from: 1);
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final animationState = widget.animationState;
    final callback = animationState == LangListItemAnimationState.NONE
        ? widget.selectedChangeCallback
        : null;
    final selected = widget.selected;
    final index = widget.index;
    final lang = widget.lang;
    final reorderable = widget.reorderable;
    final hint = widget.hint != null ? ' ${widget.hint}' : '';

    final tapCallback = widget.selectedChangeCallback == null
        ? null
        : () {
            callback!.call(!selected);
          };

    final content = InkWell(
        onTap: selected ? null : tapCallback,
        child: Row(children: [
          if (selected && tapCallback != null)
            Row(children: [
              const SizedBox(width: 14),
              Material(
                  color: Colors.transparent,
                  child: InkWell(
                    key: Key('cancel_button_${lang.name}'),
                    borderRadius: BorderRadius.circular(24),
                    onTap: tapCallback,
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: SvgPicture.asset(
                        'assets/cancel_circle.svg',
                      ),
                    ),
                  )),
            ])
          else
            const SizedBox(width: 24),
          Text('${lang.localize(context)}$hint', style: TextStyles.langName),
          if (reorderable)
            Expanded(
                child: Align(
                    alignment: Alignment.centerRight,
                    child: ReorderableDragStartListener(
                        index: index,
                        // Container to make the
                        // draggable icon larger
                        child: Container(
                            width: 71,
                            height: 40,
                            color: Colors.transparent,
                            child: SvgPicture.asset(
                                'assets/list_drag_n_drop.svg',
                                fit: BoxFit.none)))))
        ]));

    final result = Container(
        color: Colors.white,
        child: Padding(
            padding: const EdgeInsets.only(bottom: 1),
            child: Container(
              height: 42,
              color: widget.backgroundColor,
              child: Material(
                color: Colors.transparent,
                child: content,
              ),
            )));

    if (animationState == LangListItemAnimationState.NONE) {
      return result;
    }

    return FadeTransition(
      opacity: _animation,
      alwaysIncludeSemantics: true,
      child: SizeTransition(
        sizeFactor: _animation,
        child: result,
      ),
    );
  }
}
