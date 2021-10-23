import 'package:plante/base/result.dart';
import 'package:plante/lang/user_langs_manager.dart';
import 'package:plante/model/lang_code.dart';
import 'package:plante/model/product.dart';
import 'package:plante/model/shop.dart';
import 'package:plante/outside/map/osm_uid.dart';
import 'package:plante/outside/off/off_shops_manager.dart';

enum SuggestedProductsManagerError {
  NETWORK,
  OTHER,
}

typedef OsmUIDProductsMap = Map<OsmUID, List<Product>>;

class SuggestedProductsManager {
  final OffShopsManager _offShopsManager;
  final UserLangsManager _userLangsManager;

  SuggestedProductsManager(this._offShopsManager, this._userLangsManager);

  Future<Result<OsmUIDProductsMap, SuggestedProductsManagerError>>
      getSuggestedProductsFor(Iterable<Shop> shops) async {
    shops = shops.toSet(); // Defensive copy
    final names = shops.map((e) => e.name).toSet();
    final offProductsMapRes = await _offShopsManager.fetchVeganProductsForShops(
        names, await _userLangs());
    if (offProductsMapRes.isErr) {
      return Err(offProductsMapRes.unwrapErr().convert());
    }
    final offShopsProductsMap = offProductsMapRes.unwrap();

    // There can be many shops with same name,
    // let's build a map which will let us to work with that.
    final namesUidsMap = <String, List<OsmUID>>{};
    for (final shop in shops) {
      var list = namesUidsMap[shop.name];
      if (list == null) {
        list = <OsmUID>[];
        namesUidsMap[shop.name] = list;
      }
      list.add(shop.osmUID);
    }

    // We have a problem - OFF shops manager gives a map of shops names and
    // their products, but we need to return a map of OsmUID and produtcs.
    // Let's solve the problem!
    final OsmUIDProductsMap result = {};
    for (final shop in shops) {
      final productsForName = offShopsProductsMap[shop.name] ?? const [];
      result[shop.osmUID] = productsForName;
    }

    return Ok(result);
  }

  Future<List<LangCode>> _userLangs() async {
    final userLangs = await _userLangsManager.getUserLangs();
    return userLangs.langs.toList();
  }
}

extension _OffShopsManagerErrorExt on OffShopsManagerError {
  SuggestedProductsManagerError convert() {
    switch (this) {
      case OffShopsManagerError.NETWORK:
        return SuggestedProductsManagerError.NETWORK;
      case OffShopsManagerError.OTHER:
        return SuggestedProductsManagerError.OTHER;
    }
  }
}
