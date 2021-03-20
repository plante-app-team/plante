import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:untitled_vegan_app/ui/base/stepper/stepper_page.dart';

typedef PageIndicatorMaker = Widget Function(int page, bool pageFinished);
typedef DividerMaker = Widget Function(
    int leftPage, int rightPage, bool leftFinished, bool rightFinished);

class CustomizableStepperController {
  _StepFunction? _stepForwardFn;
  _StepFunction? _stepBackwardFn;
  _SetPageFunction? _setPageFunction;
  void stepForward() {
    _stepForwardFn?.call();
  }
  void stepBackward() {
    _stepBackwardFn?.call();
  }
  void setPage(int page) {
    _setPageFunction?.call(page);
  }
}

class CustomizableStepper extends StatefulWidget {
  final CustomizableStepperController controller;
  final PageIndicatorMaker pageIndicatorMaker;
  final List<StepperPage> pages;
  final DividerMaker dividerMaker;
  final EdgeInsetsGeometry contentPadding;

  CustomizableStepper({
    required this.pages,
    required this.controller,
    this.pageIndicatorMaker = defaultIndicatorMaker,
    this.dividerMaker = defaultDividerMaker,
    this.contentPadding = EdgeInsets.zero});

  @override
  _CustomizableStepperState createState() => _CustomizableStepperState(
      this.controller,
      this.pageIndicatorMaker,
      this.pages,
      this.dividerMaker,
      this.contentPadding);
}

class _CustomizableStepperState extends State<CustomizableStepper> {
  final CustomizableStepperController _controller;
  final PageIndicatorMaker _pageIndicatorMaker;
  final List<StepperPage> _pages;
  final DividerMaker _dividerMaker;

  final EdgeInsetsGeometry _contentPadding;

  final PageController _pageViewController = PageController();

  int _activePage = 0;

  _CustomizableStepperState(
      this._controller,
      this._pageIndicatorMaker,
      this._pages,
      this._dividerMaker,
      this._contentPadding) {
    _controller._stepForwardFn = () => setPage(_activePage + 1);
    _controller._stepBackwardFn = () => setPage(_activePage - 1);
    _controller._setPageFunction = (int page) => setPage(page);
  }

  void setPage(int page) {
    if (page < 0 || _pages.length <= page) {
      return;
    }
    // NOTE: no 'await'
    _pageViewController.animateToPage(
        page,
        duration: Duration(milliseconds: 250),
        curve: Curves.easeIn);
    setState(() {
      _activePage = page;
    });
  }

  @override
  Widget build(BuildContext context) {
    final pages = _pages.map((page) =>
        Container(child: page, padding: _contentPadding)).toList();
    return WillPopScope(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        verticalDirection: VerticalDirection.down,
        children: <Widget>[
          _pageIndicators(),
          Expanded(child:
            PageView(
              controller: _pageViewController,
              physics: NeverScrollableScrollPhysics(),
              scrollDirection: Axis.horizontal,
              children: pages,
          )), // Container with a label
        ],
      ),
      onWillPop: () async {
        if (_activePage == 0) {
          return true;
        } else {
          _controller.stepBackward();
          return false;
        }
      });
  }

  Widget _pageIndicators() {
    List<Widget> indicatorsWithDividers = [];
    for (int index = 0; index < _pages.length; ++index) {
      final pageFinished = index < _activePage;
      final indicator = AnimatedCrossFade(
        firstChild: _pageIndicatorMaker.call(index, false),
        secondChild: _pageIndicatorMaker.call(index, true),
        crossFadeState: !pageFinished ? CrossFadeState.showFirst : CrossFadeState.showSecond,
        duration: Duration(milliseconds: 250),
      );

      indicatorsWithDividers.add(indicator);
      if (index < _pages.length - 1) {
        final nextPageFinished = index + 1 < _activePage;
        final divider = _dividerMaker.call(
            index, index + 1, pageFinished, nextPageFinished);
        indicatorsWithDividers.add(Expanded(child: divider));
      }
    }
    return Container(
      padding: EdgeInsets.only(top: 20),
      child: Container(
        padding: _contentPadding, child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: indicatorsWithDividers)));
  }
}

typedef _StepFunction = void Function();
typedef _SetPageFunction = void Function(int page);

Widget defaultDividerMaker(int leftPage, int rightPage, bool leftFinished, bool rightFinished) {
  return Container(child: Divider(), padding: EdgeInsets.only(left: 20, right: 20));
}

Widget defaultIndicatorMaker(int page, bool pageFinished) {
  return new Container(
      width: 30,
      height: 30,
      decoration: new BoxDecoration(
        color: !pageFinished ? Colors.grey : Colors.green,
        shape: BoxShape.circle));
}
