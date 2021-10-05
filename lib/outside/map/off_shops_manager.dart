import 'package:openfoodfacts/openfoodfacts.dart' as off;
import 'package:plante/base/settings.dart';
import 'package:plante/model/product.dart';
import 'package:plante/outside/http_client.dart';
import 'package:plante/outside/map/off_shops_manager_types.dart';
import 'package:plante/outside/off/off_api.dart';
import 'package:plante/outside/off/off_shop.dart';

class OffShopsManager {
  late final OffApi _offApi;
  late List<OffShop> _offShops = [];
  late Map<String, List<Product>> _offProducts = {};
  final _listeners = <OffShopsManagerListener>[];

  OffShopsManager(Settings settings) : _offApi = OffApi(settings);

  void addListener(OffShopsManagerListener listener) {
    _listeners.add(listener);
  }

  void removeListener(OffShopsManagerListener listener) {
    _listeners.remove(listener);
  }

  void _notifyListeners() {
    _listeners.forEach((listener) {
      listener.onOffShopsChange();
    });
  }

  void fetchOffShops(String countryIso) async {
    _offShops = await _offApi.getShopsForLocation(countryIso, HttpClient());
    _notifyListeners();
  }

  void fetchVeganProductsForShop(String countryIso, String shop) async {
    off.SearchResult searchResult = await _offApi.getVeganProductsForShop(countryIso, shop, HttpClient());
    //TODO
  }

}