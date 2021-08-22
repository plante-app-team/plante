import 'package:plante/base/pair.dart';
import 'package:plante/logging/analytics.dart';

class FakeAnalytics implements Analytics {
  String? _currentPage;
  final _sentEvents = <Pair<String, Map<String, dynamic>?>>[];

  String? get currentPage => _currentPage;

  @override
  void onPageHidden(String? pageName) {
    if (_currentPage == pageName) {
      _currentPage = null;
    }
  }

  @override
  void onPageShown(String? pageName) {
    _currentPage = pageName;
  }

  @override
  void sendEvent(String event, [Map<String, dynamic>? params]) {
    _sentEvents.add(Pair(event, params));
  }

  bool wasEventSent(String event) {
    return _sentEvents.where((pair) => pair.first == event).isNotEmpty;
  }

  Pair<String, Map<String, dynamic>?> firstSentEvent(String event) {
    final events = sentEvents(event);
    return events.first;
  }

  List<Pair<String, Map<String, dynamic>?>> sentEvents(String event) {
    return _sentEvents.where((pair) => pair.first == event).toList();
  }

  List<Pair<String, Map<String, dynamic>?>> allEvents() {
    return _sentEvents.toList();
  }

  Map<String, dynamic>? sentEventParams(String event) {
    if (sentEvents(event).length != 1) {
      throw Exception('Event $event count != 1. Events: $_sentEvents');
    }
    return firstSentEvent(event).second;
  }

  void clearEvents() {
    _sentEvents.clear();
  }
}
