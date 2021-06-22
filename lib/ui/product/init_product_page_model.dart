import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:plante/base/base.dart';
import 'package:plante/base/log.dart';
import 'package:plante/base/result.dart';
import 'package:plante/model/product.dart';
import 'package:plante/model/product_restorable.dart';
import 'package:plante/model/shop.dart';
import 'package:plante/model/shops_list_restorable.dart';
import 'package:plante/model/veg_status.dart';
import 'package:plante/model/veg_status_source.dart';
import 'package:plante/outside/map/shops_manager.dart';
import 'package:plante/outside/products/products_manager.dart';
import 'package:plante/outside/products/products_manager_error.dart';
import 'package:plante/ui/photos_taker.dart';
import 'package:plante/ui/product/product_page_wrapper.dart';

enum InitProductPageOcrState {
  NONE,
  IN_PROGRESS,
  SUCCESS,
  FAILURE,
}

class InitProductPageModel {
  static const OCR_RETRIES_COUNT = 3;
  static const _NO_PHOTO = -1;
  late final dynamic Function() _onProductUpdate;
  late final dynamic Function() _forceReloadAllProductData;
  final ProductRestorable _initialProductRestorable;
  final ProductRestorable _productRestorable;
  final ShopsListRestorable _shopsRestorable;
  final RestorableInt _photoBeingTaken = RestorableInt(_NO_PHOTO);

  InitProductPageOcrState _ocrState = InitProductPageOcrState.NONE;

  Directory? _cacheDir;
  final ProductsManager _productsManager;
  final ShopsManager _shopsManager;
  final PhotosTaker _photosTaker;
  Product get _initialProduct => _initialProductRestorable.value;

  InitProductPageOcrState get ocrState => _ocrState;
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
        'initial_product': _initialProductRestorable,
        'product': _productRestorable,
        'shops': _shopsRestorable,
        'photo_being_taken': _photoBeingTaken,
      };

  InitProductPageModel(
      Product initialProduct,
      this._onProductUpdate,
      this._forceReloadAllProductData,
      List<Shop> _initialShops,
      this._productsManager,
      this._shopsManager,
      this._photosTaker)
      : _initialProductRestorable = ProductRestorable(initialProduct),
        _productRestorable = ProductRestorable(initialProduct),
        _shopsRestorable = ShopsListRestorable(_initialShops);

  void setPhotoBeingTakenForTests(ProductImageType imageType) {
    if (!isInTests()) {
      throw Exception();
    }
    _photoBeingTaken.value = imageType.index;
  }

  void initPhotoTaker(BuildContext context, Directory cacheDir) async {
    _cacheDir = cacheDir;

    try {
      final lostPhoto = await _photosTaker.retrieveLostPhoto();
      Log.i('InitProductPageModel initPhotoTaker, '
          'lostPhoto: $lostPhoto, '
          '_photoBeingTaken: ${_photoBeingTaken.value}');
      if (lostPhoto == null || _photoBeingTaken.value == _NO_PHOTO) {
        return;
      }
      if (lostPhoto.isErr) {
        Log.w('PhotosTaker error', ex: lostPhoto.unwrapErr());
        return;
      }

      final imageTypeNum =
          _photoBeingTaken.value.clamp(0, ProductImageType.values.length - 1);
      final imageType = ProductImageType.values[imageTypeNum];

      Log.i('InitProductPageModel obtained photo, cropping');
      final outPath = await _photosTaker.cropPhoto(
          lostPhoto.unwrap().path, context, cacheDir);
      if (outPath == null) {
        Log.i('InitProductPageModel cropping finished without photo');
        return;
      }

      Log.i('InitProductPageModel cropped photo');
      _onPhotoTaken(imageType, outPath);
    } finally {
      _photoBeingTaken.value = _NO_PHOTO;
    }
  }

  void takePhoto(ProductImageType imageType, BuildContext context) async {
    if (_cacheDir == null) {
      Log.i('InitProductPageModel: takePhoto return because no cache dir');
      return;
    }
    _photoBeingTaken.value = imageType.index;
    try {
      Log.i('InitProductPageModel: takePhoto start, imageType: $imageType');
      final outPath = await _photosTaker.takeAndCropPhoto(context, _cacheDir!);
      if (outPath == null) {
        Log.i('InitProductPageModel: takePhoto, outPath == null');
        return;
      }
      Log.i('InitProductPageModel: takePhoto success');
      _onPhotoTaken(imageType, outPath);
    } finally {
      _photoBeingTaken.value = _NO_PHOTO;
    }
  }

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

  void _onPhotoTaken(ProductImageType imageType, Uri outPath) async {
    product = product.rebuildWithImage(imageType, outPath);

    if (imageType != ProductImageType.INGREDIENTS) {
      return;
    }

    performOcr();
  }

  void performOcr() async {
    try {
      Log.i('InitProductPage: performOcr start');
      _ocrState = InitProductPageOcrState.IN_PROGRESS;
      _onProductUpdate.call();

      final ingredientsText = await _ocrIngredientsImpl();
      if (ingredientsText != null) {
        Log.i('InitProductPage: performOcr success: $ingredientsText');
        _ocrState = InitProductPageOcrState.SUCCESS;
        product = product.rebuild((e) => e.ingredientsText = ingredientsText);
        _forceReloadAllProductData.call();
      } else {
        Log.i('InitProductPage: performOcr fail');
        _ocrState = InitProductPageOcrState.FAILURE;
      }
    } finally {
      _onProductUpdate.call();
    }
  }

  Future<String?> _ocrIngredientsImpl() async {
    final initialProductWithIngredientsPhoto = _initialProduct.rebuildWithImage(
        ProductImageType.INGREDIENTS, product.imageIngredients);

    var attemptsCount = 1;
    Result<ProductWithOCRIngredients, ProductsManagerError> ocrResult =
        Err(ProductsManagerError.OTHER);
    while (attemptsCount <= OCR_RETRIES_COUNT &&
        (ocrResult.isErr || ocrResult.unwrap().ingredients == null)) {
      attemptsCount += 1;
      try {
        ocrResult = await _productsManager
            .updateProductAndExtractIngredients(
                initialProductWithIngredientsPhoto)
            .timeout(const Duration(seconds: 7));
      } on TimeoutException catch (e) {
        Log.w('_ocrIngredientsImpl timeout $attemptsCount', ex: e);
      }
    }

    if (ocrResult.isErr) {
      return null;
    }
    return ocrResult.unwrap().ingredients;
  }
}
