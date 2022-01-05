import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plante/ui/base/components/incremental_progress_bar.dart';

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
    final widget = IncrementalProgressBar(
      enableInTests: true,
      inProgress: true,
      progresses: {
        0.5: const Duration(seconds: 5),
        1.0: const Duration(seconds: 5),
      },
    );
    await tester.superPump(widget, pumpAndSettle: false);

    await tester.pump(const Duration(seconds: 1));
    expect(progress(), closeTo(0.1, delta));

    await tester.pump(const Duration(seconds: 2));
    expect(progress(), closeTo(0.3, delta));

    await tester.pump(const Duration(seconds: 2));
    expect(progress(), closeTo(0.5, delta));

    // Small pump to let the inside animation switch.
    // It is a hack, but I don't how to help it in any other way.
    await tester.pump(const Duration(milliseconds: 1));

    await tester.pump(const Duration(seconds: 2));
    expect(progress(), closeTo(0.7, delta));

    await tester.pump(const Duration(seconds: 30));
    expect(progress(), closeTo(1, delta));
  });

  testWidgets('inProgress : false', (WidgetTester tester) async {
    var widget = IncrementalProgressBar(
      enableInTests: true,
      inProgress: false,
      progresses: {
        1.0: const Duration(seconds: 5),
      },
    );
    await tester.superPump(widget, pumpAndSettle: false);

    var found = find.byType(LinearProgressIndicator).evaluate();
    expect(found, isEmpty);

    widget = IncrementalProgressBar(
      enableInTests: true,
      inProgress: true,
      progresses: {
        1.0: const Duration(seconds: 5),
      },
    );
    await tester.superPump(widget, pumpAndSettle: false);

    found = find.byType(LinearProgressIndicator).evaluate();
    expect(found, isNot(isEmpty));
  });
}
