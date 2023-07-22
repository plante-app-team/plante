import 'package:plante/base/pair.dart';
import 'package:plante/base/size_int.dart';
import 'package:plante/logging/analytics.dart';
import 'package:plante/logging/underlying_analytics.dart';
import 'package:test/test.dart';

void main() {
  late _FakeUnderlyingAnalytics underlyingAnalytics1;
  late _FakeUnderlyingAnalytics underlyingAnalytics2;
  late Analytics analytics;

  setUp(() {
    underlyingAnalytics1 = _FakeUnderlyingAnalytics();
    underlyingAnalytics2 = _FakeUnderlyingAnalytics();
    analytics = Analytics([underlyingAnalytics1, underlyingAnalytics2]);
  });

  test('send event', () async {
    final params = {
      'param1': 'hello',
      'param2': 'world',
    };

    expect(underlyingAnalytics1.events, isEmpty);
    expect(underlyingAnalytics2.events, isEmpty);

    analytics.sendEvent('event', params);

    expect(underlyingAnalytics1.events, equals([Pair('event', params)]));
    expect(underlyingAnalytics2.events, equals([Pair('event', params)]));
  });

  test('set current page', () async {
    expect(underlyingAnalytics1.events, isEmpty);
    expect(underlyingAnalytics2.events, isEmpty);
    expect(underlyingAnalytics1.currentPage, isNull);
    expect(underlyingAnalytics2.currentPage, isNull);

    analytics.onPageShown('main_page');

    expect(underlyingAnalytics1.currentPage, equals('main_page'));
    expect(underlyingAnalytics2.currentPage, equals('main_page'));
    expect(underlyingAnalytics1.events,
        equals([const Pair('page_shown_main_page', null)]));
    expect(underlyingAnalytics2.events,
        equals([const Pair('page_shown_main_page', null)]));
  });

  test('no types conversion', () async {
    final originalParams = {
      'param1': 'hello',
      'param2': 123,
      'param3': true,
      'param4': const SizeInt(width: 10, height: 20),
    };
    final expectedParams = originalParams;

    analytics.sendEvent('event_name', originalParams);
    expect(underlyingAnalytics1.events,
        equals([Pair('event_name', expectedParams)]));
  });
}

class _FakeUnderlyingAnalytics implements UnderlyingAnalytics {
  final events = <Pair<String, Map<String, dynamic>?>>[];
  String? currentPage;

  @override
  void sendEvent(String event, [Map<String, dynamic>? params]) {
    events.add(Pair(event, params));
  }

  @override
  void setCurrentPage(String pageName) {
    currentPage = pageName;
  }
}
