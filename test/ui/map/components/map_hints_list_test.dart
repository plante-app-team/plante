import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plante/ui/map/components/map_hint_widget.dart';
import 'package:plante/ui/map/components/map_hints_list.dart';

import '../../../widget_tester_extension.dart';

void main() {
  late MapHintsListController controller;

  setUp(() async {
    controller = MapHintsListController();
  });

  testWidgets('initial hints', (WidgetTester tester) async {
    controller.addHint('id1', 'hint1');
    controller.addHint('id2', 'hint2');

    await tester.superPump(MapHintsList(controller: controller));

    expect(find.text('hint1'), findsOneWidget);
    expect(find.text('hint2'), findsOneWidget);

    final center1 = tester.getCenter(find.text('hint1'));
    final center2 = tester.getCenter(find.text('hint2'));
    expect(center1.dy, lessThan(center2.dy));
  });

  testWidgets('add and remove hints', (WidgetTester tester) async {
    await tester.superPump(MapHintsList(controller: controller));

    controller.addHint('id1', 'hint1');
    await tester.pumpAndSettle();
    controller.addHint('id2', 'hint2');
    await tester.pumpAndSettle();
    controller.addHint('id3', 'hint3');
    await tester.pumpAndSettle();

    expect(find.text('hint1'), findsOneWidget);
    expect(find.text('hint2'), findsOneWidget);
    expect(find.text('hint3'), findsOneWidget);

    var center1 = tester.getCenter(find.text('hint1'));
    final center2 = tester.getCenter(find.text('hint2'));
    var center3 = tester.getCenter(find.text('hint3'));
    expect(center1.dy, lessThan(center2.dy));
    expect(center2.dy, lessThan(center3.dy));

    controller.removeHint('id2');
    await tester.pumpAndSettle();
    expect(find.text('hint1'), findsOneWidget);
    expect(find.text('hint2'), findsNothing);
    expect(find.text('hint3'), findsOneWidget);

    center1 = tester.getCenter(find.text('hint1'));
    center3 = tester.getCenter(find.text('hint3'));
    expect(center1.dy, lessThan(center3.dy));
  });

  testWidgets('add duplicating hints', (WidgetTester tester) async {
    await tester.superPump(MapHintsList(controller: controller));

    controller.addHint('id1', 'hint1');
    await tester.pumpAndSettle();
    controller.addHint('id2', 'hint2');
    await tester.pumpAndSettle();
    controller.addHint('id3', 'hint3');
    await tester.pumpAndSettle();

    var center1 = tester.getCenter(find.text('hint1'));
    var center2 = tester.getCenter(find.text('hint2'));
    var center3 = tester.getCenter(find.text('hint3'));
    expect(center1.dy, lessThan(center2.dy));
    expect(center2.dy, lessThan(center3.dy));

    controller.addHint('id1', 'hint1');
    await tester.pumpAndSettle();

    // We expect the 'id1' hint to get to the bottom
    center1 = tester.getCenter(find.text('hint1'));
    center2 = tester.getCenter(find.text('hint2'));
    center3 = tester.getCenter(find.text('hint3'));
    expect(center2.dy, lessThan(center3.dy));
    expect(center3.dy, lessThan(center1.dy));
  });

  testWidgets('remove a hint by clicking on its cancel button',
      (WidgetTester tester) async {
    await tester.superPump(MapHintsList(controller: controller));

    controller.addHint('id1', 'hint1');
    await tester.pumpAndSettle();
    controller.addHint('id2', 'hint2');
    await tester.pumpAndSettle();

    expect(find.text('hint1'), findsOneWidget);
    expect(find.text('hint2'), findsOneWidget);

    final hint1 = find.byType(MapHintWidget).evaluate().first.widget;
    await tester.tap(find.descendant(
        of: find.byWidget(hint1),
        matching: find.byKey(const Key('map_hint_cancel'))));
    await tester.pumpAndSettle();

    expect(find.text('hint1'), findsNothing);
    expect(find.text('hint2'), findsOneWidget);
  });
}
