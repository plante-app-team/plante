import 'package:openfoodfacts/openfoodfacts.dart' as off;
import 'package:plante/base/settings.dart';
import 'package:plante/logging/log.dart';
import 'package:plante/outside/http_client.dart';
import 'package:plante/outside/map/off_shops_manager_types.dart';
import 'package:plante/outside/off/off_api.dart';
import 'package:plante/outside/off/off_shop.dart';

class OffShopsManager {
  late final OffApi _offApi;
  late List<OffShop> _offShops = [];
  final _listeners = <OffShopsManagerListener>[];

  OffShopsManager(Settings settings) {
    _offApi = OffApi(settings);
    fetchOffShops('be');
  }

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

  Future<dynamic> fetchOffShops(String countryIso) async {
    Log.i('offShopManager.fetchOffShop start');
    _offShops = await _offApi.getShopsForLocation(countryIso, HttpClient());
  }

  Future<void> fetchVeganProductsForShop(String shopName) async {
    final index = _offShops.indexWhere((element) => element.id == shopName.toLowerCase() && element.latestSearchResult==null);
    if (index >= 0) {
      Log.i('offShopsManager.fetchVeganProductsForShop $shopName');
      final off.SearchResult searchResult = await _offApi
          .getVeganProductsForShop('be', shopName, HttpClient(), 1);

      Log.i(
          'offShopsManager.fetchVeganProductsForShop set result ${searchResult.count} for $shopName');
      _offShops[index].latestSearchResult = searchResult;
    }
  }

  bool hasVeganProducts(String shopName) {
    final index = _offShops.indexWhere((element) => element.id == shopName.toLowerCase());
    if (index >=0){
      return _offShops[index].hasVeganProducts();
    }
    return false;
  }
}
