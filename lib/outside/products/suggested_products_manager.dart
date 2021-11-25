import 'package:plante/base/base.dart';
import 'package:plante/base/result.dart';
import 'package:plante/lang/user_langs_manager.dart';
import 'package:plante/model/lang_code.dart';
import 'package:plante/model/shop.dart';
import 'package:plante/outside/map/osm_uid.dart';
import 'package:plante/outside/off/off_shops_manager.dart';

enum SuggestedProductsManagerError {
  NETWORK,
  OTHER,
}

typedef OsmUIDBarcodesMap = Map<OsmUID, List<String>>;

class SuggestedProductsManager {
  final OffShopsManager _offShopsManager;
  final UserLangsManager _userLangsManager;

  SuggestedProductsManager(this._offShopsManager, this._userLangsManager);

  Future<Result<OsmUIDBarcodesMap, SuggestedProductsManagerError>>
      getSuggestedBarcodesFor(Iterable<Shop> shops) async {
    if (!(await enableNewestFeatures())) {
      return Ok(const {});
    }

    shops = shops.toSet(); // Defensive copy
    final names = shops.map((e) => e.name).toSet();
    final barcodesMapRes = await _offShopsManager.fetchVeganBarcodesForShops(
        names, await _userLangs());
    if (barcodesMapRes.isErr) {
      return Err(barcodesMapRes.unwrapErr().convert());
    }
    final offShopsBarcodesMap = barcodesMapRes.unwrap();

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
    // their products, but we need to return a map of OsmUID and barcodes.
    // Let's solve the problem!
    final OsmUIDBarcodesMap result = {};
    for (final shop in shops) {
      final barcodesForName = offShopsBarcodesMap[shop.name] ?? const [];
      result[shop.osmUID] = barcodesForName;
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
