import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:untitled_vegan_app/ui/base/stepper/customizable_stepper.dart';
import 'package:untitled_vegan_app/ui/base/stepper/stepper_page.dart';

void main() {
  setUp(() async {
    await GetIt.I.reset();
  });

  Future<CustomizableStepperController> init(WidgetTester tester) async {
    final controller = CustomizableStepperController();

    final page1 = StepperPage(
        Text("Page 1"),
        ElevatedButton(
            child: Text("Cool button 1"),
            onPressed: controller.stepForward)
    );
    final page2 = StepperPage(
        Text("Page 2"),
        ElevatedButton(
            child: Text("Cool button 2"),
            onPressed: controller.stepForward)
    );
    final page3 = StepperPage(
        Text("Page 3"),
        ElevatedButton(
            child: Text("Cool button 3"),
            onPressed: controller.stepForward)
    );

    await tester.pumpWidget(
        Directionality(
            textDirection: TextDirection.ltr,
            child: CustomizableStepper(
                pages: [page1, page2, page3],
                controller: controller)));

    return controller;
  }

  testWidgets("Pages switching by button", (WidgetTester tester) async {
    await init(tester);

    expect(find.text("Page 1"), findsOneWidget);
    expect(find.text("Page 2"), findsNothing);
    expect(find.text("Page 3"), findsNothing);
    expect(find.text("Cool button 1"), findsOneWidget);
    expect(find.text("Cool button 2"), findsNothing);
    expect(find.text("Cool button 3"), findsNothing);

    await tester.tap(find.text("Cool button 1"));
    await tester.pumpAndSettle();

    expect(find.text("Page 1"), findsNothing);
    expect(find.text("Page 2"), findsOneWidget);
    expect(find.text("Page 3"), findsNothing);
    expect(find.text("Cool button 1"), findsNothing);
    expect(find.text("Cool button 2"), findsOneWidget);
    expect(find.text("Cool button 3"), findsNothing);

    await tester.tap(find.text("Cool button 2"));
    await tester.pumpAndSettle();

    expect(find.text("Page 1"), findsNothing);
    expect(find.text("Page 2"), findsNothing);
    expect(find.text("Page 3"), findsOneWidget);
    expect(find.text("Cool button 1"), findsNothing);
    expect(find.text("Cool button 2"), findsNothing);
    expect(find.text("Cool button 3"), findsOneWidget);
  });

  testWidgets("Pages switching by controller", (WidgetTester tester) async {
    final controller = await init(tester);

    controller.stepForward();
    await tester.pumpAndSettle();
    expect(find.text("Page 1"), findsNothing);
    expect(find.text("Page 2"), findsOneWidget);
    expect(find.text("Page 3"), findsNothing);
    expect(find.text("Cool button 1"), findsNothing);
    expect(find.text("Cool button 2"), findsOneWidget);
    expect(find.text("Cool button 3"), findsNothing);

    controller.stepBackward();
    await tester.pumpAndSettle();
    expect(find.text("Page 1"), findsOneWidget);
    expect(find.text("Page 2"), findsNothing);
    expect(find.text("Page 3"), findsNothing);
    expect(find.text("Cool button 1"), findsOneWidget);
    expect(find.text("Cool button 2"), findsNothing);
    expect(find.text("Cool button 3"), findsNothing);

    controller.setPage(2);
    await tester.pumpAndSettle();
    expect(find.text("Page 1"), findsNothing);
    expect(find.text("Page 2"), findsNothing);
    expect(find.text("Page 3"), findsOneWidget);
    expect(find.text("Cool button 1"), findsNothing);
    expect(find.text("Cool button 2"), findsNothing);
    expect(find.text("Cool button 3"), findsOneWidget);
  });

  testWidgets("Cannot step past borders", (WidgetTester tester) async {
    final controller = await init(tester);

    // Check that we tried to step backwards but couldn't
    controller.stepBackward();
    await tester.pumpAndSettle();
    expect(find.text("Page 1"), findsOneWidget);
    expect(find.text("Page 2"), findsNothing);
    expect(find.text("Page 3"), findsNothing);
    expect(find.text("Cool button 1"), findsOneWidget);
    expect(find.text("Cool button 2"), findsNothing);
    expect(find.text("Cool button 3"), findsNothing);

    // Check that we tried to step forward but couldn't
    controller.setPage(2);
    await tester.pumpAndSettle();
    controller.stepForward();
    await tester.pumpAndSettle();
    expect(find.text("Page 1"), findsNothing);
    expect(find.text("Page 2"), findsNothing);
    expect(find.text("Page 3"), findsOneWidget);
    expect(find.text("Cool button 1"), findsNothing);
    expect(find.text("Cool button 2"), findsNothing);
    expect(find.text("Cool button 3"), findsOneWidget);
  });

  testWidgets("Can dynamically update", (WidgetTester tester) async {
    final swapper = ChildrenSwapperController();
    await tester.pumpWidget(
        Directionality(
            textDirection: TextDirection.ltr,
            child: StepperChildrenSwapper(
                controller: swapper, child1: Text("Text1"), child2: Text("Text2")
            )));

    expect(find.text("Text1"), findsOneWidget);
    expect(find.text("Text2"), findsNothing);
    swapper.swap();
    await tester.pumpAndSettle();
    expect(find.text("Text1"), findsNothing);
    expect(find.text("Text2"), findsOneWidget);
  });
}


class ChildrenSwapperController {
  void Function()? _swapFn;
  void swap() {
    _swapFn?.call();
  }
}
class StepperChildrenSwapper extends StatefulWidget {
  final ChildrenSwapperController controller;
  final Widget child1;
  final Widget child2;
  StepperChildrenSwapper({required this.controller, required this.child1, required this.child2});
  @override
  _StepperChildrenSwapperState createState() => _StepperChildrenSwapperState(controller, child1, child2);
}
class _StepperChildrenSwapperState extends State<StepperChildrenSwapper> {
  final ChildrenSwapperController controller;
  final Widget child1;
  final Widget child2;
  bool showChild1 = true;
  _StepperChildrenSwapperState(this.controller, this.child1, this.child2) {
    controller._swapFn = () {
      setState(() {
        showChild1 = !showChild1;
      });
    };
  }
  @override
  Widget build(BuildContext context) {
    final controller = CustomizableStepperController();
    final page1 = StepperPage(
        showChild1 ? child1 : child2,
        Placeholder()
    );
    return CustomizableStepper(pages: [page1], controller: controller);
  }
}
