import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:plante/logging/log.dart';
import 'package:plante/ui/main/main_page.dart';

class Analytics {
  static const _IGNORED_PAGES = [
    // Main page shows other pages only, thus it's useless (and harmful) to
    // log its presence because other pages from inside of it expected
    // to be logged.
    MainPage.PAGE_NAME,
  ];
  String? _lastPage;

  Analytics();

  void sendEvent(String event, [Map<String, dynamic>? params]) {
    _sendEventImpl(event, params);
  }

  void _sendEventImpl(String event, [Map<String, dynamic>? params]) async {
    Log.i('Analytics event: $event, $params');
    await FirebaseAnalytics.instance.logEvent(name: event, parameters: params);
  }

  void onPageShown(String pageName) {
    _onPageShownImpl(pageName);
  }

  void _onPageShownImpl(String pageName) async {
    if (_IGNORED_PAGES.contains(pageName)) {
      Log.d('Analytics page ignored: $pageName');
      return;
    }
    if (_lastPage == pageName) {
      Log.i('Analytics same page shown: $pageName, ignoring');
      return;
    }
    Log.i('Analytics page shown: $pageName');
    _lastPage = pageName;
    await FirebaseAnalytics.instance.setCurrentScreen(screenName: pageName);
    await FirebaseAnalytics.instance.logEvent(name: 'page_shown_$pageName');
  }

  void onPageHidden(String? pageName) {
    _onPageHiddenImpl(pageName);
  }

  void _onPageHiddenImpl(String? pageName) async {
    // TODO(https://trello.com/c/pQ4q3ets/): keyboard causes PageStatePlante
    //         to believe it's closed,
    //         which causes invalid `shown` events to be sent when
    //         keyboard goes away.
    // if (await _settings.testingBackends()) {
    //   return;
    // }
    // if (_lastPage != pageName) {
    //   return;
    // }
    // Log.i('Analytics page hidden: $pageName');
    // _lastPage = null;
    // await _analytics.setCurrentScreen(screenName: null);
  }
}
