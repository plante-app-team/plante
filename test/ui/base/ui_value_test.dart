import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plante/ui/base/ui_utils.dart';
import 'package:plante/ui/base/ui_value.dart';

import '../../widget_tester_extension.dart';

void main() {
  testWidgets('setting value rebuilds widgets when it observes',
      (WidgetTester tester) async {
    await tester.superPump(const _HelperWidget());
    final state = tester.state<_HelperWidgetState>(find.byType(_HelperWidget));

    final initialBuilds = state.buildsCount;

    // Not observed value does not rebuild the widget
    state.notObservedValue.setValue(123);
    await tester.pumpAndSettle();
    expect(state.buildsCount, equals(initialBuilds));

    state.observedValue.setValue(123);
    await tester.pumpAndSettle();
    expect(state.buildsCount, equals(initialBuilds + 1));
  });

  testWidgets(
      'setting value rebuilds consumer when it observes, but not main widget',
      (WidgetTester tester) async {
    await tester.superPump(const _HelperWidget());
    final state = tester.state<_HelperWidgetState>(find.byType(_HelperWidget));

    final initialConsumerBuilds = state.consumerBuildsCount;
    final initialBuilds = state.buildsCount;

    // Not observed value does not rebuild consumer
    state.notObservedValue.setValue(123);
    await tester.pumpAndSettle();
    expect(state.consumerBuildsCount, equals(initialConsumerBuilds));

    // Let's update the consumer's value only
    state.observedByConsumerValue.setValue(123);
    await tester.pumpAndSettle();
    expect(state.buildsCount, equals(initialBuilds));
    expect(state.consumerBuildsCount, equals(initialConsumerBuilds + 1));

    // Now let's update the value observed by entire widget
    state.observedValue.setValue(123);
    await tester.pumpAndSettle();
    expect(state.buildsCount, equals(initialBuilds + 1));
    expect(state.consumerBuildsCount, equals(initialConsumerBuilds + 2));
  });

  testWidgets('can observe changes', (WidgetTester tester) async {
    await tester.superPump(const _HelperWidget());
    final state = tester.state<_HelperWidgetState>(find.byType(_HelperWidget));

    var lastValue = 0;
    final callback = (int value) {
      lastValue = value;
    };
    state.notObservedValue.callOnChanges(callback);

    // Observed
    state.notObservedValue.setValue(123);
    expect(lastValue, equals(123));
    state.notObservedValue.setValue(321);
    expect(lastValue, equals(321));

    // Not observed anymore
    state.notObservedValue.unregisterCallback(callback);
    state.notObservedValue.setValue(111);
    expect(lastValue, equals(321));
  });

  testWidgets('state changes to same value do nothing',
      (WidgetTester tester) async {
    await tester.superPump(const _HelperWidget());
    final state = tester.state<_HelperWidgetState>(find.byType(_HelperWidget));

    var notificationsCount = 0;
    final callback = (int value) {
      notificationsCount += 1;
    };
    state.observedValue.callOnChanges(callback);

    final initialBuilds = state.buildsCount;

    // First change is real
    state.observedValue.setValue(123);
    await tester.pumpAndSettle();
    expect(state.buildsCount, equals(initialBuilds + 1));
    expect(notificationsCount, equals(1));

    // Second change has same value
    state.observedValue.setValue(123);
    await tester.pumpAndSettle();
    expect(state.buildsCount, equals(initialBuilds + 1));
    expect(notificationsCount, equals(1));

    // Third change has different value
    state.observedValue.setValue(321);
    await tester.pumpAndSettle();
    expect(state.buildsCount, equals(initialBuilds + 2));
    expect(notificationsCount, equals(2));
  });
}

class _HelperWidget extends ConsumerStatefulWidget {
  const _HelperWidget({Key? key}) : super(key: key);

  @override
  _HelperWidgetState createState() {
    return _HelperWidgetState();
  }
}

class _HelperWidgetState extends ConsumerState<_HelperWidget> {
  var buildsCount = 0;
  var consumerBuildsCount = 0;
  late final UIValue<int> notObservedValue;
  late final UIValue<int> observedValue;
  late final UIValue<int> observedByConsumerValue;

  @override
  void initState() {
    super.initState();
    notObservedValue = UIValue(0, ref);
    observedValue = UIValue(0, ref);
    observedByConsumerValue = UIValue(0, ref);
  }

  @override
  Widget build(BuildContext context) {
    buildsCount += 1;
    return Column(children: [
      Text(observedValue.watch(ref).toString()),
      consumer((ref) {
        consumerBuildsCount += 1;
        return Text(observedByConsumerValue.watch(ref).toString());
      }),
    ]);
  }
}
