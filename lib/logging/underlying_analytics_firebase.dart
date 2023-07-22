import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:plante/logging/underlying_analytics.dart';

class UnderlyingAnalyticsFirebase implements UnderlyingAnalytics {
  final FirebaseAnalytics _firebase;

  UnderlyingAnalyticsFirebase([FirebaseAnalytics? firebase])
      : _firebase = firebase ?? FirebaseAnalytics.instance;

  @override
  void sendEvent(String event, [Map<String, dynamic>? params]) async {
    if (params != null) {
      params = {
        for (final param in params.entries)
          param.key: _convertParamValue(param.value)
      };
    }
    await _firebase.logEvent(name: event, parameters: params);
  }

  dynamic _convertParamValue(dynamic value) {
    if (value is String || value is num) {
      return value;
    } else {
      return value.toString();
    }
  }

  @override
  void setCurrentPage(String pageName) {
    _firebase.setCurrentScreen(screenName: pageName);
  }
}
