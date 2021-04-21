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

  CustomizableStepperIndicatorsTop(
      this.controller,
      this.pageIndicatorMaker,
      this.dividerMaker,
      this.pagesCount);

  @override
  _CustomizableStepperIndicatorsTopState createState() =>
      _CustomizableStepperIndicatorsTopState(
          controller, pageIndicatorMaker, dividerMaker, pagesCount);
}

class _CustomizableStepperIndicatorsTopState extends State<CustomizableStepperIndicatorsTop> {
  final CustomizableStepper2IndicatorsTopController controller;
  final PageIndicatorMaker pageIndicatorMaker;
  final DividerMaker dividerMaker;
  final int pagesCount;
  int activePage;

  _CustomizableStepperIndicatorsTopState(
      this.controller,
      this.pageIndicatorMaker,
      this.dividerMaker,
      this.pagesCount):
        activePage = controller.initialPage {
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
    List<Widget> indicatorsWithDividers = [];
    for (int index = 0; index < pagesCount; ++index) {
      final pageReached = index <= activePage;
      final indicator = AnimatedCrossFade(
        firstChild: pageIndicatorMaker.call(index, false),
        secondChild: pageIndicatorMaker.call(index, true),
        crossFadeState: !pageReached ? CrossFadeState.showFirst : CrossFadeState.showSecond,
        duration: Duration(milliseconds: 250),
      );

      indicatorsWithDividers.add(indicator);
      if (index < pagesCount - 1) {
        final nextPageReached = index + 1 <= activePage;
        final divider = dividerMaker.call(
            index, index + 1, pageReached, nextPageReached);
        indicatorsWithDividers.add(Expanded(child: divider));
      }
    }
    return Container(
        padding: EdgeInsets.only(top: 20),
        child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: indicatorsWithDividers));
  }
}
