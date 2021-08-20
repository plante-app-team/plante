import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:plante/logging/analytics.dart';
import 'package:plante/ui/base/page_state_plante.dart';

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
    await tester.superPump(const _PageForTesting());
    expect(analytics.currentPage, _PageForTesting.NAME);
  });
}

class _PageForTesting extends StatefulWidget {
  static const NAME = 'PageForTesting';
  const _PageForTesting({Key? key}) : super(key: key);

  @override
  __PageForTestingState createState() => __PageForTestingState();
}

class __PageForTestingState extends PageStatePlante<_PageForTesting> {
  __PageForTestingState() : super(_PageForTesting.NAME);

  @override
  Widget buildPage(BuildContext context) {
    return Container();
  }
}
