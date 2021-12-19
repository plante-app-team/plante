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
import 'package:plante/outside/map/extra_properties/products_at_shops_extra_properties_manager.dart';
import 'package:plante/outside/map/shops_manager.dart';
import 'package:plante/outside/map/shops_manager_types.dart';
import 'package:plante/outside/map/user_address/caching_user_address_pieces_obtainer.dart';
import 'package:plante/outside/products/products_obtainer.dart';
import 'package:plante/outside/products/suggestions/suggested_products_manager.dart';
import 'package:plante/outside/products/suggestions/suggestion_type.dart';
import 'package:plante/ui/shop/_confirmed_products_model.dart';
import 'package:plante/ui/shop/_off_suggested_products_model.dart';
import 'package:plante/ui/shop/_radius_suggested_products_model.dart';
import 'package:plante/ui/shop/_suggested_products_model.dart';

class ShopProductRangePageModel {
  final UserParamsController _userParamsController;
  final AddressObtainer _addressObtainer;
  final CachingUserAddressPiecesObtainer _userAddressObtainer;

  late final ConfirmedProductsModel _confirmedProductsModel;
  final _suggestedProductsModels = <SuggestionType, SuggestedProductsModel>{};

  final Shop _shop;
  late final FutureShortAddress _address;
  final VoidCallback _updateCallback;

  UserParams get user => _userParamsController.cachedUserParams!;
  FutureShortAddress get address => _address;

  bool get loading =>
      confirmedProductsLoading ||
      _suggestedProductsModels.values.any((model) => model.loading);
  bool get confirmedProductsLoading => _confirmedProductsModel.loading;
  ShopsManagerError? get loadingError =>
      _confirmedProductsModel.loadedRangeRes?.maybeErr();

  bool get confirmedProductsLoaded => _confirmedProductsModel.rangeLoaded;
  List<Product> get confirmedProducts => confirmedProductsLoaded
      ? _confirmedProductsModel.loadedProducts
      : const [];

  ShopProductRangePageModel(
      ShopsManager shopsManager,
      SuggestedProductsManager suggestedProductsManager,
      ProductsObtainer productsObtainer,
      ProductsAtShopsExtraPropertiesManager productsExtraProperties,
      this._userParamsController,
      this._addressObtainer,
      this._userAddressObtainer,
      this._shop,
      this._updateCallback) {
    _confirmedProductsModel =
        ConfirmedProductsModel(shopsManager, _shop, _updateCallback);
    _suggestedProductsModels[SuggestionType.RADIUS] =
        RadiusSuggestedProductsModel(suggestedProductsManager, productsObtainer,
            productsExtraProperties, shopsManager, _shop, _updateCallback);
    _suggestedProductsModels[SuggestionType.OFF] = OFFSuggestedProductsModel(
        suggestedProductsManager,
        productsObtainer,
        productsExtraProperties,
        shopsManager,
        _obtainCountryCodeOfShop(),
        _shop,
        _updateCallback);
    _address = _addressObtainer.addressOfShop(_shop);
  }

  void dispose() {
    _confirmedProductsModel.dispose();
    _suggestedProductsModels.values.forEach((model) => model.dispose());
  }

  void reload() {
    _confirmedProductsModel.reload();
    // NOTE: we don't reload the suggestions models, because those are
    // suggestions and we can live without them
  }

  int lastSeenSecs(Product product) =>
      _confirmedProductsModel.lastSeenSecs(product);

  void onProductUpdate(Product updatedProduct) {
    _confirmedProductsModel.onProductUpdate(updatedProduct);
    _suggestedProductsModels.values
        .forEach((model) => model.onProductUpdate(updatedProduct));
  }

  Future<Result<ProductPresenceVoteResult, ShopsManagerError>>
      productPresenceVote(Product product, bool positive) async {
    var result =
        await _confirmedProductsModel.productPresenceVote(product, positive);
    for (final model in _suggestedProductsModels.values) {
      result ??= await model.productPresenceVote(product, positive);
    }
    result ??= Ok(ProductPresenceVoteResult(productDeleted: false));
    if (result.maybeOk()?.productDeleted == true) {
      _confirmedProductsModel.onProductDeleted(product);
      _suggestedProductsModels.values
          .forEach((model) => model.onProductDeleted(product));
    }
    return result;
  }

  void onProductVisibilityChange(Product product, bool visible) {
    _suggestedProductsModels.values
        .forEach((model) => model.onProductVisibilityChange(product, visible));
  }

  Future<Country?> obtainCountryOfShop() async {
    return CountryTable.getCountry(await _obtainCountryCodeOfShop());
  }

  Future<String?> _obtainCountryCodeOfShop() async {
    // We'll assume the opened shop is visible to the user.
    // NOTE: it's a bad assumption if the page will ever be opened
    // by ways other than just clicking on shops.
    return await _userAddressObtainer.getCameraCountryCode();
  }

  bool areSuggestionsLoading(SuggestionType type) {
    return _suggestedProductsModels[type]?.loading ?? false;
  }

  List<Product> suggestedProductsFor(SuggestionType type) {
    return _suggestedProductsModels[type]?.suggestedProducts ?? const [];
  }
}
