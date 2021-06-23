import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:plante/base/settings.dart';
import 'package:plante/logging/log.dart';
import 'package:plante/ui/main/main_page.dart';

class Analytics {
  static const _IGNORED_PAGES = [
    // Main page shows other pages only, thus it's useless (and harmful) to
    // log its presence because other pages from inside of it expected
    // to be logged.
    MainPage.PAGE_NAME,
  ];
  final _analytics = FirebaseAnalytics();
  final Settings _settings;
  String? _lastPage;

  Analytics(this._settings);

  void sendEvent(String event, [Map<String, dynamic>? params]) {
    _sendEventImpl(event, params);
  }

  void _sendEventImpl(String event, [Map<String, dynamic>? params]) async {
    Log.i('Analytics event: $event, $params');
    if (await _settings.testingBackends()) {
      return;
    }
    await _analytics.logEvent(name: event, parameters: params);
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
    if (await _settings.testingBackends()) {
      return;
    }
    _lastPage = pageName;
    await _analytics.setCurrentScreen(screenName: pageName);
    await _analytics.logEvent(name: 'page_$pageName');
  }

  void onPageHidden(String? pageName) {
    _onPageHiddenImpl(pageName);
  }

  void _onPageHiddenImpl(String? pageName) async {
    if (await _settings.testingBackends()) {
      return;
    }
    if (_lastPage != pageName) {
      return;
    }
    Log.i('Analytics page hidden: $pageName');
    _lastPage = null;
    await _analytics.setCurrentScreen(screenName: null);
  }
}
