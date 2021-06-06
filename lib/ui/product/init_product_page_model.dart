import 'package:flutter/material.dart';
import 'package:plante/base/base.dart';
import 'package:plante/base/log.dart';
import 'package:plante/model/product.dart';
import 'package:plante/model/product_restorable.dart';
import 'package:plante/model/shop.dart';
import 'package:plante/model/shops_list_restorable.dart';
import 'package:plante/model/veg_status.dart';
import 'package:plante/model/veg_status_source.dart';
import 'package:plante/outside/map/shops_manager.dart';
import 'package:plante/outside/products/products_manager.dart';
import 'package:plante/ui/product/product_page_wrapper.dart';

class InitProductPageModel {
  late final dynamic Function() _onProductUpdate;
  final Product _initialProduct;
  final ProductRestorable _productRestorable;
  final ShopsListRestorable _shopsRestorable;
  final ProductsManager _productsManager;
  final ShopsManager _shopsManager;

  Product get product => _productRestorable.value;
  set product(Product value) {
    if (value.veganStatus != product.veganStatus) {
      // Vegan status changed
      if (value.veganStatus == VegStatus.positive) {
        value = value.rebuild((v) => v.vegetarianStatus = VegStatus.positive);
      }
    }
    if (value.vegetarianStatus != product.vegetarianStatus) {
      // Vegetarian status changed
      if (value.vegetarianStatus == VegStatus.negative) {
        value = value.rebuild((v) => v.veganStatus = VegStatus.negative);
      }
      if (value.vegetarianStatus == VegStatus.possible &&
          value.veganStatus == VegStatus.positive) {
        value = value.rebuild((v) => v.veganStatus = VegStatus.possible);
      }
      if (value.vegetarianStatus == VegStatus.unknown &&
          [VegStatus.positive, VegStatus.possible]
              .contains(value.veganStatus)) {
        value = value.rebuild((v) => v.veganStatus = VegStatus.unknown);
      }
    }
    _productRestorable.value = value;
    _onProductUpdate.call();
  }

  List<Shop> get shops => _shopsRestorable.value;
  set shops(List<Shop> value) {
    _shopsRestorable.value = value;
    _onProductUpdate.call();
  }

  bool loading = false;

  Map<String, RestorableProperty<Object?>> get restorableProperties => {
        'product': _productRestorable,
        'shops': _shopsRestorable,
      };

  InitProductPageModel(this._initialProduct, this._onProductUpdate,
      List<Shop> _initialShops, this._productsManager, this._shopsManager)
      : _productRestorable = ProductRestorable(_initialProduct),
        _shopsRestorable = ShopsListRestorable(_initialShops);

  bool askForFrontPhoto() {
    return _initialProduct.imageFront == null;
  }

  bool askForName() {
    return _initialProduct.name == null || _initialProduct.name!.trim().isEmpty;
  }

  bool askForBrand() {
    return _initialProduct.brands == null || _initialProduct.brands!.isEmpty;
  }

  bool askForCategories() {
    return _initialProduct.categories == null ||
        _initialProduct.categories!.isEmpty;
  }

  bool askForIngredientsData() {
    return _initialProduct.ingredientsText == null ||
        _initialProduct.ingredientsText!.trim().isEmpty ||
        _initialProduct.imageIngredients == null;
  }

  bool askForIngredientsText() {
    return askForIngredientsData() && product.imageIngredients != null;
  }

  bool askForVeganStatus() {
    return _initialProduct.veganStatus == null ||
        _initialProduct.veganStatusSource == null ||
        _initialProduct.veganStatusSource == VegStatusSource.open_food_facts;
  }

  bool askForVegetarianStatus() {
    return _initialProduct.vegetarianStatus == null ||
        _initialProduct.vegetarianStatusSource == null ||
        _initialProduct.vegetarianStatusSource ==
            VegStatusSource.open_food_facts;
  }

  Future<String?> ocrIngredients(String langCode) async {
    final initialProductWithIngredientsPhoto = _initialProduct.rebuildWithImage(
        ProductImageType.INGREDIENTS, product.imageIngredients);
    final ocrResult = await _productsManager.updateProductAndExtractIngredients(
        initialProductWithIngredientsPhoto, langCode);

    if (ocrResult.isErr) {
      return null;
    }
    final ocrSuccess = ocrResult.unwrap();
    product = product.rebuildWithImage(
        ProductImageType.INGREDIENTS, ocrSuccess.product.imageIngredients);
    return ocrSuccess.ingredients;
  }

  bool canSaveProduct() {
    return ProductPageWrapper.isProductFilledEnoughForDisplay(product);
  }

  Future<bool> saveProduct(String langCode) async {
    Log.i('InitProductPageModel: saveProduct: start');
    loading = true;
    _onProductUpdate.call();
    try {
      final savedProduct = product.rebuild((e) => e
        ..veganStatusSource = VegStatusSource.community
        ..vegetarianStatusSource = VegStatusSource.community);

      final productResult =
          await _productsManager.createUpdateProduct(savedProduct, langCode);
      if (productResult.isOk) {
        Log.i('InitProductPageModel: saveProduct: product saved');
        product = savedProduct;
      } else {
        return false;
      }

      if (shops.isNotEmpty) {
        Log.i('InitProductPageModel: saveProduct: saving shops');
        final shopsResult =
            await _shopsManager.putProductToShops(product, shops);
        if (shopsResult.isErr) {
          Log.i('InitProductPageModel: saveProduct: saving shops fail');
          return false;
        }
      }

      Log.i('InitProductPageModel: saveProduct: success');
      return true;
    } finally {
      loading = false;
      _onProductUpdate.call();
    }
  }

  bool askForShops() {
    return enableNewestFeatures();
  }
}
