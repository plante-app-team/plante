enum ShopsManagerError { NETWORK_ERROR, OTHER }

abstract class ShopsManagerListener {
  void onLocalShopsChange();
}
