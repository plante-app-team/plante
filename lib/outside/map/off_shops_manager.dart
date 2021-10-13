import 'package:openfoodfacts/openfoodfacts.dart' as off;
import 'package:plante/base/base.dart';
import 'package:plante/base/settings.dart';
import 'package:plante/logging/log.dart';
import 'package:plante/outside/http_client.dart';
import 'package:plante/outside/map/shops_manager.dart';
import 'package:plante/outside/map/shops_manager_types.dart';
import 'package:plante/outside/off/off_api.dart';
import 'package:plante/outside/off/off_shop.dart';

class OffShopsManager implements ShopsManagerListener {
  late final OffApi _offApi;
  final ShopsManager _shopsManager;
  late List<OffShop> _offShops = [];
  late final Map<String,off.SearchResult> _veganProductsSearch = {};

  OffShopsManager(Settings settings, this._shopsManager) {
    _offApi = OffApi(settings, HttpClient());
    _initAsync();
  }

  void _initAsync() async {
    if (await enableNewestFeatures()) {
      _shopsManager.addListener(this);
      await fetchOffShops('be');
    }
  }

  void dispose() {
    _shopsManager.removeListener(this);
  }

  @override
  void onLocalShopsChange() {
    //for (final Shop shop in _shopsManager. ._shopsCache.values) {
     // await fetchVeganProductsForShop(shop.name);
   // }
  }

  Future<dynamic> fetchOffShops(String countryIso) async {
    Log.i('offShopManager.fetchOffShop start');
    _offShops = await _offApi.getShopsForLocation(countryIso);
  }

  Future<void> fetchVeganProductsForShop(String shopName) async {
    final decodedShopName = shopName.toLowerCase();
    final index = _offShops.indexWhere((element) => element.id == decodedShopName && _veganProductsSearch[decodedShopName]==null);
    if (index >= 0) {
      Log.i('offShopsManager.fetchVeganProductsForShop $shopName');
      final off.SearchResult searchResult = await _offApi
          .getVeganProductsForShop('be', shopName, 1);

      Log.i(
          'offShopsManager.fetchVeganProductsForShop set result ${searchResult.count} for $shopName');
      _veganProductsSearch[decodedShopName] = searchResult;
    }
  }

  bool hasVeganProducts(String shopName) {
      return _veganProductsSearch[shopName.toLowerCase()] != null;
  }
}
