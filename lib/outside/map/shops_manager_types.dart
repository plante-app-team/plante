enum ShopsManagerError {
  NETWORK_ERROR,
  OSM_SERVERS_ERROR,
  OTHER,
}

abstract class ShopsManagerListener {
  void onLocalShopsChange();
}
