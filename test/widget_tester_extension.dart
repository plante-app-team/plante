import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

extension WidgetTesterExtension on WidgetTester {
  Future<BuildContext> superPump(Widget widget,
      {Duration? duration,
      NavigatorObserver? navigatorObserver,
      EnginePhase phase = EnginePhase.sendSemanticsUpdate,
      bool pumpAndSettle = true}) async {
    late BuildContext _context;
    // So that WidgetTester.pageBack() could be used
    const appBar =
        PreferredSize(preferredSize: Size(1, 1), child: BackButton());

    final Widget widgetWrapper = MediaQuery(
        data: const MediaQueryData(),
        child: ProviderScope(
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
        )));

    await pumpWidget(widgetWrapper, duration, phase);
    if (pumpAndSettle) {
      await this.pumpAndSettle();
    }
    return _context;
  }

  @Deprecated('Use superTap instead')
  Future<void> superTapDropDownItem(String text) async {
    await superTap(find.text(text));
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

  Future<void> superDragUntilVisible(
      Finder finder, Finder view, Offset moveStep) async {
    await dragUntilVisible(finder, view, moveStep);
    await pumpAndSettle();
  }

  /// Same as [enterText], but also calls [pumpAndSettle].
  Future<void> superEnterText(Finder finder, String text) async {
    await enterText(finder, text);
    await pumpAndSettle();
  }

  /// For some reason [testWidgets] doesn't work with futures which weren't
  /// produced by a [WidgetTester].
  /// Which means if a widget provides some future we can await, the awaiting
  /// test will hang on it.
  ///
  /// This function is a hack which resolves this problem - it converts
  /// the not-awaitable future to an awaitable.
  ///
  /// I'm not 100% sure of why this works.
  /// The most probable explanation is the next one:
  /// 1. Flutter widget test run in a fake async environment (FakeAsync).
  /// 2. This somehow conflicts with awaiting futures not produced by a [WidgetTester].
  /// 3. We resolve this conflict by wrapping such a future into another
  ///    future which is produced by [WidgetTester.runAsync].
  Future<T> awaitableFutureFrom<T>(Future<T> future) async {
    await runAsync(() async => _noop());
    final res = await future;
    await pumpAndSettle();
    return res;
  }

  Future<void> removeSnackBarOf(BuildContext context) async {
    ScaffoldMessenger.of(context).removeCurrentSnackBar();
    await pumpAndSettle();
  }
}

void _noop() {}
