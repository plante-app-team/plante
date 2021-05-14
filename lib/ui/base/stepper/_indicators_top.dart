import 'package:flutter/widgets.dart';
import 'package:plante/ui/base/stepper/functions.dart';

typedef _SetPageFunction = void Function(int page);

class CustomizableStepper2IndicatorsTopController {
  _SetPageFunction? setPageFn;
  final int initialPage;

  CustomizableStepper2IndicatorsTopController({this.initialPage = 0});

  void setPage(int page) {
    setPageFn?.call(page);
  }
}

class CustomizableStepperIndicatorsTop extends StatefulWidget {
  final CustomizableStepper2IndicatorsTopController controller;
  final PageIndicatorMaker pageIndicatorMaker;
  final DividerMaker dividerMaker;
  final int pagesCount;

  const CustomizableStepperIndicatorsTop(this.controller,
      this.pageIndicatorMaker, this.dividerMaker, this.pagesCount,
      {Key? key})
      : super(key: key);

  @override
  _CustomizableStepperIndicatorsTopState createState() =>
      _CustomizableStepperIndicatorsTopState(
          controller, pageIndicatorMaker, dividerMaker, pagesCount);
}

class _CustomizableStepperIndicatorsTopState
    extends State<CustomizableStepperIndicatorsTop> {
  final CustomizableStepper2IndicatorsTopController controller;
  final PageIndicatorMaker pageIndicatorMaker;
  final DividerMaker dividerMaker;
  final int pagesCount;
  int activePage;

  _CustomizableStepperIndicatorsTopState(this.controller,
      this.pageIndicatorMaker, this.dividerMaker, this.pagesCount)
      : activePage = controller.initialPage {
    controller.setPageFn = (int page) {
      if (page < 0 && pagesCount <= page) {
        return;
      }
      setState(() {
        activePage = page;
      });
    };
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> indicatorsWithDividers = [];
    for (int index = 0; index < pagesCount; ++index) {
      final PageIndicatorState indicatorState;
      if (index < activePage) {
        indicatorState = PageIndicatorState.PASSED;
      } else if (index == activePage) {
        indicatorState = PageIndicatorState.CURRENT;
      } else {
        indicatorState = PageIndicatorState.NOT_REACHED;
      }
      final indicator = pageIndicatorMaker.call(index, indicatorState);

      indicatorsWithDividers.add(indicator);
      if (index < pagesCount - 1) {
        final pageReached = index <= activePage;
        final nextPageReached = index + 1 <= activePage;
        final divider =
            dividerMaker.call(index, index + 1, pageReached, nextPageReached);
        indicatorsWithDividers.add(divider);
      }
    }
    return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: indicatorsWithDividers);
  }
}
