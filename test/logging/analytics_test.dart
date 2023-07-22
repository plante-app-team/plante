import 'package:mockito/mockito.dart';
import 'package:plante/base/size_int.dart';
import 'package:plante/logging/underlying_analytics_firebase.dart';
import 'package:test/test.dart';

import '../common_mocks.mocks.dart';

void main() {
  late MockFirebaseAnalytics firebase;
  late UnderlyingAnalyticsFirebase underlyingAnalyticsFirebase;

  setUp(() {
    firebase = MockFirebaseAnalytics();
    underlyingAnalyticsFirebase = UnderlyingAnalyticsFirebase(firebase);
  });

  test('send event', () async {
    final params = {
      'param1': 'hello',
      'param2': 'world',
      'param3': 123,
    };

    verifyZeroInteractions(firebase);

    underlyingAnalyticsFirebase.sendEvent('event_name', params);

    verify(firebase.logEvent(name: 'event_name', parameters: params));
    verifyNoMoreInteractions(firebase);
  });

  test('set current page', () async {
    verifyZeroInteractions(firebase);

    underlyingAnalyticsFirebase.setCurrentPage('main_page');

    verify(firebase.setCurrentScreen(screenName: 'main_page'));
    verifyNoMoreInteractions(firebase);
  });

  test('types conversion', () async {
    final originalParams = {
      'param1': 'hello',
      'param2': 123,
      'param3': true,
      'param4': const SizeInt(width: 10, height: 20),
    };
    final expectedParams = {
      'param1': 'hello',
      'param2': 123,
      'param3': 'true',
      'param4': '[10, 20]',
    };

    underlyingAnalyticsFirebase.sendEvent('event_name', originalParams);
    verify(firebase.logEvent(name: 'event_name', parameters: expectedParams));
  });
}
