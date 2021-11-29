import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:plante/base/result.dart';
import 'package:plante/model/country.dart';
import 'package:plante/model/country_table.dart';
import 'package:plante/model/product.dart';
import 'package:plante/model/shop.dart';
import 'package:plante/model/user_params.dart';
import 'package:plante/model/user_params_controller.dart';
import 'package:plante/outside/backend/product_presence_vote_result.dart';
import 'package:plante/outside/map/address_obtainer.dart';
import 'package:plante/outside/map/shops_manager.dart';
import 'package:plante/outside/map/shops_manager_types.dart';
import 'package:plante/outside/off/off_shops_manager.dart';
import 'package:plante/outside/products/products_obtainer.dart';
import 'package:plante/outside/products/suggested_products_manager.dart';
import 'package:plante/ui/shop/_confirmed_products_model.dart';
import 'package:plante/ui/shop/_suggested_products_model.dart';

class ShopProductRangePageModel {
  final UserParamsController _userParamsController;
  final AddressObtainer _addressObtainer;

  late final ConfirmedProductsModel _confirmedProductsModel;
  late final SuggestedProductsModel _suggestedProductsModel;
  final OffShopsManager _offShopsManager;

  final Shop _shop;
  late final FutureShortAddress _address;
  final VoidCallback _updateCallback;

  UserParams get user => _userParamsController.cachedUserParams!;
  FutureShortAddress get address => _address;

  bool get loading => confirmedProductsLoading || suggestedProductsLoading;
  bool get confirmedProductsLoading => _confirmedProductsModel.loading;
  bool get suggestedProductsLoading => _suggestedProductsModel.loading;
  ShopsManagerError? get loadingError =>
      _confirmedProductsModel.loadedRangeRes?.maybeErr();

  bool get confirmedProductsLoaded => _confirmedProductsModel.rangeLoaded;
  List<Product> get confirmedProducts => confirmedProductsLoaded
      ? _confirmedProductsModel.loadedProducts
      : const [];
  List<Product> get suggestedProducts =>
      _suggestedProductsModel.suggestedProducts;

  ShopProductRangePageModel(
      ShopsManager shopsManager,
      SuggestedProductsManager suggestedProductsManager,
      ProductsObtainer productsObtainer,
      this._userParamsController,
      this._addressObtainer,
      this._offShopsManager,
      this._shop,
      this._updateCallback) {
    _confirmedProductsModel =
        ConfirmedProductsModel(shopsManager, _shop, _updateCallback);
    _suggestedProductsModel = SuggestedProductsModel(
        suggestedProductsManager, productsObtainer, _shop, _updateCallback);
    _address = _addressObtainer.addressOfShop(_shop);
  }

  void dispose() {
    _confirmedProductsModel.dispose();
    _suggestedProductsModel.dispose();
  }

  void reload() {
    _confirmedProductsModel.reload();
    // NOTE: we don't reload _suggestedProductsModel, because those are
    // suggestions and we can live without them
  }

  int lastSeenSecs(Product product) =>
      _confirmedProductsModel.lastSeenSecs(product);

  void onProductUpdate(Product updatedProduct) {
    _confirmedProductsModel.onProductUpdate(updatedProduct);
    _suggestedProductsModel.onProductUpdate(updatedProduct);
  }

  Future<Result<ProductPresenceVoteResult, ShopsManagerError>>
      productPresenceVote(Product product, bool positive) async {
    return await _confirmedProductsModel.productPresenceVote(product, positive);
  }

  void onProductVisibilityChange(Product product, bool visible) {
    _suggestedProductsModel.onProductVisibilityChange(product, visible);
  }

  Future<Country?> obtainCountryOfShop() async {
    final offShop = await _offShopsManager.findOffShopByName(_shop.name);
    return CountryTable.getCountry(offShop.maybeOk()?.country);
  }
}
