import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

extension WidgetTesterExtension on WidgetTester {
  Future<BuildContext> superPump(
      Widget widget,
      {Duration? duration,
        NavigatorObserver? navigatorObserver,
        EnginePhase phase = EnginePhase.sendSemanticsUpdate}) async {
    late BuildContext _context;

    final Widget widgetWrapper = MediaQuery(
        data: const MediaQueryData(),
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: Builder(
            builder: (BuildContext context) {
              _context = context;
              return Scaffold(body: widget);
            },
          ),
          navigatorObservers: [
            if (navigatorObserver != null)
              navigatorObserver
          ],
        )
    );

    await pumpWidget(widgetWrapper, duration, phase);
    return _context;
  }
}
