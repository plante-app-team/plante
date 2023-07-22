abstract interface class UnderlyingAnalytics {
  void sendEvent(String event, [Map<String, dynamic>? params]);
  void setCurrentPage(String pageName);
}
