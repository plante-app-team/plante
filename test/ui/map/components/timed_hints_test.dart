import 'package:flutter_test/flutter_test.dart';
import 'package:plante/base/pair.dart';
import 'package:plante/ui/map/components/timed_hints.dart';

import '../../../widget_tester_extension.dart';

void main() {
  testWidgets('normal scenario', (WidgetTester tester) async {
    const widget = TimedHints(
        inProgress: true,
        hints: [
          Pair('', Duration(seconds: 3)),
          Pair('Hint1', Duration(seconds: 3)),
          Pair('Hint2', Duration(seconds: 3)),
        ],
        enableInTests: true);
    await tester.superPump(widget, pumpAndSettle: false);

    await tester.pump(const Duration(seconds: 1));
    expect(find.text('Hint1'), findsNothing);
    expect(find.text('Hint2'), findsNothing);

    await tester.pump(const Duration(seconds: 2));
    expect(find.text('Hint1'), findsOneWidget);
    expect(find.text('Hint2'), findsNothing);

    await tester.pump(const Duration(seconds: 3));
    expect(find.text('Hint1'), findsOneWidget);
    expect(find.text('Hint2'), findsOneWidget);

    await tester.pump(const Duration(seconds: 4));
    expect(find.text('Hint1'), findsNothing);
    expect(find.text('Hint2'), findsOneWidget);
  });

  testWidgets('test not in progress', (WidgetTester tester) async {
    const widget = TimedHints(
        inProgress: false,
        hints: [
          Pair('', Duration(seconds: 3)),
          Pair('Hint1', Duration(seconds: 3)),
          Pair('Hint2', Duration(seconds: 3)),
        ],
        enableInTests: true);
    await tester.superPump(widget, pumpAndSettle: false);

    await tester.pump(const Duration(seconds: 1));
    expect(find.text('Hint1'), findsNothing);
    expect(find.text('Hint2'), findsNothing);

    await tester.pump(const Duration(seconds: 5));
    expect(find.text('Hint1'), findsNothing);
    expect(find.text('Hint2'), findsNothing);
  });
}
