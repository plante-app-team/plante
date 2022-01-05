import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:plante/logging/analytics.dart';
import 'package:plante/ui/base/page_state_plante.dart';
import 'package:plante/ui/base/ui_value.dart';

import '../../widget_tester_extension.dart';
import '../../z_fakes/fake_analytics.dart';

void main() {
  late FakeAnalytics analytics;

  setUp(() async {
    await GetIt.I.reset();
    analytics = FakeAnalytics();
    GetIt.I.registerSingleton<Analytics>(analytics);
  });

  testWidgets('notifies analytics about current page',
      (WidgetTester tester) async {
    expect(analytics.currentPage, isNull);
    await tester.superPump(const PageForTesting());
    expect(analytics.currentPage, PageForTesting.NAME);
  });

  testWidgets('UI values factory test', (WidgetTester tester) async {
    await tester.superPump(const PageForTesting());
    final state =
        tester.state<_PageForTestingState>(find.byType(PageForTesting));

    final initialBuildsCount = state.buildsCount;

    state.factoryProducedValue.setValue(123);
    await tester.pumpAndSettle();

    expect(state.buildsCount, equals(initialBuildsCount + 1));
  });
}

class PageForTesting extends PagePlante {
  static const NAME = 'PageForTesting';
  const PageForTesting({Key? key}) : super(key: key);

  @override
  _PageForTestingState createState() => _PageForTestingState();
}

class _PageForTestingState extends PageStatePlante<PageForTesting> {
  var buildsCount = 0;

  late final UIValue<int> factoryProducedValue;

  _PageForTestingState() : super(PageForTesting.NAME);

  @override
  void initState() {
    super.initState();
    factoryProducedValue = uiValuesFactory.create<int>(0);
  }

  @override
  Widget buildPage(BuildContext context) {
    buildsCount += 1;
    final val = factoryProducedValue.watch(ref);
    return Text(val.toString());
  }
}
