import 'package:plante/model/product.dart';
import 'package:plante/model/shop.dart';

enum ShopsManagerError {
  NETWORK_ERROR,
  OSM_SERVERS_ERROR,
  OTHER,
}

mixin ShopsManagerListener {
  void onLocalShopsChange() {}
  void onShopCreated(Shop shop) {}
  void onProductPutToShops(Product product, List<Shop> shops) {}
}
