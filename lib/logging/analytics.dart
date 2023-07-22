import 'package:plante/logging/log.dart';
import 'package:plante/logging/underlying_analytics.dart';
import 'package:plante/logging/underlying_analytics_firebase.dart';
import 'package:plante/ui/main/main_page.dart';

class Analytics {
  static const _IGNORED_PAGES = [
    // Main page shows other pages only, thus it's useless (and harmful) to
    // log its presence because other pages from inside of it expected
    // to be logged.
    MainPage.PAGE_NAME,
  ];
  final List<UnderlyingAnalytics> _impls;
  String? _lastPage;

  Analytics([List<UnderlyingAnalytics>? impls])
      : _impls = impls ?? [UnderlyingAnalyticsFirebase()];

  void sendEvent(String event, [Map<String, dynamic>? params]) {
    _sendEventImpl(event, params);
  }

  void _sendEventImpl(String event, [Map<String, dynamic>? params]) async {
    Log.i('Analytics event: $event, $params');
    _impls.forEach((impl) => impl.sendEvent(event, params));
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
    _impls.forEach((impl) => impl
      ..setCurrentPage(pageName)
      ..sendEvent('page_shown_$pageName'));
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
