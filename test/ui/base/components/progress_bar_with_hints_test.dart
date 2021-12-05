import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plante/base/pair.dart';
import 'package:plante/ui/base/components/progress_bar_with_hints.dart';

import '../../../widget_tester_extension.dart';

void main() {
  const delta = 0.0001;

  double progress() {
    final found = find.byType(LinearProgressIndicator).evaluate();
    if (found.isEmpty) {
      return -1;
    }
    final widget = found.first.widget as LinearProgressIndicator;
    return widget.value!;
  }

  testWidgets('normal scenario', (WidgetTester tester) async {
    final widget = ProgressBarWithHints(
        enableInTests: true,
        inProgress: true,
        progresses: {
          0.5: const Duration(seconds: 5),
          1.0: const Duration(seconds: 5),
        },
        hints: const [
          Pair('', Duration(seconds: 3)),
          Pair('Hint1', Duration(seconds: 3)),
          Pair('Hint2', Duration(seconds: 3)),
        ]);
    await tester.superPump(widget, pumpAndSettle: false);

    await tester.pump(const Duration(seconds: 1));
    expect(progress(), closeTo(0.1, delta));
    expect(find.text('Hint1'), findsNothing);
    expect(find.text('Hint2'), findsNothing);

    await tester.pump(const Duration(seconds: 2));
    expect(progress(), closeTo(0.3, delta));
    expect(find.text('Hint1'), findsOneWidget);
    expect(find.text('Hint2'), findsNothing);

    await tester.pump(const Duration(seconds: 2));
    expect(progress(), closeTo(0.5, delta));
    expect(find.text('Hint1'), findsOneWidget);
    expect(find.text('Hint2'), findsNothing);

    // Small pump to let the inside animation switch.
    // It is a hack, but I don't how to help it in any other way.
    await tester.pump(const Duration(milliseconds: 1));

    await tester.pump(const Duration(seconds: 2));
    expect(progress(), closeTo(0.7, delta));
    expect(find.text('Hint1'), findsNothing);
    expect(find.text('Hint2'), findsOneWidget);

    await tester.pump(const Duration(seconds: 30));
    expect(progress(), closeTo(1, delta));
    expect(find.text('Hint1'), findsNothing);
    expect(find.text('Hint2'), findsOneWidget);
  });

  testWidgets('inProgress : false', (WidgetTester tester) async {
    var widget = ProgressBarWithHints(
        enableInTests: true,
        inProgress: false,
        progresses: {
          1.0: const Duration(seconds: 5),
        },
        hints: const [
          Pair('Hint2', Duration(seconds: 3)),
        ]);
    await tester.superPump(widget, pumpAndSettle: false);

    var found = find.byType(LinearProgressIndicator).evaluate();
    expect(found, isEmpty);

    widget = ProgressBarWithHints(
        enableInTests: true,
        inProgress: true,
        progresses: {
          1.0: const Duration(seconds: 5),
        },
        hints: const [
          Pair('Hint2', Duration(seconds: 3)),
        ]);
    await tester.superPump(widget, pumpAndSettle: false);

    found = find.byType(LinearProgressIndicator).evaluate();
    expect(found, isNot(isEmpty));
  });

  testWidgets('data changes in the middle of progress',
      (WidgetTester tester) async {
    final createWidget =
        (List<String> hints, {double addToProgresses = 0.0}) async {
      final progresses = <double, Duration>{};
      for (var index = 1; index <= hints.length; ++index) {
        final progress =
            (index / hints.length + addToProgresses).clamp(0.0, 1.0);
        progresses[progress] = const Duration(seconds: 10);
      }
      final widget = ProgressBarWithHints(
          enableInTests: true,
          inProgress: true,
          progresses: progresses,
          hints:
              hints.map((e) => Pair(e, const Duration(seconds: 10))).toList());
      await tester.superPump(widget, pumpAndSettle: false);
    };

    const hints1 = ['hint1', 'hint2'];
    const hints2 = ['hint3', 'hint3'];

    await createWidget(hints1);
    expect(progress(), lessThan(0.001));

    await tester.pump(const Duration(seconds: 1));
    expect(progress(), greaterThan(0.001));
    expect(find.text(hints1[0]), findsOneWidget);

    // When we just recreate the widget, its contents should stay same
    await createWidget(hints1);
    expect(progress(), greaterThan(0.001));
    expect(find.text(hints1[0]), findsOneWidget);

    // But then we recreate it with different hints,
    // it's progress should be back to 0
    await createWidget(hints2);
    expect(progress(), lessThan(0.001));

    // Move time a bit
    await tester.pump(const Duration(seconds: 1));
    expect(progress(), greaterThan(0.001));
    expect(find.text(hints2[0]), findsOneWidget);

    // And then we recreate the progress bar with different,
    // progresses, it also should reset back to 0
    await createWidget(hints2, addToProgresses: 0.1);
    expect(progress(), lessThan(0.001));

    // Finish all timers so that the test won't fail
    await tester.pump(const Duration(days: 1));
  });
}
