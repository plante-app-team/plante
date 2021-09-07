import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

extension WidgetTesterExtension on WidgetTester {
  Future<BuildContext> superPump(Widget widget,
      {Duration? duration,
      NavigatorObserver? navigatorObserver,
      EnginePhase phase = EnginePhase.sendSemanticsUpdate}) async {
    late BuildContext _context;
    // So that WidgetTester.pageBack() could be used
    const appBar =
        PreferredSize(preferredSize: Size(1, 1), child: BackButton());

    final Widget widgetWrapper = MediaQuery(
        data: const MediaQueryData(),
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: Builder(
            builder: (BuildContext context) {
              _context = context;
              return Scaffold(appBar: appBar, body: widget);
            },
          ),
          navigatorObservers: [
            if (navigatorObserver != null) navigatorObserver
          ],
        ));

    await pumpWidget(widgetWrapper, duration, phase);
    return _context;
  }

  /// Somehow the DropdownButton widget creates 2 widgets for each of the
  /// items it has.
  /// This makes it impossible to click this item with WidgetTester.tap()
  /// because widgets in those pairs are almost identical.
  /// This function is a avoiding this problem by finding only the first needed
  /// widget and clicking it, ignoring all the rest.
  Future<void> tapDropDownItem(String text) async {
    var foundFirst = false;
    await tap(find.byWidgetPredicate((widget) {
      if (foundFirst) {
        return false;
      }
      if (widget is! Text) {
        return false;
      }
      final found = widget.data == text;
      if (found) {
        foundFirst = true;
      }
      return found;
    }));
  }

  /// Same as [tap], but also calls [pumpAndSettle].
  Future<void> superTap(Finder finder,
      {int? pointer,
      int buttons = kPrimaryButton,
      bool warnIfMissed = true}) async {
    await tap(finder,
        pointer: pointer, buttons: buttons, warnIfMissed: warnIfMissed);
    await pumpAndSettle();
  }

  /// Same as [enterText], but also calls [pumpAndSettle].
  Future<void> superEnterText(Finder finder, String text) async {
    await enterText(finder, text);
    await pumpAndSettle();
  }
}
