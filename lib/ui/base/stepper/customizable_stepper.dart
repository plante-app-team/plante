import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:plante/ui/base/components/header_plante.dart';
import 'package:plante/ui/base/stepper/_back_button_wrapper.dart';
import 'package:plante/ui/base/stepper/_indicators_top.dart';
import 'package:plante/ui/base/stepper/functions.dart';
import 'package:plante/ui/base/stepper/stepper_page.dart';
import 'package:plante/ui/base/ui_utils.dart';

// ignore: always_use_package_imports
import '_default_subwidgets.dart';

class CustomizableStepperController {
  final CustomizableStepper2IndicatorsTopController _indicatorsController;
  final BackButtonWrapperController _backButtonController;
  _StepFunction? _stepForwardFn;
  _StepFunction? _stepBackwardFn;
  _SetPageFunction? _setPageFunction;
  int _activePage = 0;

  CustomizableStepperController({int initialPage = 0})
      : _indicatorsController = CustomizableStepper2IndicatorsTopController(
            initialPage: initialPage),
        _backButtonController = BackButtonWrapperController() {
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
  late final Widget _backButton;
  late final double _backButtonHeaderPadding;
  final DividerMaker _dividerMaker;
  final List<StepperPage> _pages;

  final PageController _pageViewController;
  final CustomizableStepper2IndicatorsTopController _indicatorController;
  final BackButtonWrapperController _backButtonController;

  CustomizableStepper(
      {Key? key,
      required List<StepperPage> pages,
      required CustomizableStepperController controller,
      PageIndicatorMaker pageIndicatorMaker = defaultIndicatorMaker,
      DividerMaker dividerMaker = defaultDividerMaker,
      BackButtonMaker backButtonMaker = defaultBackButtonMaker})
      : _controller = controller,
        _pageIndicatorMaker = pageIndicatorMaker,
        _dividerMaker = dividerMaker,
        _pages = pages,
        _pageViewController =
            PageController(initialPage: controller._activePage),
        _indicatorController = controller._indicatorsController,
        _backButtonController = controller._backButtonController,
        super(key: key) {
    _controller._stepForwardFn = () => _setPage(_controller._activePage + 1);
    _controller._stepBackwardFn = () => _setPage(_controller._activePage - 1);
    _controller._setPageFunction = _setPage;
    final backButton = backButtonMaker.call(() {
      controller.stepBackward();
    });

    if (backButton != null) {
      // Back button is embedded into an AnimatedCrossFade, and
      // AnimatedCrossFade cuts its widget when they are bigger than its bounds.
      // Default BackButtonPlante is bigger than its size because it's elevated
      // and it has a shadow.
      // To avoid BackButtonPlante being cut, we add paddings around it.
      _backButton = Padding(
          padding: const EdgeInsets.only(
              left: HeaderPlante.DEFAULT_ACTIONS_SIDE_PADDINGS,
              right: HeaderPlante.DEFAULT_ACTIONS_SIDE_PADDINGS),
          child: Center(child: Wrap(children: [backButton])));
    } else {
      _backButton = const SizedBox.shrink();
    }
    _backButtonHeaderPadding = 0;
    _backButtonController.setButtonShown(_controller._activePage > 0);
  }

  void _setPage(int page) {
    if (page < 0 || _pages.length <= page) {
      return;
    }
    // NOTE: no 'await'
    _pageViewController.animateToPage(page,
        duration: DURATION_DEFAULT, curve: Curves.easeIn);
    _indicatorController.setPage(page);
    _backButtonController.setButtonShown(page > 0);
    _controller._activePage = page;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
        onWillPop: () async {
          if (_controller._activePage == 0) {
            return true;
          } else {
            _controller.stepBackward();
            return false;
          }
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          verticalDirection: VerticalDirection.down,
          children: <Widget>[
            HeaderPlante(
              title: CustomizableStepperIndicatorsTop(_indicatorController,
                  _pageIndicatorMaker, _dividerMaker, _pages.length),
              leftAction: BackButtonWrapper(_backButton, _backButtonController),
              leftActionPadding: _backButtonHeaderPadding,
            ),
            Expanded(
                child: PageView(
              controller: _pageViewController,
              physics: const NeverScrollableScrollPhysics(),
              scrollDirection: Axis.horizontal,
              children: _pages,
            )), // Container with a label
          ],
        ));
  }
}

typedef _StepFunction = void Function();
typedef _SetPageFunction = void Function(int page);
