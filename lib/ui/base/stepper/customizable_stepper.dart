import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:untitled_vegan_app/ui/base/stepper/_indicators_top.dart';
import 'package:untitled_vegan_app/ui/base/stepper/functions.dart';
import 'package:untitled_vegan_app/ui/base/stepper/stepper_page.dart';

class CustomizableStepperController {
  CustomizableStepper2IndicatorsTopController _indicatorsController;
  _StepFunction? _stepForwardFn;
  _StepFunction? _stepBackwardFn;
  _SetPageFunction? _setPageFunction;
  int _activePage = 0;

  CustomizableStepperController({int initialPage = 0}):
        _indicatorsController = CustomizableStepper2IndicatorsTopController(
            initialPage: initialPage) {
    _activePage = initialPage;
  }

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

class CustomizableStepper extends StatelessWidget {
  final CustomizableStepperController _controller;
  final PageIndicatorMaker _pageIndicatorMaker;
  final DividerMaker _dividerMaker;
  final List<StepperPage> _pages;

  final EdgeInsets _contentPadding;

  final PageController _pageViewController;
  final CustomizableStepper2IndicatorsTopController _indicatorController;

  CustomizableStepper({
    required List<StepperPage> pages,
    required CustomizableStepperController controller,
    PageIndicatorMaker pageIndicatorMaker = defaultIndicatorMaker,
    DividerMaker dividerMaker = defaultDividerMaker,
    EdgeInsets contentPadding = EdgeInsets.zero}):
      _controller = controller,
      _pageIndicatorMaker = pageIndicatorMaker,
      _dividerMaker = dividerMaker,
      _pages = pages,
      _contentPadding = contentPadding,
      _pageViewController = PageController(initialPage: controller._activePage),
      _indicatorController = controller._indicatorsController {
    _controller._stepForwardFn = () => _setPage(_controller._activePage + 1);
    _controller._stepBackwardFn = () => _setPage(_controller._activePage - 1);
    _controller._setPageFunction = (int page) => _setPage(page);
  }

  void _setPage(int page) {
    if (page < 0 || _pages.length <= page) {
      return;
    }
    // NOTE: no 'await'
    _pageViewController.animateToPage(
        page,
        duration: Duration(milliseconds: 250),
        curve: Curves.easeIn);
    _indicatorController.setPage(page);
    _controller._activePage = page;
  }

  @override
  Widget build(BuildContext context) {
    final pagesPadding = EdgeInsets.only(
        left: _contentPadding.left,
        right: _contentPadding.right,
        bottom: _contentPadding.bottom);
    final pages = _pages.map((page) =>
        Container(child: page, padding: pagesPadding)).toList();
    
    final indicatorsPadding = EdgeInsets.only(
      left: _contentPadding.left,
      top: _contentPadding.top,
      right: _contentPadding.right
    );
    return WillPopScope(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          verticalDirection: VerticalDirection.down,
          children: <Widget>[
            Container(
              padding: indicatorsPadding,
              child: CustomizableStepperIndicatorsTop(
                  _indicatorController,
                  _pageIndicatorMaker,
                  _dividerMaker,
                  _pages.length)),
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
          if (_controller._activePage == 0) {
            return true;
          } else {
            _controller.stepBackward();
            return false;
          }
        });
  }
}

typedef _StepFunction = void Function();
typedef _SetPageFunction = void Function(int page);

Widget defaultDividerMaker(int leftPage, int rightPage, bool leftFinished, bool rightFinished) {
  return Container(child: Divider(), padding: EdgeInsets.only(left: 20, right: 20));
}

Widget defaultIndicatorMaker(int page, bool pageReached) {
  return new Container(
      width: 30,
      height: 30,
      decoration: new BoxDecoration(
          color: !pageReached ? Colors.grey : Colors.green,
          shape: BoxShape.circle));
}