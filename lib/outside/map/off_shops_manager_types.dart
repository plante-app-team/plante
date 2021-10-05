enum OffShopsManagerError {
  NETWORK_ERROR,
  OFF_SERVERS_ERROR,
  OTHER,
}

abstract class OffShopsManagerListener {
  void onOffShopsChange();
}
