import 'package:plante/base/result.dart';
import 'package:plante/lang/user_langs_manager.dart';
import 'package:plante/model/lang_code.dart';
import 'package:plante/model/product.dart';
import 'package:plante/model/shop.dart';
import 'package:plante/outside/off/off_shops_manager.dart';

enum SuggestedProductsManagerError {
  NETWORK,
  OTHER,
}

class SuggestedProductsManager {
  final OffShopsManager _offShopsManager;
  final UserLangsManager _userLangsManager;

  SuggestedProductsManager(this._offShopsManager, this._userLangsManager);

  Future<Result<List<Product>, SuggestedProductsManagerError>>
      getSuggestedProductsFor(Shop shop) async {
    final result = await _offShopsManager.fetchVeganProductsForShop(
        shop.name, await _userLangs());
    if (result.isErr) {
      return Err(result.unwrapErr().convert());
    }
    return Ok(result.unwrap());
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
